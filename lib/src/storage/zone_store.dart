import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_zone.dart';

/// Persists pinned zones. On web, shared_preferences writes this key to
/// `localStorage`.
final class ZoneStore {
  ZoneStore(this._preferences);

  static const storageKey = 'timezone_mobile.saved_zones.v1';

  final SharedPreferences _preferences;

  List<SavedZone> load() {
    return decodeSavedZones(_preferences.getString(storageKey));
  }

  Future<void> save(List<SavedZone> zones) {
    return _preferences.setString(storageKey, encodeSavedZones(zones));
  }
}
