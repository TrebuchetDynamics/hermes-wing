import 'package:navivox/core/gateway/capabilities/navivox_gateway_capabilities.dart';

NavivoxCapabilityDocument reconnectCapabilityDocument(
  Map<String, Object?> durableReconnect,
) {
  return NavivoxCapabilityDocument.fromJson({
    'object': 'gormes.navivox.capabilities',
    'protocol_version': 'navivox.v1',
    'capabilities': <String>[],
    'durable_reconnect': durableReconnect,
  });
}
