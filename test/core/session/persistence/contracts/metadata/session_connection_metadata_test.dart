import 'package:flutter_test/flutter_test.dart';

import 'package:navivox/core/session/persistence/contracts/metadata/connection/saved_session_web_socket_endpoint.dart';
import 'package:navivox/core/session/persistence/contracts/metadata/connection/session_connection_metadata.dart';

void main() {
  group('sanitizedSavedSessionWebSocketUrl', () {
    test('strips non-durable authority/query/fragment secret material', () {
      expect(
        sanitizedSavedSessionWebSocketUrl(
          'wss://pairing-token@gateway.example:9443/v1/navivox/stream?token=nvbx_pairing_token#handoff',
        ),
        'wss://gateway.example:9443/v1/navivox/stream',
      );
    });

    test('drops non-websocket URL-shaped values', () {
      expect(
        sanitizedSavedSessionWebSocketUrl('  https://gateway.example/stream  '),
        isNull,
      );
    });

    test('drops invalid websocket-shaped values', () {
      expect(sanitizedSavedSessionWebSocketUrl('wss:/missing-host'), isNull);
    });
  });

  group('SavedSessionWebSocketEndpoint', () {
    test('projects only durable websocket identity fields', () {
      final endpoint = SavedSessionWebSocketEndpoint.tryParse(
        'WSS://pairing-token@Gateway.Example:9443/v1/navivox/stream?token=nvbx_pairing_token#handoff',
      );

      expect(endpoint, isNotNull);
      expect(
        endpoint!.durableUrl,
        'wss://gateway.example:9443/v1/navivox/stream',
      );
    });

    test('rejects non-websocket and hostless values', () {
      expect(
        SavedSessionWebSocketEndpoint.tryParse('https://gateway.example'),
        isNull,
      );
      expect(
        SavedSessionWebSocketEndpoint.tryParse('wss:/missing-host'),
        isNull,
      );
    });
  });
}
