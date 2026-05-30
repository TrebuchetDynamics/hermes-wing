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
  return Map<String, Object?>.from(value);
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
  for (final name in names) {
    final exact = navivoxOptionalLiteralStringFromJson(json[name]);
    if (exact != null) return exact;
  }
  final normalizedNames = {
    for (final name in names) _navivoxNormalizeJsonFieldName(name),
  };
  for (final entry in json.entries) {
    if (!normalizedNames.contains(
      _navivoxNormalizeJsonFieldName('${entry.key}'),
    )) {
      continue;
    }
    final value = navivoxOptionalLiteralStringFromJson(entry.value);
    if (value != null) return value;
  }
  return null;
}

String _navivoxNormalizeJsonFieldName(String value) =>
    value.toLowerCase().replaceAll('_', '');

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

DateTime? navivoxDateTimeFromJson(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text);
}
