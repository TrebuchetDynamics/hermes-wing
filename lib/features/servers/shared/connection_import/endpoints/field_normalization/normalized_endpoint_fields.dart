part of '../../parser.dart';

_ConnectionImportEndpointFields _connectionImportEndpointFields(
  Map<dynamic, dynamic> fields,
) {
  return _ConnectionImportEndpointFieldSources.fromRawFields(fields).toFields();
}

class _ConnectionImportEndpointFieldSources {
  const _ConnectionImportEndpointFieldSources({
    required this.rawBaseUrl,
    required this.rawWebSocketUrl,
    required this.normalizedBaseUrl,
    required this.normalizedWebSocketUrl,
  });

  factory _ConnectionImportEndpointFieldSources.fromRawFields(
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
    return _ConnectionImportEndpointFieldSources(
      rawBaseUrl: rawBaseUrl,
      rawWebSocketUrl: rawWebSocketUrl,
      normalizedBaseUrl: _normalizeBaseUrl(rawBaseUrl),
      normalizedWebSocketUrl: _normalizeWebSocketUrl(rawWebSocketUrl),
    );
  }

  final String? rawBaseUrl;
  final String? rawWebSocketUrl;
  final String? normalizedBaseUrl;
  final String? normalizedWebSocketUrl;

  _ConnectionImportEndpointFields toFields() {
    return _ConnectionImportEndpointFields(
      baseUrl:
          normalizedBaseUrl ??
          _normalizeBaseUrlFromWebSocketUrl(normalizedWebSocketUrl),
      webSocketUrl: normalizedWebSocketUrl,
      queryToken: firstQueryToken,
    );
  }

  String? get firstQueryToken {
    // Only trust base_url query credentials if the base URL itself normalized;
    // otherwise malformed or unsupported base URLs cannot smuggle token-only
    // imports. A normalized websocket URL remains a valid token source and is
    // checked second to preserve explicit base_url precedence.
    return _tokenFromEndpointQuery(
          normalizedBaseUrl == null ? null : rawBaseUrl,
        ) ??
        _tokenFromEndpointQuery(normalizedWebSocketUrl);
  }
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

String? _tokenFromEndpointQuery(String? url) {
  if (url == null) return null;
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasQuery) return null;
  return navivoxFirstStringFieldFromJson(
    navivoxFirstNonBlankQueryParameterValues(uri.queryParametersAll),
    _tokenFieldNames,
  );
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

String? _normalizeWebSocketUrl(String? raw) {
  final value = navivoxOptionalLiteralStringFromJson(raw);
  if (value == null) return null;

  final uri = Uri.tryParse(value);
  if (uri == null || !_isValidConnectionImportWebSocketUri(uri)) return null;
  return navivoxWebSocketUrlFromEndpointString(value);
}

bool _isValidConnectionImportWebSocketUri(Uri uri) {
  if (!uri.hasScheme || uri.host.isEmpty || !_hasValidExplicitPort(uri)) {
    return false;
  }
  final scheme = uri.scheme.toLowerCase();
  return scheme == 'ws' || scheme == 'wss';
}

String? _normalizeBaseUrlFromWebSocketUrl(String? normalizedWebSocketUrl) =>
    navivoxHttpBaseUrlFromEndpointString(normalizedWebSocketUrl);
