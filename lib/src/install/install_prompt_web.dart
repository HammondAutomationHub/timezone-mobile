import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../theme/app_theme.dart';

@JS('__tzInstallPrompt')
external JSObject? get _tzInstallPrompt;

@JS('__tzInstallPrompt')
external set _tzInstallPrompt(JSObject? value);

extension type _Prompt._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> prompt();
  external JSPromise<_Choice> get userChoice;
}

extension type _Choice._(JSObject _) implements JSObject {
  external String get outcome;
}

bool get installSupported {
  final media = web.window.matchMedia('(display-mode: standalone)');
  return !media.matches;
}

/// Calls the browser install dialog when Chrome or Edge has offered one.
/// Returns true when the person accepts. Otherwise explains the menu path.
Future<bool> requestInstall(BuildContext context) async {
  final raw = _readPrompt();
  if (raw != null) {
    _tzInstallPrompt = null;
    final event = _Prompt._(raw);
    final prompted = event.prompt().toDart;
    final choice = event.userChoice.toDart;
    try {
      await prompted;
      final result = await choice;
      return result.outcome == 'accepted';
    } catch (_) {
      // No user gesture, or this browser has no install dialog.
    }
  }
  if (context.mounted) await _showSteps(context);
  return false;
}

JSObject? _readPrompt() {
  try {
    return _tzInstallPrompt;
  } catch (_) {
    return null;
  }
}

Future<void> _showSteps(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'Install TimeZoneMobile',
        style: TextStyle(color: AppColors.ink),
      ),
      content: const Text(
        'In Chrome, open the three-dot menu, choose Cast, save, and share, then Install page as app.\n\n'
        'In Edge, open the three-dot menu, choose Apps, then Install this site as an app.\n\n'
        'On an iPhone, use Share, then Add to Home Screen.',
        style: TextStyle(color: AppColors.muted, height: 1.45),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
