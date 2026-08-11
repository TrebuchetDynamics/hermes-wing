import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice/services/speech/sherpa_whisper_runtime.dart';

void main() {
  final modelDirectory = Platform.environment['WING_WHISPER_MODEL_DIR'];
  test(
    'loads pinned Whisper model and decodes PCM off the UI isolate',
    () async {
      final runtime = await IsolatedSherpaWhisperRuntime.start(
        files: SherpaWhisperModelFiles(
          modelId: 'whisper-base-int8-smoke',
          encoderPath: '$modelDirectory/base-encoder.int8.onnx',
          decoderPath: '$modelDirectory/base-decoder.int8.onnx',
          tokensPath: '$modelDirectory/base-tokens.txt',
        ),
      );
      addTearDown(runtime.dispose);

      final result = await runtime.transcribe(
        samples: Float32List(16000),
        sampleRate: 16000,
        language: null,
      );

      expect(result.text, isA<String>());
      expect(result.language, isA<String>());
    },
    skip: !Platform.isAndroid || modelDirectory == null
        ? 'Run on Android with WING_WHISPER_MODEL_DIR set to a verified pack.'
        : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
