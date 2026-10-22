import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'gateway_auth_models.dart';

/// RFC 8252 listener lives on this device (including Android), never the host.
/// Only the initial authorize URL is launched; HTTP API redirects fail closed.
class NativeGatewayAuth {
  NativeGatewayAuth({
    required Uri origin,
    required this.launchBrowser,
    bool allowLoopbackHttpForTests = false,
    this.timeout = const Duration(minutes: 5),
    this.requestTimeout = const Duration(seconds: 15),
  }) : origin = validateGatewayOrigin(
         origin,
         allowLoopbackHttpForTests: allowLoopbackHttpForTests,
       );

  final Uri origin;
  final Future<bool> Function(Uri) launchBrowser;
  final Duration timeout;
  final Duration requestTimeout;
  _Operation? _active;
  int _generation = 0;

  Future<void> cancel() async {
    _generation++;
    final operation = _active;
    _active = null;
    operation?.fail(const GatewayAuthException('cancelled'));
    await operation?.close();
  }

  Future<T> _run<T>(Future<T> Function(_Operation) task) async {
    final generation = ++_generation;
    final previous = _active;
    _active = null;
    previous?.fail(const GatewayAuthException('cancelled'));
    await previous?.close();
    if (generation != _generation) {
      throw const GatewayAuthException('cancelled');
    }
    // Concurrent starts are fenced by object identity, not only listener state.
    final op = _Operation();
    _active?.fail(const GatewayAuthException('cancelled'));
    _active = op;
    final result = Completer<T>();
    unawaited(
      op.failure.future.then((error) {
        if (!result.isCompleted) result.completeError(error);
      }),
    );
    final timer = Timer(
      timeout,
      () => op.fail(const GatewayAuthException('timeout')),
    );
    unawaited(() async {
      try {
        final value = await task(op);
        _check(op);
        if (!result.isCompleted) result.complete(value);
      } catch (error) {
        if (!result.isCompleted) {
          result.completeError(
            error is GatewayAuthException
                ? error
                : const GatewayAuthException('connection_failed'),
          );
        }
      }
    }());
    try {
      return await result.future;
    } finally {
      timer.cancel();
      if (identical(_active, op)) _active = null;
      await op.close();
    }
  }

  void _check(_Operation op) {
    if (!identical(_active, op) || op.closed || op.failure.isCompleted) {
      throw const GatewayAuthException('cancelled');
    }
  }

  Future<List<GatewayAuthProvider>> discoverProviders() => _run(_discover);

  Future<List<GatewayAuthProvider>> _discover(_Operation op) async {
    final status = await _json(op, '/api/status');
    final flows = status['auth_flows'];
    if (flows is! List || !flows.contains('native_pkce')) {
      throw const GatewayAuthException('native_pkce_unavailable');
    }
    final body = await _json(op, '/api/auth/providers');
    final rows = body['providers'];
    if (rows is! List || rows.isEmpty || rows.length > 64) {
      throw const GatewayAuthException('invalid_providers');
    }
    final names = <String>{};
    return List.unmodifiable(
      rows.map((row) {
        if (row is! Map || row['supports_password'] is! bool) {
          throw const GatewayAuthException('invalid_providers');
        }
        final name = boundedAuthString(row['name'], 128);
        if (!names.add(name)) {
          throw const GatewayAuthException('invalid_providers');
        }
        return GatewayAuthProvider(
          name: name,
          displayName: boundedAuthString(row['display_name'], 256),
          supportsPassword: row['supports_password'] as bool,
        );
      }),
    );
  }

  /// Empty provider leaves the gateway's browser chooser authoritative.
  Future<GatewayTokenSet> login({String? provider}) => _run((op) async {
    final providers = await _discover(op);
    if (provider != null && !providers.any((p) => p.name == provider)) {
      throw const GatewayAuthException('unknown_provider');
    }
    _check(op);
    final random = Random.secure();
    String secret() => base64Url
        .encode(List<int>.generate(32, (_) => random.nextInt(256)))
        .replaceAll('=', '');
    final verifier = secret();
    final state = secret();
    final challenge = base64Url
        .encode(sha256.convert(ascii.encode(verifier)).bytes)
        .replaceAll('=', '');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    op.server = server;
    if (op.closed) await server.close(force: true);
    _check(op);
    final code = Completer<String>();
    var consumed = false;
    server.listen(
      (request) async {
        final uri = request.uri;
        request.response.headers
          ..set(HttpHeaders.cacheControlHeader, 'no-store')
          ..set('Referrer-Policy', 'no-referrer')
          ..set(
            'Content-Security-Policy',
            "default-src 'none'; frame-ancestors 'none'",
          )
          ..contentType = ContentType.text;
        if (consumed || request.method != 'GET' || uri.path != '/callback') {
          request.response.statusCode = 404;
        } else {
          consumed = true;
          try {
            _check(op);
            if (uri.toString().length > 8192 ||
                uri.hasFragment ||
                uri.queryParametersAll['state']?.length != 1 ||
                uri.queryParameters['state'] != state) {
              throw const GatewayAuthException('invalid_callback');
            }
            if (uri.queryParameters.containsKey('error')) {
              throw const GatewayAuthException('authorization_rejected');
            }
            if (uri.queryParametersAll['code']?.length != 1) {
              throw const GatewayAuthException('invalid_callback');
            }
            final value = boundedAuthString(uri.queryParameters['code'], 2048);
            code.complete(value);
            request.response.write('Return to Hermes Wing.');
          } catch (error) {
            request.response.statusCode = 400;
            op.fail(
              error is GatewayAuthException
                  ? error
                  : const GatewayAuthException('invalid_callback'),
            );
          }
        }
        try {
          await request.response.close();
          if (consumed) await server.close(force: true);
        } catch (_) {
          op.fail(const GatewayAuthException('callback_failed'));
        }
      },
      onError: (Object _) =>
          op.fail(const GatewayAuthException('callback_failed')),
    );
    final callback = Uri(
      scheme: 'http',
      host: '127.0.0.1',
      port: server.port,
      path: '/callback',
    );
    final authorize = origin.replace(
      path: '/auth/native/authorize',
      queryParameters: {
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
        'redirect_uri': callback.toString(),
        'state': state,
        'provider': ?provider,
      },
    );
    // No bearer, refresh token or verifier ever enters a browser URL.
    if (!await op.wait(launchBrowser(authorize))) {
      throw const GatewayAuthException('browser_launch_failed');
    }
    _check(op);
    final value = await op.wait(code.future);
    _check(op);
    final body = await _json(
      op,
      '/auth/native/token',
      body: {'code': value, 'code_verifier': verifier},
    );
    final tokens = GatewayTokenSet.fromJson(origin, body);
    if (!providers.any((p) => p.name == tokens.provider) ||
        (provider != null && tokens.provider != provider)) {
      throw const GatewayAuthException('identity_mismatch');
    }
    return tokens;
  });

  /// Explicit rotation only. Never retries token POSTs or data-plane mutations.
  Future<GatewayTokenSet> refresh(GatewayTokenSet tokens) => _run((op) async {
    if (tokens.origin != origin || tokens.refreshToken.isEmpty) {
      throw const GatewayAuthException('invalid_refresh_scope');
    }
    final body = await _json(
      op,
      '/auth/native/refresh',
      body: {'refresh_token': tokens.refreshToken, 'provider': tokens.provider},
    );
    final refreshed = GatewayTokenSet.fromJson(origin, body);
    if (refreshed.provider != tokens.provider ||
        refreshed.userId != tokens.userId) {
      throw const GatewayAuthException('identity_mismatch');
    }
    return refreshed;
  });

  Future<Map<String, dynamic>> _json(
    _Operation op,
    String path, {
    Map<String, String>? body,
  }) async {
    _check(op);
    return (() async {
      final request = await op.client.openUrl(
        body == null ? 'GET' : 'POST',
        origin.replace(path: path),
      );
      _check(op);
      request.followRedirects = false;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      final response = await request.close();
      _check(op);
      if (response.statusCode != 200) {
        throw GatewayAuthException(
          response.statusCode >= 300 && response.statusCode < 400
              ? 'redirect_rejected'
              : response.statusCode == 401
              ? 'reauthentication_required'
              : 'request_failed',
        );
      }
      if (response.headers.contentType?.mimeType != 'application/json' ||
          response.contentLength > 65536) {
        throw const GatewayAuthException('invalid_response');
      }
      final bytes = <int>[];
      await for (final chunk in response) {
        _check(op);
        if (bytes.length + chunk.length > 65536) {
          throw const GatewayAuthException('response_too_large');
        }
        bytes.addAll(chunk);
      }
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        throw const GatewayAuthException('invalid_response');
      }
      return decoded;
    })().timeout(requestTimeout);
  }
}

class _Operation {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  final failure = Completer<GatewayAuthException>();
  HttpServer? server;
  bool closed = false;
  Future<T> wait<T>(Future<T> future) =>
      Future.any([future, failure.future.then<T>((error) => throw error)]);
  void fail(GatewayAuthException error) {
    if (!failure.isCompleted) failure.complete(error);
  }

  Future<void> close() async {
    closed = true;
    client.close(force: true);
    await server?.close(force: true);
  }
}
