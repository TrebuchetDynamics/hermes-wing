import 'dart:convert';

import '../../../../core/protocol/navivox_endpoint_uri.dart';
import '../../../../core/protocol/navivox_json.dart';
import '../../../../core/protocol/navivox_pairing_descriptor.dart';
import '../../models/connection_import.dart';

class ConnectionImportParser {
  const ConnectionImportParser();

  SetupQrImageImport? parsePayload(String payload) {
    final text = payload.trim();
    if (text.isEmpty) return null;

    final jsonResult = _parseQrJsonPayload(text);
    if (jsonResult != null && jsonResult.hasValues) return jsonResult;

    final uri = Uri.tryParse(text);
    if (uri != null && uri.hasScheme) {
      if (_isCorePairingDescriptorUri(uri)) {
        return _parseCorePairingDescriptor(text, uri);
      }

      final uriImport = _importFromGenericUri(uri);
      if (uriImport != null) return uriImport;
    }

    return _importFromSharedText(text);
  }

  SetupQrImageImport? _parseCorePairingDescriptor(String text, Uri uri) {
    if (uri.scheme != 'navivox' || uri.host != 'connect') return null;
    try {
      final descriptor = NavivoxPairingDescriptor.parse(text);
      return SetupQrImageImport(
        baseUrl: descriptor.baseUri.toString(),
        token: descriptor.token,
        webSocketUrl: descriptor.webSocketUri.toString(),
        serverId: descriptor.serverId,
        profileId: descriptor.profileId,
      );
    } on FormatException {
      return null;
    }
  }

  SetupQrImageImport? _parseQrJsonPayload(String text) {
    Object? decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      return null;
    }
    if (decoded is! Map) return null;

    return _bestImportFromCandidateMaps(_jsonCandidateMaps(decoded));
  }
}

SetupQrImageImport? parseNavivoxConnectionImportPayload(String payload) =>
    const ConnectionImportParser().parsePayload(payload);

bool _isCorePairingDescriptorUri(Uri uri) =>
    uri.scheme == 'navivox' && uri.host == 'connect';

Iterable<Map<dynamic, dynamic>> _jsonCandidateMaps(
  Map<dynamic, dynamic> decoded,
) sync* {
  final entries = decoded['entries'];
  if (entries is! List) {
    yield decoded;
    return;
  }

  var yieldedEntry = false;
  for (final fields in _entryCandidateMaps(decoded, entries)) {
    yieldedEntry = true;
    yield fields;
  }
  if (!yieldedEntry) yield decoded;
}

Iterable<Map<dynamic, dynamic>> _entryCandidateMaps(
  Map<dynamic, dynamic> decoded,
  List<dynamic> entries,
) sync* {
  for (final entry in entries) {
    if (entry is Map) yield _entryFieldsWithJsonDefaults(decoded, entry);
  }
}

Map<dynamic, dynamic> _entryFieldsWithJsonDefaults(
  Map<dynamic, dynamic> defaults,
  Map<dynamic, dynamic> entry,
) {
  final fields = Map<dynamic, dynamic>.of(defaults)..remove('entries');
  for (final entryField in entry.entries) {
    if (_isBlankJsonValue(entryField.value)) continue;
    fields[entryField.key] = entryField.value;
  }
  return fields;
}

bool _isBlankJsonValue(Object? value) {
  if (value == null) return true;
  if (value is String && value.trim().isEmpty) return true;
  return false;
}

SetupQrImageImport? _bestImportFromCandidateMaps(
  Iterable<Map<dynamic, dynamic>> candidateMaps,
) {
  _ConnectionImportCandidate? bestCandidate;
  for (final fields in candidateMaps) {
    final candidate = _connectionImportCandidateFromFields(fields);
    if (candidate == null) continue;
    bestCandidate = _richerConnectionImportCandidate(
      currentBest: bestCandidate,
      candidate: candidate,
    );
  }
  return bestCandidate?.toImport();
}

SetupQrImageImport? _importFromFields(
  Map<dynamic, dynamic> fields, {
  String? fallbackBaseUrl,
}) {
  return _connectionImportCandidateFromFields(
    fields,
    fallbackBaseUrl: fallbackBaseUrl,
  )?.toImport();
}

_ConnectionImportCandidate? _connectionImportCandidateFromFields(
  Map<dynamic, dynamic> fields, {
  String? fallbackBaseUrl,
}) {
  final token = navivoxFirstStringFieldFromJson(fields, _tokenFieldNames);
  final endpointFields = _connectionImportEndpointFields(fields);
  final candidate = _ConnectionImportCandidate(
    baseUrl: endpointFields.baseUrl ?? fallbackBaseUrl,
    token: token,
    webSocketUrl: endpointFields.webSocketUrl,
    serverId: navivoxFirstStringFieldFromJson(fields, _serverIdFieldNames),
    profileId: navivoxFirstStringFieldFromJson(fields, _profileIdFieldNames),
  );
  if (!candidate.hasImportValues) return null;

  return candidate;
}

_ConnectionImportEndpointFields _connectionImportEndpointFields(
  Map<dynamic, dynamic> fields,
) {
  final webSocketUrl = navivoxFirstStringFieldFromJson(
    fields,
    _webSocketUrlFieldNames,
  );
  final normalizedWebSocketUrl = _normalizeWebSocketUrl(webSocketUrl);
  return _ConnectionImportEndpointFields(
    baseUrl:
        _normalizeBaseUrl(
          navivoxFirstStringFieldFromJson(fields, _baseUrlFieldNames),
        ) ??
        _normalizeBaseUrlFromWebSocketUrl(normalizedWebSocketUrl),
    webSocketUrl: normalizedWebSocketUrl,
  );
}

class _ConnectionImportEndpointFields {
  const _ConnectionImportEndpointFields({this.baseUrl, this.webSocketUrl});

  final String? baseUrl;
  final String? webSocketUrl;
}

SetupQrImageImport? _importFromGenericUri(Uri uri) {
  final import = _importFromFields(
    _genericUriFields(uri),
    fallbackBaseUrl: _baseUrlFromGenericUri(uri),
  );
  if (import != null) return import;
  if (uri.scheme == 'http' || uri.scheme == 'https') {
    return SetupQrImageImport(baseUrl: navivoxOriginFromUri(uri));
  }
  if (_isWebSocketUri(uri)) {
    return SetupQrImageImport(
      baseUrl: _webSocketUriBaseUrl(uri),
      webSocketUrl: uri.toString(),
    );
  }
  return null;
}

SetupQrImageImport? _importFromSharedText(String text) {
  final embeddedUrlImport = _importFromFirstGenericUrl(text);
  final token = _firstToken(text) ?? embeddedUrlImport?.token;
  if (embeddedUrlImport == null && token == null) return null;

  return SetupQrImageImport(
    baseUrl: embeddedUrlImport?.baseUrl,
    token: token,
    webSocketUrl: embeddedUrlImport?.webSocketUrl,
    serverId: embeddedUrlImport?.serverId,
    profileId: embeddedUrlImport?.profileId,
  );
}

SetupQrImageImport? _importFromFirstGenericUrl(String text) {
  final url = _firstEndpointUrl(text);
  if (url == null) return null;

  final uri = Uri.tryParse(url);
  if (uri != null && uri.hasScheme) return _importFromGenericUri(uri);

  final baseUrl = _normalizeBaseUrl(url);
  return baseUrl == null ? null : SetupQrImageImport(baseUrl: baseUrl);
}

Map<String, String> _genericUriFields(Uri uri) {
  final fields = _firstNonBlankQueryParameterValues(uri.queryParametersAll);
  if (_isWebSocketUri(uri) &&
      navivoxFirstStringFieldFromJson(fields, _webSocketUrlFieldNames) ==
          null) {
    fields['websocket_url'] = uri.toString();
  }
  return fields;
}

Map<String, String> _firstNonBlankQueryParameterValues(
  Map<String, List<String>> queryParametersAll,
) {
  final result = <String, String>{};
  for (final entry in queryParametersAll.entries) {
    final value = _firstNonBlankQueryParameterValue(entry.value);
    if (value != null) result[entry.key] = value;
  }
  return result;
}

String? _firstNonBlankQueryParameterValue(List<String> values) {
  for (final value in values) {
    final text = navivoxOptionalLiteralStringFromJson(value);
    if (text != null) return text;
  }
  return null;
}

String? _baseUrlFromGenericUri(Uri uri) {
  return switch (uri.scheme) {
    'http' || 'https' => navivoxOriginFromUri(uri),
    'ws' || 'wss' => _webSocketUriBaseUrl(uri),
    _ => null,
  };
}

bool _isWebSocketUri(Uri uri) => uri.scheme == 'ws' || uri.scheme == 'wss';

String? _webSocketUriBaseUrl(Uri uri) {
  try {
    return navivoxHttpBaseUrlFromEndpointUri(uri);
  } on FormatException {
    return null;
  }
}

class _ConnectionImportCandidate {
  const _ConnectionImportCandidate({
    this.baseUrl,
    this.token,
    this.webSocketUrl,
    this.serverId,
    this.profileId,
  });

  final String? baseUrl;
  final String? token;
  final String? webSocketUrl;
  final String? serverId;
  final String? profileId;

  bool get hasImportValues => baseUrl != null || token != null;

  bool get hasCompleteConnection => baseUrl != null && token != null;

  _ConnectionImportCandidateRank get rank => _ConnectionImportCandidateRank(
    isCompleteConnection: hasCompleteConnection,
    fieldScore: _fieldScore,
  );

  int get _fieldScore {
    var result = 0;
    if (baseUrl != null) result += 2;
    if (token != null) result += 2;
    if (webSocketUrl != null) result += 1;
    if (serverId != null) result += 1;
    if (profileId != null) result += 1;
    return result;
  }

  bool isRicherThan(_ConnectionImportCandidate? other) {
    return other == null || rank.isRicherThan(other.rank);
  }

  SetupQrImageImport toImport() {
    return SetupQrImageImport(
      baseUrl: baseUrl,
      token: token,
      webSocketUrl: webSocketUrl,
      serverId: serverId,
      profileId: profileId,
    );
  }
}

class _ConnectionImportCandidateRank {
  const _ConnectionImportCandidateRank({
    required this.isCompleteConnection,
    required this.fieldScore,
  });

  final bool isCompleteConnection;
  final int fieldScore;

  bool isRicherThan(_ConnectionImportCandidateRank other) {
    if (isCompleteConnection != other.isCompleteConnection) {
      return isCompleteConnection;
    }
    return fieldScore > other.fieldScore;
  }
}

_ConnectionImportCandidate _richerConnectionImportCandidate({
  required _ConnectionImportCandidate? currentBest,
  required _ConnectionImportCandidate candidate,
}) {
  // A complete baseUrl+token candidate can still be lower-fidelity than a later
  // complete candidate carrying provenance metadata. Selection therefore scores
  // all candidates instead of short-circuiting at the first complete import.
  return candidate.isRicherThan(currentBest) ? candidate : currentBest!;
}

const _tokenFieldNames = [
  'token',
  'pairing_token',
  'pairingToken',
  'auth_token',
  'rest_token',
  'restToken',
];
const _webSocketUrlFieldNames = [
  'websocket_url',
  'websocketUrl',
  'ws_url',
  'wsUrl',
];
const _baseUrlFieldNames = ['base_url', 'baseUrl', 'gateway_url', 'url'];
const _serverIdFieldNames = ['server_id', 'serverId'];
const _profileIdFieldNames = ['profile_id', 'profileId'];

String? _firstEndpointUrl(String text) {
  final value = _endpointUrlPattern.firstMatch(text)?.group(0);
  if (value == null) return null;
  return _trimCopiedUrlTrailingPunctuation(value);
}

// Shared-text imports accept the same generic endpoint schemes as direct URL
// imports. Keeping the regex explicit prevents HTTP-only drift from silently
// dropping websocket endpoints embedded in prose.
final _endpointUrlPattern = RegExp(r'(?:https?|wss?)://\S+');

String _trimCopiedUrlTrailingPunctuation(String url) {
  var end = url.length;
  while (end > 0 && _copiedUrlTrailingPunctuation.contains(url[end - 1])) {
    end--;
  }
  return url.substring(0, end);
}

// Plain-text shares often end a copied URL with sentence/list punctuation. Keep
// this list explicit because these characters otherwise become part of the
// parsed origin when the shared URL has no path.
const _copiedUrlTrailingPunctuation = '.,;:!?)]}"\'';

String? _firstToken(String text) {
  final labeledToken = _firstLabeledToken(text);
  if (labeledToken != null) return labeledToken;

  final navivoxIndex = text.toLowerCase().indexOf('nvbx_');
  return navivoxIndex < 0 ? null : _readTokenAt(text, navivoxIndex);
}

String? _firstLabeledToken(String text) {
  for (final label in _tokenLabels) {
    final match = RegExp(
      '${RegExp.escape(label)}\\s*[:=]',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) continue;
    final token = _readTokenAt(text, match.end);
    if (token != null) return token;
  }
  return null;
}

const _tokenLabels = [
  'pairing token',
  'pairing_token',
  'pairing-token',
  'auth token',
  'auth_token',
  'auth-token',
  'token',
];

String? _readTokenAt(String text, int start) {
  var index = start;
  index = _skipTokenLeadingIgnoredChars(text, index);
  final tokenStart = index;
  while (index < text.length && _isTokenChar(text.codeUnitAt(index))) {
    index++;
  }
  if (index == tokenStart) return null;
  return _trimTokenTrailingPunctuation(text.substring(tokenStart, index));
}

int _skipTokenLeadingIgnoredChars(String text, int start) {
  var index = start;
  while (index < text.length) {
    final codeUnit = text.codeUnitAt(index);
    if (codeUnit <= 32 || _tokenLeadingDelimiters.contains(text[index])) {
      index++;
      continue;
    }
    break;
  }
  return index;
}

String _trimTokenTrailingPunctuation(String token) {
  var end = token.length;
  while (end > 0 && _tokenTrailingPunctuation.contains(token[end - 1])) {
    end--;
  }
  return token.substring(0, end);
}

const _tokenLeadingDelimiters = '"\'';
const _tokenTrailingPunctuation = '.,;:!?)]}"\'';

bool _isTokenChar(int codeUnit) {
  return (codeUnit >= 0x30 && codeUnit <= 0x39) ||
      (codeUnit >= 0x41 && codeUnit <= 0x5a) ||
      (codeUnit >= 0x61 && codeUnit <= 0x7a) ||
      codeUnit == 0x2d ||
      codeUnit == 0x2e ||
      codeUnit == 0x2f ||
      codeUnit == 0x3a ||
      codeUnit == 0x3d ||
      codeUnit == 0x5f ||
      codeUnit == 0x7e ||
      codeUnit == 0x2b;
}

String? _normalizeBaseUrl(String? raw) {
  final value = navivoxOptionalLiteralStringFromJson(raw);
  if (value == null) return null;

  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme) return value;
  if (uri.host.isEmpty) return null;

  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return null;
  return navivoxOriginFromUri(uri);
}

String? _normalizeWebSocketUrl(String? raw) =>
    navivoxWebSocketUrlFromEndpointString(
      navivoxOptionalLiteralStringFromJson(raw),
    );

String? _normalizeBaseUrlFromWebSocketUrl(String? normalizedWebSocketUrl) =>
    navivoxHttpBaseUrlFromEndpointString(normalizedWebSocketUrl);
