import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice/services/tts/platform_text_to_speech_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_tts');
  for (final dispose in [false, true]) {
    test(
      'pending configuration cannot speak after ${dispose ? 'dispose' : 'stop'}',
      () async {
        final configured = Completer<void>();
        final entered = Completer<void>();
        final calls = <String>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              calls.add(call.method);
              if (call.method == 'awaitSpeakCompletion') {
                if (!entered.isCompleted) entered.complete();
                await configured.future;
              }
              return 1;
            });
        final service = PlatformTextToSpeechService();
        final speech = service.speak('Synthetic cancelled sentence.');
        await entered.future;
        if (dispose) {
          await service.dispose();
        } else {
          await service.stop();
        }
        configured.complete();
        await speech;
        expect(calls.where((method) => method == 'speak'), isEmpty);
        if (dispose) {
          await service.speak('Must remain silent after disposal.');
          expect(calls.where((method) => method == 'speak'), isEmpty);
        } else {
          await service.speak('Explicit new sentence.');
          expect(calls.where((method) => method == 'speak'), hasLength(1));
        }
        await service.dispose();
      },
    );
  }
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
