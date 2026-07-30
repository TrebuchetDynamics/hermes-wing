import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/app_routes.dart';
import 'package:wing/shared/widgets/app_shell.dart';

Widget _testApp(Widget home) => ProviderScope(
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the More tip shows once on phones and stays dismissed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        const AppShell(
          location: AppRoutes.hermes,
          child: SizedBox(key: ValueKey('body')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('wing-tip-moreDestinations')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('wing-tip-moreDestinations-dismiss')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('wing-tip-moreDestinations')),
      findsNothing,
    );

    // A fresh shell (same device) never shows it again.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      _testApp(
        const AppShell(
          location: AppRoutes.hermes,
          child: SizedBox(key: ValueKey('body')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('wing-tip-moreDestinations')),
      findsNothing,
    );
  });
  testWidgets('Office appears in More rather than the mobile bottom bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        const AppShell(
          location: AppRoutes.hermes,
          child: SizedBox(key: ValueKey('body')),
        ),
      ),
    );

    expect(find.text('Office'), findsNothing);
    expect(find.text('More'), findsOneWidget);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('Office'), findsOneWidget);
  });

  testWidgets('Agents appears in More rather than the mobile bottom bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        const AppShell(
          location: AppRoutes.hermes,
          child: SizedBox(key: ValueKey('body')),
        ),
      ),
    );

    expect(find.text('Agents'), findsNothing);
    expect(find.text('More'), findsOneWidget);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('Agents'), findsOneWidget);
  });

  testWidgets('Providers appears in More rather than the mobile bottom bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        const AppShell(
          location: AppRoutes.hermes,
          child: SizedBox(key: ValueKey('body')),
        ),
      ),
    );

    expect(find.text('Providers'), findsNothing);
    expect(find.text('More'), findsOneWidget);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('Providers'), findsOneWidget);
  });

  testWidgets('Tools appears in More rather than the mobile bottom bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        const AppShell(
          location: AppRoutes.hermes,
          child: SizedBox(key: ValueKey('body')),
        ),
      ),
    );

    expect(find.text('Tools'), findsNothing);
    expect(find.text('More'), findsOneWidget);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('Tools'), findsOneWidget);
  });

  testWidgets('Schedules appears in More rather than the mobile bottom bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        const AppShell(
          location: AppRoutes.hermes,
          child: SizedBox(key: ValueKey('body')),
        ),
      ),
    );

    expect(find.text('Schedules'), findsNothing);
    expect(find.text('More'), findsOneWidget);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('Schedules'), findsOneWidget);
  });

  testWidgets('Gateway appears in More rather than the mobile bottom bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        const AppShell(
          location: AppRoutes.hermes,
          child: SizedBox(key: ValueKey('body')),
        ),
      ),
    );

    expect(find.text('Gateway'), findsNothing);
    expect(find.text('More'), findsOneWidget);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('Gateway'), findsOneWidget);
  });

  testWidgets('desktop rail keeps Office usable at 200% text scale', (
    tester,
  ) async {
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

  testWidgets('mobile navigation stays compact and edge aligned', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        const AppShell(
          location: AppRoutes.hermes,
          child: SizedBox(key: ValueKey('body')),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(NavigationBar)).height,
      lessThanOrEqualTo(64),
    );
    expect(
      find.byKey(const ValueKey('mobile-navigation-surface')),
      findsOneWidget,
    );
  });

  testWidgets('mobile navigation yields space to the keyboard', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      _testApp(
        const AppShell(
          location: AppRoutes.hermes,
          child: SizedBox(key: ValueKey('body')),
        ),
      ),
    );

    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('active content can claim the full mobile screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    appShellNavigationVisible.value = false;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => appShellNavigationVisible.value = true);

    await tester.pumpWidget(
      _testApp(
        const AppShell(
          location: AppRoutes.hermes,
          child: SizedBox(key: ValueKey('body')),
        ),
      ),
    );

    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('app shell exposes Hermes and Settings destinations', (
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

    expect(find.byKey(const ValueKey('body')), findsOneWidget);
    expect(find.text('HERMES ONE'), findsOneWidget);
    expect(find.text('Hermes'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Chats'), findsNothing);
    expect(find.text('Gateways'), findsNothing);
    expect(find.text('Profiles'), findsNothing);
    expect(find.text('Memory'), findsNothing);
    expect(find.text('Config'), findsNothing);
  });

  test('settings detail routes remain settings locations', () {
    expect(AppRoutes.isSettingsLocation(AppRoutes.settingsVoice), isTrue);
    expect(AppRoutes.isSettingsLocation(AppRoutes.settingsDiagnostics), isTrue);
  });
}
