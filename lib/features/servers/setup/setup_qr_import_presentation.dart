import 'dart:convert';

import '../../../core/gateway/navivox_gateway_protocol.dart';

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

      final token = _firstNonEmpty([
        uri.queryParameters['token'],
        uri.queryParameters['pairing_token'],
        uri.queryParameters['pairingToken'],
        uri.queryParameters['auth_token'],
        uri.queryParameters['rest_token'],
        uri.queryParameters['restToken'],
      ]);
      final queryWebSocketUrl = _firstNonEmpty([
        uri.queryParameters['websocket_url'],
        uri.queryParameters['websocketUrl'],
        uri.queryParameters['ws_url'],
        uri.queryParameters['wsUrl'],
      ]);
      final queryBaseUrl =
          _normalizeBaseUrl(
            _firstNonEmpty([
              uri.queryParameters['base_url'],
              uri.queryParameters['baseUrl'],
              uri.queryParameters['gateway_url'],
              uri.queryParameters['url'],
            ]),
          ) ??
          _normalizeWebSocketBaseUrl(queryWebSocketUrl);

      if (queryBaseUrl != null || token != null) {
        return SetupQrImageImport(
          baseUrl: queryBaseUrl,
          token: token,
          webSocketUrl: _normalizeWebSocketUrl(queryWebSocketUrl),
          serverId: _firstNonEmpty([uri.queryParameters['server_id']]),
          profileId: _firstNonEmpty([uri.queryParameters['profile_id']]),
        );
      }
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        return SetupQrImageImport(baseUrl: _originFromUri(uri), token: token);
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

    final topLevelToken = _stringField(decoded, const [
      'token',
      'pairing_token',
      'pairingToken',
      'auth_token',
      'rest_token',
      'restToken',
    ]);
    final topLevelWebSocketUrl = _stringField(decoded, const [
      'websocket_url',
      'websocketUrl',
      'ws_url',
      'wsUrl',
    ]);
    final topLevelBaseUrl =
        _normalizeBaseUrl(
          _stringField(decoded, const [
            'base_url',
            'baseUrl',
            'gateway_url',
            'url',
          ]),
        ) ??
        _normalizeWebSocketBaseUrl(topLevelWebSocketUrl);
    if (topLevelBaseUrl != null || topLevelToken != null) {
      return SetupQrImageImport(
        baseUrl: topLevelBaseUrl,
        token: topLevelToken,
        webSocketUrl: _normalizeWebSocketUrl(topLevelWebSocketUrl),
        serverId: _stringField(decoded, const ['server_id', 'serverId']),
        profileId: _stringField(decoded, const ['profile_id', 'profileId']),
      );
    }

    final entries = decoded['entries'];
    if (entries is List) {
      for (final entry in entries) {
        if (entry is! Map) continue;
        final webSocketUrl = _stringField(entry, const [
          'websocket_url',
          'websocketUrl',
          'ws_url',
          'wsUrl',
        ]);
        final baseUrl =
            _normalizeBaseUrl(
              _stringField(entry, const [
                'base_url',
                'baseUrl',
                'gateway_url',
                'url',
              ]),
            ) ??
            _normalizeWebSocketBaseUrl(webSocketUrl);
        final token = _stringField(entry, const [
          'token',
          'pairing_token',
          'pairingToken',
          'auth_token',
          'rest_token',
          'restToken',
        ]);
        if (baseUrl != null || token != null) {
          return SetupQrImageImport(
            baseUrl: baseUrl,
            token: token,
            webSocketUrl: _normalizeWebSocketUrl(webSocketUrl),
            serverId: _stringField(entry, const ['server_id', 'serverId']),
            profileId: _stringField(entry, const ['profile_id', 'profileId']),
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

String? _stringField(Map<dynamic, dynamic> map, List<String> names) {
  for (final name in names) {
    final exact = _asNonEmptyString(map[name]);
    if (exact != null) return exact;
  }
  final normalizedNames = {for (final name in names) _normalizeKey(name)};
  for (final entry in map.entries) {
    if (!normalizedNames.contains(_normalizeKey('${entry.key}'))) continue;
    final value = _asNonEmptyString(entry.value);
    if (value != null) return value;
  }
  return null;
}

String _normalizeKey(String value) => value.toLowerCase().replaceAll('_', '');

String? _asNonEmptyString(Object? value) {
  if (value is! String) return null;
  final text = value.trim();
  return text.isEmpty ? null : text;
}

String? _firstNonEmpty(Iterable<String?> values) {
  for (final value in values) {
    final text = _asNonEmptyString(value);
    if (text != null) return text;
  }
  return null;
}

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
  return _originFromUri(uri);
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
  if (scheme == 'ws') return _originFromUri(uri.replace(scheme: 'http'));
  if (scheme == 'wss') return _originFromUri(uri.replace(scheme: 'https'));
  if (scheme == 'http' || scheme == 'https') return _originFromUri(uri);
  return null;
}

String _originFromUri(Uri uri) {
  final host = uri.host.contains(':') ? '[${uri.host}]' : uri.host;
  final port = uri.hasPort ? ':${uri.port}' : '';
  return '${uri.scheme}://$host$port';
}
