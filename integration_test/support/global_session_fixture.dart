import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Test-only loopback response gate. Forwards the existing deterministic fixture
/// without inventing success responses; setup bypasses the recorded app plane.
class GlobalSessionFixture {
  GlobalSessionFixture._(this.backend, this.server);
  final Uri backend;
  final HttpServer server;
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
  final requests = <Map<String, Object?>>[];
  Completer<void>? held;
  Completer<void>? release;
  Completer<void>? settled;
  String get origin => 'http://127.0.0.1:${server.port}';

  static Future<GlobalSessionFixture> start(String origin) async {
    final uri = Uri.parse(origin);
    if (uri.scheme != 'http' || uri.host != '127.0.0.1') {
      throw StateError('Owned loopback fixture required');
    }
    final fixture = GlobalSessionFixture._(
      uri,
      await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
    );
    fixture.server.listen((request) => unawaited(fixture.forward(request)));
    return fixture;
  }

  bool createGate = false;
  bool failGate = false;

  void hold({bool create = false, bool fail = false}) {
    createGate = create;
    failGate = fail;
    if (release != null) throw StateError('Only one response gate permitted');
    held = Completer<void>();
    release = Completer<void>();
    settled = Completer<void>();
  }

  Future<void> forward(HttpRequest request) async {
    final done = settled;
    final gate =
        (createGate
            ? request.method == 'POST' && request.uri.path == '/api/sessions'
            : request.uri.path.endsWith('/synthetic-native-panel/messages'))
        ? release
        : null;
    try {
      if (requests.length >= 512) throw StateError('Receipt bound exceeded');
      requests.add({
        'method': request.method,
        'path': request.uri.path,
        'query': request.uri.queryParameters,
      });
      final upstream = await client.openUrl(
        request.method,
        backend.resolve(request.uri.toString()),
      );
      // Long keyboard phases outlive Node's keep-alive timeout. The gate's
      // upstream sockets are not the production transport under qualification.
      upstream.persistentConnection = false;
      await upstream.addStream(request);
      final response = await upstream.close();
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
        if (bytes.length > 1024 * 1024) {
          throw StateError('Response bound exceeded');
        }
      }
      if (gate != null) {
        held!.complete();
        await gate.future.timeout(const Duration(seconds: 60));
      }
      request.response.statusCode = gate != null && failGate
          ? HttpStatus.serviceUnavailable
          : response.statusCode;
      request.response.headers.contentType = ContentType.json;
      request.response.add(
        gate != null && failGate
            ? utf8.encode('{"error":{"message":"synthetic read failure"}}')
            : bytes,
      );
      await request.response.close();
    } catch (error, stack) {
      if (gate != null && !held!.isCompleted) held!.completeError(error, stack);
      request.response.statusCode = HttpStatus.badGateway;
      await request.response.close();
      if (gate != null && !done!.isCompleted) done.completeError(error, stack);
      rethrow;
    } finally {
      if (gate != null && !done!.isCompleted) done.complete();
    }
  }

  Future<void> settle() async {
    release!.complete();
    await settled!.future;
    release = null;
  }

  Future<Map<String, dynamic>> setup(
    String method,
    String path, [
    Map<String, Object?>? body,
  ]) async {
    final request = await client.openUrl(method, backend.resolve(path));
    request.persistentConnection = false;
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Fixture setup failed: ${response.statusCode}');
    }
    return jsonDecode(await utf8.decoder.bind(response).join())
        as Map<String, dynamic>;
  }

  Future<void> dispose() async {
    if (release != null && !release!.isCompleted) release!.complete();
    client.close(force: true);
    await server.close(force: true);
  }
}
