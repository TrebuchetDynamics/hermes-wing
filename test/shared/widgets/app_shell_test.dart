import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/app_routes.dart';
import 'package:wing/shared/widgets/app_shell.dart';

Widget _testApp(Widget home) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void _usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('mobile shell has no persistent navigation bar', (tester) async {
    _usePhoneSize(tester);

    await tester.pumpWidget(
      _testApp(
        const AppShell(
          location: AppRoutes.hermes,
          child: SizedBox(key: ValueKey('body')),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('body')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('header menu exposes every app destination', (tester) async {
    _usePhoneSize(tester);

    await tester.pumpWidget(
      _testApp(Scaffold(appBar: AppBar(actions: const [AppShellMenuButton()]))),
    );

    await tester.tap(find.byKey(const ValueKey('app-shell-menu-button')));
    await tester.pumpAndSettle();

    for (final label in [
      'Hermes',
      'Office',
      'Profiles',
      'Providers',
      'Tools',
      'Schedules',
      'Gateway',
      'Settings',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('active content can hide the header menu', (tester) async {
    _usePhoneSize(tester);
    appShellNavigationVisible.value = false;
    addTearDown(() => appShellNavigationVisible.value = true);

    await tester.pumpWidget(
      _testApp(Scaffold(appBar: AppBar(actions: const [AppShellMenuButton()]))),
    );

    expect(find.byKey(const ValueKey('app-shell-menu-button')), findsNothing);
  });

  testWidgets('desktop rail remains usable at 200% text scale', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const AppShell(
          location: AppRoutes.office,
          child: SizedBox(key: ValueKey('body')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Office'), findsOneWidget);
    expect(find.byKey(const ValueKey('body')), findsOneWidget);
  });

  testWidgets('desktop shell exposes Hermes and Settings destinations', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        const AppShell(
          location: AppRoutes.hermes,
          child: SizedBox(key: ValueKey('body')),
        ),
      ),
    );

    expect(find.text('HERMES ONE'), findsOneWidget);
    expect(find.text('Hermes'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });

  test('settings detail routes remain settings locations', () {
    expect(AppRoutes.isSettingsLocation(AppRoutes.settingsVoice), isTrue);
    expect(AppRoutes.isSettingsLocation(AppRoutes.settingsDiagnostics), isTrue);
  });
}
