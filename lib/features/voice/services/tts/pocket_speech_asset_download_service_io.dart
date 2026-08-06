import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../shared/voice/voice_settings.dart';
import 'pocket_speech_asset_download_service_base.dart';

class IoPocketSpeechAssetDownloadService
    implements PocketSpeechAssetDownloadService {
  const IoPocketSpeechAssetDownloadService({required this.config});

  final PocketSpeechAssetDownloadConfig config;

  @override
  bool isConfigured(PocketSpeechModel model) =>
      config.specFor(model).isConfigured;

  @override
  Future<PocketSpeechVoicePack> download(
    PocketSpeechModel model, {
    PocketSpeechDownloadProgressCallback? onProgress,
  }) async {
    final spec = config.specFor(model);
    if (!spec.isConfigured) {
      throw StateError('${model.label} download is not configured.');
    }
    final dir = await _modelDirectory(model);
    final staging = Directory('${dir.path}.download');
    if (await staging.exists()) await staging.delete(recursive: true);
    await staging.create(recursive: true);
    final modelFile = File('${dir.path}/model.onnx');
    final voicesFile = File('${dir.path}/voices.json');
    final modelTemp = File('${staging.path}/model.onnx');
    final voicesTemp = File('${staging.path}/voices.json');
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      await _download(
        client,
        spec.modelUrl,
        modelTemp,
        expectedSha256: spec.modelSha256,
        expectedBytes: spec.modelBytes,
        onProgress: (received) => onProgress?.call(
          PocketSpeechDownloadProgress(
            model: model,
            part: PocketSpeechDownloadPart.model,
            receivedBytes: received,
            totalBytes: spec.totalBytes,
          ),
        ),
      );
      await _download(
        client,
        spec.voicesJsonUrl,
        voicesTemp,
        expectedSha256: spec.voicesJsonSha256,
        expectedBytes: spec.voicesJsonBytes,
        onProgress: (received) => onProgress?.call(
          PocketSpeechDownloadProgress(
            model: model,
            part: PocketSpeechDownloadPart.voices,
            receivedBytes: spec.modelBytes + received,
            totalBytes: spec.totalBytes,
          ),
        ),
      );
      final decoded = jsonDecode(await voicesTemp.readAsString());
      if (decoded is! Map) {
        throw const FormatException('Pocket Speech voices must be JSON.');
      }
      await _replaceDirectory(staging, dir);
    } finally {
      client.close(force: true);
      if (await staging.exists()) await staging.delete(recursive: true);
    }
    return PocketSpeechVoicePack(
      model: model,
      modelPath: modelFile.path,
      voicesPath: voicesFile.path,
    );
  }

  @override
  Future<PocketSpeechVoicePack?> installedPack(PocketSpeechModel model) async {
    final spec = config.specFor(model);
    if (!spec.isConfigured) return null;
    try {
      final dir = await _modelDirectory(model);
      final modelFile = File('${dir.path}/model.onnx');
      final voicesFile = File('${dir.path}/voices.json');
      if (!await _matches(modelFile, spec.modelBytes, spec.modelSha256) ||
          !await _matches(
            voicesFile,
            spec.voicesJsonBytes,
            spec.voicesJsonSha256,
          ) ||
          jsonDecode(await voicesFile.readAsString()) is! Map) {
        return null;
      }
      return PocketSpeechVoicePack(
        model: model,
        modelPath: modelFile.path,
        voicesPath: voicesFile.path,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> delete(PocketSpeechModel model) async {
    final dir = await _modelDirectory(model);
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<Directory> _modelDirectory(PocketSpeechModel model) async {
    final base = await getApplicationSupportDirectory();
    return Directory('${base.path}/pocket_speech/${model.name}');
  }

  Future<bool> _matches(File file, int bytes, String expectedSha256) async =>
      await file.exists() &&
      await file.length() == bytes &&
      (await sha256.bind(file.openRead()).first).toString().toLowerCase() ==
          expectedSha256.trim().toLowerCase();

  Future<void> _download(
    HttpClient client,
    String url,
    File file, {
    required String expectedSha256,
    required int expectedBytes,
    required void Function(int receivedBytes) onProgress,
  }) async {
    if (await file.exists()) await file.delete();
    final response = await _openHttps(client, Uri.parse(url));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('GET $url failed with ${response.statusCode}');
    }
    if (response.contentLength >= 0 &&
        response.contentLength != expectedBytes) {
      throw StateError('Pocket Speech asset size mismatch.');
    }
    final sink = file.openWrite();
    var received = 0;
    try {
      await for (final chunk in response.timeout(const Duration(seconds: 30))) {
        received += chunk.length;
        if (received > expectedBytes) {
          throw StateError('Pocket Speech asset exceeded its expected size.');
        }
        sink.add(chunk);
        onProgress(received);
      }
    } finally {
      await sink.close();
    }
    if (received != expectedBytes) {
      throw StateError('Pocket Speech asset size mismatch.');
    }
    final digest = await sha256.bind(file.openRead()).first;
    if (digest.toString().toLowerCase() !=
        expectedSha256.trim().toLowerCase()) {
      throw StateError('Pocket Speech asset checksum mismatch.');
    }
  }

  Future<HttpClientResponse> _openHttps(HttpClient client, Uri uri) async {
    var current = uri;
    for (var redirects = 0; redirects <= 5; redirects++) {
      final request = await client.getUrl(current);
      request.followRedirects = false;
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      if (!const {
        HttpStatus.movedPermanently,
        HttpStatus.found,
        HttpStatus.seeOther,
        HttpStatus.temporaryRedirect,
        HttpStatus.permanentRedirect,
      }.contains(response.statusCode)) {
        return response;
      }
      final location = response.headers.value(HttpHeaders.locationHeader);
      await response.drain<void>();
      if (location == null || redirects == 5) {
        throw HttpException(
          'Pocket Speech asset redirect failed.',
          uri: current,
        );
      }
      final next = current.resolve(location);
      if (next.scheme != 'https' || next.host.isEmpty) {
        throw StateError('Pocket Speech asset redirect must use HTTPS.');
      }
      current = next;
    }
    throw StateError('Pocket Speech asset redirected too many times.');
  }

  Future<void> _replaceDirectory(
    Directory source,
    Directory destination,
  ) async {
    final backup = Directory('${destination.path}.backup');
    if (await backup.exists()) {
      if (await destination.exists()) {
        await backup.delete(recursive: true);
      } else {
        await backup.rename(destination.path);
      }
    }
    if (await destination.exists()) await destination.rename(backup.path);
    try {
      await source.rename(destination.path);
      if (await backup.exists()) await backup.delete(recursive: true);
    } catch (_) {
      if (await destination.exists()) await destination.delete(recursive: true);
      if (await backup.exists()) await backup.rename(destination.path);
      rethrow;
    }
  }
}

PocketSpeechAssetDownloadService?
createDefaultPocketSpeechAssetDownloadService({
  PocketSpeechAssetDownloadConfig? config,
}) {
  final effective = config ?? PocketSpeechAssetDownloadConfig.fromEnvironment();
  return effective.hasConfiguredModel
      ? IoPocketSpeechAssetDownloadService(config: effective)
      : null;
}
