import 'package:flutter_test/flutter_test.dart';

import 'package:navivox/core/session/persistence/contracts/metadata/connection/saved_session_base_url.dart';
import 'package:navivox/core/session/persistence/contracts/metadata/connection/saved_session_metadata_projection.dart';
import 'package:navivox/core/session/persistence/contracts/metadata/connection/saved_session_metadata_value_projection.dart';
import 'package:navivox/core/session/persistence/contracts/metadata/connection/saved_session_web_socket_endpoint.dart';
import 'package:navivox/core/session/persistence/contracts/metadata/connection/session_connection_metadata.dart';

void main() {
  group('SavedSessionMetadataProjection', () {
    test('rejects empty durable and legacy states as invalid projections', () {
      expect(
        () => SavedSessionMetadataProjection.durable(''),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => SavedSessionMetadataProjection.legacy(''),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('projectSavedSessionMetadataValue', () {
    test('prefers durable projection before unsafe-shape rejection', () {
      final projection = projectSavedSessionMetadataValue(
        text: 'https://gateway.example/setup?pairing_token=secret',
        durableValueFromText: (_) => 'https://gateway.example',
        isUnsafeUriShape: (_) => true,
      );

      expect(projection.durableValue, 'https://gateway.example');
      expect(projection.isRejectedUrl, isFalse);
      expect(projection.isLegacyText, isFalse);
    });

    test('rejects unsafe non-durable text before legacy compatibility', () {
      final projection = projectSavedSessionMetadataValue(
        text: 'gateway.example:8765/setup?pairing_token=secret',
        durableValueFromText: (_) => null,
        isUnsafeUriShape: (_) => true,
      );

      expect(projection.durableValue, isNull);
      expect(projection.isRejectedUrl, isTrue);
      expect(projection.isLegacyText, isFalse);
    });

    test('preserves non-durable safe text as legacy compatibility', () {
      final projection = projectSavedSessionMetadataValue(
        text: 'gateway.example:8765/setup',
        durableValueFromText: (_) => null,
        isUnsafeUriShape: (_) => false,
      );

      expect(projection.durableValue, 'gateway.example:8765/setup');
      expect(projection.isLegacyText, isTrue);
      expect(projection.isRejectedUrl, isFalse);
    });
  });

  group('sanitizedSavedSessionBaseUrl', () {
    test('strips setup path and bootstrap-only URL state', () {
      expect(
        sanitizedSavedSessionBaseUrl(
          ' https://gateway.example:9443/setup?pairing_token=secret#handoff ',
        ),
        'https://gateway.example:9443',
      );
    });

    test('preserves non-url legacy base URL metadata', () {
      expect(
        sanitizedSavedSessionBaseUrl(' gateway.local:8765/custom/setup '),
        'gateway.local:8765/custom/setup',
      );
    });

    test('rejects legacy-shaped base metadata with bootstrap state', () {
      expect(
        sanitizedSavedSessionBaseUrl(
          ' gateway.local:8765/custom/setup?pairing_token=secret#handoff ',
        ),
        isNull,
      );
    });

    test(
      'rejects malformed endpoint URLs instead of throwing or leaking state',
      () {
        expect(
          sanitizedSavedSessionBaseUrl(
            'https://gateway.example:bad/setup?pairing_token=secret#handoff',
          ),
          isNull,
        );
        expect(
          SessionConnectionMetadata.maybeFromStoredValues(
            baseUrl:
                'https://gateway.example:bad/setup?pairing_token=secret#handoff',
          ),
          isNull,
        );
      },
    );

    test('rejects explicit non-endpoint URI shapes as unsafe metadata', () {
      expect(sanitizedSavedSessionBaseUrl('mailto:pairing-token'), isNull);
      expect(
        sanitizedSavedSessionBaseUrl(
          'ftp://gateway.example/setup?token=secret',
        ),
        isNull,
      );
    });
  });

  group('SavedSessionBaseUrlMetadata', () {
    test('classifies absent, durable, rejected, and legacy inputs', () {
      expect(SavedSessionBaseUrlMetadata.fromStoredValue(' ').isAbsent, isTrue);

      final durable = SavedSessionBaseUrlMetadata.fromStoredValue(
        'https://gateway.example/setup?pairing_token=secret#handoff',
      );
      expect(durable.durableBaseUrl, 'https://gateway.example');
      expect(durable.isLegacyText, isFalse);
      expect(durable.isRejectedUrl, isFalse);

      final rejected = SavedSessionBaseUrlMetadata.fromStoredValue(
        'https://gateway.example:bad/setup?pairing_token=secret#handoff',
      );
      expect(rejected.durableBaseUrl, isNull);
      expect(rejected.isRejectedUrl, isTrue);
      expect(rejected.isAbsent, isFalse);

      final legacy = SavedSessionBaseUrlMetadata.fromStoredValue(
        ' gateway.local:8765/setup ',
      );
      expect(legacy.durableBaseUrl, 'gateway.local:8765/setup');
      expect(legacy.isLegacyText, isTrue);
    });
  });

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

    test('drops websocket URLs with malformed ports instead of throwing', () {
      expect(
        sanitizedSavedSessionWebSocketUrl('wss://gateway.example:bad/stream'),
        isNull,
      );
    });

    test('preserves legacy host-port websocket metadata', () {
      expect(
        sanitizedSavedSessionWebSocketUrl(' gateway.local:8765/custom/stream '),
        'gateway.local:8765/custom/stream',
      );
    });

    test('rejects legacy-shaped websocket metadata with bootstrap state', () {
      expect(
        sanitizedSavedSessionWebSocketUrl(
          ' pairing-token@gateway.local:8765/custom/stream?token=secret#frag ',
        ),
        isNull,
      );
    });

    test('preserves bracketed IPv6 host-port websocket metadata', () {
      expect(
        sanitizedSavedSessionWebSocketUrl(' [::1]:8765/custom/stream '),
        '[::1]:8765/custom/stream',
      );
    });

    test('rejects bracketed-host authority-shaped metadata', () {
      expect(
        sanitizedSavedSessionWebSocketUrl('[::1]://stream?token=secret'),
        isNull,
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
