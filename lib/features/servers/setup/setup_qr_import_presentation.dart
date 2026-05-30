import 'dart:convert';

import '../../../core/protocol/navivox_endpoint_uri.dart';
import '../../../core/protocol/navivox_json.dart';
import '../../../core/protocol/navivox_pairing_descriptor.dart';

class SetupQrImportPresentation {
  const SetupQrImportPresentation();

  SetupQrImageImport? parsePayload(String payload) {
    final text = payload.trim();
    if (text.isEmpty) return null;

    final jsonResult = _parseQrJsonPayload(text);
    if (jsonResult != null && jsonResult.hasValues) return jsonResult;

    final uri = Uri.tryParse(text);
    if (uri != null && uri.hasScheme) {
      final coreResult = _parseCorePairingDescriptor(text, uri);
      if (coreResult != null && coreResult.hasValues) return coreResult;

      final query = uri.queryParameters;
      final token = navivoxFirstStringFieldFromJson(query, _tokenFieldNames);
      final queryWebSocketUrl = navivoxFirstStringFieldFromJson(
        query,
        _webSocketUrlFieldNames,
      );
      final queryBaseUrl =
          _normalizeBaseUrl(
            navivoxFirstStringFieldFromJson(query, _baseUrlFieldNames),
          ) ??
          _normalizeWebSocketBaseUrl(queryWebSocketUrl);

      if (queryBaseUrl != null || token != null) {
        return SetupQrImageImport(
          baseUrl: queryBaseUrl,
          token: token,
          webSocketUrl: _normalizeWebSocketUrl(queryWebSocketUrl),
          serverId: navivoxFirstStringFieldFromJson(query, _serverIdFieldNames),
          profileId: navivoxFirstStringFieldFromJson(
            query,
            _profileIdFieldNames,
          ),
        );
      }
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        return SetupQrImageImport(
          baseUrl: navivoxOriginFromUri(uri),
          token: token,
        );
      }
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

    final topLevelToken = navivoxFirstStringFieldFromJson(
      decoded,
      _tokenFieldNames,
    );
    final topLevelWebSocketUrl = navivoxFirstStringFieldFromJson(
      decoded,
      _webSocketUrlFieldNames,
    );
    final topLevelBaseUrl =
        _normalizeBaseUrl(
          navivoxFirstStringFieldFromJson(decoded, _baseUrlFieldNames),
        ) ??
        _normalizeWebSocketBaseUrl(topLevelWebSocketUrl);
    if (topLevelBaseUrl != null || topLevelToken != null) {
      return SetupQrImageImport(
        baseUrl: topLevelBaseUrl,
        token: topLevelToken,
        webSocketUrl: _normalizeWebSocketUrl(topLevelWebSocketUrl),
        serverId: navivoxFirstStringFieldFromJson(decoded, _serverIdFieldNames),
        profileId: navivoxFirstStringFieldFromJson(
          decoded,
          _profileIdFieldNames,
        ),
      );
    }

    final entries = decoded['entries'];
    if (entries is List) {
      for (final entry in entries) {
        if (entry is! Map) continue;
        final webSocketUrl = navivoxFirstStringFieldFromJson(
          entry,
          _webSocketUrlFieldNames,
        );
        final baseUrl =
            _normalizeBaseUrl(
              navivoxFirstStringFieldFromJson(entry, _baseUrlFieldNames),
            ) ??
            _normalizeWebSocketBaseUrl(webSocketUrl);
        final token = navivoxFirstStringFieldFromJson(entry, _tokenFieldNames);
        if (baseUrl != null || token != null) {
          return SetupQrImageImport(
            baseUrl: baseUrl,
            token: token,
            webSocketUrl: _normalizeWebSocketUrl(webSocketUrl),
            serverId: navivoxFirstStringFieldFromJson(
              entry,
              _serverIdFieldNames,
            ),
            profileId: navivoxFirstStringFieldFromJson(
              entry,
              _profileIdFieldNames,
            ),
          );
        }
      }
    }
    return null;
  }
}

enum PairingHandoffSource { manual, qrImage, sharedText, directAppOpen }

class SetupQrImageImport {
  const SetupQrImageImport({
    this.baseUrl,
    this.token,
    this.webSocketUrl,
    this.serverId,
    this.profileId,
    this.source = PairingHandoffSource.manual,
  });

  final String? baseUrl;
  final String? token;
  final String? webSocketUrl;
  final String? serverId;
  final String? profileId;
  final PairingHandoffSource source;

  bool get hasValues => baseUrl != null || token != null;

  SetupQrImageImport withSource(PairingHandoffSource source) {
    return SetupQrImageImport(
      baseUrl: baseUrl,
      token: token,
      webSocketUrl: webSocketUrl,
      serverId: serverId,
      profileId: profileId,
      source: source,
    );
  }
}

SetupQrImageImport? parseNavivoxQrPayload(String payload) =>
    const SetupQrImportPresentation().parsePayload(payload);

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

String? _asNonEmptyString(Object? value) =>
    navivoxOptionalLiteralStringFromJson(value);

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
  final lower = text.toLowerCase();
  const labels = [
    'pairing token',
    'pairing_token',
    'pairing-token',
    'auth token',
    'auth_token',
    'auth-token',
    'token',
  ];
  for (final label in labels) {
    for (final separator in const [':', '=']) {
      final needle = '$label$separator';
      final index = lower.indexOf(needle);
      if (index < 0) continue;
      final token = _readTokenAt(text, index + needle.length);
      if (token != null) return token;
    }
  }

  final navivoxIndex = lower.indexOf('nvbx_');
  return navivoxIndex < 0 ? null : _readTokenAt(text, navivoxIndex);
}

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

String? _normalizeBaseUrl(String? raw) {
  final value = _asNonEmptyString(raw);
  if (value == null) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return value;
  if (uri.scheme != 'http' && uri.scheme != 'https') return value;
  return navivoxOriginFromUri(uri);
}

String? _normalizeWebSocketUrl(String? raw) {
  final value = _asNonEmptyString(raw);
  if (value == null) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'ws' && scheme != 'wss') return null;
  return uri.toString();
}

String? _normalizeWebSocketBaseUrl(String? raw) {
  final value = _asNonEmptyString(raw);
  if (value == null) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
  final scheme = uri.scheme.toLowerCase();
  if (scheme == 'ws' ||
      scheme == 'wss' ||
      scheme == 'http' ||
      scheme == 'https') {
    return navivoxHttpBaseUrlFromEndpointUri(uri);
  }
  return null;
}
