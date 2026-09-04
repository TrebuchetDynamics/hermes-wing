import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/client/platform/hermes_api_transport_io.dart';

void main() {
  test('rejects oversized response bodies before buffering', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      try {
        final chunk = List<int>.filled(1 << 20, 65);
        for (var index = 0; index < 65; index++) {
          request.response.add(chunk);
        }
        await request.response.close();
      } catch (_) {
        // The client is expected to close the response at the bound.
      }
    });

    try {
      await expectLater(
        defaultGet(Uri.parse('http://127.0.0.1:${server.port}/large'), {}),
        throwsA(isA<HttpException>()),
      );
    } finally {
      await server.close(force: true);
    }
  });

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
