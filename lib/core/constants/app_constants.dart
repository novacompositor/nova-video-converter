class AppConstants {
  // Название приложения
  static const String appName = 'Nova';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Профессиональный конвертер видео';
  
  // Поддерживаемые форматы ввода
  static const List<String> supportedInputFormats = [
    'mp4', 'avi', 'mkv', 'mov', 'wmv', 'flv', 'webm', 'm4v', 'mpeg', 'mpg', '3gp'
  ];
  
  // Форматы вывода
  static const List<OutputFormat> outputFormats = [
    OutputFormat(
      name: 'MP4 (H.264)',
      extension: 'mp4',
      videoCodec: 'libx264',
      audioCodec: 'aac',
      description: 'Универсальный формат, отличная совместимость',
    ),
    OutputFormat(
      name: 'MP4 (H.265/HEVC)',
      extension: 'mp4',
      videoCodec: 'libx265',
      audioCodec: 'aac',
      description: 'Лучшее сжатие, требует больше времени',
    ),
    OutputFormat(
      name: 'WebM (VP9)',
      extension: 'webm',
      videoCodec: 'libvpx-vp9',
      audioCodec: 'libopus',
      description: 'Отлично для веба',
    ),
    OutputFormat(
      name: 'MKV (H.264)',
      extension: 'mkv',
      videoCodec: 'libx264',
      audioCodec: 'aac',
      description: 'Гибкий контейнер',
    ),
    OutputFormat(
      name: 'AVI',
      extension: 'avi',
      videoCodec: 'libx264',
      audioCodec: 'mp3',
      description: 'Классический формат',
    ),
    OutputFormat(
      name: 'MOV (H.264)',
      extension: 'mov',
      videoCodec: 'libx264',
      audioCodec: 'aac',
      description: 'Формат Apple',
    ),
  ];
  
  // Битрейт аудио (в kbps)
  static const List<AudioBitrate> audioBitrates = [
    AudioBitrate(value: 64, label: '64 kbps', description: 'Низкое качество'),
    AudioBitrate(value: 96, label: '96 kbps', description: 'Приемлемое качество'),
    AudioBitrate(value: 128, label: '128 kbps', description: 'Стандартное качество'),
    AudioBitrate(value: 192, label: '192 kbps', description: 'Хорошее качество'),
    AudioBitrate(value: 256, label: '256 kbps', description: 'Высокое качество'),
    AudioBitrate(value: 320, label: '320 kbps', description: 'Максимальное качество'),
  ];
  
  // Пресеты кодирования
  static const List<EncodingPreset> encodingPresets = [
    EncodingPreset(
      name: 'ultrafast',
      label: 'Ультра быстрый',
      description: 'Минимальное время, большой размер',
      speed: 10,
    ),
    EncodingPreset(
      name: 'superfast',
      label: 'Очень быстрый',
      description: 'Быстро, приемлемое качество',
      speed: 9,
    ),
    EncodingPreset(
      name: 'veryfast',
      label: 'Быстрый',
      description: 'Хороший баланс скорости',
      speed: 8,
    ),
    EncodingPreset(
      name: 'faster',
      label: 'Ускоренный',
      description: 'Немного быстрее стандарта',
      speed: 7,
    ),
    EncodingPreset(
      name: 'fast',
      label: 'Немного быстрый',
      description: 'Чуть быстрее стандарта',
      speed: 6,
    ),
    EncodingPreset(
      name: 'medium',
      label: 'Стандартный',
      description: 'Баланс качества и скорости (рекомендуется)',
      speed: 5,
      isRecommended: true,
    ),
    EncodingPreset(
      name: 'slow',
      label: 'Медленный',
      description: 'Лучшее качество',
      speed: 4,
    ),
    EncodingPreset(
      name: 'slower',
      label: 'Очень медленный',
      description: 'Ещё лучше качество',
      speed: 3,
    ),
    EncodingPreset(
      name: 'veryslow',
      label: 'Максимальное качество',
      description: 'Лучшее качество, долго',
      speed: 2,
    ),
  ];
  
  // Режимы кодирования
  static const List<EncodingMode> encodingModes = [
    EncodingMode(
      passes: 1,
      label: '1 проход',
      description: 'Быстрее, но менее точный размер файла',
      icon: '🚀',
    ),
    EncodingMode(
      passes: 2,
      label: '2 прохода',
      description: 'Лучшее качество при заданном размере',
      icon: '⭐',
      isRecommended: true,
    ),
  ];
  
  // Резерв для контейнера и метаданных (в процентах)
  static const double containerOverheadPercent = 2.0;
  
  // Минимальный битрейт видео (в kbps)
  static const int minVideoBitrate = 100;
  
  // Максимальный битрейт видео (в kbps)
  static const int maxVideoBitrate = 50000;
}

class OutputFormat {
  final String name;
  final String extension;
  final String videoCodec;
  final String audioCodec;
  final String description;
  
  const OutputFormat({
    required this.name,
    required this.extension,
    required this.videoCodec,
    required this.audioCodec,
    required this.description,
  });
}

class AudioBitrate {
  final int value;
  final String label;
  final String description;
  
  const AudioBitrate({
    required this.value,
    required this.label,
    required this.description,
  });
}

class EncodingPreset {
  final String name;
  final String label;
  final String description;
  final int speed;
  final bool isRecommended;
  
  const EncodingPreset({
    required this.name,
    required this.label,
    required this.description,
    required this.speed,
    this.isRecommended = false,
  });
}

class EncodingMode {
  final int passes;
  final String label;
  final String description;
  final String icon;
  final bool isRecommended;
  
  const EncodingMode({
    required this.passes,
    required this.label,
    required this.description,
    required this.icon,
    this.isRecommended = false,
  });
}
