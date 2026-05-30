import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/app.dart';
import 'package:navivox/theme/navivox_theme.dart';

void main() {
  test('Navivox themes provide light and dark Telegram-blue palettes', () {
    expect(navivoxTelegramBlue, const Color(0xff229ed9));
    expect(navivoxLightTheme.useMaterial3, isTrue);
    expect(navivoxDarkTheme.useMaterial3, isTrue);
    expect(navivoxLightTheme.colorScheme.brightness, Brightness.light);
    expect(navivoxDarkTheme.colorScheme.brightness, Brightness.dark);
    expect(navivoxLightTheme.appBarTheme.centerTitle, isFalse);
    expect(navivoxDarkTheme.appBarTheme.centerTitle, isFalse);
  });

  test('Navivox themes keep top bars flat like Telegram', () {
    for (final theme in [navivoxLightTheme, navivoxDarkTheme]) {
      final appBarTheme = theme.appBarTheme;

      expect(appBarTheme.elevation, 0);
      expect(appBarTheme.scrolledUnderElevation, 0);
      expect(appBarTheme.shadowColor, Colors.transparent);
      expect(appBarTheme.surfaceTintColor, Colors.transparent);
    }
  });

  test('Navivox themes style the drawer like a Telegram side menu', () {
    for (final theme in [navivoxLightTheme, navivoxDarkTheme]) {
      final colorScheme = theme.colorScheme;
      final drawerShape = theme.drawerTheme.shape as RoundedRectangleBorder?;

      expect(theme.drawerTheme.backgroundColor, colorScheme.surface);
      expect(theme.drawerTheme.surfaceTintColor, Colors.transparent);
      expect(drawerShape?.borderRadius, BorderRadius.zero);
      expect(theme.listTileTheme.selectedColor, colorScheme.primary);
      expect(
        theme.listTileTheme.selectedTileColor,
        colorScheme.primary.withAlpha(24),
      );
    }
  });

  test('Navivox themes use compact Telegram-like navigation list tiles', () {
    for (final theme in [navivoxLightTheme, navivoxDarkTheme]) {
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
  });

  test(
    'Navivox themes style the desktop rail with Telegram-blue selection',
    () {
      for (final theme in [navivoxLightTheme, navivoxDarkTheme]) {
        final colorScheme = theme.colorScheme;
        final railTheme = theme.navigationRailTheme;

        expect(railTheme.backgroundColor, colorScheme.surface);
        expect(railTheme.indicatorColor, colorScheme.primary.withAlpha(24));
        expect(railTheme.selectedIconTheme?.color, colorScheme.primary);
        expect(railTheme.selectedLabelTextStyle?.color, colorScheme.primary);
      }
    },
  );

  test('Navivox themes use subtle Telegram-like navigation dividers', () {
    for (final theme in [navivoxLightTheme, navivoxDarkTheme]) {
      final colorScheme = theme.colorScheme;

      expect(
        theme.dividerTheme.color,
        colorScheme.outlineVariant.withAlpha(
          theme.colorScheme.brightness == Brightness.dark ? 48 : 96,
        ),
      );
      expect(theme.dividerTheme.thickness, 1);
      expect(theme.dividerTheme.space, 1);
    }
  });

  test('Navivox themes keep cards flat with subtle Telegram-like outlines', () {
    for (final theme in [navivoxLightTheme, navivoxDarkTheme]) {
      final colorScheme = theme.colorScheme;
      final cardTheme = theme.cardTheme;
      final cardShape = cardTheme.shape as RoundedRectangleBorder?;

      expect(cardTheme.color, colorScheme.surface);
      expect(cardTheme.surfaceTintColor, Colors.transparent);
      expect(cardTheme.elevation, 0);
      expect(cardShape?.borderRadius, BorderRadius.circular(16));
      expect(cardShape?.side.color, colorScheme.outlineVariant.withAlpha(96));
      expect(cardShape?.side.width, 1);
    }
  });

  testWidgets('NavivoxApp exposes system light and dark themes', (
    tester,
  ) async {
    await tester.pumpWidget(const NavivoxApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.themeMode, ThemeMode.system);
    expect(app.theme?.colorScheme.brightness, Brightness.light);
    expect(app.darkTheme?.colorScheme.brightness, Brightness.dark);
  });

  testWidgets('NavivoxApp wraps routed content in a text selection area', (
    tester,
  ) async {
    await tester.pumpWidget(const NavivoxApp());

    expect(find.byType(SelectionArea), findsOneWidget);
  });
}
