import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice/services/engine/android_voice_audio_engine.dart';
import 'package:wing/features/voice/services/models/voice_model_pack_installer.dart';
import 'package:wing/features/voice/services/speech/offline_voice_capture_factory.dart';
import 'package:wing/features/voice/services/speech/offline_voice_capture_service.dart';
import 'package:wing/features/voice/services/speech/offline_whisper_engine.dart';
import 'package:wing/features/voice/services/speech/offline_whisper_model_files.dart';
import 'package:wing/shared/voice/voice_settings.dart';

void main() {
  test('builds offline capture only from installed named artifacts', () async {
    final directory = await Directory.systemTemp.createTemp(
      'wing-offline-pack-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final pack = InstalledVoiceModelPack(
      packId: 'whisper-base-int8-en-es',
      version: 'v1',
      provenance: 'verified test pack',
      directory: directory,
      artifactPaths: const <String, String>{
        'encoder': 'whisper/encoder.onnx',
        'decoder': 'whisper/decoder.onnx',
        'tokens': 'whisper/tokens.txt',
        'silero-vad': 'vad/silero.onnx',
      },
    );
    OfflineWhisperModelFiles? files;
    String? vadPath;

    final service = await createOfflineVoiceCaptureFromPack(
      pack: pack,
      languageMode: () => VoiceLanguageMode.autoEnglishSpanish,
      audioEngine: _NoopAudioEngine(),
      runtimeFactory: (value) async {
        files = value;
        return _NoopRuntime();
      },
      vadFactory: (path) {
        vadPath = path;
        return _NoopVad();
      },
    );

    expect(service, isA<OfflineVoiceCaptureService>());
    expect(files?.encoderPath, '${directory.path}/whisper/encoder.onnx');
    expect(files?.decoderPath, '${directory.path}/whisper/decoder.onnx');
    expect(files?.tokensPath, '${directory.path}/whisper/tokens.txt');
    expect(vadPath, '${directory.path}/vad/silero.onnx');
  });
}

class _NoopAudioEngine implements VoicePcmCaptureEngine {
  @override
  Stream<VoiceAudioChunk> get audioChunks => const Stream.empty();

  @override
  Future<void> startCapture({required int generation}) async {}

  @override
  Future<void> stopCapture({required int generation}) async {}
}

class _NoopRuntime implements OfflineWhisperRuntime {
  @override
  Future<void> dispose() async {}

  @override
  Future<OfflineWhisperResult> transcribe({
    required Float32List samples,
    required int sampleRate,
    required String? language,
  }) async => const OfflineWhisperResult(text: '', language: '');
}

class _NoopVad implements OfflineVoiceActivityDetector {
  @override
  VoiceActivity accept(Uint8List pcm16) => VoiceActivity.silence;

  @override
  void reset() {}
}
