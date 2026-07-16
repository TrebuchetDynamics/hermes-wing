import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/features/hermes_chat/controllers/hermes_continuous_voice_reply_policy.dart';

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
      turns: [_assistant('a1', 'partial', status: HermesTurnStatus.streaming)],
      enabled: true,
      lastSpokenTurnId: null,
    );

    expect(reply, isNull);
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
