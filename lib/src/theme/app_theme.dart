import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF101418);
  static const surface = Color(0xFF1B222A);
  static const surfaceClosed = Color(0xFF2A2118);
  static const line = Color(0xFF2C3642);
  static const ink = Color(0xFFE8EEF3);
  static const muted = Color(0xFF93A0AC);
  static const faint = Color(0xFF6E7C89);
  static const open = Color(0xFF8FCBB0);
  static const closed = Color(0xFFE0A36A);
}

/// Type and spacing follow the window. A large desktop keeps the full clocks.
/// Shrinking the window on Windows or Mac steps the clocks, cards, and gaps down.
final class AppMetrics {
  AppMetrics(double width, {double height = 900})
    : _t = math.min(_axis(width, 300, 800), _axis(height, 340, 680));

  factory AppMetrics.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AppMetrics(size.width, height: size.height);
  }

  final double _t;

  static double _axis(double value, double compact, double regular) {
    return ((value - compact) / (regular - compact)).clamp(0.0, 1.0);
  }

  double lerp(double compact, double regular) =>
      compact + (regular - compact) * _t;

  double get localClock => lerp(20, 40);
  double get zoneClock => lerp(16, 34);
  double get placeName => lerp(14, 18);
  double get headline => lerp(18, 28);
  double get body => lerp(13, 15);
  double get meta => lerp(11, 14);
  double get pagePadding => lerp(10, 20);
  double get cardGap => lerp(8, 12);
  double get sectionGap => lerp(10, 22);
  double get cardPadLeft => lerp(10, 16);
  double get cardPadTop => lerp(8, 14);
  double get cardPadRight => lerp(4, 8);
  double get cardPadBottom => lerp(8, 16);
  double get iconTap => lerp(28, 36);
}

TextStyle zoneTextStyle({
  required Color color,
  required double size,
  FontWeight weight = FontWeight.w500,
}) {
  return TextStyle(
    color: color,
    fontSize: size,
    height: 1.05,
    fontWeight: weight,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

/// Lets a mouse or trackpad drag the lists, and keeps wheel scrolling active
/// across the full page rather than only over a card.
final class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.dark(
    surface: AppColors.surface,
    primary: AppColors.ink,
    onPrimary: AppColors.background,
    secondary: AppColors.closed,
    onSecondary: AppColors.background,
    error: Color(0xFFE09A9A),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: scheme,
    splashFactory: InkRipple.splashFactory,
    dividerColor: AppColors.line,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surface,
      contentTextStyle: TextStyle(color: AppColors.ink),
      actionTextColor: AppColors.closed,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.faint),
      prefixIconColor: AppColors.muted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.ink),
    ),
  );
}
