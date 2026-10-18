import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice/services/tts/platform_text_to_speech_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_tts');
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('platform rejection is not reported as completed speech', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'speak') return 0;
          return 1;
        });
    final service = PlatformTextToSpeechService();
    addTearDown(service.dispose);
    await expectLater(service.speak('Synthetic reply'), throwsStateError);
  });

  test(
    'completion mode is configured once and successful chunks flow',
    () async {
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            return 1;
          });
      final service = PlatformTextToSpeechService();
      addTearDown(service.dispose);
      await service.speak('First sentence.');
      await service.speak('Second sentence.');
      expect(calls, ['awaitSpeakCompletion', 'speak', 'speak']);
    },
  );
}
