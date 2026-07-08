import '../../../core/protocol/voice_unavailable_reason.dart';
import '../../../shared/voice/voice_capture_failures.dart';
import '../../../shared/voice/voice_capture_service.dart';

enum HermesVoiceCaptureStatus { unavailable, captured, failed }

class HermesVoiceCaptureOutcome {
  const HermesVoiceCaptureOutcome._({
    required this.status,
    this.capture,
    this.error,
    this.errorMessage,
  });

  const HermesVoiceCaptureOutcome.unavailable()
    : this._(status: HermesVoiceCaptureStatus.unavailable);

  const HermesVoiceCaptureOutcome.captured(VoiceCapture capture)
    : this._(status: HermesVoiceCaptureStatus.captured, capture: capture);

  const HermesVoiceCaptureOutcome.failed({
    required Object error,
    required String errorMessage,
  }) : this._(
         status: HermesVoiceCaptureStatus.failed,
         error: error,
         errorMessage: errorMessage,
       );

  final HermesVoiceCaptureStatus status;
  final VoiceCapture? capture;
  final Object? error;
  final String? errorMessage;
}

class HermesVoiceCaptureFlow {
  const HermesVoiceCaptureFlow();

  Future<HermesVoiceCaptureOutcome> capture({
    required VoiceCaptureService? service,
    required Duration timeout,
    void Function()? onStarted,
  }) async {
    if (service == null) return const HermesVoiceCaptureOutcome.unavailable();

    onStarted?.call();
    try {
      final capture = await service.capture(timeout: timeout);
      return HermesVoiceCaptureOutcome.captured(capture);
    } on VoiceCaptureTimeout catch (error) {
      return HermesVoiceCaptureOutcome.failed(
        error: error,
        errorMessage: 'Voice capture timed out.',
      );
    } on DeviceSpeechUnavailable catch (error) {
      return HermesVoiceCaptureOutcome.failed(
        error: error,
        errorMessage: _deviceSpeechUnavailableMessage(error.message),
      );
    } on SpeechToTextCaptureFailure catch (error) {
      return HermesVoiceCaptureOutcome.failed(
        error: error,
        errorMessage: error.isNoTranscript
            ? noSpeechDetectedVoiceCaptureMessage
            : 'Voice capture failed: $error',
      );
    } catch (error) {
      return HermesVoiceCaptureOutcome.failed(
        error: error,
        errorMessage: 'Voice capture failed: $error',
      );
    }
  }
}

String _deviceSpeechUnavailableMessage(String reason) {
  return canonicalVoiceUnavailableReason(reason) ==
          microphonePermissionDeniedReason
      ? microphonePermissionDeniedVoiceCaptureMessage
      : deviceSpeechUnavailableVoiceCaptureMessage;
}
