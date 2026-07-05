import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/hermes/hermes_api.dart';

void main() {
  test(
    'constructs Hermes API URLs without stale credentials or query state',
    () {
      final config = HermesApiConfig.fromBaseUrl(
        'https://user:old-key@hermes.example:8642/setup?api_key=old#frag',
        apiKey: ' hermes_live_key ',
      );

      expect(config.healthUri.toString(), 'https://hermes.example:8642/health');
      expect(
        config.capabilitiesUri.toString(),
        'https://hermes.example:8642/v1/capabilities',
      );
      expect(
        config.modelsUri.toString(),
        'https://hermes.example:8642/v1/models',
      );
      expect(
        config.skillsUri.toString(),
        'https://hermes.example:8642/v1/skills',
      );
      expect(
        config.toolsetsUri.toString(),
        'https://hermes.example:8642/v1/toolsets',
      );
      expect(
        config.sessionsUri.toString(),
        'https://hermes.example:8642/api/sessions',
      );
      expect(config.jobsUri.toString(), 'https://hermes.example:8642/api/jobs');
      expect(
        config.sessionUri(' s/1 ').toString(),
        'https://hermes.example:8642/api/sessions/s%2F1',
      );
      expect(
        config.sessionMessagesUri('s 1').toString(),
        'https://hermes.example:8642/api/sessions/s%201/messages',
      );
      expect(
        config.sessionForkUri('s 1').toString(),
        'https://hermes.example:8642/api/sessions/s%201/fork',
      );
      expect(
        config.sessionChatStreamUri('s 1').toString(),
        'https://hermes.example:8642/api/sessions/s%201/chat/stream',
      );
      expect(
        config.runEventsUri('run/1').toString(),
        'https://hermes.example:8642/v1/runs/run%2F1/events',
      );
      expect(
        config.runApprovalUri('run 1').toString(),
        'https://hermes.example:8642/v1/runs/run%201/approval',
      );
      expect(
        config.runStopUri('run 1').toString(),
        'https://hermes.example:8642/v1/runs/run%201/stop',
      );
      expect(config.headers, {'Authorization': 'Bearer hermes_live_key'});
    },
  );

  test('rejects invalid Hermes API base URLs before requests', () {
    expect(() => HermesApiConfig.fromBaseUrl('   '), throwsArgumentError);
    expect(
      () => HermesApiConfig.fromBaseUrl('127.0.0.1:8642'),
      throwsArgumentError,
    );
    expect(
      () => HermesApiConfig.fromBaseUrl('ws://127.0.0.1:8642'),
      throwsArgumentError,
    );
  });

  test('rejects blank Hermes path identifiers before ambiguous calls', () {
    final config = HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642');

    expect(() => config.sessionUri('  '), throwsArgumentError);
    expect(() => config.runEventsUri('\t'), throwsArgumentError);
  });

  test(
    'parses capability document and gates chat and run transports',
    () async {
      final capabilities = HermesCapabilityDocument.fromJson(
        jsonDecode(_capabilitiesFixture) as Map<String, Object?>,
      );
      final policy = HermesTransportPolicy(capabilities);

      expect(capabilities.auth.required, isTrue);
      expect(capabilities.supportsFeature('session_chat_streaming'), isTrue);
      expect(policy.supportsSessionChatStream, isTrue);
      expect(policy.supportsRunsTransport, isTrue);
      expect(policy.supportsRunStop, isTrue);
      expect(policy.supportsRunApprovalResponse, isTrue);
      expect(policy.supportsToolProgressEvents, isTrue);
      expect(policy.supportsAnyChatTransport, isTrue);
      final minimalRunPolicy = HermesTransportPolicy(
        HermesCapabilityDocument.fromJson(
          jsonDecode(_minimalRunCapabilitiesFixture) as Map<String, Object?>,
        ),
      );
      expect(minimalRunPolicy.supportsRunsTransport, isTrue);
      expect(minimalRunPolicy.supportsRunStop, isFalse);
      expect(minimalRunPolicy.supportsRunApprovalResponse, isFalse);
      expect(minimalRunPolicy.supportsToolProgressEvents, isFalse);
      expect(minimalRunPolicy.supportsAnyChatTransport, isTrue);
      expect(policy.supportsConfigWrite, isFalse);
      expect(policy.supportsRealtimeVoice, isFalse);

      final noChatPolicy = HermesTransportPolicy(
        HermesCapabilityDocument.fromJson(
          jsonDecode(_futureSurfaceCapabilitiesFixture) as Map<String, Object?>,
        ),
      );
      expect(noChatPolicy.supportsAnyChatTransport, isFalse);
    },
  );

  test(
    'surface readiness does not claim unwired Hermes APIs are implemented',
    () {
      final capabilities = HermesCapabilityDocument.fromJson(
        jsonDecode(_futureSurfaceCapabilitiesFixture) as Map<String, Object?>,
      );
      final readiness = hermesSurfaceReadiness(capabilities);

      final statuses = {for (final item in readiness) item.title: item.status};
      final details = {for (final item in readiness) item.title: item.detail};

      expect(
        statuses.keys,
        unorderedEquals([
          'Chat transport',
          'Sessions',
          'Local voice-to-text',
          'Server realtime voice/audio',
          'Config editing/admin',
          'Memory UI',
          'Jobs/schedules inventory',
          'Jobs/schedules admin',
          'Messaging gateways',
          'Persona/SOUL',
          'Attachments/media',
          'Files/context folders',
          'Bounded diagnostics',
          'Raw diagnostics/log export',
          'Multi-endpoint/profile management',
        ]),
      );
      expect(statuses['Chat transport'], HermesSurfaceStatus.blocked);
      expect(statuses['Sessions'], HermesSurfaceStatus.blocked);
      expect(statuses['Local voice-to-text'], HermesSurfaceStatus.available);
      expect(
        statuses['Server realtime voice/audio'],
        HermesSurfaceStatus.blocked,
      );
      expect(
        details['Server realtime voice/audio'],
        contains('device STT -> Hermes text'),
      );
      expect(statuses['Config editing/admin'], HermesSurfaceStatus.deferred);
      expect(statuses['Memory UI'], HermesSurfaceStatus.deferred);
      expect(
        statuses['Jobs/schedules inventory'],
        HermesSurfaceStatus.readOnly,
      );
      expect(statuses['Jobs/schedules admin'], HermesSurfaceStatus.deferred);
      expect(
        details['Jobs/schedules admin'],
        contains('create/edit/delete scheduling'),
      );
      expect(
        details['Jobs/schedules admin'],
        contains('no mobile mutation controls are shown'),
      );
      expect(statuses['Messaging gateways'], HermesSurfaceStatus.deferred);
      expect(
        details['Messaging gateways'],
        contains('no gateway mutation controls are shown'),
      );
      expect(statuses['Persona/SOUL'], HermesSurfaceStatus.deferred);
      expect(
        details['Persona/SOUL'],
        contains('Persona/SOUL editing is not wired'),
      );
      expect(statuses['Attachments/media'], HermesSurfaceStatus.deferred);
      expect(
        details['Attachments/media'],
        contains('no upload controls are shown'),
      );
      expect(statuses['Files/context folders'], HermesSurfaceStatus.deferred);
      expect(
        details['Files/context folders'],
        contains('remote path semantics before controls appear'),
      );
      expect(statuses['Bounded diagnostics'], HermesSurfaceStatus.readOnly);
      expect(
        statuses['Raw diagnostics/log export'],
        HermesSurfaceStatus.deferred,
      );
      expect(
        details['Raw diagnostics/log export'],
        contains('safe redaction contract'),
      );
      expect(
        statuses['Multi-endpoint/profile management'],
        HermesSurfaceStatus.available,
      );
      expect(
        details['Multi-endpoint/profile management'],
        contains('secure storage'),
      );
      expect(statuses.containsKey('Legacy durable reconnect'), isFalse);
    },
  );

  test('audio API advertisement is blocked until server audio is wired', () {
    final readiness = hermesSurfaceReadiness(
      const HermesCapabilityDocument(
        object: 'hermes.api_server.capabilities',
        platform: 'hermes-agent',
        model: 'hermes-agent',
        auth: HermesAuthCapability(type: 'bearer', required: true),
        features: {'audio_api': true},
        endpoints: {},
      ),
    );
    final item = readiness.firstWhere(
      (item) => item.title == 'Server realtime voice/audio',
    );

    expect(item.status, HermesSurfaceStatus.blocked);
    expect(item.detail, contains('server audio/realtime voice is advertised'));
    expect(item.detail, contains('device STT -> Hermes text'));
  });

  test(
    'client parses health, catalog, sessions, created sessions, and messages',
    () async {
      final requests = <String>[];
      final posts = <String, Map<String, Object?>>{};
      final client = HermesApiClient(
        config: HermesApiConfig.fromBaseUrl(
          'http://127.0.0.1:8642',
          apiKey: 'api-key',
        ),
        get: (uri, headers) async {
          expect(headers, {'Authorization': 'Bearer api-key'});
          requests.add(uri.path);
          return switch (uri.path) {
            '/health' => '{"status":"ok","platform":"hermes-agent"}',
            '/health/detailed' =>
              '{"status":"ok","platform":"hermes-agent","version":"0.16.0","gateway_state":"running","active_agents":0}',
            '/v1/capabilities' => _capabilitiesFixture,
            '/v1/models' => _modelsFixture,
            '/v1/skills' => _skillsFixture,
            '/v1/toolsets' => _toolsetsFixture,
            '/api/jobs' => _jobsFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          expect(headers['Authorization'], 'Bearer api-key');
          expect(headers['Content-Type'], 'application/json');
          posts[uri.path] = jsonDecode(body) as Map<String, Object?>;
          return '{"object":"hermes.session","session":{"id":"navi-1","source":"api_server","title":"Mobile"}}';
        },
      );

      expect((await client.health()).status, 'ok');
      final detailed = await client.healthDetailed();
      expect(detailed.version, '0.16.0');
      expect(detailed.gatewayState, 'running');
      expect(detailed.activeAgents, 0);
      expect((await client.capabilities()).model, 'hermes-agent');
      expect(await client.listModels(), ['hermes-agent']);
      expect(await client.listSkills(), ['ascii-art', 'github']);
      expect(await client.listEnabledToolsets(), ['default']);
      final jobs = await client.listJobs();
      expect(jobs.single.displayName, 'Morning check');
      expect(jobs.single.scheduleDisplay, 'Every day at 09:00');
      expect((await client.listSessions()).single.id, 'sess_1');
      expect((await client.sessionMessages('sess_1')).single.content, 'Hello');

      final created = await client.createSession(id: 'navi-1', title: 'Mobile');
      expect(created.id, 'navi-1');
      expect(posts['/api/sessions'], {'id': 'navi-1', 'title': 'Mobile'});
      expect(requests, [
        '/health',
        '/health/detailed',
        '/v1/capabilities',
        '/v1/models',
        '/v1/skills',
        '/v1/toolsets',
        '/api/jobs',
        '/api/sessions',
        '/api/sessions/sess_1/messages',
      ]);
    },
  );

  test('updates a session title over PATCH', () async {
    final patches = <String, Map<String, Object?>>{};
    final client = HermesApiClient(
      config: HermesApiConfig.fromBaseUrl(
        'http://127.0.0.1:8642',
        apiKey: 'api-key',
      ),
      patch: (uri, headers, body) async {
        expect(headers['Authorization'], 'Bearer api-key');
        expect(headers['Content-Type'], 'application/json');
        patches[uri.path] = jsonDecode(body) as Map<String, Object?>;
        return '{"object":"hermes.session","session":{"id":"sess_1","source":"api_server","title":"Renamed"}}';
      },
    );

    final updated = await client.updateSessionTitle(
      'sess_1',
      title: ' Renamed ',
    );

    expect(patches['/api/sessions/sess_1'], {'title': 'Renamed'});
    expect(updated.title, 'Renamed');
  });

  test('deletes a session over DELETE and verifies the envelope', () async {
    final deletes = <String>[];
    final client = HermesApiClient(
      config: HermesApiConfig.fromBaseUrl(
        'http://127.0.0.1:8642',
        apiKey: 'api-key',
      ),
      delete: (uri, headers) async {
        expect(headers['Authorization'], 'Bearer api-key');
        deletes.add(uri.path);
        return '{"object":"hermes.session.deleted","id":"sess_1","deleted":true}';
      },
    );

    await client.deleteSession('sess_1');

    expect(deletes, ['/api/sessions/sess_1']);
  });

  test('rejects an unconfirmed delete response', () async {
    final client = HermesApiClient(
      config: HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642'),
      delete: (uri, headers) async =>
          '{"object":"hermes.session.deleted","id":"other","deleted":false}',
    );

    await expectLater(client.deleteSession('sess_1'), throwsStateError);
  });

  test('forks a session over POST', () async {
    final posts = <String, Map<String, Object?>>{};
    final client = HermesApiClient(
      config: HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642'),
      post: (uri, headers, body) async {
        posts[uri.path] = jsonDecode(body) as Map<String, Object?>;
        return '{"object":"hermes.session","session":{"id":"fork_1","source":"api_server","title":"Fork","parent_session_id":"sess_1"}}';
      },
    );

    final fork = await client.forkSession(
      'sess_1',
      id: 'fork_1',
      title: 'Fork',
    );

    expect(posts['/api/sessions/sess_1/fork'], {
      'id': 'fork_1',
      'title': 'Fork',
    });
    expect(fork.id, 'fork_1');
    expect(fork.parentSessionId, 'sess_1');
  });

  test(
    'streams session chat turns as decoded Hermes events over POST body chunks',
    () async {
      final posts = <String, Map<String, Object?>>{};
      final client = HermesApiClient(
        config: HermesApiConfig.fromBaseUrl(
          'http://127.0.0.1:8642',
          apiKey: 'api-key',
        ),
        postStream: (uri, headers, body) {
          expect(uri.path, '/api/sessions/sess_1/chat/stream');
          expect(headers['Authorization'], 'Bearer api-key');
          expect(headers['Content-Type'], 'application/json');
          expect(headers['Accept'], 'text/event-stream');
          expect(headers['Cache-Control'], 'no-cache');
          posts[uri.path] = jsonDecode(body) as Map<String, Object?>;
          return Stream.fromIterable([
            'event: run.started\ndata: {"run_id":"run_1"}\n\n',
            'event: assistant.delta\ndata: {"delta":"Hi"}\n\ndata: [DONE]\n\n',
          ]);
        },
      );

      final events = await client
          .streamSessionChat('sess_1', message: 'hello')
          .toList();

      expect(posts['/api/sessions/sess_1/chat/stream'], {'message': 'hello'});
      expect(events.map((event) => event.name), [
        'run.started',
        'assistant.delta',
        'done',
      ]);
      expect(events[1].delta, 'Hi');
    },
  );

  test(
    'run transport: starts a run, streams run events over GET SSE, responds to approval, and stops',
    () async {
      final posts = <String, Map<String, Object?>>{};
      final getStreamRequests = <String>[];
      final client = HermesApiClient(
        config: HermesApiConfig.fromBaseUrl(
          'http://127.0.0.1:8642',
          apiKey: 'api-key',
        ),
        post: (uri, headers, body) async {
          posts[uri.path] = jsonDecode(body) as Map<String, Object?>;
          return switch (uri.path) {
            '/v1/runs' =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
            _ => '{}',
          };
        },
        getStream: (uri, headers) {
          getStreamRequests.add(uri.path);
          expect(headers['Authorization'], 'Bearer api-key');
          expect(headers['Accept'], 'text/event-stream');
          expect(headers['Cache-Control'], 'no-cache');
          return Stream.fromIterable([
            'event: message.delta\ndata: {"delta":"Hi"}\n\n',
            'event: approval.request\ndata: {"approval_id":"appr_1"}\n\ndata: [DONE]\n\n',
          ]);
        },
      );

      final run = await client.startRun(sessionId: 'sess_1', message: 'hello');
      expect(run.id, 'run_1');
      expect(posts['/v1/runs'], {'session_id': 'sess_1', 'message': 'hello'});

      final events = await client.runEvents(run.id).toList();
      expect(getStreamRequests, ['/v1/runs/run_1/events']);
      expect(events.map((event) => event.name), [
        'message.delta',
        'approval.request',
        'done',
      ]);

      await client.respondApproval(
        runId: run.id,
        approvalId: 'appr_1',
        decision: 'once',
      );
      expect(posts['/v1/runs/run_1/approval'], {
        'approval_id': 'appr_1',
        'decision': 'once',
      });

      await client.stopRun(run.id);
      expect(posts['/v1/runs/run_1/stop'], <String, Object?>{});
    },
  );

  test('decodes server-sent events across chunks and keeps multiline data', () {
    final decoder = HermesSseEventDecoder();

    final events = decoder.decode([
      ': keepalive\n',
      'id: 7\nevent: assistant.delta\ndata: first\n',
      'data: second\n\n',
      'event: done\ndata: {}\n\n',
    ]);

    expect(events, hasLength(2));
    expect(events.first.id, '7');
    expect(events.first.event, 'assistant.delta');
    expect(events.first.data, 'first\nsecond');
    expect(events.last.isDone, isTrue);
  });

  test('decodes CR-only server-sent event frames', () {
    final decoder = HermesSseEventDecoder();

    final events = decoder.decode([
      'event: assistant.delta\rdata: first\r',
      'data: second\r\r',
      'event: done\rdata: {}\r\r',
    ]);

    expect(events, hasLength(2));
    expect(events.first.event, 'assistant.delta');
    expect(events.first.data, 'first\nsecond');
    expect(events.last.isDone, isTrue);
  });

  test(
    'keeps incomplete final SSE frame buffered until a separator arrives',
    () {
      final decoder = HermesSseEventDecoder();

      expect(
        decoder.decode(['event: assistant.delta\ndata: {"delta":"partial"}']),
        isEmpty,
      );
    },
  );

  test('ignores empty chunks and no-data CR-only control frames', () {
    final decoder = HermesSseEventDecoder();

    expect(decoder.decode(['', '\r', 'id: 9\revent: ping\r\r']), isEmpty);
  });

  test('decodes no-data done events as terminal stream events', () {
    final decoder = HermesSseEventDecoder();

    final events = decoder.decodeJsonEvents(['event: done\n\n']);

    expect(events, hasLength(1));
    expect(events.single.isDone, isTrue);
  });

  test(
    'live SSE decoder flushes final data frame when the stream closes',
    () async {
      final decoder = HermesSseEventDecoder();

      final events = await decoder
          .decodeJsonEventStream(
            Stream.fromIterable([
              'event: assistant.delta\n',
              'data: {"delta":"final chunk"}',
            ]),
          )
          .toList();

      expect(events, hasLength(1));
      expect(events.single.name, 'assistant.delta');
      expect(events.single.delta, 'final chunk');
    },
  );

  test('decodes Hermes JSON SSE payloads and skips malformed events', () {
    final decoder = HermesSseEventDecoder();

    final events = decoder.decodeJsonEvents([
      'event: run.started\ndata: {"run_id":"run_1","session_id":"sess_1"}\n\n',
      'event: assistant.delta\ndata: {not json}\n\n',
      'event: assistant.delta\ndata: {"message_id":"msg_1","delta":"Hi"}\n\n',
      'data: [DONE]\n\n',
    ]);

    expect(events.map((event) => event.name), [
      'run.started',
      'assistant.delta',
      'done',
    ]);
    expect(events.first.runId, 'run_1');
    expect(events[1].delta, 'Hi');
    expect(events.last.isDone, isTrue);
  });

  test('uses embedded event names from default SSE message frames', () {
    final decoder = HermesSseEventDecoder();

    final events = decoder.decodeJsonEvents([
      'data: {"event":"message.delta","delta":"Hi"}\n\n',
      'data: {"type":"run.completed"}\n\n',
      'data: {"name":"assistant.completed"}\n\n',
    ]);

    expect(events.map((event) => event.name), [
      'message.delta',
      'run.completed',
      'assistant.completed',
    ]);
    expect(events.first.delta, 'Hi');
  });

  test('preserves non-JSON SSE error frames as stream error events', () {
    final decoder = HermesSseEventDecoder();

    final events = decoder.decodeJsonEvents([
      'event: error\ndata: upstream closed token=secret-error\n\n',
      'event: assistant.delta\ndata: {not json}\n\n',
    ]);

    expect(events, hasLength(1));
    expect(events.single.name, 'error');
    expect(
      events.single.payload['message'],
      'upstream closed token=secret-error',
    );
  });
}

const _capabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true},
  "features": {
    "session_chat_streaming": true,
    "session_resources": true,
    "run_submission": true,
    "run_status": true,
    "run_events_sse": true,
    "run_stop": true,
    "run_approval_response": true,
    "tool_progress_events": true,
    "admin_config_rw": false,
    "memory_write_api": false,
    "audio_api": false,
    "realtime_voice": false
  },
  "endpoints": {
    "sessions": {"method": "GET", "path": "/api/sessions"},
    "session_create": {"method": "POST", "path": "/api/sessions"},
    "session_messages": {"method": "GET", "path": "/api/sessions/{session_id}/messages"},
    "session_chat_stream": {"method": "POST", "path": "/api/sessions/{session_id}/chat/stream"},
    "runs": {"method": "POST", "path": "/v1/runs"},
    "run_status": {"method": "GET", "path": "/v1/runs/{run_id}"},
    "run_events": {"method": "GET", "path": "/v1/runs/{run_id}/events"},
    "run_approval": {"method": "POST", "path": "/v1/runs/{run_id}/approval"},
    "run_stop": {"method": "POST", "path": "/v1/runs/{run_id}/stop"}
  }
}
''';

const _minimalRunCapabilitiesFixture = '''
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

const _futureSurfaceCapabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true},
  "features": {
    "realtime_voice": true,
    "admin_config_rw": true,
    "memory_write_api": true,
    "jobs_admin": true,
    "attachments_api": true
  },
  "endpoints": {
    "jobs": {"method": "GET", "path": "/api/jobs"}
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
    {
      "id": "job_1",
      "name": "Morning check",
      "enabled": true,
      "state": "scheduled",
      "schedule": {"display": "Every day at 09:00"},
      "next_run_at": "2026-07-03T09:00:00Z"
    }
  ]
}
''';

const _sessionsFixture = '''
{
  "object": "list",
  "data": [
    {
      "id": "sess_1",
      "source": "api_server",
      "model": "hermes-agent",
      "title": "Demo",
      "message_count": 2,
      "last_active": "2026-06-25T12:00:00Z",
      "preview": "Hello"
    }
  ],
  "limit": 50,
  "offset": 0,
  "has_more": false
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
