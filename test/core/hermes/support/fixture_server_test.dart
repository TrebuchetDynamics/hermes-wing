import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';

import '../../../../integration_test/support/local_serve_read_fixture.dart';
import '../../../../integration_test/support/local_serve_chat_fixture.dart';
import 'fixture_server.dart';

Future<void> _serve(SendPort ready) async {
  final release = ReceivePort();
  late HttpServer server;
  try {
    server = await bindHermesFixtureServer();
  } on SocketException catch (error) {
    release.close();
    ready.send(
      'bind failed: ${error.osError?.errorCode}: ${error.osError?.message}',
    );
    return;
  }
  ready.send((server.port, release.sendPort));
  final closed = await release.first as SendPort;
  await server.close(force: true);
  release.close();
  closed.send(null);
}

class _HeldHistoryFixture extends LocalServeChatFixture {
  final entered = Completer<void>();

  @override
  Future<bool> handleRpc(WebSocket socket, Map<String, dynamic> frame) async {
    if (frame['method'] == 'session.history') entered.complete();
    return false;
  }
}

void main() {
  test(
    'fixture binds retain exclusive ownership across isolates and reuse',
    () async {
      HttpOverrides.global = null;
      final blocker = await bindHermesFixtureServer();
      addTearDown(() => blocker.close(force: true));
      blocker.listen((request) async {
        request.response.write('owned listener');
        await request.response.close();
      });
      final ports = <int>{blocker.port};
      final base = int.tryParse(
        Platform.environment['AUTOWORK_PORT_BASE'] ?? '',
      );
      for (var i = 0; i < 2; i++) {
        final ready = ReceivePort();
        addTearDown(ready.close);
        final isolate = await Isolate.spawn(_serve, ready.sendPort);
        addTearDown(() => isolate.kill(priority: Isolate.immediate));
        final result = await ready.first;
        expect(result, isA<(int, SendPort)>());
        final (port, release) = result as (int, SendPort);
        expect(ports.add(port), isTrue);
        if (base != null) expect(port, inInclusiveRange(base + 20, base + 79));
        addTearDown(() async {
          final closed = ReceivePort();
          release.send(closed.sendPort);
          await closed.first;
          closed.close();
        });
      }
      final process = await Process.start('dart', [
        'test/core/hermes/support/fixture_server_process.dart',
      ]);
      final stderr = process.stderr.transform(utf8.decoder).join();
      addTearDown(() async {
        await process.stdin.close();
        expect(await process.exitCode, 0, reason: await stderr);
      });
      final processPort = int.parse(
        await process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .first,
      );
      expect(ports.add(processPort), isTrue);
      if (base != null) {
        expect(processPort, inInclusiveRange(base + 20, base + 79));
      }
      // More than one complete reserved-range rotation, while other owners live.
      int? previous;
      for (var i = 0; i < 65; i++) {
        final fixture = LocalServeReadFixture();
        try {
          await fixture.start();
          expect(ports, isNot(contains(fixture.server.port)));
          if (base != null) {
            expect(fixture.server.port, isNot(previous));
            expect(fixture.server.port, inInclusiveRange(base + 20, base + 79));
          }
          previous = fixture.server.port;
        } finally {
          await fixture.close();
        }
      }
      final client = HttpClient();
      addTearDown(client.close);
      final response = await (await client.getUrl(
        Uri.parse('http://127.0.0.1:${blocker.port}'),
      )).close();
      expect(
        await response.transform(SystemEncoding().decoder).join(),
        'owned listener',
      );
    },
  );

  test(
    'chat cleanup releases held history without writing to closed sockets',
    () async {
      HttpOverrides.global = null;
      final fixture = _HeldHistoryFixture()..holdHistory = Completer<void>();
      addTearDown(fixture.close);
      await fixture.start();
      final port = fixture.server.port;
      fixture.tickets.add('synthetic-fixture-ticket');
      final socket = await WebSocket.connect(
        'ws://127.0.0.1:$port/api/ws',
        protocols: [
          'hermes-gateway-v1',
          'hermes-gateway-ticket.synthetic-fixture-ticket',
        ],
      );
      addTearDown(socket.close);
      final events = StreamIterator(socket);
      addTearDown(events.cancel);
      expect(await events.moveNext(), isTrue);
      socket.add(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'session.history',
          'params': <String, Object>{},
        }),
      );
      await fixture.entered.future;
      await fixture.close();
      expect(fixture.holdHistory!.isCompleted, isTrue);
      expect(await events.moveNext(), isFalse);
      final rebound = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      await rebound.close(force: true);
    },
  );

  test(
    'read fixture cleanup is safe before start and after failed allocation',
    () async {
      HttpOverrides.global = null;
      final fixture = LocalServeReadFixture();
      await fixture.close();
      await fixture.start();
      final port = fixture.server.port;
      await expectLater(fixture.start(), throwsStateError);
      expect(fixture.server.port, port);
      await fixture.close();
      await fixture.close();
      final rebound = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      await rebound.close(force: true);

      if (Platform.environment['AUTOWORK_PORT_BASE'] == null) return;
      final owned = <HttpServer>[];
      addTearDown(() async {
        for (final server in owned) {
          await server.close(force: true);
        }
      });
      // Only servers we successfully bind are ours to close; foreign listeners stay.
      try {
        while (true) {
          owned.add(await bindHermesFixtureServer());
        }
      } on StateError {
        // The bounded pool must fail rather than escaping to another port range.
      }
      final failed = LocalServeReadFixture();
      await expectLater(failed.start(), throwsStateError);
      await failed.close();
      await owned.removeLast().close(force: true);
      await failed.start();
      await failed.close();
    },
  );
}
