import '../../../../../core/protocol/navivox_event.dart';
import 'transcript_display_text.dart';

String transcriptPlainTextForMessage(NavivoxChatMessage message) {
  return switch (message.kind) {
    NavivoxMessageKind.text => message.text ?? '',
    NavivoxMessageKind.voice => message.voice?.transcript ?? '',
    NavivoxMessageKind.toolCall => transcriptJoinNonEmptyLines([
      message.toolCall?.name,
      message.toolCall?.status,
      message.toolCall?.summary,
    ]),
    NavivoxMessageKind.safetyWarning ||
    NavivoxMessageKind.approvalRequest => transcriptJoinNonEmptyLines([
      message.safetyNotice?.message,
      message.safetyNotice?.risk,
    ]),
  };
}
