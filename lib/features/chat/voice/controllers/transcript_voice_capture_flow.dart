import '../../../../core/protocol/voice_unavailable_reason.dart';
import '../../../voice/services/speech/speech_to_text_voice_capture_service.dart';
import '../../../voice/services/capture/voice_capture_service.dart';

enum TranscriptVoiceCaptureStatus { unavailable, captured, failed }

class TranscriptVoiceCaptureOutcome {
  const TranscriptVoiceCaptureOutcome._({
    required this.status,
    this.capture,
    this.error,
    this.errorMessage,
  });

  const TranscriptVoiceCaptureOutcome.unavailable()
    : this._(status: TranscriptVoiceCaptureStatus.unavailable);

  const TranscriptVoiceCaptureOutcome.captured(VoiceCapture capture)
    : this._(status: TranscriptVoiceCaptureStatus.captured, capture: capture);

  const TranscriptVoiceCaptureOutcome.failed({
    required Object error,
    required String errorMessage,
  }) : this._(
         status: TranscriptVoiceCaptureStatus.failed,
         error: error,
         errorMessage: errorMessage,
       );

  final TranscriptVoiceCaptureStatus status;
  final VoiceCapture? capture;
  final Object? error;
  final String? errorMessage;
}

class TranscriptVoiceCaptureFlow {
  const TranscriptVoiceCaptureFlow();

  Future<TranscriptVoiceCaptureOutcome> capture({
    required VoiceCaptureService? service,
    required Duration timeout,
    void Function()? onStarted,
  }) async {
    if (service == null) {
      return const TranscriptVoiceCaptureOutcome.unavailable();
    }

    onStarted?.call();
    try {
      final capture = await service.capture(timeout: timeout);
      return TranscriptVoiceCaptureOutcome.captured(capture);
    } on VoiceCaptureTimeout catch (error) {
      return TranscriptVoiceCaptureOutcome.failed(
        error: error,
        errorMessage: 'Voice capture timed out.',
      );
    } on DeviceSpeechUnavailable catch (error) {
      return TranscriptVoiceCaptureOutcome.failed(
        error: error,
        errorMessage: _deviceSpeechUnavailableMessage(error.message),
      );
    } on SpeechToTextCaptureFailure catch (error) {
      return TranscriptVoiceCaptureOutcome.failed(
        error: error,
        errorMessage: error.isNoTranscript
            ? noSpeechDetectedVoiceCaptureMessage
            : 'Voice capture failed: $error',
      );
    } catch (error) {
      return TranscriptVoiceCaptureOutcome.failed(
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
