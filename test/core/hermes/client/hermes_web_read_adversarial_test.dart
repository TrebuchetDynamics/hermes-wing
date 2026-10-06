import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/client/hermes_web_read_client.dart';

const _auth = 'synthetic-owned-auth';
Matcher fails(HermesWebFailureKind kind) => throwsA(
  isA<HermesWebReadException>()
      .having((e) => e.kind, 'kind', kind)
      .having((e) => e.toString(), 'redacted', isNot(contains(_auth))),
);
HermesWebReadClient client(
  HttpServer server, {
  String profile = 'default',
  Duration timeout = const Duration(seconds: 2),
}) => HermesWebReadClient.forQualification(
  origin: Uri.parse('http://127.0.0.1:${server.port}'),
  credential: _auth,
  profile: profile,
  timeout: timeout,
);
Map<String, dynamic> historyEnvelope() {
  final receipt =
      jsonDecode(
            File('test/fixtures/hermes_web/receipt.json').readAsStringSync(),
          )
          as Map;
  return receipt['rest_history_envelope'] as Map<String, dynamic>;
}

void ready(WebSocket ws) => ws.add(
  jsonEncode({
    'jsonrpc': '2.0',
    'method': 'event',
    'params': {
      'type': 'gateway.ready',
      'payload': {
        'change_events': true,
        'heartbeat': true,
        'replay_epoch': 'synthetic-epoch',
        'skin': {},
      },
    },
  }),
);
Future<WebSocket> upgrade(HttpRequest request) => WebSocketTransformer.upgrade(
  request,
  protocolSelector: (_) => 'hermes-gateway-v1',
);
Future<void> ticket(HttpRequest request) async {
  request.response.write('{"ticket":"owned-single-use","ttl_seconds":30}');
  await request.response.close();
}

void main() {
  test('missing native storage envelope fails closed', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.write(
        jsonEncode({'sessions': [], 'total': 0, 'limit': 50, 'offset': 0}),
      );
      await request.response.close();
    });
    final read = client(server);
    try {
      await expectLater(read.sessions(), fails(HermesWebFailureKind.malformed));
    } finally {
      read.disconnect();
      await server.close(force: true);
    }
  });
  test(
    'ticket upgrade redirects are rejected without following the location',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var requests = 0;
      server.listen((request) async {
        requests++;
        if (request.uri.path.endsWith('ws-ticket')) {
          await ticket(request);
          return;
        }
        request.response.statusCode = 302;
        request.response.headers.set(
          'Location',
          'http://127.0.0.1:${server.port}/forbidden?token=$_auth',
        );
        await request.response.close();
      });
      final read = client(server);
      try {
        await expectLater(
          read.connectReads(),
          fails(HermesWebFailureKind.redirect),
        );
        expect(requests, 2);
      } finally {
        read.disconnect();
        await server.close(force: true);
      }
    },
  );
  test('pending REST reads have a fixed bound', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final allStarted = Completer<void>();
    var count = 0;
    server.listen((request) {
      if (++count == 8) allStarted.complete();
    });
    final read = client(server);
    try {
      final waiting = List.generate(
        8,
        (_) => expectLater(read.sessions(), fails(HermesWebFailureKind.stale)),
      );
      await allStarted.future;
      await expectLater(read.sessions(), fails(HermesWebFailureKind.busy));
      read.disconnect();
      await Future.wait(waiting);
    } finally {
      read.disconnect();
      await server.close(force: true);
    }
  });
  test(
    'corrupt profile storage cannot be mistaken for an empty inventory',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        request.response.write(
          jsonEncode({
            'sessions': [],
            'total': 0,
            'limit': 50,
            'offset': 0,
            'storage': {'default': 'corrupt'},
          }),
        );
        await request.response.close();
      });
      final read = client(server);
      try {
        await expectLater(
          read.sessions(),
          fails(HermesWebFailureKind.storageUnavailable),
        );
      } finally {
        read.disconnect();
        await server.close(force: true);
      }
    },
  );
  for (final status in {
    401: HermesWebFailureKind.authentication,
    403: HermesWebFailureKind.authentication,
    404: HermesWebFailureKind.notFound,
    302: HermesWebFailureKind.redirect,
    500: HermesWebFailureKind.network,
  }.entries) {
    test(
      'REST status ${status.key} fails closed and redacts body/location',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        var count = 0;
        server.listen((request) async {
          count++;
          request.response.statusCode = status.key;
          request.response.headers.set(
            'Location',
            'http://127.0.0.1:${server.port}/secret?token=$_auth',
          );
          request.response.write(_auth);
          await request.response.close();
        });
        final read = client(server);
        try {
          await expectLater(read.sessions(), fails(status.value));
          expect(count, 1);
        } finally {
          read.disconnect();
          await server.close(force: true);
        }
      },
    );
  }
  for (final mode in [
    'profile',
    'session',
    'message-session',
    'numeric-id',
    'time',
    'pagination',
    'json',
    'oversized',
    'chunked',
  ]) {
    test('REST rejects $mode without a partial page', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        final envelope = historyEnvelope();
        if (mode == 'profile') envelope['profile'] = 'other';
        if (mode == 'session') envelope['session_id'] = 'other';
        if (mode == 'message-session') {
          (envelope['messages'] as List).first['session_id'] = 'other';
        }
        if (mode == 'numeric-id') {
          (envelope['messages'] as List).first['id'] = '1';
        }
        if (mode == 'time') {
          (envelope['messages'] as List).first['timestamp'] = '1790830400';
        }
        if (mode == 'pagination') {
          (envelope['pagination'] as Map)['returned'] = 1;
        }
        if (mode == 'oversized') {
          request.response.contentLength = HermesWebReadClient.maximumBytes + 1;
        }
        try {
          request.response.write(
            mode == 'json'
                ? _auth
                : mode == 'oversized' || mode == 'chunked'
                ? 'x' * (HermesWebReadClient.maximumBytes + 1)
                : jsonEncode(envelope),
          );
          await request.response.close();
        } catch (_) {
          /* Expected peer rejection at the bound. */
        }
      });
      final read = client(server);
      try {
        await expectLater(
          read.history(
            'wing-qualification-session',
            limit: 10,
            order: 'oldest',
          ),
          fails(
            {'profile', 'session', 'message-session'}.contains(mode)
                ? HermesWebFailureKind.identity
                : {'oversized', 'chunked'}.contains(mode)
                ? HermesWebFailureKind.oversized
                : HermesWebFailureKind.malformed,
          ),
        );
      } finally {
        read.disconnect();
        await server.close(force: true);
      }
    });
  }
  test(
    'history completion from disconnected profile cannot attach to replacement',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final pending = Completer<HttpRequest>();
      server.listen(pending.complete);
      final old = client(server);
      final newer = client(server, profile: 'new-profile');
      final result = old.history(
        'wing-qualification-session',
        limit: 10,
        order: 'oldest',
      );
      final rejection = expectLater(result, fails(HermesWebFailureKind.stale));
      final request = await pending.future;
      old.disconnect();
      request.response.write(jsonEncode(historyEnvelope()));
      await request.response.close();
      await rejection;
      expect(
        newer.productAuthorization,
        HermesWebProductAuthorization.unsupportedAuthorization,
      );
      newer.disconnect();
      await server.close(force: true);
    },
  );

  for (final mode in [
    'wrong-id',
    'error',
    'timeout',
    'disconnect',
    'oversized',
    'binary',
    'malformed',
  ]) {
    test('RPC $mode is bounded, correlated and redacted', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        if (request.uri.path.endsWith('ws-ticket')) {
          await ticket(request);
          return;
        }
        final ws = await upgrade(request);
        ready(ws);
        ws.listen((frame) async {
          final rpc = jsonDecode(frame as String) as Map;
          if (mode == 'timeout') return;
          if (mode == 'disconnect') {
            await ws.close();
            return;
          }
          if (mode == 'oversized') {
            ws.add('x' * (HermesWebReadClient.maximumBytes + 1));
            return;
          }
          if (mode == 'binary') {
            ws.add([1, 2]);
            return;
          }
          if (mode == 'malformed') {
            ws.add(_auth);
            return;
          }
          ws.add(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': mode == 'wrong-id' ? (rpc['id'] as int) + 1 : rpc['id'],
              if (mode == 'error')
                'error': {
                  'code': 4064,
                  'message': _auth,
                  'data': {'credential': _auth},
                }
              else
                'result': {'ok': true},
            }),
          );
        });
      });
      final read = client(server);
      try {
        final connection = await read.connectReads();
        await expectLater(
          connection.ping(),
          fails(switch (mode) {
            'error' => HermesWebFailureKind.rpc,
            'timeout' => HermesWebFailureKind.timeout,
            'disconnect' => HermesWebFailureKind.disconnected,
            'oversized' => HermesWebFailureKind.oversized,
            _ => HermesWebFailureKind.malformed,
          }),
        );
      } finally {
        read.disconnect();
        await server.close(force: true);
      }
    });
  }
  for (final mode in ['not-ready', 'bad-epoch', 'protocol', 'ready-timeout']) {
    test('upgrade $mode cannot become read-ready', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        if (request.uri.path.endsWith('ws-ticket')) {
          await ticket(request);
          return;
        }
        final ws = await WebSocketTransformer.upgrade(
          request,
          protocolSelector: mode == 'protocol'
              ? null
              : (_) => 'hermes-gateway-v1',
        );
        if (mode == 'ready-timeout') return;
        if (mode == 'protocol') {
          ready(ws);
          return;
        }
        ws.add(
          jsonEncode({
            'jsonrpc': '2.0',
            'method': 'event',
            'params': {
              'type': mode == 'not-ready' ? 'other' : 'gateway.ready',
              'payload': {
                'change_events': true,
                'heartbeat': true,
                'replay_epoch': null,
              },
            },
          }),
        );
      });
      final read = client(server);
      try {
        await expectLater(
          read.connectReads(),
          fails(
            mode == 'ready-timeout'
                ? HermesWebFailureKind.timeout
                : mode == 'not-ready'
                ? HermesWebFailureKind.identity
                : HermesWebFailureKind.malformed,
          ),
        );
      } finally {
        read.disconnect();
        await server.close(force: true);
      }
    });
  }
  for (final stage in ['ticket', 'ready']) {
    test(
      'delayed $stage cannot attach to a newer connection generation',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        final started = Completer<void>();
        final release = Completer<void>();
        var tickets = 0;
        var sockets = 0;
        server.listen((request) async {
          if (request.uri.path.endsWith('ws-ticket')) {
            if (++tickets == 1 && stage == 'ticket') {
              started.complete();
              await release.future;
            }
            await ticket(request);
            return;
          }
          final ws = await upgrade(request);
          if (++sockets == 1 && stage == 'ready') {
            started.complete();
            await release.future;
          }
          ready(ws);
          ws.listen((frame) {
            final rpc = jsonDecode(frame as String) as Map;
            ws.add(
              jsonEncode({
                'jsonrpc': '2.0',
                'id': rpc['id'],
                'result': {'ok': true},
              }),
            );
          });
        });
        final read = client(server);
        try {
          final old = read.connectReads();
          final rejection = expectLater(old, fails(HermesWebFailureKind.stale));
          await started.future;
          final newer = await read.connectReads();
          release.complete();
          await rejection;
          expect(await newer.ping(), isTrue);
        } finally {
          if (!release.isCompleted) release.complete();
          read.disconnect();
          await server.close(force: true);
        }
      },
    );
  }
  test(
    'pending RPC requests have a fixed bound and disconnect clears them',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        if (request.uri.path.endsWith('ws-ticket')) {
          await ticket(request);
          return;
        }
        ready(await upgrade(request));
      });
      final read = client(server);
      try {
        final connection = await read.connectReads();
        final waiting = List.generate(
          8,
          (_) => expectLater(
            connection.ping(),
            fails(HermesWebFailureKind.disconnected),
          ),
        );
        await expectLater(connection.ping(), fails(HermesWebFailureKind.busy));
        read.disconnect();
        await Future.wait(waiting);
      } finally {
        read.disconnect();
        await server.close(force: true);
      }
    },
  );
  test('qualification cannot acquire remote or URL-carried credentials', () {
    for (final uri in [
      'https://example.test',
      'http://example.test',
      'http://user:$_auth@127.0.0.1',
      'http://127.0.0.1?token=$_auth',
    ]) {
      expect(
        () => HermesWebReadClient.forQualification(
          origin: Uri.parse(uri),
          credential: _auth,
          profile: 'default',
        ),
        failsSync(HermesWebFailureKind.identity),
      );
    }
  });
}

Matcher failsSync(HermesWebFailureKind kind) => throwsA(
  isA<HermesWebReadException>()
      .having((e) => e.kind, 'kind', kind)
      .having((e) => e.toString(), 'redacted', isNot(contains(_auth))),
);
