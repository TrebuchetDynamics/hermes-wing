import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/settings/providers/voice_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('defaults: router off, rate 1.0, no voice', () {
    const s = WingVoiceSettings();
    expect(s.voiceCommandsEnabled, isFalse);
    expect(s.speechRate, 1.0);
    expect(s.ttsVoiceName, isNull);
  });

  test('setters persist and clamp', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(wingVoiceSettingsProvider.notifier);
    // No `ready` future exists on this controller; existing settings tests
    // synchronize on the async prefs load via pumpEventQueue instead
    // (see test/features/settings/providers/voice_settings_provider_test.dart).
    await pumpEventQueue();

    controller.setVoiceCommandsEnabled(true);
    controller.setSpeechRate(9.0);
    controller.setTtsVoiceName('nova');
    await pumpEventQueue();

    final state = container.read(wingVoiceSettingsProvider);
    expect(state.voiceCommandsEnabled, isTrue);
    expect(state.speechRate, 3.0);
    expect(state.ttsVoiceName, 'nova');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('voice_commands_enabled'), isTrue);
    expect(prefs.getDouble('tts_speech_rate'), 3.0);
    expect(prefs.getString('tts_voice_name'), 'nova');
  });
}
