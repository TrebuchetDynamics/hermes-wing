part of '../hermes_api_channel_test.dart';

void _hermesApiChannelConnectionTests() {
  test(
    'connect selects the first existing session and loads its messages',
    () async {
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
        ),
      );

      await channel.connect(baseUrl: 'http://127.0.0.1:8642', apiKey: 'key');

      expect(channel.state.status, HermesConnectionStatus.connected);
      expect(channel.state.connectedBaseUrl, 'http://127.0.0.1:8642');
      expect(channel.state.connectedWithApiKey, isTrue);
      expect(channel.state.sessions.single.id, 'sess_1');
      expect(channel.state.activeSessionId, 'sess_1');
      expect(channel.state.activeMessages.single.text, 'Hello');
    },
  );

  test('connect loads read-only Hermes catalog when advertised', () async {
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _catalogCapabilitiesFixture,
            '/v1/models' => _modelsFixture,
            '/v1/skills' => _skillsFixture,
            '/v1/toolsets' => _toolsetsFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
      ),
    );

    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    expect(channel.state.models, ['hermes-agent']);
    expect(channel.state.skills, ['ascii-art', 'github']);
    expect(
      channel.state.skillDetails.first.description,
      'ASCII art generation',
    );
    expect(channel.state.skillDetails.first.category, 'creative');
    expect(channel.state.enabledToolsets, ['default']);
  });

  test(
    'connect does not probe detailed health without the granted gateway scope',
    () async {
      const capabilities = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "schema_version": 1,
  "auth": {"type": "bearer", "required": true, "granted_scopes": []},
  "features": {},
  "endpoints": {
    "health_detailed": {
      "method": "GET",
      "path": "/health/detailed",
      "required_scopes": ["gateway:read"]
    }
  }
}
''';
      final requestedPaths = <String>[];
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            requestedPaths.add(uri.path);
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => capabilities,
              '/api/sessions' => '{"object":"list","data":[]}',
              '/health/detailed' => throw StateError('must not be requested'),
              _ => throw StateError('unexpected GET $uri'),
            };
          },
        ),
      );
      addTearDown(channel.dispose);

      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      expect(requestedPaths, isNot(contains('/health/detailed')));
      expect(channel.state.canReadDetailedHealth, isFalse);
      expect(channel.state.detailedHealth, isNull);

      requestedPaths.clear();
      await expectLater(channel.loadDetailedHealth(), throwsStateError);
      expect(requestedPaths, isEmpty);
    },
  );

  test(
    'connect does not probe jobs without the granted tasks read scope',
    () async {
      const capabilities = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "schema_version": 1,
  "auth": {"type": "bearer", "required": true, "granted_scopes": []},
  "features": {},
  "endpoints": {
    "jobs": {
      "method": "GET",
      "path": "/api/jobs",
      "required_scopes": ["tasks:read"]
    }
  }
}
''';
      final requestedPaths = <String>[];
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            requestedPaths.add(uri.path);
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => capabilities,
              '/api/sessions' => '{"object":"list","data":[]}',
              '/api/jobs' => throw StateError('must not be requested'),
              _ => throw StateError('unexpected GET $uri'),
            };
          },
        ),
      );
      addTearDown(channel.dispose);

      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      expect(requestedPaths, isNot(contains('/api/jobs')));
      expect(channel.state.canReadJobs, isFalse);
      expect(channel.state.jobs, isEmpty);

      requestedPaths.clear();
      await expectLater(channel.loadJobs(), throwsStateError);
      expect(requestedPaths, isEmpty);
    },
  );

  test('connect starts independent startup requests concurrently', () async {
    const capabilities = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true, "granted_scopes": ["gateway:read", "skills:read", "tools:read", "tasks:read"]},
  "features": {},
  "endpoints": {
    "health_detailed": {"method": "GET", "path": "/health/detailed", "required_scopes": ["gateway:read"]},
    "models": {"method": "GET", "path": "/v1/models"},
    "skills": {"method": "GET", "path": "/v1/skills", "required_scopes": ["skills:read"]},
    "toolsets": {"method": "GET", "path": "/v1/toolsets", "required_scopes": ["tools:read"]},
    "jobs": {"method": "GET", "path": "/api/jobs", "required_scopes": ["tasks:read"]}
  }
}
''';
    final concurrentPaths = {
      '/health/detailed',
      '/v1/models',
      '/v1/skills',
      '/v1/toolsets',
      '/api/jobs',
      '/api/sessions',
    };
    final started = <String>[];
    final firstStarted = Completer<void>();
    final release = Completer<void>();
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          if (concurrentPaths.contains(uri.path)) {
            started.add(uri.path);
            if (!firstStarted.isCompleted) firstStarted.complete();
            await release.future;
          }
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => capabilities,
            '/health/detailed' => '{"status":"ok"}',
            '/v1/models' => _modelsFixture,
            '/v1/skills' => _skillsFixture,
            '/v1/toolsets' => _toolsetsFixture,
            '/api/jobs' => _jobsFixture,
            '/api/sessions' => '{"object":"list","data":[]}',
            _ => throw StateError('unexpected GET $uri'),
          };
        },
      ),
    );
    final connect = channel.connect(baseUrl: 'http://127.0.0.1:8642');
    addTearDown(() async {
      if (!release.isCompleted) release.complete();
      await connect;
      channel.dispose();
    });

    await firstStarted.future;
    await pumpEventQueue();

    expect(started.toSet(), concurrentPaths);
    release.complete();
    await connect;
    expect(channel.state.status, HermesConnectionStatus.connected);
  });

  test('connect distinguishes failed optional inventory from empty', () async {
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _catalogCapabilitiesFixture,
            '/v1/models' ||
            '/v1/skills' ||
            '/v1/toolsets' => throw StateError('inventory offline'),
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
      ),
    );

    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    expect(channel.state.status, HermesConnectionStatus.connected);
    expect(channel.state.models, isEmpty);
    expect(
      channel.state.optionalResourceErrors.keys,
      containsAll([
        HermesOptionalResource.models,
        HermesOptionalResource.skills,
        HermesOptionalResource.toolsets,
      ]),
    );
    expect(
      channel.state.optionalResourceErrors[HermesOptionalResource.models],
      contains('inventory offline'),
    );
  });

  test('connect loads read-only Hermes jobs when advertised', () async {
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _jobsCapabilitiesFixture,
            '/api/jobs' => _jobsFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
      ),
    );

    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    expect(channel.state.jobs.single.id, 'job_1');
    expect(channel.state.jobs.single.displayName, 'Morning check');
  });

  test('connect loads detailed Hermes health when advertised', () async {
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _healthCapabilitiesFixture,
            '/health/detailed' =>
              '{"status":"ok","platform":"hermes-agent","version":"0.16.0","gateway_state":"running","active_agents":0}',
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
      ),
    );

    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    expect(channel.state.detailedHealth?.version, '0.16.0');
    expect(channel.state.detailedHealth?.gatewayState, 'running');
    expect(channel.state.detailedHealth?.activeAgents, 0);
  });

  test('loadDetailedHealth refreshes the advertised status', () async {
    var activeAgents = 0;
    final requested = <String>[];
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          requested.add(uri.path);
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _healthCapabilitiesFixture,
            '/health/detailed' =>
              '{"status":"ok","platform":"hermes-agent","version":"0.18.0","gateway_state":"running","active_agents":$activeAgents}',
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    expect(channel.state.detailedHealth?.activeAgents, 0);
    requested.clear();
    activeAgents = 2;

    await channel.loadDetailedHealth();

    expect(requested, ['/health/detailed']);
    expect(channel.state.detailedHealth?.activeAgents, 2);
  });

  test(
    'connect never creates a session merely by viewing an empty gateway',
    () async {
      final posts = <String>[];
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _sessionCreateCapabilitiesFixture,
              '/api/sessions' => '{"object":"list","data":[]}',
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            posts.add(uri.path);
            return '{}';
          },
        ),
      );

      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      expect(channel.state.status, HermesConnectionStatus.connected);
      expect(channel.state.sessions, isEmpty);
      expect(channel.state.activeSessionId, isNull);
      expect(channel.state.messages, isEmpty);
      expect(posts, isEmpty);
    },
  );

  test(
    'connect stays sessionless when create is absent and none exist',
    () async {
      final posts = <String>[];
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _chatOnlyCapabilitiesFixture,
              '/api/sessions' => '{"object":"list","data":[]}',
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            posts.add(uri.path);
            return '{}';
          },
        ),
      );

      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      expect(channel.state.status, HermesConnectionStatus.connected);
      expect(channel.state.sessions, isEmpty);
      expect(channel.state.activeSessionId, isNull);
      expect(channel.state.messages, isEmpty);
      expect(posts, isEmpty);
    },
  );

  test('connect surfaces a bounded error without throwing', () async {
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async => throw StateError('offline'),
      ),
    );

    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    expect(channel.state.status, HermesConnectionStatus.error);
    expect(channel.state.errorMessage, contains('offline'));
  });

  test('connect redacts and bounds secret-looking stored errors', () async {
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async => throw StateError(
          '401 unauthorized for Bearer secret-api-key token=secret-token '
          'Basic secret-basic Cookie: sid=secret-cookie; '
          'https://user:secret-pass@example.test/path '
          'sk-1234567890abcdef '
          'ghp_'
          'abcdefghijklmnopqrstuvwxyz123456 '
          'xoxb-'
          '123456789012-abcdefabcdefabcdef '
          'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.signaturevalue '
          '${List.filled(30, 'verbose').join(' ')} tail-marker',
        ),
      ),
    );

    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    expect(channel.state.status, HermesConnectionStatus.error);
    expect(channel.state.errorMessage, contains('401 unauthorized'));
    expect(channel.state.errorMessage, contains('Bearer [redacted]'));
    expect(channel.state.errorMessage, contains('Basic [redacted]'));
    expect(channel.state.errorMessage, contains('Cookie: [redacted]'));
    expect(channel.state.errorMessage, contains('https://[redacted]@'));
    expect(channel.state.errorMessage, contains('sk-[redacted]'));
    expect(channel.state.errorMessage, contains('ghp_[redacted]'));
    expect(channel.state.errorMessage, contains('xox-[redacted]'));
    expect(channel.state.errorMessage, contains('[redacted-jwt]'));
    expect(channel.state.errorMessage, isNot(contains('secret-api-key')));
    expect(channel.state.errorMessage, isNot(contains('secret-token')));
    expect(channel.state.errorMessage, isNot(contains('secret-basic')));
    expect(channel.state.errorMessage, isNot(contains('secret-cookie')));
    expect(channel.state.errorMessage, isNot(contains('secret-pass')));
    expect(channel.state.errorMessage, isNot(contains('tail-marker')));
    expect(channel.state.errorMessage!.length, lessThanOrEqualTo(241));
  });

  test('connect reports invalid Hermes base URLs without HTTP', () async {
    var clientBuilt = false;
    final channel = HermesApiChannel(
      clientBuilder: (config) {
        clientBuilt = true;
        return HermesApiClient(config: config);
      },
    );

    await channel.connect(baseUrl: '   ');

    expect(clientBuilt, isFalse);
    expect(channel.state.status, HermesConnectionStatus.error);
    expect(channel.state.errorMessage, contains('baseUrl'));
    expect(channel.state.sessions, isEmpty);
  });

  test('failed reconnect clears stale endpoint session data', () async {
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          if (config.baseUri.port == 8643) throw StateError('offline');
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _capabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    expect(channel.state.activeMessages.single.text, 'Hello');

    await channel.connect(baseUrl: 'http://127.0.0.1:8643');

    expect(channel.state.status, HermesConnectionStatus.error);
    expect(channel.state.errorMessage, contains('offline'));
    expect(channel.state.sessions, isEmpty);
    expect(channel.state.messages, isEmpty);
    expect(channel.state.activeSessionId, isNull);
  });

  test('stale connect results cannot overwrite a newer connection', () async {
    final firstHealthStarted = Completer<void>();
    final releaseFirstHealth = Completer<void>();
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          final staleConnection = config.baseUri.port == 8642;
          if (staleConnection && uri.path == '/health') {
            firstHealthStarted.complete();
            await releaseFirstHealth.future;
          }
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _capabilitiesFixture,
            '/api/sessions' =>
              staleConnection
                  ? _sessionsFixture
                  : '{"object":"list","data":[{"id":"fresh","source":"api_server","title":"Fresh"}]}',
            '/api/sessions/sess_1/messages' => _messagesFixture,
            '/api/sessions/fresh/messages' =>
              '{"object":"list","session_id":"fresh","data":[{"id":"msg_fresh","session_id":"fresh","role":"assistant","content":"Fresh connection"}]}',
            _ => throw StateError('unexpected GET $uri'),
          };
        },
      ),
    );

    final staleConnect = channel.connect(baseUrl: 'http://127.0.0.1:8642');
    await firstHealthStarted.future;
    await channel.connect(baseUrl: 'http://127.0.0.1:8643');
    releaseFirstHealth.complete();
    await staleConnect;

    expect(channel.state.status, HermesConnectionStatus.connected);
    expect(channel.state.activeSessionId, 'fresh');
    expect(channel.state.activeMessages.single.text, 'Fresh connection');
  });
}
