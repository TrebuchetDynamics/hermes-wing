import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/hermes/channel/hermes_channel.dart';
import 'package:navivox/core/hermes/channel/hermes_api_channel.dart';
import 'package:navivox/core/hermes/hermes_api.dart';
import 'package:navivox/core/hermes/models/hermes_chat_turn.dart';
import 'package:navivox/core/protocol/voice/models/navivox_voice_run.dart';

part 'hermes_api_channel_tests/connection_tests.dart';
part 'hermes_api_channel_tests/direct_chat_tests.dart';
part 'hermes_api_channel_tests/run_failure_tests.dart';
part 'hermes_api_channel_tests/session_mutation_tests.dart';
part 'hermes_api_channel_tests/voice_tests.dart';
part 'hermes_api_channel_tests/lifecycle_race_tests.dart';
part 'hermes_api_channel_tests/run_transport_tests.dart';
part 'hermes_api_channel_tests/approval_stop_tests.dart';

void main() {
  _hermesApiChannelConnectionTests();
  _hermesApiChannelDirectChatTests();
  _hermesApiChannelRunFailureTests();
  _hermesApiChannelSessionMutationTests();
  _hermesApiChannelVoiceTests();
  _hermesApiChannelLifecycleRaceTests();
  _hermesApiChannelRunTransportTests();
  _hermesApiChannelApprovalStopTests();
  _hermesApiChannelProfileTests();
}

const _profileCapabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "schema_version": 1,
  "profile_context": {"type": "query", "name": "profile", "required": true, "default_profile_id": "default"},
  "auth": {"type": "bearer", "required": true, "granted_scopes": ["profiles:read", "profiles:write"]},
  "features": {"session_chat_streaming": true},
  "endpoints": {
    "session_create": {"method": "POST", "path": "/api/sessions"},
    "session_chat_stream": {"method": "POST", "path": "/api/sessions/{session_id}/chat/stream"},
    "profiles": {"method": "GET", "path": "/api/profiles", "required_scopes": ["profiles:read"]},
    "profile_create": {"method": "POST", "path": "/api/profiles", "required_scopes": ["profiles:write"]},
    "profile_update": {"method": "PATCH", "path": "/api/profiles/{profile_id}", "required_scopes": ["profiles:write"]},
    "profile_delete": {"method": "DELETE", "path": "/api/profiles/{profile_id}", "required_scopes": ["profiles:write"]},
    "profile_soul": {"method": "GET", "path": "/api/profiles/{profile_id}/soul", "profile_scoped": true, "required_scopes": ["profiles:read"]},
    "profile_soul_update": {"method": "PUT", "path": "/api/profiles/{profile_id}/soul", "profile_scoped": true, "required_scopes": ["profiles:write"]}
  }
}
''';

const _profilesFixture = '''
{
  "data": [
    {"id": "default", "name": "Default", "revision": "rev-d", "is_default": true},
    {"id": "coder", "name": "Coding Agent", "revision": "rev-c", "skills_count": 3}
  ]
}
''';

const _profilesAfterCreateFixture = '''
{
  "data": [
    {"id": "default", "name": "Default", "revision": "rev-d", "is_default": true},
    {"id": "coder", "name": "Coding Agent", "revision": "rev-c"},
    {"id": "writer", "name": "Writer", "revision": "rev-w"}
  ]
}
''';

const _coderSessionsFixture = '''
{
  "object": "list",
  "data": [
    {"id": "sess_9", "source": "api_server", "title": "Coder", "message_count": 1}
  ]
}
''';

const _coderMessagesFixture = '''
{
  "object": "list",
  "session_id": "sess_9",
  "data": [
    {"id": "msg_9", "session_id": "sess_9", "role": "assistant", "content": "Coder view"}
  ]
}
''';

const _capabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true},
  "features": {"session_chat_streaming": true},
  "endpoints": {
    "session_create": {"method": "POST", "path": "/api/sessions"},
    "session_chat_stream": {"method": "POST", "path": "/api/sessions/{session_id}/chat/stream"},
    "session_update": {"method": "PATCH", "path": "/api/sessions/{session_id}"},
    "session_delete": {"method": "DELETE", "path": "/api/sessions/{session_id}"},
    "session_fork": {"method": "POST", "path": "/api/sessions/{session_id}/fork"}
  }
}
''';

const _chatOnlyCapabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true},
  "features": {"session_chat_streaming": true},
  "endpoints": {
    "session_chat_stream": {"method": "POST", "path": "/api/sessions/{session_id}/chat/stream"}
  }
}
''';

const _sessionCreateCapabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true},
  "features": {"session_chat_streaming": true},
  "endpoints": {
    "session_create": {"method": "POST", "path": "/api/sessions"},
    "session_chat_stream": {"method": "POST", "path": "/api/sessions/{session_id}/chat/stream"}
  }
}
''';

const _noChatCapabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true},
  "features": {},
  "endpoints": {}
}
''';

const _catalogCapabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true},
  "features": {},
  "endpoints": {
    "models": {"method": "GET", "path": "/v1/models"},
    "skills": {"method": "GET", "path": "/v1/skills"},
    "toolsets": {"method": "GET", "path": "/v1/toolsets"}
  }
}
''';

const _jobsCapabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true},
  "features": {"jobs_admin": false},
  "endpoints": {
    "jobs": {"method": "GET", "path": "/api/jobs"}
  }
}
''';

const _healthCapabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true},
  "features": {},
  "endpoints": {
    "health_detailed": {"method": "GET", "path": "/health/detailed"}
  }
}
''';

const _runsWithoutStopCapabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true},
  "features": {
    "run_submission": true,
    "run_events_sse": true
  },
  "endpoints": {
    "runs": {"method": "POST", "path": "/v1/runs"},
    "run_events": {"method": "GET", "path": "/v1/runs/{run_id}/events"}
  }
}
''';

const _runsCapableCapabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true},
  "features": {
    "session_chat_streaming": true,
    "run_submission": true,
    "run_status": true,
    "run_events_sse": true,
    "run_stop": true,
    "run_approval_response": true,
    "tool_progress_events": true
  },
  "endpoints": {
    "runs": {"method": "POST", "path": "/v1/runs"},
    "run_status": {"method": "GET", "path": "/v1/runs/{run_id}"},
    "run_events": {"method": "GET", "path": "/v1/runs/{run_id}/events"},
    "run_approval": {"method": "POST", "path": "/v1/runs/{run_id}/approval"},
    "run_stop": {"method": "POST", "path": "/v1/runs/{run_id}/stop"}
  }
}
''';

const _modelsFixture = '''
{
  "object": "list",
  "data": [
    {"id": "hermes-agent", "owned_by": "hermes"}
  ]
}
''';

const _skillsFixture = '''
{
  "object": "list",
  "data": [
    {"name": "ascii-art", "description": "ASCII art generation", "category": "creative"},
    {"name": "github", "description": "GitHub workflow skill", "category": "github"}
  ]
}
''';

const _toolsetsFixture = '''
{
  "object": "list",
  "platform": "api_server",
  "data": [
    {"name": "default", "label": "Default Tools", "enabled": true, "configured": true, "tools": ["read_file"]},
    {"name": "web", "label": "Web Tools", "enabled": false, "configured": true, "tools": ["web_search"]}
  ]
}
''';

const _jobsFixture = '''
{
  "jobs": [
    {"id": "job_1", "name": "Morning check", "enabled": true, "schedule_display": "Daily"}
  ]
}
''';

class _ManualStringStream extends Stream<String> {
  void Function(String)? _onData;

  int cancelCount = 0;

  void emit(String value) => _onData?.call(value);

  @override
  StreamSubscription<String> listen(
    void Function(String event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _onData = onData;
    return _ManualStringSubscription(this);
  }
}

class _ManualStringSubscription implements StreamSubscription<String> {
  _ManualStringSubscription(this._stream);

  final _ManualStringStream _stream;
  bool _paused = false;

  @override
  Future<void> cancel() async {
    _stream.cancelCount += 1;
    // Intentionally keep callbacks installed so tests can simulate stale events
    // that arrive after channel-side cancellation.
  }

  @override
  void onData(void Function(String data)? handleData) {
    _stream._onData = handleData;
  }

  @override
  void onError(Function? handleError) {}

  @override
  void onDone(void Function()? handleDone) {}

  @override
  void pause([Future<void>? resumeSignal]) {
    _paused = true;
    resumeSignal?.whenComplete(resume);
  }

  @override
  void resume() {
    _paused = false;
  }

  @override
  bool get isPaused => _paused;

  @override
  Future<E> asFuture<E>([E? futureValue]) async => futureValue as E;
}

const _sessionsFixture = '''
{
  "object": "list",
  "data": [
    {"id": "sess_1", "source": "api_server", "title": "Demo", "message_count": 1}
  ]
}
''';

const _messagesFixture = '''
{
  "object": "list",
  "session_id": "sess_1",
  "data": [
    {"id": "msg_1", "session_id": "sess_1", "role": "user", "content": "Hello"}
  ]
}
''';

const _twoSessionsFixture = '''
{
  "object": "list",
  "data": [
    {"id": "sess_1", "source": "api_server", "title": "One", "message_count": 1},
    {"id": "sess_2", "source": "api_server", "title": "Two", "message_count": 1}
  ]
}
''';

const _reconciledMessagesFixture = '''
{
  "object": "list",
  "session_id": "sess_1",
  "data": [
    {"id": "msg_1", "session_id": "sess_1", "role": "user", "content": "Hello"},
    {"id": "msg_2", "session_id": "sess_1", "role": "assistant", "content": "Hi there"}
  ]
}
''';

const _duplicateMessagesFixture = '''
{
  "object": "list",
  "session_id": "sess_1",
  "data": [
    {"id": "msg_1", "session_id": "sess_1", "role": "user", "content": "Hello"},
    {"id": "msg_2", "session_id": "sess_1", "role": "user", "content": "Hello again"},
    {"id": "msg_3", "session_id": "sess_1", "role": "assistant", "content": "Old answer"}
  ]
}
''';

const _interleavedLaterReplyMessagesFixture = '''
{
  "object": "list",
  "session_id": "sess_1",
  "data": [
    {"id": "msg_1", "session_id": "sess_1", "role": "user", "content": "Hello"},
    {"id": "msg_2", "session_id": "sess_1", "role": "user", "content": "closed stream"},
    {"id": "msg_3", "session_id": "sess_1", "role": "user", "content": "newer question"},
    {"id": "msg_4", "session_id": "sess_1", "role": "assistant", "content": "newer answer"}
  ]
}
''';

void _hermesApiChannelProfileTests() {
  test('selectProfile keeps selection client-side and scopes profile-owned '
      'refreshes with the mandatory profile query', () async {
    final requests = <Uri>[];
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          requests.add(uri);
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _profileCapabilitiesFixture,
            '/api/sessions' =>
              uri.queryParameters['profile'] == 'coder'
                  ? _coderSessionsFixture
                  : _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            '/api/sessions/sess_9/messages' => _coderMessagesFixture,
            '/api/profiles' => _profilesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    requests.clear();

    await channel.selectProfile('coder');

    expect(channel.state.selectedProfileId, 'coder');
    expect(channel.state.profiles.map((p) => p.id), ['default', 'coder']);
    expect(channel.state.sessions.single.id, 'sess_9');
    expect(channel.state.activeSessionId, 'sess_9');
    expect(channel.state.activeMessages.single.text, 'Coder view');

    // The profile list is an administrative resource: no profile query.
    final profilesRequest = requests.firstWhere(
      (uri) => uri.path == '/api/profiles',
    );
    expect(profilesRequest.queryParameters.containsKey('profile'), isFalse);

    // Profile-owned session refresh retains ?profile=coder.
    final sessionsRequest = requests.firstWhere(
      (uri) => uri.path == '/api/sessions',
    );
    expect(sessionsRequest.queryParameters['profile'], 'coder');

    // Selection never calls a server active-profile endpoint.
    expect(requests.any((uri) => uri.path.contains('active')), isFalse);
  });

  test('createProfile refreshes the profile list after a successful '
      'mutation', () async {
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _profileCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            '/api/profiles' => _profilesAfterCreateFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async => jsonEncode({
          'profile': {'id': 'writer', 'name': 'Writer', 'revision': 'rev-w'},
        }),
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.createProfile(name: 'Writer');

    expect(channel.state.profiles.map((p) => p.id), [
      'default',
      'coder',
      'writer',
    ]);
  });

  test(
    'a 412 stale-revision conflict refreshes profiles and rethrows',
    () async {
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _profileCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              '/api/profiles' => _profilesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          patch: (uri, headers, body) async =>
              throw StateError('Hermes API returned HTTP 412'),
        ),
      );
      addTearDown(channel.dispose);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await expectLater(
        channel.renameProfile(
          profileId: 'coder',
          name: 'Renamed',
          revision: 'stale',
        ),
        throwsA(isA<StateError>()),
      );

      expect(channel.state.profiles.map((p) => p.id), ['default', 'coder']);
    },
  );

  test(
    'profile mutations and selection reject unadvertised endpoints before any '
    'network call',
    () async {
      var posted = false;
      var patched = false;
      var deleted = false;
      var put = false;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            posted = true;
            return '{}';
          },
          patch: (uri, headers, body) async {
            patched = true;
            return '{}';
          },
          delete: (uri, headers) async {
            deleted = true;
            return '{}';
          },
          put: (uri, headers, body) async {
            put = true;
            return '{}';
          },
        ),
      );
      addTearDown(channel.dispose);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await expectLater(channel.selectProfile('coder'), throwsStateError);
      await expectLater(channel.createProfile(name: 'X'), throwsStateError);
      await expectLater(
        channel.renameProfile(profileId: 'coder', name: 'X', revision: 'r'),
        throwsStateError,
      );
      await expectLater(
        channel.deleteProfile(profileId: 'coder', revision: 'r'),
        throwsStateError,
      );
      await expectLater(
        channel.writeProfileSoul(profileId: 'coder', soul: 'x', revision: 'r'),
        throwsStateError,
      );

      expect(posted, isFalse);
      expect(patched, isFalse);
      expect(deleted, isFalse);
      expect(put, isFalse);
      expect(channel.state.selectedProfileId, isNull);
    },
  );

  test(
    'profile edits reject a blank revision before any network call',
    () async {
      var patched = false;
      var deleted = false;
      var put = false;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _profileCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          patch: (uri, headers, body) async {
            patched = true;
            return '{}';
          },
          delete: (uri, headers) async {
            deleted = true;
            return '{}';
          },
          put: (uri, headers, body) async {
            put = true;
            return '{}';
          },
        ),
      );
      addTearDown(channel.dispose);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await expectLater(
        channel.renameProfile(profileId: 'coder', name: 'X', revision: '  '),
        throwsArgumentError,
      );
      await expectLater(
        channel.deleteProfile(profileId: 'coder', revision: ''),
        throwsArgumentError,
      );
      await expectLater(
        channel.writeProfileSoul(profileId: 'coder', soul: 'x', revision: ' '),
        throwsArgumentError,
      );

      expect(patched, isFalse);
      expect(deleted, isFalse);
      expect(put, isFalse);
    },
  );

  test('readProfileSoul and writeProfileSoul carry the profile query and '
      'If-Match', () async {
    Uri? soulGet;
    Uri? soulPut;
    String? ifMatch;
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          if (uri.path == '/api/profiles/coder/soul') {
            soulGet = uri;
            return jsonEncode({'soul': 'Be helpful.', 'revision': 'rev-c'});
          }
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _profileCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            '/api/profiles' => _profilesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        put: (uri, headers, body) async {
          soulPut = uri;
          ifMatch = headers['If-Match'];
          return jsonEncode({'soul': 'Be terse.', 'revision': 'rev-c2'});
        },
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    final soul = await channel.readProfileSoul('coder');
    expect(soul.soul, 'Be helpful.');
    expect(soulGet!.queryParameters['profile'], 'coder');

    await channel.writeProfileSoul(
      profileId: 'coder',
      soul: 'Be terse.',
      revision: 'rev-c',
    );
    expect(soulPut!.path, '/api/profiles/coder/soul');
    expect(soulPut!.queryParameters['profile'], 'coder');
    expect(ifMatch, 'rev-c');
  });

  test(
    'a profile mutation in flight during reconnect drops its stale refresh',
    () async {
      final createStarted = Completer<void>();
      final releaseCreate = Completer<void>();
      var profileListCalls = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _profileCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              '/api/profiles' => () {
                profileListCalls += 1;
                return _profilesAfterCreateFixture;
              }(),
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            createStarted.complete();
            await releaseCreate.future;
            return jsonEncode({
              'profile': {
                'id': 'writer',
                'name': 'Writer',
                'revision': 'rev-w',
              },
            });
          },
        ),
      );
      addTearDown(channel.dispose);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      // Start a create whose POST parks mid-flight, then fire a second connect
      // (a new connection generation and client) before it resolves.
      final create = channel.createProfile(name: 'Writer');
      await createStarted.future;
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      releaseCreate.complete();
      await create;

      // The stale mutation's post-mutation profile refresh is dropped by the
      // connection-generation check: it never lists profiles for the new
      // connection, and the fresh connect's empty profile list is preserved.
      expect(channel.state.status, HermesConnectionStatus.connected);
      expect(channel.state.profiles, isEmpty);
      expect(profileListCalls, 0);
    },
  );
}
