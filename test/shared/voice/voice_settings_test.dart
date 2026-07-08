import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/shared/voice/voice_settings.dart';

void main() {
  test('kokoro settings are optional until asset paths exist', () {
    const defaults = NavivoxVoiceSettings();

    expect(defaults.kokoroTtsEnabled, isFalse);
    expect(defaults.kokoroAssetsReady, isFalse);

    final ready = defaults.copyWith(
      kokoroModelPath: '/data/kokoro/kokoro-v1.0.onnx',
      kokoroVoicesPath: '/data/kokoro/voices.json',
      kokoroTtsEnabled: true,
    );

    expect(ready.kokoroAssetsReady, isTrue);
    expect(ready.kokoroTtsEnabled, isTrue);
  });
}
