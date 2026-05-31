import '../serialization/navivox_json.dart';

/// Shared helpers for loose config-schema/validation wire maps.
///
/// Gormes config payloads may identify fields with related aliases depending on
/// whether the source is schema rows, validation errors, or section references.
/// These helpers keep alias lookup and non-empty string coercion consistent
/// across gateway protocol models and UI form models without broadening each
/// call site's accepted aliases.
String? configWireString(Object? raw) => navivoxOptionalStringFromJson(raw);

Object? configWireValueFromAliases(Map raw, Iterable<String> aliases) {
  for (final alias in aliases) {
    if (raw.containsKey(alias)) return raw[alias];
  }

  final normalizedAliases = {
    for (final alias in aliases) _configNormalizeWireFieldName(alias),
  };
  for (final entry in raw.entries) {
    if (normalizedAliases.contains(
      _configNormalizeWireFieldName('${entry.key}'),
    )) {
      return entry.value;
    }
  }
  return null;
}

String? configWireStringFromAliases(Map raw, Iterable<String> aliases) {
  for (final value in _configWireAliasCandidates(raw, aliases)) {
    final text = configWireString(value);
    if (text != null) return text;
  }
  return null;
}

List<String> configWireStringListFromAliases(Map raw, Iterable<String> aliases) {
  for (final value in _configWireAliasCandidates(raw, aliases)) {
    final list = navivoxStringListFromJson(value);
    if (list.isNotEmpty) return list;
  }
  return const [];
}

Iterable<Object?> _configWireAliasCandidates(
  Map raw,
  Iterable<String> aliases,
) sync* {
  for (final alias in aliases) {
    if (raw.containsKey(alias)) yield raw[alias];
  }

  final normalizedAliases = {
    for (final alias in aliases) _configNormalizeWireFieldName(alias),
  };
  for (final entry in raw.entries) {
    if (normalizedAliases.contains(
      _configNormalizeWireFieldName('${entry.key}'),
    )) {
      yield entry.value;
    }
  }
}

String _configNormalizeWireFieldName(String value) =>
    value.toLowerCase().replaceAll('_', '');
