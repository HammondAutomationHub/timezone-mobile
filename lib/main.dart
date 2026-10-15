import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import 'src/app.dart';
import 'src/data/place_catalog.dart';
import 'src/storage/zone_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  final preferences = await SharedPreferences.getInstance();
  final store = ZoneStore(preferences);
  runApp(
    TimeZoneApp(
      store: store,
      catalog: PlaceCatalog.build(),
      initialZones: store.load(),
    ),
  );
}
