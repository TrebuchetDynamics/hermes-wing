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
      expect(approvals.single.runId, 'run_1');
      expect(approvals.single.sessionId, 'sess_1');
      // Reconciled with server-confirmed history after the run completed.
      expect(channel.state.activeMessages.map((t) => t.text), [
        'Hello',
        'Hi there',
      ]);
    },
  );

  test(
    'terminal canonical output repairs dropped middle deltas for the owned run',
    () async {
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
          getStream: (uri, headers) => Stream.fromIterable(const [
            'event: message.delta\ndata: {"delta":"Hola, este "}\n\n',
            'event: message.delta\ndata: {"delta":"mensaje bilingüe"}\n\n',
            'event: run.completed\ndata: {"run_id":"run_1","session_id":"sess_1","output":"Hola, 世界, este mensaje bilingüe"}\n\n',
          ]),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('repair this stream');

      expect(
        channel.state.activeMessages.last.text,
        'Hola, 世界, este mensaje bilingüe',
      );
      expect(
        channel.state.activeMessages.last.status,
        HermesTurnStatus.completed,
      );
    },
  );

  for (final mismatch in const {
    'run':
        '{"run_id":"run_other","session_id":"sess_1","output":"Stale canonical"}',
    'session':
        '{"run_id":"run_1","session_id":"sess_other","output":"Stale canonical"}',
  }.entries) {
    test(
      'terminal canonical output rejects a mismatched ${mismatch.key}',
      () async {
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
              'event: message.delta\ndata: {"delta":"Owned stream"}\n\n',
              'event: run.completed\ndata: ${mismatch.value}\n\n',
            ]),
          ),
        );
        addTearDown(channel.dispose);
        await channel.connect(baseUrl: 'http://127.0.0.1:8642');

        await channel.sendText('reject stale final');

        expect(channel.state.activeMessages.last.text, 'Owned stream');
      },
    );
  }

  test(
    'session switching preserves concurrent runs and streams each transcript',
    () async {
      final streams = <String, _ManualStringStream>{};
      final approvalPosts = <String>[];
      var nextRun = 1;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async => switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' =>
              '''
{"object":"list","data":[{"id":"sess_1","source":"api"},{"id":"sess_2","source":"api"}]}
''',
            '/api/sessions/sess_1/messages' =>
              '''
{"object":"list","data":[{"id":"seed_1","session_id":"sess_1","role":"assistant","content":"First seed"}]}
''',
            '/api/sessions/sess_2/messages' =>
              '''
{"object":"list","data":[{"id":"seed_2","session_id":"sess_2","role":"assistant","content":"Second seed"}]}
''',
            _ => throw StateError('unexpected GET $uri'),
          },
          post: (uri, headers, body) async {
            if (uri.path.endsWith('/approval')) {
              approvalPosts.add(uri.path);
              return '{}';
            }
            if (uri.path != '/v1/runs') {
              throw StateError('unexpected POST $uri');
            }
            final request = jsonDecode(body) as Map<String, Object?>;
            final runId = 'run_${nextRun++}';
            return jsonEncode({
              'object': 'hermes.run',
              'run': {'id': runId, 'session_id': request['session_id']},
            });
          },
          getStream: (uri, headers) {
            final runId = uri.pathSegments[2];
            return streams.putIfAbsent(runId, _ManualStringStream.new);
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      final first = channel.sendText('first request');
      await pumpEventQueue();
      await channel.selectSession('sess_2');
      await pumpEventQueue();
      expect(
        streams['run_1']?.cancelCount,
        0,
        reason: 'switching sessions must not detach the first run stream',
      );
      final second = channel.sendText('second request');
      await pumpEventQueue();

      streams['run_1']!.emit(
        'event: approval.request\ndata: {"approval_id":"approval-first"}\n\n',
      );
      await pumpEventQueue();
      await channel.respondToApproval(
        approvalId: 'approval-first',
        decision: HermesApprovalDecision.once,
      );
      expect(approvalPosts, ['/v1/runs/run_1/approval']);

      streams['run_1']!.emit(
        'event: message.delta\ndata: {"delta":"First reply"}\n\n',
      );
      await pumpEventQueue();
      streams['run_1']!.emit('event: run.completed\ndata: {}\n\n');
      await pumpEventQueue();
      streams['run_2']!.emit(
        'event: message.delta\ndata: {"delta":"Second reply"}\n\n',
      );
      await pumpEventQueue();
      streams['run_2']!.emit('event: run.completed\ndata: {}\n\n');
      await pumpEventQueue();
      await Future.wait([first, second]);

      expect(channel.state.messages['sess_1']?.map((turn) => turn.text), [
        'First seed',
        'first request',
        'First reply',
      ]);
      expect(channel.state.messages['sess_2']?.map((turn) => turn.text), [
        'Second seed',
        'second request',
        'Second reply',
      ]);
      expect(
        channel.state.messages['sess_1']?.last.status,
        HermesTurnStatus.completed,
      );
      expect(
        channel.state.messages['sess_2']?.last.status,
        HermesTurnStatus.completed,
      );
    },
  );

  test('stop targets only the selected session run', () async {
    final streams = <String, _ManualStringStream>{};
    final stopPaths = <String>[];
    var nextRun = 1;
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async => switch (uri.path) {
          '/health' => '{"status":"ok"}',
          '/v1/capabilities' => _runsCapableCapabilitiesFixture,
          '/api/sessions' =>
            '''
{"object":"list","data":[{"id":"sess_1","source":"api"},{"id":"sess_2","source":"api"}]}
''',
          '/api/sessions/sess_1/messages' => '{"object":"list","data":[]}',
          '/api/sessions/sess_2/messages' => '{"object":"list","data":[]}',
          _ => throw StateError('unexpected GET $uri'),
        },
        post: (uri, headers, body) async {
          if (uri.path.endsWith('/stop')) {
            stopPaths.add(uri.path);
            return '{}';
          }
          if (uri.path != '/v1/runs') {
            throw StateError('unexpected POST $uri');
          }
          final request = jsonDecode(body) as Map<String, Object?>;
          final runId = 'run_${nextRun++}';
          return jsonEncode({
            'object': 'hermes.run',
            'run': {'id': runId, 'session_id': request['session_id']},
          });
        },
        getStream: (uri, headers) {
          final runId = uri.pathSegments[2];
          return streams.putIfAbsent(runId, _ManualStringStream.new);
        },
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    final first = channel.sendText('first');
    await pumpEventQueue();
    await channel.selectSession('sess_2');
    final second = channel.sendText('second');
    await pumpEventQueue();

    channel.stopActiveTurn();
    await pumpEventQueue();

    expect(stopPaths, ['/v1/runs/run_2/stop']);
    expect(
      channel.state.messages['sess_2']?.last.status,
      HermesTurnStatus.failed,
    );
    expect(
      channel.state.messages['sess_1']?.last.status,
      HermesTurnStatus.streaming,
    );

    streams['run_1']!.emit(
      'event: message.delta\ndata: {"delta":"First completed"}\n\n',
    );
    await pumpEventQueue();
    streams['run_1']!.emit('event: run.completed\ndata: {}\n\n');
    await pumpEventQueue();
    await Future.wait([first, second]);

    expect(channel.state.messages['sess_1']?.last.text, 'First completed');
    expect(
      channel.state.messages['sess_1']?.last.status,
      HermesTurnStatus.completed,
    );
  });

  test('sendText exposes bounded run token usage on the assistant turn', () async {
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
          'event: message.delta\ndata: {"delta":"Measured reply"}\n\n',
          'event: run.completed\ndata: {"usage":{"input_tokens":12,"output_tokens":7,"total_tokens":19}}\n\n',
        ]),
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.sendText('measure this');

    final assistant = channel.state.activeMessages.last;
    expect(assistant.text, 'Measured reply');
    expect(assistant.usage?.inputTokens, 12);
    expect(assistant.usage?.outputTokens, 7);
    expect(assistant.usage?.totalTokens, 19);
  });

  test('sendText surfaces bounded reasoning events before the reply', () async {
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
        post: (uri, headers, body) async =>
            '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
        getStream: (uri, headers) => Stream.fromIterable([
          'data: {"event":"reasoning.available","text":"Compare the observed constraints first."}\n\n',
          'data: {"event":"message.delta","delta":"Reasoned answer"}\n\n',
          'data: {"event":"run.completed","usage":{"total_tokens":9}}\n\n',
        ]),
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.sendText('reason about this');

    final turns = channel.state.activeMessages;
    expect(turns.map((turn) => turn.kind), [
      HermesTurnKind.text,
      HermesTurnKind.text,
      HermesTurnKind.reasoning,
      HermesTurnKind.text,
    ]);
    expect(turns[2].text, 'Compare the observed constraints first.');
    expect(turns.last.text, 'Reasoned answer');
  });

  test('sendText drops reasoning identical to the completed reply', () async {
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
        post: (uri, headers, body) async =>
            '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
        getStream: (uri, headers) => Stream.fromIterable([
          'data: {"event":"reasoning.available","text":"Same answer"}\n\n',
          'data: {"event":"message.delta","delta":"Same answer"}\n\n',
          'data: {"event":"run.completed"}\n\n',
        ]),
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.sendText('deduplicate this');

    expect(
      channel.state.activeMessages.map((turn) => turn.kind),
      everyElement(HermesTurnKind.text),
    );
    expect(channel.state.activeMessages.last.text, 'Same answer');
  });

  test('sendText bounds oversized reasoning event text', () async {
    final oversized = List.filled(20000, 'r').join();
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
        post: (uri, headers, body) async =>
            '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
        getStream: (uri, headers) => Stream.fromIterable([
          'data: ${jsonEncode({'event': 'reasoning.available', 'text': oversized})}\n\n',
          'data: {"event":"message.delta","delta":"Done"}\n\n',
          'data: {"event":"run.completed"}\n\n',
        ]),
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.sendText('bound reasoning');

    final reasoning = channel.state.activeMessages.singleWhere(
      (turn) => turn.kind == HermesTurnKind.reasoning,
    );
    expect(reasoning.text, hasLength(16384));
    expect(reasoning.text, endsWith('…'));
  });

  test(
    'sendText preserves distinct assistant and reasoning segments through history reconciliation',
    () async {
      var messagesRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async => switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' =>
              (messagesRequests++ == 0)
                  ? _messagesFixture
                  : _reconciledMessagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          },
          post: (uri, headers, body) async =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
          getStream: (uri, headers) => Stream.fromIterable([
            'data: {"event":"reasoning.available","text":"Reasoning survives."}\n\n',
            'data: {"event":"message.delta","delta":"Local"}\n\n',
            'data: {"event":"tool.started","tool":"bash","tool_call_id":"call_1","preview":"inspect"}\n\n',
            'data: {"event":"message.delta","delta":"Hi there"}\n\n',
            'data: {"event":"run.completed"}\n\n',
          ]),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('reconcile reasoning');

      expect(channel.state.activeMessages.map((turn) => turn.kind), [
        HermesTurnKind.text,
        HermesTurnKind.reasoning,
        HermesTurnKind.text,
        HermesTurnKind.toolCall,
        HermesTurnKind.text,
      ]);
      expect(channel.state.activeMessages[1].text, 'Reasoning survives.');
      expect(channel.state.activeMessages[2].text, 'Local');
      expect(channel.state.activeMessages[3].toolCall?.name, 'bash');
      expect(channel.state.activeMessages.last.text, 'Hi there');
    },
  );

  test(
    'sendText recovers usage from advertised run status and keeps it through history reconciliation',
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
            '/api/sessions/sess_1/messages' =>
              (messagesRequests++ == 0)
                  ? _messagesFixture
                  : _reconciledMessagesFixture,
            '/v1/runs/run_1' => () {
              statusRequests += 1;
              return '{"run_id":"run_1","session_id":"sess_1","status":"completed","usage":{"input_tokens":12,"output_tokens":7,"total_tokens":19}}';
            }(),
            _ => throw StateError('unexpected GET $uri'),
          },
          post: (uri, headers, body) async => switch (uri.path) {
            '/v1/runs' =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
            _ => '{}',
          },
          getStream: (uri, headers) => Stream.fromIterable([
            'event: message.delta\ndata: {"delta":"Local"}\n\n',
            'event: run.completed\ndata: {}\n\n',
          ]),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('measure this');

      expect(statusRequests, 1);
      final assistant = channel.state.activeMessages.last;
      expect(assistant.text, 'Hi there');
      expect(assistant.usage?.totalTokens, 19);
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

  test(
    'sendText keeps the owned run attached after a malformed approval request',
    () async {
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

      expect(sendDone.isCompleted, isFalse);
      expect(approvals, isEmpty);
      expect(
        channel.state.errorMessage,
        'Hermes approval request was missing an approval id. The run is still active.',
      );
      expect(
        channel.state.activeMessages.last.status,
        HermesTurnStatus.streaming,
      );

      stream.emit(
        'event: message.delta\ndata: {"delta":"Recovered"}\n\n'
        'event: run.completed\ndata: {}\n\n',
      );
      await sendDone.future;

      expect(channel.state.errorMessage, isNull);
      expect(channel.state.activeMessages.last.text, 'Recovered');
      expect(
        channel.state.activeMessages.last.status,
        HermesTurnStatus.completed,
      );
    },
  );

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

  test('sendText ignores error events after terminal success', () async {
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
    stream.add(
      'event: run.completed\ndata: {}\n\n'
      'event: error\ndata: {"message":"late stream drop"}\n\n',
    );
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

  test('sendText recovers missing failure detail from run status', () async {
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async => switch (uri.path) {
          '/health' => '{"status":"ok"}',
          '/v1/capabilities' => _runsCapableCapabilitiesFixture,
          '/api/sessions' => _sessionsFixture,
          '/api/sessions/sess_1/messages' => _messagesFixture,
          '/v1/runs/run_1' =>
            '{"object":"hermes.run","run_id":"run_1","session_id":"sess_1","status":"failed","error":"HTTP 429 for api_key=secret-key at /home/alice/.hermes"}',
          _ => throw StateError('unexpected GET $uri'),
        },
        post: (uri, headers, body) async =>
            '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
        getStream: (uri, headers) =>
            Stream.fromIterable(const ['event: run.failed\ndata: {}\n\n']),
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.sendText('recover failure details');

    expect(
      channel.state.errorMessage,
      'Hermes run failed: HTTP 429 for api_key=[redacted] at [redacted-path]',
    );
    expect(channel.state.errorMessage, isNot(contains('secret-key')));
    expect(channel.state.errorMessage, isNot(contains('/home/alice')));
  });

  test('sendText recovers structured details after generic stream errors', () async {
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async => switch (uri.path) {
          '/health' => '{"status":"ok"}',
          '/v1/capabilities' => _runsCapableCapabilitiesFixture,
          '/api/sessions' => _sessionsFixture,
          '/api/sessions/sess_1/messages' => _messagesFixture,
          '/v1/runs/run_1' =>
            '{"object":"hermes.run","run_id":"run_1","session_id":"sess_1","status":"failed","error":{"type":"authentication_error","message":"Provider rejected api_key=secret-key"}}',
          _ => throw StateError('unexpected GET $uri'),
        },
        post: (uri, headers, body) async =>
            '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
        getStream: (uri, headers) =>
            Stream.fromIterable(const ['event: stream.error\ndata: {}\n\n']),
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.sendText('recover structured failure details');

    expect(
      channel.state.errorMessage,
      'Hermes run failed: authentication_error: Provider rejected api_key=[redacted]',
    );
    expect(channel.state.errorMessage, isNot(contains('secret-key')));
  });

  test('sendText preserves redacted run failure details', () async {
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
        post: (uri, headers, body) async =>
            '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
        getStream: (uri, headers) => Stream.fromIterable(const [
          'event: run.failed\ndata: {"code":"provider_error","reason":"Quota exceeded for api_key=secret-key"}\n\n',
        ]),
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.sendText('fail with details');

    expect(
      channel.state.errorMessage,
      'Hermes run failed: provider_error: Quota exceeded for api_key=[redacted]',
    );
    expect(channel.state.errorMessage, isNot(contains('secret-key')));
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
