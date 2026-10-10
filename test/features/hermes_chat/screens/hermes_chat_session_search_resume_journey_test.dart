import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/core/hermes/client/hermes_api_config.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_hermes_gateway_directory.dart';

const _origin = 'https://example.invalid';
final _search = find.byKey(const ValueKey('hermes-session-rail-search-field'));
final _clear = find.byKey(const ValueKey('hermes-session-rail-search-clear'));
Finder _row(String id) => find.byKey(ValueKey('hermes-session-row-$id'));

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
    }),
  );

  testWidgets(
    'search selects exact owner and reopens authoritative history without replay',
    (tester) async {
      final h = await _pump(tester);
      final before = h.server.requests.length;
      final inventory = h.channel.state.sessions;
      await _query(tester, 'no matching row');
      expect(_row('keep'), findsNothing);
      expect(_row('target'), findsNothing);
      expect(h.channel.state.activeSessionId, 'keep');
      expect(find.text('Keep history default'), findsOneWidget);
      await _query(tester, '  TARGET DEFAULT  ');
      expect(_row('keep'), findsNothing);
      expect(_row('target'), findsOneWidget);
      expect(identical(h.channel.state.sessions, inventory), isTrue);
      expect(h.server.requests, hasLength(before));
      await tester.tap(_row('target'));
      await tester.pumpAndSettle();
      _expectConversation(
        tester,
        h.channel,
        'default',
        'target',
        'Target history default',
      );
      expect(h.server.requests.skip(before).map(_route), [
        'GET /api/sessions/target/messages',
      ]);
      final selected = h.channel.state.activeSession;
      final turns = h.channel.state.activeMessages;
      final clearStart = h.server.requests.length;
      await tester.tap(_clear);
      await tester.pumpAndSettle();
      expect(_row('keep'), findsOneWidget);
      expect(_row('target'), findsOneWidget);
      expect(h.server.requests, hasLength(clearStart));
      expect(h.channel.state.activeSession, same(selected));
      expect(h.channel.state.activeMessages, same(turns));
      _expectConversation(
        tester,
        h.channel,
        'default',
        'target',
        'Target history default',
      );

      h.server.targetHistory = 'Fresh server history after reconnect';
      final reconnectStart = h.server.requests.length;
      await h.channel.disconnect();
      expect(h.channel.state.messages, isEmpty);
      expect(h.channel.state.sessions, isEmpty);
      await h.channel.connect(baseUrl: _origin);
      await tester.pumpAndSettle();
      await _query(tester, 'target default');
      await tester.tap(_row('target'));
      await tester.pumpAndSettle();
      _expectConversation(
        tester,
        h.channel,
        'default',
        'target',
        h.server.targetHistory,
      );
      expect(find.text('Target history default'), findsNothing);
      expect(h.server.requests.skip(reconnectStart).map(_route), [
        'GET /health',
        'GET /v1/capabilities',
        'GET /api/sessions',
        'GET /api/sessions/keep/messages',
        'GET /api/sessions/target/messages',
      ]);
      final end = h.server.requests.length;
      await tester.tap(_clear);
      await tester.pumpAndSettle();
      expect(h.server.requests, hasLength(end));
      _expectConversation(
        tester,
        h.channel,
        'default',
        'target',
        h.server.targetHistory,
      );
      _receipt('search/reconnect', h.server, total: 10);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('late history cannot replace a newer same-profile selection', (
    tester,
  ) async {
    final h = await _pump(tester);
    final gate = h.server.delayTarget();
    await _query(tester, 'target');
    await tester.tap(_row('target'));
    await tester.pumpAndSettle();
    expect(h.server.started!.isCompleted, isTrue);
    final beforeClear = h.server.requests.length;
    await tester.tap(_clear);
    await tester.pumpAndSettle();
    expect(h.server.requests, hasLength(beforeClear));
    await tester.tap(_row('keep'));
    await tester.pumpAndSettle();
    _expectConversation(
      tester,
      h.channel,
      'default',
      'keep',
      'Keep history default',
    );
    final settled = h.channel.state;
    gate.complete(
      h.server.history('target', 'default', 'Obsolete target history'),
    );
    await tester.pumpAndSettle();
    expect(h.channel.state, same(settled));
    expect(h.channel.state.messages.containsKey('target'), isFalse);
    expect(find.text('Obsolete target history'), findsNothing);
    _expectConversation(
      tester,
      h.channel,
      'default',
      'keep',
      'Keep history default',
    );
    _receipt('new-selection', h.server, total: 6);
    expect(tester.takeException(), isNull);
  });

  for (final fails in [false, true]) {
    testWidgets(
      'same-ID profile replacement rejects obsolete history failure=$fails',
      (tester) async {
        final h = await _pump(tester);
        final gate = h.server.delayTarget();
        await _query(tester, 'target default');
        await tester.tap(_row('target'));
        await tester.pumpAndSettle();
        expect(h.server.started!.isCompleted, isTrue);
        await h.channel.selectProfile('b');
        await tester.pumpAndSettle();
        await _query(tester, 'target b');
        expect(_row('target'), findsOneWidget);
        expect(_row('keep'), findsNothing);
        await tester.tap(_row('target'));
        await tester.pumpAndSettle();
        _expectConversation(
          tester,
          h.channel,
          'b',
          'target',
          'Target history b',
        );
        final settled = h.channel.state;
        if (fails) {
          gate.completeError(StateError('Synthetic obsolete history failure'));
        } else {
          gate.complete(
            h.server.history('target', 'default', 'Obsolete owner history'),
          );
        }
        await tester.pumpAndSettle();
        expect(h.channel.state, same(settled));
        expect(find.text('Obsolete owner history'), findsNothing);
        expect(
          find.textContaining('Synthetic obsolete history failure'),
          findsNothing,
        );
        final beforeClear = h.server.requests.length;
        await tester.tap(_clear);
        await tester.pumpAndSettle();
        expect(h.server.requests, hasLength(beforeClear));
        _expectConversation(
          tester,
          h.channel,
          'b',
          'target',
          'Target history b',
        );
        _receipt('profile-replacement failure=$fails', h.server, total: 9);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<void> _query(WidgetTester tester, String query) async {
  await tester.enterText(_search, query);
  await tester.pumpAndSettle();
}

void _expectConversation(
  WidgetTester tester,
  HermesApiChannel channel,
  String profile,
  String id,
  String text,
) {
  expect(channel.state.selectedProfileId, profile);
  expect(channel.state.activeSessionId, id);
  expect(channel.state.activeSession?.id, id);
  expect(
    channel.state.activeSession?.title,
    '${id == 'target' ? 'Target' : 'Keep'} $profile',
  );
  expect(channel.state.activeMessages.single.sessionId, id);
  expect(channel.state.activeMessages.single.text, text);
  expect(find.text(text), findsOneWidget);
  expect(tester.widget<ListTile>(_row(id)).selected, isTrue);
}

String _route(_Request r) => '${r.method} ${r.uri.path}';
typedef _Request = ({String method, Uri uri, String? body});

void _receipt(String journey, _SessionServer server, {required int total}) {
  expect(server.requests, hasLength(total));
  expect(
    server.requests.every((r) => r.method == 'GET'),
    isTrue,
    reason:
        'Zero create/message/approval/Stop/replay mutations, including streaming',
  );
  final counts = <String, int>{};
  for (final r in server.requests) {
    final route = '${_route(r)} ${jsonEncode(r.uri.queryParameters)}';
    counts.update(route, (n) => n + 1, ifAbsent: () => 1);
  }
  debugPrint(
    '$journey requests=${server.requests.length} mutations=0 ${jsonEncode(counts)}',
  );
}

// Only transport functions and ancillary store/directory support are fake.
// Production filtering, callbacks, parsing, channel ownership and UI run intact.
class _SessionServer {
  final requests = <_Request>[];
  final profiles = ['default', 'b'];
  String targetHistory = 'Target history default';
  Completer<String>? delayed;
  Completer<void>? started;
  Completer<String> delayTarget() {
    started = Completer<void>();
    return delayed = Completer<String>();
  }

  String history(String id, String profile, String text) => jsonEncode({
    'object': 'list',
    'session_id': id,
    'data': [
      {
        'id': 'message-$profile-$id',
        'session_id': id,
        'role': 'assistant',
        'content': text,
      },
    ],
    'pagination': {'limit': 500, 'offset': 0, 'order': 'latest', 'returned': 1},
  });
  Future<String> handle(String method, Uri uri, [String? body]) async {
    requests.add((method: method, uri: uri, body: body));
    expect(uri.origin, _origin);
    if (method != 'GET') throw StateError('No mutation is allowed');
    if (uri.path == '/health') return '{"status":"ok"}';
    if (uri.path == '/v1/capabilities') {
      return jsonEncode({
        'schema_version': 1,
        'profile_context': {
          'type': 'query',
          'name': 'profile',
          'required': true,
          'default_profile_id': 'default',
        },
        'auth': {
          'type': 'bearer',
          'required': false,
          'granted_scopes': [
            'sessions:read',
            'sessions:write',
            'profiles:read',
          ],
        },
        'features': {'session_chat_streaming': true},
        'endpoints': {
          'sessions': {
            'method': 'GET',
            'path': '/api/sessions',
            'required_scopes': ['sessions:read'],
          },
          'session_messages': {
            'method': 'GET',
            'path': '/api/sessions/{session_id}/messages',
            'required_scopes': ['sessions:read'],
          },
          'profiles': {
            'method': 'GET',
            'path': '/api/profiles',
            'required_scopes': ['profiles:read'],
          },
          'session_create': {
            'method': 'POST',
            'path': '/api/sessions',
            'required_scopes': ['sessions:write'],
          },
          'session_chat_stream': {
            'method': 'POST',
            'path': '/api/sessions/{session_id}/chat/stream',
          },
        },
      });
    }
    if (uri.path == '/api/profiles') {
      return jsonEncode({
        'data': [
          for (final id in profiles)
            {'id': id, 'name': id, 'revision': 'rev-$id'},
        ],
      });
    }
    final profile = uri.queryParameters['profile'];
    expect(
      profiles,
      contains(profile),
      reason: 'Explicit known owner required',
    );
    if (uri.path == '/api/sessions') {
      expect(uri.queryParameters, {
        'profile': profile,
        'limit': '50',
        'offset': '0',
      });
      return jsonEncode({
        'data': [
          for (final id in ['keep', 'target'])
            {
              'id': id,
              'source': 'api_server',
              'title': '${id == 'target' ? 'Target' : 'Keep'} $profile',
              'message_count': 1,
            },
        ],
      });
    }
    if (RegExp(r'^/api/sessions/(keep|target)/messages$').hasMatch(uri.path)) {
      expect(uri.queryParameters, {
        'profile': profile,
        'limit': '500',
        'offset': '0',
        'order': 'latest',
      });
      final id = uri.pathSegments[2];
      if (id == 'target' && profile == 'default' && delayed != null) {
        final gate = delayed!;
        delayed = null;
        started!.complete();
        return gate.future;
      }
      return history(
        id,
        profile!,
        id == 'target' && profile == 'default'
            ? targetHistory
            : '${id == 'target' ? 'Target' : 'Keep'} history $profile',
      );
    }
    throw StateError('Unexpected deterministic request: $method $uri');
  }

  HermesApiClient client(HermesApiConfig config) => HermesApiClient(
    config: config,
    get: (uri, _) => handle('GET', uri),
    patch: (uri, _, body) => handle('PATCH', uri, body),
    post: (uri, _, body) => handle('POST', uri, body),
    put: (uri, _, body) => handle('PUT', uri, body),
    delete: (uri, _) => handle('DELETE', uri),
    postStream: (uri, _, body) {
      requests.add((method: 'POST', uri: uri, body: body));
      throw StateError('No streaming mutation is allowed');
    },
    getStream: (uri, _) {
      requests.add((method: 'GET', uri: uri, body: null));
      throw StateError('No stream read is expected');
    },
  );
}

Future<({HermesApiChannel channel, _SessionServer server})> _pump(
  WidgetTester tester,
) async {
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final server = _SessionServer();
  final channel = HermesApiChannel(clientBuilder: server.client);
  addTearDown(channel.dispose);
  await channel.connect(baseUrl: _origin);
  expect(channel.state.isConnected, isTrue, reason: channel.state.errorMessage);
  expect(channel.state.selectedProfileId, 'default');
  final store = FakeHermesEndpointStore();
  final directory = HermesGatewayDirectory(
    store: store,
    cache: FakeGatewayContactCache(),
    loader: FakeGatewaySummaryLoader({}),
    activeChannel: channel,
  );
  final container = ProviderContainer(
    overrides: [
      hermesChannelProvider.overrideWith((_) => channel),
      hermesEndpointStoreProvider.overrideWithValue(store),
      hermesGatewayDirectoryProvider.overrideWith((_) => directory),
      hermesVoiceCaptureServiceProvider.overrideWithValue(null),
      hermesTextToSpeechServiceProvider.overrideWithValue(null),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HermesChatScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.text('Keep history default'), findsOneWidget);
  return (channel: channel, server: server);
}
