import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import '../shared/navivox_gateway_auth.dart';
import '../shared/navivox_gateway_http.dart';

class NavivoxGatewaySocket {
  NavivoxGatewaySocket._(this._socket) {
    _socket.onmessage = ((web.MessageEvent event) {
      _events.add((event.data as JSString).toDart);
    }).toJS;
    _socket.onerror = ((web.Event event) {
      _events.addError(StateError('Gateway stream error'));
    }).toJS;
    _socket.onclose = ((web.CloseEvent event) {
      if (!_events.isClosed) unawaited(_events.close());
    }).toJS;
  }

  final web.WebSocket _socket;
  final StreamController<dynamic> _events = StreamController<dynamic>();

  Stream<dynamic> get events => _events.stream;

  void add(String message) => _socket.send(message.toJS);

  Future<void> close() async {
    _socket.close();
    if (!_events.isClosed) await _events.close();
  }
}

Future<String> defaultGet(Uri uri, Map<String, String> headers) async {
  final response = await web.window
      .fetch(
        uri.toString().toJS,
        web.RequestInit(headers: _headersToRecord(headers)),
      )
      .toDart;
  return _readResponse(response);
}

Future<String> defaultPost(
  Uri uri,
  Map<String, String> headers,
  String body,
) async {
  final response = await web.window
      .fetch(
        uri.toString().toJS,
        web.RequestInit(
          method: 'POST',
          headers: _headersToRecord(headers),
          body: body.toJS,
        ),
      )
      .toDart;
  return _readResponse(response);
}

Future<String> _readResponse(web.Response response) async {
  if (!response.ok) {
    throw StateError(navivoxGatewayHttpStatusMessage(response.status));
  }
  final jsText = await response.text().toDart;
  return jsText.toDart;
}

Future<NavivoxGatewaySocket> defaultConnectWebSocket(
  Uri uri,
  Map<String, String> headers,
) async {
  final socket = web.WebSocket(
    uri.toString(),
    navivoxGatewayWebSocketProtocols(
      headers,
    ).map((protocol) => protocol.toJS).toList().toJS,
  );
  final completer = Completer<NavivoxGatewaySocket>();

  socket.onopen = ((web.Event event) {
    if (!completer.isCompleted) {
      completer.complete(NavivoxGatewaySocket._(socket));
    }
  }).toJS;
  socket.onerror = ((web.Event event) {
    if (!completer.isCompleted) {
      completer.completeError(StateError('Navivox gateway WebSocket failed'));
    }
  }).toJS;
  socket.onclose = ((web.CloseEvent event) {
    if (!completer.isCompleted) {
      completer.completeError(StateError('Navivox gateway WebSocket closed'));
    }
  }).toJS;

  return completer.future;
}

JSObject _headersToRecord(Map<String, String> headers) {
  final record = JSObject();
  for (final entry in headers.entries) {
    record.setProperty(entry.key.toJS, entry.value.toJS);
  }
  return record;
}
