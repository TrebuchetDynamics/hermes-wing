import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/client/platform/hermes_api_transport_io.dart';

void main() {
  test('POST sends Unicode JSON as UTF-8', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final received = Completer<String>();
    server.listen((request) async {
      received.complete(await utf8.decoder.bind(request).join());
      request.response.write('{}');
      await request.response.close();
    });
    const body = '{"session_id":"navi","input":"😀","message":"😀"}';

    try {
      await defaultPost(Uri.parse('http://127.0.0.1:${server.port}/runs'), {
        'Content-Type': 'application/json',
      }, body);
      expect(await received.future, body);
    } finally {
      await server.close(force: true);
    }
  });
}
