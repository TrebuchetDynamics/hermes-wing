import '../../../core/protocol/voice_unavailable_reason.dart';
import '../../../shared/security/wing_redaction.dart';
import '../../../shared/voice/voice_capture_failures.dart';
import '../../../shared/voice/voice_capture_service.dart';
import 'hermes_voice_failure.dart';

enum HermesVoiceCaptureStatus { unavailable, captured, failed }

class HermesVoiceCaptureOutcome {
  const HermesVoiceCaptureOutcome._({
    required this.status,
    this.capture,
    this.error,
    this.failure,
    this.errorDetail,
  });

  const HermesVoiceCaptureOutcome.unavailable()
    : this._(status: HermesVoiceCaptureStatus.unavailable);

  const HermesVoiceCaptureOutcome.captured(VoiceCapture capture)
    : this._(status: HermesVoiceCaptureStatus.captured, capture: capture);

  const HermesVoiceCaptureOutcome.failed({
    required Object error,
    required HermesVoiceFailure failure,
    String? errorDetail,
  }) : this._(
         status: HermesVoiceCaptureStatus.failed,
         error: error,
         failure: failure,
         errorDetail: errorDetail,
       );

  final HermesVoiceCaptureStatus status;
  final VoiceCapture? capture;
  final Object? error;
  final HermesVoiceFailure? failure;
  final String? errorDetail;
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
        failure: HermesVoiceFailure.timedOut,
      );
    } on DeviceSpeechUnavailable catch (error) {
      return HermesVoiceCaptureOutcome.failed(
        error: error,
        failure: _deviceSpeechUnavailableFailure(error.message),
      );
    } on SpeechToTextCaptureFailure catch (error) {
      return HermesVoiceCaptureOutcome.failed(
        error: error,
        failure: error.isNoTranscript
            ? HermesVoiceFailure.noSpeech
            : HermesVoiceFailure.generic,
        errorDetail: error.isNoTranscript
            ? null
            : _safeVoiceCaptureErrorDetail(error),
      );
    } catch (error) {
      return HermesVoiceCaptureOutcome.failed(
        error: error,
        failure: HermesVoiceFailure.generic,
        errorDetail: _safeVoiceCaptureErrorDetail(error),
      );
    }
  }
}

String _safeVoiceCaptureErrorDetail(Object error) {
  final detail = error.toString().replaceFirst(
    RegExp(r'^(?:Bad state|Exception):\s*'),
    '',
  );
  return wingRedactSensitiveText(detail);
}

HermesVoiceFailure _deviceSpeechUnavailableFailure(String reason) {
  return switch (canonicalVoiceUnavailableReason(reason)) {
    microphonePermissionDeniedReason =>
      HermesVoiceFailure.microphonePermissionDenied,
    deviceSttLanguageUnavailableReason =>
      HermesVoiceFailure.deviceLanguageUnavailable,
    _ => HermesVoiceFailure.deviceSpeechUnavailable,
  };
}
