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

Iterable<_JsonConnectionImportFields> _jsonCandidateMaps(
  Map<dynamic, dynamic> decoded,
) sync* {
  final entries = decoded['entries'];
  if (entries is! List) {
    yield _JsonConnectionImportFields(
      fields: decoded,
      hasExplicitConnectionFields: true,
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
      hasExplicitConnectionFields: true,
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
    fields[entryField.key] = entryField.value;
  }
  return fields;
}

void _removeDefaultJsonAliasesOverriddenByEntry(
  Map<dynamic, dynamic> fields,
  Map<dynamic, dynamic> entry,
) {
  for (final aliases in _jsonConnectionImportFieldAliasGroups) {
    if (navivoxFirstStringFieldFromJson(entry, aliases) == null) continue;
    for (final alias in aliases) {
      fields.remove(alias);
    }
  }
}

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

SetupQrImageImport? _bestImportFromCandidateMaps(
  Iterable<_JsonConnectionImportFields> candidateMaps,
) {
  _ConnectionImportCandidate? bestCandidate;
  for (final candidateFields in candidateMaps) {
    final candidate = _connectionImportCandidateFromFields(
      candidateFields.fields,
      hasExplicitConnectionFields: candidateFields.hasExplicitConnectionFields,
    );
    if (candidate == null) continue;
    bestCandidate = _richerConnectionImportCandidate(
      currentBest: bestCandidate,
      candidate: candidate,
    );
  }
  return bestCandidate?.toImport();
}

_ConnectionImportCandidate? _connectionImportCandidateFromFields(
  Map<dynamic, dynamic> fields, {
  String? fallbackBaseUrl,
  bool hasExplicitConnectionFields = true,
}) {
  final token = navivoxFirstStringFieldFromJson(fields, _tokenFieldNames);
  final endpointFields = _connectionImportEndpointFields(fields);
  final candidate = _ConnectionImportCandidate(
    baseUrl: endpointFields.baseUrl ?? fallbackBaseUrl,
    token: token,
    webSocketUrl: endpointFields.webSocketUrl,
    serverId: navivoxFirstStringFieldFromJson(fields, _serverIdFieldNames),
    profileId: navivoxFirstStringFieldFromJson(fields, _profileIdFieldNames),
    hasExplicitConnectionFields: hasExplicitConnectionFields,
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
  return _connectionImportCandidateFromGenericUri(uri)?.toImport();
}

_ConnectionImportCandidate? _connectionImportCandidateFromGenericUri(Uri uri) {
  final candidate = _connectionImportCandidateFromFields(
    _genericUriFields(uri),
    fallbackBaseUrl: _baseUrlFromGenericUri(uri),
  );
  if (candidate != null) return candidate;
  if (uri.scheme == 'http' || uri.scheme == 'https') {
    return _ConnectionImportCandidate(baseUrl: navivoxOriginFromUri(uri));
  }
  if (_isWebSocketUri(uri)) {
    return _ConnectionImportCandidate(
      baseUrl: _webSocketUriBaseUrl(uri),
      webSocketUrl: uri.toString(),
    );
  }
  return null;
}

SetupQrImageImport? _importFromSharedText(String text) {
  final embeddedUrlCandidate = _bestGenericUrlCandidateFromSharedText(text);
  final token = _sharedTextImportToken(
    text: text,
    embeddedUrlCandidate: embeddedUrlCandidate,
  );
  if (embeddedUrlCandidate == null && token == null) return null;

  return SetupQrImageImport(
    baseUrl: embeddedUrlCandidate?.candidate.baseUrl,
    token: token,
    webSocketUrl: embeddedUrlCandidate?.candidate.webSocketUrl,
    serverId: embeddedUrlCandidate?.candidate.serverId,
    profileId: embeddedUrlCandidate?.candidate.profileId,
  );
}

String? _sharedTextImportToken({
  required String text,
  required _SharedTextEndpointCandidate? embeddedUrlCandidate,
}) {
  final candidateToken = embeddedUrlCandidate?.candidate.token;
  if (candidateToken != null) return candidateToken;

  // Keep token provenance aligned with the selected URL candidate. Tokens after
  // the selected URL are more likely to describe that endpoint than stale prose
  // tokens copied earlier in the share text. Preserve older token-before-URL
  // imports by falling back to the first token in the whole text.
  return _firstToken(
        text,
        start: embeddedUrlCandidate?.tokenSearchStart ?? 0,
        end: embeddedUrlCandidate?.tokenSearchEnd,
      ) ??
      _firstToken(text);
}

_SharedTextEndpointCandidate? _bestGenericUrlCandidateFromSharedText(
  String text,
) {
  _SharedTextEndpointCandidate? bestCandidate;
  for (final endpoint in _endpointUrls(text)) {
    final uri = Uri.tryParse(endpoint.url);
    final candidate = uri != null && uri.hasScheme
        ? _connectionImportCandidateFromGenericUri(uri)
        : _connectionImportCandidateFromFields({'base_url': endpoint.url});
    if (candidate == null) continue;
    final sharedTextCandidate = _SharedTextEndpointCandidate(
      candidate: candidate,
      tokenSearchStart: endpoint.tokenSearchStart,
      tokenSearchEnd: endpoint.tokenSearchEnd,
      hasFollowingToken:
          _firstToken(
            text,
            start: endpoint.tokenSearchStart,
            end: endpoint.tokenSearchEnd,
          ) !=
          null,
    );
    bestCandidate = sharedTextCandidate.isRicherThan(bestCandidate)
        ? sharedTextCandidate
        : bestCandidate;
  }
  return bestCandidate;
}

Iterable<_SharedTextEndpoint> _endpointUrls(String text) sync* {
  final matches = _endpointUrlPattern.allMatches(text).toList();
  for (var index = 0; index < matches.length; index++) {
    final match = matches[index];
    final url = match.group(0);
    if (url == null) continue;
    final nextEndpointStart = index + 1 < matches.length
        ? matches[index + 1].start
        : text.length;
    yield _SharedTextEndpoint(
      url: _trimCopiedUrlTrailingPunctuation(url),
      tokenSearchStart: match.end,
      tokenSearchEnd: nextEndpointStart,
    );
  }
}

class _SharedTextEndpoint {
  const _SharedTextEndpoint({
    required this.url,
    required this.tokenSearchStart,
    required this.tokenSearchEnd,
  });

  final String url;
  final int tokenSearchStart;
  final int tokenSearchEnd;
}

class _SharedTextEndpointCandidate {
  const _SharedTextEndpointCandidate({
    required this.candidate,
    required this.tokenSearchStart,
    required this.tokenSearchEnd,
    required this.hasFollowingToken,
  });

  final _ConnectionImportCandidate candidate;
  final int tokenSearchStart;
  final int tokenSearchEnd;
  final bool hasFollowingToken;

  bool isRicherThan(_SharedTextEndpointCandidate? other) {
    if (other == null) return true;

    final rank = candidate.rank;
    final otherRank = other.candidate.rank;
    if (rank.isRicherThan(otherRank)) return true;
    if (otherRank.isRicherThan(rank)) return false;

    // When two bare URLs expose the same connection fields, bind shared-text
    // tokens to the URL whose segment actually contains the token. This avoids
    // pairing a later setup token with an earlier documentation URL.
    if (hasFollowingToken != other.hasFollowingToken) return hasFollowingToken;
    return false;
  }
}

Map<String, String> _genericUriFields(Uri uri) {
  final fields = navivoxFirstNonBlankQueryParameterValues(
    uri.queryParametersAll,
  );
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
    this.hasExplicitConnectionFields = true,
  });

  final String? baseUrl;
  final String? token;
  final String? webSocketUrl;
  final String? serverId;
  final String? profileId;
  final bool hasExplicitConnectionFields;

  bool get hasImportValues => baseUrl != null || token != null;

  bool get hasCompleteConnection => baseUrl != null && token != null;

  _ConnectionImportCandidateRank get rank => _ConnectionImportCandidateRank(
    isCompleteConnection: hasCompleteConnection,
    hasExplicitConnectionFields: hasExplicitConnectionFields,
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
    required this.hasExplicitConnectionFields,
    required this.fieldScore,
  });

  final bool isCompleteConnection;
  final bool hasExplicitConnectionFields;
  final int fieldScore;

  bool isRicherThan(_ConnectionImportCandidateRank other) {
    if (isCompleteConnection != other.isCompleteConnection) {
      return isCompleteConnection;
    }
    if (hasExplicitConnectionFields != other.hasExplicitConnectionFields) {
      return hasExplicitConnectionFields;
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
const _jsonConnectionImportFieldAliasGroups = [
  _tokenFieldNames,
  _webSocketUrlFieldNames,
  _baseUrlFieldNames,
  _serverIdFieldNames,
  _profileIdFieldNames,
];

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

// Plain-text shares often end a copied URL with sentence/list punctuation or
// markdown/code delimiters. Keep this list explicit because these characters
// otherwise become part of the parsed origin when the shared URL has no path,
// or part of a query token when the URL carries connection credentials.
const _copiedUrlTrailingPunctuation = '.,;:!?)]}>"\'`';

String? _firstToken(String text, {int start = 0, int? end}) {
  final tokenSearchEnd = end ?? text.length;
  final labeledToken = _firstLabeledToken(
    text,
    start: start,
    end: tokenSearchEnd,
  );
  if (labeledToken != null) return labeledToken;

  final navivoxIndex = text.toLowerCase().indexOf('nvbx_', start);
  if (navivoxIndex < 0 || navivoxIndex >= tokenSearchEnd) return null;
  return _readTokenAt(text, navivoxIndex, end: tokenSearchEnd);
}

String? _firstLabeledToken(
  String text, {
  required int start,
  required int end,
}) {
  _LabeledTokenMatch? earliestMatch;
  for (final label in _tokenLabels) {
    final matches = RegExp(
      '${RegExp.escape(label)}\\s*[:=]',
      caseSensitive: false,
    ).allMatches(text, start).where((match) => match.start < end);
    for (final match in matches) {
      final token = _readLabeledTokenAt(text, match.end, end: end);
      if (token == null) continue;
      final candidate = _LabeledTokenMatch(start: match.start, token: token);
      if (candidate.isBefore(earliestMatch)) earliestMatch = candidate;
    }
  }
  return earliestMatch?.token;
}

class _LabeledTokenMatch {
  const _LabeledTokenMatch({required this.start, required this.token});

  final int start;
  final String token;

  bool isBefore(_LabeledTokenMatch? other) =>
      other == null || start < other.start;
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

String? _readLabeledTokenAt(String text, int start, {int? end}) {
  final token = _readTokenAt(text, start, end: end);
  if (token == null || _looksLikeUrlToken(token)) return null;
  return token;
}

bool _looksLikeUrlToken(String token) =>
    RegExp(r'^[a-z][a-z0-9+.-]*://', caseSensitive: false).hasMatch(token);

String? _readTokenAt(String text, int start, {int? end}) {
  final tokenSearchEnd = end ?? text.length;
  var index = start;
  index = _skipTokenLeadingIgnoredChars(text, index, end: tokenSearchEnd);
  final tokenStart = index;
  while (index < tokenSearchEnd &&
      index < text.length &&
      _isTokenChar(text.codeUnitAt(index))) {
    index++;
  }
  if (index == tokenStart) return null;
  return _trimTokenTrailingPunctuation(text.substring(tokenStart, index));
}

int _skipTokenLeadingIgnoredChars(String text, int start, {int? end}) {
  final tokenSearchEnd = end ?? text.length;
  var index = start;
  while (index < tokenSearchEnd && index < text.length) {
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

// Shared-text tokens may be copied from prose, quoted strings, or markdown
// code spans. Keep leading/trailing delimiters explicit so broad human-entered
// token support does not silently diverge between delimiter styles.
const _tokenLeadingDelimiters = '"\'`';
const _tokenTrailingPunctuation = '.,;:!?)]}"\'`';

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
