part of '../hermes_api_channel_test.dart';

void _hermesApiChannelRunFailureTests() {
  test(
    'stop during pending run submission prevents late stream attach',
    () async {
      final startRunStarted = Completer<void>();
      final releaseStartRun = Completer<void>();
      var runEventsOpened = false;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            expect(uri.path, '/v1/runs');
            if (!startRunStarted.isCompleted) startRunStarted.complete();
            await releaseStartRun.future;
            return '{"object":"hermes.run","run":{"id":"late_run","session_id":"sess_1"}}';
          },
          getStream: (uri, headers) {
            runEventsOpened = true;
            return Stream<String>.fromIterable([
              'event: message.delta\ndata: {"delta":"late"}\n\n',
              'data: [DONE]\n\n',
            ]);
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      final send = channel.sendText('stop me');
      await startRunStarted.future;
      channel.stopActiveTurn();
      releaseStartRun.complete();
      await send;

      expect(runEventsOpened, isFalse);
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'stop me',
        'Stopped.',
      ]);
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
      await expectLater(
        channel.respondToApproval(
          approvalId: 'appr_1',
          decision: HermesApprovalDecision.once,
        ),
        throwsStateError,
      );
    },
  );

  test(
    'stop during pending run submission ignores late submission failure',
    () async {
      final startRunStarted = Completer<void>();
      final releaseStartRun = Completer<void>();
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            expect(uri.path, '/v1/runs');
            if (!startRunStarted.isCompleted) startRunStarted.complete();
            await releaseStartRun.future;
            throw StateError('late run submit failed');
          },
          getStream: (uri, headers) => throw StateError('should not attach'),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      final send = channel.sendText('stop failing submit');
      await startRunStarted.future;
      channel.stopActiveTurn();
      releaseStartRun.complete();
      await send;

      expect(channel.state.errorMessage, isNull);
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'stop failing submit',
        'Stopped.',
      ]);
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    },
  );

  test('stale stopped run cleanup cannot clear a newer active run', () async {
    var nextRun = 1;
    final stops = <String>[];
    final streams = <String, _ManualStringStream>{};
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          if (uri.path == '/v1/runs') {
            final runId = 'run_${nextRun++}';
            return '{"object":"hermes.run","run":{"id":"$runId","session_id":"sess_1"}}';
          }
          if (uri.path.endsWith('/stop')) {
            stops.add(uri.path);
            return '{}';
          }
          throw StateError('unexpected POST $uri');
        },
        getStream: (uri, headers) {
          final runId = uri.pathSegments[2];
          return streams.putIfAbsent(runId, _ManualStringStream.new);
        },
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    final firstSend = channel.sendText('first');
    await pumpEventQueue();
    channel.stopActiveTurn();
    await pumpEventQueue();

    final secondSend = channel.sendText('second');
    await pumpEventQueue();
    channel.stopActiveTurn();
    await pumpEventQueue();

    await firstSend;
    await secondSend;
    expect(stops, ['/v1/runs/run_1/stop', '/v1/runs/run_2/stop']);
    expect(channel.state.activeMessages.map((turn) => turn.text), [
      'Hello',
      'first',
      'Stopped.',
      'second',
      'Stopped.',
    ]);
  });

  test('sendText rejects direct sends while run submission is pending', () async {
    final startRunStarted = Completer<void>();
    final releaseStartRun = Completer<void>();
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          expect(uri.path, '/v1/runs');
          if (!startRunStarted.isCompleted) startRunStarted.complete();
          await releaseStartRun.future;
          return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
        },
        getStream: (uri, headers) => const Stream<String>.empty(),
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    final firstSend = channel.sendText('first');
    await startRunStarted.future;

    await expectLater(channel.sendText('second'), throwsStateError);
    expect(channel.state.activeMessages.map((turn) => turn.text), [
      'Hello',
      'first',
      '',
    ]);

    releaseStartRun.complete();
    await firstSend;
  });

  test(
    'sendText marks local assistant failed when run event stream fails to open',
    () async {
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            expect(uri.path, '/v1/runs');
            return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
          },
          getStream: (uri, headers) => throw StateError('events offline'),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await expectLater(channel.sendText('open events'), throwsStateError);

      expect(
        channel.state.errorMessage,
        contains('Hermes run event stream failed to open'),
      );
      expect(channel.state.errorMessage, contains('events offline'));
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'open events',
        '',
      ]);
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    },
  );

  test(
    'sendText fails a run stream that closes before a terminal event',
    () async {
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            expect(uri.path, '/v1/runs');
            return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
          },
          getStream: (uri, headers) => Stream<String>.fromIterable(const [
            'event: message.delta\ndata: {"delta":"partial"}\n\n',
          ]),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('dropped run');

      expect(channel.state.errorMessage, contains('closed before a terminal'));
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'dropped run',
        'partial',
      ]);
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    },
  );

  test('sendText fails when a run stream emits an error event', () async {
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          expect(uri.path, '/v1/runs');
          return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
        },
        getStream: (uri, headers) => Stream<String>.fromIterable(const [
          'event: message.delta\ndata: {"delta":"partial"}\n\n',
          'event: error\ndata: {"error":{"code":"upstream","message":"token=secret-stream-error"}}\n\n',
        ]),
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.sendText('errored run');

    expect(
      channel.state.errorMessage,
      contains('Hermes stream reported an error'),
    );
    expect(channel.state.errorMessage, contains('upstream: token=[redacted]'));
    expect(channel.state.errorMessage, isNot(contains('secret-stream-error')));
    expect(channel.state.activeMessages.map((turn) => turn.text), [
      'Hello',
      'errored run',
      'partial',
    ]);
    expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
  });

  test('sendText recovers a closed run stream from server history', () async {
    var messagesRequests = 0;
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' =>
              (messagesRequests++ == 0)
                  ? _messagesFixture
                  : _reconciledMessagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          expect(uri.path, '/v1/runs');
          return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
        },
        getStream: (uri, headers) => Stream<String>.fromIterable(const [
          'event: message.delta\ndata: {"delta":"partial"}\n\n',
        ]),
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.sendText('dropped run');

    expect(messagesRequests, 2);
    expect(channel.state.errorMessage, isNull);
    expect(channel.state.activeMessages.map((turn) => turn.text), [
      'Hello',
      'Hi there',
    ]);
    expect(
      channel.state.activeMessages.last.status,
      HermesTurnStatus.completed,
    );
  });

  test(
    'sendText recovers a closed stream from advertised completed run status',
    () async {
      var messagesRequests = 0;
      var statusRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async => switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => () {
              messagesRequests += 1;
              return _messagesFixture;
            }(),
            '/v1/runs/run_1' => () {
              statusRequests += 1;
              return '{"run_id":"run_1","session_id":"sess_1","status":"completed","output":"Recovered directly","usage":{"input_tokens":3,"output_tokens":2,"total_tokens":5}}';
            }(),
            _ => throw StateError('unexpected GET $uri'),
          },
          post: (uri, headers, body) async =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
          getStream: (uri, headers) => Stream<String>.fromIterable(const [
            'event: message.delta\ndata: {"delta":"partial"}\n\n',
          ]),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('recover by status');

      expect(statusRequests, 1);
      expect(messagesRequests, 1);
      expect(channel.state.errorMessage, isNull);
      final assistant = channel.state.activeMessages.last;
      expect(assistant.text, 'Recovered directly');
      expect(assistant.status, HermesTurnStatus.completed);
      expect(assistant.usage?.totalTokens, 5);
    },
  );

  test('sendText never probes unadvertised run status during recovery', () async {
    var messagesRequests = 0;
    var statusRequests = 0;
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          if (uri.path == '/v1/runs/run_1') {
            statusRequests += 1;
            return '{"status":"completed"}';
          }
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsWithoutStopCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' =>
              (messagesRequests++ == 0)
                  ? _messagesFixture
                  : _reconciledMessagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async =>
            '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
        getStream: (uri, headers) => Stream<String>.fromIterable(const [
          'event: message.delta\ndata: {"delta":"partial"}\n\n',
        ]),
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.sendText('recover without probing');

    expect(statusRequests, 0);
    expect(messagesRequests, 2);
    expect(channel.state.errorMessage, isNull);
  });

  test(
    'sendText keeps a status-confirmed detached run unsafe after reconnect',
    () async {
      var messagesRequests = 0;
      var runSubmissions = 0;
      var statusRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async => switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => () {
              messagesRequests += 1;
              return _messagesFixture;
            }(),
            '/v1/runs/run_1' => () {
              statusRequests += 1;
              return '{"run_id":"run_1","session_id":"sess_1","status":"running"}';
            }(),
            _ => throw StateError('unexpected GET $uri'),
          },
          post: (uri, headers, body) async {
            runSubmissions += 1;
            return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
          },
          getStream: (uri, headers) => Stream<String>.fromIterable(const [
            'event: message.delta\ndata: {"delta":"partial"}\n\n',
          ]),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('do not duplicate');

      expect(messagesRequests, 1);
      expect(statusRequests, 1);
      expect(
        channel.state.errorMessage,
        'Hermes run is still active after its event stream closed. Reconnect before retrying.',
      );
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);

      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      await expectLater(channel.sendText('unsafe retry'), throwsStateError);

      expect(runSubmissions, 1);
      expect(statusRequests, 2);
      expect(messagesRequests, 2);
      expect(
        channel.state.errorMessage,
        'Hermes run is still active. Reconnect later before retrying.',
      );
    },
  );

  test('process recreation restores the detached-run duplicate guard', () async {
    final store = _MemoryDetachedRunStore();
    var runSubmissions = 0;
    var statusRequests = 0;
    HermesApiClient clientBuilder(HermesApiConfig config) => HermesApiClient(
      config: config,
      get: (uri, headers) async => switch (uri.path) {
        '/health' => '{"status":"ok"}',
        '/v1/capabilities' => _runsCapableCapabilitiesFixture,
        '/api/sessions' => _sessionsFixture,
        '/api/sessions/sess_1/messages' => _messagesFixture,
        '/v1/runs/run_1' => () {
          statusRequests += 1;
          return '{"run_id":"run_1","session_id":"sess_1","status":"running"}';
        }(),
        _ => throw StateError('unexpected GET $uri'),
      },
      post: (uri, headers, body) async {
        runSubmissions += 1;
        return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
      },
      getStream: (uri, headers) => Stream<String>.fromIterable(const [
        'event: message.delta\ndata: {"delta":"partial"}\n\n',
      ]),
    );

    final firstChannel = HermesApiChannel(
      clientBuilder: clientBuilder,
      detachedRunStore: store,
    );
    await firstChannel.connect(
      baseUrl:
          'http://user:secret@127.0.0.1:8642/path?api_key=must-not-persist',
    );
    await firstChannel.sendText('detached before recreation');
    expect(store.leases.single.runId, 'run_1');
    expect(store.leases.single.baseUrl, 'http://127.0.0.1:8642');
    firstChannel.dispose();

    final recreatedChannel = HermesApiChannel(
      clientBuilder: clientBuilder,
      detachedRunStore: store,
    );
    addTearDown(recreatedChannel.dispose);
    await recreatedChannel.connect(baseUrl: 'http://127.0.0.1:8642');
    await expectLater(
      recreatedChannel.sendText('must not duplicate'),
      throwsStateError,
    );

    expect(runSubmissions, 1);
    expect(statusRequests, 2);
    expect(
      recreatedChannel.state.errorMessage,
      'Hermes run is still active. Reconnect later before retrying.',
    );
  });

  test('active run lease is durable before its event stream finishes', () async {
    final store = _MemoryDetachedRunStore();
    final stream = _ManualStringStream();
    final submitted = Completer<void>();
    final channel = HermesApiChannel(
      detachedRunStore: store,
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async => switch (uri.path) {
          '/health' => '{"status":"ok"}',
          '/v1/capabilities' => _runsCapableCapabilitiesFixture,
          '/api/sessions' => _sessionsFixture,
          '/api/sessions/sess_1/messages' => _messagesFixture,
          _ => throw StateError('unexpected GET $uri'),
        },
        post: (uri, headers, body) async {
          if (!submitted.isCompleted) submitted.complete();
          return '{"object":"hermes.run","run":{"id":"run_live","session_id":"sess_1"}}';
        },
        getStream: (uri, headers) => stream,
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    unawaited(channel.sendText('survive process death'));
    await submitted.future;
    await Future<void>.delayed(Duration.zero);

    expect(store.leases.single.runId, 'run_live');
    expect(store.leases.single.sessionId, 'sess_1');
  });

  test(
    'process recreation reopens a non-default session with an active detached run',
    () async {
      final store = _MemoryDetachedRunStore()
        ..leases = [
          HermesDetachedRunLease(
            runId: 'run_detached',
            sessionId: 'sess_2',
            baseUrl: 'http://127.0.0.1:8642',
            createdAt: DateTime.now().toUtc(),
          ),
        ];
      var statusRequests = 0;
      final channel = HermesApiChannel(
        detachedRunStore: store,
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async => switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _twoSessionsFixture,
            '/api/sessions/sess_2/messages' => _messagesFixture,
            '/v1/runs/run_detached' => () {
              statusRequests += 1;
              return '{"run_id":"run_detached","session_id":"sess_2","status":"running"}';
            }(),
            _ => throw StateError('unexpected GET $uri'),
          },
        ),
      );
      addTearDown(channel.dispose);

      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      expect(statusRequests, 1);
      expect(channel.state.activeSessionId, 'sess_2');
      expect(
        channel.state.errorMessage,
        'Hermes run is still active. Reconnect later before retrying.',
      );
      await expectLater(
        channel.sendText('must not duplicate'),
        throwsStateError,
      );
    },
  );

  test(
    'reconnect releases a detached run missing after server restart',
    () async {
      final store = _MemoryDetachedRunStore()
        ..leases = [
          HermesDetachedRunLease(
            runId: 'run_gone',
            sessionId: 'sess_1',
            baseUrl: 'http://127.0.0.1:8642',
            createdAt: DateTime.now().toUtc(),
          ),
        ];
      final channel = HermesApiChannel(
        detachedRunStore: store,
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async => switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            '/v1/runs/run_gone' => throw StateError(
              'Hermes API returned HTTP 404',
            ),
            _ => throw StateError('unexpected GET $uri'),
          },
        ),
      );
      addTearDown(channel.dispose);

      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      expect(channel.state.errorMessage, isNull);
      expect(store.leases, isEmpty);
    },
  );

  test('reconnect keeps a detached run on transient status failure', () async {
    final store = _MemoryDetachedRunStore()
      ..leases = [
        HermesDetachedRunLease(
          runId: 'run_unknown',
          sessionId: 'sess_1',
          baseUrl: 'http://127.0.0.1:8642',
          createdAt: DateTime.now().toUtc(),
        ),
      ];
    final channel = HermesApiChannel(
      detachedRunStore: store,
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async => switch (uri.path) {
          '/health' => '{"status":"ok"}',
          '/v1/capabilities' => _runsCapableCapabilitiesFixture,
          '/api/sessions' => _sessionsFixture,
          '/api/sessions/sess_1/messages' => _messagesFixture,
          '/v1/runs/run_unknown' => throw StateError('network unavailable'),
          _ => throw StateError('unexpected GET $uri'),
        },
      ),
    );
    addTearDown(channel.dispose);

    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    expect(
      channel.state.errorMessage,
      'Hermes run is still active. Reconnect later before retrying.',
    );
    expect(store.leases.single.runId, 'run_unknown');
  });

  test('reconnect releases a detached run after terminal status', () async {
    var runSubmissions = 0;
    var runOneStatusRequests = 0;
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async => switch (uri.path) {
          '/health' => '{"status":"ok"}',
          '/v1/capabilities' => _runsCapableCapabilitiesFixture,
          '/api/sessions' => _sessionsFixture,
          '/api/sessions/sess_1/messages' => _messagesFixture,
          '/v1/runs/run_1' => () {
            runOneStatusRequests += 1;
            return runOneStatusRequests == 1
                ? '{"run_id":"run_1","session_id":"sess_1","status":"running"}'
                : '{"run_id":"run_1","session_id":"sess_1","status":"completed","output":"recovered"}';
          }(),
          '/v1/runs/run_2' =>
            '{"run_id":"run_2","session_id":"sess_1","status":"completed"}',
          _ => throw StateError('unexpected GET $uri'),
        },
        post: (uri, headers, body) async {
          runSubmissions += 1;
          final runId = 'run_$runSubmissions';
          return '{"object":"hermes.run","run":{"id":"$runId","session_id":"sess_1"}}';
        },
        getStream: (uri, headers) => uri.path.contains('run_1')
            ? Stream<String>.fromIterable(const [
                'event: message.delta\ndata: {"delta":"partial"}\n\n',
              ])
            : Stream<String>.fromIterable(const [
                'event: run.completed\ndata: {}\n\n',
              ]),
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    await channel.sendText('detached');

    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    expect(channel.state.errorMessage, isNull);
    await channel.sendText('safe next turn');

    expect(runOneStatusRequests, 2);
    expect(runSubmissions, 2);
  });

  test(
    'sendText does not recover a closed run stream from an old duplicate user turn',
    () async {
      var messagesRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ >= 0) ? _duplicateMessagesFixture : '',
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            expect(uri.path, '/v1/runs');
            return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
          },
          getStream: (uri, headers) => Stream<String>.fromIterable(const [
            'event: message.delta\ndata: {"delta":"partial"}\n\n',
          ]),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('Hello again');

      expect(messagesRequests, 2);
      expect(channel.state.errorMessage, contains('closed before a terminal'));
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'Hello again',
        'Old answer',
        'Hello again',
        'partial',
      ]);
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    },
  );

  test(
    'sendText does not recover a closed run stream from a later-turn assistant reply',
    () async {
      var messagesRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ == 0)
                    ? _messagesFixture
                    : _interleavedLaterReplyMessagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            expect(uri.path, '/v1/runs');
            return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
          },
          getStream: (uri, headers) => Stream<String>.fromIterable(const [
            'event: message.delta\ndata: {"delta":"partial"}\n\n',
          ]),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('closed stream');

      expect(messagesRequests, 2);
      expect(channel.state.errorMessage, contains('closed before a terminal'));
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'closed stream',
        'partial',
      ]);
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    },
  );

  test(
    'sendText keeps a dropped run stream failed when history has only old assistant replies',
    () async {
      var messagesRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ >= 0) ? _reconciledMessagesFixture : '',
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            expect(uri.path, '/v1/runs');
            return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
          },
          getStream: (uri, headers) async* {
            yield 'event: message.delta\ndata: {"delta":"partial"}\n\n';
            throw StateError('run events dropped');
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('dropped run');

      expect(messagesRequests, 2);
      expect(channel.state.errorMessage, contains('run events dropped'));
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'Hi there',
        'dropped run',
        'partial',
      ]);
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    },
  );

  test(
    'sendText does not recover a dropped run stream from a later-turn assistant reply',
    () async {
      var messagesRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ == 0)
                    ? _messagesFixture
                    : _interleavedLaterReplyMessagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            expect(uri.path, '/v1/runs');
            return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
          },
          getStream: (uri, headers) async* {
            yield 'event: message.delta\ndata: {"delta":"partial"}\n\n';
            throw StateError('run events dropped');
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('closed stream');

      expect(messagesRequests, 2);
      expect(channel.state.errorMessage, contains('run events dropped'));
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'closed stream',
        'partial',
      ]);
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    },
  );

  test('sendText recovers a dropped run stream from server history', () async {
    var messagesRequests = 0;
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' =>
              (messagesRequests++ == 0)
                  ? _messagesFixture
                  : _reconciledMessagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          expect(uri.path, '/v1/runs');
          return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
        },
        getStream: (uri, headers) async* {
          yield 'event: message.delta\ndata: {"delta":"partial"}\n\n';
          throw StateError('run events dropped');
        },
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.sendText('dropped run');

    expect(messagesRequests, 2);
    expect(channel.state.errorMessage, isNull);
    expect(channel.state.activeMessages.map((turn) => turn.text), [
      'Hello',
      'Hi there',
    ]);
    expect(
      channel.state.activeMessages.last.status,
      HermesTurnStatus.completed,
    );
  });

  test(
    'sendText marks the local assistant turn failed when run submission is rejected',
    () async {
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            throw StateError('401 unauthorized');
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await expectLater(channel.sendText('needs auth'), throwsStateError);

      final turns = channel.state.activeMessages;
      expect(turns.map((t) => t.text), ['Hello', 'needs auth', '']);
      expect(turns.last.author, HermesTurnAuthor.assistant);
      expect(turns.last.status, HermesTurnStatus.failed);
      expect(channel.state.errorMessage, contains('401 unauthorized'));
    },
  );

  test(
    'sendText redacts bearer and secret values from stored errors',
    () async {
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async => throw StateError(
            '403 forbidden for Bearer secret-stream-key api_key=secret-api-key',
          ),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await expectLater(channel.sendText('needs auth'), throwsStateError);

      expect(channel.state.errorMessage, contains('403 forbidden'));
      expect(channel.state.errorMessage, contains('Bearer [redacted]'));
      expect(channel.state.errorMessage, isNot(contains('secret-stream-key')));
      expect(channel.state.errorMessage, isNot(contains('secret-api-key')));
    },
  );
}
