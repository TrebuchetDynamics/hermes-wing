import '../../gateway/navivox_gateway_protocol.dart';
import '../../protocol/navivox_json.dart';

class ReconnectReadiness {
  const ReconnectReadiness({
    required this.kind,
    required this.message,
    this.recoveryMessage,
  });

  factory ReconnectReadiness.fromCapabilities(
    NavivoxCapabilityDocument? capabilities,
  ) {
    if (capabilities == null) {
      return const ReconnectReadiness(
        kind: ReconnectReadinessKind.unknown,
        message: 'Checking reconnect support…',
      );
    }
    final durable = capabilities.durableReconnect;
    return switch (durable.readinessKind) {
      ReconnectReadinessKind.unsupported => const ReconnectReadiness(
        kind: ReconnectReadinessKind.unsupported,
        message: 'Reconnect cannot be saved for this gateway yet.',
        recoveryMessage:
            'Connected for this app session. Pair again after restart if needed.',
      ),
      ReconnectReadinessKind.blocked => ReconnectReadiness(
        kind: ReconnectReadinessKind.blocked,
        message: 'Reconnect cannot be saved on this connection.',
        recoveryMessage: navivoxOptionalStringFromJson(durable.blockedReason),
      ),
      ReconnectReadinessKind.available => const ReconnectReadiness(
        kind: ReconnectReadinessKind.available,
        message: 'Reconnect support is available but not saved yet.',
      ),
      ReconnectReadinessKind.unknown => const ReconnectReadiness(
        kind: ReconnectReadinessKind.unknown,
        message: 'Checking reconnect support…',
      ),
      ReconnectReadinessKind.saved => const ReconnectReadiness(
        kind: ReconnectReadinessKind.saved,
        message: 'Reconnect saved for this gateway.',
      ),
    };
  }

  final ReconnectReadinessKind kind;
  final String message;
  final String? recoveryMessage;
}
