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
}
