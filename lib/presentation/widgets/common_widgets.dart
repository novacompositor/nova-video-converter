import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:nova/core/theme/app_theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Зона для перетаскивания файлов
class DropZone extends StatefulWidget {
  final VoidCallback onTap;
  final Function(List<String>) onFilesDropped;
  
  const DropZone({
    super.key,
    required this.onTap,
    required this.onFilesDropped,
  });
  
  @override
  State<DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<DropZone> {
  bool _isDragging = false;
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return DropTarget(
      onDragEntered: (details) {
        setState(() => _isDragging = true);
      },
      onDragExited: (details) {
        setState(() => _isDragging = false);
      },
      onDragDone: (details) {
        setState(() => _isDragging = false);
        final paths = details.files.map((f) => f.path).toList();
        widget.onFilesDropped(paths);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _isDragging 
                  ? AppColors.primary.withOpacity(0.1)
                  : (isDark ? AppColors.darkSurface : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isDragging ? AppColors.primary : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
                width: _isDragging ? 2 : 1,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _isDragging 
                        ? AppColors.primary.withOpacity(0.2)
                        : (isDark ? AppColors.darkCard : Colors.white),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isDragging ? Icons.file_download : Icons.add_circle_outline,
                    size: 48,
                    color: _isDragging ? AppColors.primary : (isDark ? AppColors.textSecondary : Colors.grey),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _isDragging 
                      ? AppLocalizations.of(context)!.releaseFilesHere
                      : AppLocalizations.of(context)!.dropFilesHere,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: _isDragging ? AppColors.primary : (isDark ? AppColors.textPrimary : Colors.black87),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.orClickToSelect,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.textSecondary : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.supportedFormats,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ).animate(target: _isDragging ? 1 : 0)
            .scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02)),
        ),
      ),
    );
  }
}

/// Информационная панель о качестве
class QualityInfoPanel extends StatelessWidget {
  final int calculatedBitrate;
  final String qualityLevel;
  final String qualityEmoji;
  final String message;
  
  const QualityInfoPanel({
    super.key,
    required this.calculatedBitrate,
    required this.qualityLevel,
    required this.qualityEmoji,
    required this.message,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? null : Colors.white,
        gradient: isDark ? LinearGradient(
          colors: [
            AppColors.darkCard,
            AppColors.darkSurface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ) : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.estimatedResult,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? AppColors.textPrimary : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  label: AppLocalizations.of(context)!.videoBitrate,
                  value: '${calculatedBitrate} kbps',
                  icon: Icons.speed,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _InfoItem(
                  label: AppLocalizations.of(context)!.qualityLabel,
                  value: '$qualityEmoji $qualityLevel',
                  icon: Icons.high_quality,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondary : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  
  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: isDark ? null : Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textMuted : Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? AppColors.textPrimary : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Кнопка конвертации
class ConvertButton extends StatelessWidget {
  final bool isConverting;
  final bool isEnabled;
  final VoidCallback onPressed;
  final VoidCallback onCancel;
  final double progress;
  
  const ConvertButton({
    super.key,
    required this.isConverting,
    required this.isEnabled,
    required this.onPressed,
    required this.onCancel,
    this.progress = 0,
  });
  
  @override
  Widget build(BuildContext context) {
    if (isConverting) {
      return Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              // Прогресс-бар как фон
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              // Кнопка отмены
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onCancel,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${AppLocalizations.of(context)!.btnConverting} ${(progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.btnCancel,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          disabledBackgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? AppColors.darkBorder 
              : Colors.grey.shade300,
          disabledForegroundColor: AppColors.textMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          // Убираем textStyle отсюда, чтобы не было конфликтов интерполяции
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow_rounded, size: 28),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.btnStartConversion,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                inherit: false, // Важно для предотвращения краша анимации
                color: Colors.black, // Явно задаем цвет
              ),
            ),
          ],
        ),
      ),
    ).animate(target: isEnabled ? 1 : 0)
      .scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1));
  }
}
