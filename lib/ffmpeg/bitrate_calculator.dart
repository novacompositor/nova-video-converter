import 'package:creos/core/constants/app_constants.dart';
import 'package:creos/data/models/video_models.dart';

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
    required VideoInfo videoInfo,
    required ConversionSettings settings,
  }) {
    final durationSeconds = videoInfo.duration.inSeconds.toDouble();
    
    if (durationSeconds <= 0) {
      return BitrateValidation(
        isValid: false,
        message: 'Ошибка: длительность видео не определена',
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
      message = 'Очень низкое качество: битрейт слишком мал. Увеличьте целевой размер или уменьшите битрейт аудио.';
    } else if (videoBitrate < 500) {
      qualityLevel = QualityLevel.low;
      message = 'Низкое качество: возможны артефакты сжатия';
    } else if (videoBitrate < 1500) {
      qualityLevel = QualityLevel.medium;
      message = 'Среднее качество: приемлемо для большинства видео';
    } else if (videoBitrate < 4000) {
      qualityLevel = QualityLevel.good;
      message = 'Хорошее качество: отлично для обычного просмотра';
    } else if (videoBitrate < 8000) {
      qualityLevel = QualityLevel.high;
      message = 'Высокое качество: отличный результат';
    } else {
      qualityLevel = QualityLevel.excellent;
      message = 'Превосходное качество';
    }
    
    // Проверяем, не больше ли целевой размер исходного
    if (settings.targetSizeMB >= videoInfo.fileSizeMB) {
      message = 'Внимание: целевой размер больше или равен исходному (${videoInfo.fileSizeFormatted})';
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
  String get label {
    switch (this) {
      case QualityLevel.invalid:
        return 'Ошибка';
      case QualityLevel.veryLow:
        return 'Очень низкое';
      case QualityLevel.low:
        return 'Низкое';
      case QualityLevel.medium:
        return 'Среднее';
      case QualityLevel.good:
        return 'Хорошее';
      case QualityLevel.high:
        return 'Высокое';
      case QualityLevel.excellent:
        return 'Превосходное';
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
