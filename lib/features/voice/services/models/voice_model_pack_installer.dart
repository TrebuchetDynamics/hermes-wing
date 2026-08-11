import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'voice_model_pack.dart';

typedef VoiceModelPackAdoption =
    Future<void> Function(Directory staging, Directory destination);
typedef VoiceModelPackProgressCallback =
    void Function(VoiceModelPackProgress progress);

final class VoiceModelPackProgress {
  const VoiceModelPackProgress({
    required this.receivedBytes,
    required this.totalBytes,
    required this.artifactName,
  });

  final int receivedBytes;
  final int totalBytes;
  final String artifactName;

  double get fraction => totalBytes == 0 ? 0 : receivedBytes / totalBytes;
}

/// A validated model pack together with immutable identity metadata.
final class InstalledVoiceModelPack {
  InstalledVoiceModelPack({
    required this.packId,
    required this.version,
    required this.provenance,
    required this.directory,
    required Map<String, String> artifactPaths,
  }) : _artifactPaths = Map<String, String>.unmodifiable(artifactPaths);

  final String packId;
  final String version;
  final String provenance;
  final Directory directory;
  final Map<String, String> _artifactPaths;

  File artifactFile(String name) {
    final path = _artifactPaths[name];
    if (path == null) {
      throw ArgumentError.value(name, 'name', 'Unknown artifact');
    }
    return File('${directory.path}/$path');
  }
}

/// Transactionally downloads and installs integrity-pinned voice model packs.
final class VoiceModelPackInstaller {
  VoiceModelPackInstaller({
    required this.rootDirectory,
    VoiceModelPackAdoption? adoptStaging,
  }) : _adoptStaging = adoptStaging ?? _renameDirectory;

  static const String metadataFileName = '.pack.json';
  static final Map<String, Future<void>> _operationTails =
      <String, Future<void>>{};

  final Directory rootDirectory;
  final VoiceModelPackAdoption _adoptStaging;

  Future<T> _serialize<T>(Future<T> Function() operation) async {
    final key = rootDirectory.absolute.path;
    final predecessor = _operationTails[key] ?? Future<void>.value();
    final completion = Completer<void>();
    _operationTails[key] = completion.future;
    await predecessor;
    try {
      return await operation();
    } finally {
      completion.complete();
      if (identical(_operationTails[key], completion.future)) {
        final _ = _operationTails.remove(key);
      }
    }
  }

  static Future<void> _renameDirectory(
    Directory staging,
    Directory destination,
  ) async {
    await staging.rename(destination.path);
  }

  Future<InstalledVoiceModelPack> install(
    VoiceModelPackManifest manifest, {
    VoiceModelPackProgressCallback? onProgress,
  }) => _serialize(() => _install(manifest, onProgress: onProgress));

  Future<InstalledVoiceModelPack> _install(
    VoiceModelPackManifest manifest, {
    VoiceModelPackProgressCallback? onProgress,
  }) async {
    final parent = Directory('${rootDirectory.path}/${manifest.packId}');
    await parent.create(recursive: true);
    final destination = Directory('${parent.path}/${manifest.version}');
    final backup = Directory('${destination.path}.backup');
    await _recover(destination, backup);
    final staging = await parent.createTemp('.${manifest.version}.download-');
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      var completedBytes = 0;
      _reportProgress(
        onProgress,
        receivedBytes: 0,
        totalBytes: manifest.totalBytes,
        artifactName: manifest.artifacts.first.name,
      );
      for (final artifact in manifest.artifacts) {
        final output = File('${staging.path}/${artifact.path}');
        await output.parent.create(recursive: true);
        await _download(
          client,
          artifact,
          output,
          onBytes: (artifactBytes) => _reportProgress(
            onProgress,
            receivedBytes: completedBytes + artifactBytes,
            totalBytes: manifest.totalBytes,
            artifactName: artifact.name,
          ),
        );
        completedBytes += artifact.expectedBytes;
      }
      await File(
        '${staging.path}/$metadataFileName',
      ).writeAsString(jsonEncode(_metadata(manifest)), flush: true);
      await _replace(staging, destination, backup);
      return _installed(manifest, destination);
    } finally {
      client.close(force: true);
      if (await staging.exists()) await staging.delete(recursive: true);
    }
  }

  /// Returns the installed pack only when metadata and every artifact still
  /// match the immutable manifest pins. Storage/format failures are contained.
  Future<InstalledVoiceModelPack?> installedPack(
    VoiceModelPackManifest manifest,
  ) => _serialize(() => _installedPack(manifest));

  Future<InstalledVoiceModelPack?> _installedPack(
    VoiceModelPackManifest manifest,
  ) async {
    try {
      final destination = Directory(
        '${rootDirectory.path}/${manifest.packId}/${manifest.version}',
      );
      final backup = Directory('${destination.path}.backup');
      await _recover(destination, backup);
      if (!await destination.exists()) return null;
      final metadata = jsonDecode(
        await File('${destination.path}/$metadataFileName').readAsString(),
      );
      if (jsonEncode(metadata) != jsonEncode(_metadata(manifest))) return null;
      for (final artifact in manifest.artifacts) {
        final file = File('${destination.path}/${artifact.path}');
        if (!await file.exists() ||
            await file.length() != artifact.expectedBytes ||
            (await sha256.bind(file.openRead()).first).toString() !=
                artifact.sha256) {
          return null;
        }
      }
      return _installed(manifest, destination);
    } catch (_) {
      return null;
    }
  }

  Map<String, Object?> _metadata(VoiceModelPackManifest manifest) =>
      <String, Object?>{
        'schema': 1,
        'packId': manifest.packId,
        'version': manifest.version,
        'provenance': manifest.provenance,
        'artifacts': <Map<String, Object?>>[
          for (final artifact in manifest.artifacts)
            <String, Object?>{
              'name': artifact.name,
              'path': artifact.path,
              'bytes': artifact.expectedBytes,
              'sha256': artifact.sha256,
            },
        ],
      };

  /// Deletes one installed version and its transaction leftovers.
  Future<void> delete(String packId, String version) =>
      _serialize(() => _delete(packId, version));

  Future<void> _delete(String packId, String version) async {
    final safe = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$');
    if (!safe.hasMatch(packId) ||
        !safe.hasMatch(version) ||
        packId == '.' ||
        packId == '..' ||
        version == '.' ||
        version == '..') {
      throw const FormatException('Invalid voice model pack identity.');
    }
    final parent = Directory('${rootDirectory.path}/$packId');
    if (!await parent.exists()) return;
    final names = <String>{version, '$version.backup'};
    await for (final entry in parent.list(followLinks: false)) {
      final name = entry.uri.pathSegments.where((part) => part.isNotEmpty).last;
      if (names.contains(name) || name.startsWith('.$version.download-')) {
        await entry.delete(recursive: true);
      }
    }
    if (await parent.exists() && await parent.list().isEmpty) {
      await parent.delete();
    }
  }

  InstalledVoiceModelPack _installed(
    VoiceModelPackManifest manifest,
    Directory directory,
  ) => InstalledVoiceModelPack(
    packId: manifest.packId,
    version: manifest.version,
    provenance: manifest.provenance,
    directory: directory,
    artifactPaths: Map<String, String>.unmodifiable(<String, String>{
      for (final artifact in manifest.artifacts) artifact.name: artifact.path,
    }),
  );

  Future<void> _download(
    HttpClient client,
    VoiceModelPackArtifact artifact,
    File output, {
    required void Function(int receivedBytes) onBytes,
  }) async {
    final response = await _openHttps(client, artifact.uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      await response.drain<void>();
      throw const VoiceModelPackException(
        VoiceModelPackError.fetch,
        'The voice model pack could not be downloaded.',
      );
    }
    if (response.contentLength >= 0 &&
        response.contentLength != artifact.expectedBytes) {
      await response.drain<void>();
      throw const VoiceModelPackException(
        VoiceModelPackError.integrity,
        'The voice model pack failed its integrity check.',
      );
    }
    final sink = output.openWrite();
    var received = 0;
    try {
      await for (final chunk in response.timeout(const Duration(seconds: 30))) {
        received += chunk.length;
        if (received > artifact.expectedBytes) {
          throw const VoiceModelPackException(
            VoiceModelPackError.integrity,
            'The voice model pack failed its integrity check.',
          );
        }
        sink.add(chunk);
        onBytes(received);
      }
    } finally {
      await sink.close();
    }
    if (received != artifact.expectedBytes ||
        (await sha256.bind(output.openRead()).first).toString() !=
            artifact.sha256) {
      throw const VoiceModelPackException(
        VoiceModelPackError.integrity,
        'The voice model pack failed its integrity check.',
      );
    }
  }

  void _reportProgress(
    VoiceModelPackProgressCallback? callback, {
    required int receivedBytes,
    required int totalBytes,
    required String artifactName,
  }) {
    if (callback == null) return;
    try {
      callback(
        VoiceModelPackProgress(
          receivedBytes: receivedBytes,
          totalBytes: totalBytes,
          artifactName: artifactName,
        ),
      );
    } catch (_) {
      // Progress observers cannot compromise transactional installation.
    }
  }

  Future<HttpClientResponse> _openHttps(HttpClient client, Uri initial) async {
    var current = initial;
    for (var redirects = 0; redirects <= 5; redirects++) {
      if (current.scheme != 'https' || current.host.isEmpty) {
        throw const VoiceModelPackException(
          VoiceModelPackError.transport,
          'The voice model pack requires a secure connection.',
        );
      }
      try {
        final request = await client.getUrl(current);
        request.followRedirects = false;
        final response = await request.close().timeout(
          const Duration(seconds: 20),
        );
        if (!const <int>{
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
        if (location == null || redirects == 5) break;
        current = current.resolve(location);
      } on VoiceModelPackException {
        rethrow;
      } catch (_) {
        throw const VoiceModelPackException(
          VoiceModelPackError.fetch,
          'The voice model pack could not be downloaded.',
        );
      }
    }
    throw const VoiceModelPackException(
      VoiceModelPackError.transport,
      'The voice model pack download could not be redirected securely.',
    );
  }

  Future<void> _recover(Directory destination, Directory backup) async {
    if (await backup.exists() && !await destination.exists()) {
      await backup.rename(destination.path);
    }
    final version = destination.uri.pathSegments
        .where((part) => part.isNotEmpty)
        .last;
    if (await destination.parent.exists()) {
      await for (final entry in destination.parent.list(followLinks: false)) {
        final name = entry.uri.pathSegments
            .where((part) => part.isNotEmpty)
            .last;
        if (name.startsWith('.$version.download-')) {
          await entry.delete(recursive: true);
        }
      }
    }
  }

  Future<void> _replace(
    Directory staging,
    Directory destination,
    Directory backup,
  ) async {
    if (await backup.exists()) await backup.delete(recursive: true);
    if (await destination.exists()) await destination.rename(backup.path);
    try {
      await _adoptStaging(staging, destination);
      if (await backup.exists()) await backup.delete(recursive: true);
    } catch (_) {
      if (await destination.exists()) await destination.delete(recursive: true);
      if (await backup.exists()) await backup.rename(destination.path);
      throw const VoiceModelPackException(
        VoiceModelPackError.adoption,
        'The voice model pack could not be installed.',
      );
    }
  }
}

enum VoiceModelPackError { fetch, integrity, transport, adoption, storage }

/// Safe user-facing failure which deliberately excludes source URLs and causes.
final class VoiceModelPackException implements Exception {
  const VoiceModelPackException(this.code, this.message);

  final VoiceModelPackError code;
  final String message;

  @override
  String toString() => 'VoiceModelPackException: $message';
}
