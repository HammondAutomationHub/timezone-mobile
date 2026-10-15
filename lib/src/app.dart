import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import 'connectivity/online_status.dart';
import 'data/place_catalog.dart';
import 'models/place.dart';
import 'models/saved_zone.dart';
import 'screens/home_page.dart';
import 'storage/zone_store.dart';
import 'theme/app_theme.dart';

class TimeZoneApp extends StatefulWidget {
  const TimeZoneApp({
    required this.store,
    required this.catalog,
    required this.initialZones,
    super.key,
  });

  final ZoneStore store;
  final PlaceCatalog catalog;
  final List<SavedZone> initialZones;

  @override
  State<TimeZoneApp> createState() => _TimeZoneAppState();
}

class _TimeZoneAppState extends State<TimeZoneApp> {
  late List<SavedZone> _zones;
  late final OnlineStatus _onlineStatus;
  late DateTime _now;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    final valid = widget.initialZones.where(_isKnownZone).toList();
    _zones = valid;
    if (valid.length != widget.initialZones.length) {
      unawaited(widget.store.save(valid));
    }
    _onlineStatus = OnlineStatus()..addListener(_onOnlineChanged);
    _now = DateTime.now();
    _scheduleTick();
  }

  bool _isKnownZone(SavedZone zone) {
    try {
      tz.getLocation(zone.ianaId);
      return true;
    } on tz.LocationNotFoundException {
      return false;
    }
  }

  void _onOnlineChanged() {
    if (mounted) setState(() {});
  }

  void _scheduleTick() {
    final now = DateTime.now();
    final remainder = 1000 - now.millisecond;
    _ticker = Timer(
      Duration(milliseconds: remainder == 0 ? 1000 : remainder),
      () {
        if (!mounted) return;
        setState(() => _now = DateTime.now());
        _scheduleTick();
      },
    );
  }

  void _commit(List<SavedZone> zones) {
    setState(() => _zones = zones);
    unawaited(widget.store.save(zones));
  }

  void _add(Place place) {
    if (_zones.any((zone) => zone.id == place.id)) return;
    _commit([..._zones, SavedZone.fromPlace(place)]);
  }

  void _recolor(SavedZone zone, int colorValue) {
    _commit([
      for (final item in _zones)
        if (item.id == zone.id) item.copyWith(colorValue: colorValue) else item,
    ]);
  }

  void _remove(SavedZone zone) {
    _commit(_zones.where((item) => item.id != zone.id).toList());
  }

  void _restore(SavedZone zone, int index) {
    if (_zones.any((item) => item.id == zone.id)) return;
    final next = [..._zones];
    next.insert(index.clamp(0, next.length), zone);
    _commit(next);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _onlineStatus
      ..removeListener(_onOnlineChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TimeZoneMobile',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: HomePage(
        now: _now,
        online: _onlineStatus.online,
        zones: _zones,
        catalog: widget.catalog,
        onAdd: _add,
        onColorChanged: _recolor,
        onRemove: _remove,
        onRestore: _restore,
      ),
    );
  }
}
