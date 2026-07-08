import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'kokoro_asset_download_service_base.dart';

class IoKokoroAssetDownloadService implements KokoroAssetDownloadService {
  const IoKokoroAssetDownloadService({required this.config});

  final KokoroAssetDownloadConfig config;

  @override
  Future<KokoroAssetLocation> download() async {
    if (!config.isConfigured) {
      throw StateError('Kokoro asset URLs are not configured.');
    }
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/${config.directoryName}');
    await dir.create(recursive: true);
    final model = File('${dir.path}/kokoro-v1.0.onnx');
    final voices = File('${dir.path}/voices.json');
    await _download(config.modelUrl, model);
    await _download(config.voicesJsonUrl, voices);
    return KokoroAssetLocation(modelPath: model.path, voicesPath: voices.path);
  }

  Future<void> _download(String url, File file) async {
    final request = await HttpClient().getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('GET $url failed with ${response.statusCode}');
    }
    final sink = file.openWrite();
    try {
      await response.pipe(sink);
    } finally {
      await sink.close();
    }
  }
}

KokoroAssetDownloadService? createDefaultKokoroAssetDownloadService({
  KokoroAssetDownloadConfig config = const KokoroAssetDownloadConfig(
    modelUrl: String.fromEnvironment('KOKORO_MODEL_URL'),
    voicesJsonUrl: String.fromEnvironment('KOKORO_VOICES_JSON_URL'),
  ),
}) => config.isConfigured ? IoKokoroAssetDownloadService(config: config) : null;
