part of '../hermes_api_channel_test.dart';

void _hermesApiChannelApprovalStopTests() {
  test(
    'respondToApproval rejects locally when approval endpoint is absent',
    () async {
      final posts = <String>[];
      final openRunEvents = StreamController<String>();
      addTearDown(openRunEvents.close);
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsWithoutStopCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            posts.add(uri.path);
            return switch (uri.path) {
              '/v1/runs' =>
                '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
              _ => '{}',
            };
          },
          getStream: (uri, headers) => openRunEvents.stream,
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      unawaited(channel.sendText('do the risky thing'));
      await pumpEventQueue();

      await expectLater(
        channel.respondToApproval(
          approvalId: 'appr_1',
          decision: HermesApprovalDecision.once,
        ),
        throwsStateError,
      );

      expect(posts, ['/v1/runs']);
      expect(
        channel.state.errorMessage,
        contains('did not advertise approval responses'),
      );
    },
  );

  test('respondToApproval rejects blank approval ids before POST', () async {
    final posts = <String>[];
    final openRunEvents = StreamController<String>();
    addTearDown(openRunEvents.close);
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
          posts.add(uri.path);
          return switch (uri.path) {
            '/v1/runs' =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
            _ => '{}',
          };
        },
        getStream: (uri, headers) => openRunEvents.stream,
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    unawaited(channel.sendText('do the risky thing'));
    await pumpEventQueue();

    await expectLater(
      channel.respondToApproval(
        approvalId: '   ',
        decision: HermesApprovalDecision.once,
      ),
      throwsStateError,
    );

    expect(posts, ['/v1/runs']);
    expect(channel.state.errorMessage, contains('approval id is missing'));
  });

  test('respondToApproval trims approval ids before POST', () async {
    final posts = <String, Map<String, Object?>>{};
    final openRunEvents = StreamController<String>();
    addTearDown(openRunEvents.close);
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
          posts[uri.path] = jsonDecode(body) as Map<String, Object?>;
          return switch (uri.path) {
            '/v1/runs' =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
            _ => '{}',
          };
        },
        getStream: (uri, headers) => openRunEvents.stream,
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    unawaited(channel.sendText('do the risky thing'));
    await pumpEventQueue();

    await channel.respondToApproval(
      approvalId: '  appr_1  ',
      decision: HermesApprovalDecision.once,
    );

    expect(posts['/v1/runs/run_1/approval'], {
      'approval_id': 'appr_1',
      'decision': 'once',
    });
  });

  test('respondToApproval answers the active run', () async {
    final posts = <String, Map<String, Object?>>{};
    // Left open deliberately: the run is still active awaiting the
    // operator's approval decision when respondToApproval is called.
    final openRunEvents = StreamController<String>();
    addTearDown(openRunEvents.close);
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
          posts[uri.path] = jsonDecode(body) as Map<String, Object?>;
          return switch (uri.path) {
            '/v1/runs' =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
            _ => '{}',
          };
        },
        getStream: (uri, headers) => openRunEvents.stream,
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    unawaited(channel.sendText('do the risky thing'));
    await pumpEventQueue();
    openRunEvents.add(
      'event: approval.request\ndata: {"approval_id":"appr_1"}\n\n',
    );
    await pumpEventQueue();

    await channel.respondToApproval(
      approvalId: 'appr_1',
      decision: HermesApprovalDecision.always,
    );

    expect(posts['/v1/runs/run_1/approval'], {
      'approval_id': 'appr_1',
      'decision': 'always',
    });
  });

  test(
    'respondToApproval ignores failures after the active run is gone',
    () async {
      final openRunEvents = StreamController<String>();
      final approvalStarted = Completer<void>();
      final releaseApproval = Completer<void>();
      addTearDown(openRunEvents.close);
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
            return switch (uri.path) {
              '/v1/runs' =>
                '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
              '/v1/runs/run_1/approval' => () async {
                approvalStarted.complete();
                await releaseApproval.future;
                throw StateError('approval failed after disconnect');
              }(),
              _ => '{}',
            };
          },
          getStream: (uri, headers) => openRunEvents.stream,
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      unawaited(channel.sendText('do the risky thing'));
      await pumpEventQueue();
      openRunEvents.add(
        'event: approval.request\ndata: {"approval_id":"appr_1"}\n\n',
      );
      await pumpEventQueue();

      final response = channel.respondToApproval(
        approvalId: 'appr_1',
        decision: HermesApprovalDecision.once,
      );
      await approvalStarted.future;
      await channel.disconnect();
      releaseApproval.complete();
      await response;

      expect(channel.state.status, HermesConnectionStatus.disconnected);
      expect(channel.state.errorMessage, isNull);
    },
  );

  test('respondToApproval surfaces approval response failures', () async {
    final openRunEvents = StreamController<String>();
    addTearDown(openRunEvents.close);
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
          return switch (uri.path) {
            '/v1/runs' =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
            '/v1/runs/run_1/approval' => throw StateError('approval failed'),
            _ => '{}',
          };
        },
        getStream: (uri, headers) => openRunEvents.stream,
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    unawaited(channel.sendText('do the risky thing'));
    await pumpEventQueue();
    openRunEvents.add(
      'event: approval.request\ndata: {"approval_id":"appr_1"}\n\n',
    );
    await pumpEventQueue();

    await expectLater(
      channel.respondToApproval(
        approvalId: 'appr_1',
        decision: HermesApprovalDecision.once,
      ),
      throwsA(isA<StateError>()),
    );

    expect(channel.state.errorMessage, contains('Could not answer approval'));
    expect(channel.state.errorMessage, contains('approval failed'));
  });

  test(
    'stopActiveTurn swallows server stop failure after clearing the active run',
    () async {
      final stopRequests = <String>[];
      final openRunEvents = StreamController<String>();
      addTearDown(openRunEvents.close);
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
            return switch (uri.path) {
              '/v1/runs' =>
                '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
              '/v1/runs/run_1/stop' => throw StateError(
                (stopRequests..add(uri.path)).join(','),
              ),
              _ => '{}',
            };
          },
          getStream: (uri, headers) => openRunEvents.stream,
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      unawaited(channel.sendText('keep going forever'));
      await pumpEventQueue();

      channel.stopActiveTurn();
      channel.stopActiveTurn();
      await pumpEventQueue();

      expect(stopRequests, ['/v1/runs/run_1/stop']);
    },
  );

  test('stopActiveTurn stays local when run stop is not advertised', () async {
    final posts = <String>[];
    final openRunEvents = StreamController<String>();
    addTearDown(openRunEvents.close);
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsWithoutStopCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          posts.add(uri.path);
          return switch (uri.path) {
            '/v1/runs' =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
            _ => '{}',
          };
        },
        getStream: (uri, headers) => openRunEvents.stream,
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    final sendFuture = channel.sendText('keep going forever');
    await pumpEventQueue();

    channel.stopActiveTurn();
    await sendFuture;
    await pumpEventQueue();

    expect(posts, ['/v1/runs']);
    expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    expect(channel.state.activeMessages.last.text, 'Stopped.');
  });

  test('stopActiveTurn stops the active run on the server', () async {
    final posts = <String, Map<String, Object?>>{};
    // Left open deliberately: simulates a long-running turn that only stops
    // because the operator calls stopActiveTurn, not because the stream ends.
    final openRunEvents = StreamController<String>();
    addTearDown(openRunEvents.close);
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
          posts[uri.path] = jsonDecode(body) as Map<String, Object?>;
          return switch (uri.path) {
            '/v1/runs' =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
            _ => '{}',
          };
        },
        getStream: (uri, headers) => openRunEvents.stream,
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    final sendFuture = channel.sendText('keep going forever');
    await pumpEventQueue();

    channel.stopActiveTurn();
    expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    expect(channel.state.activeMessages.last.text, 'Stopped.');
    await sendFuture;
    await pumpEventQueue();

    expect(posts['/v1/runs/run_1/stop'], <String, Object?>{});
    expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    expect(channel.state.activeMessages.last.text, 'Stopped.');
  });
}
