part of '../hermes_api_channel_test.dart';

void _hermesApiChannelStopOutcomeTests() {
  test(
    'denied terminal run hydrates canonical history before the next prompt',
    () async {
      var submits = 0;
      var directStreams = 0;
      final streams = <_ManualStringStream>[];
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async => switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' =>
              submits == 0
                  ? _messagesFixture
                  : '{"object":"list","session_id":"sess_1","data":[{"id":"canonical-user","session_id":"sess_1","role":"user","content":"Synthetic denied"},{"id":"canonical-denied","session_id":"sess_1","role":"assistant","content":"Synthetic denied outcome"}]}',
            '/v1/runs/run_1' =>
              '{"run_id":"run_1","session_id":"sess_1","status":"cancelled"}',
            _ => throw StateError('unexpected synthetic GET'),
          },
          post: (uri, headers, body) async {
            expect(uri.path, '/v1/runs');
            submits++;
            if (submits == 2) {
              expect((jsonDecode(body) as Map)['conversation_history'], [
                {'role': 'user', 'content': 'Synthetic denied'},
                {'role': 'assistant', 'content': 'Synthetic denied outcome'},
              ]);
            }
            return '{"run_id":"run_$submits","session_id":"sess_1"}';
          },
          getStream: (uri, headers) {
            final stream = _ManualStringStream();
            streams.add(stream);
            return stream;
          },
          postStream: (uri, headers, body) {
            directStreams++;
            return Stream.fromIterable(const ['data: [DONE]\n\n']);
          },
        ),
      );
      addTearDown(channel.dispose);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      final denied = channel.sendText('Synthetic denied');
      await pumpEventQueue();
      streams.single.emit(
        'event: run.cancelled\ndata: {"run_id":"run_1","session_id":"sess_1"}\n\n',
      );
      await denied;
      final next = channel.sendText('Synthetic next');
      await pumpEventQueue();
      expect(directStreams, 0);
      expect(submits, 2);
      channel.cancelActiveTurn();
      await next;
    },
  );

  for (final outcome in [
    'stopping',
    'unknown',
    'status-error',
    'stop-error',
    'wrong-run',
    'wrong-session',
    'history-error',
    'status-unadvertised',
    'cancelled',
    'completed',
    'failed',
  ]) {
    test(
      'stop outcome $outcome requires exact terminal state and history',
      () async {
        final stream = _ManualStringStream();
        var historyReads = 0;
        var submits = 0;
        var stops = 0;
        final channel = HermesApiChannel(
          clientBuilder: (config) => HermesApiClient(
            config: config,
            get: (uri, headers) async {
              switch (uri.path) {
                case '/health':
                  return '{"status":"ok"}';
                case '/v1/capabilities':
                  if (outcome == 'status-unadvertised') {
                    final capabilities =
                        jsonDecode(_runsCapableCapabilitiesFixture) as Map;
                    (capabilities['endpoints'] as Map).remove('run_status');
                    return jsonEncode(capabilities);
                  }
                  return _runsCapableCapabilitiesFixture;
                case '/api/sessions':
                  return _sessionsFixture;
                case '/api/sessions/sess_1/messages':
                  if (++historyReads > 1 && outcome == 'history-error') {
                    throw StateError('synthetic history failure');
                  }
                  return historyReads == 1
                      ? _messagesFixture
                      : '{"object":"list","session_id":"sess_1","data":[{"id":"canonical-stop","session_id":"sess_1","role":"assistant","content":"Synthetic canonical terminal history."}]}';
                case '/v1/runs/run_1':
                  expect(outcome, isNot('status-unadvertised'));
                  if (outcome == 'status-error') {
                    throw StateError('synthetic status failure');
                  }
                  return jsonEncode({
                    'run_id': outcome == 'wrong-run' ? 'foreign' : 'run_1',
                    'session_id': outcome == 'wrong-session'
                        ? 'foreign'
                        : 'sess_1',
                    'status': outcome == 'stopping' || outcome == 'unknown'
                        ? outcome
                        : outcome == 'completed'
                        ? 'completed'
                        : outcome == 'failed'
                        ? 'failed'
                        : 'cancelled',
                  });
                default:
                  throw StateError('unexpected synthetic route');
              }
            },
            post: (uri, headers, body) async {
              if (uri.path == '/v1/runs') {
                submits++;
                return '{"run_id":"run_1","session_id":"sess_1"}';
              }
              expect(uri.path, '/v1/runs/run_1/stop');
              stops++;
              if (outcome == 'stop-error') {
                throw StateError('synthetic stop failure');
              }
              return '{"run_id":"run_1","status":"stopping"}';
            },
            getStream: (uri, headers) => stream,
          ),
        );
        addTearDown(channel.dispose);
        await channel.connect(baseUrl: 'http://127.0.0.1:8642');
        final send = channel.sendText('Synthetic stop request');
        await pumpEventQueue();
        final target = channel.activeTurnInterruptionTarget!;
        final confirmed = await channel.stopTurn(target);
        await send;
        final terminal = ['cancelled', 'completed', 'failed'].contains(outcome);
        expect(confirmed, terminal);
        expect(stops, 1);
        expect(submits, 1);
        expect(channel.state.hasUnreconciledRun, !terminal);
        if (terminal) {
          expect(channel.state.activeMessages.single.id, 'canonical-stop');
        } else {
          expect(channel.state.errorMessage, contains('Reconnect'));
          await expectLater(
            channel.sendText('Do not replay'),
            throwsStateError,
          );
          expect(submits, 1);
        }
      },
    );
  }

  test(
    'stop status after session roundtrip cannot release current ownership',
    () async {
      final started = Completer<void>();
      final delayedStatus = Completer<String>();
      var reads = 0;
      final stream = _ManualStringStream();
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async => switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => '{"data":[{"id":"sess_1"},{"id":"sess_2"}]}',
            '/api/sessions/sess_1/messages' => _messagesFixture,
            '/api/sessions/sess_2/messages' =>
              '{"object":"list","session_id":"sess_2","data":[]}',
            '/v1/runs/run_1' => () {
              if (++reads == 1) {
                started.complete();
                return delayedStatus.future;
              }
              return Future.value(
                '{"run_id":"run_1","session_id":"sess_1","status":"running"}',
              );
            }(),
            _ => throw StateError('unexpected synthetic route'),
          },
          post: (uri, headers, body) async => uri.path == '/v1/runs'
              ? '{"run_id":"run_1","session_id":"sess_1"}'
              : '{}',
          getStream: (uri, headers) => stream,
        ),
      );
      addTearDown(channel.dispose);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      final send = channel.sendText('Synthetic session race');
      await pumpEventQueue();
      final stopping = channel.stopTurn(channel.activeTurnInterruptionTarget!);
      await started.future;
      await channel.selectSession('sess_2');
      await channel.selectSession('sess_1');
      delayedStatus.complete(
        '{"run_id":"run_1","session_id":"sess_1","status":"cancelled"}',
      );
      expect(await stopping, isFalse);
      await send;
      expect(channel.state.hasUnreconciledRun, isTrue);
    },
  );

  test(
    'stop status after profile roundtrip cannot release current ownership',
    () async {
      final capabilities =
          jsonDecode(_profileCapabilitiesFixture) as Map<String, dynamic>;
      final runs =
          jsonDecode(_runsCapableCapabilitiesFixture) as Map<String, dynamic>;
      (capabilities['endpoints'] as Map).addAll(runs['endpoints'] as Map);
      (capabilities['features'] as Map).addAll(runs['features'] as Map);
      final statusStarted = Completer<void>();
      final releaseStatus = Completer<String>();
      final stream = _ManualStringStream();
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async => switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => jsonEncode(capabilities),
            '/api/profiles' => _profilesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            '/v1/runs/run_1' => () {
              if (!statusStarted.isCompleted) statusStarted.complete();
              return releaseStatus.future;
            }(),
            _ => throw StateError('unexpected synthetic route'),
          },
          post: (uri, headers, body) async => uri.path == '/v1/runs'
              ? '{"run_id":"run_1","session_id":"sess_1"}'
              : '{}',
          getStream: (uri, headers) => stream,
        ),
      );
      addTearDown(channel.dispose);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      final send = channel.sendText('Synthetic race');
      await pumpEventQueue();
      final stopping = channel.stopTurn(channel.activeTurnInterruptionTarget!);
      await statusStarted.future;
      await channel.selectProfile('coder');
      final returning = channel.selectProfile('default');
      releaseStatus.complete(
        '{"run_id":"run_1","session_id":"sess_1","status":"cancelled"}',
      );
      expect(await stopping, isFalse);
      await returning;
      await send;
      expect(channel.state.selectedProfileId, 'default');
    },
  );
}
