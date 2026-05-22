import 'speech_to_text_voice_capture_service.dart';
import 'voice_capture_platform.dart';
import 'voice_capture_service.dart';

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
