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
const _fork = 'fork-child';
const _confirmedTitle = 'Server-confirmed branch';

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
    }),
  );

  testWidgets('branch submits once and reopens authoritative child history', (
    tester,
  ) async {
    final h = await _pump(tester);
    final before = h.server.requests.length;
    await _openBranch(tester);
    expect(h.server.requests, hasLength(before));
    await _confirmBranch(tester);
    final request = h.server.mutations.single;
    expect(request.method, 'POST');
    expect(request.uri.origin, _origin);
    expect(request.uri.path, '/api/sessions/target/fork');
    expect(request.uri.queryParameters, {'profile': 'default'});
    expect(jsonDecode(request.body!), {'id': _fork});
    expect(h.server.children, {'default'});
    expect(h.channel.state.activeSessionId, _fork);
    expect(h.channel.state.activeSession?.parentSessionId, _target);
    expect(h.channel.state.activeSession?.title, _confirmedTitle);
    expect(
      h.channel.state.activeMessages.single.text,
      'Target history default',
    );
    expect(find.text('Target history default'), findsOneWidget);
    expect(h.channel.state.sessions.map((s) => s.id), ['keep', _target, _fork]);
    expect(h.server.requests.skip(before).map(_route), [
      'POST /api/sessions/target/fork',
      'GET /api/sessions/fork-child/messages',
    ]);
    _expectMutationCounts(h.server, branches: 1);

    // Fresh child history after clearing channel state must replace the first
    // fork read, not inherit a cached source transcript.
    h.server.forkHistory = 'Authoritative child history after reconnect';
    final readStart = h.server.requests.length;
    await h.channel.disconnect();
    expect(h.channel.state.sessions, isEmpty);
    expect(h.channel.state.messages, isEmpty);
    await h.channel.connect(baseUrl: _origin);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('hermes-session-row-fork-child')),
    );
    await tester.pumpAndSettle();
    final reads = h.server.requests.skip(readStart).toList();
    expect(reads.map(_route), [
      'GET /health',
      'GET /v1/capabilities',
      'GET /api/sessions',
      'GET /api/sessions/keep/messages',
      'GET /api/sessions/fork-child/messages',
    ]);
    expect(
      reads
          .singleWhere((r) => r.uri.path == '/api/sessions')
          .uri
          .queryParameters,
      {'profile': 'default', 'limit': '50', 'offset': '0'},
    );
    expect(reads.last.uri.queryParameters, {
      'profile': 'default',
      'limit': '500',
      'offset': '0',
      'order': 'latest',
    });
    expect(h.channel.state.selectedProfileId, 'default');
    expect(h.channel.state.activeSessionId, _fork);
    expect(h.channel.state.activeSession?.parentSessionId, _target);
    expect(h.channel.state.activeSession?.title, _confirmedTitle);
    expect(h.channel.state.sessions.where((s) => s.id == _fork), hasLength(1));
    expect(h.channel.state.activeMessages.single.text, h.server.forkHistory);
    expect(find.text(h.server.forkHistory), findsOneWidget);
    expect(find.text('Target history default'), findsNothing);
    _expectMutationCounts(h.server, branches: 1);
    _printRequests('branch/reopen', h.server);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel submits no branch and preserves the conversation', (
    tester,
  ) async {
    final h = await _pump(tester);
    final before = h.server.requests.length;
    await _openBranch(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancel'),
      ),
    );
    await tester.pumpAndSettle();
    expect(h.server.requests, hasLength(before));
    expect(h.server.children, isEmpty);
    expect(h.channel.state.activeSessionId, 'keep');
    expect(find.text('Keep history default'), findsOneWidget);
    _expectMutationCounts(h.server, branches: 0);
    _printRequests('cancel', h.server);
    expect(tester.takeException(), isNull);
  });

  testWidgets('same-ID owner replacement rejects the old branch intent', (
    tester,
  ) async {
    final h = await _pump(tester);
    await _openBranch(tester);
    await h.channel.selectProfile('b');
    await tester.pumpAndSettle();
    expect(h.channel.state.sessions.any((s) => s.id == _target), isTrue);
    final before = h.server.requests.length;
    await _confirmBranch(tester);
    expect(h.server.requests, hasLength(before));
    expect(h.server.children, isEmpty);
    expect(h.channel.state.selectedProfileId, 'b');
    expect(h.channel.state.activeSessionId, 'keep');
    expect(find.text('Keep history b'), findsOneWidget);
    expect(find.text('Target b'), findsOneWidget);
    _expectMutationCounts(h.server, branches: 0);
    _printRequests('replacement', h.server);
    expect(tester.takeException(), isNull);
  });
}

String _route(_Request r) => '${r.method} ${r.uri.path}';

void _expectMutationCounts(_SessionServer server, {required int branches}) {
  expect(server.mutations, hasLength(branches));
  for (final verb in ['POST', 'PATCH', 'PUT', 'DELETE']) {
    expect(
      server.requests.where((r) => r.method == verb),
      hasLength(verb == 'POST' ? branches : 0),
      reason: 'No create/send/approval/Stop/replay',
    );
  }
}

void _printRequests(String journey, _SessionServer server) {
  final counts = <String, int>{};
  for (final request in server.requests) {
    final route =
        '${_route(request)} ${jsonEncode(request.uri.queryParameters)}';
    counts.update(route, (n) => n + 1, ifAbsent: () => 1);
  }
  // Only deterministic methods, routes and query maps, never request bodies.
  debugPrint(
    '$journey requests=${server.requests.length} mutations=${server.mutations.length} ${jsonEncode(counts)}',
  );
}

typedef _Request = ({String method, Uri uri, String? body});

// Only the HTTP seam is fake. Session parsing, capability/profile gates, channel
// state and the screen's mutation-intent fence all run production code.
class _SessionServer {
  final requests = <_Request>[];
  final profiles = ['default', 'b'];
  final children = <String>{};
  String forkHistory = 'Target history default';
  Iterable<_Request> get mutations => requests.where((r) => r.method != 'GET');

  Map<String, Object?> row(String id, String profile) => {
    'id': id,
    'source': 'api_server',
    'title': id == _fork
        ? _confirmedTitle
        : '${id == _target ? 'Target' : 'Keep'} $profile',
    if (id == _fork) 'parent_session_id': _target,
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
          'session_fork': {
            'method': 'POST',
            'path': '/api/sessions/{session_id}/fork',
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
    if (method == 'GET' && uri.path == '/api/sessions') {
      return jsonEncode({
        'data': [
          row('keep', profile!),
          row(_target, profile),
          if (children.contains(profile)) row(_fork, profile),
        ],
      });
    }
    if (method == 'GET' &&
        RegExp(
          r'^/api/sessions/(keep|target|fork-child)/messages$',
        ).hasMatch(uri.path)) {
      final id = uri.pathSegments[2];
      return jsonEncode({
        'object': 'list',
        'session_id': id,
        'data': [
          {
            'id': 'message-$profile-$id',
            'session_id': id,
            'role': 'assistant',
            'content': id == _fork
                ? forkHistory
                : '${id == 'keep' ? 'Keep' : 'Target'} history $profile',
          },
        ],
      });
    }
    if (method == 'POST' && uri.path == '/api/sessions/target/fork') {
      expect(jsonDecode(body!), {'id': _fork});
      expect(
        children.add(profile!),
        isTrue,
        reason: 'A branch is never replayed',
      );
      return jsonEncode({
        'object': 'hermes.session',
        'session': row(_fork, profile),
      });
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
  final channel = HermesApiChannel(
    clientBuilder: server.client,
    sessionIdFactory: () => _fork,
  );
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

Future<void> _openBranch(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('hermes-session-menu-target')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Branch'));
  await tester.pumpAndSettle();
}

Future<void> _confirmBranch(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('hermes-session-branch-confirm')));
  await tester.pumpAndSettle();
}
