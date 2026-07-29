import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/features/hermes_chat/controllers/hermes_approval_queue.dart';

import '../support/fake_hermes_channel.dart';

HermesApprovalRequest _request({
  String id = 'approval-1',
  String toolCallId = 'tool-1',
  String prompt = 'Run the deploy script?',
  String? sessionId,
}) => HermesApprovalRequest(
  id: id,
  toolCallId: toolCallId,
  prompt: prompt,
  sessionId: sessionId,
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

  test('queues distinct approvals and reports outstanding work', () {
    build();
    expect(queue.hasPendingWork, isFalse);

    queue.add(_request(id: 'a', toolCallId: 't-a'));
    queue.add(_request(id: 'b', toolCallId: 't-b'));

    expect(queue.pending.map((r) => r.id), ['a', 'b']);
    expect(queue.hasPendingWork, isTrue);
  });

  test('a replayed approval is not queued twice', () {
    build();
    queue.add(_request(id: 'a'));
    queue.add(_request(id: 'a'));

    expect(queue.pending, hasLength(1));
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

  test('a second decision is ignored while one is in flight', () async {
    final gate = Completer<void>();
    build(
      withChannel: FakeHermesChannel(approvalResponseGate: () => gate.future),
    );
    final request = _request(id: 'a');
    queue.add(request);

    final first = queue.resolve(HermesApprovalDecision.once, request);
    await queue.resolve(HermesApprovalDecision.deny, request);
    expect(queue.answeringId, 'a');
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

  test('an approval without an id is never sent', () async {
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
    expect(queue.answeringId, 'a');

    queue.clearPending();
    expect(queue.pending, isEmpty);
    expect(queue.answeringId, 'a', reason: 'an in-flight answer is tracked');

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
