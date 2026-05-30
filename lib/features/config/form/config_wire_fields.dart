/// Shared helpers for loose config-schema/validation wire maps.
///
/// Gormes config payloads may identify fields with related aliases depending on
/// whether the source is schema rows, validation errors, or section references.
/// These helpers keep the alias lookup and non-empty string coercion consistent
/// without broadening each call site's accepted aliases.
String? configWireString(Object? raw) {
  final text = raw?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

String? configWireStringFromAliases(Map raw, Iterable<String> aliases) {
  for (final alias in aliases) {
    final text = configWireString(raw[alias]);
    if (text != null) return text;
  }
  return null;
}
