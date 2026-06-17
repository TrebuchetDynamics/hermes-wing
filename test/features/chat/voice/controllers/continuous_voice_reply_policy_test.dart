import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/voice/controllers/continuous_voice_reply_policy.dart';

NavivoxChatMessage _assistant(
  String id,
  String text, {
  String serverId = 'local',
  String profileId = 'mineru',
}) {
  return NavivoxChatMessage(
    id: id,
    author: NavivoxMessageAuthor.assistant,
    kind: NavivoxMessageKind.text,
    createdAt: DateTime(2026, 6, 16, 12),
    text: text,
    serverId: serverId,
    profileId: profileId,
  );
}

NavivoxChatMessage _user(String id, String text) {
  return NavivoxChatMessage(
    id: id,
    author: NavivoxMessageAuthor.user,
    kind: NavivoxMessageKind.text,
    createdAt: DateTime(2026, 6, 16, 12),
    text: text,
    serverId: 'local',
    profileId: 'mineru',
  );
}

void main() {
  test('returns the newest unspoken assistant reply when enabled and complete', () {
    final reply = continuousVoiceReplyToSpeak(
      messages: [
        _user('u1', 'question'),
        _assistant('a1', 'first reply'),
        _assistant('a2', 'second reply'),
      ],
      activeProfileContactKey: 'local::mineru',
      enabled: true,
      turnComplete: true,
      lastSpokenMessageId: null,
    );

    expect(reply?.id, 'a2');
    expect(reply?.text, 'second reply');
  });

  test('returns null when auto-speak is disabled', () {
    final reply = continuousVoiceReplyToSpeak(
      messages: [_assistant('a1', 'reply')],
      activeProfileContactKey: 'local::mineru',
      enabled: false,
      turnComplete: true,
      lastSpokenMessageId: null,
    );

    expect(reply, isNull);
  });

  test('returns null while the turn is still streaming', () {
    final reply = continuousVoiceReplyToSpeak(
      messages: [_assistant('a1', 'partial')],
      activeProfileContactKey: 'local::mineru',
      enabled: true,
      turnComplete: false,
      lastSpokenMessageId: null,
    );

    expect(reply, isNull);
  });

  test('returns null when the newest reply was already spoken', () {
    final reply = continuousVoiceReplyToSpeak(
      messages: [_assistant('a1', 'reply')],
      activeProfileContactKey: 'local::mineru',
      enabled: true,
      turnComplete: true,
      lastSpokenMessageId: 'a1',
    );

    expect(reply, isNull);
  });

  test('ignores replies scoped to a different profile contact', () {
    final reply = continuousVoiceReplyToSpeak(
      messages: [
        _assistant('a1', 'for other', profileId: 'support'),
      ],
      activeProfileContactKey: 'local::mineru',
      enabled: true,
      turnComplete: true,
      lastSpokenMessageId: null,
    );

    expect(reply, isNull);
  });

  test('ignores non-assistant and non-text messages', () {
    final reply = continuousVoiceReplyToSpeak(
      messages: [
        _user('u1', 'hello'),
        NavivoxChatMessage(
          id: 's1',
          author: NavivoxMessageAuthor.system,
          kind: NavivoxMessageKind.text,
          createdAt: DateTime(2026, 6, 16, 12),
          text: 'system note',
          serverId: 'local',
          profileId: 'mineru',
        ),
      ],
      activeProfileContactKey: 'local::mineru',
      enabled: true,
      turnComplete: true,
      lastSpokenMessageId: null,
    );

    expect(reply, isNull);
  });
}
