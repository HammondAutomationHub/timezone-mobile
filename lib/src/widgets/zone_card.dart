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
    final metrics = AppMetrics.of(context);

    return Material(
      color: open ? AppColors.surface : AppColors.surfaceClosed,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: accent.withValues(alpha: 0.85)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          metrics.cardPadLeft,
          metrics.cardPadTop,
          metrics.cardPadRight,
          metrics.cardPadBottom,
        ),
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
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: metrics.lerp(2, 8),
                        ),
                        child: Icon(
                          Icons.drag_handle,
                          size: metrics.lerp(18, 24),
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                Tooltip(
                  message: 'Text color for ${zone.label}',
                  child: IconButton(
                    onPressed: onPickColor,
                    style: _cardButtonStyle(metrics),
                    icon: Container(
                      width: metrics.lerp(16, 22),
                      height: metrics.lerp(16, 22),
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
                    style: _cardButtonStyle(metrics),
                    icon: Icon(
                      Icons.close,
                      size: metrics.lerp(16, 20),
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: metrics.lerp(6, 12)),
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
            SizedBox(height: metrics.lerp(8, 14)),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  formatRelativeOffset(clock.relative),
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: metrics.meta,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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

ButtonStyle _cardButtonStyle(AppMetrics metrics) {
  final tap = metrics.iconTap;
  return IconButton.styleFrom(
    minimumSize: Size(tap, tap),
    fixedSize: Size(tap, tap),
    padding: EdgeInsets.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
  );
}
