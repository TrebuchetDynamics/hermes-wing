import '../../../../shared/voice/voice_settings.dart';
import '../models/voice_model_pack.dart';
import 'pocket_speech_asset_download_service_base.dart';

/// Converts Pocket Speech's release-pinned model specs into the shared,
/// transactional voice-model-pack representation.
VoiceModelPackManifest pocketSpeechManifest(
  PocketSpeechModel model,
  PocketSpeechDownloadSpec spec,
) {
  final identity = switch (model) {
    PocketSpeechModel.kitten => const (
      packId: 'pocket-speech-kitten',
      version: '84781d74e29ee25217551556398b42f80593a813',
      provenance: 'KittenML/kitten-tts-nano-0.8-int8',
      voicesPath: 'voices.json',
    ),
    PocketSpeechModel.kokoro => const (
      packId: 'pocket-speech-kokoro',
      version: 'model-files-v1.0',
      provenance: 'thewh1teagle/kokoro-onnx',
      voicesPath: 'voices.bin',
    ),
  };
  return VoiceModelPackManifest(
    packId: identity.packId,
    version: identity.version,
    provenance: identity.provenance,
    artifacts: <VoiceModelPackArtifact>[
      VoiceModelPackArtifact(
        name: 'model',
        path: 'model.onnx',
        uri: Uri.parse(spec.modelUrl),
        expectedBytes: spec.modelBytes,
        sha256: spec.modelSha256,
      ),
      VoiceModelPackArtifact(
        name: 'voices',
        path: identity.voicesPath,
        uri: Uri.parse(spec.voicesJsonUrl),
        expectedBytes: spec.voicesJsonBytes,
        sha256: spec.voicesJsonSha256,
      ),
    ],
  );
}
