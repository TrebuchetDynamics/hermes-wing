import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/pairing/pairing_descriptor_endpoints.dart';

void main() {
  const descriptor = 'navivox://connect?...';

  test(
    'derives base origin from websocket endpoint when base_url is absent',
    () {
      final endpoints = PairingDescriptorEndpoints.fromWireFields(
        webSocketUrl:
            'wss://gateway.example:9443/v1/navivox/stream?token=setup',
        explicitBaseUrl: null,
        descriptor: descriptor,
      );

      expect(
        endpoints.webSocketUri.toString(),
        'wss://gateway.example:9443/v1/navivox/stream?token=setup',
      );
      expect(endpoints.baseUri.toString(), 'https://gateway.example:9443');
    },
  );

  test(
    'explicit base_url is normalized to HTTP origin without websocket path',
    () {
      final endpoints = PairingDescriptorEndpoints.fromWireFields(
        webSocketUrl: 'ws://127.0.0.1:8765/v1/navivox/stream',
        explicitBaseUrl: 'https://gateway.example/setup?handoff=1',
        descriptor: descriptor,
      );

      expect(
        endpoints.webSocketUri.toString(),
        'ws://127.0.0.1:8765/v1/navivox/stream',
      );
      expect(endpoints.baseUri.toString(), 'https://gateway.example');
    },
  );

  test(
    'rejects hidden state in endpoint fragments before origin stripping',
    () {
      expect(
        () => PairingDescriptorEndpoints.fromWireFields(
          webSocketUrl: 'ws://127.0.0.1:8765/v1/navivox/stream',
          explicitBaseUrl: 'https://gateway.example/setup#token',
          descriptor: descriptor,
        ),
        throwsFormatException,
      );

      expect(
        () => PairingDescriptorEndpoints.fromWireFields(
          webSocketUrl: 'wss://gateway.example/stream#token',
          explicitBaseUrl: null,
          descriptor: descriptor,
        ),
        throwsFormatException,
      );
    },
  );

  test('rejects base_url userinfo before origin stripping', () {
    expect(
      () => PairingDescriptorEndpoints.fromWireFields(
        webSocketUrl: 'ws://127.0.0.1:8765/v1/navivox/stream',
        explicitBaseUrl: 'https://operator:secret@gateway.example/setup',
        descriptor: descriptor,
      ),
      throwsFormatException,
    );
  });
}
