import 'config_risk_level.dart';
import '../config_wire_fields.dart';

/// Schema-level wire helpers for config form rows and sections.
///
/// These helpers make accepted field aliases and coercion rules visible at the
/// form boundary. Schema booleans intentionally accept literal bools plus
/// strict `true`/`false` string tokens so replayed JSON captures don't depend on
/// the producer preserving native boolean types.
String? configFormFieldPathFromSchema(Map raw) {
  return configWireStringFromAliases(raw, const ['path', 'key', 'name']);
}

String configFormFieldLabelFromSchema(Map raw, String fallback) {
  return configWireStringFromAliases(raw, const ['label', 'title']) ?? fallback;
}

String configFormSectionIdFromSchema(Map raw, String fallback) {
  return configWireStringFromAliases(raw, const ['id']) ?? fallback;
}

String configFormSectionLabelFromSchema(Map raw, String fallback) {
  return configWireStringFromAliases(raw, const ['label', 'title']) ?? fallback;
}

String? configFormSectionDescriptionFromSchema(Map raw) {
  return configWireStringFromAliases(raw, const ['description']);
}

bool configFormBoolFromSchema(Map raw, Iterable<String> aliases) {
  return _configFormStrictBoolFromAliases(raw, aliases) == true;
}

String configFormRiskLevelFromSchema(Map raw) => configRiskLevelFromSchema(raw);

String configFormReloadModeFromSchema(Map raw) {
  return configWireStringFromAliases(raw, const ['reload', 'reload_mode']) ??
      '';
}

List<String> configFormAllowedValuesFromSchema(Map raw) {
  return configWireStringListFromAliases(raw, configAllowedValuesFieldAliases);
}

List<String> configFormActionsFromSchema(Map raw) {
  return configWireStringListFromAliases(raw, const [
    'actions',
    'supported_actions',
  ]);
}

List<String> configFormSectionFieldRefsFromSchemaMap(Map raw) {
  for (final candidate in configFormSectionFieldRefAliasCandidates(raw)) {
    final refs = configFormSectionFieldRefsFromSchema(candidate);
    if (refs.isNotEmpty) return refs;
  }
  return const [];
}

Iterable<Object?> configFormSectionFieldRefAliasCandidates(Map raw) {
  return configFormSchemaValueCandidates(raw, const [
    'fields',
    'field_refs',
    'field_paths',
  ]);
}

List<String> configFormSectionFieldRefsFromSchema(Object? rawFields) {
  if (rawFields is! List) return const [];
  final refs = <String>[];
  for (final raw in rawFields) {
    final text = configFormSectionFieldRefFromSchemaValue(raw);
    if (text != null) refs.add(text);
  }
  return refs;
}

String? configFormSectionFieldRefFromSchemaValue(Object? raw) {
  if (raw is Map) return configFormSectionFieldRefFromSchema(raw);
  return configWireString(raw);
}

String? configFormSectionFieldRefFromSchema(Map raw) {
  return configWireStringFromAliases(raw, const [
    'path',
    'field',
    'key',
    'name',
  ]);
}

bool? _configFormStrictBoolFromAliases(Map raw, Iterable<String> aliases) {
  for (final value in configFormSchemaValueCandidates(raw, aliases)) {
    final parsed = _configFormStrictBool(value);
    if (parsed != null) return parsed;
  }
  return null;
}

/// Replays schema alias lookup in the same order used by form parsing.
///
/// Keep form-schema diagnostics on the shared config wire alias contract so
/// exact aliases, camelCase/snake_case compatibility, and duplicate exact-key
/// suppression cannot drift from the production parsers.
Iterable<Object?> configFormSchemaValueCandidates(
  Map raw,
  Iterable<String> aliases,
) {
  return configWireAliasCandidates(raw, aliases);
}

bool? _configFormStrictBool(Object? value) {
  if (value is bool) return value;
  final text = value?.toString().trim().toLowerCase();
  return switch (text) {
    'true' => true,
    'false' => false,
    _ => null,
  };
}
