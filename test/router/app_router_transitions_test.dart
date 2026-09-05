import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/core/wing_link/local_wing_link_host.dart';
import 'package:wing/features/local_setup/providers/local_hermes_setup_provider.dart';
import 'package:wing/features/local_setup/screens/termux_hermes_setup_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/app_router.dart';
import 'package:wing/router/app_routes.dart';

import '../features/hermes_chat/support/fake_hermes_channel.dart';
import '../features/hermes_chat/support/fake_hermes_endpoint_store.dart';

void main() {
  testWidgets(
    'manual enrollment returns to the shell without duplicate pages',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final channel = FakeHermesChannel.disconnected();
      addTearDown(channel.dispose);
      final container = ProviderContainer(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(
            FakeHermesEndpointStore(profiles: const []),
          ),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(router.push(AppRoutes.enroll));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('hermes-enrollment-pair-choice')),
      );
      await tester.pumpAndSettle();
      final manual = find.byKey(
        const ValueKey('hermes-enrollment-manual-connect'),
      );
      await tester.ensureVisible(manual);
      await tester.tap(manual);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('hermes-connection-mode-local')),
        findsOneWidget,
      );
      expect(router.canPop(), isTrue);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Connect to Hermes'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.hermes);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.linux,
    }),
  );

  testWidgets(
    'phone setup returns to the pairing step of the existing chooser',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final channel = FakeHermesChannel.disconnected();
      addTearDown(channel.dispose);
      final container = ProviderContainer(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(
            FakeHermesEndpointStore(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      router.go(AppRoutes.enroll);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('hermes-enrollment-paste-link')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey('hermes-enrollment-local-setup')),
      );
      await tester.pumpAndSettle();
      for (final key in [
        'termux-ready',
        'termux-setup-finished',
        'termux-open-pairing',
      ]) {
        final action = find.byKey(ValueKey(key));
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pumpAndSettle();
      }
      expect(find.byType(TermuxHermesSetupScreen), findsNothing);
      expect(
        find.byKey(const ValueKey('hermes-enrollment-paste-link')),
        findsOneWidget,
      );
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.enroll);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'Linux setup opened from manual connection continues into pairing',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final channel = FakeHermesChannel.disconnected();
      addTearDown(channel.dispose);
      final host = LocalWingLinkHost(
        executablePath: '/opt/fixture/wing',
        runner: (_, args) async => LocalWingLinkProcessResult(
          exitCode: 0,
          stdout: args.first == 'setup'
              ? '{"protocol_version":2,"result":{"hermes_installed":true,"hermes_adopted":true,"gateway_started":true}}'
              : '{"protocol_version":2,"platform":"linux","hermes_installed":true,"hermes_healthy":true,"setup_available":true}',
        ),
      );
      final store = FakeHermesEndpointStore();
      final container = ProviderContainer(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(store),
          localWingLinkHostProvider.overrideWithValue(host),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      router.go(AppRoutes.addHermes);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final key in [
        'hermes-open-local-setup',
        'local-hermes-setup-action',
        'local-hermes-setup-confirm',
        'local-hermes-setup-continue',
      ]) {
        final action = find.byKey(ValueKey(key));
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pumpAndSettle();
      }
      expect(
        find.byKey(const ValueKey('hermes-enrollment-paste-link')),
        findsOneWidget,
      );
      expect(store.saveCalls, isEmpty);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  test('every shell destination builds a transition page', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(routerProvider);

    final shell = router.configuration.routes.first as ShellRoute;
    final destinations = shell.routes.cast<GoRoute>();
    expect(destinations, isNotEmpty);
    for (final route in destinations) {
      expect(
        route.pageBuilder,
        isNotNull,
        reason: '${route.path} should use the shared fade transition page',
      );
    }
  });

  test(
    'every route constant resolves through the router to a distinct screen',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      final context = _FakeContext();

      final constants = <String, String>{
        'AppRoutes.hermes': AppRoutes.hermes,
        'AppRoutes.addHermes': AppRoutes.addHermes,
        'AppRoutes.office': AppRoutes.office,
        'AppRoutes.profiles': AppRoutes.profiles,
        'AppRoutes.agents': AppRoutes.agents,
        'AppRoutes.legacyAgents': AppRoutes.legacyAgents,
        'AppRoutes.providers': AppRoutes.providers,
        'AppRoutes.tools': AppRoutes.tools,
        'AppRoutes.schedules': AppRoutes.schedules,
        'AppRoutes.gateway': AppRoutes.gateway,
        'AppRoutes.settings': AppRoutes.settings,
        'AppRoutes.settingsVoice': AppRoutes.settingsVoice,
        'AppRoutes.settingsDiagnostics': AppRoutes.settingsDiagnostics,
        'AppRoutes.enroll': AppRoutes.enroll,
        'AppRoutes.localSetup': AppRoutes.localSetup,
      };

      final screenIdentities = <String, Type>{};
      final redirectDestinations = <String>{};
      for (final MapEntry(key: name, value: location) in constants.entries) {
        final matchList = router.configuration.findMatch(Uri.parse(location));
        expect(
          matchList.isError,
          isFalse,
          reason: '$name ($location) should match a registered route',
        );
        final route = matchList.last.route;
        if (route.redirectOnly) {
          // Registered purely as a redirect (the legacy '/agents' alias) with
          // no screen of its own; the redirect callback is what makes the
          // constant resolvable, and the redirect itself is exercised by the
          // router tests that navigate to it.
          expect(
            route.redirect,
            isNotNull,
            reason: '$name ($location) should be a redirect-only route',
          );
          redirectDestinations.add(location);
          continue;
        }
        final state = _buildRouteState(
          matchList.last,
          router.configuration,
          matchList,
        );
        final pageBuilder = route.pageBuilder;
        final Widget? built;
        if (pageBuilder != null) {
          built =
              (pageBuilder(context, state) as CustomTransitionPage<void>).child;
        } else {
          built = route.builder!(context, state);
        }
        expect(built, isNotNull, reason: '$name should build a screen');
        final identity = _leafScreenWidget(built).runtimeType;
        final previous = screenIdentities.putIfAbsent(location, () => identity);
        expect(
          previous,
          same(identity),
          reason: '$name ($location) should not change screen identity',
        );
      }

      final destinations = constants.values.toSet()
        ..removeAll(redirectDestinations);
      expect(
        screenIdentities,
        hasLength(destinations.length),
        reason:
            'every distinct destination should resolve to a screen; '
            'AppRoutes.agents aliases AppRoutes.profiles and legacyAgents '
            'redirects, so they share a destination',
      );
      expect(
        screenIdentities.values.toSet(),
        hasLength(destinations.length),
        reason: 'every distinct destination should build a distinct screen',
      );
    },
  );

  test('root query redirects to Hermes instead of the router error page', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    addTearDown(router.dispose);
    final state = GoRouterState(
      router.configuration,
      uri: Uri.parse('/?foo=bar'),
      matchedLocation: '',
      fullPath: null,
      pathParameters: const {},
      pageKey: const ValueKey('/'),
    );

    expect(router.configuration.topRedirect(_FakeContext(), state), '/hermes');
  });

  test('Android local setup route builds the Termux guide', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    final matchList = router.configuration.findMatch(
      Uri.parse(AppRoutes.localSetup),
    );
    final route = matchList.last.route;
    final state = _buildRouteState(
      matchList.last,
      router.configuration,
      matchList,
    );

    expect(
      _leafScreenWidget(route.builder!(_FakeContext(), state)),
      isA<TermuxHermesSetupScreen>(),
    );
  });

  testWidgets('unknown routes explain the error and offer chat recovery', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    addTearDown(router.dispose);
    router.go('/missing-screen');

    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Page not found'), findsOneWidget);
    expect(
      find.text('Hermes Wing does not have a screen for /missing-screen.'),
      findsOneWidget,
    );
    final recovery = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Return to chat'),
    );
    expect(recovery.onPressed, isNotNull);

    recovery.onPressed!();
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.hermes);
  });

  testWidgets('the shared page fades its child in', (tester) async {
    final page = wingFadeThroughPage(
      key: const ValueKey('page'),
      child: const Text('destination', textDirection: TextDirection.ltr),
    );
    expect(page, isA<CustomTransitionPage<void>>());

    final transition = (page as CustomTransitionPage<void>).transitionsBuilder(
      _FakeContext(),
      const AlwaysStoppedAnimation(0.5),
      const AlwaysStoppedAnimation(0),
      const SizedBox(),
    );
    expect(transition, isA<FadeTransition>());
  });
}

class _FakeContext extends Fake implements BuildContext {}

// go_router 18 added required metadata to this internal test seam; keep the
// test runnable with the locked 17.x API until the dependency is upgraded.
GoRouterState _buildRouteState(
  dynamic match,
  dynamic configuration,
  dynamic matches,
) {
  try {
    return match.buildState(
          configuration,
          matches,
          metadata: const <String, dynamic>{},
        )
        as GoRouterState;
  } on NoSuchMethodError {
    return match.buildState(configuration, matches) as GoRouterState;
  }
}

/// The screen widget underneath the router's page and shell wrappers.
///
/// Shell destinations build the screen directly as the [CustomTransitionPage]
/// child. The enrollment and local-setup routes build theirs inside the
/// router's private _SelectableRoute shell; it cannot be named from tests, but
/// it is a thin single-child wrapper, so walking the child chain reaches the
/// real screen. No screen itself exposes a public child, so the walk stops at
/// the first leaf.
Widget _leafScreenWidget(Widget built) {
  var screen = built;
  for (var depth = 0; depth < 3; depth += 1) {
    if (screen is SelectionArea) {
      screen = screen.child;
      continue;
    }
    final Object? child;
    try {
      child = (screen as dynamic).child;
    } on NoSuchMethodError {
      break;
    }
    if (child is! Widget) break;
    screen = child;
  }
  return screen;
}
