import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/features/hermes_chat/voice/hermes_continuous_voice_reply_policy.dart';

HermesChatTurn _assistant(
  String id,
  String text, {
  HermesTurnStatus status = HermesTurnStatus.completed,
}) {
  return HermesChatTurn(
    id: id,
    sessionId: 'sess_1',
    author: HermesTurnAuthor.assistant,
    createdAt: DateTime(2026, 6, 16, 12),
    status: status,
    text: text,
  );
}

HermesChatTurn _user(String id, String text) {
  return HermesChatTurn(
    id: id,
    sessionId: 'sess_1',
    author: HermesTurnAuthor.user,
    createdAt: DateTime(2026, 6, 16, 12),
    text: text,
  );
}

void main() {
  test(
    'returns the newest unspoken completed assistant reply when enabled',
    () {
      final reply = hermesContinuousVoiceReplyToSpeak(
        turns: [
          _user('u1', 'question'),
          _assistant('a1', 'first reply'),
          _assistant('a2', 'second reply'),
        ],
        enabled: true,
        lastSpokenTurnId: null,
      );

      expect(reply?.id, 'a2');
      expect(reply?.text, 'second reply');
    },
  );

  test('returns null when auto-speak is disabled', () {
    final reply = hermesContinuousVoiceReplyToSpeak(
      turns: [_assistant('a1', 'reply')],
      enabled: false,
      lastSpokenTurnId: null,
    );

    expect(reply, isNull);
  });

  test('returns null while the newest assistant turn is still streaming', () {
    final reply = hermesContinuousVoiceReplyToSpeak(
      turns: [
        _assistant('a1', 'old reply'),
        _user('u2', 'new question'),
        _assistant('a2', 'partial', status: HermesTurnStatus.streaming),
      ],
      enabled: true,
      lastSpokenTurnId: null,
    );

    expect(reply, isNull);
  });

  test('returns a complete sentence while the assistant is streaming', () {
    final chunk = hermesContinuousVoiceReplyChunkToSpeak(
      turns: [
        _assistant(
          'a1',
          'First sentence. Second sentence is still arriving',
          status: HermesTurnStatus.streaming,
        ),
      ],
      enabled: true,
      spokenTurnId: null,
      spokenCharacterCount: 0,
    );

    expect(chunk?.turn.id, 'a1');
    expect(chunk?.text, 'First sentence.');
    expect(chunk?.spokenCharacterCount, 15);
  });

  test('returns only newly completed streaming sentences', () {
    final chunk = hermesContinuousVoiceReplyChunkToSpeak(
      turns: [
        _assistant(
          'a1',
          'First sentence. Second sentence! Third is partial',
          status: HermesTurnStatus.streaming,
        ),
      ],
      enabled: true,
      spokenTurnId: 'a1',
      spokenCharacterCount: 15,
    );

    expect(chunk?.text, 'Second sentence!');
    expect(chunk?.spokenCharacterCount, 32);
  });

  test('waits when a streaming reply has no complete new sentence', () {
    final chunk = hermesContinuousVoiceReplyChunkToSpeak(
      turns: [
        _assistant(
          'a1',
          'First sentence. Second sentence is still arriving',
          status: HermesTurnStatus.streaming,
        ),
      ],
      enabled: true,
      spokenTurnId: 'a1',
      spokenCharacterCount: 15,
    );

    expect(chunk, isNull);
  });

  test('returns the unfinished tail after Hermes completes the reply', () {
    final chunk = hermesContinuousVoiceReplyChunkToSpeak(
      turns: [_assistant('a1', 'First sentence. Final tail')],
      enabled: true,
      spokenTurnId: 'a1',
      spokenCharacterCount: 15,
    );

    expect(chunk?.text, 'Final tail');
    expect(chunk?.spokenCharacterCount, 26);
  });

  test('reconciles a rewritten canonical prefix before speaking its tail', () {
    final chunk = hermesContinuousVoiceReplyChunkToSpeak(
      turns: [_assistant('a1', 'Answer: 10. Tail')],
      enabled: true,
      spokenTurnId: 'a1',
      spokenCharacterCount: 13,
      spokenText: 'Answer is 10.',
    );

    expect(chunk?.text, 'Tail');
  });

  test('finishes a completed pre-tool tail before a newer empty segment', () {
    final turns = [
      _assistant('a1', 'First sentence. Pre-tool tail'),
      _assistant('a2', '', status: HermesTurnStatus.streaming),
    ];
    final chunk = hermesContinuousVoiceReplyChunkToSpeak(
      turns: turns,
      enabled: true,
      spokenTurnId: 'a1',
      spokenCharacterCount: 15,
      spokenText: 'First sentence.',
    );

    expect(chunk?.turn.id, 'a1');
    expect(chunk?.text, 'Pre-tool tail');

    final next = hermesContinuousVoiceReplyChunkToSpeak(
      turns: [
        turns.first,
        _assistant('a2', 'After tool.', status: HermesTurnStatus.streaming),
      ],
      enabled: true,
      spokenTurnId: 'a1',
      spokenCharacterCount: turns.first.text.length,
      spokenText: turns.first.text,
    );

    expect(next?.turn.id, 'a2');
    expect(next?.text, 'After tool.');
  });

  test('does not advance when completed-tail reconciliation is ambiguous', () {
    final chunk = hermesContinuousVoiceReplyChunkToSpeak(
      turns: [
        _assistant('a1', 'Canonical rewrite with no matching anchor'),
        _assistant('a2', 'After tool.', status: HermesTurnStatus.streaming),
      ],
      enabled: true,
      spokenTurnId: 'a1',
      spokenCharacterCount: 15,
      spokenText: 'Streamed prefix.',
    );

    expect(chunk, isNull);
  });

  test('returns null when the newest reply was already spoken', () {
    final reply = hermesContinuousVoiceReplyToSpeak(
      turns: [_assistant('a1', 'reply')],
      enabled: true,
      lastSpokenTurnId: 'a1',
    );

    expect(reply, isNull);
  });

  test('ignores empty and non-assistant turns', () {
    final reply = hermesContinuousVoiceReplyToSpeak(
      turns: [_user('u1', 'hello'), _assistant('a1', '   ')],
      enabled: true,
      lastSpokenTurnId: null,
    );

    expect(reply, isNull);
  });
}
