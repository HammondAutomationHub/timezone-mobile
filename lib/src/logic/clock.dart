import 'package:timezone/timezone.dart' as tz;

/// Local time in an IANA zone and how it compares with [instant].
final class ZoneClock {
  const ZoneClock({required this.local, required this.relative});

  final tz.TZDateTime local;

  /// Zone offset minus the device offset. Positive means the zone is ahead.
  final Duration relative;

  factory ZoneClock.resolve(String ianaId, DateTime instant) {
    final local = tz.TZDateTime.from(instant, tz.getLocation(ianaId));
    return ZoneClock(
      local: local,
      relative: local.timeZoneOffset - instant.timeZoneOffset,
    );
  }
}

/// Local wall time from 9:00 inclusive through 16:59.
bool isWithinBusinessHours(DateTime local) {
  return local.hour >= 9 && local.hour < 17;
}

String businessHoursLabel(DateTime local) {
  if (isWithinBusinessHours(local)) return 'Business hours';
  if (local.hour < 9) return 'Before 9 AM';
  return 'After 5 PM';
}

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Device-local instant for a schedule check: the calendar day of [now] at
/// [hour] and [minute].
///
/// [now] is the device clock. Pass the result to [ZoneClock.resolve] for each
/// saved place so every card shares one absolute instant. Daylight saving then
/// comes from the IANA zone rather than a fixed offset.
DateTime localScheduleInstant(DateTime now, int hour, int minute) {
  return DateTime(now.year, now.month, now.day, hour, minute);
}

String formatClock(DateTime time, {bool includeSeconds = true}) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.hour >= 12 ? 'PM' : 'AM';
  if (!includeSeconds) return '$hour:$minute $period';
  final second = time.second.toString().padLeft(2, '0');
  return '$hour:$minute:$second $period';
}

String formatDateLine(DateTime time) {
  final weekday = _weekdays[time.weekday - 1];
  final month = _months[time.month - 1];
  return '$weekday, $month ${time.day}';
}

String formatRelativeOffset(Duration difference) {
  final ahead = !difference.isNegative;
  final absolute = difference.abs();
  final hours = absolute.inHours;
  final minutes = absolute.inMinutes.remainder(60);
  if (hours == 0 && minutes == 0) return 'Same time as you';

  final parts = <String>[
    if (hours > 0) '${hours}h',
    if (minutes > 0) '${minutes}m',
  ].join(' ');
  return ahead ? '$parts ahead of you' : '$parts behind you';
}

String formatGmtOffset(Duration offset) {
  if (offset == Duration.zero) return 'GMT';
  final ahead = !offset.isNegative;
  final absolute = offset.abs();
  final hours = absolute.inHours;
  final minutes = absolute.inMinutes.remainder(60);
  final sign = ahead ? '+' : '\u2212';
  if (minutes == 0) return 'GMT$sign$hours';
  return 'GMT$sign$hours:${minutes.toString().padLeft(2, '0')}';
}
