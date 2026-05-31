import 'dart:convert';
import 'dart:io';

import '../shared/navivox_gateway_http.dart';

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
    return _readResponse(await request.close(), uri);
  } finally {
    client.close();
  }
}

Future<String> defaultPost(
  Uri uri,
  Map<String, String> headers,
  String body,
) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(uri);
    headers.forEach(request.headers.set);
    request.add(utf8.encode(body));
    return _readResponse(await request.close(), uri);
  } finally {
    client.close();
  }
}

Future<String> _readResponse(HttpClientResponse response, Uri uri) async {
  final body = await utf8.decoder.bind(response).join();
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException(
      navivoxGatewayHttpStatusMessage(response.statusCode),
      uri: uri,
    );
  }
  return body;
}

Future<NavivoxGatewaySocket> defaultConnectWebSocket(
  Uri uri,
  Map<String, String> headers,
) async {
  final socket = await WebSocket.connect(uri.toString(), headers: headers);
  return NavivoxGatewaySocket(socket);
}
