import '../../../protocol/navivox_event.dart';
import '../../../protocol/navivox_json.dart';

/// Gateway metadata decoder for transcript tool artifacts.
///
/// The gateway may send either structured artifact entries or a legacy flat
/// artifact payload. When neither is present, non-sensitive metadata is folded
/// into a bounded synthetic artifact so tool-call cards can still expose useful
/// context without leaking secrets.
List<NavivoxToolArtifact> navivoxToolArtifactsFromGatewayMetadata(
  Map<String, Object?> metadata, {
  required String toolCallId,
}) {
  if (metadata.isEmpty) return const [];
  final artifacts = <NavivoxToolArtifact>[];
  final artifactList = metadata['artifacts'];
  if (artifactList is List) {
    for (final artifact in artifactList.whereType<Map>()) {
      final parsed = _toolArtifactFromMap(Map<String, Object?>.from(artifact));
      if (parsed != null) artifacts.add(parsed);
    }
  }
  final single = _toolArtifactFromFlatMetadata(metadata);
  if (single != null) artifacts.add(single);
  if (artifacts.isNotEmpty) return artifacts;
  return [
    NavivoxToolArtifact(
      id: 'metadata-$toolCallId',
      kind: 'metadata',
      title: 'Tool metadata',
      summary: navivoxBoundedGatewayToolText(_safeMetadataSummary(metadata)),
    ),
  ];
}

String navivoxBoundedGatewayToolText(String text) {
  final trimmed = text.trim();
  if (trimmed.length <= 240) return trimmed;
  return '${trimmed.substring(0, 237)}...';
}

NavivoxToolArtifact? _toolArtifactFromMap(Map<String, Object?> json) {
  final id = navivoxOptionalStringFromJson(json['id']);
  final kind = navivoxOptionalStringFromJson(json['kind']);
  final title = navivoxOptionalStringFromJson(json['title']);
  if (id == null || kind == null || title == null) return null;
  return NavivoxToolArtifact(
    id: id,
    kind: kind,
    title: title,
    summary: navivoxOptionalStringFromJson(json['summary']),
    ref: navivoxOptionalStringFromJson(json['ref']),
  );
}

NavivoxToolArtifact? _toolArtifactFromFlatMetadata(
  Map<String, Object?> metadata,
) {
  final id = navivoxOptionalStringFromJson(metadata['artifact_id']);
  final kind = navivoxOptionalStringFromJson(metadata['artifact_kind']);
  final title = navivoxOptionalStringFromJson(metadata['artifact_title']);
  if (id == null || kind == null || title == null) return null;
  return NavivoxToolArtifact(
    id: id,
    kind: kind,
    title: title,
    summary: navivoxOptionalStringFromJson(metadata['artifact_summary']),
    ref: navivoxOptionalStringFromJson(metadata['artifact_ref']),
  );
}

String _safeMetadataSummary(Map<String, Object?> metadata) {
  final parts = <String>[];
  for (final entry in metadata.entries) {
    if (_isSensitiveMetadataKey(entry.key)) continue;
    parts.add('${entry.key}: ${_safeMetadataValue(entry.value)}');
  }
  return parts.isEmpty ? 'Metadata unavailable' : parts.join('; ');
}

String _safeMetadataValue(Object? value) {
  if (value is Map) return '[object]';
  if (value is List) return '[list]';
  return value?.toString() ?? '';
}

bool _isSensitiveMetadataKey(String key) {
  final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  return _sensitiveMetadataKeyFragments.any(normalized.contains);
}

const _sensitiveMetadataKeyFragments = <String>[
  'token',
  'secret',
  'password',
  'apikey',
  'authorization',
  'credential',
  'bearer',
];
