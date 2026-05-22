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
        colorScheme.outlineVariant.withAlpha(96),
      );
      expect(theme.dividerTheme.thickness, 1);
      expect(theme.dividerTheme.space, 1);
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
}
