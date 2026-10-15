import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A small country flag for a pinned place.
class ZoneFlag extends StatelessWidget {
  const ZoneFlag({required this.countryCode, super.key});

  final String? countryCode;

  @override
  Widget build(BuildContext context) {
    final code = countryCode;
    if (code == null || code.length != 2) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: CountryFlag.fromCountryCode(
          code,
          theme: const ImageTheme(
            width: 22,
            height: 15,
            shape: RoundedRectangle(2),
          ),
        ),
      ),
    );
  }
}
