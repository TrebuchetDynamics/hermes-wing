import '../../../../../protocol/navivox_endpoint_uri.dart';
import '../../../../../protocol/navivox_json.dart';

import 'saved_session_web_socket_endpoint.dart';

/// Normalized non-secret gateway connection metadata shared by saved-session
/// persistence contracts.
class SessionConnectionMetadata {
  const SessionConnectionMetadata({
    required this.baseUrl,
    this.webSocketUrl,
    this.gatewayId,
  });

  factory SessionConnectionMetadata.fromStoredValues({
    required Object? baseUrl,
    Object? webSocketUrl,
    Object? gatewayId,
  }) {
    final normalizedBaseUrl = navivoxOptionalStringFromJson(baseUrl);
    if (normalizedBaseUrl == null) {
      throw ArgumentError.value(baseUrl, 'baseUrl', 'must not be blank');
    }

    return _fromNormalizedValues(
      baseUrl: normalizedBaseUrl,
      webSocketUrl: webSocketUrl,
      gatewayId: gatewayId,
    );
  }

  static SessionConnectionMetadata? maybeFromStoredValues({
    required Object? baseUrl,
    Object? webSocketUrl,
    Object? gatewayId,
  }) {
    final normalizedBaseUrl = navivoxOptionalStringFromJson(baseUrl);
    if (normalizedBaseUrl == null) return null;

    return _fromNormalizedValues(
      baseUrl: normalizedBaseUrl,
      webSocketUrl: webSocketUrl,
      gatewayId: gatewayId,
    );
  }

  static SessionConnectionMetadata _fromNormalizedValues({
    required String baseUrl,
    Object? webSocketUrl,
    Object? gatewayId,
  }) {
    return SessionConnectionMetadata(
      baseUrl: sanitizedSavedSessionBaseUrl(baseUrl),
      webSocketUrl: sanitizedSavedSessionWebSocketUrl(webSocketUrl),
      gatewayId: navivoxOptionalStringFromJson(gatewayId),
    );
  }

  final String baseUrl;
  final String? webSocketUrl;
  final String? gatewayId;
}

/// Returns only the reconnect-safe HTTP origin for endpoint-shaped base URLs.
///
/// Saved sessions are non-secret metadata. Connection/setup URLs can be pasted
/// with bootstrap token query params, so persistence strips path/query/fragment
/// whenever an endpoint origin can be derived. Non-endpoint legacy values keep
/// their existing trimmed compatibility behavior.
String sanitizedSavedSessionBaseUrl(String value) {
  return navivoxHttpBaseUrlFromEndpointString(value) ?? value;
}

/// Returns a websocket endpoint without non-durable bootstrap state.
///
/// The path is preserved because websocket deployments may serve the stream
/// outside the default Navivox path, but query params, fragments, and userinfo
/// are not durable metadata and may contain pairing credentials.
String? sanitizedSavedSessionWebSocketUrl(Object? value) {
  return durableSavedSessionWebSocketUrlFromMetadata(value);
}

/// Projects a websocket URI onto the durable saved-session identity fields.
Uri durableSavedSessionWebSocketUri(Uri uri) {
  final endpoint = SavedSessionWebSocketEndpoint.tryParse(uri.toString());
  if (endpoint == null) {
    throw FormatException(
      'Saved session websocket URI must use ws or wss and include a host',
      uri.toString(),
    );
  }
  return endpoint.uri;
}
