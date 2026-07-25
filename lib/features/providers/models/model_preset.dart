import 'dart:convert';

import '../../../core/protocol/serialization/wing_json.dart';

/// A saved model+slot+provider combination that the user can recall later.
///
/// Presets are stored client-side only (shared_preferences) and never
/// sent to the Hermes Agent.
class ModelPreset {
  const ModelPreset({
    required this.name,
    required this.slot,
    required this.provider,
    required this.model,
  });

  factory ModelPreset.fromJson(Map<String, Object?> json) {
    return ModelPreset(
      name: _bounded(wingStringFromJson(json['name'], fallback: ''), 80),
      slot: _bounded(wingStringFromJson(json['slot'], fallback: 'main'), 40),
      provider: _bounded(
        wingStringFromJson(json['provider'], fallback: ''),
        120,
      ),
      model: _bounded(wingStringFromJson(json['model'], fallback: ''), 120),
    );
  }

  final String name;
  final String slot;
  final String provider;
  final String model;

  Map<String, Object?> toJson() => {
    'name': name,
    'slot': slot,
    'provider': provider,
    'model': model,
  };

  String encode() => jsonEncode(toJson());

  /// Returns true when the preset matches the given selection.
  bool matches({
    required String slot,
    required String provider,
    required String model,
  }) => this.slot == slot && this.provider == provider && this.model == model;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelPreset &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          slot == other.slot &&
          provider == other.provider &&
          model == other.model;

  @override
  int get hashCode => Object.hash(name, slot, provider, model);
}

String _bounded(String value, int limit) {
  final normalized = value
      .replaceAll(RegExp(r'[\u0000-\u001f\u007f]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (normalized.length <= limit) return normalized;
  return '${normalized.substring(0, limit - 1)}…';
}
