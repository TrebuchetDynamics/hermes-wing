import '../../../../../core/protocol/navivox_event.dart';
import 'transcript_display_text.dart';
import 'transcript_message_plain_text.dart';

class TranscriptMessagePlainTextPresentation {
  const TranscriptMessagePlainTextPresentation({required this.text});

  factory TranscriptMessagePlainTextPresentation.fromMessage(
    NavivoxChatMessage message,
  ) {
    return TranscriptMessagePlainTextPresentation(
      text: transcriptPlainTextForMessage(message),
    );
  }

  final String text;

  bool get hasText => transcriptHasDisplayText(text);
}
