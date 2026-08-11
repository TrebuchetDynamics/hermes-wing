import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wing/core/hermes/channel/hermes_channel_state.dart';
import 'package:wing/core/hermes/models/hermes_model_assignment.dart';
import 'package:wing/core/hermes/models/hermes_profile.dart';
import 'package:wing/core/hermes/models/hermes_toolset.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/app_routes.dart';
import 'package:wing/shared/widgets/app_shell.dart';

import '../../features/hermes_chat/support/fake_hermes_channel.dart';

Widget _testApp(Widget home, {FakeHermesChannel? channel, ThemeData? theme}) =>
    ProviderScope(
      overrides: [
        hermesChannelProvider.overrideWithValue(
          channel ?? FakeHermesChannel.disconnected(),
        ),
      ],
      child: MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
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
      final destination = find.widgetWithText(ListTile, label);
      if (destination.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          destination,
          120,
          scrollable: find.byType(Scrollable).last,
        );
      }
      expect(destination, findsOneWidget);
    }
  });

  testWidgets('mobile menu prioritizes destinations over status summary', (
    tester,
  ) async {
    _usePhoneSize(tester);

    await tester.pumpWidget(
      _testApp(Scaffold(appBar: AppBar(actions: const [AppShellMenuButton()]))),
    );

    await tester.tap(find.byKey(const ValueKey('app-shell-menu-button')));
    await tester.pumpAndSettle();

    for (final label in ['Hermes', 'Office', 'Profiles', 'Providers']) {
      expect(find.text(label).hitTestable(), findsOneWidget, reason: label);
    }
  });

  testWidgets('Android Back returns from a mobile menu destination', (
    tester,
  ) async {
    _usePhoneSize(tester);
    final router = GoRouter(
      initialLocation: '/source',
      routes: [
        GoRoute(
          path: '/source',
          builder: (context, state) => Scaffold(
            appBar: AppBar(actions: const [AppShellMenuButton()]),
            body: const Text('Source screen'),
          ),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) =>
              const Scaffold(body: Text('Settings screen')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(
            FakeHermesChannel.disconnected(),
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('app-shell-menu-button')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Settings'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings screen'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Source screen'), findsOneWidget);
  });

  testWidgets('mobile menu exposes bounded connected Hermes status', (
    tester,
  ) async {
    _usePhoneSize(tester);
    final channel = FakeHermesChannel(
      profiles: const [
        HermesProfile(
          id: 'mineru',
          displayName: 'Mineru',
          revision: 'profile-rev-1',
        ),
      ],
      selectedProfileId: 'mineru',
      skills: const ['memory', 'planning'],
      toolsets: const [
        HermesToolset(name: 'core', tools: ['web', 'terminal', 'web']),
      ],
      modelInventory: const HermesModelInventory(
        assignment: HermesModelAssignment(activeModel: 'qwen3'),
      ),
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      _testApp(
        Scaffold(appBar: AppBar(actions: const [AppShellMenuButton()])),
        channel: channel,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('app-shell-menu-button')));
    await tester.pumpAndSettle();

    expect(find.text('Gateway'), findsWidgets);
    expect(find.text('Connected · fake-hermes:8642'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Mineru'), findsOneWidget);
    expect(find.text('Model'), findsOneWidget);
    expect(find.text('qwen3'), findsOneWidget);
    expect(find.text('2 tools · 2 skills'), findsOneWidget);
  });

  testWidgets('desktop shell preserves the selected parent brightness', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        AppShell(
          location: AppRoutes.settings,
          child: Builder(
            builder: (context) =>
                const SizedBox(key: ValueKey('desktop-themed-content')),
          ),
        ),
        theme: ThemeData.light(),
      ),
    );

    final contentContext = tester.element(
      find.byKey(const ValueKey('desktop-themed-content')),
    );
    expect(Theme.of(contentContext).brightness, Brightness.light);
  });

  testWidgets('desktop shell shows the shared Hermes status bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final channel = FakeHermesChannel(
      selectedProfileId: 'default',
      profiles: const [
        HermesProfile(
          id: 'default',
          displayName: 'Default',
          revision: 'rev-1',
          model: 'profile-model',
        ),
      ],
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      _testApp(
        const AppShell(
          location: AppRoutes.hermes,
          child: SizedBox(key: ValueKey('body')),
        ),
        channel: channel,
      ),
    );

    expect(find.byKey(const ValueKey('app-shell-status-bar')), findsOneWidget);
    expect(find.text('Connected · fake-hermes:8642'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
    expect(find.text('profile-model'), findsOneWidget);
  });

  testWidgets('failed inventory never exposes stale tool or skill counts', (
    tester,
  ) async {
    _usePhoneSize(tester);
    final channel = FakeHermesChannel(
      skills: const ['stale-skill'],
      toolsets: const [
        HermesToolset(name: 'stale', tools: ['stale-tool']),
      ],
      optionalResourceErrors: const {
        HermesOptionalResource.skills: 'failed',
        HermesOptionalResource.toolsets: 'failed',
      },
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      _testApp(
        Scaffold(appBar: AppBar(actions: const [AppShellMenuButton()])),
        channel: channel,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('app-shell-menu-button')));
    await tester.pumpAndSettle();

    expect(find.text('Unavailable'), findsOneWidget);
    expect(find.text('1 tools · 1 skills'), findsNothing);
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
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(
            FakeHermesChannel.disconnected(),
          ),
        ],
        child: MaterialApp(
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
