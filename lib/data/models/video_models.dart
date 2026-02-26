import 'dart:io';
import 'package:nova/core/constants/app_constants.dart';

/// Модель информации о видео файле
class VideoInfo {
  final String filePath;
  final String fileName;
  final int fileSize; // в байтах
  final Duration duration;
  final int videoBitrate; // в kbps
  final int audioBitrate; // в kbps
  final String videoCodec;
  final String audioCodec;
  final int width;
  final int height;
  final double frameRate;
  
  VideoInfo({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.duration,
    required this.videoBitrate,
    required this.audioBitrate,
    required this.videoCodec,
    required this.audioCodec,
    required this.width,
    required this.height,
    required this.frameRate,
  });
  
  /// Размер файла в мегабайтах
  double get fileSizeMB => fileSize / (1024 * 1024);
  
  /// Разрешение в формате "1920x1080"
  String get resolution => '${width}x$height';
  
  /// Длительность в формате "00:05:30"
  String get durationFormatted {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  /// Размер файла форматированный
  String get fileSizeFormatted {
    if (fileSizeMB >= 1024) {
      return '${(fileSizeMB / 1024).toStringAsFixed(2)} ГБ';
    }
    return '${fileSizeMB.toStringAsFixed(2)} МБ';
  }
}

/// Модель файла для конвертации
class ConversionFile {
  final String id;
  final VideoInfo videoInfo;
  ConversionStatus status;
  double progress;
  int currentPass; // 1 или 2
  int totalPasses; // 1 или 2
  String? outputPath;
  String? errorMessage;
  double? speed; // скорость в x (например, 2.5x)
  Duration? eta; // оставшееся время
  
  ConversionFile({
    required this.id,
    required this.videoInfo,
    this.status = ConversionStatus.pending,
    this.progress = 0,
    this.currentPass = 0,
    this.totalPasses = 1,
    this.outputPath,
    this.errorMessage,
    this.speed,
    this.eta,
  });
  
  ConversionFile copyWith({
    ConversionStatus? status,
    double? progress,
    int? currentPass,
    int? totalPasses,
    String? outputPath,
    String? errorMessage,
    double? speed,
    Duration? eta,
  }) {
    return ConversionFile(
      id: id,
      videoInfo: videoInfo,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      currentPass: currentPass ?? this.currentPass,
      totalPasses: totalPasses ?? this.totalPasses,
      outputPath: outputPath ?? this.outputPath,
      errorMessage: errorMessage ?? this.errorMessage,
      speed: speed ?? this.speed,
      eta: eta ?? this.eta,
    );
  }
}

enum ConversionStatus {
  pending,     // Ожидает
  processing,  // В процессе
  completed,   // Завершено
  error,       // Ошибка
  cancelled,   // Отменено
}

/// Модель настроек конвертации
class ConversionSettings {
  final double targetSizeMB;
  final OutputFormat outputFormat;
  final AudioBitrate audioBitrate;
  final EncodingPreset preset;
  final int passes; // 1 или 2
  final String outputDirectory;
  final int? width;
  final int? height;
  final String scaleMode; // 'fit' или 'crop'
  
  const ConversionSettings({
    required this.targetSizeMB,
    required this.outputFormat,
    required this.audioBitrate,
    required this.preset,
    required this.passes,
    required this.outputDirectory,
    this.width,
    this.height,
    this.scaleMode = 'fit',
  });
  
  ConversionSettings copyWith({
    double? targetSizeMB,
    OutputFormat? outputFormat,
    AudioBitrate? audioBitrate,
    EncodingPreset? preset,
    int? passes,
    String? outputDirectory,
    int? width,
    int? height,
    String? scaleMode,
    bool clearResolution = false,
  }) {
    return ConversionSettings(
      targetSizeMB: targetSizeMB ?? this.targetSizeMB,
      outputFormat: outputFormat ?? this.outputFormat,
      audioBitrate: audioBitrate ?? this.audioBitrate,
      preset: preset ?? this.preset,
      passes: passes ?? this.passes,
      outputDirectory: outputDirectory ?? this.outputDirectory,
      width: clearResolution ? null : (width ?? this.width),
      height: clearResolution ? null : (height ?? this.height),
      scaleMode: scaleMode ?? this.scaleMode,
    );
  }
  
  /// Настройки по умолчанию
  factory ConversionSettings.defaultSettings() {
    return ConversionSettings(
      targetSizeMB: 50,
      outputFormat: AppConstants.outputFormats[0], // MP4 H.264
      audioBitrate: AppConstants.audioBitrates[2], // 128 kbps
      preset: AppConstants.encodingPresets[5], // medium
      passes: 2, // двухпроходный по умолчанию
      outputDirectory: '',
      width: null,
      height: null,
      scaleMode: 'fit',
    );
  }
}
