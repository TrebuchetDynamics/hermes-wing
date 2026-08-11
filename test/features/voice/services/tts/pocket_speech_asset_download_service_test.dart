import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice/services/tts/pocket_speech_asset_download_service.dart';
import 'package:wing/features/voice/services/tts/pocket_speech_asset_download_service_io.dart'
    as io;
import 'package:wing/features/voice/services/tts/pocket_speech_model_manifests.dart';
import 'package:wing/shared/voice/voice_settings.dart';

void main() {
  test('release defaults configure exact download sizes for progress', () {
    final config = PocketSpeechAssetDownloadConfig.fromEnvironment();

    expect(config.kitten.isConfigured, isTrue);
    expect(config.kitten.totalBytes, 26453800);
    expect(config.kokoro.isConfigured, isTrue);
    expect(config.kokoro.totalBytes, 331147356);
  });

  test('release defaults pin immutable model revisions', () {
    final config = PocketSpeechAssetDownloadConfig.fromEnvironment();

    expect(
      Uri.parse(config.kitten.modelUrl).path,
      contains('/resolve/84781d74e29ee25217551556398b42f80593a813/'),
    );
    expect(Uri.parse(config.kitten.modelUrl).path, isNot(contains('/main/')));
    expect(
      Uri.parse(config.kokoro.modelUrl).path,
      contains('/releases/download/model-files-v1.0/'),
    );
  });

  test('release default uses the shared transactional installer', () {
    final service = io.createDefaultPocketSpeechAssetDownloadService();

    expect(service, isA<io.TransactionalPocketSpeechAssetDownloadService>());
  });

  test('Pocket Speech specs map to generic transactional manifests', () {
    final config = PocketSpeechAssetDownloadConfig.fromEnvironment();

    final kitten = pocketSpeechManifest(
      PocketSpeechModel.kitten,
      config.kitten,
    );
    final kokoro = pocketSpeechManifest(
      PocketSpeechModel.kokoro,
      config.kokoro,
    );

    expect(kitten.packId, 'pocket-speech-kitten');
    expect(kitten.version, '84781d74e29ee25217551556398b42f80593a813');
    expect(kitten.provenance, 'KittenML/kitten-tts-nano-0.8-int8');
    expect(kitten.artifacts.map((artifact) => artifact.path), [
      'model.onnx',
      'voices.json',
    ]);
    expect(kitten.totalBytes, config.kitten.totalBytes);

    expect(kokoro.packId, 'pocket-speech-kokoro');
    expect(kokoro.version, 'model-files-v1.0');
    expect(kokoro.provenance, 'thewh1teagle/kokoro-onnx');
    expect(kokoro.artifacts.map((artifact) => artifact.path), [
      'model.onnx',
      'voices.bin',
    ]);
    expect(kokoro.totalBytes, config.kokoro.totalBytes);
  });

  test('download progress reports the active part and aggregate fraction', () {
    const progress = PocketSpeechDownloadProgress(
      model: PocketSpeechModel.kitten,
      part: PocketSpeechDownloadPart.model,
      receivedBytes: 13226900,
      totalBytes: 26453800,
    );

    expect(progress.fraction, 0.5);
    expect(progress.part.label, 'Model');
  });

  test('each model requires HTTPS URLs, sizes, and pinned digests', () {
    const hash =
        '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
    const ready = PocketSpeechDownloadSpec(
      modelUrl: 'https://example.com/model.onnx',
      voicesJsonUrl: 'https://example.com/voices.json',
      modelSha256: hash,
      voicesJsonSha256: hash,
      modelBytes: 10,
      voicesJsonBytes: 5,
    );
    const missing = PocketSpeechDownloadSpec(
      modelUrl: '',
      voicesJsonUrl: '',
      modelSha256: '',
      voicesJsonSha256: '',
      modelBytes: 0,
      voicesJsonBytes: 0,
    );
    const cleartext = PocketSpeechDownloadSpec(
      modelUrl: 'http://example.com/model.onnx',
      voicesJsonUrl: 'https://example.com/voices.json',
      modelSha256: hash,
      voicesJsonSha256: hash,
      modelBytes: 10,
      voicesJsonBytes: 5,
    );

    expect(ready.isConfigured, isTrue);
    expect(missing.isConfigured, isFalse);
    expect(cleartext.isConfigured, isFalse);

    final service = io.createDefaultPocketSpeechAssetDownloadService(
      config: const PocketSpeechAssetDownloadConfig(
        kitten: ready,
        kokoro: missing,
      ),
    );
    expect(service?.isConfigured(PocketSpeechModel.kitten), isTrue);
    expect(service?.isConfigured(PocketSpeechModel.kokoro), isFalse);
  });
}
