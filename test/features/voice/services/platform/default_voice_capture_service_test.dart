import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/voice/services/platform/default_voice_capture_service.dart';
import 'package:navivox/shared/voice/voice_capture_service.dart';

void main() {
  test('creates speech_to_text capture on supported platforms', () {
    for (final platform in const [
      VoiceCapturePlatform(isAndroid: true),
      VoiceCapturePlatform(isAndroid: false, isIOS: true),
      VoiceCapturePlatform(isAndroid: false, isMacOS: true),
      VoiceCapturePlatform(isAndroid: false, isWindows: true),
      VoiceCapturePlatform(isAndroid: false, isWeb: true),
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

  test('leaves unsupported platforms without default STT', () {
    expect(
      createDefaultVoiceCaptureService(
        platform: const VoiceCapturePlatform(isAndroid: false),
        speechToTextServiceFactory: _FakeVoiceCaptureService.new,
      ),
      isNull,
    );
  });
}

class _FakeVoiceCaptureService implements VoiceCaptureService {
  @override
  Future<VoiceCapture> capture({required Duration timeout}) {
    throw UnimplementedError();
  }
}
