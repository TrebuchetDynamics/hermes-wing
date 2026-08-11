import '../../../../shared/voice/voice_capture_service.dart';
import '../../../../shared/voice/voice_settings.dart';
import '../engine/android_voice_audio_engine.dart';
import '../models/offline_voice_model_manifests.dart';
import '../models/voice_model_pack_installer.dart';
import 'offline_voice_capture_service.dart';
import 'offline_voice_native_factory.dart';
import 'offline_whisper_engine.dart';
import 'offline_whisper_model_files.dart';

typedef OfflineWhisperRuntimeFactory =
    Future<OfflineWhisperRuntime> Function(OfflineWhisperModelFiles files);
typedef OfflineVadFactory =
    OfflineVoiceActivityDetector Function(String modelPath);

Future<OfflineWhisperRuntime> _createRuntime(OfflineWhisperModelFiles files) =>
    createNativeOfflineWhisperRuntime(files);

OfflineVoiceActivityDetector _createVad(String modelPath) =>
    createNativeOfflineVad(modelPath);

Future<VoiceCaptureService?> loadInstalledOfflineVoiceCapture({
  required VoiceModelPackInstaller installer,
  required VoiceLanguageMode Function() languageMode,
  OfflineSttModelTier tier = OfflineSttModelTier.recommended,
  VoicePcmCaptureEngine? audioEngine,
  OfflineWhisperRuntimeFactory runtimeFactory = _createRuntime,
  OfflineVadFactory vadFactory = _createVad,
}) async {
  final pack = await installer.installedPack(offlineSttManifestForTier(tier));
  if (pack == null) return null;
  return createOfflineVoiceCaptureFromPack(
    pack: pack,
    languageMode: languageMode,
    audioEngine: audioEngine ?? AndroidVoiceAudioEngine(),
    runtimeFactory: runtimeFactory,
    vadFactory: vadFactory,
  );
}

Future<VoiceCaptureService> createOfflineVoiceCaptureFromPack({
  required InstalledVoiceModelPack pack,
  required VoiceLanguageMode Function() languageMode,
  required VoicePcmCaptureEngine audioEngine,
  OfflineWhisperRuntimeFactory runtimeFactory = _createRuntime,
  OfflineVadFactory vadFactory = _createVad,
}) async {
  final files = OfflineWhisperModelFiles(
    modelId: '${pack.packId}@${pack.version}',
    encoderPath: pack.artifactFile('encoder').path,
    decoderPath: pack.artifactFile('decoder').path,
    tokensPath: pack.artifactFile('tokens').path,
  );
  final runtime = await runtimeFactory(files);
  try {
    final vad = vadFactory(pack.artifactFile('silero-vad').path);
    return OfflineVoiceCaptureService(
      audioEngine: audioEngine,
      vad: vad,
      transcriber: OfflineWhisperEngine(runtime),
      languageMode: languageMode,
      modelId: files.modelId,
    );
  } catch (_) {
    await runtime.dispose();
    rethrow;
  }
}
