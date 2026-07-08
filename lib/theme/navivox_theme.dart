import 'package:flutter/material.dart';

const navivoxTelegramBlue = Color(0xff229ed9);
const navivoxHermesBlue = Color(0xff3b82f6);
const navivoxHermesDarkBackground = Color(0xff111214);
const navivoxHermesDarkPane = Color(0xff1f2023);
const navivoxHermesDarkRail = Color(0xff15171a);
const navivoxHermesDarkCard = Color(0xff1b1d21);
const navivoxHermesDarkCardHigh = Color(0xff24272d);
const navivoxHermesDarkOutline = Color(0xff30343b);

final navivoxLightTheme = _buildTelegramLightTheme();
final navivoxHermesDarkTheme = _buildHermesDarkTheme();

/// Backwards-compatible name used by existing app/tests. This is now the
/// Hermes Desktop-inspired dark theme, while [navivoxLightTheme] remains the
/// Telegram-light mobile-friendly variant.
final navivoxDarkTheme = navivoxHermesDarkTheme;

ThemeData _buildTelegramLightTheme() => _buildNavivoxTheme(
  ColorScheme.fromSeed(seedColor: navivoxTelegramBlue),
  selectedTileAlpha: 24,
  dividerAlpha: 96,
);

ThemeData _buildHermesDarkTheme() {
  final seeded = ColorScheme.fromSeed(
    seedColor: navivoxHermesBlue,
    brightness: Brightness.dark,
  );
  return _buildNavivoxTheme(
    seeded.copyWith(
      primary: navivoxHermesBlue,
      onPrimary: Colors.white,
      secondary: const Color(0xff7dd3fc),
      surface: navivoxHermesDarkBackground,
      onSurface: const Color(0xfff4f4f5),
      surfaceContainerLowest: navivoxHermesDarkPane,
      surfaceContainerLow: navivoxHermesDarkRail,
      surfaceContainer: navivoxHermesDarkCard,
      surfaceContainerHigh: navivoxHermesDarkCardHigh,
      surfaceContainerHighest: const Color(0xff2b2f36),
      onSurfaceVariant: const Color(0xffc4c8cf),
      outline: const Color(0xff565b65),
      outlineVariant: navivoxHermesDarkOutline,
    ),
    selectedTileAlpha: 36,
    dividerAlpha: 92,
  );
}

ThemeData _buildNavivoxTheme(
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
      color: isDark ? colorScheme.surfaceContainer : colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(96)),
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
      side: BorderSide(color: colorScheme.outlineVariant.withAlpha(128)),
      labelStyle: TextStyle(color: colorScheme.onSurface),
      secondaryLabelStyle: TextStyle(color: colorScheme.onSurface),
      iconTheme: IconThemeData(color: colorScheme.primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: isDark,
      fillColor: isDark ? colorScheme.surfaceContainer : null,
      border: isDark
          ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            )
          : null,
      enabledBorder: isDark
          ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            )
          : null,
      focusedBorder: isDark
          ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
            )
          : null,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: colorScheme.onSurfaceVariant,
      textColor: colorScheme.onSurface,
      selectedColor: colorScheme.primary,
      selectedTileColor: selectedColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      horizontalTitleGap: 20,
      minLeadingWidth: 24,
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
