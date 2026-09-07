import '../../protocol/wing_json.dart';
import 'hermes_metadata_text.dart';

/// Bounded public metadata from one advertised `/v1/models` entry.
///
/// Hermes exposes the primary runtime model plus optional route aliases. Wing
/// retains only their public identifiers and routing relationship; permissions
/// and unknown provider payloads are discarded.
class HermesRuntimeModel {
  const HermesRuntimeModel({
    required this.id,
    this.root = '',
    this.parent = '',
  });

  factory HermesRuntimeModel.fromJson(Map<String, Object?> json) {
    final id = _firstBounded(json, const ['id', 'root', 'model', 'name']);
    return HermesRuntimeModel(
      id: id,
      root: boundedHermesMetadataText(
        wingStringFromJson(json['root'], fallback: id),
        120,
      ),
      parent: boundedHermesMetadataText(
        wingStringFromJson(json['parent'], fallback: ''),
        120,
      ),
    );
  }

  final String id;
  final String root;
  final String parent;

  bool get isRouteAlias => root.isNotEmpty && root != id;
}

String _firstBounded(Map<String, Object?> json, List<String> fields) {
  for (final field in fields) {
    final value = wingOptionalStringFromJson(json[field]);
    if (value != null && value.trim().isNotEmpty) {
      return boundedHermesMetadataText(value, 120);
    }
  }
  return '';
}
