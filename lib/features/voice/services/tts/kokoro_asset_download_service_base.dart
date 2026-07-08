class KokoroAssetLocation {
  const KokoroAssetLocation({
    required this.modelPath,
    required this.voicesPath,
  });

  final String modelPath;
  final String voicesPath;
}

class KokoroAssetDownloadConfig {
  const KokoroAssetDownloadConfig({
    required this.modelUrl,
    required this.voicesJsonUrl,
    this.directoryName = 'kokoro',
  });

  factory KokoroAssetDownloadConfig.fromEnvironment() =>
      const KokoroAssetDownloadConfig(
        modelUrl: String.fromEnvironment('KOKORO_MODEL_URL'),
        voicesJsonUrl: String.fromEnvironment('KOKORO_VOICES_JSON_URL'),
      );

  final String modelUrl;
  final String voicesJsonUrl;
  final String directoryName;

  bool get isConfigured =>
      modelUrl.trim().isNotEmpty && voicesJsonUrl.trim().isNotEmpty;
}

abstract interface class KokoroAssetDownloadService {
  Future<KokoroAssetLocation> download();
}
