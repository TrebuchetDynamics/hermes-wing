import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wing/features/voice/services/speech/offline_voice_capture_service.dart';
import 'package:wing/features/voice/services/speech/sherpa_silero_vad.dart';
import 'package:wing/features/voice/services/speech/sherpa_whisper_runtime.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const modelDirectory = String.fromEnvironment('WING_WHISPER_MODEL_DIR');

  test(
    'Whisper initializes and decodes PCM in its worker isolate on Android',
    () async {
      for (final name in [
        'base-encoder.int8.onnx',
        'base-decoder.int8.onnx',
        'base-tokens.txt',
      ]) {
        expect(File('$modelDirectory/$name').existsSync(), isTrue);
      }

      final runtime = await IsolatedSherpaWhisperRuntime.start(
        files: const SherpaWhisperModelFiles(
          modelId: 'whisper-base-int8-smoke',
          encoderPath: '$modelDirectory/base-encoder.int8.onnx',
          decoderPath: '$modelDirectory/base-decoder.int8.onnx',
          tokensPath: '$modelDirectory/base-tokens.txt',
        ),
      ).timeout(const Duration(minutes: 2));
      addTearDown(runtime.dispose);

      final result = await runtime
          .transcribe(
            samples: Float32List(16000),
            sampleRate: 16000,
            language: null,
          )
          .timeout(const Duration(minutes: 2));

      expect(result.text, isA<String>());
      expect(result.language, isA<String>());
    },
    skip: !Platform.isAndroid || modelDirectory.isEmpty,
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'Silero VAD initializes and accepts PCM on Android',
    () async {
      final modelPath = '$modelDirectory/silero_vad_v5.onnx';
      expect(File(modelPath).existsSync(), isTrue);

      final detector = SherpaSileroVoiceActivityDetector.fromModel(
        modelPath: modelPath,
      );
      addTearDown(detector.dispose);

      expect(detector.accept(Uint8List(1024)), VoiceActivity.silence);
      detector.reset();
    },
    skip: !Platform.isAndroid || modelDirectory.isEmpty,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
