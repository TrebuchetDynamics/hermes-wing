import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/controllers/hermes_follow_up_queue.dart';

void main() {
  late HermesFollowUpQueue queue;

  setUp(() => queue = HermesFollowUpQueue(capacity: 3));

  QueuedFollowUp? take({
    String? activeSessionId = 'session-1',
    bool turnActive = false,
    bool canSendTurns = true,
  }) => queue.takeNextIfEligible(
    activeSessionId: activeSessionId,
    turnActive: turnActive,
    canSendTurns: canSendTurns,
  );

  group('capacity', () {
    test('accepts turns up to capacity and refuses beyond it', () {
      expect(queue.enqueue('one', 'session-1'), isTrue);
      expect(queue.enqueue('two', 'session-1'), isTrue);
      expect(queue.enqueue('three', 'session-1'), isTrue);
      expect(queue.isFull, isTrue);

      expect(queue.enqueue('four', 'session-1'), isFalse);
      expect(queue.length, 3);
      expect(
        queue.pending.map((q) => q.text),
        ['one', 'two', 'three'],
        reason: 'a refused turn must not displace an accepted one',
      );
    });

    test('enqueuing clears a stale error', () {
      queue.error = 'previous problem';

      queue.enqueue('one', 'session-1');

      expect(queue.error, isNull);
    });
  });

  group('send eligibility', () {
    test('sends in order once the session is idle and supported', () {
      queue.enqueue('one', 'session-1');
      queue.enqueue('two', 'session-1');

      expect(take()?.text, 'one');
      expect(take()?.text, 'two');
      expect(take(), isNull);
    });

    test('waits while a turn is still streaming', () {
      queue.enqueue('one', 'session-1');

      expect(take(turnActive: true), isNull);
      expect(queue.length, 1, reason: 'a blocked turn stays queued');
    });

    test('waits when the transport cannot send turns', () {
      queue.enqueue('one', 'session-1');

      expect(take(canSendTurns: false), isNull);
      expect(queue.length, 1);
    });

    test('parks a turn composed in another session', () {
      queue.enqueue('one', 'session-1');

      expect(
        take(activeSessionId: 'session-2'),
        isNull,
        reason: 'a follow-up must not be misdelivered to another session',
      );
      expect(queue.length, 1);
    });

    test('a session-less turn waits for a session-less view', () {
      queue.enqueue('one', null);

      expect(take(activeSessionId: 'session-1'), isNull);
      expect(take(activeSessionId: null)?.text, 'one');
    });
  });

  group('requeue after a failed send', () {
    test('returns the turn to the head so ordering survives', () {
      queue.enqueue('second', 'session-1');

      queue.requeueFailed('first', 'session-1', message: 'send failed');

      expect(queue.pending.map((q) => q.text), ['first', 'second']);
      expect(queue.error, 'send failed');
    });

    test('a full queue drops the retry but still reports it', () {
      queue.enqueue('a', 'session-1');
      queue.enqueue('b', 'session-1');
      queue.enqueue('c', 'session-1');

      queue.requeueFailed('lost', 'session-1', message: 'send failed');

      expect(queue.length, 3);
      expect(queue.pending.map((q) => q.text), ['a', 'b', 'c']);
      expect(
        queue.error,
        'send failed',
        reason: 'the operator must learn the send failed even when dropped',
      );
    });
  });

  group('session lifecycle', () {
    test('drops turns whose session disappeared', () {
      queue.enqueue('keep', 'session-1');
      queue.enqueue('drop', 'session-gone');
      queue.enqueue('global', null);

      queue.dropForMissingSessions({'session-1'});

      expect(queue.pending.map((q) => q.text), ['keep', 'global']);
    });

    test('canOpenNextSession only when it exists and is not already open', () {
      queue.enqueue('one', 'session-2');

      expect(
        queue.canOpenNextSession(
          activeSessionId: 'session-1',
          knownSessionIds: {'session-1', 'session-2'},
        ),
        isTrue,
      );
      expect(
        queue.canOpenNextSession(
          activeSessionId: 'session-2',
          knownSessionIds: {'session-2'},
        ),
        isFalse,
        reason: 'already open',
      );
      expect(
        queue.canOpenNextSession(
          activeSessionId: 'session-1',
          knownSessionIds: {'session-1'},
        ),
        isFalse,
        reason: 'session no longer exists',
      );
    });

    test('a session-less turn offers no session to open', () {
      queue.enqueue('one', null);

      expect(
        queue.canOpenNextSession(
          activeSessionId: 'session-1',
          knownSessionIds: {'session-1'},
        ),
        isFalse,
      );
    });
  });

  group('clearing', () {
    test('clear drops turns but keeps the error visible', () {
      queue.enqueue('one', 'session-1');
      queue.error = 'send failed';

      queue.clear();

      expect(queue.isEmpty, isTrue);
      expect(queue.error, 'send failed');
    });

    test('reset drops turns and the error', () {
      queue.enqueue('one', 'session-1');
      queue.error = 'send failed';

      queue.reset();

      expect(queue.isEmpty, isTrue);
      expect(queue.error, isNull);
    });
  });

  test('an empty queue exposes no next turn', () {
    expect(queue.next, isNull);
    expect(queue.isEmpty, isTrue);
    expect(take(), isNull);
  });
}
