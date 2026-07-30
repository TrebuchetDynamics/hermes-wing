import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'model_preset.dart';

/// Client-side persistence for [ModelPreset]s in shared_preferences.
///
/// Presets are non-secret local conveniences and are never sent to the
/// Hermes Agent.
class ModelPresetStore {
  static const _key = 'wing.hermes.model_presets.v1';

  /// Oldest presets are dropped past this bound.
  static const maxPresets = 32;

  Future<List<ModelPreset>> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map)
            if (ModelPreset.fromJson(item.cast<String, Object?>())
                case final preset
                when preset.name.isNotEmpty && preset.model.isNotEmpty)
              preset,
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<List<ModelPreset>> save(ModelPreset preset) async {
    final existing = await load();
    final index = existing.indexWhere((item) => item.name == preset.name);
    final presets = index >= 0
        ? ([...existing]..[index] = preset)
        : [...existing, preset];
    while (presets.length > maxPresets) {
      presets.removeAt(0);
    }
    await _persist(presets);
    return presets;
  }

  Future<List<ModelPreset>> remove(String name) async {
    final presets = [
      for (final preset in await load())
        if (preset.name != name) preset,
    ];
    await _persist(presets);
    return presets;
  }

  Future<void> _persist(List<ModelPreset> presets) async {
    await (await SharedPreferences.getInstance()).setString(
      _key,
      jsonEncode([for (final preset in presets) preset.toJson()]),
    );
  }
}
