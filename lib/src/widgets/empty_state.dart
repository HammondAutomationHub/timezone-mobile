import 'package:flutter/material.dart';

import '../logic/clock.dart';
import '../models/place.dart';
import '../theme/app_theme.dart';
import 'zone_flag.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.suggestions,
    required this.now,
    required this.onAdd,
    required this.onSearch,
    super.key,
  });

  final List<Place> suggestions;
  final DateTime now;
  final ValueChanged<Place> onAdd;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final metrics = AppMetrics(MediaQuery.sizeOf(context).width);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No places yet',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: metrics.headline,
            fontWeight: FontWeight.w600,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Pin a city or country to keep its local time on this device. '
          'The offset is measured from your clock, and daylight saving follows the IANA zone. '
          'Cards shift color outside local business hours, 9 AM to 5 PM.',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: metrics.body,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'SUGGESTED',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        for (final place in suggestions) ...[
          SuggestionTile(place: place, now: now, onAdd: () => onAdd(place)),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onSearch,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Search cities and countries'),
          ),
        ),
      ],
    );
  }
}

class SuggestionTile extends StatelessWidget {
  const SuggestionTile({
    required this.place,
    required this.now,
    required this.onAdd,
    super.key,
  });

  final Place place;
  final DateTime now;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final clock = ZoneClock.resolve(place.ianaId, now);
    final open = isWithinBusinessHours(clock.local);
    final accent = open ? AppColors.open : AppColors.closed;

    return Material(
      color: open ? AppColors.surface : AppColors.surfaceClosed,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent.withValues(alpha: 0.7)),
      ),
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ZoneFlag(countryCode: place.countryCode),
                        if (place.countryCode != null) const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            place.label,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${formatClock(clock.local, includeSeconds: false)} · ${formatRelativeOffset(clock.relative)}',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: AppMetrics(
                          MediaQuery.sizeOf(context).width,
                        ).meta,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      businessHoursLabel(clock.local),
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.add, color: AppColors.ink),
            ],
          ),
        ),
      ),
    );
  }
}
