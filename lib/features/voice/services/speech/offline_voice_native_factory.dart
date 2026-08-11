import 'offline_voice_capture_service.dart';
import 'offline_voice_native_factory_stub.dart'
    if (dart.library.io) 'offline_voice_native_factory_io.dart'
    as platform;
import 'offline_whisper_engine.dart';
import 'offline_whisper_model_files.dart';

Future<OfflineWhisperRuntime> createNativeOfflineWhisperRuntime(
  OfflineWhisperModelFiles files,
) => platform.createNativeOfflineWhisperRuntime(files);

OfflineVoiceActivityDetector createNativeOfflineVad(String modelPath) =>
    platform.createNativeOfflineVad(modelPath);
