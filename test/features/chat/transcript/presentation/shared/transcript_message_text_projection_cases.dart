import 'package:navivox/core/protocol/navivox_event.dart';

import '../../shared/transcript_test_fixtures.dart';

class TranscriptMessageTextProjectionCase {
  const TranscriptMessageTextProjectionCase({
    required this.description,
    required this.message,
    required this.expectedText,
  });

  final String description;
  final NavivoxChatMessage message;
  final String expectedText;
}

List<TranscriptMessageTextProjectionCase>
transcriptMessageTextProjectionCases() {
  return [
    TranscriptMessageTextProjectionCase(
      description: 'text message',
      message: transcriptTextMessage(text: 'copy this'),
      expectedText: 'copy this',
    ),
    TranscriptMessageTextProjectionCase(
      description: 'voice message',
      message: transcriptVoiceMessage(transcript: 'captured voice'),
      expectedText: 'captured voice',
    ),
    TranscriptMessageTextProjectionCase(
      description: 'tool message',
      message: transcriptToolMessage(toolCall: transcriptToolCall()),
      expectedText: 'grep\nfinished\nMatched 2 files',
    ),
    TranscriptMessageTextProjectionCase(
      description: 'safety notice',
      message: transcriptNoticeMessage(
        kind: NavivoxMessageKind.safetyWarning,
        notice: transcriptSafetyNotice(
          id: 'safety-1',
          message: 'Unsafe exposure',
          risk: 'Public gateway',
        ),
      ),
      expectedText: 'Unsafe exposure\nPublic gateway',
    ),
    TranscriptMessageTextProjectionCase(
      description: 'approval notice',
      message: transcriptNoticeMessage(
        kind: NavivoxMessageKind.approvalRequest,
        notice: transcriptApprovalNotice(
          id: 'approval-1',
          message: 'Approve restart?',
          risk: 'Interrupts active run',
        ),
      ),
      expectedText: 'Approve restart?\nInterrupts active run',
    ),
  ];
}
