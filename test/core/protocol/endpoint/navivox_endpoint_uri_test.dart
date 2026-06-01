import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_endpoint_uri.dart';

void main() {
  test('normalizes http origins while preserving non-http base URL values', () {
    expect(
      navivoxHttpOriginOrOriginalFromString(
        ' https://gateway.example:9443/path ',
      ),
      'https://gateway.example:9443',
    );
    expect(
      navivoxHttpOriginOrOriginalFromString('ws://gateway.example:7319/socket'),
      'ws://gateway.example:7319/socket',
    );
    expect(navivoxHttpOriginOrOriginalFromString('not a url'), 'not a url');
    expect(navivoxHttpOriginOrOriginalFromString('   '), isNull);
  });

  test('normalizes websocket endpoint strings separately from base URLs', () {
    expect(
      navivoxWebSocketUrlFromEndpointString(' wss://gateway.example/socket '),
      'wss://gateway.example/socket',
    );
    expect(
      navivoxWebSocketUrlFromEndpointString('https://gateway.example'),
      isNull,
    );
    expect(
      navivoxHttpBaseUrlFromEndpointString('wss://gateway.example/socket'),
      'https://gateway.example',
    );
    expect(
      navivoxHttpBaseUrlFromEndpointString('http://127.0.0.1:7319/api'),
      'http://127.0.0.1:7319',
    );
  });

  test(
    'rejects websocket fragments before they become dropped client state',
    () {
      expect(
        () => navivoxWebSocketUriFromEndpointString(
          'wss://gateway.example/socket#pairing-token',
        ),
        throwsFormatException,
      );
      expect(
        navivoxWebSocketUrlFromEndpointString(
          'wss://gateway.example/socket#pairing-token',
        ),
        isNull,
      );
    },
  );

  test('trims direct websocket endpoint parsing like optional URL parsing', () {
    final uri = navivoxWebSocketUriFromEndpointString(
      ' wss://gateway.example/socket ',
    );

    expect(uri.toString(), 'wss://gateway.example/socket');
    expect(
      navivoxWebSocketUrlFromEndpointString(' wss://gateway.example/socket '),
      'wss://gateway.example/socket',
    );
  });

  test('optional endpoint helpers reject malformed explicit ports', () {
    expect(
      navivoxHttpBaseUrlFromEndpointString('https://gateway.example:bad/api'),
      isNull,
    );
    expect(
      navivoxWebSocketUrlFromEndpointString(
        'wss://gateway.example:bad/socket',
      ),
      isNull,
    );
  });

  test('optional endpoint helpers reject userinfo before origin stripping', () {
    expect(
      navivoxHttpBaseUrlFromEndpointString(
        'https://operator:secret@gateway.example/setup',
      ),
      isNull,
    );
    expect(
      navivoxWebSocketUrlFromEndpointString(
        'wss://operator:secret@gateway.example/socket',
      ),
      isNull,
    );
  });

  group('base URL derivation invariants', () {
    test(
      'derives HTTP origin from websocket endpoint without dropping explicit port',
      () {
        expect(
          navivoxHttpBaseUrlFromEndpointString(
            'wss://gateway.example:443/navivox/ws?token=secret',
          ),
          'https://gateway.example:443',
        );
      },
    );

    test('strips path and query only for HTTP base URL derivation', () {
      expect(
        navivoxHttpBaseUrlFromEndpointString(
          'https://gateway.example:8443/api?token=secret',
        ),
        'https://gateway.example:8443',
      );
    });

    test('preserves websocket path and query for connection endpoint', () {
      expect(
        navivoxWebSocketUrlFromEndpointString(
          'wss://gateway.example/navivox/ws?token=secret',
        ),
        'wss://gateway.example/navivox/ws?token=secret',
      );
    });

    test('keeps original value when HTTP origin cannot be derived', () {
      expect(
        navivoxHttpOriginOrOriginalFromString('ftp://gateway.example/resource'),
        'ftp://gateway.example/resource',
      );
    });
  });
}
