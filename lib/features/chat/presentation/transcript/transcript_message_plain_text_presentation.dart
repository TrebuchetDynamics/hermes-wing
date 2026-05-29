import '../../../../core/protocol/navivox_event.dart';
import 'transcript_text_message_presentation.dart';

class TranscriptMessagePlainTextPresentation {
  const TranscriptMessagePlainTextPresentation({required this.text});

  factory TranscriptMessagePlainTextPresentation.fromMessage(
    NavivoxChatMessage message,
  ) {
    return TranscriptMessagePlainTextPresentation(
      text: switch (message.kind) {
        NavivoxMessageKind.text =>
          TranscriptTextMessagePresentation.fromMessage(message).text,
        NavivoxMessageKind.voice => message.voice?.transcript ?? '',
        NavivoxMessageKind.toolCall => _joinLines([
          message.toolCall?.name,
          message.toolCall?.status,
          message.toolCall?.summary,
        ]),
        NavivoxMessageKind.safetyWarning ||
        NavivoxMessageKind.approvalRequest => _joinLines([
          message.safetyNotice?.message,
          message.safetyNotice?.risk,
        ]),
      },
    );
  }

  final String text;

  bool get hasText => text.isNotEmpty;
}

String _joinLines(List<String?> parts) {
  return parts.whereType<String>().where((part) => part.isNotEmpty).join('\n');
}
