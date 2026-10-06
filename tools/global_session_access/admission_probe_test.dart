import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/hermes_api.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/app_routes.dart';
import 'package:wing/shared/widgets/app_shell.dart';

import '../../test/features/hermes_chat/support/fake_hermes_channel.dart';
import '../../test/features/hermes_chat/support/fake_hermes_endpoint_store.dart';
import '../../test/features/hermes_chat/support/fake_hermes_gateway_directory.dart';

// Diagnostic only: this file is outside test/ because its shell case is the
// intentionally RED requested outcome, not an implemented feature regression.
const capabilities = '''
{"object":"hermes.api_server.capabilities","platform":"test","model":"test",
 "features":{"session_chat_streaming":true},
 "endpoints":{"session_create":{"method":"POST","path":"/api/sessions"},
 "session_chat_stream":{"method":"POST","path":"/api/sessions/{session_id}/chat/stream"},
 "session_messages":{"method":"GET","path":"/api/sessions/{session_id}/messages"}}}
''';
const sessions = '''
{"data":[{"id":"synthetic-active","source":"test"},
{"id":"synthetic-other","source":"test"}]}
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'characterization: merely reading directory provider starts reads and replaces loaded owner',
    () async {
      final channel = FakeHermesChannel(
        sessionId: 'synthetic-other',
        connectedBaseUrl: 'http://127.0.0.1:8642',
        selectedProfileId: 'default',
      );
      addTearDown(channel.dispose);
      final cache = FakeGatewayContactCache()
        ..selection = const GatewayContactSelection(
          contactId: GatewayContactId(
            gatewayId: 'synthetic-saved',
            profileId: 'default',
          ),
          sessionId: 'sess_1',
        );
      final loader = FakeGatewaySummaryLoader({
        'synthetic-saved': gatewaySummary(['default']),
      });
      final container = ProviderContainer(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(
            FakeHermesEndpointStore(
              profiles: const [
                HermesEndpointConfig(
                  id: 'synthetic-saved',
                  baseUrl: 'http://127.0.0.1:8643',
                ),
              ],
            ),
          ),
          gatewayContactCacheProvider.overrideWithValue(cache),
          hermesGatewaySummaryLoaderProvider.overrideWithValue(loader),
        ],
      );
      addTearDown(container.dispose);
      expect(loader.calls, isEmpty);
      expect(channel.connectCalls, isEmpty);
      final directory = container.read(hermesGatewayDirectoryProvider);
      final settled = Completer<void>();
      void observe() {
        if (!directory.isActivating &&
            directory.activeContactId != null &&
            channel.state.activeSessionId == 'sess_1' &&
            !settled.isCompleted) {
          settled.complete();
        }
      }

      directory.addListener(observe);
      await settled.future.timeout(const Duration(seconds: 5));
      directory.removeListener(observe);
      expect(loader.calls, ['synthetic-saved']);
      expect(channel.connectCalls.map((call) => call.baseUrl), [
        'http://127.0.0.1:8643',
      ]);
      expect(channel.selectProfileCalls, ['default']);
      expect(channel.selectSessionCalls, ['sess_1']);
      expect(channel.state.activeSessionId, 'sess_1');
      expect(channel.state.connectedBaseUrl, 'http://127.0.0.1:8643');
    },
  );
  testWidgets('RED shell offers an exact loaded session on Tools', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final channel = FakeHermesChannel(
      sessions: const [
        HermesSession(
          id: 'synthetic-active',
          source: 'test',
          title: 'Synthetic active',
        ),
        HermesSession(
          id: 'synthetic-other',
          source: 'test',
          title: 'Synthetic other',
        ),
      ],
      activeSessionId: 'synthetic-active',
    );
    addTearDown(channel.dispose);
    final router = GoRouter(
      initialLocation: AppRoutes.tools,
      routes: [
        ShellRoute(
          builder: (_, state, child) =>
              AppShell(location: state.uri.path, child: child),
          routes: [
            for (final path in [AppRoutes.tools, AppRoutes.hermes])
              GoRoute(
                path: path,
                builder: (_, _) => Scaffold(body: Text('Page $path')),
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Page ${AppRoutes.tools}'), findsOneWidget);
    expect(channel.selectSessionCalls, isEmpty);
    expect(channel.createSessionCalls, isEmpty);
    expect(find.textContaining('Synthetic other'), findsOneWidget);
  });

  for (final action in ['select', 'create']) {
    test(
      'characterization: $action still commits after caller lifetime ends',
      () async {
        final started = Completer<void>();
        final response = Completer<String>();
        var callerAlive = true;
        var posts = 0;
        var historyReads = 0;
        final channel = HermesApiChannel(
          sessionIdFactory: () => 'synthetic-created',
          clientBuilder: (config) => HermesApiClient(
            config: config,
            get: (uri, headers) async {
              if (uri.path == '/api/sessions/synthetic-other/messages') {
                historyReads++;
                started.complete();
                return response.future;
              }
              return switch (uri.path) {
                '/health' => '{"status":"ok"}',
                '/v1/capabilities' => capabilities,
                '/api/sessions' => sessions,
                '/api/sessions/synthetic-active/messages' ||
                '/api/sessions/synthetic-created/messages' => '{"data":[]}',
                _ => throw StateError('unexpected synthetic GET'),
              };
            },
            post: (uri, headers, body) {
              expect(uri.path, '/api/sessions');
              expect((jsonDecode(body) as Map)['id'], 'synthetic-created');
              posts++;
              started.complete();
              return response.future;
            },
          ),
        );
        addTearDown(channel.dispose);
        await channel.connect(baseUrl: 'http://127.0.0.1:8642');
        expect(channel.state.activeSessionId, 'synthetic-active');
        final operation = action == 'select'
            ? channel.selectSession('synthetic-other')
            : channel.createSession();
        await started.future;
        // This is a presentation owner disappearing, not a channel disconnect.
        // The public methods have no way to convey the caller's invalidation.
        callerAlive = false;
        response.complete(
          action == 'select'
              ? '{"data":[]}'
              : '{"session":{"id":"synthetic-created","source":"test"}}',
        );
        await operation;
        expect(callerAlive, isFalse);
        expect(
          channel.state.activeSessionId,
          action == 'select' ? 'synthetic-other' : 'synthetic-created',
        );
        expect(posts, action == 'create' ? 1 : 0);
        expect(historyReads, action == 'select' ? 1 : 0);
      },
    );
  }

  test(
    'characterization: guarded restore rejects late history but clears active immediately',
    () async {
      final started = Completer<void>();
      final response = Completer<String>();
      var callerAlive = true;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            if (uri.path == '/api/sessions/synthetic-other/messages') {
              started.complete();
              return response.future;
            }
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => capabilities,
              '/api/sessions' => sessions,
              '/api/sessions/synthetic-active/messages' => '{"data":[]}',
              _ => throw StateError('unexpected synthetic GET'),
            };
          },
        ),
      );
      addTearDown(channel.dispose);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      final operation = channel.restoreSession(
        'synthetic-other',
        canAccept: () => callerAlive,
      );
      await started.future;
      expect(channel.state.activeSessionId, isNull);
      callerAlive = false;
      response.complete('{"data":[]}');
      expect(await operation, isFalse);
      expect(channel.state.activeSessionId, isNull);
    },
  );
}
