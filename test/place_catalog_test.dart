import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone_mobile/src/data/place_catalog.dart';

void main() {
  late PlaceCatalog catalog;

  setUpAll(() {
    tzdata.initializeTimeZones();
    catalog = PlaceCatalog.build();
  });

  test('suggests the starter set in order', () {
    expect(catalog.starters.map((place) => place.label).toList(), [
      'California',
      'Malaysia',
      'Japan',
      'Indonesia',
      'Singapore',
    ]);
    expect(catalog.starters.map((place) => place.id).toList(), [
      'America/Los_Angeles',
      'Asia/Kuala_Lumpur',
      'Asia/Tokyo',
      'Asia/Jakarta',
      'Asia/Singapore',
    ]);
    // tzdata 2026e keeps Kuala Lumpur's clock on the Singapore zone.
    expect(catalog.starters[1].ianaId, 'Asia/Singapore');
  });

  test('search prefers the label that matches the query', () {
    expect(catalog.search('california').first.label, 'California');
    expect(catalog.search('los angeles').first.label, 'Los Angeles');
    expect(catalog.search('los angeles').first.ianaId, 'America/Los_Angeles');
    expect(catalog.search('malaysia').first.label, 'Malaysia');
    expect(catalog.search('kuala lumpur').first.label, 'Malaysia');
    expect(catalog.search('kuala lumpur').first.id, 'Asia/Kuala_Lumpur');
    expect(catalog.search('japan').first.ianaId, 'Asia/Tokyo');
    expect(catalog.search('tokyo').first.label, 'Tokyo');
    expect(catalog.search('indonesia').first.ianaId, 'Asia/Jakarta');
    expect(catalog.search('jakarta').first.label, 'Jakarta');
    expect(catalog.search('singapore').first.label, 'Singapore');
    expect(
      catalog.search('singapore').map((place) => place.label),
      isNot(contains('Malaysia')),
    );
    expect(catalog.search('são paulo').first.ianaId, 'America/Sao_Paulo');
    expect(catalog.search('mumbai').first.label, 'Mumbai');
  });

  test('returns one row per zone and nothing for a blank query', () {
    expect(catalog.search('   '), isEmpty);
    final unitedStates = catalog.search('united states');
    expect(
      unitedStates.map((place) => place.ianaId).toSet().length,
      unitedStates.length,
    );
    expect(
      unitedStates.any((place) => place.ianaId == 'America/New_York'),
      isTrue,
    );
    expect(catalog.popular.any((place) => place.label == 'New York'), isTrue);
  });
}
