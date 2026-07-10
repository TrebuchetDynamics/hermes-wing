part of '../hermes_api_channel_test.dart';

void _hermesApiChannelRunTransportTests() {
  test(
    'sendText uses run transport when advertised: streams deltas, surfaces an approval, then reconciles',
    () async {
      final approvals = <HermesApprovalRequest>[];
      var messagesRequests = 0;
      final posts = <String, Map<String, Object?>>{};
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
            posts[uri.path] = jsonDecode(body) as Map<String, Object?>;
            return switch (uri.path) {
              '/v1/runs' =>
                '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
              _ => '{}',
            };
          },
          getStream: (uri, headers) {
            expect(uri.path, '/v1/runs/run_1/events');
            return Stream.fromIterable([
              'event: message.delta\ndata: {"delta":"Hi"}\n\n',
              'event: approval.request\ndata: {"approval_id":"appr_1","prompt":"Run rm -rf?","risk":"high"}\n\n',
              'event: run.completed\ndata: {}\n\ndata: [DONE]\n\n',
            ]);
          },
        ),
      );
      channel.approvalRequests.listen(approvals.add);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('rm the temp dir');

      expect(posts['/v1/runs'], {
        'session_id': 'sess_1',
        'input': 'rm the temp dir',
        'message': 'rm the temp dir',
      });
      expect(approvals, hasLength(1));
      expect(approvals.single.id, 'appr_1');
      expect(approvals.single.prompt, 'Run rm -rf?');
      expect(approvals.single.risk, 'high');
      // Reconciled with server-confirmed history after the run completed.
      expect(channel.state.activeMessages.map((t) => t.text), [
        'Hello',
        'Hi there',
      ]);
    },
  );

  test('sendText accepts response SSE aliases', () async {
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
        post: (uri, headers, body) async => switch (uri.path) {
          '/v1/runs' =>
            '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
          _ => '{}',
        },
        getStream: (uri, headers) => Stream.fromIterable([
          'event: response.output_text.delta\ndata: {"delta":"Alias reply"}\n\n',
          'event: response.done\ndata: {}\n\n',
        ]),
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.sendText('use aliases');

    expect(channel.state.errorMessage, isNull);
    expect(channel.state.activeMessages.last.text, 'Alias reply');
    expect(
      channel.state.activeMessages.last.status,
      HermesTurnStatus.completed,
    );
  });

  test('sendText accepts approval event-name aliases', () async {
    final approvals = <HermesApprovalRequest>[];
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async => switch (uri.path) {
          '/health' => '{"status":"ok"}',
          '/v1/capabilities' => _runsCapableCapabilitiesFixture,
          '/api/sessions' => _sessionsFixture,
          '/api/sessions/sess_1/messages' => _messagesFixture,
          _ => throw StateError('unexpected GET $uri'),
        },
        post: (uri, headers, body) async => switch (uri.path) {
          '/v1/runs' =>
            '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
          _ => '{}',
        },
        getStream: (uri, headers) => Stream.fromIterable([
          'event: approval.required\ndata: {"approval_id":"appr_alias","prompt":"Approve alias?"}\n\n',
          'event: message.completed\ndata: {}\n\n',
        ]),
      ),
    );
    channel.approvalRequests.listen(approvals.add);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.sendText('needs approval');

    expect(approvals.single.id, 'appr_alias');
    expect(channel.state.errorMessage, isNull);
  });

  test('sendText accepts approval id aliases from run events', () async {
    final approvals = <HermesApprovalRequest>[];
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
            _ => '{}',
          };
        },
        getStream: (uri, headers) => Stream.fromIterable([
          'event: approval.request\ndata: {"id":"appr_alias","toolCallId":"tool_alias","prompt":"Approve alias?"}\n\n',
          'event: run.completed\ndata: {}\n\ndata: [DONE]\n\n',
        ]),
      ),
    );
    channel.approvalRequests.listen(approvals.add);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.sendText('needs approval');

    expect(approvals, hasLength(1));
    expect(approvals.single.id, 'appr_alias');
    expect(approvals.single.toolCallId, 'tool_alias');
    expect(approvals.single.prompt, 'Approve alias?');
    expect(channel.state.errorMessage, isNull);
  });

  test('sendText fails locally for malformed approval requests', () async {
    final approvals = <HermesApprovalRequest>[];
    final stream = _ManualStringStream();
    final sendDone = Completer<void>();
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
            _ => '{}',
          };
        },
        getStream: (uri, headers) => stream,
      ),
    );
    channel.approvalRequests.listen(approvals.add);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    unawaited(
      channel.sendText('needs approval').whenComplete(sendDone.complete),
    );
    await pumpEventQueue();
    stream.emit('event: approval.request\ndata: {"prompt":"Approve?"}\n\n');
    await pumpEventQueue();

    expect(sendDone.isCompleted, isTrue);
    expect(approvals, isEmpty);
    expect(
      channel.state.errorMessage,
      'Hermes approval request was missing an approval id.',
    );
    expect(channel.state.activeMessages.map((turn) => turn.text), [
      'Hello',
      'needs approval',
      '',
    ]);
    expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
  });

  test(
    'sendText completes and reconciles when run completed arrives without stream close',
    () async {
      var messagesRequests = 0;
      final stream = StreamController<String>();
      addTearDown(stream.close);
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
            return switch (uri.path) {
              '/v1/runs' =>
                '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
              _ => '{}',
            };
          },
          getStream: (uri, headers) => stream.stream,
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      final send = channel.sendText('finish run');
      await pumpEventQueue();
      stream.add('event: message.delta\ndata: {"delta":"local"}\n\n');
      stream.add('event: run.completed\ndata: {}\n\n');
      await send;
      stream.add('event: message.delta\ndata: {"delta":"late"}\n\n');
      await pumpEventQueue();

      expect(messagesRequests, 2);
      expect(channel.state.errorMessage, isNull);
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'Hi there',
      ]);
    },
  );

  test(
    'sendText keeps streamed assistant when server history is stale',
    () async {
      var messagesRequests = 0;
      final stream = StreamController<String>();
      addTearDown(stream.close);
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ == 0) ? _messagesFixture : _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            return switch (uri.path) {
              '/v1/runs' =>
                '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
              _ => '{}',
            };
          },
          getStream: (uri, headers) => stream.stream,
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      final send = channel.sendText('finish run');
      await pumpEventQueue();
      stream.add('event: message.delta\ndata: {"delta":"local reply"}\n\n');
      stream.add('event: run.completed\ndata: {}\n\n');
      await send;

      expect(messagesRequests, 2);
      expect(channel.state.errorMessage, isNull);
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'finish run',
        'local reply',
      ]);
      expect(
        channel.state.activeMessages.last.status,
        HermesTurnStatus.completed,
      );
    },
  );

  test('sendText ignores stream errors after terminal success', () async {
    var messagesRequests = 0;
    final stream = StreamController<String>();
    addTearDown(stream.close);
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
          return switch (uri.path) {
            '/v1/runs' =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
            _ => '{}',
          };
        },
        getStream: (uri, headers) => stream.stream,
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    final send = channel.sendText('finish run');
    await pumpEventQueue();
    stream.add('event: message.delta\ndata: {"delta":"local"}\n\n');
    stream.add('event: run.completed\ndata: {}\n\n');
    stream.addError(StateError('late stream drop'));
    await send;
    await pumpEventQueue();

    expect(messagesRequests, 2);
    expect(channel.state.errorMessage, isNull);
    expect(channel.state.activeMessages.map((turn) => turn.text), [
      'Hello',
      'Hi there',
    ]);
  });

  test('sendText treats assistant completed as terminal success', () async {
    var messagesRequests = 0;
    final stream = StreamController<String>();
    addTearDown(stream.close);
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
          return switch (uri.path) {
            '/v1/runs' =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
            _ => '{}',
          };
        },
        getStream: (uri, headers) => stream.stream,
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    final send = channel.sendText('finish assistant');
    await pumpEventQueue();
    stream.add('event: message.delta\ndata: {"delta":"local"}\n\n');
    stream.add('event: assistant.completed\ndata: {}\n\n');
    await send;
    stream.add('event: message.delta\ndata: {"delta":"late"}\n\n');
    await pumpEventQueue();

    expect(messagesRequests, 2);
    expect(channel.state.errorMessage, isNull);
    expect(channel.state.activeMessages.map((turn) => turn.text), [
      'Hello',
      'Hi there',
    ]);
  });

  test(
    'sendText completes when a terminal run cancelled event arrives without stream close',
    () async {
      final stream = _ManualStringStream();
      final sendDone = Completer<void>();
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
              _ => '{}',
            };
          },
          getStream: (uri, headers) => stream,
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      unawaited(channel.sendText('cancel run').whenComplete(sendDone.complete));
      await pumpEventQueue();
      stream.emit('event: run.cancelled\ndata: {}\n\n');
      await pumpEventQueue();

      expect(sendDone.isCompleted, isTrue);
      stream.emit('event: message.delta\ndata: {"delta":"late"}\n\n');
      await pumpEventQueue();

      expect(channel.state.errorMessage, 'Hermes run was cancelled.');
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'cancel run',
        '',
      ]);
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    },
  );

  test('sendText treats assistant failed as terminal failure', () async {
    final stream = _ManualStringStream();
    final sendDone = Completer<void>();
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
            _ => '{}',
          };
        },
        getStream: (uri, headers) => stream,
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    unawaited(
      channel.sendText('fail assistant').whenComplete(sendDone.complete),
    );
    await pumpEventQueue();
    stream.emit('event: message.delta\ndata: {"delta":"partial"}\n\n');
    await pumpEventQueue();
    stream.emit('event: assistant.failed\ndata: {}\n\n');
    await pumpEventQueue();

    expect(sendDone.isCompleted, isTrue);
    stream.emit('event: message.delta\ndata: {"delta":"late"}\n\n');
    await pumpEventQueue();

    expect(channel.state.errorMessage, 'Hermes run failed.');
    expect(channel.state.activeMessages.map((turn) => turn.text), [
      'Hello',
      'fail assistant',
      'partial',
    ]);
    expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
  });

  test(
    'sendText keeps local failed assistant turn when run failed event arrives',
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
                    : _reconciledMessagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            return switch (uri.path) {
              '/v1/runs' =>
                '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
              _ => '{}',
            };
          },
          getStream: (uri, headers) => Stream.fromIterable([
            'event: message.delta\ndata: {"delta":"partial"}\n\n',
            'event: run.failed\ndata: {}\n\ndata: [DONE]\n\n',
          ]),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('fail the run');

      expect(messagesRequests, 1);
      expect(channel.state.errorMessage, 'Hermes run failed.');
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'fail the run',
        'partial',
      ]);
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    },
  );

  test(
    'sendText via run transport tracks tool events by call id instead of duplicating turns',
    () async {
      var messagesRequests = 0;
      final states = <HermesChannelState>[];
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
            return switch (uri.path) {
              '/v1/runs' =>
                '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
              _ => '{}',
            };
          },
          getStream: (uri, headers) => Stream.fromIterable([
            'event: tool.started\ndata: {"tool":"bash","preview":"ls -la"}\n\n',
            'event: message.delta\ndata: {"delta":"Looking"}\n\n',
            'event: tool.completed\ndata: {"tool":"bash","result_text":"file1"}\n\n',
            'event: message.delta\ndata: {"delta":" done"}\n\ndata: [DONE]\n\n',
          ]),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      channel.addListener(() => states.add(channel.state));

      await channel.sendText('list the files');

      // Snapshot from mid-run, before reconciliation replaces the transcript
      // with server-confirmed history: exactly one tool-call turn (not two),
      // updated in place from `running` to `completed`, ordered before the
      // streaming assistant reply.
      final duringRun = states.lastWhere(
        (s) => s.activeMessages.any((t) => t.kind == HermesTurnKind.toolCall),
      );
      final turns = duringRun.activeMessages;
      expect(
        turns.where((t) => t.kind == HermesTurnKind.toolCall),
        hasLength(1),
      );
      final toolTurn = turns.firstWhere(
        (t) => t.kind == HermesTurnKind.toolCall,
      );
      final toolIndex = turns.indexOf(toolTurn);
      final assistantIndex = turns.indexWhere(
        (t) => t.author == HermesTurnAuthor.assistant,
      );
      expect(toolIndex, lessThan(assistantIndex));
      expect(toolTurn.toolCall?.name, 'bash');
      expect(toolTurn.toolCall?.status, 'completed');
      expect(toolTurn.toolCall?.result, 'file1');
    },
  );

  test('sendText via run transport updates tool progress in place', () async {
    final states = <HermesChannelState>[];
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
            _ => '{}',
          };
        },
        getStream: (uri, headers) => Stream.fromIterable([
          'event: tool.started\ndata: {"tool":"bash","tool_call_id":"call_1","preview":"starting"}\n\n',
          'event: tool.progress\ndata: {"tool":"bash","tool_call_id":"call_1","preview":"halfway"}\n\n',
          'event: message.delta\ndata: {"delta":"done"}\n\ndata: [DONE]\n\n',
        ]),
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    channel.addListener(() => states.add(channel.state));

    await channel.sendText('track progress');

    final progressState = states.lastWhere(
      (s) => s.activeMessages.any(
        (turn) =>
            turn.kind == HermesTurnKind.toolCall &&
            turn.toolCall?.preview == 'halfway',
      ),
    );
    final toolTurns = progressState.activeMessages
        .where((turn) => turn.kind == HermesTurnKind.toolCall)
        .toList(growable: false);
    expect(toolTurns, hasLength(1));
    expect(toolTurns.single.toolCall?.name, 'bash');
    expect(toolTurns.single.toolCall?.status, 'running');
    expect(toolTurns.single.toolCall?.preview, 'halfway');
  });

  test(
    'sendText via run transport keeps same-name tool calls separate by event call id',
    () async {
      var messagesRequests = 0;
      final states = <HermesChannelState>[];
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
            return switch (uri.path) {
              '/v1/runs' =>
                '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
              _ => '{}',
            };
          },
          getStream: (uri, headers) => Stream.fromIterable([
            'event: tool.started\ndata: {"tool":"bash","tool_call_id":"call_a","preview":"ls"}\n\n',
            'event: tool.started\ndata: {"tool":"bash","tool_call_id":"call_b","preview":"pwd"}\n\n',
            'event: tool.completed\ndata: {"tool":"bash","tool_call_id":"call_a","result_text":"file1"}\n\n',
            'event: tool.completed\ndata: {"tool":"bash","tool_call_id":"call_b","result_text":"/tmp"}\n\n',
            'event: message.delta\ndata: {"delta":"done"}\n\ndata: [DONE]\n\n',
          ]),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      channel.addListener(() => states.add(channel.state));

      await channel.sendText('run two commands');

      final duringRun = states.lastWhere(
        (s) =>
            s.activeMessages
                .where((t) => t.kind == HermesTurnKind.toolCall)
                .length ==
            2,
      );
      final toolTurns = duringRun.activeMessages
          .where((t) => t.kind == HermesTurnKind.toolCall)
          .toList(growable: false);
      expect(toolTurns, hasLength(2));
      expect(toolTurns.map((turn) => turn.toolCall?.name), ['bash', 'bash']);
      expect(toolTurns.map((turn) => turn.toolCall?.status), [
        'completed',
        'completed',
      ]);
      expect(toolTurns.map((turn) => turn.toolCall?.result), ['file1', '/tmp']);
    },
  );
}
