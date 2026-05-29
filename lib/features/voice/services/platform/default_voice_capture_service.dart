import '../capture/voice_capture_service.dart';
import '../speech/speech_to_text_voice_capture_service.dart';
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
}) {
  final effectivePlatform = platform ?? currentVoiceCapturePlatform();
  if (!effectivePlatform.isAndroid) return null;

  final factory =
      speechToTextServiceFactory ?? SpeechToTextVoiceCaptureService.new;
  return factory();
}
