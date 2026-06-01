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

    test('preserves legacy host-port websocket metadata', () {
      expect(
        sanitizedSavedSessionWebSocketUrl(' gateway.local:8765/custom/stream '),
        'gateway.local:8765/custom/stream',
      );
    });

    test('preserves bracketed IPv6 host-port websocket metadata', () {
      expect(
        sanitizedSavedSessionWebSocketUrl(' [::1]:8765/custom/stream '),
        '[::1]:8765/custom/stream',
      );
    });
  });

  group('durableSavedSessionWebSocketUri', () {
    test('rejects non-websocket URI instead of returning unsafe original', () {
      expect(
        () => durableSavedSessionWebSocketUri(
          Uri.parse('https://gateway.example/stream?token=secret'),
        ),
        throwsFormatException,
      );
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

    test('trims direct parser input before URI classification', () {
      final endpoint = SavedSessionWebSocketEndpoint.tryParse(
        ' wss://gateway.example/navivox/stream ',
      );

      expect(endpoint?.durableUrl, 'wss://gateway.example/navivox/stream');
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

  group('SavedSessionWebSocketMetadata', () {
    test('classifies absent, durable, rejected, and legacy inputs', () {
      expect(
        SavedSessionWebSocketMetadata.fromStoredValue(' ').isAbsent,
        isTrue,
      );

      final durable = SavedSessionWebSocketMetadata.fromStoredValue(
        'wss://user:secret@gateway.example/stream?token=secret#frag',
      );
      expect(durable.durableUrl, 'wss://gateway.example/stream');
      expect(durable.isLegacyText, isFalse);
      expect(durable.isRejectedUrl, isFalse);

      final rejected = SavedSessionWebSocketMetadata.fromStoredValue(
        'https://gateway.example/stream?token=secret',
      );
      expect(rejected.durableUrl, isNull);
      expect(rejected.isRejectedUrl, isTrue);
      expect(rejected.isAbsent, isFalse);

      final legacy = SavedSessionWebSocketMetadata.fromStoredValue(
        ' gateway.local:8765/custom/stream ',
      );
      expect(legacy.durableUrl, 'gateway.local:8765/custom/stream');
      expect(legacy.isLegacyText, isTrue);
    });
  });
}
