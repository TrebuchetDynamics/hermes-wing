import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/settings/providers/theme_settings_provider.dart';
import 'package:wing/features/settings/screens/settings_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/theme/wing_theme.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';

void main() {
  testWidgets('the appearance section selects and persists mode and palette', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final channel = FakeHermesChannel.disconnected();
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Dark'), 200);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forest'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('wing.theme.mode'), 'dark');
    expect(prefs.getString('wing.theme.palette'), 'forest');
  });

  testWidgets('the appearance section stays usable at 200% text scale', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final channel = FakeHermesChannel.disconnected();
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('settings-palette-forest')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings-palette-forest')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      (await SharedPreferences.getInstance()).getString('wing.theme.palette'),
      'forest',
    );
  });

  test('defaults to the system mode and the Wing palette', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final settings = container.read(wingThemeSettingsProvider);
    expect(settings.mode, ThemeMode.system);
    expect(settings.palette, WingThemePalette.wing);
  });

  test('selections persist and reload', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(wingThemeSettingsProvider.notifier)
        .setMode(ThemeMode.dark);
    await container
        .read(wingThemeSettingsProvider.notifier)
        .setPalette(WingThemePalette.forest);

    final reloaded = ProviderContainer();
    addTearDown(reloaded.dispose);
    reloaded.read(wingThemeSettingsProvider);
    await reloaded.read(wingThemeSettingsProvider.notifier).loaded;

    final settings = reloaded.read(wingThemeSettingsProvider);
    expect(settings.mode, ThemeMode.dark);
    expect(settings.palette, WingThemePalette.forest);
  });

  test('an unknown stored palette falls back to Wing', () async {
    SharedPreferences.setMockInitialValues({
      'flutter.wing.theme.palette': 'neon-slime',
      'flutter.wing.theme.mode': 'disco',
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(wingThemeSettingsProvider);
    await container.read(wingThemeSettingsProvider.notifier).loaded;

    final settings = container.read(wingThemeSettingsProvider);
    expect(settings.mode, ThemeMode.system);
    expect(settings.palette, WingThemePalette.wing);
  });
}
