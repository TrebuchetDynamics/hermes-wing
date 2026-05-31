import '../../gateway/navivox_gateway_protocol.dart';
import '../contracts/navivox_channel.dart';
import 'gateway_capability_policy.dart';
import 'gateway_client_guard.dart';

/// Gateway config-admin request guard.
///
/// Config refresh/diff/validate/apply share the same connection and advertised
/// availability contract. Keeping the guard outside the channel keeps those
/// call sites aligned without exposing config-admin state mutation.
NavivoxGatewayClient navivoxRequireGatewayConfigAdminClient({
  required NavivoxGatewayClient? client,
  required bool available,
  required String action,
}) {
  final connectedClient = navivoxRequireConnectedGatewayClient(
    client: client,
    message: 'Connect to Gormes to $action.',
  );
  if (!available) {
    throw StateError('Connect to Gormes to $action.');
  }
  return connectedClient;
}

/// Best-effort load of the advertised config-admin schema and current values.
///
/// Initial connect and manual refresh both need the same typed schema/value
/// snapshot. Connect can opt into a degraded null result when the endpoint is
/// unavailable or fails; refresh keeps its existing fail-fast behavior through
/// [navivoxRefreshGatewayConfigAdminState].
Future<({Map<String, Object?> schema, Map<String, Object?> values})?>
navivoxLoadGatewayConfigAdminState({
  required NavivoxGatewayClient client,
  required NavivoxCapabilityDocument capabilities,
}) async {
  if (!navivoxConfigAdminSupported(capabilities)) return null;
  try {
    return await navivoxRefreshGatewayConfigAdminState(client: client);
  } catch (_) {
    return null;
  }
}

/// Loads the current config-admin schema/value snapshot.
Future<({Map<String, Object?> schema, Map<String, Object?> values})>
navivoxRefreshGatewayConfigAdminState({
  required NavivoxGatewayClient client,
}) async {
  final schema = await client.configAdminSchema();
  final values = await client.configAdminValues();
  return (schema: schema.toConfigSchema(), values: values.toConfigValues());
}

/// Applies a config-admin gateway response to channel state.
///
/// Validate, diff, and apply all surface the gateway snapshot through the same
/// `configDiff` field. Apply may also refresh persisted values when the server
/// accepted the change.
NavivoxChannelState navivoxStateWithConfigAdminResponse({
  required NavivoxChannelState state,
  required NavivoxConfigAdminResponse response,
  Map<String, Object?>? nextValues,
}) {
  return state.copyWith(
    configValues: nextValues,
    configDiff: response.snapshot,
  );
}

/// Best-effort value refresh after an applied config-admin mutation.
///
/// A failed refresh should not hide a successful apply response; callers keep
/// the response snapshot and leave current values unchanged.
Future<Map<String, Object?>?> navivoxConfigAdminValuesAfterAppliedResponse({
  required NavivoxGatewayClient client,
  required NavivoxConfigAdminResponse response,
}) async {
  if (!response.applied) return null;
  try {
    return (await client.configAdminValues()).toConfigValues();
  } catch (_) {
    return null;
  }
}
