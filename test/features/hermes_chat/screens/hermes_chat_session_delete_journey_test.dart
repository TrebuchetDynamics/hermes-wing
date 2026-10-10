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
const _target = 'target';

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
    }),
  );

  testWidgets('confirmed delete is scoped once and absent after reconnect', (
    tester,
  ) async {
    final h = await _pump(tester);
    await _openDelete(tester);
    expect(h.server.mutations, isEmpty, reason: 'Confirmation is required');
    await _confirmDelete(tester);
    expect(h.server.mutations, hasLength(1));
    final request = h.server.mutations.single;
    expect(request.method, 'DELETE');
    expect(request.uri.origin, _origin);
    expect(request.uri.path, '/api/sessions/target');
    expect(request.uri.queryParameters, {'profile': 'default'});
    expect(request.body, isNull);
    expect(h.server.rows, {
      'default': {'keep'},
      'b': {'keep', 'target'},
    });
    expect(h.channel.state.activeSessionId, 'keep');
    expect(
      find.byKey(const ValueKey('hermes-session-row-target')),
      findsNothing,
    );
    expect(find.text('Keep history default'), findsOneWidget);

    // Fresh server reads after clearing channel state establish absence
    // independently of the immediate local removal after the DELETE response.
    final readStart = h.server.requests.length;
    await h.channel.disconnect();
    expect(h.channel.state.sessions, isEmpty);
    await h.channel.connect(baseUrl: _origin);
    await tester.pumpAndSettle();
    final reads = h.server.requests.skip(readStart).toList();
    expect(reads.every((r) => r.method == 'GET'), isTrue);
    expect(
      reads
          .where((r) => r.uri.path == '/api/sessions')
          .map((r) => r.uri.queryParameters),
      [
        {'profile': 'default', 'limit': '50', 'offset': '0'},
      ],
    );
    expect(
      reads
          .where((r) => r.uri.path == '/api/sessions/keep/messages')
          .map((r) => r.uri.queryParameters),
      [
        {
          'profile': 'default',
          'limit': '500',
          'offset': '0',
          'order': 'latest',
        },
      ],
    );
    expect(h.channel.state.selectedProfileId, 'default');
    expect(h.channel.state.activeSessionId, 'keep');
    expect(h.channel.state.sessions.map((s) => s.id), ['keep']);
    expect(
      find.byKey(const ValueKey('hermes-session-row-target')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('hermes-session-row-keep')),
      findsOneWidget,
    );
    expect(find.text('Keep history default'), findsOneWidget);
    expect(
      h.server.mutations,
      hasLength(1),
      reason: 'No create/send/approval/Stop/replay',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel submits nothing and preserves both owners rows', (
    tester,
  ) async {
    final h = await _pump(tester);
    final requestsBefore = h.server.requests.length;
    await _openDelete(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancel'),
      ),
    );
    await tester.pumpAndSettle();
    expect(h.server.mutations, isEmpty);
    expect(h.server.requests, hasLength(requestsBefore));
    expect(h.server.rows, {
      'default': {'keep', 'target'},
      'b': {'keep', 'target'},
    });
    expect(h.channel.state.activeSessionId, 'keep');
    expect(find.text('Keep history default'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('hermes-session-row-target')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('same-ID profile replacement rejects the old delete intent', (
    tester,
  ) async {
    final h = await _pump(tester);
    await _openDelete(tester);
    await h.channel.selectProfile('b');
    await tester.pumpAndSettle();
    expect(h.channel.state.selectedProfileId, 'b');
    expect(h.channel.state.sessions.map((s) => s.id), ['keep', 'target']);
    final requestsBefore = h.server.requests.length;
    await _confirmDelete(tester);
    expect(h.server.mutations, isEmpty, reason: 'Neither owner may be deleted');
    expect(h.server.requests, hasLength(requestsBefore));
    expect(h.server.rows, {
      'default': {'keep', 'target'},
      'b': {'keep', 'target'},
    });
    expect(h.channel.state.activeSessionId, 'keep');
    expect(find.text('Keep history b'), findsOneWidget);
    expect(find.text('Target b'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

typedef _Request = ({String method, Uri uri, String? body});

// Only the HTTP seam is fake. Session parsing, capability/profile gates, channel
// state and the screen's mutation-intent fence all run production code.
class _SessionServer {
  final requests = <_Request>[];
  final rows = {
    'default': <String>{'keep', 'target'},
    'b': <String>{'keep', 'target'},
  };
  Iterable<_Request> get mutations => requests.where((r) => r.method != 'GET');

  Map<String, Object?> row(String id, String profile) => {
    'id': id,
    'source': 'api_server',
    'title': id == _target ? 'Target $profile' : 'Keep $profile',
    'message_count': 1,
  };

  Future<String> handle(String method, Uri uri, [String? body]) async {
    requests.add((method: method, uri: uri, body: body));
    expect(uri.origin, _origin);
    if (method == 'GET' && uri.path == '/health') {
      return jsonEncode({'status': 'ok'});
    }
    if (method == 'GET' && uri.path == '/v1/capabilities') {
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
          'profiles': {
            'method': 'GET',
            'path': '/api/profiles',
            'required_scopes': ['profiles:read'],
          },
          'session_delete': {
            'method': 'DELETE',
            'path': '/api/sessions/{session_id}',
            'required_scopes': ['sessions:write'],
          },
          'session_chat_stream': {
            'method': 'POST',
            'path': '/api/sessions/{session_id}/chat/stream',
          },
        },
      });
    }
    if (method == 'GET' && uri.path == '/api/profiles') {
      return jsonEncode({
        'data': [
          for (final id in rows.keys)
            {'id': id, 'name': id, 'revision': 'rev-$id'},
        ],
      });
    }
    final profile = uri.queryParameters['profile'];
    expect(rows, contains(profile), reason: 'Explicit known owner required');
    if (method == 'GET' && uri.path == '/api/sessions') {
      return jsonEncode({
        'data': [for (final id in rows[profile]!) row(id, profile!)],
      });
    }
    if (method == 'GET' &&
        RegExp(r'^/api/sessions/(keep|target)/messages$').hasMatch(uri.path)) {
      final id = uri.pathSegments[2];
      return jsonEncode({
        'object': 'list',
        'session_id': id,
        'data': [
          {
            'id': 'message-$profile-$id',
            'session_id': id,
            'role': 'assistant',
            'content': '${id == 'keep' ? 'Keep' : 'Target'} history $profile',
          },
        ],
      });
    }
    if (method == 'DELETE' && uri.path == '/api/sessions/target') {
      expect(body, isNull);
      expect(rows[profile]!.remove(_target), isTrue);
      return jsonEncode({'id': _target, 'deleted': true});
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
    getStream: (uri, _) => throw StateError('No stream read is expected'),
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

Future<void> _openDelete(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('hermes-session-menu-target')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Delete'));
  await tester.pumpAndSettle();
  expect(find.byType(AlertDialog), findsOneWidget);
  expect(
    find.byKey(const ValueKey('hermes-session-delete-confirm')),
    findsOneWidget,
  );
}

Future<void> _confirmDelete(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('hermes-session-delete-confirm')));
  await tester.pumpAndSettle();
}
