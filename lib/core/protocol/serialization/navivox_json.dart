/// Shared coercion helpers for Navivox wire-protocol JSON payloads.
///
/// These helpers intentionally accept loose `Object?` values because gateway and
/// memory endpoints can be decoded from typed maps, platform channels, or JSON
/// maps with dynamic keys.
String navivoxStringFromJson(Object? value, {required String fallback}) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return fallback;
  return text;
}

String? navivoxOptionalStringFromJson(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

/// Returns a trimmed string only when [value] is already a literal string.
String? navivoxOptionalLiteralStringFromJson(Object? value) {
  if (value is! String) return null;
  final text = value.trim();
  return text.isEmpty ? null : text;
}

int navivoxIntFromJson(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? navivoxDoubleFromJson(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

bool navivoxBoolFromJson(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  final text = value?.toString().trim().toLowerCase();
  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;
  return fallback;
}

/// Returns only literal bool values or `true`/`false` string tokens.
///
/// Use this for protocol flags whose existing contract intentionally does not
/// accept broader truthy aliases such as `1` or `yes`.
bool navivoxStrictBoolFromJson(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  final text = value?.toString().trim().toLowerCase();
  if (text == 'true') return true;
  if (text == 'false') return false;
  return fallback;
}

Map<String, Object?> navivoxMapFromJson(Object? value) {
  if (value is! Map) return const {};
  return {
    for (final entry in value.entries)
      if (entry.key is String) entry.key as String: entry.value,
  };
}

Map<String, Object?> navivoxMapFieldFromJson(
  Map<String, Object?> json,
  String key,
) {
  return navivoxMapFromJson(json[key]);
}

List<Object?> navivoxListFromJson(Object? value) {
  if (value is! List) return const [];
  return value.cast<Object?>();
}

/// Returns map entries from a loose wire list, ignoring non-map items.
List<Map<String, Object?>> navivoxMapListFromJson(Object? value) {
  return navivoxListFromJson(
    value,
  ).whereType<Map>().map(navivoxMapFromJson).toList(growable: false);
}

List<Object?> navivoxListFieldFromJson(Map<String, Object?> json, String key) {
  return navivoxListFromJson(json[key]);
}

List<String> navivoxStringListFromJson(Object? value) {
  if (value is! List) return const [];
  return navivoxTrimmedStringList(value);
}

String navivoxStringFieldFromJson(Map<String, Object?> json, String key) {
  return navivoxStringFromJson(json[key], fallback: '');
}

/// Selects a typed enum/value object by matching its wire value.
///
/// The wire token uses the same non-empty trimmed string semantics as other
/// Navivox protocol fields and falls back when the value is blank or unknown.
T navivoxValueFromWire<T>({
  required Object? value,
  required Iterable<T> values,
  required String Function(T value) wireValue,
  required T fallback,
}) {
  final text = navivoxOptionalStringFromJson(value);
  if (text == null) return fallback;
  for (final candidate in values) {
    if (wireValue(candidate) == text) return candidate;
  }
  return fallback;
}

/// Returns the first non-empty literal string field whose key matches [names].
///
/// The lookup first honors exact keys, then falls back to a compatibility match
/// that ignores underscores and case so wire payloads can use either
/// `snake_case` or `camelCase` aliases without each parser reimplementing that
/// policy. Non-string values are intentionally ignored to preserve strict wire
/// semantics for IDs, URLs, and tokens.
String? navivoxFirstStringFieldFromJson(
  Map<dynamic, dynamic> json,
  Iterable<String> names,
) {
  for (final value in navivoxWireFieldValuesFromAliases(json, names)) {
    final text = navivoxOptionalLiteralStringFromJson(value);
    if (text != null) return text;
  }
  return null;
}

/// Canonical field-name form used for loose Navivox wire aliases.
///
/// This makes the snake_case/camelCase compatibility rule explicit and shared
/// across JSON objects and query-derived maps.
String navivoxCanonicalWireFieldName(String value) =>
    value.toLowerCase().replaceAll('_', '');

/// Yields values for [names], preferring exact keys before canonical aliases.
///
/// Exact-key precedence keeps a producer's canonical field from being shadowed
/// by an older compatibility alias while still accepting case/underscore drift
/// such as `serverId` for `server_id`.
Iterable<Object?> navivoxWireFieldValuesFromAliases(
  Map<dynamic, dynamic> json,
  Iterable<String> names,
) sync* {
  final exactNames = names.toSet();
  final yieldedKeys = <dynamic>{};
  for (final name in exactNames) {
    if (!json.containsKey(name)) continue;
    yieldedKeys.add(name);
    yield json[name];
  }

  final canonicalNames = {
    for (final name in exactNames) navivoxCanonicalWireFieldName(name),
  };
  for (final entry in json.entries) {
    if (yieldedKeys.contains(entry.key)) continue;
    if (!canonicalNames.contains(
      navivoxCanonicalWireFieldName('${entry.key}'),
    )) {
      continue;
    }
    yield entry.value;
  }
}

List<String> navivoxStringListFieldFromJson(
  Map<String, Object?> json,
  String key,
) {
  return navivoxStringListFromJson(json[key]);
}

/// Returns non-empty trimmed string values in their original order.
List<String> navivoxTrimmedStringList(Iterable<Object?> values) {
  return values
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

/// Returns a string map with null/blank values removed and remaining values
/// trimmed. Useful for query params and wire request bodies that share Navivox
/// non-empty string field semantics.
Map<String, String> navivoxTrimmedStringFields(Map<String, Object?> values) {
  return {
    for (final entry in values.entries)
      if (entry.value case final value?)
        if (value.toString().trim().isNotEmpty)
          entry.key: value.toString().trim(),
  };
}

/// Returns a query-parameter map using the first non-empty value for each key.
///
/// This keeps copied URLs with duplicate blank parameters from erasing the
/// earlier value supplied by the producer.
Map<String, String> navivoxFirstNonBlankQueryParameterValues(
  Map<String, List<String>> queryParametersAll,
) {
  final result = <String, String>{};
  for (final entry in queryParametersAll.entries) {
    final value = navivoxFirstNonBlankQueryParameterValue(entry.value);
    if (value != null) result[entry.key] = value;
  }
  return result;
}

String? navivoxFirstNonBlankQueryParameterValue(List<String> values) {
  for (final value in values) {
    final text = navivoxOptionalLiteralStringFromJson(value);
    if (text != null) return text;
  }
  return null;
}

DateTime? navivoxDateTimeFromJson(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text);
}
