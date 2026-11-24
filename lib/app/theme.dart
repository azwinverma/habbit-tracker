import 'package:flutter/material.dart';

/// DailyMantra design tokens (blueprint §5 "Brand system").
///
/// Palette, 8-pt spacing, radii 12/16/24, 48-dp minimum touch targets,
/// Plus Jakarta Sans (English) with Noto Sans Devanagari (Nepali) fallback.
/// Category colours are accents only; status uses semantic tokens.
/// Text/background pairs are checked for WCAG AA in test/design/contrast_test.dart.
abstract final class BrandColors {
  static const deepTeal = Color(0xFF176B67); // primary / brand anchor
  static const mint = Color(0xFFDCF3E9); // soft surfaces
  static const coral = Color(0xFFF4A58A); // highlights, celebrations
  static const lavender = Color(0xFFA99CE7); // focus / meditation
  static const sky = Color(0xFF70B7E3); // water / learning

  static const backgroundLight = Color(0xFFF7FAF8);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1B2B2A);
  static const muted = Color(0xFF647572);

  static const backgroundDark = Color(0xFF101A1A);
  static const surfaceDark = Color(0xFF1A2828);
  static const textDark = Color(0xFFE9F3F0);
}

/// 8-point spacing scale.
abstract final class Space {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Horizontal page gutter.
  static const page = 20.0;
}

abstract final class Radii {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const pill = 999.0;
}

abstract final class Motion {
  static const short = Duration(milliseconds: 200);
  static const medium = Duration(milliseconds: 450);
  static const curve = Curves.easeOutCubic;

  /// Respect the OS "remove animations" setting.
  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.maybeDisableAnimationsOf(context) == true ? Duration.zero : d;
}

/// Per-category accent (icon badge, ring) + a soft container colour.
/// Accents are never used for body text, only for shapes/icons.
@immutable
class CategoryPalette {
  final Color accent;
  final Color container;
  final Color onContainer;
  const CategoryPalette(this.accent, this.container, this.onContainer);
}

/// Semantic status colours and category palettes, as a ThemeExtension so they
/// switch with light/dark.
@immutable
class DmColors extends ThemeExtension<DmColors> {
  const DmColors({
    required this.success,
    required this.warning,
    required this.medicine,
    required this.water,
    required this.mind,
    required this.reading,
    required this.movement,
    required this.habit,
    required this.celebrate,
  });

  final Color success;
  final Color warning;
  final CategoryPalette medicine, water, mind, reading, movement, habit;
  final Color celebrate;

  static const light = DmColors(
    success: Color(0xFF1E7B4F),
    warning: Color(0xFF8A5A00),
    medicine: CategoryPalette(Color(0xFFC2533A), Color(0xFFFDE7DF), Color(0xFF6B2A17)),
    water: CategoryPalette(Color(0xFF2F8FCB), Color(0xFFE1F1FB), Color(0xFF0E4466)),
    mind: CategoryPalette(Color(0xFF7A6AD8), Color(0xFFEDEAFB), Color(0xFF392C86)),
    reading: CategoryPalette(Color(0xFFA06C1C), Color(0xFFFAF0DC), Color(0xFF5A3D0A)),
    movement: CategoryPalette(Color(0xFF2E9A6A), Color(0xFFDCF3E9), Color(0xFF0F4A31)),
    habit: CategoryPalette(BrandColors.deepTeal, BrandColors.mint, Color(0xFF0B3B38)),
    celebrate: BrandColors.coral,
  );

  static const dark = DmColors(
    success: Color(0xFF7FD6A8),
    warning: Color(0xFFF2C46D),
    medicine: CategoryPalette(Color(0xFFF4A58A), Color(0xFF3A2620), Color(0xFFFFDBCF)),
    water: CategoryPalette(Color(0xFF8CCBF0), Color(0xFF17303F), Color(0xFFD3ECFB)),
    mind: CategoryPalette(Color(0xFFBDB2F2), Color(0xFF29254A), Color(0xFFE6E1FF)),
    reading: CategoryPalette(Color(0xFFE8C07A), Color(0xFF3A2F1A), Color(0xFFFBEBCB)),
    movement: CategoryPalette(Color(0xFF86D9B1), Color(0xFF173528), Color(0xFFCDF2DF)),
    habit: CategoryPalette(Color(0xFF7FD3C9), Color(0xFF124F4B), BrandColors.mint),
    celebrate: BrandColors.coral,
  );

  @override
  DmColors copyWith() => this;

  @override
  DmColors lerp(ThemeExtension<DmColors>? other, double t) =>
      (other is DmColors && t >= 0.5) ? other : this;
}

extension DmTheme on BuildContext {
  DmColors get dm => Theme.of(this).extension<DmColors>() ?? DmColors.light;
}

ColorScheme brandScheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final base = ColorScheme.fromSeed(seedColor: BrandColors.deepTeal, brightness: brightness);
  if (!dark) {
    return base.copyWith(
      primary: BrandColors.deepTeal,
      onPrimary: Colors.white,
      primaryContainer: BrandColors.mint,
      onPrimaryContainer: const Color(0xFF0B3B38),
      secondary: const Color(0xFF4A6360),
      secondaryContainer: const Color(0xFFE3EEEA),
      onSecondaryContainer: const Color(0xFF1B2B2A),
      tertiary: const Color(0xFF5E52B8),
      tertiaryContainer: const Color(0xFFEDEAFB),
      onTertiaryContainer: const Color(0xFF2A1F73),
      surface: BrandColors.backgroundLight,
      onSurface: BrandColors.ink,
      onSurfaceVariant: BrandColors.muted,
      surfaceContainerLowest: BrandColors.surfaceLight,
      surfaceContainerLow: const Color(0xFFF2F7F4),
      surfaceContainer: const Color(0xFFECF3EF),
      surfaceContainerHigh: const Color(0xFFE5EEEA),
      surfaceContainerHighest: const Color(0xFFDDE8E3),
      outline: const Color(0xFF7E8F8B),
      outlineVariant: const Color(0xFFD6E2DD),
      error: const Color(0xFFB3261E),
    );
  }
  return base.copyWith(
    primary: const Color(0xFF7FD3C9),
    onPrimary: const Color(0xFF00332F),
    primaryContainer: const Color(0xFF124F4B),
    onPrimaryContainer: BrandColors.mint,
    secondaryContainer: const Color(0xFF243837),
    onSecondaryContainer: BrandColors.textDark,
    tertiary: const Color(0xFFBDB2F2),
    tertiaryContainer: const Color(0xFF29254A),
    onTertiaryContainer: const Color(0xFFE6E1FF),
    surface: BrandColors.backgroundDark,
    onSurface: BrandColors.textDark,
    onSurfaceVariant: const Color(0xFFA9BBB7),
    surfaceContainerLowest: const Color(0xFF0B1414),
    surfaceContainerLow: const Color(0xFF152121),
    surfaceContainer: BrandColors.surfaceDark,
    surfaceContainerHigh: const Color(0xFF213131),
    surfaceContainerHighest: const Color(0xFF2B3C3C),
    outline: const Color(0xFF8A9C98),
    outlineVariant: const Color(0xFF2E4040),
  );
}

const _fontFamily = 'PlusJakartaSans';
const _fontFallback = ['NotoSansDevanagari'];

TextTheme brandTextTheme(ColorScheme s) {
  TextStyle t(double size, FontWeight w, {double height = 1.4, double ls = 0, Color? c}) => TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFallback,
        fontSize: size,
        fontWeight: w,
        height: height,
        letterSpacing: ls,
        color: c ?? s.onSurface,
      );
  // Sizes from the blueprint: display 28–32, headline 22–24, section 18–20,
  // body 14–16, captions 12–13. Devanagari needs generous line height.
  return TextTheme(
    displayLarge: t(40, FontWeight.w800, height: 1.15, ls: -1.0),
    displayMedium: t(34, FontWeight.w800, height: 1.15, ls: -0.8),
    displaySmall: t(30, FontWeight.w800, height: 1.2, ls: -0.6),
    headlineLarge: t(28, FontWeight.w700, height: 1.25, ls: -0.5),
    headlineMedium: t(24, FontWeight.w700, height: 1.3, ls: -0.4),
    headlineSmall: t(22, FontWeight.w700, height: 1.3, ls: -0.3),
    titleLarge: t(19, FontWeight.w700, height: 1.35, ls: -0.2),
    titleMedium: t(16, FontWeight.w600, height: 1.4),
    titleSmall: t(14, FontWeight.w600, height: 1.4),
    bodyLarge: t(16, FontWeight.w400, height: 1.5),
    bodyMedium: t(14.5, FontWeight.w400, height: 1.5),
    bodySmall: t(13, FontWeight.w400, height: 1.45, c: s.onSurfaceVariant),
    labelLarge: t(14, FontWeight.w600, height: 1.3),
    labelMedium: t(12.5, FontWeight.w600, height: 1.3),
    labelSmall: t(12, FontWeight.w500, height: 1.3, ls: 0.2),
  );
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final s = brandScheme(brightness);
  final text = brandTextTheme(s);
  final cardColor = dark ? s.surfaceContainer : s.surfaceContainerLowest;
  const pill = StadiumBorder();
  const minButton = Size(64, 52);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: s,
    fontFamily: _fontFamily,
    fontFamilyFallback: _fontFallback,
    textTheme: text,
    scaffoldBackgroundColor: s.surface,
    extensions: [dark ? DmColors.dark : DmColors.light],
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
    appBarTheme: AppBarTheme(
      backgroundColor: s.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
      foregroundColor: s.onSurface,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: BorderSide(color: s.outlineVariant.withValues(alpha: dark ? 0.6 : 0.7)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: minButton,
        shape: pill,
        textStyle: text.labelLarge?.copyWith(fontSize: 15),
        padding: const EdgeInsets.symmetric(horizontal: Space.xl),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: pill,
        side: BorderSide(color: s.outlineVariant),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48), shape: pill, textStyle: text.labelLarge),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(minimumSize: minButton, shape: pill, elevation: 0),
    ),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(minimumSize: const Size(48, 48))),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: s.primary,
      foregroundColor: s.onPrimary,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md + 4)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? s.surfaceContainerHigh : s.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.lg),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.md), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md), borderSide: BorderSide(color: s.outlineVariant)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md), borderSide: BorderSide(color: s.primary, width: 2)),
      labelStyle: text.bodyMedium?.copyWith(color: s.onSurfaceVariant),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      elevation: 0,
      backgroundColor: dark ? s.surfaceContainerLow : s.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      indicatorColor: s.primaryContainer,
      indicatorShape: const StadiumBorder(),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((st) => text.labelMedium?.copyWith(
            color: st.contains(WidgetState.selected) ? s.onSurface : s.onSurfaceVariant,
          )),
      iconTheme: WidgetStateProperty.resolveWith((st) => IconThemeData(
            color: st.contains(WidgetState.selected) ? s.onPrimaryContainer : s.onSurfaceVariant,
          )),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: dark ? s.surfaceContainerLow : s.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: dark ? s.surfaceContainerHigh : s.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg + 4)),
      titleTextStyle: text.titleLarge,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sm)),
      side: BorderSide(color: s.outlineVariant),
      labelStyle: text.labelLarge,
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
      minVerticalPadding: Space.md,
      titleTextStyle: text.titleMedium,
      subtitleTextStyle: text.bodySmall,
      iconColor: s.onSurfaceVariant,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        minimumSize: const Size(48, 48),
        selectedBackgroundColor: s.primaryContainer,
        selectedForegroundColor: s.onPrimaryContainer,
        side: BorderSide(color: s.outlineVariant),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbIcon: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.selected) ? const Icon(Icons.check, size: 16) : null),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: s.primary,
      linearTrackColor: s.surfaceContainerHighest,
      circularTrackColor: s.surfaceContainerHighest,
      linearMinHeight: 8,
    ),
    dividerTheme: DividerThemeData(color: s.outlineVariant, thickness: 1, space: 1),
    tabBarTheme: TabBarThemeData(
      labelStyle: text.labelLarge,
      unselectedLabelStyle: text.labelLarge,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
    ),
  );
}
