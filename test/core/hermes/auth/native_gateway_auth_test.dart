import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/auth/native_gateway_auth.dart';
import 'package:wing/core/hermes/auth/native_gateway_auth_stub.dart'
    as web_stub;

void main() {
  test('web stub never offers native loopback authentication', () async {
    final auth = web_stub.NativeGatewayAuth(
      origin: Uri.parse('https://example.invalid'),
      launchBrowser: (_) async => throw StateError('must not launch'),
    );
    await expectLater(auth.login(), throwsA(isA<GatewayAuthException>()));
    await expectLater(
      auth.discoverProviders(),
      throwsA(isA<GatewayAuthException>()),
    );
    await auth.cancel();
  });
  test('cancel before listener setup prevents browser launch', () async {
    final fixture = await GatewayFixture.start();
    addTearDown(fixture.close);
    var launches = 0;
    final auth = NativeGatewayAuth(
      origin: fixture.origin,
      allowLoopbackHttpForTests: true,
      launchBrowser: (_) async {
        launches++;
        return true;
      },
    );
    final checked = expectLater(
      auth.login(),
      throwsA(isA<GatewayAuthException>()),
    );
    await auth.cancel();
    await checked;
    expect(launches, 0);
  });
  test(
    'token redirects never follow changed origin or replay exchange',
    () async {
      final fixture = await GatewayFixture.start();
      final other = await GatewayFixture.start();
      addTearDown(fixture.close);
      addTearDown(other.close);
      final auth = NativeGatewayAuth(
        origin: fixture.origin,
        allowLoopbackHttpForTests: true,
        launchBrowser: (uri) async {
          await fixture.callback(uri);
          fixture.redirect = other.origin.toString();
          return true;
        },
      );
      await expectLater(
        auth.login(),
        throwsA(
          isA<GatewayAuthException>().having(
            (e) => e.reason,
            'reason',
            'redirect_rejected',
          ),
        ),
      );
      expect(other.requests, 0);
    },
  );

  test('callback rejects errors duplicate and oversized code', () async {
    final fixture = await GatewayFixture.start();
    addTearDown(fixture.close);
    for (final mode in ['duplicate', 'error', 'oversized', 'missing']) {
      final auth = NativeGatewayAuth(
        origin: fixture.origin,
        allowLoopbackHttpForTests: true,
        launchBrowser: (uri) async {
          final callback = Uri.parse(uri.queryParameters['redirect_uri']!);
          final noise = await fixture.browser.getUrl(
            callback.replace(path: '/noise'),
          );
          await (await noise.close()).drain<void>();
          final query =
              'state=${uri.queryParameters['state']}'
              '${mode == 'error' ? '&error=private-upstream-error' : ''}'
              '${mode == 'missing' || mode == 'error' ? '' : '&code=${mode == 'oversized' ? 'x' * 2049 : 'fixture-code'}'}'
              '${mode == 'duplicate' ? '&code=duplicate' : ''}';
          final response = await fixture.browser.getUrl(
            callback.replace(query: query),
          );
          await (await response.close()).drain<void>();
          return true;
        },
      );
      await expectLater(
        auth.login(),
        throwsA(
          isA<GatewayAuthException>().having(
            (e) => e.toString(),
            'redacted',
            isNot(contains('private-upstream')),
          ),
        ),
      );
    }
    expect(fixture.tokenPosts, 0);
  });
  test('rejects non-origin and insecure gateway input', () {
    for (final raw in [
      'http://example.invalid',
      'https://example.invalid/path',
      'https://user@example.invalid',
      'https://example.invalid?x=1',
      'https://example.invalid#secret',
      'http://localhost:1234',
    ]) {
      expect(
        () => NativeGatewayAuth(
          origin: Uri.parse(raw),
          launchBrowser: (_) async => true,
        ),
        throwsA(isA<GatewayAuthException>()),
      );
    }
  });

  test(
    'wrong state is consumed without exchanging or exposing details',
    () async {
      final fixture = await GatewayFixture.start();
      addTearDown(fixture.close);
      final auth = NativeGatewayAuth(
        origin: fixture.origin,
        allowLoopbackHttpForTests: true,
        launchBrowser: (uri) async {
          await fixture.callback(uri, state: 'wrong-private-state');
          return true;
        },
      );
      await expectLater(
        auth.login(),
        throwsA(
          isA<GatewayAuthException>().having(
            (e) => e.toString(),
            'sanitized',
            isNot(contains('private')),
          ),
        ),
      );
      expect(fixture.tokenPosts, 0);
    },
  );

  test('rejects API redirects without following a changed origin', () async {
    final fixture = await GatewayFixture.start();
    final other = await GatewayFixture.start();
    addTearDown(fixture.close);
    addTearDown(other.close);
    fixture.redirect = other.origin.toString();
    final auth = NativeGatewayAuth(
      origin: fixture.origin,
      allowLoopbackHttpForTests: true,
      launchBrowser: (_) async => true,
    );
    await expectLater(
      auth.discoverProviders(),
      throwsA(
        isA<GatewayAuthException>().having(
          (e) => e.reason,
          'reason',
          'redirect_rejected',
        ),
      ),
    );
    expect(other.requests, 0);
  });

  test(
    'cancel during browser launch closes callback and fences late completion',
    () async {
      final fixture = await GatewayFixture.start();
      addTearDown(fixture.close);
      final launched = Completer<Uri>();
      final release = Completer<bool>();
      final auth = NativeGatewayAuth(
        origin: fixture.origin,
        allowLoopbackHttpForTests: true,
        launchBrowser: (uri) {
          launched.complete(uri);
          return release.future;
        },
      );
      final pending = auth.login();
      final checked = expectLater(
        pending,
        throwsA(
          isA<GatewayAuthException>().having(
            (e) => e.reason,
            'reason',
            'cancelled',
          ),
        ),
      );
      final uri = await launched.future;
      await auth.cancel();
      release.complete(true);
      await checked;
      await expectLater(fixture.callback(uri), throwsA(isA<SocketException>()));
      expect(fixture.tokenPosts, 0);
    },
  );

  test('timeout and launch refusal fail closed', () async {
    final fixture = await GatewayFixture.start();
    addTearDown(fixture.close);
    for (final launch in [true, false]) {
      final auth = NativeGatewayAuth(
        origin: fixture.origin,
        allowLoopbackHttpForTests: true,
        timeout: const Duration(milliseconds: 100),
        launchBrowser: (_) async => launch,
      );
      await expectLater(
        auth.login(),
        throwsA(
          isA<GatewayAuthException>().having(
            (e) => e.reason,
            'reason',
            launch ? 'timeout' : 'browser_launch_failed',
          ),
        ),
      );
    }
  });

  test(
    'explicit refresh rotates once and rejects cross-origin scope',
    () async {
      final fixture = await GatewayFixture.start();
      addTearDown(fixture.close);
      final auth = NativeGatewayAuth(
        origin: fixture.origin,
        allowLoopbackHttpForTests: true,
        launchBrowser: (uri) async {
          await fixture.callback(uri);
          return true;
        },
      );
      final tokens = await auth.login();
      expect(fixture.refreshPosts, 0);
      final rotated = await auth.refresh(tokens);
      expect(rotated.accessToken, 'fixture-rotated');
      expect(fixture.refreshPosts, 1);
      final wrong = GatewayTokenSet.fromJson(
        Uri.parse('https://example.invalid'),
        fixture.tokenBody,
      );
      await expectLater(
        auth.refresh(wrong),
        throwsA(isA<GatewayAuthException>()),
      );
      expect(fixture.refreshPosts, 1);
      fixture.refreshStatus = 401;
      await expectLater(
        auth.refresh(rotated),
        throwsA(
          isA<GatewayAuthException>().having(
            (e) => e.reason,
            'reason',
            'reauthentication_required',
          ),
        ),
      );
      expect(fixture.refreshPosts, 2);
    },
  );

  test('strict token shape rejects coercion and oversized credentials', () {
    final valid = <String, Object>{
      'access_token': 'fixture-access',
      'refresh_token': '',
      'token_type': 'Bearer',
      'expires_at': 0,
      'provider': 'fixture',
      'user_id': 'fixture-user',
    };
    for (final changed in <Map<String, Object>>[
      {'access_token': 123},
      {'access_token': 'x' * 16385},
      {'expires_at': '2000000000'},
      {'expires_at': double.nan},
      {'expires_at': -1},
      {'token_type': 'Other'},
      {'provider': ''},
      {'user_id': 'bad\nidentity'},
    ]) {
      expect(
        () => GatewayTokenSet.fromJson(Uri.parse('https://example.invalid'), {
          ...valid,
          ...changed,
        }),
        throwsA(isA<GatewayAuthException>()),
      );
    }
  });
  test(
    'native login uses phone loopback state and S256 code exchange',
    () async {
      final fixture = await GatewayFixture.start();
      addTearDown(fixture.close);
      final auth = NativeGatewayAuth(
        origin: fixture.origin,
        allowLoopbackHttpForTests: true,
        launchBrowser: (uri) async {
          fixture.authorize = uri;
          final callback = Uri.parse(uri.queryParameters['redirect_uri']!);
          expect(callback.host, '127.0.0.1');
          expect(callback.port, isNot(0));
          expect(callback.path, '/callback');
          expect(uri.queryParameters['code_challenge_method'], 'S256');
          final response = await fixture.browser.getUrl(
            callback.replace(
              queryParameters: {
                'state': uri.queryParameters['state']!,
                'code': 'fixture-code',
              },
            ),
          );
          await (await response.close()).drain<void>();
          return true;
        },
      );
      addTearDown(auth.cancel);
      final tokens = await auth.login(provider: 'fixture');
      expect(tokens.origin, fixture.origin);
      expect(tokens.accessToken, 'fixture-access');
      expect(tokens.provider, 'fixture');
      expect(fixture.tokenPosts, 1);
      expect(fixture.verifier, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
      expect(
        base64Url
            .encode(sha256.convert(ascii.encode(fixture.verifier!)).bytes)
            .replaceAll('=', ''),
        fixture.authorize!.queryParameters['code_challenge'],
      );
      expect(tokens.toString(), isNot(contains('fixture-access')));
    },
  );
}

class GatewayFixture {
  GatewayFixture(this.server) {
    server.listen((request) async {
      requests++;
      request.response.headers.contentType = ContentType.json;
      if (redirect != null) {
        request.response.statusCode = 302;
        request.response.headers.set('location', redirect!);
        await request.response.close();
        return;
      }
      switch (request.uri.path) {
        case '/api/status':
          request.response.write(
            jsonEncode({
              'auth_flows': ['native_pkce'],
            }),
          );
        case '/api/auth/providers':
          request.response.write(
            jsonEncode({
              'providers': [
                {
                  'name': 'fixture',
                  'display_name': 'Fixture',
                  'supports_password': true,
                },
              ],
            }),
          );
        case '/auth/native/token':
          tokenPosts++;
          final body =
              jsonDecode(await utf8.decoder.bind(request).join()) as Map;
          expect(body['code'], 'fixture-code');
          verifier = body['code_verifier'] as String;
          request.response.write(jsonEncode(tokenBody));
        case '/auth/native/refresh':
          refreshPosts++;
          final body =
              jsonDecode(await utf8.decoder.bind(request).join()) as Map;
          expect(body['refresh_token'], 'fixture-refresh');
          expect(body['provider'], 'fixture');
          request.response.statusCode = refreshStatus;
          request.response.write(
            jsonEncode({...tokenBody, 'access_token': 'fixture-rotated'}),
          );
        default:
          request.response.statusCode = 404;
      }
      await request.response.close();
    });
  }

  final HttpServer server;
  final browser = HttpClient();
  Uri? authorize;
  String? verifier;
  int tokenPosts = 0;
  int refreshPosts = 0;
  int refreshStatus = 200;
  int requests = 0;
  String? redirect;
  Future<void> callback(Uri uri, {String? state}) async {
    final callback = Uri.parse(uri.queryParameters['redirect_uri']!);
    final response = await browser.getUrl(
      callback.replace(
        queryParameters: {
          'state': state ?? uri.queryParameters['state']!,
          'code': 'fixture-code',
        },
      ),
    );
    await (await response.close()).drain<void>();
  }

  Map<String, Object> get tokenBody => {
    'access_token': 'fixture-access',
    'refresh_token': 'fixture-refresh',
    'token_type': 'Bearer',
    'expires_at': 2000000000,
    'provider': 'fixture',
    'user_id': 'fixture-user',
  };
  Uri get origin => Uri.parse('http://127.0.0.1:${server.port}');
  static Future<GatewayFixture> start() async =>
      GatewayFixture(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));
  Future<void> close() async {
    browser.close(force: true);
    await server.close(force: true);
  }
}
