import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/client/hermes_web_read_client.dart';

void main() {
  test(
    'native qualification transport has no product import or export path',
    () {
      const internal = {
        'lib/core/hermes/client/hermes_web_read_client.dart',
        'lib/core/hermes/client/hermes_web_read_rpc.dart',
        'lib/core/hermes/client/hermes_web_lifecycle.dart',
        'lib/core/hermes/models/hermes_web_reads.dart',
      };
      for (final file
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where(
                (f) => f.path.endsWith('.dart') && !internal.contains(f.path),
              )) {
        expect(
          file.readAsStringSync(),
          isNot(contains('hermes_web_read')),
          reason: file.path,
        );
        expect(
          file.readAsStringSync(),
          isNot(contains('HermesWebReadClient')),
          reason: file.path,
        );
      }
    },
  );
  test(
    'ticket subprotocol ready permits only fixed ping and list reads',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final methods = <String>[];
      server.listen((request) async {
        expect(request.uri.query, isNot(contains('synthetic-owned-auth')));
        if (request.uri.path == '/api/auth/ws-ticket') {
          expect(request.method, 'POST');
          expect(
            request.headers.value('Authorization'),
            'Bearer synthetic-owned-auth',
          );
          request.response.write(
            '{"ticket":"single-use-fixture","ttl_seconds":30}',
          );
          await request.response.close();
        } else {
          expect(request.uri.path, '/api/ws');
          expect(request.headers.value('Authorization'), isNull);
          expect(
            request.headers.value('sec-websocket-protocol'),
            contains('hermes-gateway-ticket.single-use-fixture'),
          );
          final ws = await WebSocketTransformer.upgrade(
            request,
            protocolSelector: (protocols) => 'hermes-gateway-v1',
          );
          ws.add(
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
          ws.listen((frame) {
            final rpc = jsonDecode(frame as String) as Map<String, dynamic>;
            methods.add(rpc['method'] as String);
            expect((rpc['params'] as Map)['profile'], 'default');
            ws.add(
              jsonEncode({
                'jsonrpc': '2.0',
                'id': rpc['id'],
                'result': rpc['method'] == 'gateway.ping'
                    ? {'ok': true}
                    : {
                        'sessions': [
                          {'id': 'wing-qualification-session'},
                        ],
                      },
              }),
            );
          });
        }
      });
      final client = HermesWebReadClient.forQualification(
        origin: Uri.parse('http://127.0.0.1:${server.port}'),
        credential: 'synthetic-owned-auth',
        profile: 'default',
      );
      try {
        final connection = await client.connectReads();
        expect(connection.replayEpoch, 'synthetic-epoch');
        expect(await connection.ping(), isTrue);
        expect(await connection.sessionIds(limit: 10), [
          'wing-qualification-session',
        ]);
        expect(methods, ['gateway.ping', 'session.list']);
        expect(
          client.productAuthorization,
          HermesWebProductAuthorization.unsupportedAuthorization,
        );
      } finally {
        client.disconnect();
        await server.close(force: true);
      }
    },
  );
  test(
    'native REST reads retain receipt identity, nulls and pagination',
    () async {
      final receipt =
          jsonDecode(
                File(
                  'test/fixtures/hermes_web/receipt.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final inventory = receipt['rest_list_envelope'] as Map<String, dynamic>;
      final history = receipt['rest_history_envelope'] as Map<String, dynamic>;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final requests = <Uri>[];
      server.listen((request) async {
        requests.add(request.uri);
        expect(
          request.headers.value('Authorization'),
          'Bearer synthetic-owned-auth',
        );
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode(
            request.uri.path.endsWith('/messages') ? history : inventory,
          ),
        );
        await request.response.close();
      });
      final client = HermesWebReadClient.forQualification(
        origin: Uri.parse('http://127.0.0.1:${server.port}'),
        credential: 'synthetic-owned-auth',
        profile: 'default',
      );
      try {
        final page = await client.sessions(limit: 10);
        expect(page.total, 1);
        expect(page.limit, 10);
        expect(page.offset, 0);
        expect(page.sessions.single.id, 'wing-qualification-session');
        expect(page.sessions.single.model, isNull);
        expect(
          page.sessions.single.startedAt!.microsecondsSinceEpoch,
          (((inventory['sessions'] as List).single['started_at'] as num) *
                  1000000)
              .round(),
        );
        final messages = await client.history(
          'wing-qualification-session',
          limit: 10,
          order: 'oldest',
        );
        expect(messages.messages.map((m) => m.id), [1, 2]);
        expect(messages.messages.first.toolName, isNull);
        expect(messages.order, 'oldest');
        expect(messages.limit, 10);
        expect(messages.offset, 0);
        expect(messages.returned, 2);
        expect(
          requests.every((u) => u.queryParameters['profile'] == 'default'),
          isTrue,
        );
        expect(requests.join(), isNot(contains('synthetic-owned-auth')));
        expect(
          client.productAuthorization,
          HermesWebProductAuthorization.unsupportedAuthorization,
        );
      } finally {
        client.disconnect();
        await server.close(force: true);
      }
    },
  );
}
