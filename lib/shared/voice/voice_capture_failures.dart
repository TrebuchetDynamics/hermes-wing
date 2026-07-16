import 'package:wing/core/protocol/voice_unavailable_reason.dart';

const noSpeechDetectedVoiceCaptureMessage =
    'No speech was detected. Check microphone permission, device speech recognition, or try speaking closer to the mic.';
const deviceSpeechUnavailableVoiceCaptureMessage =
    'Device speech recognition is unavailable. Install or enable device speech recognition, then return to Hermes Wing.';
const microphonePermissionDeniedVoiceCaptureMessage =
    'Microphone permission denied. Grant microphone permission in Android App info, then return to Hermes Wing.';

class DeviceSpeechUnavailable implements Exception {
  const DeviceSpeechUnavailable([this.message = deviceSttUnavailableReason]);

  final String message;

  @override
  String toString() => message;
}

class SpeechToTextCaptureFailure implements Exception {
  const SpeechToTextCaptureFailure(this.cause);

  final Object cause;

  bool get isNoTranscript => isNoTranscriptVoiceCaptureReason('$cause');

  @override
  String toString() => 'SpeechToTextCaptureFailure: $cause';
}

bool isNoTranscriptVoiceCaptureReason(String reason) {
  final normalized = reason.trim().toLowerCase();
  return normalized == 'no transcript' ||
      normalized == 'empty transcript' ||
      normalized.contains('error_no_match') ||
      normalized.contains('error_speech_timeout');
}
