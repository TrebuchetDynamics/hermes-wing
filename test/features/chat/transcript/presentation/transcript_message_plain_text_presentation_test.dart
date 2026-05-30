import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/transcript/presentation/transcript_message_plain_text_presentation.dart';

void main() {
  test('projects text and Voice run messages into plain text', () {
    final text = TranscriptMessagePlainTextPresentation.fromMessage(
      _textMessage('copy this'),
    );
    final voice = TranscriptMessagePlainTextPresentation.fromMessage(
      _voiceMessage('captured voice'),
    );

    expect(text.text, 'copy this');
    expect(text.hasText, isTrue);
    expect(voice.text, 'captured voice');
    expect(voice.hasText, isTrue);
  });

  test('projects tool cards into name, status, and summary lines', () {
    final presentation = TranscriptMessagePlainTextPresentation.fromMessage(
      _toolMessage(
        const NavivoxToolCall(
          name: 'grep',
          status: 'finished',
          summary: 'Matched 2 files',
        ),
      ),
    );

    expect(presentation.text, 'grep\nfinished\nMatched 2 files');
    expect(presentation.hasText, isTrue);
  });

  test('projects safety and approval notices into message and risk lines', () {
    final safety = TranscriptMessagePlainTextPresentation.fromMessage(
      _noticeMessage(
        kind: NavivoxMessageKind.safetyWarning,
        notice: const NavivoxSafetyNotice(
          id: 'safety-1',
          message: 'Unsafe exposure',
          risk: 'Public gateway',
        ),
      ),
    );
    final approval = TranscriptMessagePlainTextPresentation.fromMessage(
      _noticeMessage(
        kind: NavivoxMessageKind.approvalRequest,
        notice: const NavivoxSafetyNotice(
          id: 'approval-1',
          message: 'Approve restart?',
          risk: 'Interrupts active run',
        ),
      ),
    );

    expect(safety.text, 'Unsafe exposure\nPublic gateway');
    expect(safety.hasText, isTrue);
    expect(approval.text, 'Approve restart?\nInterrupts active run');
    expect(approval.hasText, isTrue);
  });

  test('omits empty optional lines and exposes empty state', () {
    final tool = TranscriptMessagePlainTextPresentation.fromMessage(
      _toolMessage(const NavivoxToolCall(name: '', status: '', summary: '')),
    );
    final missingVoice = TranscriptMessagePlainTextPresentation.fromMessage(
      _chatMessage(kind: NavivoxMessageKind.voice),
    );
    final notice = TranscriptMessagePlainTextPresentation.fromMessage(
      _noticeMessage(
        kind: NavivoxMessageKind.safetyWarning,
        notice: const NavivoxSafetyNotice(id: 'safety-2', message: ''),
      ),
    );

    expect(tool.text, isEmpty);
    expect(tool.hasText, isFalse);
    expect(missingVoice.text, isEmpty);
    expect(missingVoice.hasText, isFalse);
    expect(notice.text, isEmpty);
    expect(notice.hasText, isFalse);
  });
}

NavivoxChatMessage _textMessage(String text) {
  return _chatMessage(kind: NavivoxMessageKind.text, text: text);
}

NavivoxChatMessage _voiceMessage(String transcript) {
  return _chatMessage(
    kind: NavivoxMessageKind.voice,
    voice: NavivoxVoiceMessage(
      duration: const Duration(seconds: 1),
      transcript: transcript,
      confidence: 0.9,
    ),
  );
}

NavivoxChatMessage _toolMessage(NavivoxToolCall toolCall) {
  return _chatMessage(kind: NavivoxMessageKind.toolCall, toolCall: toolCall);
}

NavivoxChatMessage _noticeMessage({
  required NavivoxMessageKind kind,
  required NavivoxSafetyNotice notice,
}) {
  return _chatMessage(kind: kind, safetyNotice: notice);
}

NavivoxChatMessage _chatMessage({
  required NavivoxMessageKind kind,
  String? text,
  NavivoxToolCall? toolCall,
  NavivoxVoiceMessage? voice,
  NavivoxSafetyNotice? safetyNotice,
}) {
  return NavivoxChatMessage(
    id: 'message-1',
    author: NavivoxMessageAuthor.assistant,
    kind: kind,
    createdAt: DateTime.utc(2026, 5, 23, 12, 6),
    text: text,
    toolCall: toolCall,
    voice: voice,
    safetyNotice: safetyNotice,
  );
}
