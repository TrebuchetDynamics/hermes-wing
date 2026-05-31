import 'navivox_gateway_socket_contract.dart';

/// Shared HTTP GET transport contract used by the gateway client and tests.
typedef NavivoxGatewayGet =
    Future<String> Function(Uri uri, Map<String, String> headers);

/// Shared HTTP POST transport contract used by the gateway client and tests.
typedef NavivoxGatewayPost =
    Future<String> Function(Uri uri, Map<String, String> headers, String body);

/// Shared WebSocket transport contract decoupled from platform socket wrappers.
typedef NavivoxGatewayWebSocketConnector =
    Future<NavivoxGatewaySocketConnection> Function(
      Uri uri,
      Map<String, String> headers,
    );
