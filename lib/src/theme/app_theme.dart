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
