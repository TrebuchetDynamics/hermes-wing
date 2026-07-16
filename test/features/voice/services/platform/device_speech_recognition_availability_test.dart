import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice/services/platform/default_voice_capture_service.dart';

void main() {
  test(
    'readiness is available on non-Android speech_to_text platforms',
    () async {
      for (final platform in const [
        VoiceCapturePlatform(isAndroid: false, isIOS: true),
        VoiceCapturePlatform(isAndroid: false, isMacOS: true),
        VoiceCapturePlatform(isAndroid: false, isWindows: true),
        VoiceCapturePlatform(isAndroid: false, isWeb: true),
      ]) {
        final readiness = await checkDefaultVoiceCaptureReadiness(
          platform: platform,
        );

        expect(readiness.available, isTrue);
      }
    },
  );

  test('readiness remains unavailable on unsupported platforms', () async {
    final readiness = await checkDefaultVoiceCaptureReadiness(
      platform: const VoiceCapturePlatform(isAndroid: false),
    );

    expect(readiness.available, isFalse);
  });
}
