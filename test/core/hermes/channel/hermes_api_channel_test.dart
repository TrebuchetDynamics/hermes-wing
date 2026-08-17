import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/channel/hermes_detached_run_store.dart';
import 'package:wing/core/hermes/hermes_api.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/core/protocol/voice/models/wing_voice_run.dart';

import '../../../features/hermes_chat/support/fake_hermes_channel.dart';

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
  _hermesApiChannelAudioTests();
  _hermesApiChannelProfileTests();
  _hermesApiChannelProviderModelTests();
  _hermesApiChannelJobsTests();
}

void _hermesApiChannelAudioTests() {
  test(
    'speech synthesis requires every declared endpoint scope before I/O',
    () async {
      var posted = false;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async => switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' =>
              '''
{
  "object":"hermes.api_server.capabilities",
  "platform":"test",
  "model":"test",
  "auth":{"type":"bearer","required":true,"granted_scopes":[]},
  "features":{"audio_api":true},
  "endpoints":{
    "audio_speak":{"method":"POST","path":"/api/audio/speak","required_scopes":["audio:speak"]}
  }
}''',
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          },
          post: (uri, headers, body) async {
            posted = true;
            return '{"data_url":"data:audio/wav;base64,AA=="}';
          },
        ),
      );
      addTearDown(channel.dispose);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      expect(() => channel.synthesizeSpeech('hello'), throwsStateError);

      expect(posted, isFalse);
    },
  );
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
    "profile_update": {"method": "PATCH", "path": "/api/profiles/{name}", "required_scopes": ["profiles:write"]},
    "profile_delete": {"method": "DELETE", "path": "/api/profiles/{name}", "required_scopes": ["profiles:write"]},
    "profile_soul": {"method": "GET", "path": "/api/profiles/{name}/soul", "profile_scoped": false, "required_scopes": ["profiles:read"]},
    "profile_soul_update": {"method": "PUT", "path": "/api/profiles/{name}/soul", "profile_scoped": false, "required_scopes": ["profiles:write"]}
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
  "auth": {"type": "bearer", "required": true, "granted_scopes": ["chat:read", "skills:read", "tools:read"]},
  "features": {},
  "endpoints": {
    "models": {"method": "GET", "path": "/v1/models"},
    "skills": {"method": "GET", "path": "/v1/skills", "required_scopes": ["skills:read"]},
    "toolsets": {"method": "GET", "path": "/v1/toolsets", "required_scopes": ["tools:read"]}
  }
}
''';

const _jobsCapabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true, "granted_scopes": ["tasks:read"]},
  "features": {"jobs_admin": false},
  "endpoints": {
    "jobs": {"method": "GET", "path": "/api/jobs", "required_scopes": ["tasks:read"]}
  }
}
''';

const _healthCapabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true, "granted_scopes": ["gateway:read"]},
  "features": {},
  "endpoints": {
    "health_detailed": {"method": "GET", "path": "/health/detailed", "required_scopes": ["gateway:read"]}
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
    {"id": "hermes-agent", "root": "hermes-agent", "parent": null, "owned_by": "hermes"},
    {"id": "fast", "root": "openrouter/example", "parent": "hermes-agent", "owned_by": "hermes"}
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

const _jobsFixtureUpdated = '''
{
  "jobs": [
    {"id": "job_2", "name": "Evening review", "enabled": false, "state": "paused", "schedule_display": "0 18 * * *"}
  ]
}
''';

class _MemoryDetachedRunStore implements HermesDetachedRunStore {
  List<HermesDetachedRunLease> leases = const [];

  @override
  Object get coordinationKey => this;

  @override
  Future<List<HermesDetachedRunLease>> load() async => List.of(leases);

  @override
  Future<void> save(List<HermesDetachedRunLease> leases) async {
    this.leases = List.of(leases);
  }
}

class _BlockingDetachedRunStore implements HermesDetachedRunStore {
  _BlockingDetachedRunStore({this.blockLoad = false});

  List<HermesDetachedRunLease> leases = const [];
  final saveSnapshots = <List<HermesDetachedRunLease>>[];
  final _saveCompleters = <Completer<void>>[];
  final bool blockLoad;
  final _loadCompleter = Completer<void>();
  int loadCalls = 0;

  int get saveCalls => saveSnapshots.length;

  @override
  Object get coordinationKey => this;

  @override
  Future<List<HermesDetachedRunLease>> load() async {
    loadCalls += 1;
    if (blockLoad) await _loadCompleter.future;
    return List.of(leases);
  }

  void completeLoad() => _loadCompleter.complete();

  @override
  Future<void> save(List<HermesDetachedRunLease> leases) async {
    final snapshot = List<HermesDetachedRunLease>.of(leases);
    saveSnapshots.add(snapshot);
    final completer = Completer<void>();
    _saveCompleters.add(completer);
    await completer.future;
    this.leases = snapshot;
  }

  void completeSave(int index) => _saveCompleters[index].complete();
}

class _DetachedRunStoreView implements HermesDetachedRunStore {
  const _DetachedRunStoreView({required this.backing, required this.key});

  final HermesDetachedRunStore backing;
  final Object key;

  @override
  Object get coordinationKey => key;

  @override
  Future<List<HermesDetachedRunLease>> load() => backing.load();

  @override
  Future<void> save(List<HermesDetachedRunLease> leases) =>
      backing.save(leases);
}

class _ThrowingLoadDetachedRunStore implements HermesDetachedRunStore {
  bool failLoad = true;
  List<HermesDetachedRunLease> leases = const [];
  int saveCalls = 0;

  @override
  Object get coordinationKey => this;

  @override
  Future<List<HermesDetachedRunLease>> load() => failLoad
      ? Future.error(StateError('secure read failed'))
      : Future.value(List.of(leases));

  @override
  Future<void> save(List<HermesDetachedRunLease> leases) async {
    saveCalls += 1;
    this.leases = List.of(leases);
  }
}

class _FailingSaveNumberDetachedRunStore implements HermesDetachedRunStore {
  _FailingSaveNumberDetachedRunStore(this.failureNumber);

  final int failureNumber;
  List<HermesDetachedRunLease> leases = const [];
  int saveCalls = 0;

  @override
  Object get coordinationKey => this;

  @override
  Future<List<HermesDetachedRunLease>> load() async => List.of(leases);

  @override
  Future<void> save(List<HermesDetachedRunLease> leases) async {
    saveCalls += 1;
    if (saveCalls == failureNumber) throw StateError('save failed');
    this.leases = List.of(leases);
  }
}

class _FailFirstDetachedRunStore implements HermesDetachedRunStore {
  _FailFirstDetachedRunStore({this.failures = 1});

  final int failures;
  List<HermesDetachedRunLease> leases = const [];
  int saveCalls = 0;

  @override
  Object get coordinationKey => this;

  @override
  Future<List<HermesDetachedRunLease>> load() async => List.of(leases);

  @override
  Future<void> save(List<HermesDetachedRunLease> leases) async {
    saveCalls += 1;
    if (saveCalls <= failures) throw StateError('save failed');
    this.leases = List.of(leases);
  }
}

class _BlockingFailSaveDetachedRunStore implements HermesDetachedRunStore {
  List<HermesDetachedRunLease> leases = const [];
  final saveStarted = Completer<void>();
  final releaseSave = Completer<void>();
  int saveCalls = 0;

  @override
  Object get coordinationKey => this;

  @override
  Future<List<HermesDetachedRunLease>> load() async => List.of(leases);

  @override
  Future<void> save(List<HermesDetachedRunLease> leases) async {
    saveCalls += 1;
    if (saveCalls == 1) {
      saveStarted.complete();
      await releaseSave.future;
      throw StateError('save failed');
    }
    this.leases = List.of(leases);
  }
}

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

class _ThrowingListenStringStream extends Stream<String> {
  @override
  StreamSubscription<String> listen(
    void Function(String event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => throw StateError('listen failed synchronously');
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
  test(
    'history refresh keeps server timestamps and known per-turn usage',
    () async {
      var messageReads = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                messageReads++ == 0
                    ? '''{"object":"list","data":[{"id":"live-id","session_id":"sess_1","role":"assistant","content":"white\\n","timestamp":"2026-08-07T12:00:00Z","usage":{"input_tokens":100,"output_tokens":1,"total_tokens":101}}]}'''
                    : '''{"object":"list","data":[{"id":"server-id","session_id":"sess_1","role":"assistant","content":"white","timestamp":"2026-08-07T12:00:00Z"}]}''',
              _ => throw StateError('unexpected GET $uri'),
            };
          },
        ),
      );
      addTearDown(channel.dispose);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      await channel.disconnect();
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      final turn = channel.state.activeMessages.single;
      expect(turn.id, 'server-id');
      expect(turn.createdAt, DateTime.parse('2026-08-07T12:00:00Z').toLocal());
      expect(turn.usage?.inputTokens, 100);
      expect(turn.usage?.outputTokens, 1);
      expect(turn.usage?.totalTokens, 101);

      await channel.disconnect();
      await channel.connect(
        baseUrl: 'http://127.0.0.1:8642',
        apiKey: 'different-credential',
      );
      expect(channel.state.activeMessages.single.usage, isNull);
    },
  );

  test('history metadata does not cross profile boundaries', () async {
    var messageReads = 0;
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _profileCapabilitiesFixture,
            '/api/profiles' => _profilesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' =>
              messageReads++ == 0
                  ? '''{"object":"list","data":[{"id":"same-id","session_id":"sess_1","role":"assistant","content":"same","timestamp":"2026-08-07T12:00:00Z","usage":{"input_tokens":8,"output_tokens":2,"total_tokens":10}}]}'''
                  : '''{"object":"list","data":[{"id":"same-id","session_id":"sess_1","role":"assistant","content":"same","timestamp":"2026-08-07T12:00:00Z"}]}''',
            _ => throw StateError('unexpected GET $uri'),
          };
        },
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    expect(channel.state.activeMessages.single.usage?.totalTokens, 10);

    await channel.selectProfile('coder');

    expect(channel.state.selectedProfileId, 'coder');
    expect(channel.state.activeMessages.single.usage, isNull);
  });

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
    channel.startVoiceRun();
    requests.clear();

    await channel.selectProfile('coder');

    expect(channel.state.selectedProfileId, 'coder');
    expect(channel.state.profiles.map((p) => p.id), ['default', 'coder']);
    expect(channel.state.sessions.single.id, 'sess_9');
    expect(channel.state.activeSessionId, 'sess_9');
    expect(channel.state.activeMessages.single.text, 'Coder view');
    expect(channel.state.messages.keys, ['sess_9']);
    expect(channel.state.voiceRuns, isEmpty);
    expect(channel.state.activeVoiceRunId, isNull);

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

  test('a late profile selection cannot replace a newer profile snapshot', () async {
    final capabilityMap =
        jsonDecode(_profileCapabilitiesFixture) as Map<String, dynamic>;
    (capabilityMap['auth'] as Map<String, dynamic>)['granted_scopes'] = [
      'profiles:read',
      'profiles:write',
      'skills:read',
      'tools:read',
      'tasks:read',
    ];
    (capabilityMap['endpoints'] as Map<String, dynamic>).addAll({
      'models': {'method': 'GET', 'path': '/v1/models'},
      'skills': {
        'method': 'GET',
        'path': '/v1/skills',
        'required_scopes': ['skills:read'],
      },
      'toolsets': {
        'method': 'GET',
        'path': '/v1/toolsets',
        'required_scopes': ['tools:read'],
      },
      'jobs': {
        'method': 'GET',
        'path': '/api/jobs',
        'required_scopes': ['tasks:read'],
      },
    });
    final coderSessionsStarted = Completer<void>();
    final releaseCoderSessions = Completer<void>();
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          final profile = uri.queryParameters['profile'] ?? 'default';
          if (uri.path == '/api/sessions' && profile == 'coder') {
            coderSessionsStarted.complete();
            await releaseCoderSessions.future;
          }
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => jsonEncode(capabilityMap),
            '/api/profiles' => _profilesAfterCreateFixture,
            '/api/sessions' =>
              '{"data":[{"id":"session-$profile","source":"test","title":"$profile"}]}',
            _ when uri.path.startsWith('/api/sessions/session-') =>
              '{"data":[{"id":"message-$profile","role":"assistant","content":"$profile message"}]}',
            '/v1/models' =>
              '{"data":[{"id":"$profile-model","owned_by":"test"}]}',
            '/v1/skills' =>
              '{"data":[{"name":"$profile-skill","description":"test","category":"test"}]}',
            '/v1/toolsets' =>
              '{"data":[{"name":"$profile-tools","enabled":true,"configured":true,"tools":[]}]}',
            '/api/jobs' =>
              '{"jobs":[{"id":"$profile-job","name":"$profile job","enabled":true}]}',
            _ => throw StateError('unexpected GET $uri'),
          };
        },
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    final selectingCoder = channel.selectProfile('coder');
    await coderSessionsStarted.future;
    await channel.selectProfile('writer');
    releaseCoderSessions.complete();
    await selectingCoder;

    expect(channel.state.selectedProfileId, 'writer');
    expect(channel.state.sessions.single.id, 'session-writer');
    expect(channel.state.activeMessages.single.text, 'writer message');
    expect(channel.state.models, ['writer-model']);
    expect(channel.state.skills, ['writer-skill']);
    expect(channel.state.enabledToolsets, ['writer-tools']);
    expect(channel.state.jobs.single.id, 'writer-job');
    expect(channel.state.providers, isEmpty);
    expect(channel.state.modelInventory, isNull);
  });

  test(
    'selectProfile accepts a topology-discovered profile with declared context',
    () async {
      final requests = <Uri>[];
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            requests.add(uri);
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _profileCapabilitiesFixture,
              '/api/sessions' => _coderSessionsFixture,
              '/api/sessions/sess_9/messages' => _coderMessagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
        ),
      );
      addTearDown(channel.dispose);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      requests.clear();

      await channel.selectProfile('coder', allowDiscovered: true);

      expect(channel.state.selectedProfileId, 'coder');
      expect(channel.state.profiles.single.id, 'coder');
      expect(requests.any((uri) => uri.path == '/api/profiles'), isFalse);
      expect(
        requests
            .firstWhere((uri) => uri.path == '/api/sessions')
            .queryParameters['profile'],
        'coder',
      );
    },
  );

  test('selectProfile never reuses inventory from the prior profile when '
      'refreshes fail', () async {
    final capabilityMap =
        jsonDecode(_profileCapabilitiesFixture) as Map<String, dynamic>;
    final endpoints = capabilityMap['endpoints'] as Map<String, dynamic>;
    final auth = capabilityMap['auth'] as Map<String, dynamic>;
    auth['granted_scopes'] = [
      'profiles:read',
      'profiles:write',
      'chat:read',
      'skills:read',
      'tools:read',
      'tasks:read',
    ];
    endpoints.addAll({
      'models': {'method': 'GET', 'path': '/v1/models'},
      'skills': {
        'method': 'GET',
        'path': '/v1/skills',
        'required_scopes': ['skills:read'],
      },
      'toolsets': {
        'method': 'GET',
        'path': '/v1/toolsets',
        'required_scopes': ['tools:read'],
      },
      'jobs': {
        'method': 'GET',
        'path': '/api/jobs',
        'required_scopes': ['tasks:read'],
      },
    });
    final capabilities = jsonEncode(capabilityMap);
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          final selectingCoder = uri.queryParameters['profile'] == 'coder';
          if (selectingCoder &&
              const {
                '/v1/models',
                '/v1/skills',
                '/v1/toolsets',
                '/api/jobs',
              }.contains(uri.path)) {
            throw StateError('coder inventory unavailable');
          }
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => capabilities,
            '/api/sessions' =>
              selectingCoder ? _coderSessionsFixture : _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            '/api/sessions/sess_9/messages' => _coderMessagesFixture,
            '/api/profiles' => _profilesFixture,
            '/v1/models' => _modelsFixture,
            '/v1/skills' => _skillsFixture,
            '/v1/toolsets' => _toolsetsFixture,
            '/api/jobs' => _jobsFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    expect(channel.state.models, isNotEmpty);
    expect(channel.state.skills, isNotEmpty);
    expect(channel.state.enabledToolsets, isNotEmpty);
    expect(channel.state.jobs, isNotEmpty);

    await channel.selectProfile('coder');

    expect(channel.state.models, isEmpty);
    expect(channel.state.skills, isEmpty);
    expect(channel.state.enabledToolsets, isEmpty);
    expect(channel.state.jobs, isEmpty);
    expect(channel.state.optionalResourceErrors.keys, {
      HermesOptionalResource.models,
      HermesOptionalResource.skills,
      HermesOptionalResource.toolsets,
      HermesOptionalResource.jobs,
    });
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
    'deleting the selected profile adopts a surviving profile context',
    () async {
      var deleted = false;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _profileCapabilitiesFixture,
              '/api/profiles' =>
                deleted
                    ? '''{"data":[{"id":"default","name":"Default","revision":"rev-d","is_default":true}]}'''
                    : _profilesFixture,
              '/api/sessions' =>
                uri.queryParameters['profile'] == 'coder'
                    ? _coderSessionsFixture
                    : _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              '/api/sessions/sess_9/messages' => _coderMessagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          delete: (uri, headers) async {
            deleted = true;
            return '{"id":"coder","deleted":true}';
          },
        ),
      );
      addTearDown(channel.dispose);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      await channel.selectProfile('coder');
      expect(channel.state.activeSessionId, 'sess_9');

      await channel.deleteProfile(profileId: 'coder', revision: 'rev-c');

      expect(channel.state.profiles.map((profile) => profile.id), ['default']);
      expect(channel.state.selectedProfileId, 'default');
      expect(channel.state.activeSessionId, 'sess_1');
      expect(channel.state.activeMessages.single.text, 'Hello');
      expect(channel.state.messages.keys, ['sess_1']);
    },
  );

  test(
    'deleting the final profile clears every profile-owned snapshot',
    () async {
      var deleted = false;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _profileCapabilitiesFixture,
              '/api/profiles' => deleted ? '{"data":[]}' : _profilesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          delete: (uri, headers) async {
            deleted = true;
            return '{"id":"default","deleted":true}';
          },
        ),
      );
      addTearDown(channel.dispose);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      expect(channel.state.selectedProfileId, 'default');
      expect(channel.state.activeMessages, isNotEmpty);

      await channel.deleteProfile(profileId: 'default', revision: 'rev-d');

      expect(channel.state.profiles, isEmpty);
      expect(channel.state.selectedProfileId, isNull);
      expect(channel.state.sessions, isEmpty);
      expect(channel.state.activeSessionId, isNull);
      expect(channel.state.messages, isEmpty);
      expect(channel.state.providers, isEmpty);
      expect(channel.state.modelInventory, isNull);
    },
  );

  test(
    'deleting a profile preserves a newer concurrent survivor selection',
    () async {
      const profilesBefore = '''
{"data":[
  {"id":"default","name":"Default","revision":"rev-d","is_default":true},
  {"id":"coder","name":"Coder","revision":"rev-c"},
  {"id":"writer","name":"Writer","revision":"rev-w"}
]}''';
      const profilesAfter = '''
{"data":[
  {"id":"default","name":"Default","revision":"rev-d","is_default":true},
  {"id":"writer","name":"Writer","revision":"rev-w"}
]}''';
      final deleteStarted = Completer<void>();
      final finishDelete = Completer<void>();
      var deleted = false;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _profileCapabilitiesFixture,
              '/api/profiles' => deleted ? profilesAfter : profilesBefore,
              '/api/sessions' => '{"data":[]}',
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          delete: (uri, headers) async {
            deleteStarted.complete();
            await finishDelete.future;
            deleted = true;
            return '{"id":"coder","deleted":true}';
          },
        ),
      );
      addTearDown(channel.dispose);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      await channel.selectProfile('coder');

      final deleting = channel.deleteProfile(
        profileId: 'coder',
        revision: 'rev-c',
      );
      await deleteStarted.future;
      await channel.selectProfile('writer');
      finishDelete.complete();
      await deleting;

      expect(channel.state.profiles.map((profile) => profile.id), [
        'default',
        'writer',
      ]);
      expect(channel.state.selectedProfileId, 'writer');
    },
  );

  test(
    'deleting a profile cancels an in-flight selection of that profile',
    () async {
      final coderSessionsStarted = Completer<void>();
      final finishCoderSessions = Completer<void>();
      var deleted = false;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            if (uri.path == '/api/sessions' &&
                uri.queryParameters['profile'] == 'coder') {
              if (!coderSessionsStarted.isCompleted) {
                coderSessionsStarted.complete();
              }
              await finishCoderSessions.future;
              return _coderSessionsFixture;
            }
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _profileCapabilitiesFixture,
              '/api/profiles' =>
                deleted
                    ? '''{"data":[{"id":"default","name":"Default","revision":"rev-d","is_default":true}]}'''
                    : _profilesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              '/api/sessions/sess_9/messages' => _coderMessagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          delete: (uri, headers) async {
            deleted = true;
            return '{"id":"coder","deleted":true}';
          },
        ),
      );
      addTearDown(channel.dispose);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      final selecting = channel.selectProfile('coder');
      await coderSessionsStarted.future;
      await channel.deleteProfile(profileId: 'coder', revision: 'rev-c');
      finishCoderSessions.complete();
      await selecting;

      expect(channel.state.profiles.map((profile) => profile.id), ['default']);
      expect(channel.state.selectedProfileId, 'default');
      expect(channel.state.activeSessionId, 'sess_1');
    },
  );

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

  test('profile mutations require endpoint scope declarations', () async {
    final capabilityMap =
        jsonDecode(_profileCapabilitiesFixture) as Map<String, dynamic>;
    final endpoints = capabilityMap['endpoints'] as Map<String, dynamic>;
    (endpoints['profile_create'] as Map<String, dynamic>).remove(
      'required_scopes',
    );
    var posted = false;
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async => switch (uri.path) {
          '/health' => '{"status":"ok"}',
          '/v1/capabilities' => jsonEncode(capabilityMap),
          '/api/sessions' => _sessionsFixture,
          '/api/sessions/sess_1/messages' => _messagesFixture,
          _ => throw StateError('unexpected GET $uri'),
        },
        post: (uri, headers, body) async {
          posted = true;
          return '{}';
        },
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await expectLater(channel.createProfile(name: 'X'), throwsStateError);

    expect(posted, isFalse);
  });

  test('profile reads require profiles:read before network I/O', () async {
    final capabilityMap =
        jsonDecode(_profileCapabilitiesFixture) as Map<String, dynamic>;
    (capabilityMap['auth'] as Map<String, dynamic>)['granted_scopes'] = [];
    var profileRead = false;
    var soulRead = false;
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          if (uri.path == '/api/profiles') profileRead = true;
          if (uri.path.endsWith('/soul')) soulRead = true;
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => jsonEncode(capabilityMap),
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            '/api/profiles' => _profilesFixture,
            '/api/profiles/coder/soul' =>
              '{"soul":"persona","revision":"rev-1"}',
            _ => throw StateError('unexpected GET $uri'),
          };
        },
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await expectLater(channel.selectProfile('coder'), throwsStateError);
    await expectLater(channel.readProfileSoul('coder'), throwsStateError);

    expect(profileRead, isFalse);
    expect(soulRead, isFalse);
  });

  test('profile mutations require profiles:write before network I/O', () async {
    final capabilityMap =
        jsonDecode(_profileCapabilitiesFixture) as Map<String, dynamic>;
    (capabilityMap['auth'] as Map<String, dynamic>)['granted_scopes'] = [
      'profiles:read',
    ];
    var posted = false;
    var patched = false;
    var deleted = false;
    var put = false;
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async => switch (uri.path) {
          '/health' => '{"status":"ok"}',
          '/v1/capabilities' => jsonEncode(capabilityMap),
          '/api/sessions' => _sessionsFixture,
          '/api/sessions/sess_1/messages' => _messagesFixture,
          '/api/profiles' => _profilesFixture,
          _ => throw StateError('unexpected GET $uri'),
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
  });

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

const _providerModelCapabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "schema_version": 1,
  "profile_context": {"type": "query", "name": "profile", "required": true, "default_profile_id": "default"},
  "auth": {"type": "bearer", "required": true, "granted_scopes": ["profiles:read", "profiles:write", "providers:read", "providers:write", "models:read", "models:write"]},
  "features": {"session_chat_streaming": true},
  "endpoints": {
    "session_create": {"method": "POST", "path": "/api/sessions"},
    "session_chat_stream": {"method": "POST", "path": "/api/sessions/{session_id}/chat/stream"},
    "profiles": {"method": "GET", "path": "/api/profiles", "required_scopes": ["profiles:read"]},
    "providers": {"method": "GET", "path": "/api/providers", "profile_scoped": true, "required_scopes": ["providers:read"]},
    "provider_credential_set": {"method": "PUT", "path": "/api/providers/{slug}/credential", "profile_scoped": true, "required_scopes": ["providers:write"]},
    "provider_credential_delete": {"method": "DELETE", "path": "/api/providers/{slug}/credential", "profile_scoped": true, "required_scopes": ["providers:write"]},
    "provider_credential_validate": {"method": "POST", "path": "/api/providers/{slug}/credential/validate", "profile_scoped": true, "required_scopes": ["providers:write"]},
    "models": {"method": "GET", "path": "/api/models", "profile_scoped": true, "required_scopes": ["models:read"]},
    "models_refresh": {"method": "POST", "path": "/api/models/refresh", "profile_scoped": true, "required_scopes": ["models:write"]},
    "models_assignment": {"method": "PUT", "path": "/api/models/assignment", "profile_scoped": true, "required_scopes": ["models:write"]}
  }
}
''';

const _providerModelReadOnlyCapabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "schema_version": 1,
  "profile_context": {"type": "query", "name": "profile", "required": true, "default_profile_id": "default"},
  "auth": {"type": "bearer", "required": true, "granted_scopes": ["profiles:read", "providers:read", "models:read"]},
  "features": {"session_chat_streaming": true},
  "endpoints": {
    "session_create": {"method": "POST", "path": "/api/sessions"},
    "session_chat_stream": {"method": "POST", "path": "/api/sessions/{session_id}/chat/stream"},
    "profiles": {"method": "GET", "path": "/api/profiles", "required_scopes": ["profiles:read"]},
    "providers": {"method": "GET", "path": "/api/providers", "profile_scoped": true, "required_scopes": ["providers:read"]},
    "provider_credential_set": {"method": "PUT", "path": "/api/providers/{slug}/credential", "profile_scoped": true, "required_scopes": ["providers:write"]},
    "provider_credential_validate": {"method": "POST", "path": "/api/providers/{slug}/credential/validate", "profile_scoped": true, "required_scopes": ["providers:write"]},
    "models": {"method": "GET", "path": "/api/models", "profile_scoped": true, "required_scopes": ["models:read"]},
    "models_refresh": {"method": "POST", "path": "/api/models/refresh", "profile_scoped": true, "required_scopes": ["models:write"]},
    "models_assignment": {"method": "PUT", "path": "/api/models/assignment", "profile_scoped": true, "required_scopes": ["models:write"]}
  }
}
''';

String _providersFixtureBody({
  String keyHint = '····1234',
  bool configured = true,
}) {
  return jsonEncode({
    'data': [
      {
        'slug': 'openai',
        'label': 'OpenAI',
        'auth_type': 'api_key',
        'env_vars': ['OPENAI_API_KEY'],
        'configured': configured,
        'key_hint': configured ? keyHint : null,
      },
      {
        'slug': 'anthropic',
        'label': 'Anthropic',
        'auth_type': 'api_key',
        'env_vars': ['ANTHROPIC_API_KEY'],
        'configured': false,
        'key_hint': null,
      },
    ],
  });
}

const _modelsInventoryBody = '''
{
  "catalog": {"providers": {"openai": {"models": [{"id": "gpt-5", "description": "flagship"}]}}},
  "active": {"provider": "openai", "model": "gpt-5"},
  "auxiliary": [{"task": "title", "provider": "auto", "model": ""}],
  "revision": "mrev-1"
}
''';

/// Connects a channel with the provider/model capabilities and selects the
/// `default` profile so provider/model operations have a scoped profile.
Future<HermesApiChannel> _connectedProviderModelChannel({
  required String capabilities,
  Future<String?> Function(Uri uri)? get,
  Future<String> Function(Uri uri, String body)? put,
  Future<String> Function(Uri uri, String body)? post,
  Future<String> Function(Uri uri)? delete,
  List<Uri>? requests,
}) async {
  final channel = HermesApiChannel(
    clientBuilder: (config) => HermesApiClient(
      config: config,
      get: (uri, headers) async {
        requests?.add(uri);
        final custom = await get?.call(uri);
        if (custom != null) return custom;
        return switch (uri.path) {
          '/health' => '{"status":"ok"}',
          '/v1/capabilities' => capabilities,
          '/api/sessions' => _sessionsFixture,
          '/api/sessions/sess_1/messages' => _messagesFixture,
          '/api/profiles' => _profilesFixture,
          _ => throw StateError('unexpected GET $uri'),
        };
      },
      put: put == null
          ? null
          : (uri, headers, body) async {
              requests?.add(uri);
              return put(uri, body);
            },
      post: post == null
          ? null
          : (uri, headers, body) async {
              requests?.add(uri);
              return post(uri, body);
            },
      delete: delete == null
          ? null
          : (uri, headers) async {
              requests?.add(uri);
              return delete(uri);
            },
    ),
  );
  addTearDown(channel.dispose);
  await channel.connect(baseUrl: 'http://127.0.0.1:8642');
  await channel.selectProfile('default');
  requests?.clear();
  return channel;
}

void _hermesApiChannelJobsTests() {
  test('loadJobs refreshes advertised read-only inventory', () async {
    var jobsBody = _jobsFixture;
    final requests = <Uri>[];
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          requests.add(uri);
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _jobsCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            '/api/jobs' => jobsBody,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    expect(channel.state.jobs.single.id, 'job_1');
    requests.clear();
    jobsBody = _jobsFixtureUpdated;

    await channel.loadJobs();

    expect(requests.map((uri) => uri.path), ['/api/jobs']);
    expect(channel.state.jobs.single.id, 'job_2');
    expect(
      channel.state.optionalResourceErrors.containsKey(
        HermesOptionalResource.jobs,
      ),
      isFalse,
    );
  });

  test('loadJobs rejects an unadvertised route before network I/O', () async {
    final requests = <Uri>[];
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          requests.add(uri);
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _noChatCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    requests.clear();

    await expectLater(channel.loadJobs(), throwsStateError);

    expect(requests, isEmpty);
  });
}

void _hermesApiChannelProviderModelTests() {
  test('loadProviders scopes the request with ?profile= and stores presence '
      'without a full key', () async {
    const sentinel = 'sk-secret-value-1234';
    final requests = <Uri>[];
    final channel = await _connectedProviderModelChannel(
      capabilities: _providerModelCapabilitiesFixture,
      requests: requests,
      get: (uri) async =>
          uri.path == '/api/providers' ? _providersFixtureBody() : null,
    );

    await channel.loadProviders();

    final providersRequest = requests.firstWhere(
      (uri) => uri.path == '/api/providers',
    );
    expect(providersRequest.queryParameters['profile'], 'default');
    expect(channel.state.providers.map((p) => p.slug), ['openai', 'anthropic']);
    expect(channel.state.providers.first.configured, isTrue);
    expect(channel.state.providers.first.keyHint, '····1234');
    // Invariant: no state field carries the raw secret.
    expect(channel.state.providers.first.keyHint!.contains(sentinel), isFalse);
  });

  test(
    'profile selection clears provider and model state owned by its predecessor',
    () async {
      final channel = await _connectedProviderModelChannel(
        capabilities: _providerModelCapabilitiesFixture,
        get: (uri) async => switch (uri.path) {
          '/api/providers' => _providersFixtureBody(),
          '/api/models' => _modelsInventoryBody,
          _ => null,
        },
      );
      await channel.loadProviders();
      await channel.loadModels();
      expect(channel.state.providers, isNotEmpty);
      expect(channel.state.modelInventory, isNotNull);

      await channel.selectProfile('coder');

      expect(channel.state.providers, isEmpty);
      expect(channel.state.modelInventory, isNull);
    },
  );

  test(
    'late provider and model loads cannot repopulate a prior profile',
    () async {
      final providersStarted = Completer<void>();
      final modelsStarted = Completer<void>();
      final releaseProviders = Completer<void>();
      final releaseModels = Completer<void>();
      final channel = await _connectedProviderModelChannel(
        capabilities: _providerModelCapabilitiesFixture,
        get: (uri) async {
          if (uri.path == '/api/providers') {
            providersStarted.complete();
            await releaseProviders.future;
            return _providersFixtureBody();
          }
          if (uri.path == '/api/models') {
            modelsStarted.complete();
            await releaseModels.future;
            return _modelsInventoryBody;
          }
          return null;
        },
      );

      final providers = channel.loadProviders();
      final models = channel.loadModels();
      await Future.wait([providersStarted.future, modelsStarted.future]);
      await channel.selectProfile('coder');
      releaseProviders.complete();
      releaseModels.complete();
      await Future.wait([providers, models]);

      expect(channel.state.selectedProfileId, 'coder');
      expect(channel.state.providers, isEmpty);
      expect(channel.state.modelInventory, isNull);
    },
  );

  test('setProviderCredential sends the value in the body but never stores '
      'it in state', () async {
    const sentinel = 'sk-live-DEADBEEF-super-secret';
    final requests = <Uri>[];
    String? putBodyRaw;
    final channel = await _connectedProviderModelChannel(
      capabilities: _providerModelCapabilitiesFixture,
      requests: requests,
      get: (uri) async =>
          uri.path == '/api/providers' ? _providersFixtureBody() : null,
      put: (uri, body) async {
        putBodyRaw = body;
        return jsonEncode({
          'data': {
            'slug': 'openai',
            'label': 'OpenAI',
            'auth_type': 'api_key',
            'env_vars': ['OPENAI_API_KEY'],
            'configured': true,
            'key_hint': '····cret',
          },
        });
      },
    );
    await channel.loadProviders();

    await channel.setProviderCredential(
      slug: 'openai',
      envVar: 'OPENAI_API_KEY',
      value: sentinel,
    );

    // The credential set request carries the profile and the value...
    final putRequest = requests.firstWhere(
      (uri) => uri.path == '/api/providers/openai/credential',
    );
    expect(putRequest.queryParameters['profile'], 'default');
    expect(putBodyRaw!.contains(sentinel), isTrue);
    // ...but the presence-updated state never contains the sent value.
    final openai = channel.state.providers.firstWhere(
      (p) => p.slug == 'openai',
    );
    expect(openai.configured, isTrue);
    expect(openai.keyHint, '····cret');
    expect(_stateContainsSentinel(channel.state, sentinel), isFalse);
  });

  test(
    'loadModels stores the parsed inventory scoped to the profile',
    () async {
      final requests = <Uri>[];
      final channel = await _connectedProviderModelChannel(
        capabilities: _providerModelCapabilitiesFixture,
        requests: requests,
        get: (uri) async =>
            uri.path == '/api/models' ? _modelsInventoryBody : null,
      );

      await channel.loadModels();

      final modelsRequest = requests.firstWhere(
        (uri) => uri.path == '/api/models',
      );
      expect(modelsRequest.queryParameters['profile'], 'default');
      final inventory = channel.state.modelInventory!;
      expect(inventory.assignment.activeModel, 'gpt-5');
      expect(inventory.catalog.providers.single.provider, 'openai');
      expect(inventory.assignment.auxiliary.single.task, 'title');
    },
  );

  test(
    'refreshModels hits the refresh endpoint and replaces the catalog only',
    () async {
      final requests = <Uri>[];
      final channel = await _connectedProviderModelChannel(
        capabilities: _providerModelCapabilitiesFixture,
        requests: requests,
        get: (uri) async =>
            uri.path == '/api/models' ? _modelsInventoryBody : null,
        post: (uri, body) async => jsonEncode({
          'catalog': {
            'providers': {
              'anthropic': {
                'models': [
                  {'id': 'claude-4'},
                ],
              },
            },
          },
        }),
      );
      await channel.loadModels();

      await channel.refreshModels();

      final refreshRequest = requests.firstWhere(
        (uri) => uri.path == '/api/models/refresh',
      );
      expect(refreshRequest.queryParameters['profile'], 'default');
      final inventory = channel.state.modelInventory!;
      // Catalog was refreshed...
      expect(inventory.catalog.providers.single.provider, 'anthropic');
      // ...while the existing assignment is preserved.
      expect(inventory.assignment.activeModel, 'gpt-5');
    },
  );

  test('assignModel sends If-Match and updates the active assignment', () async {
    final requests = <Uri>[];
    String? ifMatch;
    Map<String, Object?>? putBody;
    final channel = await _connectedProviderModelChannel(
      capabilities: _providerModelCapabilitiesFixture,
      requests: requests,
      get: (uri) async =>
          uri.path == '/api/models' ? _modelsInventoryBody : null,
      put: (uri, body) async {
        putBody = jsonDecode(body) as Map<String, Object?>;
        return jsonEncode({
          'active': {'provider': 'anthropic', 'model': 'claude-4'},
          'auxiliary': <Object?>[],
          'revision': 'mrev-2',
        });
      },
    );
    await channel.loadModels();

    // Capture the If-Match by intercepting the PUT headers via a second client.
    final headerRequests = <String, String?>{};
    final headerChannel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _providerModelCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            '/api/profiles' => _profilesFixture,
            '/api/models' => _modelsInventoryBody,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        put: (uri, headers, body) async {
          headerRequests['If-Match'] = headers['If-Match'];
          return jsonEncode({
            'active': {'provider': 'anthropic', 'model': 'claude-4'},
            'auxiliary': <Object?>[],
            'revision': 'mrev-2',
          });
        },
      ),
    );
    addTearDown(headerChannel.dispose);
    await headerChannel.connect(baseUrl: 'http://127.0.0.1:8642');
    await headerChannel.selectProfile('default');
    await headerChannel.loadModels();
    await headerChannel.assignModel(
      scope: 'main',
      provider: 'anthropic',
      model: 'claude-4',
      revision: 'mrev-1',
    );
    ifMatch = headerRequests['If-Match'];

    await channel.assignModel(
      scope: 'main',
      provider: 'anthropic',
      model: 'claude-4',
      revision: 'mrev-1',
    );

    final assignRequest = requests.firstWhere(
      (uri) => uri.path == '/api/models/assignment',
    );
    expect(assignRequest.queryParameters['profile'], 'default');
    expect(ifMatch, 'mrev-1');
    expect(putBody, {
      'scope': 'main',
      'provider': 'anthropic',
      'model': 'claude-4',
    });
    final inventory = channel.state.modelInventory!;
    expect(inventory.assignment.activeProvider, 'anthropic');
    expect(inventory.assignment.activeModel, 'claude-4');
    expect(inventory.assignment.revision, 'mrev-2');
  });

  test('assignModel refreshes the model inventory and rethrows on a 412 '
      'stale revision', () async {
    final requests = <Uri>[];
    var modelsGets = 0;
    final channel = await _connectedProviderModelChannel(
      capabilities: _providerModelCapabilitiesFixture,
      requests: requests,
      get: (uri) async {
        if (uri.path == '/api/models') {
          modelsGets += 1;
          // First load reports mrev-1; the post-412 refresh reports the
          // winning revision the caller must retry against.
          return modelsGets == 1
              ? _modelsInventoryBody
              : jsonEncode({
                  'catalog': {
                    'providers': {
                      'openai': {
                        'models': [
                          {'id': 'gpt-5'},
                        ],
                      },
                    },
                  },
                  'active': {'provider': 'openai', 'model': 'gpt-5'},
                  'auxiliary': <Object?>[],
                  'revision': 'mrev-9',
                });
        }
        return null;
      },
      put: (uri, body) async =>
          throw StateError('Hermes API returned HTTP 412'),
    );
    await channel.loadModels();
    expect(channel.state.modelInventory!.assignment.revision, 'mrev-1');
    requests.clear();
    final getsBefore = modelsGets;

    await expectLater(
      channel.assignModel(
        scope: 'main',
        provider: 'openai',
        model: 'gpt-5',
        revision: 'mrev-1',
      ),
      throwsStateError,
    );

    // The stale assignment refreshed the inventory before rethrowing: the
    // model-list GET fired again and the state now holds the winning revision.
    expect(modelsGets, getsBefore + 1);
    expect(requests.any((uri) => uri.path == '/api/models'), isTrue);
    expect(channel.state.modelInventory!.assignment.revision, 'mrev-9');
  });

  test('read-only scopes gate write operations and visibility hooks before '
      'any network call', () async {
    var wrote = false;
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _providerModelReadOnlyCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            '/api/profiles' => _profilesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        put: (uri, headers, body) async {
          wrote = true;
          return '{}';
        },
        post: (uri, headers, body) async {
          wrote = true;
          return '{}';
        },
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    await channel.selectProfile('default');

    // Read visibility hooks are granted; write hooks are not.
    expect(channel.state.canReadProviders, isTrue);
    expect(channel.state.canWriteProviders, isFalse);
    expect(channel.state.canReadModels, isTrue);
    expect(channel.state.canWriteModels, isFalse);

    await expectLater(
      channel.setProviderCredential(
        slug: 'openai',
        envVar: 'OPENAI_API_KEY',
        value: 'x',
      ),
      throwsStateError,
    );
    await expectLater(channel.refreshModels(), throwsStateError);
    await expectLater(
      channel.assignModel(
        scope: 'main',
        provider: 'openai',
        model: 'gpt-5',
        revision: 'mrev-1',
      ),
      throwsStateError,
    );

    expect(wrote, isFalse);
  });

  test('connect selects the advertised default profile context', () async {
    final requests = <Uri>[];
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          requests.add(uri);
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _profileCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
      ),
    );
    addTearDown(channel.dispose);

    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    expect(channel.state.selectedProfileId, 'default');
    expect(
      requests
          .where(
            (uri) =>
                uri.path == '/api/sessions' ||
                uri.path == '/api/sessions/sess_1/messages',
          )
          .every((uri) => uri.queryParameters['profile'] == 'default'),
      isTrue,
    );
  });

  test('the fake channel exposes the provider/model seam with call '
      'recording', () async {
    const sentinel = 'sk-fake-secret-value-xyz';
    final fake = FakeHermesChannel(
      providers: const [
        HermesProvider(
          slug: 'openai',
          label: 'OpenAI',
          authType: 'api_key',
          envVars: ['OPENAI_API_KEY'],
        ),
      ],
      selectedProfileId: 'default',
    );
    addTearDown(fake.dispose);

    await fake.loadProviders();
    await fake.setProviderCredential(
      slug: 'openai',
      envVar: 'OPENAI_API_KEY',
      value: sentinel,
    );
    final probe = await fake.validateProviderCredential(slug: 'openai');
    await fake.loadModels();
    await fake.refreshModels();
    await fake.assignModel(
      scope: 'main',
      provider: 'openai',
      model: 'gpt-5',
      revision: 'mrev-1',
    );

    expect(fake.loadProvidersCalls, 1);
    expect(fake.setProviderCredentialCalls.single['slug'], 'openai');
    expect(fake.setProviderCredentialCalls.single['value'], sentinel);
    expect(probe.ok, isTrue);
    expect(fake.assignModelCalls.single['revision'], 'mrev-1');
    // The fake records presence, not the raw key, in observable state.
    final openai = fake.state.providers.firstWhere((p) => p.slug == 'openai');
    expect(openai.configured, isTrue);
    expect(_stateContainsSentinel(fake.state, sentinel), isFalse);
  });
}

/// Serializes the public, non-secret surface of provider/model state and
/// asserts the sent credential value never appears there.
bool _stateContainsSentinel(HermesChannelState state, String sentinel) {
  final encoded = jsonEncode({
    'providers': [
      for (final p in state.providers)
        {
          'slug': p.slug,
          'label': p.label,
          'authType': p.authType,
          'envVars': p.envVars,
          'configured': p.configured,
          'keyHint': p.keyHint,
        },
    ],
    'models': {
      'activeProvider': state.modelInventory?.assignment.activeProvider,
      'activeModel': state.modelInventory?.assignment.activeModel,
      'revision': state.modelInventory?.assignment.revision,
    },
  });
  return encoded.contains(sentinel);
}
