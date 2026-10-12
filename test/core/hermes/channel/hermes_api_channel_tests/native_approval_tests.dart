part of '../hermes_api_channel_test.dart';

void _hermesApiChannelNativeApprovalTests() {
  for (final terminal in [false, true]) {
    for (final delayedAnswer in [false, true]) {
      test(
        '${terminal ? 'terminal run' : 'externally settled approval'} retires production queue and response ownership (delayed=$delayedAnswer)',
        () async {
          final stream = _ManualStringStream();
          var approvalPosts = 0;
          final answerGate = Completer<String>();
          final channel = HermesApiChannel(
            clientBuilder: (config) => HermesApiClient(
              config: config,
              get: (uri, headers) async => switch (uri.path) {
                '/health' => '{"status":"ok"}',
                '/v1/capabilities' => _runsCapableCapabilitiesFixture,
                '/api/sessions' => _sessionsFixture,
                '/api/sessions/sess_1/messages' => _messagesFixture,
                '/v1/runs/run_1' =>
                  '{"run_id":"run_1","session_id":"sess_1","status":"completed"}',
                _ => throw StateError('unexpected synthetic read'),
              },
              post: (uri, headers, body) async {
                if (uri.path == '/v1/runs') {
                  return '{"run_id":"run_1","session_id":"sess_1","status":"queued"}';
                }
                approvalPosts++;
                return answerGate.future;
              },
              getStream: (uri, headers) => stream,
            ),
          );
          addTearDown(channel.dispose);
          final errors = <Object>[];
          final queue = HermesApprovalQueue(
            channel: () => channel,
            onResolveError: errors.add,
          );
          addTearDown(queue.dispose);
          queue.watch(channel);
          await channel.connect(baseUrl: 'http://127.0.0.1:8642');
          final send = channel.sendText('Synthetic approval settlement');
          await pumpEventQueue();
          stream.emit(
            'event: approval.request\ndata: {"request_id":"a","run_id":"run_1","session_id":"sess_1"}\n\n',
          );
          await pumpEventQueue();
          final origin = queue.pending.single;
          final answer = delayedAnswer
              ? queue.resolve(HermesApprovalDecision.once, origin)
              : null;
          await pumpEventQueue();
          stream.emit(
            terminal
                ? 'event: run.completed\ndata: {"run_id":"run_1","session_id":"sess_1","status":"completed"}\n\n'
                : 'event: approval.responded\ndata: {"request_id":"a","run_id":"run_1","session_id":"sess_1","resolved":1,"choice":"once"}\n\n',
          );
          await pumpEventQueue();
          expect(queue.pending, isEmpty);
          if (answer != null) {
            answerGate.completeError(const _TestHermesStatusException(409));
            await answer;
          }
          expect(channel.state.errorMessage, isNull);
          await queue.resolve(HermesApprovalDecision.once, origin);
          await expectLater(
            channel.respondToApproval(
              approvalId: origin.id,
              runId: origin.runId,
              origin: origin,
              decision: HermesApprovalDecision.once,
            ),
            throwsStateError,
          );
          expect(approvalPosts, delayedAnswer ? 1 : 0);
          expect(errors, isEmpty);
          stream.emit(
            'event: run.completed\ndata: {"run_id":"run_1","session_id":"sess_1","status":"completed"}\n\n',
          );
          await send;
        },
      );
    }
  }
  test(
    'reattached replay retires settled approval while retaining the live request',
    () async {
      final store = _MemoryDetachedRunStore()
        ..leases = [
          HermesDetachedRunLease(
            runId: 'run_1',
            sessionId: 'sess_1',
            baseUrl: 'http://127.0.0.1:8642',
            createdAt: DateTime.now().toUtc(),
          ),
        ];
      final stream = _ManualStringStream();
      var writes = 0;
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
              '{"run_id":"run_1","session_id":"sess_1","status":"running"}',
            _ => throw StateError('unexpected synthetic read'),
          },
          post: (uri, headers, body) async {
            writes++;
            return '{}';
          },
          getStream: (uri, headers) => stream,
        ),
      );
      addTearDown(channel.dispose);
      final queue = HermesApprovalQueue(
        channel: () => channel,
        onResolveError: (error) => fail('$error'),
      );
      addTearDown(queue.dispose);
      queue.watch(channel);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      await pumpEventQueue();
      stream.emit(
        'event: approval.request\ndata: {"request_id":"settled","run_id":"run_1","session_id":"sess_1"}\n\n'
        'event: approval.request\ndata: {"request_id":"live","run_id":"run_1","session_id":"sess_1"}\n\n',
      );
      await pumpEventQueue();
      final settled = queue.pending.first;
      final live = queue.pending.last;
      stream.emit(
        'event: approval.responded\ndata: {"request_id":"live","run_id":"wrong","session_id":"sess_1"}\n\n'
        'event: approval.responded\ndata: {"request_id":"live","run_id":"run_1","session_id":"wrong"}\n\n'
        'event: approval.responded\ndata: {"run_id":"run_1","session_id":"sess_1","resolved":1}\n\n',
      );
      await pumpEventQueue();
      expect(queue.pending, [settled, live]);
      stream.emit(
        'event: approval.responded\ndata: {"request_id":"settled","run_id":"run_1","session_id":"sess_1"}\n\n'
        'event: message.delta\ndata: {"run_id":"run_1","session_id":"sess_1","delta":"continuing"}\n\n',
      );
      await pumpEventQueue();
      expect(queue.pending, [live]);
      expect(channel.state.activeMessages.last.text, contains('continuing'));
      await queue.resolve(HermesApprovalDecision.once, settled);
      expect(writes, 0);
      stream.emit(
        'event: run.completed\ndata: {"run_id":"run_1","session_id":"sess_1","status":"completed"}\n\n',
      );
      await pumpEventQueue();
      expect(queue.pending, isEmpty);
      expect(writes, 0);
    },
  );
  test('legacy turns do not retain same-key approval display content', () async {
    var turn = 0;
    final requests = <HermesApprovalRequest>[];
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async => switch (uri.path) {
          '/health' => '{"status":"ok"}',
          '/v1/capabilities' => _capabilitiesFixture,
          '/api/sessions' => _sessionsFixture,
          '/api/sessions/sess_1/messages' => _messagesFixture,
          _ => throw StateError('unexpected synthetic read'),
        },
        postStream: (uri, headers, body) => Stream.fromIterable([
          'event: approval.request\ndata: {"request_id":"legacy","prompt":"Synthetic turn ${++turn}"}\n\n',
          'event: assistant.delta\ndata: {"delta":"Synthetic reply"}\n\n',
          'event: done\n\n',
        ]),
      ),
    );
    addTearDown(channel.dispose);
    channel.approvalRequests.listen(requests.add);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    await channel.sendText('Synthetic first turn');
    await pumpEventQueue();
    await channel.sendText('Synthetic second turn');
    await pumpEventQueue();
    expect(requests, hasLength(2));
    expect(requests.last.runId, isNull);
    expect(requests.last.prompt, 'Synthetic turn 2');
    expect(identical(requests.first, requests.last), isFalse);
  });
  for (final decision in [
    HermesApprovalDecision.once,
    HermesApprovalDecision.deny,
  ]) {
    test(
      'native approval request_id correlates ${decision.name} without FIFO or replay',
      () async {
        final stream = _ManualStringStream();
        final requests = <HermesApprovalRequest>[];
        final answers = <Map<String, Object?>>[];
        final resolved = <String>[];
        final pending = <String>['native_old'];
        final answerStarted = Completer<void>();
        final releaseAnswer = Completer<void>();
        final channel = HermesApiChannel(
          clientBuilder: (config) => HermesApiClient(
            config: config,
            get: (uri, headers) async => switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              '/v1/runs/run_1' =>
                '{"run_id":"run_1","session_id":"sess_1","status":"completed"}',
              _ => throw StateError('unexpected synthetic read'),
            },
            post: (uri, headers, body) async {
              if (uri.path == '/v1/runs') {
                return '{"run_id":"run_1","session_id":"sess_1","status":"queued"}';
              }
              expect(uri.path, '/v1/runs/run_1/approval');
              final answer = jsonDecode(body) as Map<String, Object?>;
              answers.add(answer);
              // Mirror Agent's exact-ID resolver, including the legacy FIFO path.
              final id = answer['request_id'] as String?;
              final target = id ?? pending.first;
              if (!pending.remove(target)) {
                throw const _TestHermesStatusException(409);
              }
              resolved.add(target);
              answerStarted.complete();
              await releaseAnswer.future;
              return jsonEncode({
                'request_id': target,
                'choice': answer['choice'],
              });
            },
            getStream: (uri, headers) => stream,
          ),
        );
        addTearDown(channel.dispose);
        channel.approvalRequests.listen(requests.add);
        await channel.connect(baseUrl: 'http://127.0.0.1:8642');
        final send = channel.sendText('Synthetic native approval prompt');
        await pumpEventQueue();
        void emit(String id) => stream.emit(
          'event: approval.request\ndata: ${jsonEncode({
            'request_id': id,
            'approval_id': 'legacy_alias',
            'run_id': 'run_1',
            'session_id': 'sess_1',
            'choices': ['once', 'deny'],
          })}\n\n',
        );
        emit('native_old');
        await pumpEventQueue();
        final old = requests.single;
        expect(old.id, 'native_old');
        // Agent expires/replaces A while the run remains active with B pending.
        pending
          ..clear()
          ..add('native_current');
        emit('native_current');
        await pumpEventQueue();
        final current = requests.last;
        expect(current.id, 'native_current');
        Future<void> respond(HermesApprovalRequest origin) =>
            channel.respondToApproval(
              approvalId: origin.id,
              runId: origin.runId,
              origin: origin,
              decision: decision,
            );
        await expectLater(
          respond(old),
          throwsA(isA<_TestHermesStatusException>()),
        );
        expect(
          resolved,
          isEmpty,
          reason: 'stale exact ID must not answer current FIFO entry',
        );
        expect(pending, ['native_current']);
        final answer = respond(current);
        await answerStarted.future;
        await expectLater(respond(current), throwsStateError);
        expect(answers, [
          {'request_id': 'native_old', 'choice': decision.name},
          {'request_id': 'native_current', 'choice': decision.name},
        ]);
        releaseAnswer.complete();
        await answer;
        await expectLater(respond(current), throwsStateError);
        expect(resolved, ['native_current']);
        stream.emit(
          'event: run.completed\ndata: {"run_id":"run_1","session_id":"sess_1","status":"completed"}\n\n',
        );
        await send;
        await channel.connect(baseUrl: 'http://127.0.0.1:8642');
        await expectLater(respond(current), throwsStateError);
        expect(
          answers,
          hasLength(2),
          reason: 'completion/reconnect must not replay approvals',
        );
        expect(channel.state.activeSessionId, 'sess_1');
      },
    );
  }
}
