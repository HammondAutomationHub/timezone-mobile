import 'package:flutter/widgets.dart';

/// Non-web builds have no browser install prompt.
bool get installSupported => false;

Future<bool> requestInstall(BuildContext context) async => false;
