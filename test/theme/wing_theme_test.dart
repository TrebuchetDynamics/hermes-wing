import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/app.dart';
import 'package:wing/theme/wing_theme.dart';

void main() {
  test(
    'Hermes Wing themes provide Telegram Light and Hermes Dark palettes',
    () {
      expect(wingTelegramBlue, const Color(0xff229ed9));
      expect(wingHermesBlue, const Color(0xff3b82f6));
      expect(wingLightTheme.useMaterial3, isTrue);
      expect(wingHermesDarkTheme.useMaterial3, isTrue);
      expect(wingLightTheme.colorScheme.brightness, Brightness.light);
      expect(wingHermesDarkTheme.colorScheme.brightness, Brightness.dark);
      expect(wingHermesDarkTheme.colorScheme.surface, wingHermesDarkBackground);
      expect(
        wingHermesDarkTheme.colorScheme.surfaceContainerLowest,
        wingHermesDarkPane,
      );
      expect(wingLightTheme.appBarTheme.centerTitle, isFalse);
      expect(wingHermesDarkTheme.appBarTheme.centerTitle, isFalse);
    },
  );

  test('Hermes Wing themes keep top bars flat like Telegram', () {
    for (final theme in [wingLightTheme, wingDarkTheme]) {
      final appBarTheme = theme.appBarTheme;

      expect(appBarTheme.elevation, 0);
      expect(appBarTheme.scrolledUnderElevation, 0);
      expect(appBarTheme.shadowColor, Colors.transparent);
      expect(appBarTheme.surfaceTintColor, Colors.transparent);
    }
  });

  test('Hermes Wing themes style the drawer like a Telegram side menu', () {
    for (final theme in [wingLightTheme, wingDarkTheme]) {
      final colorScheme = theme.colorScheme;
      final drawerShape = theme.drawerTheme.shape as RoundedRectangleBorder?;

      expect(theme.drawerTheme.backgroundColor, colorScheme.surface);
      expect(theme.drawerTheme.surfaceTintColor, Colors.transparent);
      expect(drawerShape?.borderRadius, BorderRadius.zero);
      expect(theme.listTileTheme.selectedColor, colorScheme.primary);
      expect(theme.listTileTheme.selectedTileColor, isNotNull);
    }
  });

  test(
    'Hermes Wing themes use compact Telegram-like navigation list tiles',
    () {
      for (final theme in [wingLightTheme, wingDarkTheme]) {
        final colorScheme = theme.colorScheme;
        final listTileTheme = theme.listTileTheme;

        expect(listTileTheme.iconColor, colorScheme.onSurfaceVariant);
        expect(listTileTheme.textColor, colorScheme.onSurface);
        expect(
          listTileTheme.contentPadding,
          const EdgeInsets.symmetric(horizontal: 24),
        );
        expect(listTileTheme.horizontalTitleGap, 20);
        expect(listTileTheme.minLeadingWidth, 24);
      }
    },
  );

  test(
    'Hermes Wing themes style the desktop rail with selected Hermes accents',
    () {
      for (final theme in [wingLightTheme, wingDarkTheme]) {
        final colorScheme = theme.colorScheme;
        final railTheme = theme.navigationRailTheme;

        expect(railTheme.backgroundColor, colorScheme.surface);
        expect(railTheme.indicatorColor, isNotNull);
        expect(railTheme.selectedIconTheme?.color, colorScheme.primary);
        expect(railTheme.selectedLabelTextStyle?.color, colorScheme.primary);
      }
    },
  );

  test('Hermes Wing themes use subtle Telegram-like navigation dividers', () {
    for (final theme in [wingLightTheme, wingDarkTheme]) {
      final colorScheme = theme.colorScheme;

      expect(
        theme.dividerTheme.color,
        colorScheme.outlineVariant.withAlpha(
          theme.colorScheme.brightness == Brightness.dark ? 92 : 96,
        ),
      );
      expect(theme.dividerTheme.thickness, 1);
      expect(theme.dividerTheme.space, 1);
    }
  });

  test(
    'Hermes Wing themes keep cards flat with subtle Telegram-like outlines',
    () {
      for (final theme in [wingLightTheme, wingDarkTheme]) {
        final colorScheme = theme.colorScheme;
        final cardTheme = theme.cardTheme;
        final cardShape = cardTheme.shape as RoundedRectangleBorder?;

        expect(
          cardTheme.color,
          theme.colorScheme.brightness == Brightness.dark
              ? colorScheme.surfaceContainer
              : colorScheme.surface,
        );
        expect(cardTheme.surfaceTintColor, Colors.transparent);
        expect(cardTheme.elevation, 0);
        expect(cardShape?.borderRadius, BorderRadius.circular(16));
        expect(cardShape?.side.color, colorScheme.outlineVariant.withAlpha(96));
        expect(cardShape?.side.width, 1);
      }
    },
  );

  test('every palette provides Material 3 themes in both brightnesses', () {
    expect(WingThemePalette.values, hasLength(5));
    for (final palette in WingThemePalette.values) {
      final light = wingThemeFor(palette, Brightness.light);
      final dark = wingThemeFor(palette, Brightness.dark);
      expect(light.colorScheme.brightness, Brightness.light);
      expect(dark.colorScheme.brightness, Brightness.dark);
      expect(light.useMaterial3, isTrue);
      expect(dark.useMaterial3, isTrue);
      // Every palette keeps the flat Telegram-like top bar.
      expect(light.appBarTheme.elevation, 0);
      expect(dark.appBarTheme.elevation, 0);
    }
  });

  test('the Wing palette is the existing hand-tuned default pair', () {
    expect(
      wingThemeFor(WingThemePalette.wing, Brightness.light),
      same(wingLightTheme),
    );
    expect(
      wingThemeFor(WingThemePalette.wing, Brightness.dark),
      same(wingHermesDarkTheme),
    );
  });

  test('palettes are visually distinct', () {
    final primaries = {
      for (final palette in WingThemePalette.values)
        wingThemeFor(palette, Brightness.light).colorScheme.primary,
    };
    expect(primaries, hasLength(WingThemePalette.values.length));
  });

  testWidgets('WingApp exposes system light and dark themes', (tester) async {
    await tester.pumpWidget(const WingApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.themeMode, ThemeMode.system);
    expect(app.theme?.colorScheme.brightness, Brightness.light);
    expect(app.darkTheme?.colorScheme.brightness, Brightness.dark);
  });

  testWidgets('WingApp applies the persisted theme mode and palette', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'flutter.wing.theme.mode': 'dark',
      'flutter.wing.theme.palette': 'forest',
    });

    await tester.pumpWidget(const WingApp());
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(
      app.theme,
      same(wingThemeFor(WingThemePalette.forest, Brightness.light)),
    );
    expect(
      app.darkTheme,
      same(wingThemeFor(WingThemePalette.forest, Brightness.dark)),
    );
  });

  testWidgets('WingApp wraps routed content in a text selection area', (
    tester,
  ) async {
    await tester.pumpWidget(const WingApp());

    expect(find.byType(SelectionArea), findsOneWidget);
  });
}
