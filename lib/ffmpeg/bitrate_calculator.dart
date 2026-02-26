import 'package:flutter/material.dart';
import 'package:nova/core/constants/app_constants.dart';
import 'package:nova/data/models/video_models.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Калькулятор битрейта для достижения целевого размера файла
class BitrateCalculator {
  /// Рассчитывает целевой битрейт видео для заданного размера файла
  /// 
  /// [targetSizeMB] - целевой размер файла в мегабайтах
  /// [durationSeconds] - длительность видео в секундах
  /// [audioBitrateKbps] - битрейт аудио в kbps
  /// 
  /// Возвращает битрейт видео в kbps
  static int calculateVideoBitrate({
    required double targetSizeMB,
    required double durationSeconds,
    required int audioBitrateKbps,
  }) {
    // Целевой размер в битах
    final targetSizeBits = targetSizeMB * 8 * 1024 * 1024;
    
    // Размер аудио в битах
    final audioSizeBits = audioBitrateKbps * 1000 * durationSeconds;
    
    // Резерв для контейнера и метаданных
    final overhead = targetSizeBits * (AppConstants.containerOverheadPercent / 100);
    
    // Доступный размер для видео
    final availableForVideo = targetSizeBits - audioSizeBits - overhead;
    
    // Битрейт видео в kbps
    // Уменьшаем на 5% для страховки от превышения размера
    final safeAvailableForVideo = availableForVideo * 0.95;
    int videoBitrateKbps = (safeAvailableForVideo / durationSeconds / 1000).round();
    
    // Ограничиваем минимальным и максимальным значениями
    videoBitrateKbps = videoBitrateKbps.clamp(
      AppConstants.minVideoBitrate,
      AppConstants.maxVideoBitrate,
    );
    
    return videoBitrateKbps;
  }
  
  /// Рассчитывает предполагаемый размер файла по битрейту
  /// 
  /// Возвращает размер в мегабайтах
  static double calculateFileSize({
    required double durationSeconds,
    required int videoBitrateKbps,
    required int audioBitrateKbps,
  }) {
    // Размер видео в битах
    final videoSizeBits = videoBitrateKbps * 1000 * durationSeconds;
    
    // Размер аудио в битах
    final audioSizeBits = audioBitrateKbps * 1000 * durationSeconds;
    
    // Общий размер с учетом резерва
    final totalBits = (videoSizeBits + audioSizeBits) * (1 + AppConstants.containerOverheadPercent / 100);
    
    // Размер в мегабайтах
    return totalBits / 8 / 1024 / 1024;
  }
  
  /// Проверяет возможность достижения целевого размера
  /// 
  /// Возвращает объект с результатом проверки
  static BitrateValidation validateSettings({
    required BuildContext context,
    required VideoInfo videoInfo,
    required ConversionSettings settings,
  }) {
    final durationSeconds = videoInfo.duration.inSeconds.toDouble();
    
    if (durationSeconds <= 0) {
      return BitrateValidation(
        isValid: false,
        message: AppLocalizations.of(context)!.msgDurationError,
        calculatedBitrate: 0,
        qualityLevel: QualityLevel.invalid,
      );
    }
    
    final videoBitrate = calculateVideoBitrate(
      targetSizeMB: settings.targetSizeMB,
      durationSeconds: durationSeconds,
      audioBitrateKbps: settings.audioBitrate.value,
    );
    
    // Определяем уровень качества
    QualityLevel qualityLevel;
    String message;
    
    if (videoBitrate <= AppConstants.minVideoBitrate) {
      qualityLevel = QualityLevel.veryLow;
      message = AppLocalizations.of(context)!.msgQualityVeryLow;
    } else if (videoBitrate < 500) {
      qualityLevel = QualityLevel.low;
      message = AppLocalizations.of(context)!.msgQualityLow;
    } else if (videoBitrate < 1500) {
      qualityLevel = QualityLevel.medium;
      message = AppLocalizations.of(context)!.msgQualityMedium;
    } else if (videoBitrate < 4000) {
      qualityLevel = QualityLevel.good;
      message = AppLocalizations.of(context)!.msgQualityGood;
    } else if (videoBitrate < 8000) {
      qualityLevel = QualityLevel.high;
      message = AppLocalizations.of(context)!.msgQualityHigh;
    } else {
      qualityLevel = QualityLevel.excellent;
      message = AppLocalizations.of(context)!.msgQualityExcellent;
    }
    
    // Проверяем, не больше ли целевой размер исходного
    if (settings.targetSizeMB >= videoInfo.fileSizeMB) {
      message = '${AppLocalizations.of(context)!.msgTargetLargerThanOriginal} (${videoInfo.fileSizeFormatted})';
    }
    
    return BitrateValidation(
      isValid: videoBitrate > AppConstants.minVideoBitrate,
      message: message,
      calculatedBitrate: videoBitrate,
      qualityLevel: qualityLevel,
    );
  }
  
  /// Рассчитывает рекомендуемый целевой размер для хорошего качества
  static double calculateRecommendedSize({
    required VideoInfo videoInfo,
    required int audioBitrateKbps,
    int targetVideoBitrateKbps = 2000, // рекомендуемый битрейт видео
  }) {
    return calculateFileSize(
      durationSeconds: videoInfo.duration.inSeconds.toDouble(),
      videoBitrateKbps: targetVideoBitrateKbps,
      audioBitrateKbps: audioBitrateKbps,
    );
  }
}

/// Результат валидации битрейта
class BitrateValidation {
  final bool isValid;
  final String message;
  final int calculatedBitrate; // в kbps
  final QualityLevel qualityLevel;
  
  BitrateValidation({
    required this.isValid,
    required this.message,
    required this.calculatedBitrate,
    required this.qualityLevel,
  });
  
  /// Битрейт в формате "2500 kbps"
  String get bitrateFormatted => '$calculatedBitrate kbps';
  
  /// Битрейт в Mbps для больших значений
  String get bitrateFormattedAuto {
    if (calculatedBitrate >= 1000) {
      return '${(calculatedBitrate / 1000).toStringAsFixed(1)} Mbps';
    }
    return '$calculatedBitrate kbps';
  }
}

/// Уровень качества видео
enum QualityLevel {
  invalid,
  veryLow,
  low,
  medium,
  good,
  high,
  excellent,
}

extension QualityLevelExtension on QualityLevel {
  String getLabel(BuildContext context) {
    switch (this) {
      case QualityLevel.invalid:
        return AppLocalizations.of(context)!.qualityError;
      case QualityLevel.veryLow:
        return AppLocalizations.of(context)!.qualityVeryLow;
      case QualityLevel.low:
        return AppLocalizations.of(context)!.qualityLow;
      case QualityLevel.medium:
        return AppLocalizations.of(context)!.qualityMedium;
      case QualityLevel.good:
        return AppLocalizations.of(context)!.qualityGood;
      case QualityLevel.high:
        return AppLocalizations.of(context)!.qualityHigh;
      case QualityLevel.excellent:
        return AppLocalizations.of(context)!.qualityExcellent;
    }
  }
  
  String get emoji {
    switch (this) {
      case QualityLevel.invalid:
        return '❌';
      case QualityLevel.veryLow:
        return '😰';
      case QualityLevel.low:
        return '😕';
      case QualityLevel.medium:
        return '😊';
      case QualityLevel.good:
        return '👍';
      case QualityLevel.high:
        return '🎯';
      case QualityLevel.excellent:
        return '⭐';
    }
  }
}
