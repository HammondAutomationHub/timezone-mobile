import 'package:country_flags/country_flags.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone_mobile/src/data/place_catalog.dart';
import 'package:timezone_mobile/src/models/place.dart';
import 'package:timezone_mobile/src/models/saved_zone.dart';
import 'package:timezone_mobile/src/screens/add_place_page.dart';
import 'package:timezone_mobile/src/screens/home_page.dart';
import 'package:timezone_mobile/src/theme/app_theme.dart';

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
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
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
}
