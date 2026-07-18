import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_health.dart';
import 'package:wing/core/hermes/models/hermes_profile.dart';
import 'package:wing/core/hermes/models/hermes_run.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/routes/app_routes.dart';

import '../support/fake_hermes_channel.dart';

Widget _testApp(FakeHermesChannel channel, {double textScale = 1}) =>
    ProviderScope(
      overrides: [hermesChannelProvider.overrideWithValue(channel)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const HermesChatScreen(),
      ),
    );

Widget _routerTestApp(FakeHermesChannel channel) {
  final router = GoRouter(
    initialLocation: AppRoutes.hermes,
    routes: [
      GoRoute(
        path: AppRoutes.hermes,
        builder: (_, _) => const HermesChatScreen(),
      ),
      GoRoute(
        path: AppRoutes.tools,
        builder: (_, _) => const Scaffold(body: Text('Tools destination')),
      ),
      GoRoute(
        path: AppRoutes.gateway,
        builder: (_, _) => const Scaffold(body: Text('Gateway destination')),
      ),
      GoRoute(
        path: AppRoutes.agents,
        builder: (_, _) => const Scaffold(body: Text('Agents destination')),
      ),
      GoRoute(
        path: AppRoutes.providers,
        builder: (_, _) => const Scaffold(body: Text('Providers destination')),
      ),
      GoRoute(
        path: AppRoutes.schedules,
        builder: (_, _) => const Scaffold(body: Text('Schedules destination')),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const Scaffold(body: Text('Settings destination')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [hermesChannelProvider.overrideWithValue(channel)],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  testWidgets('slash suggestions execute the local new-session command', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/n',
    );
    await tester.pump();

    expect(find.text('Wing commands'), findsOneWidget);
    expect(find.text('/new'), findsOneWidget);
    expect(find.text('/sessions'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('hermes-local-command-new')));
    await tester.pumpAndSettle();

    expect(channel.createSessionCalls, [null]);
    expect(channel.sentVoiceTranscripts, isEmpty);
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    expect(field.controller?.text, isEmpty);
  });

  testWidgets('slash suggestions remain usable at 200% text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel, textScale: 2));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/s',
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('/sessions'), findsOneWidget);
    expect(find.text('/settings'), findsOneWidget);
    expect(find.text('/new'), findsNothing);
  });

  testWidgets('exact local clear command never reaches Hermes', (tester) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/clear',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(channel.sentVoiceTranscripts, isEmpty);
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    expect(field.controller?.text, isEmpty);
  });

  testWidgets('local help command lists Wing-owned commands at 200% scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel, textScale: 2));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/help',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hermes-local-command-help')));
    await tester.pumpAndSettle();

    expect(find.text('Wing commands'), findsOneWidget);
    expect(find.text('/new'), findsOneWidget);
    expect(find.text('/usage'), findsOneWidget);
    expect(
      channel.state.activeMessages.where((turn) => turn.text == '/help'),
      isEmpty,
    );
  });

  testWidgets('local tools command opens the implemented Tools surface', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_routerTestApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/tools',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(find.text('Tools destination'), findsOneWidget);
    expect(
      channel.state.activeMessages.where((turn) => turn.text == '/tools'),
      isEmpty,
    );
  });

  testWidgets('local skills command opens installed skill inventory', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_routerTestApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/skills',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(find.text('Tools destination'), findsOneWidget);
    expect(
      channel.state.activeMessages.where((turn) => turn.text == '/skills'),
      isEmpty,
    );
  });

  testWidgets('local agents command opens the implemented Agents surface', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_routerTestApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/agents',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(find.text('Agents destination'), findsOneWidget);
    expect(
      channel.state.activeMessages.where((turn) => turn.text == '/agents'),
      isEmpty,
    );
  });

  testWidgets('advertised persona command reads the selected profile SOUL', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: HermesCapabilityDocument.fromJson({
        'schema_version': 1,
        'auth': {
          'type': 'bearer',
          'required': true,
          'granted_scopes': ['profiles:read'],
        },
        'features': {'session_chat_streaming': true},
        'endpoints': {
          'session_chat_stream': {
            'method': 'POST',
            'path': '/api/sessions/{session_id}/chat/stream',
          },
          'profile_soul': {
            'method': 'GET',
            'path': '/api/profiles/{name}/soul',
            'required_scopes': ['profiles:read'],
          },
        },
      }),
      profiles: const [
        HermesProfile(id: 'coder', displayName: 'Coder', revision: 'profile-1'),
      ],
      selectedProfileId: 'coder',
      profileSoul: const HermesProfileSoul(
        soul: 'Be concise and verify every claim.',
        revision: 'soul-1',
      ),
    );
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/persona',
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('hermes-local-command-persona')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('hermes-local-command-persona')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coder persona'), findsOneWidget);
    expect(find.text('Be concise and verify every claim.'), findsOneWidget);
    expect(channel.readProfileSoulCalls, ['coder']);
    expect(
      channel.state.activeMessages.where((turn) => turn.text == '/persona'),
      isEmpty,
    );
  });

  testWidgets('persona control requires the granted profiles read scope', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: HermesCapabilityDocument.fromJson({
        'schema_version': 1,
        'auth': {
          'type': 'bearer',
          'required': true,
          'granted_scopes': <String>[],
        },
        'features': {'session_chat_streaming': true},
        'endpoints': {
          'session_chat_stream': {
            'method': 'POST',
            'path': '/api/sessions/{session_id}/chat/stream',
          },
          'profile_soul': {
            'method': 'GET',
            'path': '/api/profiles/{name}/soul',
            'required_scopes': ['profiles:read'],
          },
        },
      }),
      profiles: const [
        HermesProfile(id: 'coder', displayName: 'Coder', revision: 'p1'),
      ],
      selectedProfileId: 'coder',
    );
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/persona',
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-local-command-persona')),
      findsNothing,
    );
    expect(channel.readProfileSoulCalls, isEmpty);
  });

  testWidgets('unadvertised persona command stays server-owned', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/persona',
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-local-command-persona')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(channel.readProfileSoulCalls, isEmpty);
    expect(
      channel.state.activeMessages.any((turn) => turn.text == '/persona'),
      isTrue,
    );
  });

  testWidgets('advertised version command reports bounded gateway version', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: HermesCapabilityDocument.fromJson({
        'schema_version': 1,
        'auth': {
          'type': 'bearer',
          'required': true,
          'granted_scopes': ['gateway:read'],
        },
        'features': {'session_chat_streaming': true},
        'endpoints': {
          'session_chat_stream': {
            'method': 'POST',
            'path': '/api/sessions/{session_id}/chat/stream',
          },
          'health_detailed': {
            'method': 'GET',
            'path': '/health/detailed',
            'required_scopes': ['gateway:read'],
          },
        },
      }),
      detailedHealth: const HermesHealthStatus(
        status: 'ok',
        platform: 'hermes-agent',
        version: '0.18.0',
      ),
    );
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/version',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('hermes-local-command-version')),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Gateway version: hermes-agent 0.18.0'), findsOneWidget);
    expect(
      channel.state.activeMessages.where((turn) => turn.text == '/version'),
      isEmpty,
    );
  });

  testWidgets('local model command opens provider and model management', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_routerTestApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/model',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(find.text('Providers destination'), findsOneWidget);
    expect(
      channel.state.activeMessages.where((turn) => turn.text == '/model'),
      isEmpty,
    );
  });

  testWidgets(
    'local providers command opens the implemented Providers surface',
    (tester) async {
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      await tester.pumpWidget(_routerTestApp(channel));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('hermes-composer-field')),
        '/providers',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
      await tester.pumpAndSettle();

      expect(find.text('Providers destination'), findsOneWidget);
      expect(
        channel.state.activeMessages.where((turn) => turn.text == '/providers'),
        isEmpty,
      );
    },
  );

  testWidgets(
    'local schedules command opens the implemented Schedules surface',
    (tester) async {
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      await tester.pumpWidget(_routerTestApp(channel));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('hermes-composer-field')),
        '/schedules',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
      await tester.pumpAndSettle();

      expect(find.text('Schedules destination'), findsOneWidget);
      expect(
        channel.state.activeMessages.where((turn) => turn.text == '/schedules'),
        isEmpty,
      );
    },
  );

  testWidgets('local settings command opens Wing settings without sending', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_routerTestApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/settings',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(find.text('Settings destination'), findsOneWidget);
    expect(
      channel.state.activeMessages.where((turn) => turn.text == '/settings'),
      isEmpty,
    );
  });

  testWidgets('local gateway command opens the implemented Gateway surface', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_routerTestApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/gateway',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(find.text('Gateway destination'), findsOneWidget);
    expect(
      channel.state.activeMessages.where((turn) => turn.text == '/gateway'),
      isEmpty,
    );
  });

  testWidgets('local usage command reports the latest server token counts', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Measure it.');
    channel.completeStreamingTurn(
      text: 'Measured.',
      usage: const HermesRunUsage(
        inputTokens: 12,
        outputTokens: 7,
        totalTokens: 19,
      ),
    );
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/usage',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pump();

    expect(
      find.text('Token usage: 12 input, 7 output, 19 total'),
      findsOneWidget,
    );
    expect(
      channel.state.activeMessages.where((turn) => turn.text == '/usage'),
      isEmpty,
    );
  });

  testWidgets('local usage command explains when metadata is unavailable', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/usage',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.text('No server-reported token usage is available yet.'),
      findsOneWidget,
    );
    expect(channel.state.activeMessages, isEmpty);
  });

  testWidgets('local commands cannot bypass an active run', (tester) async {
    final channel = FakeHermesChannel()..beginStreamingTurn('Running work');
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/new',
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-local-command-suggestions')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pump();

    expect(channel.createSessionCalls, isEmpty);
    expect(
      find.byKey(const ValueKey('hermes-queued-follow-up')),
      findsOneWidget,
    );
  });

  testWidgets('unknown slash commands remain server-owned messages', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '/retry',
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-local-command-suggestions')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(
      channel.state.activeMessages.any((turn) => turn.text == '/retry'),
      isTrue,
    );
  });
}
