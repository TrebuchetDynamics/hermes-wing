import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/protocol/voice_unavailable_reason.dart';
import 'package:wing/features/voice/services/speech/speech_to_text_capture_policy.dart';
import 'package:wing/shared/voice/voice_capture_failures.dart';

/// Wing asks Android for on-device-only recognition, which is a deliberate
/// privacy choice. The cost is that a device whose recognizer is installed but
/// lacks the offline pack for the active locale fails every capture, and
/// Android reports that distinctly. Collapsing it into the generic
/// "install or enable device speech recognition" advice sends the operator to
/// the wrong setting.
void main() {
  group('language availability is its own reason', () {
    test('an unavailable language maps to the language reason', () {
      expect(
        speechToTextDeviceUnavailableReasonFromMessage(
          'error_language_unavailable',
        ),
        deviceSttLanguageUnavailableReason,
      );
    });

    test('an unsupported language maps to the language reason', () {
      expect(
        speechToTextDeviceUnavailableReasonFromMessage(
          'error_language_not_supported',
        ),
        deviceSttLanguageUnavailableReason,
      );
    });

    test('the language reason carries actionable guidance', () {
      expect(
        deviceSpeechLanguageUnavailableVoiceCaptureMessage.toLowerCase(),
        contains('language'),
      );
      expect(
        deviceSpeechLanguageUnavailableVoiceCaptureMessage,
        isNot(deviceSpeechUnavailableVoiceCaptureMessage),
      );
    });

    test('the language reason survives canonicalization', () {
      expect(
        canonicalVoiceUnavailableReason(deviceSttLanguageUnavailableReason),
        deviceSttLanguageUnavailableReason,
      );
    });
  });

  group('existing reasons are unchanged', () {
    test('a permission error still maps to the permission reason', () {
      expect(
        speechToTextDeviceUnavailableReasonFromMessage('error_permission'),
        microphonePermissionDeniedReason,
      );
    });

    test('an unrelated error still maps to the generic reason', () {
      expect(
        speechToTextDeviceUnavailableReasonFromMessage('error_client'),
        deviceSttUnavailableReason,
      );
    });
  });
}
