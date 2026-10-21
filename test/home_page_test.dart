import 'package:country_flags/country_flags.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone_mobile/src/data/place_catalog.dart';
import 'package:timezone_mobile/src/logic/clock.dart';
import 'package:timezone_mobile/src/models/place.dart';
import 'package:timezone_mobile/src/models/saved_zone.dart';
import 'package:timezone_mobile/src/screens/add_place_page.dart';
import 'package:timezone_mobile/src/screens/home_page.dart';
import 'package:timezone_mobile/src/theme/app_theme.dart';
import 'package:timezone_mobile/src/widgets/zone_card.dart';

void main() {
  late PlaceCatalog catalog;

  setUpAll(() {
    tzdata.initializeTimeZones();
    catalog = PlaceCatalog.build();
  });

  Future<void> pumpHome(
    WidgetTester tester, {
    required List<SavedZone> zones,
    bool online = true,
    Size size = const Size(1200, 2400),
    DateTime? now,
    ValueChanged<Place>? onAdd,
    void Function(SavedZone zone, int colorValue)? onColorChanged,
    ValueChanged<SavedZone>? onRemove,
    void Function(SavedZone zone, int index)? onRestore,
    void Function(int oldIndex, int newIndex)? onReorder,
  }) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    return tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: HomePage(
          now: now ?? DateTime.utc(2026, 7, 15, 12),
          online: online,
          zones: zones,
          catalog: catalog,
          onAdd: onAdd ?? (_) {},
          onColorChanged: onColorChanged ?? (_, _) {},
          onRemove: onRemove ?? (_) {},
          onRestore: onRestore ?? (_, _) {},
          onReorder: onReorder ?? (_, _) {},
        ),
      ),
    );
  }

  testWidgets('empty state offers the starter set and adds on tap', (
    tester,
  ) async {
    Place? added;
    await pumpHome(tester, zones: const [], onAdd: (place) => added = place);

    expect(find.text('No places yet'), findsOneWidget);
    expect(find.text('California'), findsOneWidget);
    expect(find.byType(CountryFlag), findsWidgets);
    expect(find.text('Malaysia'), findsOneWidget);
    expect(find.text('Japan'), findsOneWidget);
    expect(find.text('Indonesia'), findsOneWidget);
    expect(find.text('Singapore'), findsOneWidget);
    expect(
      find.text('Offline · clocks keep running on this device'),
      findsNothing,
    );

    await tester.tap(find.text('California'));
    expect(added?.ianaId, 'America/Los_Angeles');
    expect(added?.label, 'California');
  });

  testWidgets('shows a quiet offline line when the network is down', (
    tester,
  ) async {
    await pumpHome(tester, zones: const [], online: false);
    expect(find.byKey(const Key('offline-indicator')), findsOneWidget);
    expect(find.textContaining('Offline'), findsOneWidget);
  });

  testWidgets('your time shows hours and minutes without seconds', (
    tester,
  ) async {
    final now = DateTime(2026, 1, 1, 15, 4, 5);
    await pumpHome(tester, zones: const [], now: now);

    expect(find.text('Your time'), findsOneWidget);
    expect(find.text('3:04 PM'), findsOneWidget);
    expect(find.text('3:04:05 PM'), findsNothing);
    expect(find.textContaining('Thursday, Jan 1'), findsOneWidget);
  });

  testWidgets('saved zones show local time, offset, and business hours', (
    tester,
  ) async {
    await pumpHome(
      tester,
      zones: const [
        SavedZone(
          ianaId: 'Asia/Tokyo',
          label: 'Japan',
          subtitle: 'Tokyo',
          colorValue: SavedZone.defaultColorValue,
        ),
        SavedZone(
          ianaId: 'America/Los_Angeles',
          label: 'California',
          subtitle: 'Los Angeles',
          colorValue: SavedZone.defaultColorValue,
        ),
      ],
    );

    expect(find.text('9:00 PM'), findsOneWidget);
    expect(find.text('9h ahead of you'), findsOneWidget);
    expect(find.text('After 5 PM'), findsOneWidget);
    expect(find.text('5:00 AM'), findsOneWidget);
    expect(find.text('7h behind you'), findsOneWidget);
    expect(find.text('Before 9 AM'), findsOneWidget);
    expect(find.textContaining('9 AM–5 PM'), findsOneWidget);
  });

  testWidgets('search adds a place and remove can be undone', (tester) async {
    Place? added;
    SavedZone? removed;
    SavedZone? restored;
    await pumpHome(
      tester,
      zones: const [
        SavedZone(
          ianaId: 'Asia/Tokyo',
          label: 'Japan',
          subtitle: 'Tokyo',
          colorValue: 0xFF9BB6E0,
        ),
      ],
      onAdd: (place) => added = place,
      onRemove: (zone) => removed = zone,
      onRestore: (zone, _) => restored = zone,
    );

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'malaysia');
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byType(AddPlacePage),
        matching: find.text('Malaysia'),
      ),
    );
    expect(added?.id, 'Asia/Kuala_Lumpur');
    expect(added?.ianaId, 'Asia/Singapore');

    Navigator.of(tester.element(find.byType(AddPlacePage))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Remove Japan'));
    expect(removed?.ianaId, 'Asia/Tokyo');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    expect(restored?.label, 'Japan');
  });

  testWidgets('color picker updates the zone color', (tester) async {
    int? color;
    await pumpHome(
      tester,
      zones: const [
        SavedZone(
          ianaId: 'Asia/Tokyo',
          label: 'Japan',
          subtitle: 'Tokyo',
          colorValue: SavedZone.defaultColorValue,
        ),
      ],
      onColorChanged: (_, next) => color = next,
    );

    await tester.tap(find.byTooltip('Text color for Japan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Blue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use this color'));
    await tester.pumpAndSettle();
    expect(color, 0xFF0000FF);
  });

  testWidgets('color slider commits a custom color', (tester) async {
    int? color;
    await pumpHome(
      tester,
      zones: const [
        SavedZone(
          ianaId: 'Asia/Tokyo',
          label: 'Japan',
          subtitle: 'Tokyo',
          colorValue: SavedZone.defaultColorValue,
        ),
      ],
      onColorChanged: (_, next) => color = next,
    );

    await tester.tap(find.byTooltip('Text color for Japan'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Slider).first, const Offset(160, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use this color'));
    await tester.pumpAndSettle();
    expect(color, isNotNull);
    expect(color, isNot(SavedZone.defaultColorValue));
  });

  testWidgets('clocks fit a narrow phone width', (tester) async {
    await pumpHome(tester, size: const Size(320, 640), zones: const []);
    expect(find.text('No places yet'), findsOneWidget);
    expect(find.text('California'), findsOneWidget);

    await pumpHome(
      tester,
      size: const Size(320, 640),
      zones: const [
        SavedZone(
          ianaId: 'America/Los_Angeles',
          label: 'California',
          subtitle: 'Los Angeles',
          colorValue: SavedZone.defaultColorValue,
        ),
        SavedZone(
          ianaId: 'Asia/Tokyo',
          label: 'Japan',
          subtitle: 'Tokyo',
          colorValue: SavedZone.defaultColorValue,
        ),
      ],
    );

    expect(find.text('California'), findsOneWidget);
    expect(find.text('5:00 AM'), findsOneWidget);
    expect(find.text('9:00 PM'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpHome(
      tester,
      size: const Size(280, 360),
      zones: const [
        SavedZone(
          ianaId: 'America/Los_Angeles',
          label: 'California',
          subtitle: 'Los Angeles',
          colorValue: SavedZone.defaultColorValue,
        ),
        SavedZone(
          ianaId: 'Asia/Tokyo',
          label: 'Japan',
          subtitle: 'Tokyo',
          colorValue: SavedZone.defaultColorValue,
        ),
      ],
    );
    expect(find.text('California'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpHome(
      tester,
      size: const Size(220, 640),
      zones: const [
        SavedZone(
          ianaId: 'America/Los_Angeles',
          label: 'California',
          subtitle: 'Los Angeles',
          colorValue: SavedZone.defaultColorValue,
        ),
      ],
    );
    expect(find.text('TIMEZONEMOBILE'), findsOneWidget);
    expect(find.text('dev'), findsOneWidget);
    expect(find.text('California'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dragging a handle reports the new tile order', (tester) async {
    int? oldIndex;
    int? newIndex;
    await pumpHome(
      tester,
      zones: const [
        SavedZone(
          ianaId: 'Asia/Tokyo',
          label: 'Japan',
          subtitle: 'Tokyo',
          colorValue: SavedZone.defaultColorValue,
        ),
        SavedZone(
          ianaId: 'America/Los_Angeles',
          label: 'California',
          subtitle: 'Los Angeles',
          colorValue: SavedZone.defaultColorValue,
        ),
      ],
      onReorder: (old, next) {
        oldIndex = old;
        newIndex = next;
      },
    );

    expect(find.byTooltip('Drag to rearrange Japan'), findsOneWidget);
    final handle = find.byTooltip('Drag to rearrange Japan');
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.moveBy(const Offset(0, 280));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 80));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(oldIndex, 0);
    expect(newIndex, greaterThan(0));
  });

  testWidgets('scrolling from the page margin moves the zone list', (
    tester,
  ) async {
    await pumpHome(
      tester,
      size: const Size(1400, 520),
      zones: [
        for (var index = 0; index < 8; index++)
          SavedZone(
            id: 'place-$index',
            ianaId: 'America/Los_Angeles',
            label: 'Place $index',
            subtitle: 'Test',
            colorValue: SavedZone.defaultColorValue,
          ),
      ],
    );

    final position = tester
        .stateList<ScrollableState>(find.byType(Scrollable))
        .map((state) => state.position)
        .firstWhere(
          (item) => item.axis == Axis.vertical && item.maxScrollExtent > 0,
        );
    expect(position.maxScrollExtent, greaterThan(0));

    await tester.sendEventToBinding(
      const PointerScrollEvent(
        position: Offset(16, 240),
        scrollDelta: Offset(0, 280),
      ),
    );
    await tester.pump();

    expect(position.pixels, greaterThan(0));
  });

  testWidgets(
    'checking a local time converts a saved zone and unchecking restores the live clock',
    (tester) async {
      final now = DateTime(2026, 7, 15, 8, 15);
      const zone = SavedZone(
        ianaId: 'Asia/Tokyo',
        label: 'Japan',
        subtitle: 'Tokyo',
        colorValue: SavedZone.defaultColorValue,
      );
      await pumpHome(
        tester,
        size: const Size(280, 640),
        now: now,
        zones: const [zone],
      );

      final live = ZoneClock.resolve(zone.ianaId, now);
      final liveLabel = formatClock(live.local, includeSeconds: false);
      final toggle = find.byKey(const Key('check-schedule-toggle'));
      expect(_zoneText(liveLabel), findsOneWidget);
      expect(find.text('Check schedule'), findsOneWidget);
      expect(tester.widget<Checkbox>(toggle).value, isFalse);
      expect(find.byKey(const Key('check-schedule-hour')), findsNothing);
      expect(find.text('8:15 AM'), findsWidgets);
      expect(find.text('8:15:00 AM'), findsNothing);

      String fieldText(Key key) {
        return tester.widget<TextField>(find.byKey(key)).controller?.text ??
            '';
      }

      await tester.tap(toggle);
      await tester.pump();
      expect(tester.widget<Checkbox>(toggle).value, isTrue);
      expect(fieldText(const Key('check-schedule-minute')), '00');
      expect(fieldText(const Key('check-schedule-hour')), isEmpty);
      expect(_zoneText(liveLabel), findsOneWidget);
      expect(
        find.text('Blank keeps the current time in each place.'),
        findsOneWidget,
      );

      await tester.enterText(find.byKey(const Key('check-schedule-hour')), '3');
      await tester.pump();
      expect(fieldText(const Key('check-schedule-minute')), '00');
      expect(_zoneText(liveLabel), findsOneWidget);

      await tester.tap(find.byKey(const Key('check-schedule-pm')));
      await tester.pump();

      final scheduled = localScheduleInstant(now, 15, 0);
      final tokyo = ZoneClock.resolve(zone.ianaId, scheduled);
      final scheduledLabel = formatClock(tokyo.local, includeSeconds: false);
      expect(scheduledLabel, isNot(liveLabel));
      expect(_zoneText(scheduledLabel), findsOneWidget);
      expect(_zoneText(liveLabel), findsNothing);
      expect(_zoneText(formatDateLine(tokyo.local)), findsOneWidget);
      expect(_zoneText(businessHoursLabel(tokyo.local)), findsOneWidget);
      expect(find.text('Saved places show 3:00 PM today.'), findsOneWidget);
      expect(find.text('8:15 AM'), findsOneWidget);
      expect(find.textContaining(RegExp(r'\d:\d{2}:\d{2}')), findsNothing);
      if (tokyo.local.year != now.year ||
          tokyo.local.month != now.month ||
          tokyo.local.day != now.day) {
        expect(_zoneText(formatDateLine(now)), findsNothing);
      }

      await tester.enterText(
        find.byKey(const Key('check-schedule-minute')),
        '30',
      );
      await tester.pump();
      final moved = localScheduleInstant(now, 15, 30);
      final movedTokyo = ZoneClock.resolve(zone.ianaId, moved);
      final movedLabel = formatClock(movedTokyo.local, includeSeconds: false);
      expect(_zoneText(movedLabel), findsOneWidget);
      expect(_zoneText(scheduledLabel), findsNothing);
      expect(find.text('Saved places show 3:30 PM today.'), findsOneWidget);

      await tester.tap(toggle);
      await tester.pump();

      expect(tester.widget<Checkbox>(toggle).value, isFalse);
      expect(_zoneText(liveLabel), findsOneWidget);
      expect(_zoneText(scheduledLabel), findsNothing);
      expect(_zoneText(movedLabel), findsNothing);
      expect(find.byKey(const Key('check-schedule-hour')), findsNothing);
      expect(find.text('Saved places show 3:00 PM today.'), findsNothing);
      expect(find.text('Saved places show 3:30 PM today.'), findsNothing);

      await tester.tap(toggle);
      await tester.pump();
      expect(tester.widget<Checkbox>(toggle).value, isTrue);
      expect(fieldText(const Key('check-schedule-hour')), isEmpty);
      expect(fieldText(const Key('check-schedule-minute')), '00');
      expect(_zoneText(liveLabel), findsOneWidget);
      expect(_zoneText(scheduledLabel), findsNothing);
      expect(_zoneText(movedLabel), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

Finder _zoneText(String text) {
  return find.descendant(of: find.byType(ZoneCard), matching: find.text(text));
}
