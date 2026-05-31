import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/transcript/presentation/transcript_message_plain_text_presentation.dart';

import '../../shared/transcript_test_fixtures.dart';
import '../shared/transcript_message_text_projection_cases.dart';

void main() {
  test('projects transcript messages into shared plain text cases', () {
    for (final testCase in transcriptMessageTextProjectionCases()) {
      final presentation = TranscriptMessagePlainTextPresentation.fromMessage(
        testCase.message,
      );

      expect(
        presentation.text,
        testCase.expectedText,
        reason: testCase.description,
      );
      expect(presentation.hasText, isTrue, reason: testCase.description);
    }
  });

  test('omits empty optional lines and exposes empty state', () {
    final tool = TranscriptMessagePlainTextPresentation.fromMessage(
      transcriptToolMessage(
        toolCall: transcriptToolCall(name: '', status: '', summary: ''),
      ),
    );
    final missingVoice = TranscriptMessagePlainTextPresentation.fromMessage(
      transcriptChatMessage(kind: NavivoxMessageKind.voice),
    );
    final notice = TranscriptMessagePlainTextPresentation.fromMessage(
      transcriptNoticeMessage(
        kind: NavivoxMessageKind.safetyWarning,
        notice: transcriptSafetyNotice(id: 'safety-2', message: ''),
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
