import 'package:flutter/material.dart';

import '../logic/clock.dart';
import '../models/saved_zone.dart';
import '../theme/app_theme.dart';
import 'zone_flag.dart';

class ZoneCard extends StatelessWidget {
  const ZoneCard({
    required this.zone,
    required this.now,
    required this.onPickColor,
    required this.onRemove,
    this.countryCode,
    this.reorderIndex,
    super.key,
  });

  final SavedZone zone;
  final DateTime now;
  final VoidCallback onPickColor;
  final VoidCallback onRemove;
  final String? countryCode;
  final int? reorderIndex;

  @override
  Widget build(BuildContext context) {
    final clock = ZoneClock.resolve(zone.ianaId, now);
    final open = isWithinBusinessHours(clock.local);
    final accent = open ? AppColors.open : AppColors.closed;
    final textColor = Color(zone.colorValue);
    final metrics = AppMetrics(MediaQuery.sizeOf(context).width);

    return Material(
      color: open ? AppColors.surface : AppColors.surfaceClosed,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: accent.withValues(alpha: 0.85)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ZoneFlag(countryCode: countryCode),
                          if (countryCode != null) const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              zone.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: zoneTextStyle(
                                color: textColor,
                                size: metrics.placeName,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${zone.subtitle} · ${clock.local.timeZoneName} · ${formatGmtOffset(clock.local.timeZoneOffset)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: metrics.meta,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (reorderIndex != null)
                  ReorderableDragStartListener(
                    index: reorderIndex!,
                    child: Tooltip(
                      message: 'Drag to rearrange ${zone.label}',
                      child: const Padding(
                        padding: EdgeInsets.fromLTRB(4, 10, 4, 10),
                        child: Icon(Icons.drag_handle, color: AppColors.muted),
                      ),
                    ),
                  ),
                Tooltip(
                  message: 'Text color for ${zone.label}',
                  child: IconButton(
                    onPressed: onPickColor,
                    visualDensity: VisualDensity.compact,
                    icon: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: textColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.line),
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Remove ${zone.label}',
                  child: IconButton(
                    onPressed: onRemove,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, color: AppColors.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatClock(clock.local, includeSeconds: false),
                style: zoneTextStyle(
                  color: textColor,
                  size: metrics.zoneClock,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              formatDateLine(clock.local),
              style: TextStyle(color: AppColors.muted, fontSize: metrics.meta),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatRelativeOffset(clock.relative),
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: metrics.meta,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Text(
                      businessHoursLabel(clock.local),
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
