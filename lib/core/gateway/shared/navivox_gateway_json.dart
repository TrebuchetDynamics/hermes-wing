import 'dart:convert';

import '../../protocol/navivox_json.dart' show navivoxMapListFromJson;

/// Decodes a gateway response body that must contain a JSON object.
Map<String, Object?> navivoxGatewayDecodeObject(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map) {
    throw const FormatException('expected JSON object');
  }
  return Map<String, Object?>.from(decoded);
}

/// Converts a loose gateway JSON value into an object map when possible.
Map<String, Object?>? navivoxGatewayOptionalObjectFromJson(Object? value) {
  if (value is! Map) return null;
  return Map<String, Object?>.from(value);
}

/// Reads a gateway wire field as a raw string without trimming.
///
/// WebSocket event text fields preserve the gateway's existing coercion
/// semantics: any non-null value is converted with `toString()`, including
/// whitespace-only strings and numeric compatibility values.
String navivoxGatewayRawStringField(
  Map<String, Object?> json,
  String key, {
  String fallback = '',
}) {
  return json[key]?.toString() ?? fallback;
}

/// Reads an optional gateway wire field as a raw string without trimming.
String? navivoxGatewayOptionalRawStringField(
  Map<String, Object?> json,
  String key,
) {
  return json[key]?.toString();
}

/// Returns whether a loose gateway value contains non-empty text after trim.
///
/// Request builders and readiness checks intentionally share the same tolerant
/// string-presence contract: null and whitespace-only values are absent, while
/// non-string compatibility values are checked through their wire text form.
bool navivoxGatewayHasText(Object? value) {
  return value?.toString().trim().isNotEmpty ?? false;
}

/// Reads a literal boolean field from a decoded gateway response.
///
/// Gateway feature flags intentionally preserve strict wire semantics: only the
/// JSON boolean `true` is truthy, while strings or numeric aliases remain false.
bool navivoxGatewayBoolField(Map<String, Object?> json, String key) {
  return json[key] == true;
}

/// Reads a required JSON object field from a decoded gateway response.
Map<String, Object?> navivoxGatewayObjectField(
  Map<String, Object?> body,
  String key,
) {
  final object = navivoxGatewayOptionalObjectFromJson(body[key]);
  if (object == null) {
    throw FormatException('expected JSON object field $key');
  }
  return object;
}

/// Parses a loose gateway JSON list into typed values.
///
/// Non-map values are ignored, matching the gateway wire contract used by the
/// protocol helpers, while the optional predicate keeps repeated non-empty ID
/// filtering close to the typed model being decoded.
List<T> navivoxGatewayObjectListFromJson<T>(
  Object? value,
  T Function(Map<String, Object?> json) fromJson, {
  bool Function(T item)? where,
}) {
  final items = navivoxMapListFromJson(value).map(fromJson);
  return (where == null ? items : items.where(where)).toList(growable: false);
}

/// Parses a loose gateway JSON object whose values are nested objects.
///
/// Non-map values are ignored so optional reference maps can tolerate forward
/// compatible wire payloads without each parser reimplementing the same loop.
Map<String, T> navivoxGatewayObjectValueMapFromJson<T>(
  Object? value,
  T Function(Map<String, Object?> json) fromJson,
) {
  if (value is! Map) return const {};
  final parsed = <String, T>{};
  for (final entry in value.entries) {
    final object = navivoxGatewayOptionalObjectFromJson(entry.value);
    if (object != null) {
      parsed[entry.key.toString()] = fromJson(object);
    }
  }
  return parsed;
}
