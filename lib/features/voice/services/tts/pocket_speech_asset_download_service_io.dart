import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../shared/voice/voice_settings.dart';
import '../models/default_voice_model_pack_installer.dart';
import '../models/voice_model_pack_installer.dart';
import 'pocket_speech_asset_download_service_base.dart';
import 'pocket_speech_model_manifests.dart';

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

typedef PocketSpeechModelPackInstallerFactory =
    Future<VoiceModelPackInstaller> Function();

/// Production Pocket Speech storage backed by the same transactional installer
/// as offline STT packs: immutable metadata, recovery, rollback, and root-wide
/// operation serialization are therefore shared by both model families.
final class TransactionalPocketSpeechAssetDownloadService
    implements PocketSpeechAssetDownloadService {
  TransactionalPocketSpeechAssetDownloadService({
    required this.config,
    PocketSpeechModelPackInstallerFactory? installerFactory,
  }) : _installerFactory =
           installerFactory ?? createDefaultVoiceModelPackInstaller;

  final PocketSpeechAssetDownloadConfig config;
  final PocketSpeechModelPackInstallerFactory _installerFactory;
  Future<VoiceModelPackInstaller>? _installer;

  Future<VoiceModelPackInstaller> get _resolvedInstaller =>
      _installer ??= _installerFactory();

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
    final manifest = pocketSpeechManifest(model, spec);
    final installer = await _resolvedInstaller;
    final installed = await installer.install(
      manifest,
      onProgress: (progress) => onProgress?.call(
        PocketSpeechDownloadProgress(
          model: model,
          part: progress.artifactName == 'model'
              ? PocketSpeechDownloadPart.model
              : PocketSpeechDownloadPart.voices,
          receivedBytes: progress.receivedBytes,
          totalBytes: progress.totalBytes,
        ),
      ),
    );
    return _voicePack(model, installed);
  }

  @override
  Future<PocketSpeechVoicePack?> installedPack(PocketSpeechModel model) async {
    final spec = config.specFor(model);
    if (!spec.isConfigured) return null;
    final installer = await _resolvedInstaller;
    final installed = await installer.installedPack(
      pocketSpeechManifest(model, spec),
    );
    return installed == null ? null : _voicePack(model, installed);
  }

  @override
  Future<void> delete(PocketSpeechModel model) async {
    final spec = config.specFor(model);
    if (!spec.isConfigured) return;
    final manifest = pocketSpeechManifest(model, spec);
    final installer = await _resolvedInstaller;
    await installer.delete(manifest.packId, manifest.version);
  }

  PocketSpeechVoicePack _voicePack(
    PocketSpeechModel model,
    InstalledVoiceModelPack installed,
  ) => PocketSpeechVoicePack(
    model: model,
    modelPath: installed.artifactFile('model').path,
    voicesPath: installed.artifactFile('voices').path,
  );
}

PocketSpeechAssetDownloadService?
createDefaultPocketSpeechAssetDownloadService({
  PocketSpeechAssetDownloadConfig? config,
}) {
  final effective = config ?? PocketSpeechAssetDownloadConfig.fromEnvironment();
  return effective.hasConfiguredModel
      ? TransactionalPocketSpeechAssetDownloadService(config: effective)
      : null;
}
