import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'native voice engine owns and tears down generation-tagged PCM playback',
    (_) async {
      const channel = MethodChannel('wing/voice_engine');
      const generation = 901;
      final started = await channel.invokeMethod<bool>('startPlayback', {
        'generation': generation,
        'sampleRate': 24000,
        'channelCount': 1,
      });
      expect(started, isTrue);
      try {
        await channel.invokeMethod<void>('writePlaybackPcm', {
          'generation': generation,
          // 20 ms of mono PCM16 silence at 24 kHz.
          'pcm16': Uint8List(960),
        });
      } finally {
        await channel.invokeMethod<void>('stopPlayback', {
          'generation': generation,
        });
      }
    },
    skip: !Platform.isAndroid,
  );
}
