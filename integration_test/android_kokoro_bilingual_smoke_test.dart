import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wing/features/voice/services/tts/android_incremental_pcm_playback.dart';
import 'package:wing/features/voice/services/tts/incremental_tts_engine.dart';
import 'package:wing/features/voice/services/tts/pocket_speech_incremental_tts_engine.dart';
import 'package:wing/features/voice/services/tts/pocket_speech_text_to_speech_service.dart';
import 'package:wing/shared/voice/voice_settings.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const modelPath = String.fromEnvironment('WING_KOKORO_MODEL_PATH');
  const voicesPath = String.fromEnvironment('WING_KOKORO_VOICES_PATH');

  test(
    'Kokoro initializes and synthesizes English and Spanish PCM on Android',
    () async {
      expect(File(modelPath).existsSync(), isTrue);
      expect(File(voicesPath).existsSync(), isTrue);

      final engine = PocketSpeechIncrementalTtsEngine(
        PackagePocketSpeechEngine(
          PocketSpeechVoicePack(
            model: PocketSpeechModel.kokoro,
            modelPath: modelPath,
            voicesPath: voicesPath,
          ),
        ),
        selectedVoice: () => 'af_heart',
      );
      addTearDown(engine.dispose);

      final english = await engine
          .synthesize(
            const TtsSynthesisRequest(
              generation: 1,
              text: 'Hello from Hermes Wing.',
              languageHint: 'en-US',
            ),
          )
          .toList()
          .timeout(const Duration(minutes: 3));
      final spanish = await engine
          .synthesize(
            const TtsSynthesisRequest(
              generation: 2,
              text: 'Hola desde Hermes Wing.',
              languageHint: 'es-US',
            ),
          )
          .toList()
          .timeout(const Duration(minutes: 3));

      expect(english, isNotEmpty);
      expect(spanish, isNotEmpty);
      expect(english.every((chunk) => chunk.generation == 1), isTrue);
      expect(spanish.every((chunk) => chunk.generation == 2), isTrue);
      expect(english.every((chunk) => chunk.sampleRate == 24000), isTrue);
      expect(spanish.every((chunk) => chunk.sampleRate == 24000), isTrue);
      expect(
        english.fold<int>(0, (total, chunk) => total + chunk.bytes.length),
        greaterThan(1000),
      );
      expect(
        spanish.fold<int>(0, (total, chunk) => total + chunk.bytes.length),
        greaterThan(1000),
      );

      final playback = AndroidIncrementalPcmPlayback();
      addTearDown(playback.dispose);
      for (final chunk in english) {
        await playback.write(chunk);
      }
      await playback.stop();
      for (final chunk in spanish) {
        await playback.write(chunk);
      }
      await playback.stop();
    },
    skip: !Platform.isAndroid || modelPath.isEmpty || voicesPath.isEmpty,
  );
}
