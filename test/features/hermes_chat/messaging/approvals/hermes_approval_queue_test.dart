import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/features/hermes_chat/messaging/approvals/hermes_approval_queue.dart';

import '../../support/fake_hermes_channel.dart';

HermesApprovalRequest _request({
  String id = 'approval-1',
  String toolCallId = 'tool-1',
  String prompt = 'Run the deploy script?',
  String? sessionId,
  String? runId,
  String? profileId,
  int? connectionGeneration,
}) => HermesApprovalRequest(
  id: id,
  toolCallId: toolCallId,
  prompt: prompt,
  runId: runId,
  sessionId: sessionId,
  profileId: profileId,
  connectionGeneration: connectionGeneration,
);

void main() {
  late FakeHermesChannel channel;
  late List<Object> errors;
  late HermesApprovalQueue queue;

  void build({FakeHermesChannel? withChannel}) {
    channel = withChannel ?? FakeHermesChannel();
    errors = [];
    queue = HermesApprovalQueue(
      channel: () => channel,
      onResolveError: errors.add,
    );
    addTearDown(queue.dispose);
  }

  test('stopped-turn dismissal preserves other approval owners', () {
    build();
    final matching = _request(
      id: 'match',
      runId: 'run',
      sessionId: 'session',
      profileId: 'profile',
      connectionGeneration: 1,
    );
    final others = [
      _request(
        id: 'other-run',
        runId: 'other',
        sessionId: 'session',
        profileId: 'profile',
        connectionGeneration: 1,
      ),
      _request(
        id: 'other-session',
        runId: 'run',
        sessionId: 'other',
        profileId: 'profile',
        connectionGeneration: 1,
      ),
      _request(
        id: 'other-profile',
        runId: 'run',
        sessionId: 'session',
        profileId: 'other',
        connectionGeneration: 1,
      ),
      _request(
        id: 'other-connection',
        runId: 'run',
        sessionId: 'session',
        profileId: 'profile',
        connectionGeneration: 2,
      ),
    ];
    for (final request in [matching, ...others]) {
      queue.add(request);
    }
    HermesTurnInterruptionTarget target(Object owner) =>
        HermesTurnInterruptionTarget(
          owner: owner,
          connectionGeneration: 1,
          profileId: 'profile',
          sessionId: 'session',
          streamGeneration: 1,
          runId: 'run',
        );
    queue.dismissStoppedTurn(target(Object()));
    expect(queue.pending.length, 5);
    queue.dismissStoppedTurn(target(channel));
    expect(queue.pending, others);
    expect(channel.respondToApprovalCalls, isEmpty);
  });

  test('stopping an answered run ignores its late failure', () async {
    final gate = Completer<void>();
    build(
      withChannel: FakeHermesChannel(approvalResponseGate: () => gate.future),
    );
    final request = _request(
      runId: 'run',
      sessionId: 'session',
      connectionGeneration: 1,
    );
    queue.add(request);
    final answer = queue.resolve(HermesApprovalDecision.once, request);
    queue.dismissStoppedTurn(
      HermesTurnInterruptionTarget(
        owner: channel,
        connectionGeneration: 1,
        profileId: null,
        sessionId: 'session',
        streamGeneration: 1,
        runId: 'run',
      ),
    );
    gate.completeError(StateError('stopped response'));
    await answer;
    expect(queue.pending, isEmpty);
    expect(queue.answeringId, isNull);
    expect(errors, isEmpty);
  });

  test('queues distinct approvals and reports outstanding work', () {
    build();
    expect(queue.hasPendingWork, isFalse);

    queue.add(_request(id: 'a', toolCallId: 't-a'));
    queue.add(_request(id: 'b', toolCallId: 't-b'));

    expect(queue.pending.map((r) => r.id), ['a', 'b']);
    expect(queue.hasPendingWork, isTrue);
  });

  test('old approval failure cannot affect replacement queue', () async {
    final gate = Completer<void>();
    build(
      withChannel: FakeHermesChannel(approvalResponseGate: () => gate.future),
    );
    final request = _request(id: 'same');
    queue.add(request);
    final old = queue.resolve(HermesApprovalDecision.once, request);
    queue.reset();
    queue.add(request);
    gate.completeError(StateError('obsolete response'));
    await old;
    expect(queue.pending, [request]);
    expect(errors, isEmpty);
  });

  test('a replayed approval is not queued twice', () {
    build();
    queue.add(_request(id: 'a'));
    queue.add(_request(id: 'a'));

    expect(queue.pending, hasLength(1));
  });

  test('run-id approvals dedupe on connection, profile, session, and run', () {
    build();
    final first = _request(
      id: '',
      toolCallId: '',
      prompt: 'Approve?',
      connectionGeneration: 1,
      profileId: 'alpha',
      sessionId: 'session-1',
      runId: 'run-1',
    );
    queue.add(first);
    queue.add(first);
    queue.add(
      _request(
        id: '',
        toolCallId: '',
        prompt: 'Approve?',
        connectionGeneration: 1,
        profileId: 'alpha',
        sessionId: 'session-1',
        runId: 'run-2',
      ),
    );
    queue.add(
      _request(
        id: '',
        toolCallId: '',
        prompt: 'Approve?',
        connectionGeneration: 1,
        profileId: 'beta',
        sessionId: 'session-1',
        runId: 'run-1',
      ),
    );
    queue.add(
      _request(
        id: '',
        toolCallId: '',
        prompt: 'Approve?',
        connectionGeneration: 2,
        profileId: 'alpha',
        sessionId: 'session-1',
        runId: 'run-1',
      ),
    );

    expect(queue.pending, hasLength(4));
  });

  test('identity falls back to tool call then prompt', () {
    build();
    queue.add(_request(id: '  ', toolCallId: 'tool-x', prompt: 'first'));
    queue.add(_request(id: '', toolCallId: 'tool-x', prompt: 'second'));
    expect(queue.pending, hasLength(1), reason: 'same tool call is one ask');

    queue.add(_request(id: '', toolCallId: '', prompt: 'unique prompt'));
    queue.add(_request(id: '', toolCallId: '', prompt: 'unique prompt'));
    expect(queue.pending, hasLength(2), reason: 'prompt is the last resort');
  });

  test('activeFor keeps session-less approvals and the active session', () {
    build();
    queue.add(_request(id: 'global', toolCallId: 't1'));
    queue.add(_request(id: 'here', toolCallId: 't2', sessionId: 'session-1'));
    queue.add(_request(id: 'other', toolCallId: 't3', sessionId: 'session-2'));

    expect(queue.activeFor('session-1').map((r) => r.id), ['global', 'here']);
    expect(queue.activeFor(null).map((r) => r.id), ['global']);
  });

  test('resolving answers Hermes and drops the approval', () async {
    build();
    final request = _request(id: 'a');
    queue.add(request);

    await queue.resolve(HermesApprovalDecision.once, request);

    expect(channel.respondToApprovalCalls.single['approvalId'], 'a');
    expect(
      channel.respondToApprovalCalls.single['decision'],
      HermesApprovalDecision.once,
    );
    expect(queue.pending, isEmpty);
    expect(queue.answeringId, isNull);
    expect(errors, isEmpty);
  });

  test('a decision omitted by Agent choices is never sent', () async {
    build();
    const request = HermesApprovalRequest(
      id: '',
      toolCallId: '',
      prompt: 'Approve?',
      choices: {HermesApprovalDecision.once, HermesApprovalDecision.deny},
      runId: 'run-1',
    );
    queue.add(request);

    await queue.resolve(HermesApprovalDecision.always, request);

    expect(channel.respondToApprovalCalls, isEmpty);
    expect(queue.pending, [request]);
  });

  test('a second decision is ignored while one is in flight', () async {
    final gate = Completer<void>();
    build(
      withChannel: FakeHermesChannel(approvalResponseGate: () => gate.future),
    );
    final request = _request(id: 'a');
    queue.add(request);

    final first = queue.resolve(HermesApprovalDecision.once, request);
    await queue.resolve(HermesApprovalDecision.deny, request);
    expect(queue.answeringId, request.identityKey);
    expect(channel.respondToApprovalCalls, hasLength(1));

    gate.complete();
    await first;
    expect(queue.pending, isEmpty);
  });

  test(
    'a failed answer clears the in-flight id and reports the error',
    () async {
      build(withChannel: FakeHermesChannel(approvalResponsesFail: true));
      final request = _request(id: 'a');
      queue.add(request);

      await queue.resolve(HermesApprovalDecision.once, request);

      expect(queue.answeringId, isNull);
      expect(queue.pending, hasLength(1), reason: 'an unanswered ask stays');
      expect(errors, hasLength(1));
    },
  );

  test('an approval without an id uses its run identity', () async {
    build();
    final request = _request(id: '   ', toolCallId: 't1', runId: 'run-1');
    queue.add(request);

    await queue.resolve(HermesApprovalDecision.once, request);

    expect(channel.respondToApprovalCalls.single['approvalId'], isEmpty);
    expect(channel.respondToApprovalCalls.single['runId'], 'run-1');
    expect(queue.pending, isEmpty);
  });

  test('an approval without an id or run identity is never sent', () async {
    build();
    final request = _request(id: '   ', toolCallId: 't1');
    queue.add(request);

    await queue.resolve(HermesApprovalDecision.once, request);

    expect(channel.respondToApprovalCalls, isEmpty);
    expect(queue.pending, hasLength(1));
  });

  test('an approval that is no longer queued is never sent', () async {
    build();
    await queue.resolve(HermesApprovalDecision.once, _request(id: 'ghost'));

    expect(channel.respondToApprovalCalls, isEmpty);
  });

  test('dismiss drops the approval without answering Hermes', () {
    build();
    final request = _request(id: 'a');
    queue.add(request);

    queue.dismiss(request);

    expect(queue.pending, isEmpty);
    expect(channel.respondToApprovalCalls, isEmpty);
  });

  test('watch drops the previous gateway queue and follows the new stream', () {
    build();
    queue.add(_request(id: 'stale'));

    final next = FakeHermesChannel();
    addTearDown(next.dispose);
    queue.watch(next);

    expect(queue.pending, isEmpty, reason: 'a new gateway starts clean');
  });

  test('reset clears the answer, clearPending keeps it', () async {
    final gate = Completer<void>();
    build(
      withChannel: FakeHermesChannel(approvalResponseGate: () => gate.future),
    );
    final request = _request(id: 'a');
    queue.add(request);
    unawaited(queue.resolve(HermesApprovalDecision.once, request));
    expect(queue.answeringId, request.identityKey);

    queue.clearPending();
    expect(queue.pending, isEmpty);
    expect(
      queue.answeringId,
      request.identityKey,
      reason: 'an in-flight answer is tracked',
    );

    queue.reset();
    expect(queue.answeringId, isNull);

    gate.complete();
  });

  test('a late stream event after dispose is ignored', () {
    build();
    queue.dispose();

    queue.add(_request(id: 'late'));

    expect(queue.pending, isEmpty);
  });
}
