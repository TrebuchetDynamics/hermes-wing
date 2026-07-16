import 'package:flutter_test/flutter_test.dart';
import 'package:wing/shared/voice/voice_settings.dart';

void main() {
  test('Pocket Speech defaults to the smaller Kitten model', () {
    const defaults = WingVoiceSettings();

    expect(defaults.pocketSpeechModel, PocketSpeechModel.kitten);
    expect(PocketSpeechModel.kitten.downloadSize, '≈26 MB');
    expect(PocketSpeechModel.kokoro.downloadSize, '≈365 MB');
    expect(defaults.pocketSpeechTtsEnabled, isFalse);
    expect(defaults.pocketSpeechVoicePackReady, isFalse);
  });

  test('Pocket Speech voice pack records its model and can be cleared', () {
    const ready = WingVoiceSettings(
      pocketSpeechModel: PocketSpeechModel.kokoro,
      pocketSpeechVoicePack: PocketSpeechVoicePack(
        model: PocketSpeechModel.kokoro,
        modelPath: '/data/kokoro/kokoro-v1.0.onnx',
        voicesPath: '/data/kokoro/voices.json',
      ),
      pocketSpeechTtsEnabled: true,
    );

    expect(ready.pocketSpeechVoicePackReady, isTrue);
    expect(ready.pocketSpeechVoicePack?.model, PocketSpeechModel.kokoro);

    final cleared = ready.copyWith(
      pocketSpeechTtsEnabled: false,
      clearPocketSpeechVoicePack: true,
    );
    expect(cleared.pocketSpeechVoicePackReady, isFalse);
    expect(cleared.pocketSpeechVoicePack, isNull);
  });
}
