import 'package:flutter/material.dart';
import 'package:creos/core/theme/app_theme.dart';
import 'package:creos/core/constants/app_constants.dart';

/// Переключатель режима кодирования (1 проход / 2 прохода)
class EncodingModeSelector extends StatelessWidget {
  final int selectedPasses;
  final ValueChanged<int> onChanged;
  
  const EncodingModeSelector({
    super.key,
    required this.selectedPasses,
    required this.onChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Режим кодирования',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: isDark ? AppColors.textPrimary : Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Двухпроходное кодирование анализирует видео первым проходом,\n'
                  'затем применяет оптимальное распределение битрейта во втором.\n'
                  'Это даёт лучшее качество при заданном размере файла.',
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: isDark ? AppColors.textMuted : Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade300),
          ),
          child: Row(
            children: [
              // 1 проход
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selectedPasses == 1 
                          ? AppColors.primary.withOpacity(0.15) 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      border: selectedPasses == 1 
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          '1 проход',
                          style: TextStyle(
                            fontWeight: selectedPasses == 1 ? FontWeight.w600 : FontWeight.normal,
                            color: selectedPasses == 1 ? AppColors.primary : (isDark ? AppColors.textPrimary : Colors.black87),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Быстрее',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textMuted : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 2 прохода
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selectedPasses == 2 
                          ? AppColors.primary.withOpacity(0.15) 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      border: selectedPasses == 2 
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '2 прохода',
                              style: TextStyle(
                                fontWeight: selectedPasses == 2 ? FontWeight.w600 : FontWeight.normal,
                                color: selectedPasses == 2 ? AppColors.primary : (isDark ? AppColors.textPrimary : Colors.black87),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                              /*
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  'рек.',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              */
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Рекомендуется',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textMuted : Colors.grey,
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
      ],
    );
  }
}

/// Ввод целевого размера с ручным вводом
class TargetSizeInput extends StatefulWidget {
  final double value;
  final double originalSize;
  final ValueChanged<double> onChanged;
  
  const TargetSizeInput({
    super.key,
    required this.value,
    required this.originalSize,
    required this.onChanged,
  });
  
  @override
  State<TargetSizeInput> createState() => _TargetSizeInputState();
}

class _TargetSizeInputState extends State<TargetSizeInput> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(1));
    // Слушаем фокус, чтобы обновить значение при потере фокуса если нужно
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _controller.text = widget.value.toStringAsFixed(1);
      }
    });
  }
  
  @override
  void didUpdateWidget(TargetSizeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Обновляем текст только если значение изменилось И поле не в фокусе
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _controller.text = widget.value.toStringAsFixed(1);
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Целевой размер файла',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: isDark ? AppColors.textPrimary : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Поле ввода
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        suffixText: 'МБ',
                        suffixStyle: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      onSubmitted: (value) {
                         // При Enter обновляем
                         // format fix: replace comma with dot
                         value = value.replaceAll(',', '.');
                         final parsed = double.tryParse(value);
                         if (parsed != null && parsed > 0) {
                           widget.onChanged(parsed.clamp(1, widget.originalSize));
                         }
                      },
                      onChanged: (value) {
                        // format fix: replace comma with dot
                        value = value.replaceAll(',', '.');
                        final parsed = double.tryParse(value);
                        if (parsed != null && parsed > 0) {
                          widget.onChanged(parsed.clamp(1, widget.originalSize));
                        }
                      },
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'из ${widget.originalSize.toStringAsFixed(1)} МБ',
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondary : Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                  thumbColor: AppColors.primary,
                  overlayColor: AppColors.primary.withOpacity(0.2),
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                ),
                child: Slider(
                  value: widget.value.clamp(1, widget.originalSize),
                  min: 1,
                  max: widget.originalSize > 1 ? widget.originalSize : 100,
                  onChanged: widget.onChanged,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '1 МБ',
                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMuted : Colors.grey),
                  ),
                  Text(
                    '${((1 - widget.value / widget.originalSize) * 100).toStringAsFixed(0)}% сжатие',
                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : Colors.grey.shade600),
                  ),
                  Text(
                    '${widget.originalSize.toStringAsFixed(0)} МБ',
                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMuted : Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Выпадающий список выбора формата
class FormatSelector extends StatelessWidget {
  final OutputFormat selectedFormat;
  final ValueChanged<OutputFormat> onChanged;
  
  const FormatSelector({
    super.key,
    required this.selectedFormat,
    required this.onChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Формат вывода',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: isDark ? AppColors.textPrimary : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade300),
          ),
          child: DropdownButton<OutputFormat>(
            value: selectedFormat,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: isDark ? AppColors.darkCard : Colors.white,
            icon: Icon(Icons.expand_more, color: isDark ? AppColors.textSecondary : Colors.grey),
            items: AppConstants.outputFormats.map((format) {
              return DropdownMenuItem<OutputFormat>(
                value: format,
                child: Text(
                  format.name,
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimary : Colors.black87,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ),
      ],
    );
  }
}

/// Выбор битрейта аудио
class AudioBitrateSelector extends StatelessWidget {
  final AudioBitrate selectedBitrate;
  final ValueChanged<AudioBitrate> onChanged;
  
  const AudioBitrateSelector({
    super.key,
    required this.selectedBitrate,
    required this.onChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Битрейт аудио',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: isDark ? AppColors.textPrimary : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: AppConstants.audioBitrates.map((bitrate) {
            final isSelected = bitrate.value == selectedBitrate.value;
            return GestureDetector(
              onTap: () => onChanged(bitrate),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withOpacity(0.15) : (isDark ? AppColors.darkSurface : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  bitrate.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppColors.primary : (isDark ? AppColors.textPrimary : Colors.black87),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Настройка разрешения видео
class ResolutionSelector extends StatefulWidget {
  final int? width;
  final int? height;
  final String scaleMode; // 'fit' или 'crop'
  final Function(int?, int?, String) onChanged;
  
  const ResolutionSelector({
    super.key,
    this.width,
    this.height,
    required this.scaleMode,
    required this.onChanged,
  });
  
  @override
  State<ResolutionSelector> createState() => _ResolutionSelectorState();
}

class _ResolutionSelectorState extends State<ResolutionSelector> {
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  bool _useOriginal = true;
  
  static const List<Map<String, int>> presets = [
    {'w': 1920, 'h': 1080},
    {'w': 1080, 'h': 1920},
    {'w': 1280, 'h': 720},
    {'w': 720, 'h': 1280},
    {'w': 1080, 'h': 1080},
    {'w': 640, 'h': 480},
  ];
  
  @override
  void initState() {
    super.initState();
    _widthController = TextEditingController(text: widget.width?.toString() ?? '');
    _heightController = TextEditingController(text: widget.height?.toString() ?? '');
    _useOriginal = widget.width == null && widget.height == null;
  }
  
  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }
  
  void _applyPreset(int w, int h) {
    setState(() {
      _useOriginal = false;
      _widthController.text = w.toString();
      _heightController.text = h.toString();
    });
    widget.onChanged(w, h, widget.scaleMode);
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Разрешение видео',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: isDark ? AppColors.textPrimary : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        // Оригинальное разрешение
        GestureDetector(
          onTap: () {
            setState(() => _useOriginal = true);
            widget.onChanged(null, null, widget.scaleMode);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _useOriginal ? AppColors.primary.withOpacity(0.15) : (isDark ? AppColors.darkSurface : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _useOriginal ? AppColors.primary : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
                width: _useOriginal ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _useOriginal ? Icons.radio_button_checked : Icons.radio_button_off,
                  size: 18,
                  color: _useOriginal ? AppColors.primary : (isDark ? AppColors.textMuted : Colors.grey),
                ),
                const SizedBox(width: 8),
                Text(
                  'Оригинальное',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _useOriginal ? FontWeight.w600 : FontWeight.normal,
                    color: _useOriginal ? AppColors.primary : (isDark ? AppColors.textPrimary : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Пресеты
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: presets.map((p) {
            final w = p['w']!;
            final h = p['h']!;
            final isSelected = !_useOriginal && widget.width == w && widget.height == h;
            return GestureDetector(
              onTap: () => _applyPreset(w, h),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withOpacity(0.15) : (isDark ? AppColors.darkSurface : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  '${w}x$h',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppColors.primary : (isDark ? AppColors.textPrimary : Colors.black87),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // Ручной ввод
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _widthController,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 13, color: isDark ? AppColors.textPrimary : Colors.black87),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  hintText: 'Ширина',
                  hintStyle: TextStyle(color: isDark ? AppColors.textMuted : Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onChanged: (v) {
                  setState(() => _useOriginal = false);
                  final w = int.tryParse(v);
                  final h = int.tryParse(_heightController.text);
                  widget.onChanged(w, h, widget.scaleMode);
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('×'),
            ),
            Expanded(
              child: TextField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 13, color: isDark ? AppColors.textPrimary : Colors.black87),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  hintText: 'Высота',
                  hintStyle: TextStyle(color: isDark ? AppColors.textMuted : Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onChanged: (v) {
                  setState(() => _useOriginal = false);
                  final w = int.tryParse(_widthController.text);
                  final h = int.tryParse(v);
                  widget.onChanged(w, h, widget.scaleMode);
                },
              ),
            ),
          ],
        ),
        if (!_useOriginal && widget.width != null && widget.height != null) ...[
          const SizedBox(height: 8),
          // Режим масштабирования
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.onChanged(widget.width, widget.height, 'fit'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.scaleMode == 'fit' ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: widget.scaleMode == 'fit' ? Border.all(color: AppColors.primary) : null,
                    ),
                    child: Text(
                      'Растянуть',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.scaleMode == 'fit' ? AppColors.primary : (isDark ? AppColors.textSecondary : Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.onChanged(widget.width, widget.height, 'crop'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.scaleMode == 'crop' ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: widget.scaleMode == 'crop' ? Border.all(color: AppColors.primary) : null,
                    ),
                    child: Text(
                      'Обрезать',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.scaleMode == 'crop' ? AppColors.primary : (isDark ? AppColors.textSecondary : Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
