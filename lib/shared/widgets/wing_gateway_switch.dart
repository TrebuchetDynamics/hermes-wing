import 'package:flutter/widgets.dart';

import '../../core/hermes/channel/hermes_channel.dart';
import '../../l10n/app_localizations.dart';
import '../../features/hermes_chat/gateways/hermes_gateway_directory.dart';

/// Completes a screen-initiated switch without updating a disposed screen or
/// forwarding raw activation errors. Callers own their initial state resets.
Future<void> completeWingGatewaySwitch({
  required BuildContext context,
  required HermesGatewayDirectory directory,
  required HermesChannel channel,
  required String gatewayId,
  required ValueChanged<HermesConnectionFailureKind?> onFailure,
  required VoidCallback onFinished,
}) async {
  try {
    await directory.activateGateway(gatewayId);
    if (context.mounted &&
        channel.state.status == HermesConnectionStatus.error &&
        directory.activeContactId?.gatewayId != gatewayId) {
      onFailure(channel.state.connectionFailureKind);
    }
  } catch (_) {
    if (context.mounted) onFailure(channel.state.connectionFailureKind);
  } finally {
    if (context.mounted) onFinished();
  }
}

/// Only typed categories reach presentation, never raw server or transport text.
String wingGatewayConnectionFailureMessage(
  AppLocalizations strings,
  HermesConnectionFailureKind? kind,
) => switch (kind) {
  HermesConnectionFailureKind.authentication => strings.connectionCheckDenied,
  HermesConnectionFailureKind.invalidEndpoint =>
    strings.chatErrorConnectInvalidEndpointBody,
  HermesConnectionFailureKind.incompatibleResponse =>
    strings.chatErrorConnectIncompatibleBody,
  HermesConnectionFailureKind.network =>
    strings.chatErrorConnectUnreachableBody,
  HermesConnectionFailureKind.tls => strings.chatErrorConnectTlsBody,
  HermesConnectionFailureKind.timeout => strings.chatErrorConnectTimeoutBody,
  HermesConnectionFailureKind.unknown || null => strings.gatewayConnectFailed,
};
