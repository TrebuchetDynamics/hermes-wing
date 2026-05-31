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

    final baseUrl = _normalizeBaseUrl(_firstUrl(text));
    final token = _firstToken(text);
    if (baseUrl != null || token != null) {
      return SetupQrImageImport(baseUrl: baseUrl, token: token);
    }
    return null;
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
  yield decoded;
  final entries = decoded['entries'];
  if (entries is! List) return;
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
  final webSocketUrl = navivoxFirstStringFieldFromJson(
    fields,
    _webSocketUrlFieldNames,
  );
  final explicitBaseUrl =
      _normalizeBaseUrl(
        navivoxFirstStringFieldFromJson(fields, _baseUrlFieldNames),
      ) ??
      _normalizeWebSocketBaseUrl(webSocketUrl);
  final candidate = _ConnectionImportCandidate(
    baseUrl: explicitBaseUrl ?? fallbackBaseUrl,
    token: token,
    webSocketUrl: _normalizeWebSocketUrl(webSocketUrl),
    serverId: navivoxFirstStringFieldFromJson(fields, _serverIdFieldNames),
    profileId: navivoxFirstStringFieldFromJson(fields, _profileIdFieldNames),
  );
  if (!candidate.hasImportValues) return null;

  return candidate;
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

Map<String, String> _genericUriFields(Uri uri) {
  final fields = Map<String, String>.of(uri.queryParameters);
  if (_isWebSocketUri(uri) &&
      navivoxFirstStringFieldFromJson(fields, _webSocketUrlFieldNames) ==
          null) {
    fields['websocket_url'] = uri.toString();
  }
  return fields;
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

  int get score {
    var result = 0;
    if (baseUrl != null) result += 2;
    if (token != null) result += 2;
    if (webSocketUrl != null) result += 1;
    if (serverId != null) result += 1;
    if (profileId != null) result += 1;
    return result;
  }

  bool isRicherThan(_ConnectionImportCandidate? other) {
    return other == null || score > other.score;
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

String? _firstUrl(String text) {
  var value = RegExp(r'https?://\S+').firstMatch(text)?.group(0);
  while (value != null &&
      value.isNotEmpty &&
      ',;)]}"'.contains(value[value.length - 1])) {
    value = value.substring(0, value.length - 1);
  }
  return value;
}

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
  while (index < text.length && text.codeUnitAt(index) <= 32) {
    index++;
  }
  final tokenStart = index;
  while (index < text.length && _isTokenChar(text.codeUnitAt(index))) {
    index++;
  }
  if (index == tokenStart) return null;
  return _trimTokenTrailingPunctuation(text.substring(tokenStart, index));
}

String _trimTokenTrailingPunctuation(String token) {
  var end = token.length;
  while (end > 0 && '.,;:!?)]}"\''.contains(token[end - 1])) {
    end--;
  }
  return token.substring(0, end);
}

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

String? _normalizeBaseUrl(String? raw) => navivoxHttpOriginOrOriginalFromString(
  navivoxOptionalLiteralStringFromJson(raw),
);

String? _normalizeWebSocketUrl(String? raw) =>
    navivoxWebSocketUrlFromEndpointString(
      navivoxOptionalLiteralStringFromJson(raw),
    );

String? _normalizeWebSocketBaseUrl(String? raw) =>
    navivoxHttpBaseUrlFromEndpointString(
      navivoxOptionalLiteralStringFromJson(raw),
    );
