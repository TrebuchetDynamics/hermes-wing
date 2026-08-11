import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice/services/speech/sherpa_whisper_runtime.dart';

void main() {
  test('builds multilingual Whisper config without translation', () {
    const files = SherpaWhisperModelFiles(
      modelId: 'whisper-base-int8',
      encoderPath: '/models/base-encoder.int8.onnx',
      decoderPath: '/models/base-decoder.int8.onnx',
      tokensPath: '/models/base-tokens.txt',
    );

    final config = buildSherpaWhisperConfig(
      files: files,
      language: null,
      numThreads: 3,
    );

    expect(config.model.whisper.encoder, files.encoderPath);
    expect(config.model.whisper.decoder, files.decoderPath);
    expect(config.model.whisper.language, '');
    expect(config.model.whisper.task, 'transcribe');
    expect(config.model.tokens, files.tokensPath);
    expect(config.model.numThreads, 3);
    expect(config.model.debug, isFalse);
    expect(config.feat.sampleRate, 16000);
  });

  test(
    'isolated runtime reports model initialization failure without paths',
    () async {
      const files = SherpaWhisperModelFiles(
        modelId: 'missing-test-model',
        encoderPath: '/secret/missing-encoder.onnx',
        decoderPath: '/secret/missing-decoder.onnx',
        tokensPath: '/secret/missing-tokens.txt',
      );

      await expectLater(
        IsolatedSherpaWhisperRuntime.start(files: files),
        throwsA(
          isA<SherpaWhisperWorkerException>().having(
            (error) => error.toString(),
            'safe message',
            allOf(
              contains('could not be initialized'),
              isNot(contains('/secret/')),
            ),
          ),
        ),
      );
    },
  );

  test('explicit language remains transcription rather than translation', () {
    const files = SherpaWhisperModelFiles(
      modelId: 'whisper-base-int8',
      encoderPath: '/encoder.onnx',
      decoderPath: '/decoder.onnx',
      tokensPath: '/tokens.txt',
    );

    final config = buildSherpaWhisperConfig(
      files: files,
      language: 'es',
      numThreads: 2,
    );

    expect(config.model.whisper.language, 'es');
    expect(config.model.whisper.task, 'transcribe');
  });
}
