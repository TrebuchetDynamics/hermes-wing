import 'offline_voice_capture_service.dart';
import 'offline_whisper_engine.dart';
import 'offline_whisper_model_files.dart';

Future<OfflineWhisperRuntime> createNativeOfflineWhisperRuntime(
  OfflineWhisperModelFiles files,
) => throw UnsupportedError('Offline speech is unavailable on this platform.');

OfflineVoiceActivityDetector createNativeOfflineVad(String modelPath) =>
    throw UnsupportedError('Offline speech is unavailable on this platform.');
