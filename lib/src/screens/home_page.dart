import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/place_catalog.dart';
import '../install/install_prompt.dart';
import '../logic/clock.dart';
import '../models/place.dart';
import '../models/saved_zone.dart';
import '../theme/app_theme.dart';
import '../widgets/color_picker_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/zone_card.dart';
import 'add_place_page.dart';

class HomePage extends StatelessWidget {
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

  void _openAdd(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AddPlacePage(
          catalog: catalog,
          savedIds: zones.map((zone) => zone.id).toSet(),
          now: now,
          onAdd: onAdd,
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
    onColorChanged(zone, next);
  }

  void _remove(BuildContext context, SavedZone zone) {
    final index = zones.indexWhere((item) => item.id == zone.id);
    if (index < 0) return;
    onRemove(zone);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Removed ${zone.label}'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => onRestore(zone, index),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final deviceZone = now.timeZoneName;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = AppMetrics(constraints.maxWidth);
            final side = math.max(0.0, (constraints.maxWidth - 680) / 2);
            final pad = metrics.pagePadding;
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(side + pad, 12, side + 12, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'TIMEZONEMOBILE',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: metrics.lerp(11, 12),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: metrics.lerp(0.6, 1.6),
                                ),
                              ),
                            ),
                            const InstallButton(),
                            TextButton(
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
                            formatClock(now),
                            style: zoneTextStyle(
                              color: AppColors.ink,
                              size: metrics.localClock,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${formatDateLine(now)} · $deviceZone · ${formatGmtOffset(now.timeZoneOffset)}',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: metrics.meta,
                            height: 1.35,
                          ),
                        ),
                        if (!online) const _OfflineIndicator(),
                        const SizedBox(height: 22),
                      ],
                    ),
                  ),
                ),
                if (zones.isEmpty)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(side + pad, 0, side + pad, 28),
                    sliver: SliverToBoxAdapter(
                      child: EmptyState(
                        suggestions: catalog.starters,
                        now: now,
                        onAdd: onAdd,
                        onSearch: () => _openAdd(context),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(side + pad, 0, side + pad, 12),
                    sliver: SliverReorderableList(
                      itemCount: zones.length,
                      onReorder: onReorder,
                      itemBuilder: (context, index) {
                        final zone = zones[index];
                        final canReorder = zones.length > 1;
                        return Padding(
                          key: ValueKey(zone.id),
                          padding: EdgeInsets.only(
                            bottom: index == zones.length - 1 ? 0 : 12,
                          ),
                          child: canReorder
                              ? ReorderableDelayedDragStartListener(
                                  index: index,
                                  child: ZoneCard(
                                    zone: zone,
                                    now: now,
                                    countryCode: catalog.countryCodeFor(
                                      zone.id,
                                      zone.ianaId,
                                    ),
                                    reorderIndex: index,
                                    onPickColor: () => _pickColor(context, zone),
                                    onRemove: () => _remove(context, zone),
                                  ),
                                )
                              : ZoneCard(
                                  zone: zone,
                                  now: now,
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
                    padding: EdgeInsets.fromLTRB(side + pad, 4, side + pad, 24),
                    sliver: const SliverToBoxAdapter(
                      child: Text(
                        'Drag a handle to arrange the list. Business hours are 9 AM–5 PM in that place. Outside that window, the card shifts color.',
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
