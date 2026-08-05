import '../../../../shared/voice/voice_settings.dart';

enum PocketSpeechDownloadPart {
  model('Model'),
  voices('Voice data');

  const PocketSpeechDownloadPart(this.label);

  final String label;
}

class PocketSpeechDownloadProgress {
  const PocketSpeechDownloadProgress({
    required this.model,
    required this.part,
    required this.receivedBytes,
    required this.totalBytes,
  });

  final PocketSpeechModel model;
  final PocketSpeechDownloadPart part;
  final int receivedBytes;
  final int totalBytes;

  double get fraction =>
      totalBytes <= 0 ? 0 : (receivedBytes / totalBytes).clamp(0.0, 1.0);
}

typedef PocketSpeechDownloadProgressCallback =
    void Function(PocketSpeechDownloadProgress progress);

class PocketSpeechDownloadSpec {
  const PocketSpeechDownloadSpec({
    required this.modelUrl,
    required this.voicesJsonUrl,
    required this.modelSha256,
    required this.voicesJsonSha256,
    required this.modelBytes,
    required this.voicesJsonBytes,
  });

  final String modelUrl;
  final String voicesJsonUrl;
  final String modelSha256;
  final String voicesJsonSha256;
  final int modelBytes;
  final int voicesJsonBytes;

  int get totalBytes => modelBytes + voicesJsonBytes;

  bool get isConfigured {
    final modelUri = Uri.tryParse(modelUrl.trim());
    final voicesUri = Uri.tryParse(voicesJsonUrl.trim());
    final hashPattern = RegExp(r'^[a-fA-F0-9]{64}$');
    return modelUri?.scheme == 'https' &&
        modelUri!.host.isNotEmpty &&
        voicesUri?.scheme == 'https' &&
        voicesUri!.host.isNotEmpty &&
        hashPattern.hasMatch(modelSha256.trim()) &&
        hashPattern.hasMatch(voicesJsonSha256.trim()) &&
        modelBytes > 0 &&
        voicesJsonBytes > 0;
  }
}

class PocketSpeechAssetDownloadConfig {
  const PocketSpeechAssetDownloadConfig({
    required this.kitten,
    required this.kokoro,
  });

  factory PocketSpeechAssetDownloadConfig.fromEnvironment() => const PocketSpeechAssetDownloadConfig(
    kitten: PocketSpeechDownloadSpec(
      modelUrl: String.fromEnvironment(
        'KITTEN_MODEL_URL',
        defaultValue:
            'https://huggingface.co/KittenML/kitten-tts-nano-0.8-int8/resolve/main/kitten_tts_nano_v0_8.onnx?download=true',
      ),
      voicesJsonUrl: String.fromEnvironment(
        'KITTEN_VOICES_JSON_URL',
        defaultValue:
            'https://github.com/TrebuchetDynamics/pocket-speech-dart/releases/download/runtime-assets-v1/kitten-nano-int8-jasper-voices.json',
      ),
      modelSha256: String.fromEnvironment(
        'KITTEN_MODEL_SHA256',
        defaultValue:
            'f7b0afcbee92870b32b8e0276d855b954dc25470c9f051b376ac7eee537c76fc',
      ),
      voicesJsonSha256: String.fromEnvironment(
        'KITTEN_VOICES_JSON_SHA256',
        defaultValue:
            'f9fcbecb209f112ff679905a4c9ff357dcd979a2ed0ba7ba516815d951f32b52',
      ),
      modelBytes: int.fromEnvironment(
        'KITTEN_MODEL_BYTES',
        defaultValue: 24369971,
      ),
      voicesJsonBytes: int.fromEnvironment(
        'KITTEN_VOICES_JSON_BYTES',
        defaultValue: 2083829,
      ),
    ),
    kokoro: PocketSpeechDownloadSpec(
      modelUrl: String.fromEnvironment(
        'KOKORO_MODEL_URL',
        defaultValue:
            'https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/kokoro-v1.0.onnx',
      ),
      voicesJsonUrl: String.fromEnvironment(
        'KOKORO_VOICES_JSON_URL',
        defaultValue:
            'https://github.com/TrebuchetDynamics/pocket-speech-dart/releases/download/runtime-assets-v1/kokoro-af_heart-ef_dora-voices.json',
      ),
      modelSha256: String.fromEnvironment(
        'KOKORO_MODEL_SHA256',
        defaultValue:
            '7d5df8ecf7d4b1878015a32686053fd0eebe2bc377234608764cc0ef3636a6c5',
      ),
      voicesJsonSha256: String.fromEnvironment(
        'KOKORO_VOICES_JSON_SHA256',
        defaultValue:
            '01788eb0bc097dd0d2964072361fa1bc98d7fdb847bab3cdc6be4cc34109a566',
      ),
      modelBytes: int.fromEnvironment(
        'KOKORO_MODEL_BYTES',
        defaultValue: 325532387,
      ),
      voicesJsonBytes: int.fromEnvironment(
        'KOKORO_VOICES_JSON_BYTES',
        defaultValue: 5614969,
      ),
    ),
  );

  final PocketSpeechDownloadSpec kitten;
  final PocketSpeechDownloadSpec kokoro;

  PocketSpeechDownloadSpec specFor(PocketSpeechModel model) =>
      model == PocketSpeechModel.kitten ? kitten : kokoro;

  bool get hasConfiguredModel => kitten.isConfigured || kokoro.isConfigured;
}

abstract interface class PocketSpeechAssetDownloadService {
  bool isConfigured(PocketSpeechModel model);
  Future<PocketSpeechVoicePack> download(
    PocketSpeechModel model, {
    PocketSpeechDownloadProgressCallback? onProgress,
  });
  Future<PocketSpeechVoicePack?> installedPack(PocketSpeechModel model);
  Future<void> delete(PocketSpeechModel model);
}
