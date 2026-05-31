import '../../gateway/navivox_gateway_protocol.dart';

/// Shared gateway-client connection guard for channel request policies.
///
/// Feature-specific policies decide whether a capability is available and what
/// message to expose. This helper keeps the "no client means not connected"
/// branch consistent without broadening any public channel API.
NavivoxGatewayClient navivoxRequireConnectedGatewayClient({
  required NavivoxGatewayClient? client,
  required String message,
}) {
  if (client == null) {
    throw StateError(message);
  }
  return client;
}
