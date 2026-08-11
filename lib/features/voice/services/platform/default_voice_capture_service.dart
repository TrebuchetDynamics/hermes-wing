import '../../../../core/protocol/voice_unavailable_reason.dart';
import '../../../../shared/voice/voice_capture_service.dart';
import '../speech/speech_to_text_voice_capture_service.dart';
import 'device_speech_recognition_availability.dart';
import 'voice_capture_platform.dart';

export 'device_speech_recognition_availability.dart'
    show
        DeviceSpeechRecognitionDiagnostics,
        DeviceSpeechRecognitionDiagnosticsProbe,
        VoiceCaptureReadiness,
        checkDefaultVoiceCaptureReadiness;
export 'voice_capture_platform.dart' show VoiceCapturePlatform;

typedef VoiceCaptureServiceFactory = VoiceCaptureService Function();

VoiceCaptureService? createDefaultVoiceCaptureService({
  VoiceCapturePlatform? platform,
  VoiceCaptureServiceFactory? speechToTextServiceFactory,
  String? localeId,
}) {
  final effectivePlatform = platform ?? currentVoiceCapturePlatform();
  if (!_supportsSpeechToText(effectivePlatform)) return null;

  if (speechToTextServiceFactory != null) {
    return speechToTextServiceFactory();
  }
  return SpeechToTextVoiceCaptureService(
    localeId: localeId,
    readinessCheck: effectivePlatform.isAndroid
        ? () async {
            final reason = (await checkDefaultVoiceCaptureReadiness(
              platform: effectivePlatform,
            )).unavailableReason;
            // Let speech_to_text request runtime microphone permission on the
            // first capture; only recognizer capability blocks initialization.
            return reason == microphonePermissionDeniedReason ? null : reason;
          }
        : null,
  );
}

bool _supportsSpeechToText(VoiceCapturePlatform platform) {
  return platform.isAndroid || platform.isIOS || platform.isMacOS;
}
