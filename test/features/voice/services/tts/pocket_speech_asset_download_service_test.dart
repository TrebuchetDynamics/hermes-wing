import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice/services/tts/pocket_speech_asset_download_service.dart';
import 'package:wing/shared/voice/voice_settings.dart';

void main() {
  test('release defaults configure both downloadable models', () {
    final config = PocketSpeechAssetDownloadConfig.fromEnvironment();

    expect(config.kitten.isConfigured, isTrue);
    expect(config.kokoro.isConfigured, isTrue);
  });

  test('each model requires HTTPS URLs and pinned SHA-256 digests', () {
    const hash =
        '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
    const ready = PocketSpeechDownloadSpec(
      modelUrl: 'https://example.com/model.onnx',
      voicesJsonUrl: 'https://example.com/voices.json',
      modelSha256: hash,
      voicesJsonSha256: hash,
    );
    const missing = PocketSpeechDownloadSpec(
      modelUrl: '',
      voicesJsonUrl: '',
      modelSha256: '',
      voicesJsonSha256: '',
    );
    const cleartext = PocketSpeechDownloadSpec(
      modelUrl: 'http://example.com/model.onnx',
      voicesJsonUrl: 'https://example.com/voices.json',
      modelSha256: hash,
      voicesJsonSha256: hash,
    );

    expect(ready.isConfigured, isTrue);
    expect(missing.isConfigured, isFalse);
    expect(cleartext.isConfigured, isFalse);

    final service = createDefaultPocketSpeechAssetDownloadService(
      config: const PocketSpeechAssetDownloadConfig(
        kitten: ready,
        kokoro: missing,
      ),
    );
    expect(service?.isConfigured(PocketSpeechModel.kitten), isTrue);
    expect(service?.isConfigured(PocketSpeechModel.kokoro), isFalse);
  });
}
