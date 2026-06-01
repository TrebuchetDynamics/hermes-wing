/// Pure value/key normalization helpers for config-admin wire models.
///
/// Keeping these policies outside the response DTOs makes hidden assumptions
/// explicit and easy to regression-test: outgoing changes require a replayable
/// field key, list values use the gateway's comma-separated wire shape, and
/// redacted summaries never expose secret values.
String configAdminRequiredKey(String key) {
  final trimmedKey = key.trim();
  if (trimmedKey.isEmpty) {
    throw ArgumentError.value(key, 'key', 'must not be blank');
  }
  return trimmedKey;
}

String configAdminWireValue(Object? value) {
  if (value == null) return '';
  if (value is Iterable) return configAdminWireListItems(value).join(',');
  return value.toString().trim();
}

List<String> configAdminWireListItems(Iterable<Object?> values) {
  return values
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

String configAdminDisplayValue(
  Object? value, {
  bool redacted = false,
  String secretStatus = '',
}) {
  if (redacted) {
    final status = secretStatus.trim();
    return status.isEmpty ? '[redacted]' : '[redacted:$status]';
  }
  if (value == null) return '—';
  if (value is Iterable) return value.join(', ');
  return '$value';
}
