import '../../../../../core/channel/navivox_channel.dart';
import '../../../../../core/protocol/navivox_event.dart';
import '../shared/transcript_display_text.dart';
import '../shared/transcript_message_plain_text.dart';

class TranscriptMessageForwardTargetPresentation {
  const TranscriptMessageForwardTargetPresentation({
    required this.contact,
    required this.displayName,
    required this.subtitle,
  });

  final NavivoxProfileContact contact;
  final String displayName;
  final String subtitle;
}

class TranscriptMessageActionPresentation {
  const TranscriptMessageActionPresentation._({
    required this.text,
    required this.runRecordId,
    required this.canCancelActiveTurn,
    required this.textToSpeechAvailable,
    required this.forwardTargets,
    required this.forwardingAvailable,
  });

  factory TranscriptMessageActionPresentation.fromMessage(
    NavivoxChatMessage message, {
    bool textToSpeechAvailable = false,
    bool canCancelActiveTurn = false,
    List<NavivoxProfileContact> forwardTargets = const [],
    bool forwardingAvailable = false,
    bool runRecordInspectionAvailable = false,
  }) {
    return TranscriptMessageActionPresentation._(
      text: transcriptPlainTextForMessage(message),
      runRecordId: runRecordInspectionAvailable
          ? runRecordIdForMessage(message)
          : null,
      canCancelActiveTurn: canCancelActiveTurn,
      textToSpeechAvailable: textToSpeechAvailable,
      forwardingAvailable: forwardingAvailable,
      forwardTargets: [
        for (final target in forwardTargets)
          TranscriptMessageForwardTargetPresentation(
            contact: target,
            displayName: target.displayName,
            subtitle: target.serverLabel,
          ),
      ],
    );
  }

  final String text;
  final String? runRecordId;
  final bool canCancelActiveTurn;
  final bool textToSpeechAvailable;
  final bool forwardingAvailable;
  final List<TranscriptMessageForwardTargetPresentation> forwardTargets;

  String get title => 'Message actions';
  bool get hasText => transcriptHasDisplayText(text);

  bool get showPauseStream => canCancelActiveTurn;
  String get pauseLabel => 'Pause stream';
  String get pauseSubtitle => 'Stop the current assistant response.';
  String get pauseSnackbar => 'Stream pause requested';

  bool get showCopy => hasText;
  String get copyLabel => 'Copy text';
  String get copySnackbar => 'Message copied';

  bool get canReadAloud => hasText && textToSpeechAvailable;
  String get readAloudLabel => 'Read aloud';
  String get readAloudSnackbar => 'Reading aloud';

  bool get showInspectRunRecord => runRecordId != null;
  String get inspectRunRecordLabel => 'View evidence';
  String get inspectRunRecordSubtitle =>
      'Show redacted transcript, voice, tool, usage, and cost evidence.';

  bool get showReadAloudUnavailable => hasText && !textToSpeechAvailable;
  String get readAloudUnavailableLabel => 'Read aloud unavailable';
  String get readAloudUnavailableSubtitle => 'Device TTS is not connected.';

  bool get showForwardSection =>
      hasText && forwardingAvailable && forwardTargets.isNotEmpty;
  String get forwardTitle => 'Forward to';

  static String? runRecordIdForMessage(NavivoxChatMessage message) {
    return transcriptTrimmedTextOrNull(message.runRecordReference);
  }
}
