part of '../hermes_api_channel_test.dart';

void _hermesApiChannelNativeApprovalTests() {
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
