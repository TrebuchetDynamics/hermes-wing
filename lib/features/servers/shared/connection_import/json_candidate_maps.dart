part of 'parser.dart';

Iterable<_JsonConnectionImportFields> _jsonCandidateMaps(
  Map<dynamic, dynamic> decoded,
) sync* {
  final entries = decoded['entries'];
  if (entries is! List) {
    yield _JsonConnectionImportFields(
      fields: decoded,
      hasExplicitConnectionFields: _hasNonBlankJsonConnectionField(decoded),
    );
    return;
  }

  var yieldedEntry = false;
  for (final fields in _entryCandidateMaps(decoded, entries)) {
    yieldedEntry = true;
    yield fields;
  }
  if (!yieldedEntry) {
    yield _JsonConnectionImportFields(
      fields: decoded,
      hasExplicitConnectionFields: _hasNonBlankJsonConnectionField(decoded),
    );
  }
}

Iterable<_JsonConnectionImportFields> _entryCandidateMaps(
  Map<dynamic, dynamic> decoded,
  List<dynamic> entries,
) sync* {
  for (final entry in entries) {
    if (entry is! Map) continue;
    yield _JsonConnectionImportFields(
      fields: _entryFieldsWithJsonDefaults(decoded, entry),
      hasExplicitConnectionFields: _hasNonBlankJsonConnectionField(entry),
    );
  }
}

class _JsonConnectionImportFields {
  const _JsonConnectionImportFields({
    required this.fields,
    required this.hasExplicitConnectionFields,
  });

  final Map<dynamic, dynamic> fields;

  // Entries may inherit top-level credentials, but metadata-only entries should
  // not outrank entries that carry their own endpoint/token provenance.
  final bool hasExplicitConnectionFields;
}

Map<dynamic, dynamic> _entryFieldsWithJsonDefaults(
  Map<dynamic, dynamic> defaults,
  Map<dynamic, dynamic> entry,
) {
  final fields = Map<dynamic, dynamic>.of(defaults)..remove('entries');
  _removeDefaultJsonAliasesOverriddenByEntry(fields, entry);
  for (final entryField in entry.entries) {
    if (_isBlankJsonValue(entryField.value)) continue;
    if (_isJsonConnectionImportFieldName('${entryField.key}') &&
        !_isNonBlankJsonString(entryField.value)) {
      continue;
    }
    fields[entryField.key] = entryField.value;
  }
  return fields;
}

void _removeDefaultJsonAliasesOverriddenByEntry(
  Map<dynamic, dynamic> fields,
  Map<dynamic, dynamic> entry,
) {
  final hasUsableConnectionField = _hasNonBlankJsonConnectionField(entry);
  for (final aliases in _jsonConnectionImportFieldAliasGroups) {
    if (!_jsonEntryOverridesAlias(entry, aliases) &&
        !(hasUsableConnectionField &&
            _jsonEntryHasUnusableAlias(entry, aliases))) {
      continue;
    }
    for (final alias in aliases) {
      fields.remove(alias);
    }
  }
}

bool _jsonEntryOverridesAlias(
  Map<dynamic, dynamic> entry,
  Iterable<String> aliases,
) {
  return entry.entries.any(
    (entry) =>
        _isNonBlankJsonString(entry.value) &&
        _jsonEntryKeyMatchesAliases(entry.key, aliases),
  );
}

bool _jsonEntryHasUnusableAlias(
  Map<dynamic, dynamic> entry,
  Iterable<String> aliases,
) {
  return entry.entries.any(
    (entry) =>
        !_isNonBlankJsonString(entry.value) &&
        _jsonEntryKeyMatchesAliases(entry.key, aliases),
  );
}

bool _jsonEntryKeyMatchesAliases(Object? key, Iterable<String> aliases) {
  final normalizedAliases = {
    for (final alias in aliases) _normalizeJsonConnectionImportFieldName(alias),
  };
  return normalizedAliases.contains(
    _normalizeJsonConnectionImportFieldName('$key'),
  );
}

bool _isJsonConnectionImportFieldName(String name) {
  final normalizedName = _normalizeJsonConnectionImportFieldName(name);
  return _jsonConnectionImportFieldAliasGroups.any(
    (aliases) => aliases.any(
      (alias) =>
          _normalizeJsonConnectionImportFieldName(alias) == normalizedName,
    ),
  );
}

String _normalizeJsonConnectionImportFieldName(String value) =>
    value.toLowerCase().replaceAll('_', '');

bool _hasNonBlankJsonConnectionField(Map<dynamic, dynamic> fields) {
  return navivoxFirstStringFieldFromJson(fields, _tokenFieldNames) != null ||
      navivoxFirstStringFieldFromJson(fields, _baseUrlFieldNames) != null ||
      navivoxFirstStringFieldFromJson(fields, _webSocketUrlFieldNames) != null;
}

bool _isBlankJsonValue(Object? value) {
  if (value == null) return true;
  if (value is String && value.trim().isEmpty) return true;
  return false;
}

bool _isNonBlankJsonString(Object? value) =>
    value is String && value.trim().isNotEmpty;
