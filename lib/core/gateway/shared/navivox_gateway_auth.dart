import 'dart:convert';

import 'navivox_gateway_constants.dart';

/// Gateway HTTP authorization header name used by REST and stream setup.
const navivoxGatewayAuthorizationHeader = 'Authorization';

const _bearerPrefix = 'Bearer ';
const _bearerScheme = 'bearer';

/// Builds the gateway's bearer authorization header value from a raw token.
String navivoxGatewayBearerAuthorization(String token) {
  return '$_bearerPrefix${token.trim()}';
}

/// Replayable parse result for gateway Authorization header values.
class NavivoxGatewayBearerAuth {
  const NavivoxGatewayBearerAuth._(this.token);

  static NavivoxGatewayBearerAuth? tryParse(String value) {
    final auth = value.trim();
    final separator = auth.indexOf(' ');
    if (separator <= 0) return null;

    final scheme = auth.substring(0, separator).toLowerCase();
    if (scheme != _bearerScheme) return null;

    final token = auth.substring(separator + 1).trim();
    return token.isEmpty ? null : NavivoxGatewayBearerAuth._(token);
  }

  final String token;
}

/// Extracts a bearer token from gateway headers using case-insensitive names.
String? navivoxGatewayBearerToken(Map<String, String> headers) {
  final auth = headers.entries
      .where(
        (entry) =>
            entry.key.toLowerCase() ==
            navivoxGatewayAuthorizationHeader.toLowerCase(),
      )
      .map((entry) => NavivoxGatewayBearerAuth.tryParse(entry.value))
      .whereType<NavivoxGatewayBearerAuth>()
      .firstOrNull;
  return auth?.token;
}

/// Builds WebSocket subprotocols accepted by the gateway.
///
/// Browsers cannot set arbitrary WebSocket headers, so bearer auth is carried
/// as a gateway-specific subprotocol while retaining the base Navivox protocol.
List<String> navivoxGatewayWebSocketProtocols(Map<String, String> headers) {
  final protocols = <String>[navivoxWebSocketProtocol];
  final token = navivoxGatewayBearerToken(headers);
  if (token != null && token.isNotEmpty) {
    protocols.add(
      '$navivoxWebSocketTokenProtocolPrefix'
      '${base64Url.encode(utf8.encode(token)).replaceAll('=', '')}',
    );
  }
  return protocols;
}
