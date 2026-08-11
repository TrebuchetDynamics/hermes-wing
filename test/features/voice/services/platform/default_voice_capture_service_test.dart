import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice/services/platform/default_voice_capture_service.dart';
import 'package:wing/features/voice/services/speech/speech_to_text_voice_capture_service.dart';
import 'package:wing/shared/voice/voice_capture_service.dart';

void main() {
  test('passes an explicit profile language to platform recognition', () {
    final service = createDefaultVoiceCaptureService(
      platform: const VoiceCapturePlatform(isAndroid: true),
      localeId: 'es-US',
    );

    expect(service, isA<SpeechToTextVoiceCaptureService>());
    expect(
      (service as VoiceCaptureProvenanceService).provenance,
      const VoiceEngineProvenance(
        engine: 'Platform SpeechRecognizer',
        adapter: 'speech_to_text 7.4.0',
        model: null,
        offlineRequested: true,
        appOwnedModel: false,
      ),
    );
    expect(
      (service as SpeechToTextVoiceCaptureService).configuredLocaleId,
      'es-US',
    );
  });

  test('creates speech_to_text capture on supported platforms', () {
    for (final platform in const [
      VoiceCapturePlatform(isAndroid: true),
      VoiceCapturePlatform(isAndroid: false, isIOS: true),
      VoiceCapturePlatform(isAndroid: false, isMacOS: true),
    ]) {
      expect(
        createDefaultVoiceCaptureService(
          platform: platform,
          speechToTextServiceFactory: _FakeVoiceCaptureService.new,
        ),
        isA<_FakeVoiceCaptureService>(),
      );
    }
  });

  test('leaves non-private STT platforms unsupported', () {
    for (final platform in const [
      VoiceCapturePlatform(isAndroid: false),
      VoiceCapturePlatform(isAndroid: false, isWindows: true),
      VoiceCapturePlatform(isAndroid: false, isWeb: true),
    ]) {
      expect(
        createDefaultVoiceCaptureService(
          platform: platform,
          speechToTextServiceFactory: _FakeVoiceCaptureService.new,
        ),
        isNull,
      );
    }
  });
}

class _FakeVoiceCaptureService implements VoiceCaptureService {
  @override
  Future<VoiceCapture> capture({required Duration timeout}) {
    throw UnimplementedError();
  }

  @override
  Future<void> cancel() async {}
}
