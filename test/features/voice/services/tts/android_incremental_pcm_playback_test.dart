import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice/services/tts/android_incremental_pcm_playback.dart';
import 'package:wing/features/voice/services/tts/incremental_tts_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('wing/voice_engine');
  final calls = <MethodCall>[];

  setUp(calls.clear);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'starts one native PCM stream and preserves generation ownership',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return call.method == 'startPlayback' ? true : null;
          });
      final playback = AndroidIncrementalPcmPlayback(sampleRate: 24000);

      await playback.write(
        PcmAudioChunk(generation: 7, bytes: Uint8List.fromList([1, 2])),
      );
      await playback.write(
        PcmAudioChunk(generation: 7, bytes: Uint8List.fromList([3, 4])),
      );
      await playback.stop();

      expect(calls.map((call) => call.method), [
        'startPlayback',
        'writePlaybackPcm',
        'writePlaybackPcm',
        'stopPlayback',
      ]);
      expect(calls[0].arguments, {
        'generation': 7,
        'sampleRate': 24000,
        'channelCount': 1,
      });
      expect(calls[1].arguments, {
        'generation': 7,
        'pcm16': Uint8List.fromList([1, 2]),
      });
      expect(calls[3].arguments, {'generation': 7});
    },
  );

  test(
    'stop invalidates generation before a pending native start settles',
    () async {
      final start = Completer<bool>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (call.method == 'startPlayback') return start.future;
            return null;
          });
      final playback = AndroidIncrementalPcmPlayback();
      final write = playback.write(
        PcmAudioChunk(generation: 11, bytes: Uint8List.fromList([1, 2])),
      );
      await Future<void>.delayed(Duration.zero);

      final stop = playback.stop();
      start.complete(true);
      await Future.wait([write, stop]);

      expect(calls.where((call) => call.method == 'writePlaybackPcm'), isEmpty);
      expect(
        calls.where((call) => call.method == 'stopPlayback').single.arguments,
        {'generation': 11},
      );
    },
  );

  test(
    'dispose invalidates output and stops only its owned generation',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return call.method == 'startPlayback' ? true : null;
          });
      final playback = AndroidIncrementalPcmPlayback();
      await playback.write(
        PcmAudioChunk(generation: 2, bytes: Uint8List.fromList([1, 2])),
      );

      await playback.dispose();

      expect(
        calls.map((call) => call.method),
        containsAllInOrder([
          'startPlayback',
          'writePlaybackPcm',
          'stopPlayback',
        ]),
      );
      expect(
        calls.map((call) => call.method),
        isNot(contains('disposePlayback')),
      );
      expect(
        calls.where((call) => call.method == 'stopPlayback').single.arguments,
        {'generation': 2},
      );
      await expectLater(
        playback.write(
          PcmAudioChunk(generation: 3, bytes: Uint8List.fromList([3, 4])),
        ),
        throwsStateError,
      );
    },
  );
}
