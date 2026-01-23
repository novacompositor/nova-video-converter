import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:creos/data/models/video_models.dart';
import 'package:creos/ffmpeg/bitrate_calculator.dart';
import 'package:path/path.dart' as path;

/// Сервис для работы с FFmpeg
class FFmpegService {
  Process? _currentProcess;
  bool _isCancelled = false;
  
  /// Получает путь к FFmpeg бинарнику
  Future<String> get ffmpegPath async {
    final String binaryName = Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg';
    
    // 1. Проверяем рядом с исполняемым файлом или в подпапке bin (Portable/Linux/Windows)
    final exeDir = path.dirname(Platform.resolvedExecutable);
    final searchPaths = [
      exeDir,
      path.join(exeDir, 'bin'),
      path.join(exeDir, 'data', 'flutter_assets', 'bin'), // На случай упаковки в ассеты
    ];

    for (final p in searchPaths) {
      final fullPath = path.join(p, binaryName);
      if (await File(fullPath).exists()) {
        return fullPath;
      }
    }
    
    // 2. Проверяем в Resources или Frameworks (MacOS)
    if (Platform.isMacOS) {
      final macSearchPaths = [
         path.join(exeDir, '..', 'Resources', binaryName),
         path.join(exeDir, '..', 'Frameworks', binaryName),
      ];
      for (final p in macSearchPaths) {
        if (await File(p).exists()) {
          return p;
        }
      }
    }
    
    // 3. Возвращаем системную команду
    return binaryName;
  }
  
  /// Получает путь к ffprobe
  Future<String> get ffprobePath async {
    final String binaryName = Platform.isWindows ? 'ffprobe.exe' : 'ffprobe';
    
    // 1. Проверяем рядом с исполняемым файлом или в подпапке bin
    final exeDir = path.dirname(Platform.resolvedExecutable);
    final searchPaths = [
      exeDir,
      path.join(exeDir, 'bin'),
      path.join(exeDir, 'data', 'flutter_assets', 'bin'),
    ];

    for (final p in searchPaths) {
      final fullPath = path.join(p, binaryName);
      if (await File(fullPath).exists()) {
        return fullPath;
      }
    }
    
    // 2. Проверяем в Resources или Frameworks (MacOS)
    if (Platform.isMacOS) {
      final macSearchPaths = [
         path.join(exeDir, '..', 'Resources', binaryName),
         path.join(exeDir, '..', 'Frameworks', binaryName),
      ];
      for (final p in macSearchPaths) {
        if (await File(p).exists()) {
          return p;
        }
      }
    }
    
    // 3. Возвращаем системную команду
    return binaryName;
  }
  
  /// Проверяет доступность FFmpeg
  Future<bool> isFFmpegAvailable() async {
    try {
      final binaryPath = await ffmpegPath;
      final result = await Process.run(binaryPath, ['-version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
  
  /// Получает информацию о видео файле
  Future<VideoInfo?> getVideoInfo(String filePath) async {
    try {
      final binaryPath = await ffprobePath;
      final result = await Process.run(
        binaryPath,
        [
          '-v', 'quiet',
          '-print_format', 'json',
          '-show_format',
          '-show_streams',
          filePath,
        ],
      );
      
      if (result.exitCode != 0) {
        return null;
      }
      
      final json = jsonDecode(result.stdout as String);
      final format = json['format'] as Map<String, dynamic>;
      final streams = json['streams'] as List;
      
      // Находим видео и аудио потоки
      Map<String, dynamic>? videoStream;
      Map<String, dynamic>? audioStream;
      
      for (final stream in streams) {
        final codecType = stream['codec_type'];
        if (codecType == 'video' && videoStream == null) {
          videoStream = stream;
        } else if (codecType == 'audio' && audioStream == null) {
          audioStream = stream;
        }
      }
      
      if (videoStream == null) {
        return null;
      }
      
      // Парсим длительность
      final durationStr = format['duration'] as String?;
      final duration = durationStr != null
          ? Duration(milliseconds: (double.parse(durationStr) * 1000).round())
          : Duration.zero;
      
      // Парсим размер файла
      final sizeStr = format['size'] as String?;
      final fileSize = sizeStr != null ? int.parse(sizeStr) : 0;
      
      // Парсим битрейт
      final bitrateStr = format['bit_rate'] as String?;
      final totalBitrate = bitrateStr != null ? int.parse(bitrateStr) ~/ 1000 : 0;
      
      // Битрейт аудио
      int audioBitrate = 0;
      if (audioStream != null) {
        final audioBitrateStr = audioStream['bit_rate'] as String?;
        audioBitrate = audioBitrateStr != null ? int.parse(audioBitrateStr) ~/ 1000 : 128;
      }
      
      // Битрейт видео (примерно)
      final videoBitrate = totalBitrate - audioBitrate;
      
      // Парсим разрешение
      final width = videoStream['width'] as int? ?? 0;
      final height = videoStream['height'] as int? ?? 0;
      
      // Парсим FPS
      double frameRate = 30.0;
      final fpsStr = videoStream['r_frame_rate'] as String?;
      if (fpsStr != null && fpsStr.contains('/')) {
        final parts = fpsStr.split('/');
        if (parts.length == 2) {
          final num = double.tryParse(parts[0]) ?? 30;
          final den = double.tryParse(parts[1]) ?? 1;
          if (den > 0) {
            frameRate = num / den;
          }
        }
      }
      
      return VideoInfo(
        filePath: filePath,
        fileName: path.basename(filePath),
        fileSize: fileSize,
        duration: duration,
        videoBitrate: videoBitrate > 0 ? videoBitrate : 1000,
        audioBitrate: audioBitrate > 0 ? audioBitrate : 128,
        videoCodec: videoStream['codec_name'] as String? ?? 'unknown',
        audioCodec: audioStream?['codec_name'] as String? ?? 'unknown',
        width: width,
        height: height,
        frameRate: frameRate,
      );
    } catch (e) {
      print('Error getting video info: $e');
      return null;
    }
  }
  
  /// Конвертирует видео в один проход
  Stream<ConversionProgress> convertSinglePass({
    required String inputPath,
    required String outputPath,
    required int videoBitrateKbps,
    required ConversionSettings settings,
    required Duration duration,
  }) async* {
    _isCancelled = false;
    
    final filters = _buildVideoFilters(settings);
    
    final args = [
      '-y', // перезаписывать без вопросов
      '-i', inputPath,
      '-c:v', settings.outputFormat.videoCodec,
      '-b:v', '${videoBitrateKbps}k',
      if (filters.isNotEmpty) ...['-vf', filters],
      '-preset', settings.preset.name,
      '-c:a', settings.outputFormat.audioCodec,
      '-b:a', '${settings.audioBitrate.value}k',
      '-progress', 'pipe:1',
      '-nostats',
      outputPath,
    ];
    
    yield* _runFFmpeg(args, 1, 1, duration);
  }
  
  /// Конвертирует видео в два прохода
  Stream<ConversionProgress> convertTwoPass({
    required String inputPath,
    required String outputPath,
    required int videoBitrateKbps,
    required ConversionSettings settings,
    required Duration duration,
  }) async* {
    _isCancelled = false;
    
    final filters = _buildVideoFilters(settings);
    
    // Создаем временную директорию для файлов статистики
    final tempDir = Directory.systemTemp.createTempSync('creos_');
    final passLogFile = path.join(tempDir.path, 'ffmpeg2pass');
    
    try {
      // Первый проход
      final pass1Args = [
        '-y',
        '-i', inputPath,
        '-c:v', settings.outputFormat.videoCodec,
        '-b:v', '${videoBitrateKbps}k',
        if (filters.isNotEmpty) ...['-vf', filters],
        '-preset', settings.preset.name,
        '-pass', '1',
        '-passlogfile', passLogFile,
        '-an', // без аудио в первом проходе
        '-f', 'null',
        Platform.isWindows ? 'NUL' : '/dev/null',
        '-progress', 'pipe:1', // тоже выводим прогресс
        '-nostats',
      ];
      
      yield* _runFFmpeg(pass1Args, 1, 2, duration);
      
      if (_isCancelled) return;
      
      print('First pass completed. Preparing for second pass...');
      // Небольшая задержка, чтобы ОС успела освободить файлы логов
      await Future.delayed(const Duration(seconds: 1));
      
      // Проверяем существование лог файлов (для отладки)
      final logFiles = tempDir.listSync().where((e) => e.path.contains('ffmpeg2pass'));
      print('Log files found: ${logFiles.map((e) => e.path).join(', ')}');
      
      // Второй проход
      final pass2Args = [
        '-y',
        '-i', inputPath,
        '-c:v', settings.outputFormat.videoCodec,
        '-b:v', '${videoBitrateKbps}k',
        if (filters.isNotEmpty) ...['-vf', filters],
        '-preset', settings.preset.name,
        '-pass', '2',
        '-passlogfile', passLogFile,
        '-c:a', settings.outputFormat.audioCodec,
        '-b:a', '${settings.audioBitrate.value}k',
        '-progress', 'pipe:1',
        '-nostats',
        outputPath,
      ];
      
      print('Starting second pass with args: $pass2Args');
      yield* _runFFmpeg(pass2Args, 2, 2, duration);
    } finally {
      // Удаляем временные файлы
      try {
        if (await tempDir.exists()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    }
  }
  
  /// Строит фильтры видео (масштабирование)
  String _buildVideoFilters(ConversionSettings settings) {
    if (settings.width == null || settings.height == null) {
      return '';
    }
    
    final w = settings.width!;
    final h = settings.height!;
    
    if (settings.scaleMode == 'crop') {
      // Обрезать: масштабируем чтобы заполнить, затем обрезаем по центру
      return 'scale=$w:$h:force_original_aspect_ratio=increase,crop=$w:$h';
    } else {
      // Растянуть: просто масштабируем игнорируя пропорции
      return 'scale=$w:$h';
    }
  }
  
  /// Запускает FFmpeg и парсит прогресс
  Stream<ConversionProgress> _runFFmpeg(
    List<String> args,
    int currentPass,
    int totalPasses,
    Duration totalDuration,
  ) async* {
    print('Starting FFmpeg with args: $args');
    
    final binaryPath = await ffmpegPath;
    _currentProcess = await Process.start(binaryPath, args);
    
    // Подписка на stderr для логов (не блокирует)
    final stderrSub = _currentProcess!.stderr
        .transform(utf8.decoder)
        .listen((data) {
      print('FFmpeg stderr: $data');
    });
    
    Duration currentTime = Duration.zero;
    double speed = 0;
    
    try {
      // Читаем stdout построчно
      final stream = _currentProcess!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.trim().isEmpty) continue;
        
        if (line.startsWith('out_time_ms=')) {
          final parts = line.split('=');
          if (parts.length > 1) {
              final ms = int.tryParse(parts[1]);
            if (ms != null) {
              final newTime = Duration(microseconds: ms);
              // Защита от "прыжков" времени назад
              if (newTime >= currentTime) {
                currentTime = newTime;
              }
            }
          }
        } else if (line.startsWith('speed=')) {
          final parts = line.split('=');
          if (parts.length > 1) {
            final speedStr = parts[1].replaceAll('x', '').trim();
            speed = double.tryParse(speedStr) ?? 0;
          }
        } else if (line.startsWith('progress=')) {
          final parts = line.split('=');
          if (parts.length > 1) {
            final progressStatus = parts[1].trim();
            
            // Расчет прогресса
            double progress = 0.0;
            if (totalDuration.inMicroseconds > 0) {
              progress = currentTime.inMicroseconds / totalDuration.inMicroseconds;
            }
            
            // Коррекция для двухпроходного кодирования
            double overallProgress = progress;
            if (totalPasses == 2) {
              if (currentPass == 1) {
                overallProgress = progress * 0.5;
              } else {
                overallProgress = 0.5 + (progress * 0.5);
              }
            }
            
            // Если статус end, то проверяем, последний ли это проход
            if (progressStatus == 'end') {
              final isLastPass = currentPass == totalPasses;
              yield ConversionProgress(
                progress: totalPasses == 2 && currentPass == 1 ? 0.5 : 1.0,
                currentPass: currentPass,
                totalPasses: totalPasses,
                currentTime: totalDuration,
                speed: speed,
                isCompleted: isLastPass,
              );
            } else {
              yield ConversionProgress(
                progress: overallProgress.clamp(0.0, 1.0),
                currentPass: currentPass,
                totalPasses: totalPasses,
                currentTime: currentTime,
                speed: speed,
                isCompleted: false,
              );
            }
          }
        }
      }
    } finally {
      await stderrSub.cancel();
    }
    
    final exitCode = await _currentProcess!.exitCode;
    _currentProcess = null;
    
    if (exitCode != 0 && !_isCancelled) {
      throw Exception('FFmpeg завершился с ошибкой: код $exitCode');
    }
  }
  
  /// Отменяет текущий процесс конвертации
  void cancel() {
    _isCancelled = true;
    _currentProcess?.kill();
    _currentProcess = null;
  }
}

/// Прогресс конвертации
class ConversionProgress {
  final double progress; // 0.0 - 1.0
  final int currentPass;
  final int totalPasses;
  final Duration currentTime;
  final double speed;
  final bool isCompleted;
  final String? error;
  
  ConversionProgress({
    required this.progress,
    required this.currentPass,
    required this.totalPasses,
    required this.currentTime,
    required this.speed,
    required this.isCompleted,
    this.error,
  });
  
  /// Прогресс в процентах
  int get progressPercent => (progress * 100).round();
  
  /// Скорость в формате "2.5x"
  String get speedFormatted => '${speed.toStringAsFixed(1)}x';
  
  /// Формат прохода "1/2"
  String get passFormatted => '$currentPass/$totalPasses';
}
