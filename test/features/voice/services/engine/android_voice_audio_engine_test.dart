import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice/services/engine/android_voice_audio_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('wing/voice_engine');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'capabilities' => <String, Object?>{
              'sampleRate': 16000,
              'aecAvailable': true,
              'noiseSuppressorAvailable': true,
              'automaticGainControlAvailable': false,
            },
            'startCapture' => true,
            'stopCapture' => null,
            _ => null,
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'reports native DSP capabilities without assuming availability',
    () async {
      final engine = AndroidVoiceAudioEngine();

      final capabilities = await engine.capabilities();

      expect(capabilities.sampleRate, 16000);
      expect(capabilities.aecAvailable, isTrue);
      expect(capabilities.noiseSuppressorAvailable, isTrue);
      expect(capabilities.automaticGainControlAvailable, isFalse);
    },
  );

  test('capture operations carry immutable generation ownership', () async {
    final engine = AndroidVoiceAudioEngine();

    await engine.startCapture(generation: 7);
    await engine.stopCapture(generation: 7);

    expect(calls.map((call) => call.method), ['startCapture', 'stopCapture']);
    expect(calls[0].arguments, <String, Object?>{'generation': 7});
    expect(calls[1].arguments, <String, Object?>{'generation': 7});
  });
}
