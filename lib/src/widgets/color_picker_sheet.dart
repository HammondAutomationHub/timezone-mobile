import 'package:flutter/material.dart';

import '../models/saved_zone.dart';
import '../theme/app_theme.dart';

const _swatches = <(int, String)>[
  (SavedZone.defaultColorValue, 'Neutral gray'),
  (0xFFE8EEF3, 'White'),
  (0xFF9BB6E0, 'Blue'),
  (0xFF8FCBB0, 'Green'),
  (0xFFE0A36A, 'Amber'),
  (0xFFE09A9A, 'Rose'),
  (0xFFD7B0E0, 'Lilac'),
  (0xFF8FD0D0, 'Teal'),
  (0xFFF0D58C, 'Sand'),
  (0xFFC8B8A8, 'Stone'),
];

Future<int?> showZoneColorPicker({
  required BuildContext context,
  required int current,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (context) => _ZoneColorPicker(initialColor: current),
  );
}

class _ZoneColorPicker extends StatefulWidget {
  const _ZoneColorPicker({required this.initialColor});

  final int initialColor;

  @override
  State<_ZoneColorPicker> createState() => _ZoneColorPickerState();
}

class _ZoneColorPickerState extends State<_ZoneColorPicker> {
  late int _selected;
  late double _hue;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialColor;
    final hue = HSLColor.fromColor(Color(widget.initialColor)).hue;
    _hue = hue.isNaN ? 0 : hue;
  }

  void _select(int colorValue) {
    final hue = HSLColor.fromColor(Color(colorValue)).hue;
    setState(() {
      _selected = colorValue;
      if (!hue.isNaN) _hue = hue;
    });
  }

  void _onHue(double hue) {
    final color = HSLColor.fromAHSL(1, hue, 0.38, 0.74).toColor();
    setState(() {
      _hue = hue;
      _selected = color.toARGB32();
    });
  }

  @override
  Widget build(BuildContext context) {
    final preview = Color(_selected);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Text color',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Used for this place’s name and clock. Default is neutral gray.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Place name',
                      style: zoneTextStyle(
                        color: preview,
                        size: 18,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '9:41:02 AM',
                      style: zoneTextStyle(color: preview, size: 36),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final swatch in _swatches)
                  Tooltip(
                    message: swatch.$2,
                    child: InkWell(
                      onTap: () => _select(swatch.$1),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(swatch.$1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selected == swatch.$1
                                ? AppColors.ink
                                : AppColors.line,
                            width: _selected == swatch.$1 ? 2 : 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Semantics(
              label: 'Custom hue',
              child: Slider(
                value: _hue.clamp(0, 360).toDouble(),
                max: 360,
                activeColor: AppColors.ink,
                onChanged: _onHue,
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () => _select(SavedZone.defaultColorValue),
                  child: const Text('Neutral gray'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(_selected),
                  child: const Text('Use this color'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
