import 'voice_model_pack.dart';

enum OfflineSttModelTier {
  compact('Compact · Whisper Tiny', 'About 106 MB'),
  recommended('Recommended · Whisper Base', 'About 163 MB'),
  quality('Quality · Whisper Small', 'About 378 MB');

  const OfflineSttModelTier(this.label, this.downloadSize);

  final String label;
  final String downloadSize;
}

const _tinyRevision = '65176e2deb88badc814a94058666cadccc29b61c';
const _baseRevision = 'bb53ee204431c90d314c1cc08d28d23e5b7927cc';
const _smallRevision = '8f3c18b358db4d1f2fc1eae49d75cd20989e4309';
const _sherpaReleaseRoot =
    'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models';
const _sileroSha256 =
    '6b99cbfd39246b6706f98ec13c7c50c6b299181f2474fa05cbc8046acc274396';
const _tokensSha256 =
    'b34b360dbb493e781e479794586d661700670d65564001f23024971d1f2fa126';

/// Integrity-pinned multilingual Whisper Tiny INT8 plus Silero VAD v5.
final VoiceModelPackManifest whisperTinyInt8EnglishSpanishPack = _whisperPack(
  tierName: 'tiny',
  revision: _tinyRevision,
  version: '65176e2d-silero-v5',
  encoderBytes: 12937772,
  encoderSha256:
      'd24fb083ae3b1041fc24e97971d60e280c9342201fbb67b0ab428a8b4a51a434',
  decoderBytes: 89855401,
  decoderSha256:
      'd2fece8dd42771f1df975c6c0445770d0c292bf7547c2cae04a6c0cc57540925',
);

/// Integrity-pinned multilingual Whisper Base INT8 plus Silero VAD v5.
///
/// Whisper uses its immutable Hugging Face repository revision and every file
/// is independently size- and SHA-256-pinned. The pack performs transcription,
/// never translation, and supports Auto, English, and Spanish recognition.
final VoiceModelPackManifest whisperBaseInt8EnglishSpanishPack = _whisperPack(
  tierName: 'base',
  revision: _baseRevision,
  version: 'bb53ee20-silero-v5',
  encoderBytes: 29120534,
  encoderSha256:
      '0b8fb1304b6109976038efff5ace81720e00386f3ff6b54ee8c75291ca0a1e11',
  decoderBytes: 130672026,
  decoderSha256:
      '9759d217388a01b3a4c7c15533201067b48ae819c4daafc8624e64b9409dc02d',
);

/// Integrity-pinned multilingual Whisper Small INT8 plus Silero VAD v5.
final VoiceModelPackManifest whisperSmallInt8EnglishSpanishPack = _whisperPack(
  tierName: 'small',
  revision: _smallRevision,
  version: '8f3c18b3-silero-v5',
  encoderBytes: 112442483,
  encoderSha256:
      '4cbe7b22fa9026b843b60a68640c747de05bafb1a11b57edc0e66c232d9f33a9',
  decoderBytes: 262226114,
  decoderSha256:
      'acad50b5c782696e91b55914cc5ab4f756f1532f76e22aa6fc615f39fb69a8ee',
);

VoiceModelPackManifest offlineSttManifestForTier(OfflineSttModelTier tier) =>
    switch (tier) {
      OfflineSttModelTier.compact => whisperTinyInt8EnglishSpanishPack,
      OfflineSttModelTier.recommended => whisperBaseInt8EnglishSpanishPack,
      OfflineSttModelTier.quality => whisperSmallInt8EnglishSpanishPack,
    };

VoiceModelPackManifest _whisperPack({
  required String tierName,
  required String revision,
  required String version,
  required int encoderBytes,
  required String encoderSha256,
  required int decoderBytes,
  required String decoderSha256,
}) {
  final repository = 'csukuangfj/sherpa-onnx-whisper-$tierName';
  final root = 'https://huggingface.co/$repository/resolve/$revision';
  return VoiceModelPackManifest(
    packId: 'whisper-$tierName-int8-en-es',
    version: version,
    provenance:
        '$repository@$revision; '
        'k2-fsa/sherpa-onnx asr-models silero_vad_v5.onnx',
    artifacts: <VoiceModelPackArtifact>[
      VoiceModelPackArtifact(
        name: 'encoder',
        path: 'whisper/$tierName-encoder.int8.onnx',
        uri: Uri.parse('$root/$tierName-encoder.int8.onnx'),
        expectedBytes: encoderBytes,
        sha256: encoderSha256,
      ),
      VoiceModelPackArtifact(
        name: 'decoder',
        path: 'whisper/$tierName-decoder.int8.onnx',
        uri: Uri.parse('$root/$tierName-decoder.int8.onnx'),
        expectedBytes: decoderBytes,
        sha256: decoderSha256,
      ),
      VoiceModelPackArtifact(
        name: 'tokens',
        path: 'whisper/$tierName-tokens.txt',
        uri: Uri.parse('$root/$tierName-tokens.txt'),
        expectedBytes: 816730,
        sha256: _tokensSha256,
      ),
      VoiceModelPackArtifact(
        name: 'silero-vad',
        path: 'vad/silero_vad_v5.onnx',
        uri: Uri.parse('$_sherpaReleaseRoot/silero_vad_v5.onnx'),
        expectedBytes: 2313101,
        sha256: _sileroSha256,
      ),
    ],
  );
}
