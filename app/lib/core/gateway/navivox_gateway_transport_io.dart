import 'dart:convert';
import 'dart:io';

class NavivoxGatewaySocket {
  NavivoxGatewaySocket(this._socket);

  final WebSocket _socket;

  Stream<dynamic> get events => _socket;

  void add(String message) => _socket.add(message);

  Future<void> close() => _socket.close();
}

Future<String> defaultGet(Uri uri, Map<String, String> headers) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    headers.forEach(request.headers.set);
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Navivox gateway returned HTTP ${response.statusCode}',
        uri: uri,
      );
    }
    return body;
  } finally {
    client.close();
  }
}

Future<NavivoxGatewaySocket> defaultConnectWebSocket(
  Uri uri,
  Map<String, String> headers,
) async {
  final socket = await WebSocket.connect(uri.toString(), headers: headers);
  return NavivoxGatewaySocket(socket);
}
