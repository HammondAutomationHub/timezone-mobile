import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone_mobile/src/logic/clock.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('formats clocks, dates, and offsets', () {
    expect(formatClock(DateTime(2026, 1, 1, 0, 5, 9)), '12:05:09 AM');
    expect(formatClock(DateTime(2026, 1, 1, 12)), '12:00:00 PM');
    expect(formatClock(DateTime(2026, 1, 1, 15, 4, 5)), '3:04:05 PM');
    expect(
      formatClock(DateTime(2026, 1, 1, 15, 4, 5), includeSeconds: false),
      '3:04 PM',
    );
    expect(formatDateLine(DateTime(2026, 10, 15)), 'Thursday, Oct 15');

    expect(formatRelativeOffset(Duration.zero), 'Same time as you');
    expect(
      formatRelativeOffset(const Duration(hours: 5, minutes: 30)),
      '5h 30m ahead of you',
    );
    expect(
      formatRelativeOffset(const Duration(minutes: -45)),
      '45m behind you',
    );
    expect(formatRelativeOffset(const Duration(hours: -2)), '2h behind you');

    expect(formatGmtOffset(Duration.zero), 'GMT');
    expect(formatGmtOffset(const Duration(hours: 8)), 'GMT+8');
    expect(formatGmtOffset(const Duration(hours: -7)), 'GMT\u22127');
    expect(formatGmtOffset(const Duration(hours: 5, minutes: 30)), 'GMT+5:30');
    expect(
      formatGmtOffset(const Duration(hours: -3, minutes: -30)),
      'GMT\u22123:30',
    );
  });

  test('business hours run from 9 AM through 4:59 PM', () {
    expect(isWithinBusinessHours(DateTime(2026, 1, 1, 9)), isTrue);
    expect(isWithinBusinessHours(DateTime(2026, 1, 1, 16, 59)), isTrue);
    expect(isWithinBusinessHours(DateTime(2026, 1, 1, 17)), isFalse);
    expect(isWithinBusinessHours(DateTime(2026, 1, 1, 8, 59)), isFalse);
    expect(businessHoursLabel(DateTime(2026, 1, 1, 9)), 'Business hours');
    expect(businessHoursLabel(DateTime(2026, 1, 1, 8, 59)), 'Before 9 AM');
    expect(businessHoursLabel(DateTime(2026, 1, 1, 17)), 'After 5 PM');
  });

  test('resolves zone time against the same instant', () {
    final instant = DateTime.utc(2026, 7, 15, 12);

    final tokyo = ZoneClock.resolve('Asia/Tokyo', instant);
    expect(tokyo.local.hour, 21);
    expect(tokyo.relative, const Duration(hours: 9));
    expect(businessHoursLabel(tokyo.local), 'After 5 PM');

    final california = ZoneClock.resolve('America/Los_Angeles', instant);
    expect(california.local.hour, 5);
    expect(california.relative, const Duration(hours: -7));
    expect(businessHoursLabel(california.local), 'Before 9 AM');
  });

  test('Los Angeles moves an hour between winter and summer', () {
    final losAngeles = tz.getLocation('America/Los_Angeles');
    final winter = tz.TZDateTime(losAngeles, 2026, 1, 15, 12);
    final summer = tz.TZDateTime(losAngeles, 2026, 7, 15, 12);
    expect(winter.timeZoneOffset, const Duration(hours: -8));
    expect(summer.timeZoneOffset, const Duration(hours: -7));
    expect(winter.timeZoneName, 'PST');
    expect(summer.timeZoneName, 'PDT');
  });

  test('starter zones that do not observe DST keep a fixed offset', () {
    const expected = {
      'Asia/Kuching': Duration(hours: 8),
      'Asia/Singapore': Duration(hours: 8),
      'Asia/Tokyo': Duration(hours: 9),
      'Asia/Jakarta': Duration(hours: 7),
    };
    for (final entry in expected.entries) {
      final location = tz.getLocation(entry.key);
      final winter = tz.TZDateTime(location, 2026, 1, 15, 12);
      final summer = tz.TZDateTime(location, 2026, 7, 15, 12);
      expect(winter.timeZoneOffset, entry.value, reason: entry.key);
      expect(summer.timeZoneOffset, entry.value, reason: entry.key);
    }
  });
}
