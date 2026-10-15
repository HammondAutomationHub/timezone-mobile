import 'package:flutter/material.dart';

import '../logic/clock.dart';
import '../models/saved_zone.dart';
import '../theme/app_theme.dart';

class ZoneCard extends StatelessWidget {
  const ZoneCard({
    required this.zone,
    required this.now,
    required this.onPickColor,
    required this.onRemove,
    super.key,
  });

  final SavedZone zone;
  final DateTime now;
  final VoidCallback onPickColor;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final clock = ZoneClock.resolve(zone.ianaId, now);
    final open = isWithinBusinessHours(clock.local);
    final accent = open ? AppColors.open : AppColors.closed;
    final textColor = Color(zone.colorValue);

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
                      Text(
                        zone.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: zoneTextStyle(
                          color: textColor,
                          size: 18,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${zone.subtitle} · ${clock.local.timeZoneName} · ${formatGmtOffset(clock.local.timeZoneOffset)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
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
            Text(
              formatClock(clock.local),
              style: zoneTextStyle(color: textColor, size: 36),
            ),
            const SizedBox(height: 6),
            Text(
              formatDateLine(clock.local),
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatRelativeOffset(clock.relative),
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
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
