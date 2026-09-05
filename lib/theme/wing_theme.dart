import 'package:flutter/material.dart';

const wingTelegramBlue = Color(0xff229ed9);
const wingHermesBlue = Color(0xff3b82f6);
const wingHermesDarkBackground = Color(0xff111214);
const wingHermesDarkPane = Color(0xff1f2023);
const wingHermesDarkRail = Color(0xff15171a);
const wingHermesDarkCard = Color(0xff1b1d21);
const wingHermesDarkCardHigh = Color(0xff24272d);
const wingHermesDarkOutline = Color(0xff30343b);

/// The five shipped color palettes (ROADMAP 5.1). [wing] is the default
/// hand-tuned pair; the others derive both brightnesses from one seed
/// through the same [_buildWingTheme] pipeline.
enum WingThemePalette {
  wing(wingTelegramBlue),
  indigo(Color(0xff6366f1)),
  forest(Color(0xff059669)),
  amber(Color(0xffd97706)),
  mulberry(Color(0xffbe185d));

  const WingThemePalette(this.seed);

  /// Representative swatch color shown in the theme picker.
  final Color seed;
}

final _paletteThemes = <WingThemePalette, ({ThemeData light, ThemeData dark})>{
  for (final palette in WingThemePalette.values)
    palette: palette == WingThemePalette.wing
        ? (light: wingLightTheme, dark: wingHermesDarkTheme)
        : (
            light: _buildWingTheme(
              ColorScheme.fromSeed(seedColor: palette.seed),
              selectedTileAlpha: 24,
              dividerAlpha: 96,
            ),
            dark: _buildWingTheme(
              ColorScheme.fromSeed(
                seedColor: palette.seed,
                brightness: Brightness.dark,
              ),
              selectedTileAlpha: 36,
              dividerAlpha: 92,
            ),
          ),
};

/// The [ThemeData] for [palette] at [brightness].
ThemeData wingThemeFor(WingThemePalette palette, Brightness brightness) {
  final pair = _paletteThemes[palette]!;
  return brightness == Brightness.dark ? pair.dark : pair.light;
}

final wingLightTheme = _buildTelegramLightTheme();
final wingHermesDarkTheme = _buildHermesDarkTheme();

/// Backwards-compatible name used by existing app/tests. This is now the
/// Hermes Desktop-inspired dark theme, while [wingLightTheme] remains the
/// Telegram-light mobile-friendly variant.
final wingDarkTheme = wingHermesDarkTheme;

ThemeData _buildTelegramLightTheme() => _buildWingTheme(
  ColorScheme.fromSeed(seedColor: wingTelegramBlue).copyWith(
    surface: const Color(0xfffafbfc),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: const Color(0xfff0f2f5),
    surfaceContainer: const Color(0xffe9edf2),
    surfaceContainerHigh: const Color(0xffe2e7ee),
    surfaceContainerHighest: const Color(0xffdce2ea),
    onSurface: const Color(0xff1b2533),
    onSurfaceVariant: const Color(0xff526071),
    outlineVariant: const Color(0xffd7dee7),
  ),
  selectedTileAlpha: 24,
  dividerAlpha: 96,
);

ThemeData _buildHermesDarkTheme() {
  final seeded = ColorScheme.fromSeed(
    seedColor: wingHermesBlue,
    brightness: Brightness.dark,
  );
  return _buildWingTheme(
    seeded.copyWith(
      primary: const Color(0xff8ab4ff),
      onPrimary: const Color(0xff10294c),
      secondary: const Color(0xff7dd3fc),
      surface: wingHermesDarkBackground,
      onSurface: const Color(0xfff4f4f5),
      surfaceContainerLowest: wingHermesDarkPane,
      surfaceContainerLow: wingHermesDarkRail,
      surfaceContainer: wingHermesDarkCard,
      surfaceContainerHigh: wingHermesDarkCardHigh,
      surfaceContainerHighest: const Color(0xff2b2f36),
      onSurfaceVariant: const Color(0xffc4c8cf),
      outline: const Color(0xff565b65),
      outlineVariant: wingHermesDarkOutline,
    ),
    selectedTileAlpha: 36,
    dividerAlpha: 92,
  );
}

ThemeData _buildWingTheme(
  ColorScheme colorScheme, {
  required int selectedTileAlpha,
  required int dividerAlpha,
}) {
  final isDark = colorScheme.brightness == Brightness.dark;
  final selectedColor = colorScheme.primary.withAlpha(selectedTileAlpha);

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: colorScheme.surface,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.7,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        height: 1.35,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(fontSize: 15, height: 1.45, letterSpacing: 0),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4, letterSpacing: 0),
      bodySmall: TextStyle(fontSize: 12, height: 1.4, letterSpacing: 0),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      elevation: 0,
      backgroundColor: isDark
          ? colorScheme.surfaceContainerLow
          : colorScheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      indicatorColor: selectedColor,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: isDark
          ? colorScheme.surfaceContainer
          : colorScheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: isDark
          ? colorScheme.surfaceContainer
          : colorScheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      shape: const CircleBorder(),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant.withAlpha(dividerAlpha),
      thickness: 1,
      space: 1,
    ),
    cardTheme: CardThemeData(
      color: isDark
          ? colorScheme.surfaceContainer
          : colorScheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(150)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: isDark
          ? colorScheme.surfaceContainerHigh
          : colorScheme.surfaceContainerLowest,
      selectedColor: selectedColor,
      disabledColor: colorScheme.surfaceContainerHighest.withAlpha(
        isDark ? 88 : 56,
      ),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      labelStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: TextStyle(color: colorScheme.onSurface),
      iconTheme: IconThemeData(color: colorScheme.primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? colorScheme.surfaceContainer
          : colorScheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      helperMaxLines: 4,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: colorScheme.onSurfaceVariant,
      textColor: colorScheme.onSurface,
      selectedColor: colorScheme.primary,
      selectedTileColor: selectedColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      horizontalTitleGap: 12,
      minLeadingWidth: 24,
      titleTextStyle: TextStyle(
        fontSize: 15,
        height: 1.35,
        color: colorScheme.onSurface,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 12,
        height: 1.4,
        color: colorScheme.onSurfaceVariant,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colorScheme.surface,
      indicatorColor: selectedColor,
      selectedIconTheme: IconThemeData(color: colorScheme.primary),
      selectedLabelTextStyle: TextStyle(
        color: colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
      unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      unselectedLabelTextStyle: TextStyle(color: colorScheme.onSurfaceVariant),
    ),
  );
}
