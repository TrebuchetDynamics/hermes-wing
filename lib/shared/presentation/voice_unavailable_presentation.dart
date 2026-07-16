import 'package:wing/core/protocol/voice_unavailable_reason.dart';

export 'package:wing/core/protocol/voice_unavailable_reason.dart'
    show
        canonicalVoiceUnavailableReason,
        deviceSttUnavailableReason,
        microphonePermissionDeniedReason;

const selectProfileContactVoiceUnavailableReason = 'select a profile contact';

/// Shared presentation policy for local voice-capture unavailable states.
///
/// Keep these labels centralized because the chat composer and readiness UI both
/// surface the same Android speech-recognition blockers through different rows.

String? defaultVoiceUnavailableRecoveryAction(String reason) {
  if (reason == deviceSttUnavailableReason) {
    return 'Install or enable device speech recognition, then return to Hermes Wing.';
  }
  if (reason == microphonePermissionDeniedReason) {
    return 'Grant microphone permission in Android App info, then return to Hermes Wing.';
  }
  return null;
}

String voiceUnavailableHelpText(String? reason) {
  return defaultVoiceUnavailableRecoveryAction(reason ?? '') ??
      (reason == selectProfileContactVoiceUnavailableReason
          ? 'Select a profile contact before using continuous voice.'
          : 'Check microphone permissions and Settings.');
}

String voiceSettingsSubtitleForUnavailableReason(String? reason) {
  return reason == deviceSttUnavailableReason
      ? 'Review continuous voice after enabling device speech recognition.'
      : reason == microphonePermissionDeniedReason
      ? 'Review continuous voice after granting microphone permission.'
      : reason == selectProfileContactVoiceUnavailableReason
      ? 'Select a profile contact before reviewing continuous voice settings.'
      : 'Review continuous voice and trust settings';
}
