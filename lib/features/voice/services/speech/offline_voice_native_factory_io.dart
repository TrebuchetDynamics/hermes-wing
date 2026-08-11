import 'offline_voice_capture_service.dart';
import 'offline_whisper_engine.dart';
import 'offline_whisper_model_files.dart';
import 'sherpa_silero_vad.dart';
import 'sherpa_whisper_runtime.dart';

Future<OfflineWhisperRuntime> createNativeOfflineWhisperRuntime(
  OfflineWhisperModelFiles files,
) => IsolatedSherpaWhisperRuntime.start(
  files: SherpaWhisperModelFiles(
    modelId: files.modelId,
    encoderPath: files.encoderPath,
    decoderPath: files.decoderPath,
    tokensPath: files.tokensPath,
  ),
);

OfflineVoiceActivityDetector createNativeOfflineVad(String modelPath) =>
    SherpaSileroVoiceActivityDetector.fromModel(modelPath: modelPath);
