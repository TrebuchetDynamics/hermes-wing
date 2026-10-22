import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import '../../../../integration_test/support/local_serve_chat_fixture.dart';
import '../../../../integration_test/support/local_serve_read_fixture.dart';
import '../support/gateway_tls_fixture.dart';

void main() {
  test(
    'native Android gateway uses verified TLS, WSS tickets and exact profile without replay',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final upstream = LocalServeChatFixture();
      await upstream.start();
      final tls = GatewayTlsFixture();
      await tls.start(Uri.parse(upstream.origin));
      final channel = HermesApiChannel();
      var checkpoints = 0;
      try {
        await channel.connectRemoteGateway(
          baseUrl: tls.origin.toString(),
          accessToken: LocalServeReadFixture.token,
          profile: 'demo',
          canAccept: () => true,
          onAcquire: (_) {},
          persistRecovery: (_) async {
            checkpoints++;
          },
        );
        expect(channel.state.isConnected, isTrue);
        expect(channel.state.selectedProfileId, 'demo');
        await channel.enableLocalServeChat();
        expect(channel.state.serveChat?.canSubmit, isTrue);
        expect(upstream.minted, 1);
        expect((upstream.rpc.firstWhere((r) => r['method'] == 'session.resume')['params'] as Map)['profile'], 'demo');
        expect(upstream.count('prompt.submit'), 0);
        await channel.sendText('synthetic deliberate test');
        expect(upstream.count('prompt.submit'), 1);
        expect(checkpoints, greaterThanOrEqualTo(2));
        await channel.disconnect();
        expect(upstream.count('prompt.submit'), 1);
      } finally {
        channel.dispose();
        await tls.close();
        await upstream.close();
      }
    },
  );
}
