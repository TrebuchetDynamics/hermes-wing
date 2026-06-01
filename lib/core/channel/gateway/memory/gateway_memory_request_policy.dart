import '../../../gateway/navivox_gateway_protocol.dart';
import '../../contracts/navivox_channel.dart';
import '../../contracts/navivox_memory_scope.dart';

/// Shared request policy for gateway-backed memory operations.
///
/// Memory overview/search/detail/action all resolve the same profile scope,
/// degrade when disconnected, and degrade on gateway failures. This helper keeps
/// that behavior aligned while each call supplies its typed degraded result.
Future<T> navivoxGatewayMemoryRequest<T>({
  required NavivoxGatewayClient? client,
  required NavivoxProfileContact? activeProfile,
  String? serverId,
  String? profileId,
  required String disconnectedReason,
  required String unavailableReason,
  required T Function(NavivoxMemoryScope scope, String reason) degraded,
  required Future<T> Function(
    NavivoxGatewayClient client,
    NavivoxMemoryScope scope,
  )
  request,
}) async {
  final scope = navivoxMemoryScopeFor(
    activeProfile: activeProfile,
    serverId: serverId,
    profileId: profileId,
  );
  if (client == null) {
    return degraded(scope, disconnectedReason);
  }
  try {
    return await request(client, scope);
  } catch (_) {
    return degraded(scope, unavailableReason);
  }
}
