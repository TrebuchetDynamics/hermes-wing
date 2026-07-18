import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/hermes_api.dart';

void main() {
  test('summarizes multimodal history without exposing image data', () {
    final message = HermesMessage.fromJson({
      'id': 'message-1',
      'session_id': 'session-1',
      'role': 'user',
      'content': [
        {'type': 'text', 'text': 'What is this?'},
        {
          'type': 'image_url',
          'image_url': {'url': 'data:image/png;base64,secret'},
        },
      ],
    });

    expect(message.content, 'What is this?\n\n[Image]');
    expect(message.content, isNot(contains('secret')));
  });

  test('summarizes text-file history without exposing its contents', () {
    final message = HermesMessage.fromJson({
      'id': 'message-1',
      'session_id': 'session-1',
      'role': 'user',
      'content':
          'Review this\n\n<file name="notes&lt;&amp;.txt" mime="text/plain">\nsecret contents\n</file>',
    });

    expect(message.content, 'Review this\n\n[File: notes<&.txt]');
    expect(message.content, isNot(contains('secret contents')));
  });

  test('client bounds requests that never complete', () async {
    final never = Completer<String>();
    final client = HermesApiClient(
      config: HermesApiConfig.fromBaseUrl('https://hermes.example'),
      requestTimeout: const Duration(milliseconds: 10),
      get: (uri, headers) => never.future,
    );

    await expectLater(client.health(), throwsA(isA<TimeoutException>()));
  });

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

  test(
    'warns before sending bearer credentials over remote cleartext HTTP',
    () {
      expect(
        hermesEndpointRequiresCleartextCredentialWarning(
          'http://192.168.1.20:8642',
          apiKey: 'secret',
        ),
        isTrue,
      );
      expect(
        hermesEndpointRequiresCleartextCredentialWarning(
          'http://127.0.0.1:8642',
          apiKey: 'secret',
        ),
        isFalse,
      );
      expect(
        hermesEndpointRequiresCleartextCredentialWarning(
          'https://hermes.example',
          apiKey: 'secret',
        ),
        isFalse,
      );
    },
  );

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

  test('capabilities parse caller scopes and endpoint requirements', () {
    final document = HermesCapabilityDocument.fromJson({
      'schema_version': 1,
      'profile_context': {
        'type': 'query',
        'name': 'profile',
        'required': true,
        'default_profile_id': 'default',
      },
      'auth': {
        'type': 'bearer',
        'required': true,
        'granted_scopes': ['profiles:read'],
        'credential_kind': 'operator_token',
      },
      'endpoints': {
        'profiles': {
          'method': 'GET',
          'path': '/api/profiles',
          'required_scopes': ['profiles:read'],
          'profile_scoped': false,
        },
      },
    });

    expect(document.schemaVersion, 1);
    expect(document.supportsSchema, isTrue);
    expect(document.profileContext.name, 'profile');
    expect(document.profileContext.required, isTrue);
    expect(document.profileContext.defaultProfileId, 'default');
    expect(document.auth.allows('profiles:read'), isTrue);
    expect(document.auth.allows('profiles:write'), isFalse);
    expect(document.endpoints['profiles']!.requiredScopes, ['profiles:read']);
    expect(document.endpoints['profiles']!.profileScoped, isFalse);
    expect(
      document.advertisesScopedEndpoint(
        'profiles',
        'GET',
        '/api/profiles',
        'profiles:read',
      ),
      isTrue,
    );
    expect(
      document.advertisesScopedEndpoint(
        'profiles',
        'GET',
        '/api/profiles',
        'profiles:write',
      ),
      isFalse,
    );
  });

  test('chat transports require every declared endpoint scope', () {
    final readOnly = HermesCapabilityDocument.fromJson({
      'schema_version': 1,
      'auth': {
        'type': 'bearer',
        'required': true,
        'granted_scopes': ['chat:read'],
      },
      'features': {
        'run_submission': true,
        'run_events_sse': true,
        'session_chat_streaming': true,
      },
      'endpoints': {
        'runs': {
          'method': 'POST',
          'path': '/v1/runs',
          'required_scopes': ['chat:write'],
        },
        'run_events': {
          'method': 'GET',
          'path': '/v1/runs/{run_id}/events',
          'required_scopes': ['chat:read'],
        },
        'session_chat_stream': {
          'method': 'POST',
          'path': '/api/sessions/{session_id}/chat/stream',
          'required_scopes': ['chat:write'],
        },
      },
    });
    final authorized = HermesCapabilityDocument.fromJson({
      'schema_version': 1,
      'auth': {
        'type': 'bearer',
        'required': true,
        'granted_scopes': ['chat:read', 'chat:write'],
      },
      'features': {
        'run_submission': true,
        'run_events_sse': true,
        'session_chat_streaming': true,
      },
      'endpoints': readOnly.endpoints.map(
        (name, endpoint) => MapEntry(name, {
          'method': endpoint.method,
          'path': endpoint.path,
          'required_scopes': endpoint.requiredScopes,
        }),
      ),
    });

    expect(HermesTransportPolicy(readOnly).supportsAnyChatTransport, isFalse);
    expect(HermesTransportPolicy(readOnly).supportsRunStatus, isFalse);
    expect(HermesTransportPolicy(authorized).supportsSessionChatStream, isTrue);
    expect(HermesTransportPolicy(authorized).supportsRunsTransport, isTrue);
  });

  test('parsed capability scopes are immutable', () {
    final document = HermesCapabilityDocument.fromJson({
      'auth': {
        'type': 'bearer',
        'required': true,
        'granted_scopes': ['profiles:read'],
      },
      'endpoints': {
        'profiles': {
          'method': 'GET',
          'path': '/api/profiles',
          'required_scopes': ['profiles:read'],
        },
      },
    });

    expect(
      () => document.auth.grantedScopes[0] = 'profiles:write',
      throwsUnsupportedError,
    );
    expect(
      () =>
          document.endpoints['profiles']!.requiredScopes[0] = 'profiles:write',
      throwsUnsupportedError,
    );
  });

  test('absent schema_version parses as version 1', () {
    final document = HermesCapabilityDocument.fromJson({
      'auth': {'type': 'bearer', 'required': true},
      'endpoints': <String, Object?>{},
    });

    expect(document.schemaVersion, 1);
    expect(document.supportsSchema, isTrue);
  });

  test('absent scope arrays parse as empty rather than crashing', () {
    final document = HermesCapabilityDocument.fromJson({
      'auth': {'type': 'bearer', 'required': true},
      'endpoints': {
        'profiles': {'method': 'GET', 'path': '/api/profiles'},
      },
    });

    expect(document.auth.grantedScopes, isEmpty);
    expect(document.auth.allows('profiles:read'), isFalse);
    expect(document.endpoints['profiles']!.requiredScopes, isEmpty);
    expect(document.endpoints['profiles']!.profileScoped, isFalse);
  });

  test('unknown top-level and nested fields do not crash older clients', () {
    expect(
      () => HermesCapabilityDocument.fromJson({
        'schema_version': 1,
        'unexpected_top_level_field': 'ignored',
        'auth': {
          'type': 'bearer',
          'required': true,
          'unexpected_auth_field': 'ignored',
        },
        'endpoints': {
          'profiles': {
            'method': 'GET',
            'path': '/api/profiles',
            'unexpected_endpoint_field': 'ignored',
          },
        },
      }),
      returnsNormally,
    );
  });

  test('profile context support requires the exact query declaration', () {
    final valid = HermesProfileContextCapability.fromJson({
      'type': 'query',
      'name': 'profile',
      'required': true,
      'default_profile_id': 'default',
    });
    expect(valid.isSupportedQueryContext, isTrue);

    for (final malformed in [
      {
        'type': 'header',
        'name': 'profile',
        'required': true,
        'default_profile_id': 'default',
      },
      {
        'type': 'query',
        'name': 'wrong',
        'required': true,
        'default_profile_id': 'default',
      },
      {
        'type': 'query',
        'name': 'profile',
        'required': false,
        'default_profile_id': 'default',
      },
      {'type': 'query', 'name': 'profile', 'required': true},
    ]) {
      expect(
        HermesProfileContextCapability.fromJson(
          malformed,
        ).isSupportedQueryContext,
        isFalse,
        reason: '$malformed is not the advertised profile query contract',
      );
    }
  });

  test('absent profile_context leaves profile-scoped operations unavailable '
      'rather than implicitly default-scoped', () {
    final document = HermesCapabilityDocument.fromJson({
      'auth': {'type': 'bearer', 'required': true},
      'endpoints': {
        'session_chat_stream': {
          'method': 'POST',
          'path': '/api/sessions/{session_id}/chat/stream',
          'profile_scoped': true,
        },
      },
      'features': {'session_chat_streaming': true},
    });

    expect(document.profileContext.name, isEmpty);
    expect(document.profileContext.isSupportedQueryContext, isFalse);

    final policy = HermesTransportPolicy(document);
    expect(policy.supportsSessionChatStream, isFalse);
  });

  test(
    'schema version 2 exposes no transport operations until the client supports it',
    () {
      final document = HermesCapabilityDocument.fromJson({
        'schema_version': 2,
        ...jsonDecode(_capabilitiesFixture) as Map<String, Object?>,
      });
      final policy = HermesTransportPolicy(document);

      expect(document.supportsSchema, isFalse);
      expect(policy.supportsSessionChatStream, isFalse);
      expect(policy.supportsRunsTransport, isFalse);
      expect(policy.supportsRunStatus, isFalse);
      expect(policy.supportsRunStop, isFalse);
      expect(policy.supportsRunApprovalResponse, isFalse);
      expect(policy.supportsToolProgressEvents, isFalse);
      expect(policy.supportsAnyChatTransport, isFalse);
      expect(policy.supportsConfigWrite, isFalse);
      expect(policy.supportsMemoryWrite, isFalse);
      expect(policy.supportsAudioApi, isFalse);
      expect(policy.supportsRealtimeVoice, isFalse);
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
          'Gateway health',
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
      expect(statuses['Gateway health'], HermesSurfaceStatus.deferred);
      expect(statuses['Memory UI'], HermesSurfaceStatus.deferred);
      expect(
        statuses['Jobs/schedules inventory'],
        HermesSurfaceStatus.readOnly,
      );
      expect(statuses['Jobs/schedules admin'], HermesSurfaceStatus.deferred);
      expect(
        details['Jobs/schedules admin'],
        contains('create/pause/resume/trigger/delete scheduling'),
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
        contains('exact scoped profile soul contract'),
      );
      expect(statuses['Attachments/media'], HermesSurfaceStatus.available);
      expect(details['Attachments/media'], contains('bounded UTF-8 text'));
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

  test('surface readiness rejects ungranted session scopes', () {
    final capabilities = HermesCapabilityDocument.fromJson({
      'schema_version': 1,
      'auth': {
        'type': 'bearer',
        'required': true,
        'granted_scopes': <String>[],
      },
      'endpoints': {
        'sessions': {
          'method': 'GET',
          'path': '/api/sessions',
          'required_scopes': ['sessions:read'],
        },
        'session_create': {
          'method': 'POST',
          'path': '/api/sessions',
          'required_scopes': ['sessions:write'],
        },
      },
    });

    final sessions = hermesSurfaceReadiness(
      capabilities,
    ).singleWhere((item) => item.title == 'Sessions');

    expect(sessions.status, HermesSurfaceStatus.blocked);
    expect(sessions.detail, contains('authorized'));
  });

  test('surface readiness recognizes advertised detailed gateway health', () {
    final capabilities = HermesCapabilityDocument.fromJson({
      'schema_version': 1,
      'auth': {
        'type': 'bearer',
        'required': true,
        'granted_scopes': ['gateway:read'],
      },
      'endpoints': {
        'health_detailed': {
          'method': 'GET',
          'path': '/health/detailed',
          'required_scopes': ['gateway:read'],
        },
      },
    });

    final gatewayHealth = hermesSurfaceReadiness(
      capabilities,
    ).singleWhere((item) => item.title == 'Gateway health');

    expect(gatewayHealth.status, HermesSurfaceStatus.readOnly);
    expect(gatewayHealth.detail, contains('bounded detailed health'));
  });

  test('surface readiness recognizes exact scoped persona contracts', () {
    final capabilities = HermesCapabilityDocument.fromJson({
      'schema_version': 1,
      'auth': {
        'type': 'bearer',
        'required': true,
        'granted_scopes': ['profiles:read', 'profiles:write'],
      },
      'endpoints': {
        'profile_soul': {
          'method': 'GET',
          'path': '/api/profiles/{name}/soul',
          'required_scopes': ['profiles:read'],
        },
        'profile_soul_update': {
          'method': 'PUT',
          'path': '/api/profiles/{name}/soul',
          'required_scopes': ['profiles:write'],
        },
      },
    });

    final persona = hermesSurfaceReadiness(
      capabilities,
    ).singleWhere((item) => item.title == 'Persona/SOUL');

    expect(persona.status, HermesSurfaceStatus.available);
    expect(persona.detail, contains('gateway-scoped profile editor'));
  });

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
      final skillDetails = await client.listSkillDetails();
      expect(skillDetails.map((skill) => skill.name), ['ascii-art', 'github']);
      expect(skillDetails.first.description, 'ASCII art generation');
      expect(skillDetails.first.category, 'creative');
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
        '/v1/skills',
        '/v1/toolsets',
        '/api/jobs',
        '/api/sessions',
        '/api/sessions/sess_1/messages',
      ]);
    },
  );

  test('installed skill metadata is normalized and bounded', () {
    final skill = HermesSkill.fromJson({
      'name': '  browser\u0000 skill  ',
      'description': List.filled(1200, 'd').join(),
      'category': List.filled(100, 'c').join(),
    });

    expect(skill.name, 'browser skill');
    expect(skill.description, hasLength(1000));
    expect(skill.description, endsWith('…'));
    expect(skill.category, hasLength(80));
    expect(skill.category, endsWith('…'));
  });

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

  test('serializes image content for session and run transports', () async {
    const content = [
      {'type': 'input_text', 'text': 'What is this?'},
      {'type': 'input_image', 'image_url': 'data:image/png;base64,AAAA'},
    ];
    final posts = <String, Map<String, Object?>>{};
    final client = HermesApiClient(
      config: HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642'),
      postStream: (uri, headers, body) {
        posts[uri.path] = jsonDecode(body) as Map<String, Object?>;
        return const Stream.empty();
      },
      post: (uri, headers, body) async {
        posts[uri.path] = jsonDecode(body) as Map<String, Object?>;
        return '{"id":"run_1","session_id":"sess_1"}';
      },
    );

    await client.streamSessionChat('sess_1', message: content).toList();
    await client.startRun(sessionId: 'sess_1', message: content);

    expect(posts['/api/sessions/sess_1/chat/stream'], {'message': content});
    expect(posts['/v1/runs'], {
      'session_id': 'sess_1',
      'input': [
        {'role': 'user', 'content': content},
      ],
      'message': content,
    });
  });

  test('run transport reads bounded status and token usage', () async {
    final client = HermesApiClient(
      config: HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642'),
      get: (uri, headers) async {
        expect(uri.path, '/v1/runs/run_1');
        return '''
          {
            "object": "hermes.run",
            "run_id": "run_1",
            "session_id": "sess_1",
            "status": "completed",
            "output": "Done",
            "usage": {
              "input_tokens": 12,
              "output_tokens": 7,
              "total_tokens": 19
            }
          }
        ''';
      },
    );

    final run = await client.getRunStatus('run_1');

    expect(run.id, 'run_1');
    expect(run.sessionId, 'sess_1');
    expect(run.status, HermesRunLifecycle.completed);
    expect(run.output, 'Done');
    expect(run.usage?.inputTokens, 12);
    expect(run.usage?.outputTokens, 7);
    expect(run.usage?.totalTokens, 19);
  });

  test('run status preserves explicitly reported zero token usage', () {
    final run = HermesRun.fromJson({
      'run_id': 'run_1',
      'usage': {'input_tokens': 0, 'output_tokens': 0, 'total_tokens': 0},
    });

    expect(run.usage, isNotNull);
    expect(run.usage?.totalTokens, 0);
  });

  test('run usage rejects negative values and caps excessive counts', () {
    final usage = HermesRunUsage.fromJson({
      'input_tokens': -12,
      'output_tokens': 999999999999,
      'total_tokens': 999999999999,
    });

    expect(usage.inputTokens, 0);
    expect(usage.outputTokens, 999999999);
    expect(usage.totalTokens, 999999999);
  });

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
      expect(posts['/v1/runs'], {
        'session_id': 'sess_1',
        'input': 'hello',
        'message': 'hello',
      });

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
      'event: message.error\ndata: message failed token=secret-message-error\n\n',
      'event: response.error\ndata: response failed token=secret-response-error\n\n',
      'event: assistant.delta\ndata: {not json}\n\n',
    ]);

    expect(events.map((event) => event.name), [
      'error',
      'message.error',
      'response.error',
    ]);
    expect(
      events.first.payload['message'],
      'upstream closed token=secret-error',
    );
    expect(
      events[1].payload['message'],
      'message failed token=secret-message-error',
    );
    expect(
      events.last.payload['message'],
      'response failed token=secret-response-error',
    );
  });

  test('profile list parses stable id and metadata', () async {
    final config = HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642');
    final client = HermesApiClient(
      config: config,
      get: (_, _) async => jsonEncode({
        'data': [
          {
            'id': 'coder',
            'name': 'Coding Agent',
            'revision': 'rev-1',
            'skills_count': 4,
          },
        ],
      }),
    );

    final profiles = await client.listProfiles();
    expect(profiles.single.id, 'coder');
    expect(profiles.single.displayName, 'Coding Agent');
    expect(profiles.single.revision, 'rev-1');
    expect(profiles.single.skillsCount, 4);
  });

  test('listProfiles discards rows with a blank id', () async {
    final client = HermesApiClient(
      config: HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642'),
      get: (_, _) async => jsonEncode({
        'data': [
          {'id': '', 'name': 'Ghost', 'revision': 'r'},
          {'name': 'Missing id', 'revision': 'r'},
          {'id': 'keep', 'name': 'Kept', 'revision': 'rev-2'},
        ],
      }),
    );

    final profiles = await client.listProfiles();
    expect(profiles.map((profile) => profile.id), ['keep']);
  });

  test('creates and clones a profile over POST', () async {
    final posts = <String, Map<String, Object?>>{};
    final client = HermesApiClient(
      config: HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642'),
      post: (uri, headers, body) async {
        posts[uri.path] = jsonDecode(body) as Map<String, Object?>;
        return jsonEncode({
          'profile': {'id': 'coder', 'name': 'Coder', 'revision': 'rev-1'},
        });
      },
    );

    final created = await client.createProfile(
      name: ' Coder ',
      cloneFrom: ' default ',
    );

    expect(posts['/api/profiles'], {'name': 'Coder', 'clone_from': 'default'});
    expect(created.id, 'coder');
    expect(created.revision, 'rev-1');
  });

  test('renames a profile over PATCH with an If-Match precondition', () async {
    final patches = <String, Map<String, Object?>>{};
    String? ifMatch;
    final client = HermesApiClient(
      config: HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642'),
      patch: (uri, headers, body) async {
        patches[uri.path] = jsonDecode(body) as Map<String, Object?>;
        ifMatch = headers['If-Match'];
        return jsonEncode({
          'profile': {'id': 'coder', 'name': 'Renamed', 'revision': 'rev-2'},
        });
      },
    );

    final updated = await client.renameProfile(
      profileId: 'coder',
      name: ' Renamed ',
      revision: 'rev-1',
    );

    expect(patches['/api/profiles/coder'], {'name': 'Renamed'});
    expect(ifMatch, 'rev-1');
    expect(updated.revision, 'rev-2');
  });

  test('deletes a profile over DELETE with If-Match and confirms the '
      'envelope', () async {
    final deletes = <String>[];
    String? ifMatch;
    final client = HermesApiClient(
      config: HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642'),
      delete: (uri, headers) async {
        deletes.add(uri.path);
        ifMatch = headers['If-Match'];
        return jsonEncode({'id': 'coder', 'deleted': true});
      },
    );

    await client.deleteProfile(profileId: 'coder', revision: 'rev-9');

    expect(deletes, ['/api/profiles/coder']);
    expect(ifMatch, 'rev-9');
  });

  test('rejects an unconfirmed profile delete response', () async {
    final client = HermesApiClient(
      config: HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642'),
      delete: (_, _) async => jsonEncode({'id': 'other', 'deleted': false}),
    );

    await expectLater(
      client.deleteProfile(profileId: 'coder', revision: 'rev-9'),
      throwsStateError,
    );
  });

  test('reads and writes profile soul with the mandatory profile query and '
      'an If-Match precondition', () async {
    Uri? getUri;
    Uri? putUri;
    String? ifMatch;
    Map<String, Object?>? putBody;
    final client = HermesApiClient(
      config: HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642'),
      get: (uri, headers) async {
        getUri = uri;
        return jsonEncode({'soul': 'Be helpful.', 'revision': 'rev-1'});
      },
      put: (uri, headers, body) async {
        putUri = uri;
        ifMatch = headers['If-Match'];
        putBody = jsonDecode(body) as Map<String, Object?>;
        return jsonEncode({'soul': 'Be terse.', 'revision': 'rev-2'});
      },
    );

    final soul = await client.readProfileSoul('default');
    expect(soul.soul, 'Be helpful.');
    expect(getUri!.path, '/api/profiles/default/soul');
    expect(getUri!.queryParameters['profile'], 'default');

    final saved = await client.writeProfileSoul(
      profileId: 'default',
      soul: 'Be terse.',
      revision: 'rev-1',
    );
    expect(putUri!.path, '/api/profiles/default/soul');
    expect(putUri!.queryParameters['profile'], 'default');
    expect(ifMatch, 'rev-1');
    expect(putBody, {'soul': 'Be terse.'});
    expect(saved.revision, 'rev-2');
  });

  test('profileScopedUri merges a mandatory profile query including '
      'default', () {
    final config = HermesApiConfig.fromBaseUrl('https://hermes.example:8642');

    expect(
      config.profilesUri.toString(),
      'https://hermes.example:8642/api/profiles',
    );
    expect(
      config.profileUri('coder').toString(),
      'https://hermes.example:8642/api/profiles/coder',
    );
    expect(
      config.profileSoulUri('coder').toString(),
      'https://hermes.example:8642/api/profiles/coder/soul',
    );
    expect(
      config.profileScopedUri(config.sessionsUri, 'default').toString(),
      'https://hermes.example:8642/api/sessions?profile=default',
    );
    expect(
      config.profileScopedUri(config.sessionsUri, ' coder ').toString(),
      'https://hermes.example:8642/api/sessions?profile=coder',
    );
    expect(
      () => config.profileScopedUri(config.sessionsUri, '  '),
      throwsArgumentError,
    );
  });

  test('provider list parses presence and a masked hint without a full '
      'key', () async {
    const sentinel = 'sk-secret-value-1234';
    Uri? requested;
    final client = HermesApiClient(
      config: HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642'),
      get: (uri, headers) async {
        requested = uri;
        return jsonEncode({
          'data': [
            {
              'slug': 'openai',
              'label': 'OpenAI',
              'auth_type': 'api_key',
              'env_vars': ['OPENAI_API_KEY'],
              'configured': true,
              'key_hint': '····1234',
            },
            {'slug': '', 'label': 'Ghost', 'env_vars': <String>[]},
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
      },
    );

    final providers = await client.listProviders(profile: 'default');

    // Invariant: the request carries the mandatory ?profile=.
    expect(requested!.path, '/api/providers');
    expect(requested!.queryParameters['profile'], 'default');
    // Blank-slug rows are discarded.
    expect(providers.map((p) => p.slug), ['openai', 'anthropic']);
    final openai = providers.first;
    expect(openai.configured, isTrue);
    expect(openai.keyHint, '····1234');
    expect(openai.envVars, ['OPENAI_API_KEY']);
    // The masked hint never carries the full key.
    expect(openai.keyHint!.contains(sentinel), isFalse);
  });

  test('setProviderCredential sends the value in the PUT body but never '
      'returns it', () async {
    const sentinel = 'sk-live-DEADBEEF-super-secret';
    Uri? putUri;
    Map<String, Object?>? putBody;
    final client = HermesApiClient(
      config: HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642'),
      put: (uri, headers, body) async {
        putUri = uri;
        putBody = jsonDecode(body) as Map<String, Object?>;
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

    final provider = await client.setProviderCredential(
      slug: 'openai',
      envVar: 'OPENAI_API_KEY',
      value: sentinel,
      profile: 'default',
    );

    // The secret IS transmitted in the request body...
    expect(putBody, {'env_var': 'OPENAI_API_KEY', 'value': sentinel});
    expect(putUri!.path, '/api/providers/openai/credential');
    expect(putUri!.queryParameters['profile'], 'default');
    // ...but the returned model exposes only presence, never the sent value.
    expect(provider.configured, isTrue);
    expect(provider.keyHint, '····cret');
    final encoded = jsonEncode({
      'slug': provider.slug,
      'label': provider.label,
      'authType': provider.authType,
      'envVars': provider.envVars,
      'configured': provider.configured,
      'keyHint': provider.keyHint,
    });
    expect(encoded.contains(sentinel), isFalse);
  });

  test('removeProviderCredential deletes with the profile and env_var '
      'query', () async {
    Uri? deleteUri;
    final client = HermesApiClient(
      config: HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642'),
      delete: (uri, headers) async {
        deleteUri = uri;
        return jsonEncode({
          'data': {
            'slug': 'openai',
            'label': 'OpenAI',
            'auth_type': 'api_key',
            'env_vars': ['OPENAI_API_KEY'],
            'configured': false,
            'key_hint': null,
          },
        });
      },
    );

    final provider = await client.removeProviderCredential(
      slug: 'openai',
      envVar: 'OPENAI_API_KEY',
      profile: 'default',
    );

    expect(deleteUri!.path, '/api/providers/openai/credential');
    expect(deleteUri!.queryParameters['profile'], 'default');
    expect(deleteUri!.queryParameters['env_var'], 'OPENAI_API_KEY');
    expect(provider.configured, isFalse);
    expect(provider.keyHint, isNull);
  });

  test(
    'validateProviderCredential returns ok and a non-secret detail',
    () async {
      Uri? postUri;
      final client = HermesApiClient(
        config: HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642'),
        post: (uri, headers, body) async {
          postUri = uri;
          return jsonEncode({'ok': true, 'detail': 'Credential accepted.'});
        },
      );

      final probe = await client.validateProviderCredential(
        slug: 'openai',
        profile: 'default',
      );

      expect(postUri!.path, '/api/providers/openai/credential/validate');
      expect(postUri!.queryParameters['profile'], 'default');
      expect(probe.ok, isTrue);
      expect(probe.detail, 'Credential accepted.');
    },
  );

  test('model inventory parses catalog, active, auxiliary, and '
      'revision', () async {
    Uri? requested;
    final client = HermesApiClient(
      config: HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642'),
      get: (uri, headers) async {
        requested = uri;
        return jsonEncode({
          'catalog': {
            'providers': {
              'openai': {
                'models': [
                  {'id': 'gpt-5', 'description': 'flagship'},
                ],
              },
            },
          },
          'active': {'provider': 'openai', 'model': 'gpt-5'},
          'auxiliary': [
            {'task': 'title', 'provider': 'auto', 'model': ''},
          ],
          'revision': 'mrev-1',
        });
      },
    );

    final inventory = await client.getModelInventory(profile: 'default');

    expect(requested!.path, '/api/models');
    expect(requested!.queryParameters['profile'], 'default');
    expect(inventory.assignment.activeProvider, 'openai');
    expect(inventory.assignment.activeModel, 'gpt-5');
    expect(inventory.assignment.revision, 'mrev-1');
    expect(inventory.assignment.auxiliary.single.task, 'title');
    expect(inventory.catalog.providers.single.provider, 'openai');
    expect(inventory.catalog.providers.single.models.single.id, 'gpt-5');
  });

  test('refreshModelCatalog hits the refresh endpoint, not the plain '
      'GET', () async {
    Uri? postUri;
    var getCalled = false;
    final client = HermesApiClient(
      config: HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642'),
      get: (uri, headers) async {
        getCalled = true;
        return '{}';
      },
      post: (uri, headers, body) async {
        postUri = uri;
        return jsonEncode({
          'catalog': {
            'providers': {
              'anthropic': {
                'models': [
                  {'id': 'claude-4'},
                ],
              },
            },
          },
        });
      },
    );

    final catalog = await client.refreshModelCatalog(profile: 'default');

    expect(getCalled, isFalse);
    expect(postUri!.path, '/api/models/refresh');
    expect(postUri!.queryParameters['profile'], 'default');
    expect(catalog.providers.single.models.single.id, 'claude-4');
  });

  test('assignModel sends If-Match and the assignment body', () async {
    Uri? putUri;
    String? ifMatch;
    Map<String, Object?>? putBody;
    final client = HermesApiClient(
      config: HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642'),
      put: (uri, headers, body) async {
        putUri = uri;
        ifMatch = headers['If-Match'];
        putBody = jsonDecode(body) as Map<String, Object?>;
        return jsonEncode({
          'active': {'provider': 'openai', 'model': 'gpt-5'},
          'auxiliary': <Object?>[],
          'revision': 'mrev-2',
        });
      },
    );

    final assignment = await client.assignModel(
      scope: 'main',
      provider: 'openai',
      model: 'gpt-5',
      revision: 'mrev-1',
      profile: 'default',
    );

    expect(putUri!.path, '/api/models/assignment');
    expect(putUri!.queryParameters['profile'], 'default');
    expect(ifMatch, 'mrev-1');
    expect(putBody, {'scope': 'main', 'provider': 'openai', 'model': 'gpt-5'});
    expect(assignment.revision, 'mrev-2');
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
  "auth": {"type": "bearer", "required": true, "granted_scopes": ["tasks:read"]},
  "features": {
    "realtime_voice": true,
    "admin_config_rw": true,
    "memory_write_api": true,
    "jobs_admin": true,
    "attachments_api": true
  },
  "endpoints": {
    "jobs": {"method": "GET", "path": "/api/jobs", "required_scopes": ["tasks:read"]}
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
