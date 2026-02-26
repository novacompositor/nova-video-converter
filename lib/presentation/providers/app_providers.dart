import 'package:nova/core/constants/app_constants.dart';
import 'package:nova/data/models/video_models.dart';
import 'package:nova/ffmpeg/bitrate_calculator.dart';
import 'package:nova/ffmpeg/ffmpeg_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

/// Провайдер для SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main.dart');
});

/// Провайдер активной локали (языка)
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

class LocaleNotifier extends StateNotifier<Locale?> {
  final SharedPreferences _prefs;
  static const _localeKey = 'app_locale';
  
  LocaleNotifier(this._prefs) : super(_loadLocale(_prefs));
  
  static Locale? _loadLocale(SharedPreferences prefs) {
    final languageCode = prefs.getString(_localeKey);
    if (languageCode != null && languageCode.isNotEmpty) {
      return Locale(languageCode);
    }
    return null; // System default
  }
  
  Future<void> setLocale(Locale? locale) async {
    state = locale;
    if (locale == null) {
      await _prefs.remove(_localeKey);
    } else {
      await _prefs.setString(_localeKey, locale.languageCode);
    }
  }
}


/// Провайдер сервиса FFmpeg
final ffmpegServiceProvider = Provider<FFmpegService>((ref) {
  return FFmpegService();
});

/// Провайдер настроек конвертации
final settingsProvider = StateNotifierProvider<SettingsNotifier, ConversionSettings>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<ConversionSettings> {
  SettingsNotifier() : super(ConversionSettings.defaultSettings());
  
  void setTargetSize(double sizeMB) {
    state = state.copyWith(targetSizeMB: sizeMB);
  }
  
  void setOutputFormat(OutputFormat format) {
    state = state.copyWith(outputFormat: format);
  }
  
  void setAudioBitrate(AudioBitrate bitrate) {
    state = state.copyWith(audioBitrate: bitrate);
  }
  
  void setPreset(EncodingPreset preset) {
    state = state.copyWith(preset: preset);
  }
  
  void setPasses(int passes) {
    state = state.copyWith(passes: passes);
  }
  
  void setOutputDirectory(String directory) {
    state = state.copyWith(outputDirectory: directory);
  }
  
  void setResolution(int? width, int? height, String scaleMode) {
    state = state.copyWith(
      width: width,
      height: height,
      scaleMode: scaleMode,
      clearResolution: width == null && height == null,
    );
  }
}

/// Провайдер списка файлов для конвертации
final filesProvider = StateNotifierProvider<FilesNotifier, List<ConversionFile>>((ref) {
  return FilesNotifier(ref);
});

class FilesNotifier extends StateNotifier<List<ConversionFile>> {
  final Ref _ref;
  
  FilesNotifier(this._ref) : super([]);
  
  /// Добавляет файлы через диалог выбора
  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );
    
    if (result != null) {
      await addFiles(result.paths.whereType<String>().toList());
    }
  }
  
  /// Добавляет файлы по путям
  Future<void> addFiles(List<String> paths) async {
    final ffmpeg = _ref.read(ffmpegServiceProvider);
    
    for (final filePath in paths) {
      // Проверяем, не добавлен ли уже этот файл
      if (state.any((f) => f.videoInfo.filePath == filePath)) {
        continue;
      }
      
      // Получаем информацию о видео
      final videoInfo = await ffmpeg.getVideoInfo(filePath);
      if (videoInfo != null) {
        final file = ConversionFile(
          id: DateTime.now().millisecondsSinceEpoch.toString() + filePath.hashCode.toString(),
          videoInfo: videoInfo,
        );
        state = [...state, file];
        
        // Обновляем целевой размер по умолчанию на основе первого файла
        if (state.length == 1) {
          final settingsNotifier = _ref.read(settingsProvider.notifier);
          settingsNotifier.setTargetSize(videoInfo.fileSizeMB * 0.5); // 50% от оригинала
        }
      }
    }
  }
  
  /// Удаляет файл из списка
  void removeFile(String id) {
    state = state.where((f) => f.id != id).toList();
  }
  
  /// Очищает список файлов
  void clearFiles() {
    state = [];
  }
  
  /// Обновляет прогресс файла
  void updateProgress(String id, {
    ConversionStatus? status,
    double? progress,
    int? currentPass,
    int? totalPasses,
    String? outputPath,
    String? errorMessage,
    double? speed,
    Duration? eta,
  }) {
    state = state.map((file) {
      if (file.id == id) {
        // Строгая защита от "скачков" прогресса назад
        // Если статус не меняется (идет обновление прогресса) и новый прогресс меньше текущего,
        // то игнорируем падение (оставляем текущий).
        double? effectiveProgress = progress;
        if (status == null && progress != null && file.progress > 0 && progress < file.progress) {
          effectiveProgress = file.progress;
        }

        return file.copyWith(
          status: status,
          progress: effectiveProgress,
          currentPass: currentPass,
          totalPasses: totalPasses,
          outputPath: outputPath,
          errorMessage: errorMessage,
          speed: speed,
          eta: eta,
        );
      }
      return file;
    }).toList();
  }
}

/// Провайдер состояния конвертации
final conversionStateProvider = StateNotifierProvider<ConversionStateNotifier, ConversionState>((ref) {
  return ConversionStateNotifier(ref);
});

class ConversionState {
  final bool isConverting;
  final int currentFileIndex;
  final int totalFiles;
  final String? currentFileName;
  final double currentFileProgress;
  
  const ConversionState({
    this.isConverting = false,
    this.currentFileIndex = 0,
    this.totalFiles = 0,
    this.currentFileName,
    this.currentFileProgress = 0,
  });
  
  ConversionState copyWith({
    bool? isConverting,
    int? currentFileIndex,
    int? totalFiles,
    String? currentFileName,
    double? currentFileProgress,
  }) {
    return ConversionState(
      isConverting: isConverting ?? this.isConverting,
      currentFileIndex: currentFileIndex ?? this.currentFileIndex,
      totalFiles: totalFiles ?? this.totalFiles,
      currentFileName: currentFileName ?? this.currentFileName,
      currentFileProgress: currentFileProgress ?? this.currentFileProgress,
    );
  }
  
  double get overallProgress {
    if (totalFiles == 0) return 0;
    return (currentFileIndex + currentFileProgress) / totalFiles;
  }
}

class ConversionStateNotifier extends StateNotifier<ConversionState> {
  final Ref _ref;
  
  ConversionStateNotifier(this._ref) : super(const ConversionState());
  
  /// Запускает конвертацию всех файлов
  Future<void> startConversion() async {
    final files = _ref.read(filesProvider);
    final settings = _ref.read(settingsProvider);
    final ffmpeg = _ref.read(ffmpegServiceProvider);
    final filesNotifier = _ref.read(filesProvider.notifier);
    
    if (files.isEmpty) return;
    
    // Определяем папку для сохранения
    String outputDir = settings.outputDirectory;
    if (outputDir.isEmpty) {
      // Используем папку первого файла
      outputDir = path.dirname(files.first.videoInfo.filePath);
    }
    
    state = state.copyWith(
      isConverting: true,
      totalFiles: files.length,
      currentFileIndex: 0,
    );
    
    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      
      state = state.copyWith(
        currentFileIndex: i,
        currentFileName: file.videoInfo.fileName,
      );
      
      // Рассчитываем битрейт
      final durationSeconds = file.videoInfo.duration.inSeconds.toDouble();
      final videoBitrate = BitrateCalculator.calculateVideoBitrate(
        targetSizeMB: settings.targetSizeMB,
        durationSeconds: durationSeconds,
        audioBitrateKbps: settings.audioBitrate.value,
      );
      
      // Формируем путь вывода
      final baseName = path.basenameWithoutExtension(file.videoInfo.filePath);
      final outputPath = path.join(
        outputDir,
        '${baseName}_nova.${settings.outputFormat.extension}',
      );
      
      filesNotifier.updateProgress(
        file.id,
        status: ConversionStatus.processing,
        progress: 0,
        currentPass: 1,
        totalPasses: settings.passes,
      );
      
      try {
        Stream<ConversionProgress> progressStream;
        
        if (settings.passes == 2) {
          progressStream = ffmpeg.convertTwoPass(
            inputPath: file.videoInfo.filePath,
            outputPath: outputPath,
            videoBitrateKbps: videoBitrate,
            settings: settings,
            duration: file.videoInfo.duration,
          );
        } else {
          progressStream = ffmpeg.convertSinglePass(
            inputPath: file.videoInfo.filePath,
            outputPath: outputPath,
            videoBitrateKbps: videoBitrate,
            settings: settings,
            duration: file.videoInfo.duration,
          );
        }
        
        await for (final progress in progressStream) {
          filesNotifier.updateProgress(
            file.id,
            progress: progress.progress,
            currentPass: progress.currentPass,
            speed: progress.speed,
          );
          
          state = state.copyWith(currentFileProgress: progress.progress);
          
          if (progress.isCompleted) {
            filesNotifier.updateProgress(
              file.id,
              status: ConversionStatus.completed,
              progress: 1.0,
              outputPath: outputPath,
            );
          }
        }
      } catch (e) {
        filesNotifier.updateProgress(
          file.id,
          status: ConversionStatus.error,
          errorMessage: e.toString(),
        );
      }
    }
    
    state = state.copyWith(
      isConverting: false,
      currentFileIndex: files.length,
    );
  }
  
  /// Отменяет конвертацию
  void cancelConversion() {
    final ffmpeg = _ref.read(ffmpegServiceProvider);
    ffmpeg.cancel();
    state = state.copyWith(isConverting: false);
    
    // Помечаем текущие файлы как отменённые
    final files = _ref.read(filesProvider);
    final filesNotifier = _ref.read(filesProvider.notifier);
    
    for (final file in files) {
      if (file.status == ConversionStatus.processing) {
        filesNotifier.updateProgress(
          file.id,
          status: ConversionStatus.cancelled,
        );
      }
    }
  }
}

/// Провайдер темы
final isDarkModeProvider = StateProvider<bool>((ref) => true);
