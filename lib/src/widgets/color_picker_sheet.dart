import 'package:flutter/material.dart';

import '../models/saved_zone.dart';
import '../theme/app_theme.dart';

const _primaries = <(int, String)>[
  (0xFFFF0000, 'Red'),
  (0xFFFFFF00, 'Yellow'),
  (0xFF0000FF, 'Blue'),
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
  late double _saturation;
  late double _lightness;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialColor;
    final hsl = HSLColor.fromColor(Color(widget.initialColor));
    _hue = hsl.hue.isNaN ? 0 : hsl.hue;
    _saturation = hsl.saturation.isNaN ? 0 : hsl.saturation;
    _lightness = hsl.lightness;
  }

  void _select(int colorValue) {
    final hsl = HSLColor.fromColor(Color(colorValue));
    setState(() {
      _selected = colorValue;
      if (!hsl.hue.isNaN) _hue = hsl.hue;
      _saturation = hsl.saturation.isNaN ? 0 : hsl.saturation;
      _lightness = hsl.lightness;
    });
  }

  void _onHue(double hue) {
    setState(() {
      _hue = hue;
      // Gray has almost no saturation, so the first move on this slider
      // jumps to a vivid color instead of a barely visible tint.
      if (_saturation < 0.15) {
        _saturation = 1;
        _lightness = 0.5;
      }
      _applyHsl();
    });
  }

  void _onSaturation(double saturation) {
    setState(() {
      _saturation = saturation;
      _applyHsl();
    });
  }

  void _onLightness(double lightness) {
    setState(() {
      _lightness = lightness;
      _applyHsl();
    });
  }

  void _applyHsl() {
    _selected = HSLColor.fromAHSL(
      1,
      _hue,
      _saturation,
      _lightness,
    ).toColor().toARGB32();
  }

  @override
  Widget build(BuildContext context) {
    final preview = Color(_selected);
    return SafeArea(
      child: SingleChildScrollView(
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
              'Choose a primary color, or slide to any custom color. This colors the place name and clock.',
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
                        size: AppMetrics.of(context).placeName,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '9:41 AM',
                        style: zoneTextStyle(
                          color: preview,
                          size: AppMetrics.of(context).zoneClock,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _SectionLabel('Primary colors'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Swatch(
                  colorValue: SavedZone.defaultColorValue,
                  label: 'Neutral gray',
                  selected: _selected == SavedZone.defaultColorValue,
                  onTap: () => _select(SavedZone.defaultColorValue),
                ),
                for (final swatch in _primaries)
                  _Swatch(
                    colorValue: swatch.$1,
                    label: swatch.$2,
                    selected: _selected == swatch.$1,
                    onTap: () => _select(swatch.$1),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            const _SectionLabel('All colors'),
            const SizedBox(height: 4),
            _ColorSlider(
              label: 'Color',
              value: _hue.clamp(0, 360).toDouble(),
              max: 360,
              onChanged: _onHue,
              colors: const [
                Color(0xFFFF0000),
                Color(0xFFFFFF00),
                Color(0xFF00FF00),
                Color(0xFF00FFFF),
                Color(0xFF0000FF),
                Color(0xFFFF00FF),
                Color(0xFFFF0000),
              ],
            ),
            const SizedBox(height: 8),
            const _SectionLabel('Custom'),
            const SizedBox(height: 4),
            _ColorSlider(
              label: 'Saturation',
              value: _saturation.clamp(0, 1).toDouble(),
              max: 1,
              onChanged: _onSaturation,
              colors: [
                HSLColor.fromAHSL(1, _hue, 0, _lightness).toColor(),
                HSLColor.fromAHSL(1, _hue, 1, _lightness).toColor(),
              ],
            ),
            _ColorSlider(
              label: 'Lightness',
              value: _lightness.clamp(0, 1).toDouble(),
              max: 1,
              onChanged: _onLightness,
              colors: [
                const Color(0xFF000000),
                HSLColor.fromAHSL(1, _hue, _saturation, 0.5).toColor(),
                const Color(0xFFFFFFFF),
              ],
            ),
            const SizedBox(height: 8),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.colorValue,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final int colorValue;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color(colorValue),
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.ink : AppColors.line,
              width: selected ? 2.5 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorSlider extends StatelessWidget {
  const _ColorSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
    required this.colors,
  });

  final String label;
  final double value;
  final double max;
  final ValueChanged<double> onChanged;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      slider: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          SizedBox(
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(colors: colors),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: const SizedBox(height: 12, width: double.infinity),
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 12,
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                    thumbColor: AppColors.ink,
                    overlayColor: AppColors.ink.withValues(alpha: 0.12),
                  ),
                  child: Slider(value: value, max: max, onChanged: onChanged),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
