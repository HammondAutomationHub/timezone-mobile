import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Tracks `navigator.onLine`. Web only — the clock itself does not need a network.
final class OnlineStatus extends ChangeNotifier {
  OnlineStatus() {
    _online = web.window.navigator.onLine;
    _onOnline = _handleOnline.toJS;
    _onOffline = _handleOffline.toJS;
    web.window.addEventListener('online', _onOnline);
    web.window.addEventListener('offline', _onOffline);
  }

  late final web.EventListener _onOnline;
  late final web.EventListener _onOffline;
  bool _online = true;

  bool get online => _online;

  void _handleOnline(web.Event _) => _setOnline(true);

  void _handleOffline(web.Event _) => _setOnline(false);

  void _setOnline(bool value) {
    if (_online == value) return;
    _online = value;
    notifyListeners();
  }

  @override
  void dispose() {
    web.window.removeEventListener('online', _onOnline);
    web.window.removeEventListener('offline', _onOffline);
    super.dispose();
  }
}
