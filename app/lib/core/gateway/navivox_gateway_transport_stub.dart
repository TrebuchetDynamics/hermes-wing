class NavivoxGatewaySocket {
  Stream<dynamic> get events => const Stream<dynamic>.empty();

  void add(String message) {
    throw UnsupportedError('Navivox gateway WebSocket is not supported here.');
  }

  Future<void> close() async {}
}

Future<String> defaultGet(Uri uri, Map<String, String> headers) {
  throw UnsupportedError('Navivox gateway HTTP is not supported here.');
}

Future<NavivoxGatewaySocket> defaultConnectWebSocket(
  Uri uri,
  Map<String, String> headers,
) {
  throw UnsupportedError('Navivox gateway WebSocket is not supported here.');
}
