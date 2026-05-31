import 'dart:convert';

import '../../gateway/navivox_gateway_protocol.dart';

String navivoxGatewayNoActiveTurnMessage({required bool stop}) {
  return stop ? 'No active turn to stop.' : 'No active turn to cancel.';
}

String navivoxGatewayTurnControlSubmittedMessage({required bool stop}) {
  return stop
      ? 'Stop requested. Started side effects may still exist.'
      : 'Cancel requested. Started side effects may still exist.';
}

String navivoxGatewayTurnControlFrame({
  required bool stop,
  required String requestId,
  required String sessionId,
}) {
  final message = stop
      ? NavivoxGatewayMessage.stopTurn(
          requestId: requestId,
          sessionId: sessionId,
        )
      : NavivoxGatewayMessage.cancelTurn(
          requestId: requestId,
          sessionId: sessionId,
        );
  return jsonEncode(message.body);
}
