import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/presentation/transcript/transcript_text_message_presentation.dart';

void main() {
  test('derives text message display state', () {
    final presentation = TranscriptTextMessagePresentation.fromMessage(
      _textMessage('hello profile contact'),
    );

    expect(presentation.text, 'hello profile contact');
    expect(presentation.hasText, isTrue);
  });

  test('preserves operator text exactly without trimming', () {
    final presentation = TranscriptTextMessagePresentation.fromMessage(
      _textMessage('  keep spacing  '),
    );

    expect(presentation.text, '  keep spacing  ');
    expect(presentation.hasText, isTrue);
  });

  test('normalizes missing text to empty display state', () {
    final presentation = TranscriptTextMessagePresentation.fromMessage(
      _textMessage(null),
    );

    expect(presentation.text, '');
    expect(presentation.hasText, isFalse);
  });
}

NavivoxChatMessage _textMessage(String? text) {
  return NavivoxChatMessage(
    id: 'text-1',
    author: NavivoxMessageAuthor.user,
    kind: NavivoxMessageKind.text,
    createdAt: DateTime.utc(2026, 5, 23, 12),
    text: text,
  );
}
