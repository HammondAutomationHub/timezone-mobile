import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone_mobile/src/models/place.dart';
import 'package:timezone_mobile/src/models/saved_zone.dart';
import 'package:timezone_mobile/src/storage/zone_store.dart';

void main() {
  test('new places start as neutral gray', () {
    const place = Place(
      label: 'Japan',
      subtitle: 'Tokyo',
      ianaId: 'Asia/Tokyo',
    );
    final zone = SavedZone.fromPlace(place);
    expect(zone.id, 'Asia/Tokyo');
    expect(zone.colorValue, SavedZone.defaultColorValue);
    expect(zone.colorValue, 0xFFB7BCC4);
    expect(zone.label, 'Japan');
  });

  test('round-trips zones and drops corrupt or duplicate rows', () {
    const original = [
      SavedZone(
        ianaId: 'Asia/Tokyo',
        label: 'Japan',
        subtitle: 'Tokyo',
        colorValue: 0xFF8FCBB0,
      ),
      SavedZone(
        ianaId: 'Asia/Tokyo',
        label: 'Tokyo again',
        subtitle: 'Japan',
        colorValue: 0xFFB7BCC4,
      ),
    ];
    final raw = encodeSavedZones(original);
    final decoded = decodeSavedZones(raw);
    expect(decoded, hasLength(1));
    expect(decoded.single.label, 'Japan');
    expect(decoded.single.colorValue, 0xFF8FCBB0);

    expect(decodeSavedZones('not json'), isEmpty);
    expect(decodeSavedZones('{"ianaId":"Asia/Tokyo"}'), isEmpty);
    expect(
      decodeSavedZones(
        '[{"label":" ","ianaId":"Asia/Tokyo"},{"ianaId":"Asia/Jakarta","label":"Indonesia"}]',
      ).single.label,
      'Indonesia',
    );
  });

  test('zone store writes the encoded list', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = ZoneStore(preferences);
    const zone = SavedZone(
      ianaId: 'Asia/Singapore',
      label: 'Singapore',
      subtitle: 'Singapore',
      colorValue: SavedZone.defaultColorValue,
    );

    expect(store.load(), isEmpty);
    await store.save(const [zone]);
    expect(store.load().single.ianaId, 'Asia/Singapore');
    expect(preferences.getString(ZoneStore.storageKey), isNotNull);
  });
}
