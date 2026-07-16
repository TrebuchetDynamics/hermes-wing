import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';

void main() {
  test('connects automatically when a Hermes endpoint was saved', () async {
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.disconnected,
    );
    final store = FakeHermesEndpointStore(
      initial: const HermesEndpointConfig(
        baseUrl: 'http://10.0.2.2:8642',
        apiKey: 'saved-key',
      ),
    );

    await hermesAutoConnect(channel, store);

    expect(channel.connectCalls, hasLength(1));
    expect(channel.connectCalls.single.baseUrl, 'http://10.0.2.2:8642');
    expect(channel.connectCalls.single.apiKey, 'saved-key');
  });

  test('does nothing when no Hermes endpoint was saved', () async {
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.disconnected,
    );
    final store = FakeHermesEndpointStore();

    await hermesAutoConnect(channel, store);

    expect(channel.connectCalls, isEmpty);
  });
}
