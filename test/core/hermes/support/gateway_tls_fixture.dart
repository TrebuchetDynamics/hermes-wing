import 'dart:async';
import 'dart:io';

/// Test-only TLS proxy: clients still perform normal certificate verification.
/// No badCertificateCallback and no production HTTP escape hatch.
class GatewayTlsFixture {
  late Directory directory;
  late HttpServer server;
  final _sockets = <WebSocket>[];
  Uri get origin => Uri.parse('https://localhost:${server.port}');

  Future<void> start(Uri upstream) async {
    directory = await Directory.systemTemp.createTemp('wing-gateway-tls-');
    final cert = '${directory.path}/cert.pem';
    final key = '${directory.path}/key.pem';
    final result = await Process.run('openssl', [
      'req',
      '-x509',
      '-newkey',
      'rsa:2048',
      '-nodes',
      '-keyout',
      key,
      '-out',
      cert,
      '-days',
      '1',
      '-subj',
      '/CN=localhost',
      '-addext',
      'subjectAltName=DNS:localhost',
    ]);
    if (result.exitCode != 0) {
      throw StateError('TLS fixture certificate generation failed');
    }
    final context = SecurityContext()
      ..useCertificateChain(cert)
      ..usePrivateKey(key);
    SecurityContext.defaultContext.setTrustedCertificates(cert);
    server = await HttpServer.bindSecure(
      InternetAddress.loopbackIPv4,
      0,
      context,
    );
    server.listen((request) async {
      final client = HttpClient()..findProxy = (_) => 'DIRECT';
      try {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final protocols = request.headers
              .value('sec-websocket-protocol')
              ?.split(',')
              .map((s) => s.trim())
              .toList();
          final back = await WebSocket.connect(
            upstream.replace(scheme: 'ws', path: request.uri.path).toString(),
            protocols: protocols,
            customClient: client,
          );
          final front = await WebSocketTransformer.upgrade(
            request,
            protocolSelector: (_) => back.protocol,
          );
          _sockets.addAll([front, back]);
          front.listen(back.add, onDone: () => back.close());
          back.listen(front.add, onDone: () => front.close());
          return;
        }
        final back = await client.openUrl(
          request.method,
          upstream.resolveUri(request.uri),
        );
        request.headers.forEach((name, values) {
          if (![
            'host',
            'transfer-encoding',
            'connection',
            'content-length',
          ].contains(name)) {
            back.headers.set(name, values);
          }
        });
        await back.addStream(request);
        final response = await back.close();
        request.response.statusCode = response.statusCode;
        response.headers.forEach((name, values) {
          if (![
            'transfer-encoding',
            'connection',
            'content-length',
          ].contains(name)) {
            request.response.headers.set(name, values);
          }
        });
        await request.response.addStream(response);
        await request.response.close();
      } catch (_) {
        try {
          request.response.statusCode = 502;
          await request.response.close();
        } catch (_) {
          /* Client already closed. */
        }
      }
    });
  }

  Future<void> close() async {
    for (final socket in _sockets) {
      await socket.close();
    }
    await server.close(force: true);
    await directory.delete(recursive: true);
  }
}
