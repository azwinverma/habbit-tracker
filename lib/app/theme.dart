import 'package:flutter/material.dart';

/// Brand palette from the DailyMantra 2.0 blueprint. Category colours are for
/// accents only; status uses the semantic colours of the ColorScheme.
/// Contrast is to be verified per pairing in Phase 2 (design system).
abstract final class BrandColors {
  static const deepTeal = Color(0xFF176B67); // primary / brand anchor
  static const mint = Color(0xFFDCF3E9); // soft surfaces
  static const coral = Color(0xFFF4A58A); // highlights, celebrations
  static const lavender = Color(0xFFA99CE7); // focus / meditation
  static const sky = Color(0xFF70B7E3); // water / learning

  static const backgroundLight = Color(0xFFF7FAF8);
  static const ink = Color(0xFF1B2B2A);
  static const muted = Color(0xFF647572);

  static const backgroundDark = Color(0xFF101A1A);
  static const surfaceDark = Color(0xFF1A2828);
  static const textDark = Color(0xFFE9F3F0);
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: BrandColors.deepTeal,
    brightness: brightness,
    primary: dark ? null : BrandColors.deepTeal,
    surface: dark ? BrandColors.backgroundDark : BrandColors.backgroundLight,
    onSurface: dark ? BrandColors.textDark : BrandColors.ink,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    cardTheme: CardThemeData(
      elevation: 0,
      color: dark ? BrandColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: scheme.primaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    visualDensity: VisualDensity.standard,
  );
}
