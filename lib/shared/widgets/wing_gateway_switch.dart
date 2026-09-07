import 'package:flutter/widgets.dart';

import '../../features/hermes_chat/gateways/hermes_gateway_directory.dart';

/// Completes a screen-initiated switch without updating a disposed screen or
/// forwarding raw activation errors. Callers own their initial state resets.
Future<void> completeWingGatewaySwitch({
  required BuildContext context,
  required HermesGatewayDirectory directory,
  required String gatewayId,
  required VoidCallback onFailure,
  required VoidCallback onFinished,
}) async {
  try {
    await directory.activateGateway(gatewayId);
  } catch (_) {
    if (context.mounted) onFailure();
  } finally {
    if (context.mounted) onFinished();
  }
}
