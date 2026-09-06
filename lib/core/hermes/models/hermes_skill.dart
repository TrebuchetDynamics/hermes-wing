import '../../protocol/wing_json.dart';
import 'hermes_metadata_text.dart';

/// Bounded public metadata from one installed `/v1/skills` entry.
class HermesSkill {
  const HermesSkill({
    required this.name,
    this.description = '',
    this.category = '',
  });

  factory HermesSkill.fromJson(Map<String, Object?> json) {
    return HermesSkill(
      name: boundedHermesMetadataText(
        wingStringFromJson(json['name'], fallback: ''),
        120,
      ),
      description: boundedHermesMetadataText(
        wingStringFromJson(json['description'], fallback: ''),
        1000,
      ),
      category: boundedHermesMetadataText(
        wingStringFromJson(json['category'], fallback: ''),
        80,
      ),
    );
  }

  final String name;
  final String description;
  final String category;
}
