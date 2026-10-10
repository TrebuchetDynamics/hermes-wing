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
const _submittedTitle = 'Requested title';
const _confirmedTitle = 'Server-confirmed title';
const _target = 'target';

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
    }),
  );

  testWidgets('rename is scoped once and survives authoritative reopen', (
    tester,
  ) async {
    final h = await _pump(tester);
    await _openRename(tester);
    await tester.tap(find.byKey(const ValueKey('hermes-session-title-save')));
    await tester.pumpAndSettle();

    expect(h.server.mutations, hasLength(1));
    final request = h.server.mutations.single;
    expect(request.method, 'PATCH');
    expect(request.uri.origin, _origin);
    expect(request.uri.path, '/api/sessions/target');
    expect(request.uri.queryParameters, {'profile': 'default'});
    expect(jsonDecode(request.body!), {'title': _submittedTitle});
    expect(h.channel.state.activeSessionId, 'keep');
    expect(find.text(_confirmedTitle), findsOneWidget);
    expect(find.text(_submittedTitle), findsNothing);

    // Reconnect clears the channel's session state; the title must come from
    // another authoritative list read, not a locally cached rename draft.
    final readStart = h.server.requests.length;
    await h.channel.disconnect();
    await h.channel.connect(baseUrl: _origin);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hermes-session-row-target')));
    await tester.pumpAndSettle();

    final reopenReads = h.server.requests.skip(readStart).toList();
    expect(reopenReads.every((request) => request.method == 'GET'), isTrue);
    expect(
      reopenReads.where((request) => request.uri.path == '/api/sessions'),
      hasLength(1),
    );
    expect(
      reopenReads.where(
        (request) =>
            request.uri.path == '/api/sessions/target/messages' &&
            request.uri.queryParameters['profile'] == 'default',
      ),
      hasLength(1),
    );
    expect(h.channel.state.selectedProfileId, 'default');
    expect(h.channel.state.activeSessionId, _target);
    expect(
      h.channel.state.sessions.singleWhere((s) => s.id == _target).title,
      _confirmedTitle,
    );
    expect(find.text(_confirmedTitle), findsWidgets);
    expect(find.text('Target history default'), findsOneWidget);
    expect(
      h.server.mutations,
      hasLength(1),
      reason: 'No create, send or replay',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel submits nothing and preserves the conversation', (
    tester,
  ) async {
    final h = await _pump(tester);
    final requestsBefore = h.server.requests.length;
    await _openRename(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancel'),
      ),
    );
    await tester.pumpAndSettle();

    expect(h.server.mutations, isEmpty);
    expect(h.server.requests, hasLength(requestsBefore));
    expect(h.channel.state.activeSessionId, 'keep');
    expect(find.text('Keep history default'), findsOneWidget);
    expect(find.text('Target default'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('same-ID profile replacement rejects the old rename intent', (
    tester,
  ) async {
    final h = await _pump(tester);
    await _openRename(tester);
    await h.channel.selectProfile('b');
    await tester.pumpAndSettle();
    expect(h.channel.state.selectedProfileId, 'b');
    expect(h.channel.state.sessions.any((s) => s.id == _target), isTrue);
    final requestsBefore = h.server.requests.length;
    await tester.tap(find.byKey(const ValueKey('hermes-session-title-save')));
    await tester.pumpAndSettle();

    expect(h.server.mutations, isEmpty, reason: 'Neither owner may be renamed');
    expect(h.server.requests, hasLength(requestsBefore));
    expect(h.server.titles, {'default': 'Target default', 'b': 'Target b'});
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
  final titles = {'default': 'Target default', 'b': 'Target b'};
  Iterable<_Request> get mutations => requests.where((r) => r.method != 'GET');

  Map<String, Object?> row(String id, String profile) => {
    'id': id,
    'source': 'api_server',
    'title': id == _target ? titles[profile] : 'Keep $profile',
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
          'session_update': {
            'method': 'PATCH',
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
          for (final id in titles.keys)
            {'id': id, 'name': id, 'revision': 'rev-$id'},
        ],
      });
    }
    final profile = uri.queryParameters['profile'];
    expect(titles, contains(profile), reason: 'Explicit known owner required');
    if (method == 'GET' && uri.path == '/api/sessions') {
      return jsonEncode({
        'data': [row('keep', profile!), row(_target, profile)],
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
    if (method == 'PATCH' && uri.path == '/api/sessions/target') {
      expect(jsonDecode(body!), {'title': _submittedTitle});
      titles[profile!] = _confirmedTitle;
      return jsonEncode({'session': row(_target, profile)});
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

Future<void> _openRename(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('hermes-session-menu-target')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Rename'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('hermes-session-title-field')),
    '  $_submittedTitle  ',
  );
  await tester.pump();
}
