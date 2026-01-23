import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:creos/core/theme/app_theme.dart';
import 'package:creos/core/constants/app_constants.dart';
import 'package:creos/data/models/video_models.dart';
import 'package:creos/ffmpeg/bitrate_calculator.dart';
import 'package:creos/presentation/providers/app_providers.dart';
import 'package:creos/presentation/widgets/file_card.dart';
import 'package:creos/presentation/widgets/settings_widgets.dart';
import 'package:creos/presentation/widgets/common_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final files = ref.watch(filesProvider);
    final settings = ref.watch(settingsProvider);
    final conversionState = ref.watch(conversionStateProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);
    
    // Рассчитываем качество для первого файла (если есть)
    BitrateValidation? validation;
    if (files.isNotEmpty) {
      validation = BitrateCalculator.validateSettings(
        videoInfo: files.first.videoInfo,
        settings: settings,
      );
    }
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode ? LinearGradient(
            colors: [
              AppColors.darkBackground,
              Color(0xFF0D1117),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : LinearGradient(
            colors: [
              AppColors.lightBackground,
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Шапка приложения
            _buildHeader(isDarkMode),
            
            // Основной контент
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Левая панель - файлы
                  Expanded(
                    flex: 3,
                    child: _buildFilesPanel(files, isDarkMode),
                  ),
                  
                  // Разделитель
                  Container(
                    width: 1,
                    color: isDarkMode ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  
                  // Правая панель - настройки
                  SizedBox(
                    width: 400, // Фиксированная ширина для компактности
                    child: _buildSettingsPanel(files, settings, validation, conversionState, isDarkMode),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface.withOpacity(0.5) : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(color: isDarkMode ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Row(
        children: [

          // Логотип
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () async {
                 final url = Uri.parse('https://creos.me/');
                 if (await canLaunchUrl(url)) {
                   await launchUrl(url);
                 }
              },
              child: SvgPicture.asset(
                isDarkMode ? 'assets/images/logo_black.svg' : 'assets/images/logo_white.svg',
                height: 32,
                placeholderBuilder: (context) {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.black, size: 16),
                  );
                },
              ),
            ),
          ),
          const Spacer(),
          
          // Переключатель темы
          IconButton(
            onPressed: () {
              ref.read(isDarkModeProvider.notifier).state = !isDarkMode;
            },
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: isDarkMode ? AppColors.textSecondary : Colors.grey.shade700,
            ),
            tooltip: isDarkMode ? 'Светлая тема' : 'Тёмная тема',
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilesPanel(List<ConversionFile> files, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Файлы для конвертации',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? AppColors.textPrimary : Colors.black87,
                ),
              ),
              if (files.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    ref.read(filesProvider.notifier).clearFiles();
                  },
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Очистить'),
                  style: TextButton.styleFrom(
                    foregroundColor: isDarkMode ? AppColors.textMuted : Colors.grey,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Зона добавления файлов или список файлов
          Expanded(
            child: files.isEmpty
                ? DropZone(
                    onTap: () {
                      ref.read(filesProvider.notifier).pickFiles();
                    },
                    onFilesDropped: (paths) {
                      ref.read(filesProvider.notifier).addFiles(paths);
                    },
                  )
                : Column(
                    children: [
                      // Мини-зона добавления
                      GestureDetector(
                        onTap: () {
                          ref.read(filesProvider.notifier).pickFiles();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: isDarkMode ? AppColors.darkSurface : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDarkMode ? AppColors.darkBorder : Colors.grey.shade300,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Добавить файлы',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Список файлов
                      Expanded(
                        child: ListView.builder(
                          itemCount: files.length,
                          itemBuilder: (context, index) {
                            final file = files[index];
                            return FileCard(
                              file: file,
                              onRemove: () {
                                ref.read(filesProvider.notifier).removeFile(file.id);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingsPanel(
    List<ConversionFile> files,
    ConversionSettings settings,
    BitrateValidation? validation,
    ConversionState conversionState,
    bool isDarkMode,
  ) {
    // Средний размер файла для настройки слайдера
    final avgFileSize = files.isNotEmpty
        ? files.map((f) => f.videoInfo.fileSizeMB).reduce((a, b) => a + b) / files.length
        : 100.0;
        
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? null : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Настройки',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? AppColors.textPrimary : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: SingleChildScrollView( // Оставляем скролл, но пытаемся вписать всё
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TargetSizeInput(
                    value: settings.targetSizeMB,
                    originalSize: avgFileSize,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).setTargetSize(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  EncodingModeSelector(
                    selectedPasses: settings.passes,
                    onChanged: (passes) {
                      ref.read(settingsProvider.notifier).setPasses(passes);
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Компактная строка с форматом и аудио
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: FormatSelector(
                          selectedFormat: settings.outputFormat,
                          onChanged: (format) {
                            ref.read(settingsProvider.notifier).setOutputFormat(format);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AudioBitrateSelector(
                          selectedBitrate: settings.audioBitrate,
                          onChanged: (bitrate) {
                            ref.read(settingsProvider.notifier).setAudioBitrate(bitrate);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Разрешение видео
                  ResolutionSelector(
                    width: settings.width,
                    height: settings.height,
                    scaleMode: settings.scaleMode,
                    onChanged: (w, h, mode) {
                      ref.read(settingsProvider.notifier).setResolution(w, h, mode);
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Информация о качестве
                  if (validation != null)
                    QualityInfoPanel(
                      calculatedBitrate: validation.calculatedBitrate,
                      qualityLevel: validation.qualityLevel.label,
                      qualityEmoji: validation.qualityLevel.emoji,
                      message: validation.message,
                    ).animate().fadeIn(duration: 300.ms),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Кнопка конвертации (всегда внизу)
          ConvertButton(
            isConverting: conversionState.isConverting,
            isEnabled: files.isNotEmpty && !conversionState.isConverting,
            progress: conversionState.overallProgress,
            onPressed: () {
              ref.read(conversionStateProvider.notifier).startConversion();
            },
            onCancel: () {
              ref.read(conversionStateProvider.notifier).cancelConversion();
            },
          ),
        ],
      ),
    );
  }
}
