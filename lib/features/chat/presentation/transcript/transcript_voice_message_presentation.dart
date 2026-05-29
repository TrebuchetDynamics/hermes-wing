import '../../../../core/protocol/navivox_event.dart';

class TranscriptVoiceMessagePresentation {
  const TranscriptVoiceMessagePresentation({
    required this.title,
    required this.durationLabel,
    required this.transcript,
    required this.morphIntensity,
  });

  factory TranscriptVoiceMessagePresentation.fromVoice(
    NavivoxVoiceMessage voice,
  ) {
    return TranscriptVoiceMessagePresentation(
      title: 'Voice message',
      durationLabel: '${voice.duration.inSeconds}s',
      transcript: voice.transcript,
      morphIntensity: voice.confidence,
    );
  }

  final String title;
  final String durationLabel;
  final String transcript;
  final double morphIntensity;

  bool get showTranscript => transcript.isNotEmpty;
}
