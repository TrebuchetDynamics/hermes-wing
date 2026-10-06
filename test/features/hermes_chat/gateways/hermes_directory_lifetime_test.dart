import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_hermes_gateway_directory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'passive observation never starts directory, even after reattachment',
    () async {
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      final loader = FakeGatewaySummaryLoader({});
      final container = ProviderContainer(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(
            FakeHermesEndpointStore(),
          ),
          gatewayContactCacheProvider.overrideWithValue(
            FakeGatewayContactCache(),
          ),
          hermesGatewaySummaryLoaderProvider.overrideWithValue(loader),
        ],
      );
      addTearDown(container.dispose);
      final lifetime = container.read(hermesDirectoryLifetimeProvider);
      for (var i = 0; i < 3; i++) {
        void observe() {}
        lifetime.addListener(observe);
        expect(lifetime.current, isNull);
        lifetime.removeListener(observe);
        await container.pump();
      }
      expect(container.exists(hermesGatewayDirectoryProvider), isFalse);
      expect(loader.calls, isEmpty);
      expect(channel.connectCalls, isEmpty);

      final directory = container.read(hermesGatewayDirectoryProvider);
      expect(lifetime.current, same(directory));
      await container.pump();
      var invalidated = false;
      lifetime.addListener(() {
        if (lifetime.current == null) invalidated = true;
      });
      container.invalidate(hermesGatewayDirectoryProvider);
      expect(lifetime.current, isNull);
      expect(invalidated, isTrue);
      await container.pump();
      expect(lifetime.current, isNull);
      expect(loader.calls, isEmpty);
      expect(channel.connectCalls, isEmpty);
    },
  );
}
