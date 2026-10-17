import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/core/hermes/setup/secure_hermes_serve_recovery_store.dart';

class _CleanupBarrier implements HermesServeRecoveryStore {
  final entered = Completer<void>();
  final release = Completer<void>();

  @override
  Future<void> clear() async {
    if (!entered.isCompleted) {
      entered.complete();
      await release.future;
    }
  }

  @override
  Future<HermesServeRecoverySelection?> load() async => null;

  @override
  Future<void> save(HermesServeRecoverySelection selection) async {}
}

HermesApiChannel _channel(_CleanupBarrier store, List<Uri> reads) =>
    HermesApiChannel(
      serveRecoveryStore: store,
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, _) async {
          reads.add(uri);
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => '{"schema_version":1}',
            '/api/sessions' => '{"data":[]}',
            _ => throw StateError('Unexpected synthetic read'),
          };
        },
      ),
    );

void main() {
  test('superseded cleanup cannot start an old connection', () async {
    for (final localReads in [false, true]) {
      for (final successor in ['disconnect', 'replacement', 'dispose']) {
        final store = _CleanupBarrier();
        final reads = <Uri>[];
        final channel = _channel(store, reads);
        const old = 'https://old.example.invalid';
        const replacement = 'https://replacement.example.invalid';
        final pending = localReads
            ? channel.connectLocalServeReads(baseUrl: old, credential: '')
            : channel.connect(baseUrl: old);
        await store.entered.future;
        final next = switch (successor) {
          'replacement' => channel.connect(baseUrl: replacement),
          'disconnect' => channel.disconnect(),
          _ => Future<void>.sync(channel.dispose),
        };
        store.release.complete();
        await Future.wait([pending, next]);
        expect(
          reads.where((uri) => uri.host == 'old.example.invalid'),
          isEmpty,
        );
        if (successor != 'dispose') {
          expect(
            channel.state.status,
            successor == 'replacement'
                ? HermesConnectionStatus.connected
                : HermesConnectionStatus.disconnected,
          );
          expect(
            channel.state.connectedBaseUrl,
            successor == 'replacement' ? replacement : null,
          );
          channel.dispose();
        }
      }
    }
    // An older disconnect must reserve its cleanup before yielding too.
    final store = _CleanupBarrier();
    final reads = <Uri>[];
    final channel = _channel(store, reads);
    addTearDown(channel.dispose);
    final disconnected = channel.disconnect();
    final connected = channel.connect(
      baseUrl: 'https://latest.example.invalid',
    );
    await store.entered.future;
    store.release.complete();
    await Future.wait([disconnected, connected]);
    expect(channel.state.status, HermesConnectionStatus.connected);
    expect(channel.state.connectedBaseUrl, 'https://latest.example.invalid');
    expect(reads, isNotEmpty);
    expect(reads.every((uri) => uri.host == 'latest.example.invalid'), isTrue);
  });
}
