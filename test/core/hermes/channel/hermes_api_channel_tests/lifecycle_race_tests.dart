part of '../hermes_api_channel_test.dart';

void _hermesApiChannelLifecycleRaceTests() {
  test(
    'dispose cancels an active run stream and completes pending send',
    () async {
      final stream = _ManualStringStream();
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
          getStream: (uri, headers) => stream,
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      final send = channel.sendText('keep going');
      await pumpEventQueue();
      expect(stream.cancelCount, 0);

      channel.dispose();
      await send;
      stream.emit('event: message.delta\ndata: {"delta":"late"}\n\n');
      await pumpEventQueue();

      expect(stream.cancelCount, 1);
    },
  );

  test(
    'disconnect while run submission later fails keeps disconnected state empty',
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
            startRunStarted.complete();
            await releaseStartRun.future;
            throw StateError('late run submit failed');
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      final send = channel.sendText('slow run');
      await startRunStarted.future;
      await channel.disconnect();
      releaseStartRun.complete();
      await send;

      expect(channel.state.status, HermesConnectionStatus.disconnected);
      expect(channel.state.messages, isEmpty);
      expect(channel.state.errorMessage, isNull);
    },
  );

  test(
    'disconnect while run submission is pending prevents late run stream attach',
    () async {
      final startRunStarted = Completer<void>();
      final releaseStartRun = Completer<void>();
      final sendDone = Completer<void>();
      final stream = _ManualStringStream();
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
            return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
          },
          getStream: (uri, headers) {
            runEventsOpened = true;
            return stream;
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      unawaited(channel.sendText('slow run').whenComplete(sendDone.complete));
      await startRunStarted.future;
      await channel.disconnect();
      releaseStartRun.complete();
      await sendDone.future;
      stream.emit('event: message.delta\ndata: {"delta":"late"}\n\n');
      await pumpEventQueue();

      expect(runEventsOpened, isFalse);
      expect(channel.state.status, HermesConnectionStatus.disconnected);
      expect(channel.state.messages, isEmpty);
    },
  );

  test(
    'stale run submission cannot attach a run id to a newer connection',
    () async {
      final startRunStarted = Completer<void>();
      final releaseStartRun = Completer<void>();
      final sendDone = Completer<void>();
      final approvalPosts = <String>[];
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
              if (config.baseUri.port == 8642) {
                if (!startRunStarted.isCompleted) startRunStarted.complete();
                await releaseStartRun.future;
                return '{"object":"hermes.run","run":{"id":"old_run","session_id":"sess_1"}}';
              }
              return '{"object":"hermes.run","run":{"id":"new_run","session_id":"sess_1"}}';
            }
            approvalPosts.add(uri.path);
            return '{}';
          },
          getStream: (uri, headers) => const Stream<String>.empty(),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      unawaited(channel.sendText('slow run').whenComplete(sendDone.complete));
      await startRunStarted.future;
      await channel.connect(baseUrl: 'http://127.0.0.1:8643');
      releaseStartRun.complete();
      await sendDone.future;

      await expectLater(
        channel.respondToApproval(
          approvalId: 'appr_1',
          decision: HermesApprovalDecision.once,
        ),
        throwsA(isA<StateError>()),
      );
      expect(approvalPosts, isEmpty);
      expect(
        channel.state.errorMessage,
        'Could not answer approval: active run is no longer available.',
      );
    },
  );
}
