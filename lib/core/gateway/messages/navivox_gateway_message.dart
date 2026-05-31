import '../shared/navivox_gateway_json.dart';

/// Typed WebSocket message sent to the Navivox gateway.
class NavivoxGatewayMessage {
  const NavivoxGatewayMessage._(this.body);

  factory NavivoxGatewayMessage.ping({required String requestId}) {
    return NavivoxGatewayMessage._({'type': 'ping', 'request_id': requestId});
  }

  factory NavivoxGatewayMessage.startTurn({
    required String requestId,
    String? sessionId,
    required String text,
    Map<String, Object?> metadata = const {
      'client': 'navivox',
      'platform': 'flutter',
    },
  }) {
    return NavivoxGatewayMessage._({
      'type': 'start_turn',
      'request_id': requestId,
      if (navivoxGatewayHasText(sessionId)) 'session_id': sessionId,
      'text': text,
      'metadata': metadata,
    });
  }

  factory NavivoxGatewayMessage.cancelTurn({
    required String requestId,
    required String sessionId,
  }) {
    return NavivoxGatewayMessage._({
      'type': 'cancel_turn',
      'request_id': requestId,
      'session_id': sessionId,
    });
  }

  factory NavivoxGatewayMessage.stopTurn({
    required String requestId,
    required String sessionId,
  }) {
    return NavivoxGatewayMessage._({
      'type': 'stop_turn',
      'request_id': requestId,
      'session_id': sessionId,
    });
  }

  factory NavivoxGatewayMessage.subscribeSession({
    required String requestId,
    required String sessionId,
  }) {
    return NavivoxGatewayMessage._({
      'type': 'subscribe_session',
      'request_id': requestId,
      'session_id': sessionId,
    });
  }

  final Map<String, Object?> body;
}
