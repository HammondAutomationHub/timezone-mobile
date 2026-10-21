import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../data/place_catalog.dart';
import '../install/install_prompt.dart';
import '../logic/clock.dart';
import '../models/place.dart';
import '../models/saved_zone.dart';
import '../theme/app_theme.dart';
import '../widgets/color_picker_sheet.dart';
import '../widgets/ellipsis_line.dart';
import '../widgets/empty_state.dart';
import '../widgets/zone_card.dart';
import 'add_place_page.dart';

/// Short git SHA from `--dart-define=BUILD_ID`. Local runs and tests show "dev".
const _buildId = String.fromEnvironment('BUILD_ID', defaultValue: 'dev');

class HomePage extends StatefulWidget {
  const HomePage({
    required this.now,
    required this.online,
    required this.zones,
    required this.catalog,
    required this.onAdd,
    required this.onColorChanged,
    required this.onRemove,
    required this.onRestore,
    required this.onReorder,
    super.key,
  });

  final DateTime now;
  final bool online;
  final List<SavedZone> zones;
  final PlaceCatalog catalog;
  final ValueChanged<Place> onAdd;
  final void Function(SavedZone zone, int colorValue) onColorChanged;
  final ValueChanged<SavedZone> onRemove;
  final void Function(SavedZone zone, int index) onRestore;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _hour = TextEditingController();
  final _minute = TextEditingController();
  var _scheduleEnabled = false;
  DayPeriod? _period;
  TimeOfDay? _schedule;
  String? _scheduleError;

  @override
  void dispose() {
    _hour.dispose();
    _minute.dispose();
    super.dispose();
  }

  void _openAdd(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AddPlacePage(
          catalog: widget.catalog,
          savedIds: widget.zones.map((zone) => zone.id).toSet(),
          now: widget.now,
          onAdd: widget.onAdd,
        ),
      ),
    );
  }

  Future<void> _pickColor(BuildContext context, SavedZone zone) async {
    final next = await showZoneColorPicker(
      context: context,
      current: zone.colorValue,
    );
    if (!context.mounted || next == null || next == zone.colorValue) return;
    widget.onColorChanged(zone, next);
  }

  void _remove(BuildContext context, SavedZone zone) {
    final index = widget.zones.indexWhere((item) => item.id == zone.id);
    if (index < 0) return;
    widget.onRemove(zone);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Removed ${zone.label}'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => widget.onRestore(zone, index),
          ),
        ),
      );
  }

  void _applyParsed() {
    if (!_scheduleEnabled) {
      _schedule = null;
      _scheduleError = null;
      return;
    }
    final hourText = _hour.text.trim();
    final minuteText = _minute.text.trim();
    if (hourText.isEmpty || minuteText.isEmpty || _period == null) {
      _schedule = null;
      _scheduleError = null;
      return;
    }
    final hour = int.tryParse(hourText);
    final minute = int.tryParse(minuteText);
    if (hour == null || hour < 1 || hour > 12) {
      _schedule = null;
      _scheduleError = 'Enter an hour from 1 to 12.';
      return;
    }
    if (minute == null || minute < 0 || minute > 59) {
      _schedule = null;
      _scheduleError = 'Enter minutes from 0 to 59.';
      return;
    }
    final hour24 = _period == DayPeriod.pm ? (hour % 12) + 12 : hour % 12;
    _schedule = TimeOfDay(hour: hour24, minute: minute);
    _scheduleError = null;
  }

  void _recomputeSchedule() => setState(_applyParsed);

  void _togglePeriod(DayPeriod period) {
    setState(() {
      _period = _period == period ? null : period;
      _applyParsed();
    });
  }

  void _setScheduleEnabled(bool enabled) {
    if (enabled) {
      // Minute starts at 00 so only the hour (and AM/PM) need to be chosen.
      _minute.text = '00';
    }
    setState(() {
      _scheduleEnabled = enabled;
      if (!enabled) {
        _period = null;
        _schedule = null;
        _scheduleError = null;
      } else {
        _applyParsed();
      }
    });
    if (!enabled) {
      _hour.clear();
      _minute.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = widget.now;
    final zones = widget.zones;
    final catalog = widget.catalog;
    final online = widget.online;
    final schedule = _scheduleEnabled ? _schedule : null;
    final cardInstant = schedule == null
        ? now
        : localScheduleInstant(now, schedule.hour, schedule.minute);
    final deviceZone = now.timeZoneName;
    final appliedLabel = schedule == null
        ? null
        : formatClock(cardInstant, includeSeconds: false);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = AppMetrics(
              constraints.maxWidth,
              height: constraints.maxHeight,
            );
            final pad = metrics.pagePadding;
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 12, pad, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: EllipsisLine(
                                      text: 'TIMEZONEMOBILE',
                                      style: TextStyle(
                                        color: AppColors.muted,
                                        fontSize: metrics.lerp(11, 12),
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: metrics.lerp(0.4, 1.2),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: metrics.lerp(4, 6)),
                                  Text(
                                    _buildId,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      color: AppColors.faint,
                                      fontSize: metrics.lerp(9, 10),
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const InstallButton(),
                            TextButton(
                              style: _shrinkButtonStyle,
                              onPressed: () => _openAdd(context),
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your time',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formatClock(now, includeSeconds: false),
                            style: zoneTextStyle(
                              color: AppColors.ink,
                              size: metrics.localClock,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        EllipsisLine(
                          text:
                              '${formatDateLine(now)} · $deviceZone · ${formatGmtOffset(now.timeZoneOffset)}',
                          maxLines: 3,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: metrics.meta,
                            height: 1.35,
                          ),
                        ),
                        SizedBox(height: metrics.lerp(12, 16)),
                        _ZeroMinWidth(
                          child: _CheckSchedule(
                            enabled: _scheduleEnabled,
                            hour: _hour,
                            minute: _minute,
                            period: _period,
                            appliedLabel: appliedLabel,
                            error: _scheduleError,
                            onEnabled: _setScheduleEnabled,
                            onChanged: _recomputeSchedule,
                            onPeriod: _togglePeriod,
                          ),
                        ),
                        if (!online) const _OfflineIndicator(),
                        SizedBox(height: metrics.sectionGap),
                      ],
                    ),
                  ),
                ),
                if (zones.isEmpty)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(pad, 0, pad, 28),
                    sliver: SliverToBoxAdapter(
                      child: EmptyState(
                        suggestions: catalog.starters,
                        now: now,
                        onAdd: widget.onAdd,
                        onSearch: () => _openAdd(context),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(pad, 0, pad, 12),
                    sliver: SliverReorderableList(
                      itemCount: zones.length,
                      onReorder: widget.onReorder,
                      itemBuilder: (context, index) {
                        final zone = zones[index];
                        final canReorder = zones.length > 1;
                        return Padding(
                          key: ValueKey(zone.id),
                          padding: EdgeInsets.only(
                            bottom: index == zones.length - 1
                                ? 0
                                : metrics.cardGap,
                          ),
                          child: canReorder
                              ? ReorderableDelayedDragStartListener(
                                  index: index,
                                  child: ZoneCard(
                                    zone: zone,
                                    now: cardInstant,
                                    countryCode: catalog.countryCodeFor(
                                      zone.id,
                                      zone.ianaId,
                                    ),
                                    reorderIndex: index,
                                    onPickColor: () =>
                                        _pickColor(context, zone),
                                    onRemove: () => _remove(context, zone),
                                  ),
                                )
                              : ZoneCard(
                                  zone: zone,
                                  now: cardInstant,
                                  countryCode: catalog.countryCodeFor(
                                    zone.id,
                                    zone.ianaId,
                                  ),
                                  onPickColor: () => _pickColor(context, zone),
                                  onRemove: () => _remove(context, zone),
                                ),
                        );
                      },
                    ),
                  ),
                if (zones.isNotEmpty)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(pad, 4, pad, 24),
                    sliver: const SliverToBoxAdapter(
                      child: Text(
                        'Drag a handle to arrange the list. Business hours are 9 AM–5 PM in that place. Outside that window, the card shifts color.',
                        softWrap: true,
                        style: TextStyle(
                          color: AppColors.faint,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

const _shrinkButtonStyle = ButtonStyle(
  minimumSize: WidgetStatePropertyAll(Size.zero),
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  visualDensity: VisualDensity.compact,
  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 6)),
);

class _CheckSchedule extends StatelessWidget {
  const _CheckSchedule({
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.period,
    required this.appliedLabel,
    required this.error,
    required this.onEnabled,
    required this.onChanged,
    required this.onPeriod,
  });

  final bool enabled;
  final TextEditingController hour;
  final TextEditingController minute;
  final DayPeriod? period;
  final String? appliedLabel;
  final String? error;
  final ValueChanged<bool> onEnabled;
  final VoidCallback onChanged;
  final ValueChanged<DayPeriod> onPeriod;

  @override
  Widget build(BuildContext context) {
    final metrics = AppMetrics.of(context);
    final note = !enabled
        ? null
        : error ??
              (appliedLabel == null
                  ? 'Blank keeps the current time in each place.'
                  : 'Saved places show $appliedLabel today.');
    final noteColor = error == null
        ? AppColors.faint
        : Theme.of(context).colorScheme.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              key: const Key('check-schedule-toggle'),
              value: enabled,
              onChanged: (value) => onEnabled(value ?? false),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: AppColors.ink,
              checkColor: AppColors.background,
              side: const BorderSide(color: AppColors.muted, width: 1.5),
            ),
            Flexible(
              child: GestureDetector(
                onTap: () => onEnabled(!enabled),
                child: const Text(
                  'Check schedule',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
        if (enabled) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _ScheduleField(
                  fieldKey: const Key('check-schedule-hour'),
                  controller: hour,
                  hint: 'Hour',
                  applied: appliedLabel != null,
                  onChanged: onChanged,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  ':',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: _ScheduleField(
                  fieldKey: const Key('check-schedule-minute'),
                  controller: minute,
                  hint: 'Minute',
                  applied: appliedLabel != null,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PeriodChoice(
                  key: const Key('check-schedule-am'),
                  label: 'AM',
                  selected: period == DayPeriod.am,
                  onTap: () => onPeriod(DayPeriod.am),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PeriodChoice(
                  key: const Key('check-schedule-pm'),
                  label: 'PM',
                  selected: period == DayPeriod.pm,
                  onTap: () => onPeriod(DayPeriod.pm),
                ),
              ),
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: 6),
            Text(
              note,
              softWrap: true,
              style: TextStyle(
                color: noteColor,
                fontSize: metrics.lerp(11, 12),
                height: 1.35,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _ScheduleField extends StatelessWidget {
  const _ScheduleField({
    required this.fieldKey,
    required this.controller,
    required this.hint,
    required this.applied,
    required this.onChanged,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String hint;
  final bool applied;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final borderColor = applied
        ? AppColors.ink.withValues(alpha: 0.55)
        : AppColors.line;
    return TextField(
      key: fieldKey,
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      enableSuggestions: false,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.ink),
        ),
      ),
      onChanged: (_) => onChanged(),
    );
  }
}

class _PeriodChoice extends StatelessWidget {
  const _PeriodChoice({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.ink.withValues(alpha: 0.14)
          : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selected ? AppColors.ink : AppColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ZeroMinWidth extends SingleChildRenderObjectWidget {
  const _ZeroMinWidth({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderZeroMinWidth();
}

class _RenderZeroMinWidth extends RenderProxyBox {
  @override
  double computeMinIntrinsicWidth(double height) => 0;
}

class _OfflineIndicator extends StatelessWidget {
  const _OfflineIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      key: Key('offline-indicator'),
      padding: EdgeInsets.only(top: 14),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, size: 16, color: AppColors.muted),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline · clocks keep running on this device',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
