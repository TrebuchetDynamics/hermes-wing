import '../speech/speech_recognizer.dart';

/// Safety policy for the future-facing binary audio capture path.
///
/// Hermes Wing currently submits transcripts through the active voice path. This
/// policy prevents the recorder-backed path from silently producing audio-only
/// captures before the gateway audio transport and retention contract exists.
final class RecordVoiceCapturePolicy {
  const RecordVoiceCapturePolicy();

  Object? firstFailure(Object? recorderFailure, Object? recognizerFailure) {
    return recorderFailure ?? recognizerFailure;
  }

  bool hasUsableTranscript(SpeechResult speech) {
    return speech.transcript.trim().isNotEmpty;
  }

  String get emptyTranscriptFailure => 'empty transcript';
}
