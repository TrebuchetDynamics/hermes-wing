import 'dart:convert';

import '../../protocol/navivox_json.dart'
    show
        navivoxMapFieldFromJson,
        navivoxMapListFromJson,
        navivoxStringFieldFromJson,
        navivoxStringFromJson;

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

/// Reads a display string with a stable same-object fallback field.
///
/// Gateway profile-shaped responses often expose an optional display label that
/// falls back to the identity field when absent or blank. Centralizing that
/// contract keeps routing and voice views aligned without changing the tolerant
/// protocol string parsing semantics.
String navivoxGatewayStringFieldWithFallbackField(
  Map<String, Object?> json,
  String key,
  String fallbackKey,
) {
  return navivoxStringFromJson(
    json[key],
    fallback: navivoxStringFieldFromJson(json, fallbackKey),
  );
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

/// Parses a nested gateway object field into a typed value.
///
/// Gateway response models use the protocol map-field contract for optional
/// nested objects: missing or malformed objects decode as an empty map, leaving
/// each typed parser responsible for its own defaults. This helper keeps that
/// object-field-to-value seam shared without changing wire tolerance.
T navivoxGatewayObjectFromField<T>(
  Map<String, Object?> json,
  String key,
  T Function(Map<String, Object?> json) fromJson,
) {
  return fromJson(navivoxMapFieldFromJson(json, key));
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

/// Parses a loose gateway JSON list and keeps items whose selected text exists.
///
/// Several gateway collections tolerate partial rows but only expose rows with a
/// usable identity/key. This keeps that non-empty text filter shared with the
/// same tolerant string-presence contract used by request builders.
List<T> navivoxGatewayObjectListWhereHasText<T>(
  Object? value,
  T Function(Map<String, Object?> json) fromJson,
  Object? Function(T item) textOf,
) {
  return navivoxGatewayObjectListFromJson(
    value,
    fromJson,
    where: (item) => navivoxGatewayHasText(textOf(item)),
  );
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
