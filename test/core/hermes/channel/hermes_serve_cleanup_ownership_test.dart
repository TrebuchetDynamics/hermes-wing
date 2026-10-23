import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/hermes_api.dart';
import 'package:wing/core/hermes/setup/secure_hermes_serve_recovery_store.dart';

import '../../../../integration_test/support/local_serve_read_fixture.dart';

class _HeldClearStore implements HermesServeRecoveryStore {
  final entered = Completer<void>();
  final release = Completer<void>();
  bool reject = false;

  @override
  Future<void> clear() async {
    if (!entered.isCompleted) {
      entered.complete();
      await release.future;
    }
    if (reject) throw StateError('synthetic storage failure');
  }

  @override
  Future<HermesServeRecoverySelection?> load() async => null;

  @override
  Future<void> save(HermesServeRecoverySelection selection) async {}
}

void main() {
  for (final replacement in ['disconnect', 'api', 'serve', 'abandon']) {
    test('serve cleanup wait cannot overtake $replacement ownership', () async {
      final original = LocalServeReadFixture();
      final newer = LocalServeReadFixture();
      addTearDown(original.close);
      await original.start();
      addTearDown(newer.close);
      await newer.start();
      final store = _HeldClearStore();
      final apiReads = <String>[];
      final channel = HermesApiChannel(
        serveRecoveryStore: store,
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            apiReads.add(uri.path);
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' =>
                '''{
                "object":"hermes.api_server.capabilities",
                "platform":"test", "model":"test",
                "auth":{"type":"bearer","required":true,"granted_scopes":[]},
                "features":{}, "endpoints":{}
              }''',
              '/api/sessions' => '{"sessions":[],"total":0}',
              _ => throw StateError('Unexpected API read'),
            };
          },
        ),
      );
      addTearDown(channel.dispose);
      var admitted = true;
      final first = channel.connectLocalServeReads(
        baseUrl: original.origin,
        credential: LocalServeReadFixture.token,
        canAccept: () => admitted,
      );
      await store.entered.future;
      if (replacement == 'abandon') admitted = false;
      final second = switch (replacement) {
        'abandon' => Future<void>.value(),
        'api' => channel.connect(
          baseUrl: newer.origin,
          apiKey: 'synthetic-replacement',
        ),
        'serve' => channel.connectLocalServeReads(
          baseUrl: newer.origin,
          credential: LocalServeReadFixture.token,
        ),
        _ => channel.disconnect(),
      };
      store.release.complete();
      await Future.wait([first, second]);

      expect(original.requests, isEmpty);
      if (replacement == 'disconnect' || replacement == 'abandon') {
        expect(channel.state.status, HermesConnectionStatus.disconnected);
        expect(newer.requests, isEmpty);
      } else {
        expect(channel.state.isConnected, true);
        expect(channel.state.connectedBaseUrl, newer.origin);
        expect(channel.state.isServeReadOnly, replacement == 'serve');
        expect(newer.requests, hasLength(replacement == 'serve' ? 3 : 0));
      }
      expect(
        apiReads,
        replacement == 'api'
            ? ['/health', '/v1/capabilities', '/api/sessions']
            : isEmpty,
      );
    });
  }

  test(
    'serve cleanup failure is sanitized and cannot enable credential Retry',
    () async {
      final fixture = LocalServeReadFixture();
      await fixture.start();
      addTearDown(fixture.close);
      final store = _HeldClearStore()..reject = true;
      final channel = HermesApiChannel(serveRecoveryStore: store);
      addTearDown(channel.dispose);
      final connecting = channel.connectLocalServeReads(
        baseUrl: fixture.origin,
        credential: LocalServeReadFixture.token,
      );
      await store.entered.future;
      store.release.complete();
      await connecting;
      expect(channel.state.status, HermesConnectionStatus.error);
      expect(channel.state.errorMessage, 'Local serve read connection failed.');
      expect(channel.state.connectedBaseUrl, isNull);
      await channel.retryLocalServeConversation();
      expect(fixture.requests, isEmpty);
    },
  );
}
