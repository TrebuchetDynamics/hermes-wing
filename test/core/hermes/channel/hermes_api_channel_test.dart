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
}

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
