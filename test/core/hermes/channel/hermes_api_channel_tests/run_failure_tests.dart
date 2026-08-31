part of '../hermes_api_channel_test.dart';

void _hermesApiChannelRunFailureTests() {
  test('sendText rejects a started run owned by another session', () async {
    final store = _MemoryDetachedRunStore();
    var streamOpened = false;
    var stopCalled = false;
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
          if (uri.path == '/v1/runs') {
            return '{"object":"hermes.run","run":{"id":"run_wrong","session_id":"sess_other"}}';
          }
          if (uri.path == '/v1/runs/run_wrong/stop') {
            stopCalled = true;
            return '{}';
          }
          throw StateError('unexpected POST $uri');
        },
        getStream: (uri, headers) {
          streamOpened = true;
          return const Stream.empty();
        },
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await expectLater(channel.sendText('wrong owner'), throwsStateError);

    expect(stopCalled, isTrue);
    expect(streamOpened, isFalse);
    expect(store.leases, isEmpty);
    expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
  });

  test('failed mismatched-run rollback retains exact server ownership', () async {
    final store = _MemoryDetachedRunStore();
    var streamOpened = false;
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
          if (uri.path == '/v1/runs') {
            return '{"object":"hermes.run","run":{"id":"run_wrong","session_id":"sess_other"}}';
          }
          if (uri.path == '/v1/runs/run_wrong/stop') {
            throw StateError('stop failed');
          }
          throw StateError('unexpected POST $uri');
        },
        getStream: (uri, headers) {
          streamOpened = true;
          return const Stream.empty();
        },
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await expectLater(channel.sendText('wrong owner'), throwsStateError);

    expect(streamOpened, isFalse);
    expect(store.leases, hasLength(1));
    expect(store.leases.single.runId, 'run_wrong');
    expect(store.leases.single.sessionId, 'sess_other');
  });

  test(
    'mismatched run without Stop support retains exact server ownership',
    () async {
      final store = _MemoryDetachedRunStore();
      final postPaths = <String>[];
      var streamOpened = false;
      final channel = HermesApiChannel(
        detachedRunStore: store,
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async => switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsWithoutStopCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          },
          post: (uri, headers, body) async {
            postPaths.add(uri.path);
            return '{"object":"hermes.run","run":{"id":"run_wrong","session_id":"sess_other"}}';
          },
          getStream: (uri, headers) {
            streamOpened = true;
            return const Stream.empty();
          },
        ),
      );
      addTearDown(channel.dispose);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await expectLater(channel.sendText('wrong owner'), throwsStateError);

      expect(postPaths, ['/v1/runs']);
      expect(streamOpened, isFalse);
      expect(store.leases.single.runId, 'run_wrong');
      expect(store.leases.single.sessionId, 'sess_other');
    },
  );

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

  test('sendText reconciles a silent run stream from failed run status', () async {
    final stream = _ManualStringStream();
    var statusRequests = 0;
    final channel = HermesApiChannel(
      streamIdleTimeout: const Duration(minutes: 1),
      runStatusReconcileInterval: const Duration(milliseconds: 10),
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async => switch (uri.path) {
          '/health' => '{"status":"ok"}',
          '/v1/capabilities' => _runsCapableCapabilitiesFixture,
          '/api/sessions' => _sessionsFixture,
          '/api/sessions/sess_1/messages' => _messagesFixture,
          '/v1/runs/run_1' => () {
            statusRequests += 1;
            return '{"run_id":"run_1","session_id":"sess_1","status":"failed","error":"provider rejected api_key=secret-value"}';
          }(),
          _ => throw StateError('unexpected GET $uri'),
        },
        post: (uri, headers, body) async =>
            '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
        getStream: (uri, headers) => stream,
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await expectLater(
      channel.sendText('silent failed run').timeout(const Duration(seconds: 1)),
      completes,
    );

    expect(statusRequests, 1);
    expect(
      channel.state.errorMessage,
      'Hermes run failed: provider rejected api_key=[redacted]',
    );
    expect(channel.state.errorMessage, isNot(contains('secret-value')));
    expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
  });

  test(
    'sendText fails an empty terminal run after status was still running',
    () async {
      final stream = _ManualStringStream();
      final statusRead = Completer<void>();
      final channel = HermesApiChannel(
        streamIdleTimeout: const Duration(minutes: 1),
        runStatusReconcileInterval: const Duration(milliseconds: 10),
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async => switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            '/v1/runs/run_1' => () {
              if (!statusRead.isCompleted) statusRead.complete();
              return '{"run_id":"run_1","session_id":"sess_1","status":"running"}';
            }(),
            _ => throw StateError('unexpected GET $uri'),
          },
          post: (uri, headers, body) async =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
          getStream: (uri, headers) => stream,
        ),
      );
      addTearDown(channel.dispose);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      final send = channel.sendText('empty terminal run');
      await statusRead.future;
      stream.emit('event: run.completed\ndata: {}\n\n');
      await send;

      expect(
        channel.state.errorMessage,
        'Hermes finished without an assistant reply.',
      );
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

  test('mismatched primary recovery status remains fail-closed', () async {
    final store = _MemoryDetachedRunStore();
    var runSubmissions = 0;
    final channel = HermesApiChannel(
      detachedRunStore: store,
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async => switch (uri.path) {
          '/health' => '{"status":"ok"}',
          '/v1/capabilities' => _runsCapableCapabilitiesFixture,
          '/api/sessions' => _sessionsFixture,
          '/api/sessions/sess_1/messages' => _messagesFixture,
          '/v1/runs/run_1' =>
            '{"run_id":"run_other","session_id":"sess_1","status":"completed","output":"wrong output","usage":{"total_tokens":99}}',
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
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.sendText('wrong status owner');

    expect(store.leases.single.runId, 'run_1');
    expect(channel.state.hasUnreconciledRun, isTrue);
    expect(channel.state.activeMessages.last.text, 'partial');
    expect(channel.state.activeMessages.last.usage, isNull);
    await expectLater(channel.sendText('must not duplicate'), throwsStateError);
    expect(runSubmissions, 1);
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
      expect(channel.state.hasUnreconciledRun, isTrue);

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
      var messagesRequests = 0;
      final stream = _ManualStringStream();
      final streamAttached = Completer<void>();
      final channel = HermesApiChannel(
        detachedRunStore: store,
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async => switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _twoSessionsFixture,
            '/api/sessions/sess_2/messages' =>
              messagesRequests++ == 0
                  ? _messagesFixture
                  : _reconciledMessagesFixture,
            '/v1/runs/run_detached' => () {
              statusRequests += 1;
              return '{"run_id":"run_detached","session_id":"sess_2","status":"running"}';
            }(),
            _ => throw StateError('unexpected GET $uri'),
          },
          getStream: (uri, headers) {
            expect(uri.path, '/v1/runs/run_detached/events');
            if (!streamAttached.isCompleted) streamAttached.complete();
            return stream;
          },
        ),
      );
      addTearDown(channel.dispose);

      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      await streamAttached.future;
      await pumpEventQueue();

      expect(statusRequests, 1);
      expect(channel.state.activeSessionId, 'sess_2');
      expect(channel.state.errorMessage, isNull);
      expect(channel.state.hasUnreconciledRun, isTrue);
      expect(
        channel.state.activeMessages.last.status,
        HermesTurnStatus.streaming,
      );

      stream.emit(
        'event: tool.started\ndata: {"run_id":"run_detached","session_id":"sess_2","tool":"search","tool_call_id":"call-1","preview":"Looking up results"}\n\n',
      );
      HermesChatTurn? toolTurn;
      final toolDeadline = DateTime.now().add(const Duration(seconds: 1));
      while (toolTurn == null && DateTime.now().isBefore(toolDeadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        toolTurn = channel.state.activeMessages
            .where((turn) => turn.kind == HermesTurnKind.toolCall)
            .firstOrNull;
      }
      expect(toolTurn, isNotNull);
      expect(toolTurn!.toolCall?.name, 'search');
      expect(toolTurn.toolCall?.status, 'running');

      await expectLater(
        channel.sendText('must not duplicate'),
        throwsStateError,
      );

      stream.emit(
        'event: message.delta\ndata: {"run_id":"wrong","delta":"wrong"}\n\n'
        'event: run.completed\ndata: {"run_id":"wrong","session_id":"sess_2"}\n\n',
      );
      await pumpEventQueue();

      expect(store.leases.single.runId, 'run_detached');
      expect(channel.state.hasUnreconciledRun, isTrue);
      expect(channel.state.activeMessages.last.text, isNot(contains('wrong')));

      stream.emit(
        'event: message.delta\ndata: {"run_id":"run_detached","session_id":"sess_2","delta":"reattached"}\n\n'
        'event: run.completed\ndata: {"run_id":"run_detached","session_id":"sess_2"}\n\n',
      );
      await pumpEventQueue();

      expect(store.leases, isEmpty);
      expect(channel.state.hasUnreconciledRun, isFalse);
      expect(channel.state.errorMessage, isNull);
      expect(
        channel.state.activeMessages.last.status,
        HermesTurnStatus.completed,
      );
    },
  );

  test('reattached done marker keeps an active run fail-closed', () async {
    final store = _MemoryDetachedRunStore()
      ..leases = [
        HermesDetachedRunLease(
          runId: 'run_detached',
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
          '/v1/runs/run_detached' =>
            '{"run_id":"run_detached","session_id":"sess_1","status":"running"}',
          _ => throw StateError('unexpected GET $uri'),
        },
        getStream: (uri, headers) =>
            Stream<String>.fromIterable(const ['data: [DONE]\n\n']),
      ),
    );
    addTearDown(channel.dispose);

    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    await pumpEventQueue();

    expect(store.leases.single.runId, 'run_detached');
    expect(channel.state.hasUnreconciledRun, isTrue);
    await expectLater(channel.sendText('must not duplicate'), throwsStateError);
  });

  test(
    'session selection scopes a recovered run guard without detaching it',
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
      final stream = _ManualStringStream();
      final channel = HermesApiChannel(
        detachedRunStore: store,
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async => switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _twoSessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            '/api/sessions/sess_2/messages' => _messagesFixture,
            '/v1/runs/run_detached' =>
              '{"run_id":"run_detached","session_id":"sess_2","status":"running"}',
            _ => throw StateError('unexpected GET $uri'),
          },
          getStream: (uri, headers) => stream,
        ),
      );
      addTearDown(channel.dispose);

      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      await pumpEventQueue();
      expect(channel.state.activeSessionId, 'sess_2');
      expect(channel.state.hasUnreconciledRun, isTrue);

      await channel.selectSession('sess_1');
      expect(channel.state.hasUnreconciledRun, isFalse);
      expect(stream.cancelCount, 0);

      await channel.selectSession('sess_2');
      expect(channel.state.hasUnreconciledRun, isTrue);
      expect(stream.cancelCount, 0);

      stream.emit(
        'event: run.completed\ndata: {"run_id":"run_detached","session_id":"sess_2"}\n\n',
      );
      await pumpEventQueue();
      expect(store.leases, isEmpty);
      expect(channel.state.hasUnreconciledRun, isFalse);
    },
  );

  test('reattached generic error preserves exact stop ownership', () async {
    final store = _MemoryDetachedRunStore()
      ..leases = [
        HermesDetachedRunLease(
          runId: 'run_detached',
          sessionId: 'sess_1',
          baseUrl: 'http://127.0.0.1:8642',
          createdAt: DateTime.now().toUtc(),
        ),
      ];
    final stopPaths = <String>[];
    final channel = HermesApiChannel(
      detachedRunStore: store,
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async => switch (uri.path) {
          '/health' => '{"status":"ok"}',
          '/v1/capabilities' => _runsCapableCapabilitiesFixture,
          '/api/sessions' => _sessionsFixture,
          '/api/sessions/sess_1/messages' => _messagesFixture,
          '/v1/runs/run_detached' =>
            '{"run_id":"run_detached","session_id":"sess_1","status":"running"}',
          _ => throw StateError('unexpected GET $uri'),
        },
        post: (uri, headers, body) async {
          stopPaths.add(uri.path);
          return '{}';
        },
        getStream: (uri, headers) => Stream<String>.fromIterable(const [
          'event: error\ndata: {"run_id":"run_detached","session_id":"sess_1","message":"transport failed"}\n\n',
        ]),
      ),
    );
    addTearDown(channel.dispose);

    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    await pumpEventQueue();

    expect(store.leases.single.runId, 'run_detached');
    expect(channel.state.hasUnreconciledRun, isTrue);
    channel.stopActiveTurn();
    await pumpEventQueue();

    expect(stopPaths, ['/v1/runs/run_detached/stop']);
    expect(store.leases, isEmpty);
  });

  test('reattachment transport close preserves exact stop ownership', () async {
    final store = _MemoryDetachedRunStore()
      ..leases = [
        HermesDetachedRunLease(
          runId: 'run_detached',
          sessionId: 'sess_1',
          baseUrl: 'http://127.0.0.1:8642',
          createdAt: DateTime.now().toUtc(),
        ),
      ];
    final stopPaths = <String>[];
    final channel = HermesApiChannel(
      detachedRunStore: store,
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async => switch (uri.path) {
          '/health' => '{"status":"ok"}',
          '/v1/capabilities' => _runsCapableCapabilitiesFixture,
          '/api/sessions' => _sessionsFixture,
          '/api/sessions/sess_1/messages' => _messagesFixture,
          '/v1/runs/run_detached' =>
            '{"run_id":"run_detached","session_id":"sess_1","status":"running"}',
          _ => throw StateError('unexpected GET $uri'),
        },
        post: (uri, headers, body) async {
          stopPaths.add(uri.path);
          return '{}';
        },
        getStream: (uri, headers) => Stream<String>.empty(),
      ),
    );
    addTearDown(channel.dispose);

    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    await pumpEventQueue();
    channel.stopActiveTurn();
    await pumpEventQueue();

    expect(stopPaths, ['/v1/runs/run_detached/stop']);
    expect(store.leases, isEmpty);
    expect(channel.state.hasUnreconciledRun, isFalse);
  });

  test(
    'reattachment reconciles terminal status after the event stream closes',
    () async {
      final store = _MemoryDetachedRunStore()
        ..leases = [
          HermesDetachedRunLease(
            runId: 'run_detached',
            sessionId: 'sess_1',
            baseUrl: 'http://127.0.0.1:8642',
            createdAt: DateTime.now().toUtc(),
          ),
        ];
      var statusRequests = 0;
      final channel = HermesApiChannel(
        detachedRunStore: store,
        runStatusReconcileInterval: const Duration(milliseconds: 1),
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async => switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _reconciledMessagesFixture,
            '/v1/runs/run_detached' =>
              ++statusRequests == 1
                  ? '{"run_id":"run_detached","session_id":"sess_1","status":"running"}'
                  : '{"run_id":"run_detached","session_id":"sess_1","status":"completed","output":"recovered"}',
            _ => throw StateError('unexpected GET $uri'),
          },
          getStream: (uri, headers) => Stream<String>.empty(),
        ),
      );
      addTearDown(channel.dispose);

      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      final deadline = DateTime.now().add(const Duration(seconds: 1));
      while (statusRequests < 2 && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }

      expect(statusRequests, greaterThanOrEqualTo(2));
      expect(store.leases, isEmpty);
      expect(channel.state.hasUnreconciledRun, isFalse);
      expect(channel.state.errorMessage, isNull);
      expect(
        channel.state.activeMessages.last.status,
        HermesTurnStatus.completed,
      );
    },
  );

  test(
    'delayed stop completion cannot clear reconnected run ownership',
    () async {
      final store = _MemoryDetachedRunStore();
      final stopStarted = Completer<void>();
      final releaseStop = Completer<void>();
      final firstStream = _ManualStringStream();
      final secondStream = _ManualStringStream();
      var clientNumber = 0;
      final channel = HermesApiChannel(
        detachedRunStore: store,
        clientBuilder: (config) {
          final currentClient = ++clientNumber;
          return HermesApiClient(
            config: config,
            get: (uri, headers) async => switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              '/v1/runs/run_1' =>
                '{"run_id":"run_1","session_id":"sess_1","status":"running"}',
              _ => throw StateError('unexpected GET $uri'),
            },
            post: (uri, headers, body) async {
              if (uri.path == '/v1/runs') {
                return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
              }
              if (uri.path == '/v1/runs/run_1/stop') {
                if (!stopStarted.isCompleted) stopStarted.complete();
                await releaseStop.future;
                return '{}';
              }
              throw StateError('unexpected POST $uri');
            },
            getStream: (uri, headers) =>
                currentClient == 1 ? firstStream : secondStream,
          );
        },
      );
      addTearDown(channel.dispose);

      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      unawaited(channel.sendText('first lifecycle'));
      await pumpEventQueue();
      channel.stopActiveTurn();
      await stopStarted.future;

      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      await pumpEventQueue();
      expect(channel.state.hasUnreconciledRun, isTrue);
      expect(store.leases.single.runId, 'run_1');

      releaseStop.complete();
      await pumpEventQueue();

      expect(channel.state.hasUnreconciledRun, isTrue);
      expect(store.leases.single.runId, 'run_1');
      await expectLater(
        channel.sendText('must not duplicate'),
        throwsStateError,
      );
    },
  );

  test('terminal status releases only the exact endpoint run tuple', () async {
    final store = _MemoryDetachedRunStore()
      ..leases = [
        HermesDetachedRunLease(
          runId: 'run_shared',
          sessionId: 'sess_1',
          baseUrl: 'http://127.0.0.1:8642',
          createdAt: DateTime.now().toUtc(),
        ),
        HermesDetachedRunLease(
          runId: 'run_shared',
          sessionId: 'sess_1',
          baseUrl: 'http://127.0.0.1:8643',
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
          '/v1/runs/run_shared' =>
            '{"run_id":"run_shared","session_id":"sess_1","status":"completed"}',
          _ => throw StateError('unexpected GET $uri'),
        },
      ),
    );
    addTearDown(channel.dispose);

    await channel.connect(baseUrl: 'http://127.0.0.1:8643');

    expect(store.leases, hasLength(1));
    expect(store.leases.single.baseUrl, 'http://127.0.0.1:8642');
    expect(store.leases.single.runId, 'run_shared');
  });

  test('concurrent reconnects await one detached lease load', () async {
    final store = _BlockingDetachedRunStore(blockLoad: true)
      ..leases = [
        HermesDetachedRunLease(
          runId: 'run_loaded',
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
          '/v1/runs/run_loaded' => throw StateError('network unavailable'),
          _ => throw StateError('unexpected GET $uri'),
        },
      ),
    );
    addTearDown(channel.dispose);

    final firstConnect = channel.connect(baseUrl: 'http://127.0.0.1:8642');
    while (store.loadCalls < 1) {
      await pumpEventQueue();
    }
    var secondCompleted = false;
    final secondConnect = channel
        .connect(baseUrl: 'http://127.0.0.1:8642')
        .whenComplete(() => secondCompleted = true);
    await pumpEventQueue();

    expect(store.loadCalls, 1);
    expect(secondCompleted, isFalse);
    store.completeLoad();
    await Future.wait([firstConnect, secondConnect]);
    expect(channel.state.hasUnreconciledRun, isTrue);
    expect(
      channel.state.errorMessage,
      'Hermes run is still active. Reconnect later before retrying.',
    );
  });

  test('detached lease saves serialize without losing concurrent runs', () async {
    final store = _BlockingDetachedRunStore();
    final streams = <String, _ManualStringStream>{};
    var runCount = 0;
    final channel = HermesApiChannel(
      detachedRunStore: store,
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async => switch (uri.path) {
          '/health' => '{"status":"ok"}',
          '/v1/capabilities' => _runsCapableCapabilitiesFixture,
          '/api/sessions' => _twoSessionsFixture,
          '/api/sessions/sess_1/messages' => _messagesFixture,
          '/api/sessions/sess_2/messages' => _messagesFixture,
          _ => throw StateError('unexpected GET $uri'),
        },
        post: (uri, headers, body) async {
          runCount += 1;
          final sessionId = body.contains('sess_2') ? 'sess_2' : 'sess_1';
          return '{"object":"hermes.run","run":{"id":"run_$runCount","session_id":"$sessionId"}}';
        },
        getStream: (uri, headers) =>
            streams.putIfAbsent(uri.path, _ManualStringStream.new),
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    final firstSend = channel.sendText('first');
    while (store.saveCalls < 1) {
      await pumpEventQueue();
    }
    await channel.selectSession('sess_2');
    final secondSend = channel.sendText('second');
    await pumpEventQueue();

    expect(store.saveCalls, 1);
    store.completeSave(0);
    while (store.saveCalls < 2) {
      await pumpEventQueue();
    }
    expect(store.saveSnapshots[1], hasLength(2));
    store.completeSave(1);
    await pumpEventQueue();
    expect(
      store.leases.map((lease) => lease.runId),
      containsAll(['run_1', 'run_2']),
    );

    await channel.disconnect();
    await Future.wait([firstSend, secondSend]);
  });

  test('successor load waits for predecessor detached save', () async {
    final backing = _BlockingDetachedRunStore();
    const coordinationKey = 'shared-detached-store';
    final predecessorStore = _DetachedRunStoreView(
      backing: backing,
      key: coordinationKey,
    );
    final successorStore = _DetachedRunStoreView(
      backing: backing,
      key: coordinationKey,
    );
    HermesApiClient buildClient(HermesApiConfig config) => HermesApiClient(
      config: config,
      get: (uri, headers) async => switch (uri.path) {
        '/health' => '{"status":"ok"}',
        '/v1/capabilities' => _runsCapableCapabilitiesFixture,
        '/api/sessions' => _sessionsFixture,
        '/api/sessions/sess_1/messages' => _messagesFixture,
        '/v1/runs/run_predecessor' => throw StateError('network unavailable'),
        _ => throw StateError('unexpected GET $uri'),
      },
      post: (uri, headers, body) async =>
          '{"object":"hermes.run","run":{"id":"run_predecessor","session_id":"sess_1"}}',
      getStream: (uri, headers) => _ManualStringStream(),
    );
    final predecessor = HermesApiChannel(
      detachedRunStore: predecessorStore,
      clientBuilder: buildClient,
    );
    final successor = HermesApiChannel(
      detachedRunStore: successorStore,
      clientBuilder: buildClient,
    );
    addTearDown(successor.dispose);
    await predecessor.connect(baseUrl: 'http://127.0.0.1:8642');

    final send = predecessor.sendText('start predecessor');
    while (backing.saveCalls < 1) {
      await pumpEventQueue();
    }
    predecessor.dispose();
    var successorConnected = false;
    final connect = successor
        .connect(baseUrl: 'http://127.0.0.1:8642')
        .whenComplete(() => successorConnected = true);
    await pumpEventQueue();

    expect(successorConnected, isFalse);
    expect(backing.loadCalls, 2);
    backing.completeSave(0);
    await connect;
    expect(backing.loadCalls, 3);
    expect(successor.state.hasUnreconciledRun, isTrue);
    expect(
      successor.state.errorMessage,
      'Hermes run is still active. Reconnect later before retrying.',
    );
    await send;
  });

  test('live channel saves merge leases from shared backing state', () async {
    final backing = _MemoryDetachedRunStore();
    const coordinationKey = 'shared-live-detached-store';
    HermesApiChannel buildChannel(
      String runId,
      HermesDetachedRunStore store,
    ) => HermesApiChannel(
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
        post: (uri, headers, body) async =>
            '{"object":"hermes.run","run":{"id":"$runId","session_id":"sess_1"}}',
        getStream: (uri, headers) => _ManualStringStream(),
      ),
    );
    final first = buildChannel(
      'run_first',
      _DetachedRunStoreView(backing: backing, key: coordinationKey),
    );
    final second = buildChannel(
      'run_second',
      _DetachedRunStoreView(backing: backing, key: coordinationKey),
    );
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await first.connect(baseUrl: 'http://127.0.0.1:8642');
    await second.connect(baseUrl: 'http://127.0.0.1:8642');

    final firstSend = first.sendText('first');
    while (backing.leases.every((lease) => lease.runId != 'run_first')) {
      await pumpEventQueue();
    }
    final secondSend = second.sendText('second');
    while (backing.leases.every((lease) => lease.runId != 'run_second')) {
      await pumpEventQueue();
    }

    expect(
      backing.leases.map((lease) => lease.runId),
      containsAll(['run_first', 'run_second']),
    );
    await first.disconnect();
    await second.disconnect();
    await Future.wait([firstSend, secondSend]);
  });

  test('detached store load failure blocks run submission', () async {
    final store = _ThrowingLoadDetachedRunStore();
    var postCalls = 0;
    var streamCalls = 0;
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
          postCalls += 1;
          return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
        },
        getStream: (uri, headers) {
          streamCalls += 1;
          return const Stream.empty();
        },
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await expectLater(channel.sendText('must stay local'), throwsStateError);

    expect(postCalls, 0);
    expect(streamCalls, 0);
    expect(store.saveCalls, 0);
    expect(
      channel.state.errorMessage,
      'Wing could not load durable Hermes run recovery state. Reconnect before sending.',
    );

    store.failLoad = false;
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    final recoveredSend = channel.sendText('safe after reconnect');
    while (store.saveCalls < 1) {
      await pumpEventQueue();
    }
    expect(postCalls, 1);
    expect(streamCalls, 1);
    await channel.disconnect();
    await recoveredSend;
  });

  test('full detached ownership store blocks submission before POST', () async {
    final store = _MemoryDetachedRunStore()
      ..leases = List.generate(
        16,
        (index) => HermesDetachedRunLease(
          runId: 'existing_$index',
          sessionId: 'other_$index',
          baseUrl: 'http://127.0.0.1:8642',
          profileId: null,
          createdAt: DateTime.utc(2099, 1, index + 1),
        ),
      );
    var postCalls = 0;
    var streamCalls = 0;
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
          postCalls += 1;
          return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
        },
        getStream: (uri, headers) {
          streamCalls += 1;
          return const Stream.empty();
        },
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await expectLater(channel.sendText('must not start'), throwsStateError);

    expect(postCalls, 0);
    expect(streamCalls, 0);
    expect(store.leases, hasLength(16));
    expect(store.leases.map((lease) => lease.runId), isNot(contains('run_1')));
  });

  test('shared capacity serializes admission across live channels', () async {
    final backing = _MemoryDetachedRunStore()
      ..leases = List.generate(
        15,
        (index) => HermesDetachedRunLease(
          runId: 'existing_$index',
          sessionId: 'other_$index',
          baseUrl: 'http://127.0.0.1:8642',
          profileId: null,
          createdAt: DateTime.utc(2099, 1, index + 1),
        ),
      );
    final key = Object();
    var postCalls = 0;
    var streamCalls = 0;
    HermesApiChannel buildChannel() => HermesApiChannel(
      detachedRunStore: _DetachedRunStoreView(backing: backing, key: key),
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
          if (uri.path.endsWith('/stop')) return '{}';
          postCalls += 1;
          return '{"object":"hermes.run","run":{"id":"run_$postCalls","session_id":"sess_1"}}';
        },
        getStream: (uri, headers) {
          streamCalls += 1;
          return const Stream.empty();
        },
      ),
    );
    final first = buildChannel();
    final second = buildChannel();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await Future.wait([
      first.connect(baseUrl: 'http://127.0.0.1:8642'),
      second.connect(baseUrl: 'http://127.0.0.1:8642'),
    ]);

    await Future.wait([
      first.sendText('first').catchError((_) {}),
      second.sendText('second').catchError((_) {}),
    ]);

    expect(postCalls, 1);
    expect(streamCalls, 1);
    expect(backing.leases, hasLength(16));
    expect(backing.leases.map((lease) => lease.runId), contains('run_1'));
  });

  test(
    'disconnect after accepted run still rolls back failed admission',
    () async {
      final store = _BlockingFailSaveDetachedRunStore();
      var stopCalls = 0;
      var streamOpened = false;
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
            if (uri.path == '/v1/runs/run_1/stop') {
              stopCalls += 1;
              return '{}';
            }
            return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
          },
          getStream: (uri, headers) {
            streamOpened = true;
            return const Stream.empty();
          },
        ),
      );
      addTearDown(channel.dispose);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      final send = channel.sendText('race');
      await store.saveStarted.future;
      await channel.disconnect();
      store.releaseSave.complete();
      await send;
      for (var index = 0; index < 20; index += 1) {
        await pumpEventQueue();
      }

      expect(stopCalls, 1);
      expect(streamOpened, isFalse);
      expect(store.leases, isEmpty);
    },
  );

  test('initial detached save failure stops run without opening SSE', () async {
    final store = _FailFirstDetachedRunStore();
    var streamOpened = false;
    var stoppedRunId = '';
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
          if (uri.path == '/v1/runs/run_1/stop') {
            stoppedRunId = 'run_1';
            return '{}';
          }
          return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
        },
        getStream: (uri, headers) {
          streamOpened = true;
          return const Stream.empty();
        },
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await expectLater(channel.sendText('first'), throwsStateError);

    expect(streamOpened, isFalse);
    expect(stoppedRunId, 'run_1');
    expect(store.saveCalls, 2);
    expect(channel.state.hasUnreconciledRun, isFalse);
    expect(
      channel.state.errorMessage,
      'Hermes run was stopped because Wing could not persist its recovery lease.',
    );
    expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
  });

  test(
    'successful rollback remains authoritative when cleanup save fails',
    () async {
      final store = _FailFirstDetachedRunStore(failures: 2);
      var stoppedRunId = '';
      var streamOpened = false;
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
            if (uri.path == '/v1/runs/run_1/stop') {
              stoppedRunId = 'run_1';
              return '{}';
            }
            return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
          },
          getStream: (uri, headers) {
            streamOpened = true;
            return const Stream.empty();
          },
        ),
      );
      addTearDown(channel.dispose);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await expectLater(channel.sendText('first'), throwsStateError);

      expect(stoppedRunId, 'run_1');
      expect(streamOpened, isFalse);
      expect(store.saveCalls, 2);
      expect(channel.state.hasUnreconciledRun, isFalse);
      expect(
        channel.state.errorMessage,
        'Hermes run was stopped because Wing could not persist its recovery lease.',
      );
    },
  );

  test('failed rollback keeps detached run guarded', () async {
    final store = _FailFirstDetachedRunStore(failures: 2);
    var streamOpened = false;
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
          if (uri.path == '/v1/runs/run_1/stop') {
            throw StateError('stop failed');
          }
          return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
        },
        getStream: (uri, headers) {
          streamOpened = true;
          return const Stream.empty();
        },
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await expectLater(channel.sendText('first'), throwsStateError);

    expect(streamOpened, isFalse);
    expect(store.saveCalls, 1);
    expect(channel.state.hasUnreconciledRun, isTrue);
    expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    await expectLater(channel.sendText('must not duplicate'), throwsStateError);
  });

  test('failed detached save does not poison a later retry', () async {
    final store = _FailFirstDetachedRunStore();
    var runCount = 0;
    final channel = HermesApiChannel(
      detachedRunStore: store,
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async => switch (uri.path) {
          '/health' => '{"status":"ok"}',
          '/v1/capabilities' => _runsCapableCapabilitiesFixture,
          '/api/sessions' => _twoSessionsFixture,
          '/api/sessions/sess_1/messages' => _messagesFixture,
          '/api/sessions/sess_2/messages' => _messagesFixture,
          _ => throw StateError('unexpected GET $uri'),
        },
        post: (uri, headers, body) async {
          if (uri.path.endsWith('/stop')) return '{}';
          runCount += 1;
          final sessionId = body.contains('sess_2') ? 'sess_2' : 'sess_1';
          return '{"object":"hermes.run","run":{"id":"run_$runCount","session_id":"$sessionId"}}';
        },
        getStream: (uri, headers) => _ManualStringStream(),
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await expectLater(channel.sendText('first'), throwsStateError);
    await channel.selectSession('sess_2');
    final secondSend = channel.sendText('second');
    while (store.saveCalls < 3) {
      await pumpEventQueue();
    }

    expect(store.leases.map((lease) => lease.runId), ['run_2']);
    await channel.disconnect();
    await secondSend;
  });

  test('successful Stop cleans durable ownership after disconnect', () async {
    final store = _MemoryDetachedRunStore();
    final stream = _ManualStringStream();
    final stopStarted = Completer<void>();
    final releaseStop = Completer<void>();
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
          if (uri.path == '/v1/runs/run_1/stop') {
            stopStarted.complete();
            await releaseStop.future;
            return '{}';
          }
          return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
        },
        getStream: (uri, headers) => stream,
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    final send = channel.sendText('start');
    while (store.leases.isEmpty) {
      await pumpEventQueue();
    }

    channel.stopActiveTurn();
    await stopStarted.future;
    await channel.disconnect();
    releaseStop.complete();
    for (var index = 0; index < 20; index += 1) {
      await pumpEventQueue();
    }

    expect(store.leases, isEmpty);
    await send;
  });

  test('normal stop stays authoritative when cleanup save fails', () async {
    final store = _FailingSaveNumberDetachedRunStore(2);
    final stream = _ManualStringStream();
    var stopCalls = 0;
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
          if (uri.path == '/v1/runs/run_1/stop') {
            stopCalls += 1;
            return '{}';
          }
          return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
        },
        getStream: (uri, headers) => stream,
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    final send = channel.sendText('start');
    while (store.saveCalls < 1) {
      await pumpEventQueue();
    }

    channel.stopActiveTurn();
    while (stopCalls < 1 || store.saveCalls < 2) {
      await pumpEventQueue();
    }

    expect(channel.state.hasUnreconciledRun, isFalse);
    expect(channel.state.errorMessage, isNull);
    expect(store.leases.single.runId, 'run_1');
    await send;
  });

  test(
    'confirmation from another endpoint cannot authenticate reconnect',
    () async {
      final store = _MemoryDetachedRunStore()
        ..leases = [
          HermesDetachedRunLease(
            runId: 'run_a',
            sessionId: 'sess_1',
            baseUrl: 'http://127.0.0.1:8642',
            createdAt: DateTime.now().toUtc(),
          ),
          HermesDetachedRunLease(
            runId: 'run_b',
            sessionId: 'sess_1',
            baseUrl: 'http://127.0.0.1:8643',
            createdAt: DateTime.now().toUtc(),
          ),
        ];
      var streamOpenedOnB = false;
      final channel = HermesApiChannel(
        detachedRunStore: store,
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async => switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            '/v1/runs/run_a' =>
              '{"run_id":"run_a","session_id":"sess_1","status":"running"}',
            '/v1/runs/run_b' => throw StateError('network unavailable'),
            _ => throw StateError('unexpected GET $uri'),
          },
          getStream: (uri, headers) {
            if (config.baseUri.port == 8643) streamOpenedOnB = true;
            return const Stream.empty();
          },
        ),
      );
      addTearDown(channel.dispose);

      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      expect(channel.state.errorMessage, isNull);
      await channel.disconnect();
      await channel.connect(baseUrl: 'http://127.0.0.1:8643');

      expect(streamOpenedOnB, isFalse);
      expect(
        channel.state.errorMessage,
        'Hermes run is still active. Reconnect later before retrying.',
      );
      expect(channel.state.hasUnreconciledRun, isTrue);
    },
  );

  test('mismatched run status remains unconfirmed and fail-closed', () async {
    final store = _MemoryDetachedRunStore()
      ..leases = [
        HermesDetachedRunLease(
          runId: 'run_owned',
          sessionId: 'sess_1',
          baseUrl: 'http://127.0.0.1:8642',
          createdAt: DateTime.now().toUtc(),
        ),
      ];
    var streamOpened = false;
    final channel = HermesApiChannel(
      detachedRunStore: store,
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async => switch (uri.path) {
          '/health' => '{"status":"ok"}',
          '/v1/capabilities' => _runsCapableCapabilitiesFixture,
          '/api/sessions' => _sessionsFixture,
          '/api/sessions/sess_1/messages' => _messagesFixture,
          '/v1/runs/run_owned' =>
            '{"run_id":"run_other","session_id":"sess_1","status":"completed"}',
          _ => throw StateError('unexpected GET $uri'),
        },
        getStream: (uri, headers) {
          streamOpened = true;
          return const Stream.empty();
        },
      ),
    );
    addTearDown(channel.dispose);

    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    expect(store.leases.single.runId, 'run_owned');
    expect(streamOpened, isFalse);
    expect(channel.state.hasUnreconciledRun, isTrue);
    await expectLater(channel.sendText('must not duplicate'), throwsStateError);
  });

  test('stale and future detached leases reconcile conservatively', () async {
    final store = _MemoryDetachedRunStore()
      ..leases = [
        HermesDetachedRunLease(
          runId: 'run_old',
          sessionId: 'sess_1',
          baseUrl: 'http://127.0.0.1:8642',
          createdAt: DateTime.now().toUtc().subtract(const Duration(days: 2)),
        ),
        HermesDetachedRunLease(
          runId: 'run_future',
          sessionId: 'sess_1',
          baseUrl: 'http://127.0.0.1:8642',
          createdAt: DateTime.now().toUtc().add(const Duration(days: 2)),
        ),
      ];
    final statusPaths = <String>[];
    final channel = HermesApiChannel(
      detachedRunStore: store,
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          if (uri.path.startsWith('/v1/runs/')) {
            statusPaths.add(uri.path);
            final runId = uri.pathSegments.last;
            return '{"run_id":"$runId","session_id":"sess_1","status":"running"}';
          }
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        getStream: (uri, headers) => const Stream.empty(),
      ),
    );
    addTearDown(channel.dispose);

    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    expect(
      statusPaths,
      containsAll(['/v1/runs/run_old', '/v1/runs/run_future']),
    );
    expect(store.leases.map((lease) => lease.runId).toSet(), {
      'run_old',
      'run_future',
    });
    expect(channel.state.hasUnreconciledRun, isTrue);
  });

  test(
    'synchronous stream listen failure preserves only durable ownership',
    () async {
      final store = _MemoryDetachedRunStore();
      final stopPaths = <String>[];
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
            if (uri.path == '/v1/runs') {
              return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
            }
            stopPaths.add(uri.path);
            return '{}';
          },
          getStream: (uri, headers) => _ThrowingListenStringStream(),
        ),
      );
      addTearDown(channel.dispose);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('listen failure');
      channel.stopActiveTurn();
      await pumpEventQueue();

      expect(stopPaths, isEmpty);
      expect(store.leases.single.runId, 'run_1');
      expect(channel.state.hasUnreconciledRun, isTrue);
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

  test(
    'unresolved legacy blank-session lease blocks duplicate submission',
    () async {
      final store = _MemoryDetachedRunStore()
        ..leases = [
          HermesDetachedRunLease(
            runId: 'run_legacy',
            sessionId: '',
            baseUrl: 'http://127.0.0.1:8642',
            createdAt: DateTime.now().toUtc(),
          ),
        ];
      var runSubmissions = 0;
      final channel = HermesApiChannel(
        detachedRunStore: store,
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async => switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            '/v1/runs/run_legacy' => throw StateError('network unavailable'),
            _ => throw StateError('unexpected GET $uri'),
          },
          post: (uri, headers, body) async {
            runSubmissions += 1;
            return '{}';
          },
        ),
      );
      addTearDown(channel.dispose);

      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await expectLater(channel.sendText('do not duplicate'), throwsStateError);
      expect(runSubmissions, 0);
      expect(
        channel.state.errorMessage,
        'Wing could not verify a previous Hermes run. Reconnect before sending.',
      );
    },
  );

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
