class OfflineWhisperModelFiles {
  const OfflineWhisperModelFiles({
    required this.modelId,
    required this.encoderPath,
    required this.decoderPath,
    required this.tokensPath,
  });

  final String modelId;
  final String encoderPath;
  final String decoderPath;
  final String tokensPath;
}
