import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/pairing/navivox_pairing_descriptor.dart';

void main() {
  test('rejects descriptor path or fragment instead of dropping hidden state', () {
    for (final value in [
      'navivox://connect/legacy?websocket_url=ws%3A%2F%2F127.0.0.1%3A8765%2Fstream',
      'navivox://connect?websocket_url=ws%3A%2F%2F127.0.0.1%3A8765%2Fstream#handoff',
    ]) {
      expect(
        () => NavivoxPairingDescriptor.parse(value),
        throwsFormatException,
      );
    }
  });

  test('rejects explicit base_url fragments instead of dropping them', () {
    expect(
      () => NavivoxPairingDescriptor.parse(
        'navivox://connect?'
        'websocket_url=ws%3A%2F%2F127.0.0.1%3A8765%2Fstream&'
        'base_url=https%3A%2F%2Fgateway.example%2Fsetup%23pairing-token',
      ),
      throwsFormatException,
    );
  });

  test(
    'preserves interleaved channel_ids alias order from descriptor query',
    () {
      final descriptor = NavivoxPairingDescriptor.parse(
        'navivox://connect?'
        'websocket_url=ws%3A%2F%2F127.0.0.1%3A8765%2Fv1%2Fnavivox%2Fstream&'
        'tokenRequired=true&'
        'restToken=setup-secret-token&'
        'channel_ids=telegram&'
        'channelIds=navivox%2Cdiscord&'
        'channel_ids=matrix',
      );

      expect(descriptor.channelIds, [
        'telegram',
        'navivox',
        'discord',
        'matrix',
      ]);
    },
  );

  test('uses first non-blank scalar alias in descriptor query order', () {
    final descriptor = NavivoxPairingDescriptor.parse(
      'navivox://connect?'
      'websocketUrl=ws%3A%2F%2F127.0.0.1%3A8765%2Fv1%2Fnavivox%2Fstream&'
      'websocket_url=ws%3A%2F%2Fshadow.example%2Fstream&'
      'tokenRequired=true&'
      'restToken=first-token&'
      'rest_token=shadow-token&'
      'serverId=first-server&'
      'server_id=shadow-server',
    );

    expect(descriptor.webSocketUri.host, '127.0.0.1');
    expect(descriptor.token, 'first-token');
    expect(descriptor.serverId, 'first-server');
  });
}
