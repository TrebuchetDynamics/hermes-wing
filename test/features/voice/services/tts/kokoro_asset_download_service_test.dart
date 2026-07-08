import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/voice/services/tts/kokoro_asset_download_service.dart';

void main() {
  test('download config is unavailable until both urls are present', () {
    const missing = KokoroAssetDownloadConfig(modelUrl: '', voicesJsonUrl: '');
    const partial = KokoroAssetDownloadConfig(
      modelUrl: 'https://example.com/model.onnx',
      voicesJsonUrl: '',
    );
    const ready = KokoroAssetDownloadConfig(
      modelUrl: 'https://example.com/model.onnx',
      voicesJsonUrl: 'https://example.com/voices.json',
    );

    expect(missing.isConfigured, isFalse);
    expect(partial.isConfigured, isFalse);
    expect(ready.isConfigured, isTrue);
    expect(createDefaultKokoroAssetDownloadService(config: missing), isNull);
  });
}
