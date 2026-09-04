import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/features/hermes_chat/controllers/hermes_channel_observation.dart';

HermesChatTurn _turn({
  required String id,
  required String sessionId,
  HermesTurnAuthor author = HermesTurnAuthor.assistant,
  HermesTurnStatus status = HermesTurnStatus.completed,
}) => HermesChatTurn(
  id: id,
  sessionId: sessionId,
  author: author,
  createdAt: DateTime.utc(2026, 7, 29),
  text: 'body',
  status: status,
);

HermesChannelState _state({
  String? activeSessionId = 'session-1',
  Map<String, List<HermesChatTurn>> messages = const {},
}) => HermesChannelState(activeSessionId: activeSessionId, messages: messages);

void main() {
  test('ambiguous missing and duplicate IDs never create completion edges', () {
    final observer = HermesChannelObservation()..adopt(_state());
    final result = observer.observe(
      _state(
        messages: {
          'session-1': [
            _turn(id: '', sessionId: 'session-1'),
            _turn(id: 'duplicate', sessionId: 'session-1'),
            _turn(id: 'duplicate', sessionId: 'session-1'),
          ],
        },
      ),
    );
    expect(result.completedReplyArrived, isFalse);
    expect(result.activeReplyCompleted, isFalse);
  });
  late HermesChannelObservation observation;

  setUp(() => observation = HermesChannelObservation());

  group('completed reply edge', () {
    test('a finished reply is reported once, not on every look', () {
      observation.adopt(_state());

      final withReply = _state(
        messages: {
          'session-1': [_turn(id: 'a', sessionId: 'session-1')],
        },
      );
      expect(observation.observe(withReply).completedReplyArrived, isTrue);
      expect(
        observation.observe(withReply).completedReplyArrived,
        isFalse,
        reason: 'the same reply must not refresh the contact repeatedly',
      );
    });

    test('a background completion reports its session exactly once', () {
      observation.adopt(
        _state(
          activeSessionId: 'session-1',
          messages: {
            'session-2': [
              _turn(
                id: 'background',
                sessionId: 'session-2',
                status: HermesTurnStatus.streaming,
              ),
            ],
          },
        ),
      );
      final completed = _state(
        activeSessionId: 'session-1',
        messages: {
          'session-2': [_turn(id: 'background', sessionId: 'session-2')],
        },
      );

      expect(observation.observe(completed).completedReplySessionIds, {
        'session-2',
      });
      expect(observation.observe(completed).completedReplySessionIds, isEmpty);
    });

    test('a second reply is a new edge', () {
      observation.adopt(_state());
      observation.observe(
        _state(
          messages: {
            'session-1': [_turn(id: 'a', sessionId: 'session-1')],
          },
        ),
      );

      final change = observation.observe(
        _state(
          messages: {
            'session-1': [
              _turn(id: 'a', sessionId: 'session-1'),
              _turn(id: 'b', sessionId: 'session-1'),
            ],
          },
        ),
      );

      expect(change.completedReplyArrived, isTrue);
    });

    test('a streaming reply is not a completed one', () {
      observation.adopt(_state());

      final change = observation.observe(
        _state(
          messages: {
            'session-1': [
              _turn(
                id: 'a',
                sessionId: 'session-1',
                status: HermesTurnStatus.streaming,
              ),
            ],
          },
        ),
      );

      expect(change.completedReplyArrived, isFalse);
    });

    test('a user turn is not a reply', () {
      observation.adopt(_state());

      final change = observation.observe(
        _state(
          messages: {
            'session-1': [
              _turn(
                id: 'a',
                sessionId: 'session-1',
                author: HermesTurnAuthor.user,
              ),
            ],
          },
        ),
      );

      expect(change.completedReplyArrived, isFalse);
    });

    test('losing every reply is not reported as one arriving', () {
      observation.adopt(
        _state(
          messages: {
            'session-1': [_turn(id: 'a', sessionId: 'session-1')],
          },
        ),
      );

      final change = observation.observe(_state());

      expect(
        change.completedReplyArrived,
        isFalse,
        reason: 'an emptied transcript is a change, but no reply arrived',
      );
    });
  });

  group('active session edge', () {
    test('the first look is not a session change', () {
      final change = observation.observe(_state(activeSessionId: 'session-1'));

      expect(
        change.activeSessionChanged,
        isFalse,
        reason: 'arriving at a session is not leaving one',
      );
    });

    test('moving to another session is reported once', () {
      observation.adopt(_state(activeSessionId: 'session-1'));

      expect(
        observation
            .observe(_state(activeSessionId: 'session-2'))
            .activeSessionChanged,
        isTrue,
      );
      expect(
        observation
            .observe(_state(activeSessionId: 'session-2'))
            .activeSessionChanged,
        isFalse,
      );
    });

    test('staying put is not a change', () {
      observation.adopt(_state(activeSessionId: 'session-1'));

      expect(
        observation
            .observe(_state(activeSessionId: 'session-1'))
            .activeSessionChanged,
        isFalse,
      );
    });

    test('losing the active session counts as leaving it', () {
      observation.adopt(_state(activeSessionId: 'session-1'));

      expect(
        observation.observe(_state(activeSessionId: null)).activeSessionChanged,
        isTrue,
      );
    });
  });

  group('baseline handling', () {
    test('adopt records without reporting a change', () {
      observation.adopt(
        _state(
          activeSessionId: 'session-1',
          messages: {
            'session-1': [_turn(id: 'a', sessionId: 'session-1')],
          },
        ),
      );

      final change = observation.observe(
        _state(
          activeSessionId: 'session-1',
          messages: {
            'session-1': [_turn(id: 'a', sessionId: 'session-1')],
          },
        ),
      );

      expect(change.completedReplyArrived, isFalse);
      expect(change.activeSessionChanged, isFalse);
    });

    test('reset makes the next look a fresh baseline', () {
      observation.adopt(_state(activeSessionId: 'session-1'));

      observation.reset();

      expect(
        observation
            .observe(_state(activeSessionId: 'session-2'))
            .activeSessionChanged,
        isFalse,
        reason: 'a reconnect starts over rather than reporting a stale move',
      );
    });
  });

  test('reply identity is order-independent but content-sensitive', () {
    final ascending = _state(
      messages: {
        'session-1': [
          _turn(id: 'a', sessionId: 'session-1'),
          _turn(id: 'b', sessionId: 'session-1'),
        ],
      },
    );
    final descending = _state(
      messages: {
        'session-1': [
          _turn(id: 'b', sessionId: 'session-1'),
          _turn(id: 'a', sessionId: 'session-1'),
        ],
      },
    );

    expect(
      HermesChannelObservation.completedReplySignature(ascending),
      HermesChannelObservation.completedReplySignature(descending),
      reason: 'reordering the same replies is not a new reply',
    );
    expect(
      HermesChannelObservation.completedReplySignature(ascending),
      isNot(
        HermesChannelObservation.completedReplySignature(
          _state(
            messages: {
              'session-1': [_turn(id: 'a', sessionId: 'session-1')],
            },
          ),
        ),
      ),
    );
  });

  test('replies in different sessions stay distinct', () {
    final here = _state(
      messages: {
        'session-1': [_turn(id: 'a', sessionId: 'session-1')],
      },
    );
    final elsewhere = _state(
      messages: {
        'session-2': [_turn(id: 'a', sessionId: 'session-2')],
      },
    );

    expect(
      HermesChannelObservation.completedReplySignature(here),
      isNot(HermesChannelObservation.completedReplySignature(elsewhere)),
      reason: 'the same reply id in another session is a different reply',
    );
  });
}
