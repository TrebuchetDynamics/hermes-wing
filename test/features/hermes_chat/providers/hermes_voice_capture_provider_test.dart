import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/voice/services/platform/voice_capture_platform.dart';
import 'package:wing/features/voice/services/speech/speech_to_text_voice_capture_service.dart';

void main() {
  test('production capture selector uses device recognition on Android', () {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        hermesVoiceCapturePlatformProvider.overrideWithValue(
          const VoiceCapturePlatform(isAndroid: true),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(hermesVoiceCaptureServiceProvider),
      isA<SpeechToTextVoiceCaptureService>(),
    );
  });

  test('production capture selector stays unavailable off supported hosts', () {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        hermesVoiceCapturePlatformProvider.overrideWithValue(
          const VoiceCapturePlatform(isAndroid: false),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(hermesVoiceCaptureServiceProvider), isNull);
  });
}
