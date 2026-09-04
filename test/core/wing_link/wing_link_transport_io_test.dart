@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/wing_link/wing_link_http.dart';
import 'package:wing/core/wing_link/wing_link_transport_io.dart';

void main() {
  test(
    'allows loopback HTTP but rejects remote cleartext before I/O',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) {
        request.response.write('ok');
        request.response.close();
      });
      final transport = WingLinkTransport();

      expect(
        await transport.get(
          Uri.parse('http://127.0.0.1:${server.port}/healthz'),
          const {},
        ),
        'ok',
      );
      await expectLater(
        transport.get(Uri.parse('http://192.0.2.1:8654/healthz'), const {}),
        throwsA(isA<HandshakeException>()),
      );
    },
  );

  test('does not follow redirects with credentials', () async {
    final target = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final authorizationHeaders = <String?>[];
    target.listen((request) {
      authorizationHeaders.add(
        request.headers.value(HttpHeaders.authorizationHeader),
      );
      request.response.write('ok');
      request.response.close();
    });
    final redirect = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    redirect.listen((request) {
      request.response.headers.set(
        HttpHeaders.locationHeader,
        'http://127.0.0.1:${target.port}/target',
      );
      request.response.statusCode = HttpStatus.temporaryRedirect;
      request.response.close();
    });
    addTearDown(() async {
      await redirect.close(force: true);
      await target.close(force: true);
    });

    final transport = WingLinkTransport();
    await expectLater(
      transport.get(
        Uri.parse('http://127.0.0.1:${redirect.port}/redirect'),
        const {'Authorization': 'Bearer redirect-secret'},
      ),
      throwsA(
        isA<WingLinkHttpException>().having(
          (error) => error.statusCode,
          'statusCode',
          HttpStatus.temporaryRedirect,
        ),
      ),
    );
    expect(authorizationHeaders, isEmpty);
  });

  test(
    'accepts one pinned TLS identity and rejects a changed identity',
    () async {
      final first = await _PinnedServer.start();
      final second = await _PinnedServer.start();
      addTearDown(first.close);
      addTearDown(second.close);

      final probe = HttpClient()..badCertificateCallback = (_, _, _) => true;
      final probeResponse = await (await probe.getUrl(first.uri)).close();
      expect(
        wingLinkCertificateFingerprint(probeResponse.certificate!),
        first.fingerprint,
      );
      await probeResponse.drain<void>();
      probe.close(force: true);

      final matching = WingLinkTransport(
        expectedHostFingerprint: first.fingerprint,
      );
      expect(await matching.get(first.uri, const {}), 'ok');

      SecurityContext.defaultContext.setTrustedCertificates(
        second.certificatePath,
      );
      final changed = WingLinkTransport(
        expectedHostFingerprint: first.fingerprint,
      );
      await expectLater(
        changed.get(second.uri, const {
          'Authorization': 'Bearer must-not-send',
        }),
        throwsA(isA<HandshakeException>()),
      );
      expect(second.authorizationHeaders, isEmpty);
    },
  );
}

class _PinnedServer {
  _PinnedServer(
    this.server,
    this.directory,
    this.certificatePath,
    this.fingerprint,
    this.authorizationHeaders,
  );

  final HttpServer server;
  final Directory directory;
  final String certificatePath;
  final String fingerprint;
  final List<String?> authorizationHeaders;

  Uri get uri => Uri.parse('https://localhost:${server.port}/healthz');

  static Future<_PinnedServer> start() async {
    final directory = await Directory.systemTemp.createTemp(
      'wing-link-transport-test-',
    );
    final certificate = File('${directory.path}/certificate.pem');
    final privateKey = File('${directory.path}/private-key.pem');
    final generated = await Process.run('openssl', [
      'req',
      '-x509',
      '-newkey',
      'rsa:2048',
      '-nodes',
      '-keyout',
      privateKey.path,
      '-out',
      certificate.path,
      '-days',
      '1',
      '-subj',
      '/CN=localhost',
      '-addext',
      'subjectAltName=DNS:localhost,IP:127.0.0.1',
    ]);
    if (generated.exitCode != 0) {
      await directory.delete(recursive: true);
      throw StateError('OpenSSL could not create the TLS test identity');
    }
    final publicKey = await Process.run('openssl', [
      'x509',
      '-in',
      certificate.path,
      '-pubkey',
      '-noout',
    ]);
    // Process.run cannot pipe directly, so perform the SPKI conversion with a
    // bounded shell-free second process.
    final process = await Process.start('openssl', [
      'pkey',
      '-pubin',
      '-outform',
      'DER',
    ]);
    process.stdin.write(publicKey.stdout as String);
    await process.stdin.close();
    final spkiBytes = await process.stdout.fold<List<int>>(
      <int>[],
      (bytes, chunk) => bytes..addAll(chunk),
    );
    if (await process.exitCode != 0 || spkiBytes.isEmpty) {
      await directory.delete(recursive: true);
      throw StateError('OpenSSL could not derive the TLS test SPKI');
    }
    final fingerprint =
        'sha256/${base64Url.encode(sha256.convert(spkiBytes).bytes).replaceAll('=', '')}';
    final context = SecurityContext()
      ..useCertificateChain(certificate.path)
      ..usePrivateKey(privateKey.path);
    final server = await HttpServer.bindSecure(
      InternetAddress.loopbackIPv4,
      0,
      context,
    );
    final authorizationHeaders = <String?>[];
    server.listen((request) {
      authorizationHeaders.add(
        request.headers.value(HttpHeaders.authorizationHeader),
      );
      request.response.write('ok');
      request.response.close();
    });
    return _PinnedServer(
      server,
      directory,
      certificate.path,
      fingerprint,
      authorizationHeaders,
    );
  }

  Future<void> close() async {
    await server.close(force: true);
    await directory.delete(recursive: true);
  }
}
