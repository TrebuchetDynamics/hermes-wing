import 'dart:convert';

import '../../../../core/protocol/navivox_endpoint_uri.dart';
import '../../../../core/protocol/navivox_json.dart';
import '../../../../core/protocol/navivox_pairing_descriptor.dart';
import '../../models/connection_import.dart';

part 'candidate.dart';
part 'candidate_rank.dart';
part 'endpoint_uri_identity.dart';
part 'json_candidate_maps.dart';
part 'shared_text_endpoint.dart';
part 'shared_text_endpoint_selection.dart';

class ConnectionImportParser {
  const ConnectionImportParser();

  SetupQrImageImport? parsePayload(String payload) {
    final text = payload.trim();
    if (text.isEmpty) return null;

    final jsonResult = _parseQrJsonPayload(text);
    if (jsonResult.isJsonObject) return jsonResult.importValue;

    final copiedUriPayload = _copiedUriPayload(text);
    if (copiedUriPayload != null) {
      return _importFromCopiedUriPayload(copiedUriPayload);
    }

    return _importFromSharedText(text);
  }

  _CopiedUriPayload? _copiedUriPayload(String text) {
    final copiedUrl = _trimCopiedEndpointUrl(text);
    if (_containsWhitespace(copiedUrl)) return null;
    final uri = Uri.tryParse(copiedUrl);
    if (uri == null || !uri.hasScheme) return null;
    return _CopiedUriPayload(text: copiedUrl, uri: uri);
  }

  _JsonPayloadParseResult _parseQrJsonPayload(String text) {
    Object? decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      return const _JsonPayloadParseResult.notJsonObject();
    }
    if (decoded is! Map) return const _JsonPayloadParseResult.notJsonObject();

    // JSON object payloads are a structured import contract. If the object does
    // not expose connection fields, do not reinterpret arbitrary JSON string
    // values as prose tokens or copied URLs.
    return _JsonPayloadParseResult.jsonObject(
      _bestImportFromCandidateMaps(_jsonCandidateMaps(decoded)),
    );
  }
}

class _JsonPayloadParseResult {
  const _JsonPayloadParseResult.jsonObject(this.importValue)
    : isJsonObject = true;

  const _JsonPayloadParseResult.notJsonObject()
    : isJsonObject = false,
      importValue = null;

  final bool isJsonObject;
  final SetupQrImageImport? importValue;
}

SetupQrImageImport? parseNavivoxConnectionImportPayload(String payload) =>
    const ConnectionImportParser().parsePayload(payload);

SetupQrImageImport? _importFromCopiedUriPayload(_CopiedUriPayload payload) {
  // A navivox://connect URI is a closed protocol contract: if it is malformed,
  // do not reinterpret its query params as a generic token-only import.
  if (_isCorePairingDescriptorUri(payload.uri)) {
    return _parseCorePairingDescriptorPayload(payload.text) ??
        (_isLegacyNavivoxConnectCompatibilityUri(payload.uri)
            ? _importFromLegacyNavivoxConnectCompatibilityUri(payload.uri)
            : null);
  }
  return _importFromGenericUri(payload.uri);
}

SetupQrImageImport? _importFromLegacyNavivoxConnectCompatibilityUri(Uri uri) {
  return _connectionImportCandidateFromFields(_uriQueryFields(uri))?.toImport();
}

bool _isLegacyNavivoxConnectCompatibilityUri(Uri uri) {
  final query = navivoxFirstNonBlankQueryParameterValues(
    uri.queryParametersAll,
  );
  if (navivoxFirstStringFieldFromJson(query, _webSocketUrlFieldNames) != null) {
    return false;
  }
  if (navivoxFirstStringFieldFromJson(query, const [
        'rest_token',
        'restToken',
      ]) !=
      null) {
    return false;
  }
  return navivoxFirstStringFieldFromJson(query, _baseUrlFieldNames) != null ||
      navivoxFirstStringFieldFromJson(query, const ['token']) != null;
}

class _CopiedUriPayload {
  const _CopiedUriPayload({required this.text, required this.uri});

  final String text;
  final Uri uri;
}

bool _isCorePairingDescriptorUri(Uri uri) =>
    uri.scheme == 'navivox' && uri.host == 'connect';

bool _containsWhitespace(String value) =>
    value.codeUnits.any((unit) => unit <= 32);

SetupQrImageImport? _bestImportFromCandidateMaps(
  Iterable<_JsonConnectionImportFields> candidateMaps,
) {
  return _bestConnectionImportCandidate(
    _jsonConnectionImportCandidates(candidateMaps),
  )?.toImport();
}

Iterable<_ConnectionImportCandidate> _jsonConnectionImportCandidates(
  Iterable<_JsonConnectionImportFields> candidateMaps,
) sync* {
  for (final candidateFields in candidateMaps) {
    final candidate = _connectionImportCandidateFromFields(
      candidateFields.fields,
      hasExplicitConnectionFields: candidateFields.hasExplicitConnectionFields,
    );
    if (candidate != null) yield candidate;
  }
}

_ConnectionImportCandidate? _bestConnectionImportCandidate(
  Iterable<_ConnectionImportCandidate> candidates,
) {
  _ConnectionImportCandidate? bestCandidate;
  for (final candidate in candidates) {
    bestCandidate = _richerConnectionImportCandidate(
      currentBest: bestCandidate,
      candidate: candidate,
    );
  }
  return bestCandidate;
}

_ConnectionImportCandidate? _connectionImportCandidateFromFields(
  Map<dynamic, dynamic> fields, {
  String? fallbackBaseUrl,
  bool hasExplicitConnectionFields = true,
}) {
  final explicitToken = navivoxFirstStringFieldFromJson(
    fields,
    _tokenFieldNames,
  );
  final endpointFields = _connectionImportEndpointFields(fields);
  final candidate = _ConnectionImportCandidate(
    baseUrl: endpointFields.baseUrl ?? fallbackBaseUrl,
    token: explicitToken ?? endpointFields.queryToken,
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
  final rawBaseUrl = navivoxFirstStringFieldFromJson(
    fields,
    _baseUrlFieldNames,
  );
  final rawWebSocketUrl = navivoxFirstStringFieldFromJson(
    fields,
    _webSocketUrlFieldNames,
  );
  final normalizedWebSocketUrl = _normalizeWebSocketUrl(rawWebSocketUrl);
  final normalizedBaseUrl = _normalizeBaseUrl(rawBaseUrl);
  return _ConnectionImportEndpointFields(
    baseUrl:
        normalizedBaseUrl ??
        _normalizeBaseUrlFromWebSocketUrl(normalizedWebSocketUrl),
    webSocketUrl: normalizedWebSocketUrl,
    queryToken: _firstEndpointQueryToken(
      rawBaseUrl: normalizedBaseUrl == null ? null : rawBaseUrl,
      normalizedWebSocketUrl: normalizedWebSocketUrl,
    ),
  );
}

class _ConnectionImportEndpointFields {
  const _ConnectionImportEndpointFields({
    this.baseUrl,
    this.webSocketUrl,
    this.queryToken,
  });

  final String? baseUrl;
  final String? webSocketUrl;
  final String? queryToken;
}

String? _firstEndpointQueryToken({
  required String? rawBaseUrl,
  required String? normalizedWebSocketUrl,
}) {
  return _tokenFromEndpointQuery(rawBaseUrl) ??
      _tokenFromEndpointQuery(normalizedWebSocketUrl);
}

String? _tokenFromEndpointQuery(String? url) {
  if (url == null) return null;
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasQuery) return null;
  return navivoxFirstStringFieldFromJson(
    navivoxFirstNonBlankQueryParameterValues(uri.queryParametersAll),
    _tokenFieldNames,
  );
}

SetupQrImageImport? _importFromGenericUri(Uri uri) {
  return _connectionImportCandidateFromGenericUri(uri)?.toImport();
}

_ConnectionImportCandidate? _connectionImportCandidateFromGenericUri(Uri uri) {
  final identity = _ConnectionImportEndpointUriIdentity.fromUri(uri);
  if (!identity.isSupported) return null;

  final candidate = _connectionImportCandidateFromFields(
    _genericUriFields(uri, identity: identity),
    fallbackBaseUrl: identity.baseUrl,
  );
  if (candidate != null) return candidate;
  if (identity.kind == _GenericEndpointSchemeKind.http) {
    return _ConnectionImportCandidate(baseUrl: identity.baseUrl);
  }
  return _ConnectionImportCandidate(
    baseUrl: identity.baseUrl,
    webSocketUrl: uri.toString(),
  );
}

SetupQrImageImport? _importFromSharedText(String text) {
  final coreDescriptorCandidates =
      _corePairingDescriptorCandidatesFromSharedText(
        text,
      ).toList(growable: false);
  for (final coreDescriptor in coreDescriptorCandidates) {
    final coreImport = _parseCorePairingDescriptorPayload(
      coreDescriptor.payload,
    );
    if (coreImport != null) return coreImport;
  }

  final genericEndpoints = _endpointUrls(text).toList(growable: false);
  final embeddedUrlCandidate = _bestGenericUrlCandidateFromSharedText(
    text,
    genericEndpoints,
  );
  if (embeddedUrlCandidate == null &&
      (coreDescriptorCandidates.isNotEmpty || genericEndpoints.isNotEmpty)) {
    return null;
  }
  final tokenSourceText = _sharedTextWithoutMalformedCoreDescriptors(
    text,
    coreDescriptorCandidates,
  );
  final token = _sharedTextImportToken(
    text: tokenSourceText,
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

  return _SharedTextTokenProvenance.fromSelectedEndpoint(
    embeddedUrlCandidate,
  ).firstToken(text);
}

_SharedTextEndpointCandidate? _bestGenericUrlCandidateFromSharedText(
  String text,
  Iterable<_SharedTextEndpoint> endpoints,
) {
  _SharedTextEndpointCandidate? bestCandidate;
  for (final endpoint in endpoints) {
    final candidate = _sharedTextEndpointCandidate(text, endpoint);
    if (candidate == null) continue;
    bestCandidate = candidate.isRicherThan(bestCandidate)
        ? candidate
        : bestCandidate;
  }
  return bestCandidate;
}

_SharedTextEndpointCandidate? _sharedTextEndpointCandidate(
  String text,
  _SharedTextEndpoint endpoint,
) {
  final uri = Uri.tryParse(endpoint.url);
  final candidate = uri != null && uri.hasScheme
      ? _connectionImportCandidateFromGenericUri(uri)
      : _connectionImportCandidateFromFields({'base_url': endpoint.url});
  if (candidate == null) return null;

  final followingToken = endpoint.followingToken(text);
  return _SharedTextEndpointCandidate(
    candidate: candidate,
    tokenSearchStart: endpoint.tokenWindow.start,
    tokenSearchEnd: endpoint.tokenWindow.end,
    leadingTokenSearchEnd: endpoint.sourceWindow.start,
    hasFollowingToken: followingToken != null,
    canUseLeadingToken: !endpoint.hasPriorEndpoint,
    hasConnectionPath: uri != null && _hasConnectionPath(uri),
  );
}

Iterable<_SharedTextEndpoint> _endpointUrls(String text) =>
    _sharedTextEndpoints(text);

Iterable<_SharedTextEndpointMatch> _endpointUrlMatches(String text) sync* {
  for (final match in _endpointUrlPattern.allMatches(text)) {
    final matchedText = match.group(0);
    if (matchedText == null) continue;
    final trimmedUrlStart = _copiedEndpointUrlStart(matchedText);
    final rawUrlEnd = _matchedEndpointUrlEndBeforeAttachedTokenLabel(
      matchedText,
      start: trimmedUrlStart,
    );
    final trimmedUrlEnd = _copiedEndpointUrlEnd(
      matchedText.substring(0, rawUrlEnd),
      start: trimmedUrlStart,
    );
    if (trimmedUrlEnd <= trimmedUrlStart) continue;

    yield _SharedTextEndpointMatch(
      url: matchedText.substring(trimmedUrlStart, trimmedUrlEnd),
      sourceWindow: _TextWindow(start: match.start, end: match.end),
      trailingPunctuationWindow: _TextWindow(
        start: match.start + trimmedUrlEnd,
        end: match.end,
      ),
    );
  }
}

int _matchedEndpointUrlEndBeforeAttachedTokenLabel(
  String matchedText, {
  required int start,
}) {
  final punctuationAlternation = _attachedTokenLabelPunctuation
      .map(RegExp.escape)
      .join('|');
  int? earliestTokenLabelStart;
  for (final label in _tokenLabels) {
    final labelPattern = RegExp(
      '(?:$punctuationAlternation)\\s*${RegExp.escape(label)}\\s*[:=]',
      caseSensitive: false,
    );
    final match = labelPattern.firstMatch(matchedText.substring(start));
    if (match == null) continue;
    final labelStart = start + match.start;
    if (earliestTokenLabelStart == null ||
        labelStart < earliestTokenLabelStart) {
      earliestTokenLabelStart = labelStart;
    }
  }
  return earliestTokenLabelStart ?? matchedText.length;
}

bool _hasConnectionPath(Uri uri) {
  return uri.pathSegments.any(
    (segment) => _connectionPathSegments.contains(segment.toLowerCase()),
  );
}

const _connectionPathSegments = {'connect', 'connection', 'pair', 'pairing'};

SetupQrImageImport? _parseCorePairingDescriptorPayload(String text) {
  final uri = Uri.tryParse(text);
  if (uri == null || !_isCorePairingDescriptorUri(uri)) return null;
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

Iterable<_SharedTextCoreDescriptorCandidate>
_corePairingDescriptorCandidatesFromSharedText(String text) sync* {
  for (final match in _corePairingDescriptorUriPattern.allMatches(text)) {
    final matchedText = match.group(0);
    if (matchedText == null) continue;
    yield _SharedTextCoreDescriptorCandidate(
      payload: _trimCopiedEndpointUrl(matchedText),
      sourceWindow: _TextWindow(start: match.start, end: match.end),
    );
  }
}

class _SharedTextCoreDescriptorCandidate {
  const _SharedTextCoreDescriptorCandidate({
    required this.payload,
    required this.sourceWindow,
  });

  final String payload;
  final _TextWindow sourceWindow;
}

String _sharedTextWithoutMalformedCoreDescriptors(
  String text,
  Iterable<_SharedTextCoreDescriptorCandidate> coreDescriptors,
) {
  final characters = text.split('');
  for (final descriptor in coreDescriptors) {
    if (_parseCorePairingDescriptorPayload(descriptor.payload) != null) {
      continue;
    }
    for (
      var index = descriptor.sourceWindow.start;
      index < descriptor.sourceWindow.end;
      index++
    ) {
      characters[index] = ' ';
    }
  }
  return characters.join();
}

final _corePairingDescriptorUriPattern = RegExp(
  r'\bnavivox://connect(?:\?\S*)?',
  caseSensitive: false,
);

Map<String, String> _genericUriFields(
  Uri uri, {
  required _ConnectionImportEndpointUriIdentity identity,
}) {
  final fields = _uriQueryFields(uri);
  if (identity.isWebSocket &&
      navivoxFirstStringFieldFromJson(fields, _webSocketUrlFieldNames) ==
          null) {
    fields['websocket_url'] = uri.toString();
  }
  return fields;
}

Map<String, String> _uriQueryFields(Uri uri) =>
    navivoxFirstNonBlankQueryParameterValues(uri.queryParametersAll);

enum _GenericEndpointSchemeKind { http, webSocket, unsupported }

bool _hasGenericEndpointIdentity(Uri uri) =>
    uri.hasScheme && uri.host.isNotEmpty && _hasValidExplicitPort(uri);

bool _hasValidExplicitPort(Uri uri) {
  if (!uri.hasPort) return true;
  try {
    final port = uri.port;
    return port > 0 && port <= 65535;
  } on FormatException {
    return false;
  }
}

String? _webSocketUriBaseUrl(Uri uri) {
  try {
    return navivoxHttpBaseUrlFromEndpointUri(uri);
  } on FormatException {
    return null;
  }
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
// dropping websocket endpoints embedded in prose. URI schemes are
// case-insensitive, so match copied prose URLs case-insensitively before Uri
// parsing normalizes the selected candidate.
final _endpointUrlPattern = RegExp(
  r'(?:https?|wss?)://\S+',
  caseSensitive: false,
);

String _trimCopiedEndpointUrl(String url) {
  final start = _copiedEndpointUrlStart(url);
  final end = _copiedEndpointUrlEnd(url, start: start);
  return url.substring(start, end);
}

int _copiedEndpointUrlStart(String url) {
  var start = 0;
  while (start < url.length &&
      _copiedUrlLeadingDelimiters.contains(url[start])) {
    start++;
  }
  return start;
}

int _copiedEndpointUrlEnd(String url, {required int start}) {
  var end = url.length;
  while (end > start &&
      _shouldTrimCopiedEndpointTrailingChar(url, start, end)) {
    end--;
  }
  return end;
}

bool _shouldTrimCopiedEndpointTrailingChar(String url, int start, int end) {
  final char = url[end - 1];
  if (!_copiedUrlTrailingPunctuation.contains(char)) return false;
  return switch (char) {
    ')' => _hasUnmatchedClosingDelimiterAtEnd(
      url,
      start: start,
      end: end,
      open: '(',
      close: ')',
    ),
    ']' => _hasUnmatchedClosingDelimiterAtEnd(
      url,
      start: start,
      end: end,
      open: '[',
      close: ']',
    ),
    '}' => _hasUnmatchedClosingDelimiterAtEnd(
      url,
      start: start,
      end: end,
      open: '{',
      close: '}',
    ),
    _ => true,
  };
}

bool _hasUnmatchedClosingDelimiterAtEnd(
  String text, {
  required int start,
  required int end,
  required String open,
  required String close,
}) {
  var balance = 0;
  for (var index = start; index < end; index++) {
    final char = text[index];
    if (char == open) balance++;
    if (char == close) balance--;
  }
  return balance < 0;
}

// Plain-text shares often wrap or end a copied URL with sentence/list
// punctuation or markdown/code delimiters. Keep these lists explicit because
// these characters otherwise become part of the parsed origin when the shared
// URL has no path, or part of a query token when the URL carries connection
// credentials.
const _copiedUrlLeadingDelimiters = '<"\'`';
const _copiedUrlTrailingPunctuation = '.,;:!?)]}>"\'`';
const _attachedTokenLabelPunctuation = [
  ',',
  ';',
  '.',
  '!',
  ')',
  ']',
  '}',
  '>',
  '"',
  "'",
  '`',
];

String? _firstToken(String text, {int start = 0, int? end}) {
  return _tokenInWindow(
    text,
    start: start,
    end: end ?? text.length,
    preferLatest: false,
  );
}

String? _lastToken(String text, {int start = 0, int? end}) {
  return _tokenInWindow(
    text,
    start: start,
    end: end ?? text.length,
    preferLatest: true,
  );
}

String? _tokenInWindow(
  String text, {
  required int start,
  required int end,
  required bool preferLatest,
}) {
  final labeledToken = _labeledTokenInWindow(
    text,
    start: start,
    end: end,
    preferLatest: preferLatest,
  );
  if (labeledToken != null) return labeledToken;

  return preferLatest
      ? _lastNavivoxToken(text, start: start, end: end)
      : _firstNavivoxToken(text, start: start, end: end);
}

String? _labeledTokenInWindow(
  String text, {
  required int start,
  required int end,
  required bool preferLatest,
}) {
  _TokenMatch? selectedMatch;
  for (final label in _tokenLabels) {
    final matches = _tokenLabelPattern(
      label,
    ).allMatches(text, start).where((match) => match.start < end);
    for (final match in matches) {
      final token = _readLabeledTokenAt(text, match.end, end: end);
      if (token == null) continue;
      final candidate = _TokenMatch(start: match.start, token: token);
      if (candidate.isPreferredOver(
        selectedMatch,
        preferLatest: preferLatest,
      )) {
        selectedMatch = candidate;
      }
    }
  }
  return selectedMatch?.token;
}

String? _firstNavivoxToken(
  String text, {
  required int start,
  required int end,
}) {
  final index = _firstNavivoxTokenStart(text, start: start, end: end);
  if (index == null) return null;
  return _readTokenAt(text, index, end: end);
}

String? _lastNavivoxToken(String text, {required int start, required int end}) {
  final index = _lastNavivoxTokenStart(text, start: start, end: end);
  if (index == null) return null;
  return _readTokenAt(text, index, end: end);
}

int? _firstNavivoxTokenStart(
  String text, {
  required int start,
  required int end,
}) {
  return _navivoxTokenStart(text, start: start, end: end, preferLatest: false);
}

int? _lastNavivoxTokenStart(
  String text, {
  required int start,
  required int end,
}) {
  return _navivoxTokenStart(text, start: start, end: end, preferLatest: true);
}

int? _navivoxTokenStart(
  String text, {
  required int start,
  required int end,
  required bool preferLatest,
}) {
  var searchStart = start;
  int? selectedIndex;
  final lower = text.toLowerCase();
  while (searchStart < end) {
    final navivoxIndex = lower.indexOf('nvbx_', searchStart);
    if (navivoxIndex < 0 || navivoxIndex >= end) break;
    if (_hasTokenStartBoundary(text, navivoxIndex, windowStart: start)) {
      selectedIndex = navivoxIndex;
      if (!preferLatest) break;
    }
    searchStart = navivoxIndex + 1;
  }
  return selectedIndex;
}

bool _hasTokenStartBoundary(
  String text,
  int tokenStart, {
  required int windowStart,
}) {
  if (tokenStart <= windowStart) return true;
  return !_isTokenChar(text.codeUnitAt(tokenStart - 1));
}

class _TokenMatch {
  const _TokenMatch({required this.start, required this.token});

  final int start;
  final String token;

  bool isPreferredOver(_TokenMatch? other, {required bool preferLatest}) {
    if (other == null) return true;
    return preferLatest ? start > other.start : start < other.start;
  }
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

RegExp _tokenLabelPattern(String label) {
  // Field labels are provenance, not substring searches. Without an explicit
  // left boundary, a copied field such as "notoken:" or "server-token:" can
  // accidentally satisfy the generic "token:" label and attach unrelated data
  // to the selected endpoint.
  return RegExp(
    '(^|[^A-Za-z0-9_-])${RegExp.escape(label)}\\s*[:=]',
    caseSensitive: false,
  );
}

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
  if (_tokenContinuesPastWindow(text, index, tokenSearchEnd)) return null;
  return _trimTokenTrailingPunctuationOrNull(text.substring(tokenStart, index));
}

bool _tokenContinuesPastWindow(String text, int tokenEnd, int windowEnd) {
  return tokenEnd == windowEnd &&
      windowEnd < text.length &&
      _isTokenChar(text.codeUnitAt(windowEnd));
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

String? _trimTokenTrailingPunctuationOrNull(String token) {
  var end = token.length;
  while (end > 0 && _tokenTrailingPunctuation.contains(token[end - 1])) {
    end--;
  }
  final trimmed = token.substring(0, end);
  return trimmed.isEmpty ? null : trimmed;
}

// Shared-text tokens may be copied from prose, quoted strings, markdown code
// spans, or angle-bracket wrappers. Keep delimiter pairs explicit so broad
// human-entered token support does not silently diverge between wrapper styles.
const _tokenLeadingDelimiters = '"\'`<';
const _tokenTrailingPunctuation = '.,;:!?)]}>"\'`';

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
  if (uri.host.isEmpty || !_hasValidExplicitPort(uri)) return null;

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
