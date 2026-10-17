import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/hermes_api.dart';

import '../../../../integration_test/support/local_serve_read_fixture.dart';

void main() {
  for (final disconnectFirst in [false, true]) {
    test(
      'serve Retry never sends retired credentials to an API replacement; disconnect=$disconnectFirst',
      () async {
        final original = LocalServeReadFixture();
        final replacement = LocalServeReadFixture();
        await original.start();
        await replacement.start();
        addTearDown(original.close);
        addTearDown(replacement.close);
        final apiReads = <String>[];
        final channel = HermesApiChannel(
          clientBuilder: (config) => HermesApiClient(
            config: config,
            get: (uri, headers) async {
              apiReads.add(uri.path);
              return switch (uri.path) {
                '/health' => '{"status":"ok"}',
                '/v1/capabilities' =>
                  '''{
                  "object":"hermes.api_server.capabilities",
                  "platform":"test",
                  "model":"test",
                  "auth":{"type":"bearer","required":true,"granted_scopes":[]},
                  "features":{},
                  "endpoints":{}
                }''',
                '/api/sessions' => '{"sessions":[],"total":0}',
                _ => throw StateError('Unexpected API read'),
              };
            },
          ),
        );
        addTearDown(channel.dispose);
        await channel.connectLocalServeReads(
          baseUrl: original.origin,
          credential: LocalServeReadFixture.token,
        );
        expect(channel.state.isConnected, true);
        if (disconnectFirst) await channel.disconnect();
        await channel.connect(
          baseUrl: replacement.origin,
          apiKey: 'synthetic-api-owner',
        );
        expect(channel.state.isConnected, true);
        expect(channel.state.isServeReadOnly, false);
        final state = channel.state;
        final reads = List<String>.of(apiReads);

        await channel.retryLocalServeConversation();

        expect(replacement.requests, isEmpty);
        expect(identical(channel.state, state), true);
        expect(apiReads, reads);
        expect(original.requests, hasLength(3));
      },
    );
  }

  test('failed serve reads retain same-origin explicit Retry', () async {
    final fixture = LocalServeReadFixture()..unsupported = true;
    await fixture.start();
    addTearDown(fixture.close);
    final channel = HermesApiChannel();
    addTearDown(channel.dispose);
    await channel.connectLocalServeReads(
      baseUrl: fixture.origin,
      credential: LocalServeReadFixture.token,
    );
    expect(channel.state.isConnected, false);
    expect(fixture.requests, hasLength(1));
    fixture.unsupported = false;

    await channel.retryLocalServeConversation();

    expect(channel.state.isConnected, true);
    expect(channel.state.isServeReadOnly, true);
    expect(channel.state.connectedBaseUrl, fixture.origin);
    expect(channel.state.activeSessionId, 'default-session');
    expect(fixture.requests, hasLength(4));
    expect(fixture.requests, everyElement(startsWith('GET ')));
  });
}
