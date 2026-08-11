import 'dart:collection';

final RegExp _safeIdentifier = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$');
final RegExp _sha256 = RegExp(r'^[a-fA-F0-9]{64}$');

Never _invalid(String field) =>
    throw FormatException('Invalid voice model pack $field.');

void _requireSafeIdentifier(String value, String field) {
  if (!_safeIdentifier.hasMatch(value) || value == '.' || value == '..') {
    _invalid(field);
  }
}

String _validateArtifactPath(String value) {
  if (value.isEmpty || value.startsWith('/') || value.startsWith(r'\')) {
    _invalid('artifact path');
  }
  final normalized = value.replaceAll(r'\', '/');
  final segments = normalized.split('/');
  if (normalized.length > 1024 ||
      segments.any(
        (part) =>
            part.isEmpty ||
            part == '.' ||
            part == '..' ||
            !_safeIdentifier.hasMatch(part),
      ) ||
      segments.first == '.pack.json') {
    _invalid('artifact path');
  }
  return value;
}

/// One integrity-pinned file in a downloadable voice model pack.
final class VoiceModelPackArtifact {
  VoiceModelPackArtifact({
    required this.name,
    required String path,
    required this.uri,
    required this.expectedBytes,
    required String sha256,
  }) : path = _validateArtifactPath(path),
       sha256 = sha256.trim().toLowerCase() {
    _requireSafeIdentifier(name, 'artifact name');
    if (uri.scheme != 'https' || uri.host.isEmpty) _invalid('artifact URI');
    if (expectedBytes <= 0) _invalid('artifact byte count');
    if (!_sha256.hasMatch(sha256.trim())) _invalid('artifact SHA-256');
  }

  final String name;
  final String path;
  final Uri uri;
  final int expectedBytes;
  final String sha256;
}

/// Immutable identity, provenance, and artifact manifest for a voice model pack.
final class VoiceModelPackManifest {
  VoiceModelPackManifest({
    required this.packId,
    required this.version,
    required this.provenance,
    required List<VoiceModelPackArtifact> artifacts,
  }) : artifacts = List<VoiceModelPackArtifact>.unmodifiable(artifacts),
       artifactsByName = UnmodifiableMapView<String, VoiceModelPackArtifact>(
         <String, VoiceModelPackArtifact>{
           for (final artifact in artifacts) artifact.name: artifact,
         },
       ) {
    _requireSafeIdentifier(packId, 'ID');
    _requireSafeIdentifier(version, 'version');
    if (provenance.trim().isEmpty) _invalid('provenance');
    final sortedPaths = artifacts.map((artifact) => artifact.path).toList()
      ..sort();
    final pathsOverlap =
        <int>[
          for (var index = 0; index + 1 < sortedPaths.length; index++) index,
        ].any(
          (index) =>
              sortedPaths[index + 1].startsWith('${sortedPaths[index]}/'),
        );
    if (artifacts.isEmpty ||
        artifactsByName.length != artifacts.length ||
        artifacts.map((artifact) => artifact.path).toSet().length !=
            artifacts.length ||
        pathsOverlap) {
      _invalid('artifacts');
    }
  }

  final String packId;
  final String version;
  final String provenance;
  final List<VoiceModelPackArtifact> artifacts;
  final Map<String, VoiceModelPackArtifact> artifactsByName;

  int get totalBytes => artifacts.fold<int>(
    0,
    (total, artifact) => total + artifact.expectedBytes,
  );
}
