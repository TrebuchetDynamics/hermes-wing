import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';

/// Downloads and installs the Needle CQ4 runtime bundle.
///
/// IO pattern (temp file, HTTPS-only redirects, size cap, sha256) mirrors
/// IoPocketSpeechAssetDownloadService; duplicated here on purpose so the
/// spike stays fully decoupled from production voice code.
class NeedleModelInstallService {
  NeedleModelInstallService({required this.supportDirectory});

  final Directory supportDirectory;

  static const modelZipUrl =
      'https://huggingface.co/Cactus-Compute/needle/resolve/main/needle-cq4.zip';
  static const modelZipSha256 =
      'a3423af7d7bd2a35e08ba1f262c4796f4e97963da0a3fbe124d3a8eaae9e4098';
  static const maximumZipBytes = 32 * 1024 * 1024;

  Directory get _root => Directory('${supportDirectory.path}/needle_spike');
  Directory get _modelRoot => Directory('${_root.path}/model');
  File get _marker => File('${_root.path}/.installed');

  /// Path to a previously installed model directory, or null.
  Future<String?> installedModelDir() async {
    if (!await _marker.exists()) return null;
    final recorded = (await _marker.readAsString()).trim();
    if (recorded.isEmpty || !await Directory(recorded).exists()) return null;
    return recorded;
  }

  Future<String>? _inFlight;

  /// Ensures the bundle is downloaded, verified, and extracted.
  /// Returns the directory to pass to `cactus_init`.
  ///
  /// Concurrent calls share one in-flight download/extract; only the first
  /// caller's [onProgress] receives updates.
  Future<String> ensureModel({void Function(int receivedBytes)? onProgress}) {
    return _inFlight ??= _ensureModel(onProgress: onProgress).whenComplete(() {
      _inFlight = null;
    });
  }

  Future<String> _ensureModel({
    void Function(int receivedBytes)? onProgress,
  }) async {
    final existing = await installedModelDir();
    if (existing != null) return existing;
    final zipBytes = await _downloadZip(onProgress: onProgress);
    return installFromZipBytes(zipBytes);
  }

  /// Extracts [zipBytes] and records the resolved model dir. Public so tests
  /// can exercise laydown logic without the network.
  Future<String> installFromZipBytes(List<int> zipBytes) async {
    if (await _modelRoot.exists()) {
      await _modelRoot.delete(recursive: true);
    }
    await _modelRoot.create(recursive: true);
    final archive = ZipDecoder().decodeBytes(zipBytes);
    await extractArchiveToDisk(archive, _modelRoot.path);
    // extractArchiveToDisk swallows per-entry write failures, so verify
    // every archive file actually landed on disk with the expected size.
    for (final entry in archive.files.where((f) => f.isFile)) {
      final out = File('${_modelRoot.path}/${entry.name}');
      if (!await out.exists() || await out.length() != entry.size) {
        throw StateError('Needle bundle extraction incomplete.');
      }
    }
    final modelDir = _resolveModelDir(_modelRoot);
    final hasFiles = modelDir
        .listSync(recursive: true)
        .whereType<File>()
        .isNotEmpty;
    if (!hasFiles) {
      throw StateError('Needle bundle extraction incomplete.');
    }
    await _marker.writeAsString(modelDir.path);
    return modelDir.path;
  }

  /// If the zip wraps everything in one directory, descend into it.
  Directory _resolveModelDir(Directory root) {
    var current = root;
    for (var depth = 0; depth < 3; depth++) {
      final entries = current.listSync();
      final files = entries.whereType<File>().toList();
      final dirs = entries.whereType<Directory>().toList();
      if (files.isNotEmpty || dirs.length != 1) return current;
      current = dirs.single;
    }
    return current;
  }

  Future<List<int>> _downloadZip({
    void Function(int receivedBytes)? onProgress,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      final response = await _openHttps(client, Uri.parse(modelZipUrl));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'GET $modelZipUrl failed with ${response.statusCode}',
        );
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response.timeout(const Duration(seconds: 30))) {
        builder.add(chunk);
        if (builder.length > maximumZipBytes) {
          throw StateError('Needle bundle exceeded its size limit.');
        }
        onProgress?.call(builder.length);
      }
      final bytes = builder.takeBytes();
      final digest = sha256.convert(bytes).toString().toLowerCase();
      if (digest != modelZipSha256.trim().toLowerCase()) {
        throw StateError('Needle bundle checksum mismatch.');
      }
      return bytes;
    } finally {
      client.close(force: true);
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
        throw HttpException('Needle bundle redirect failed.', uri: current);
      }
      final next = current.resolve(location);
      if (next.scheme != 'https' || next.host.isEmpty) {
        throw StateError('Needle bundle redirect must use HTTPS.');
      }
      current = next;
    }
    throw StateError('Needle bundle redirected too many times.');
  }
}
