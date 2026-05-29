import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/servers/registration/gateway_connection_presentation.dart';

void main() {
  test('validates supported Gormes gateway URL schemes', () {
    const presentation = GatewayConnectionPresentation();

    expect(
      presentation.validateBaseUrl(''),
      'Enter the Gormes gateway base URL.',
    );
    expect(
      presentation.validateBaseUrl('not a url'),
      'Enter a valid Gormes gateway URL.',
    );
    expect(
      presentation.validateBaseUrl('ftp://example.com'),
      'Use http, https, ws, or wss.',
    );
    expect(presentation.validateBaseUrl('http://127.0.0.1:7319'), isNull);
    expect(presentation.validateBaseUrl('https://gateway.example'), isNull);
    expect(presentation.validateBaseUrl('ws://127.0.0.1:7319'), isNull);
    expect(presentation.validateBaseUrl('wss://gateway.example'), isNull);
  });

  test(
    'validates and builds separate address and port connection payloads',
    () {
      const presentation = GatewayConnectionPresentation();

      expect(
        presentation.validateAddressAndPort(address: '', port: '8765'),
        'Enter the Gormes gateway address.',
      );
      expect(
        presentation.validateAddressAndPort(address: '127.0.0.1', port: 'bad'),
        'Enter a valid gateway port.',
      );
      expect(
        presentation.validateAddressAndPort(
          address: 'ftp://example.com',
          port: '8765',
        ),
        'Use http, https, ws, or wss.',
      );
      expect(
        presentation.validateAddressAndPort(address: '127.0.0.1', port: '8765'),
        isNull,
      );

      final separate = presentation.connectRequestFromParts(
        address: ' 127.0.0.1 ',
        port: ' 8765 ',
        token: ' nvbx_token ',
      );
      final pastedUrl = presentation.connectRequestFromParts(
        address: 'http://127.0.0.1:7319',
        port: '8765',
        token: '',
      );

      expect(separate.baseUrl, 'http://127.0.0.1:8765');
      expect(separate.token, 'nvbx_token');
      expect(pastedUrl.baseUrl, 'http://127.0.0.1:7319');
      expect(pastedUrl.token, isNull);
    },
  );

  test('splits imported base URLs into address and port fields', () {
    const presentation = GatewayConnectionPresentation();

    final split = presentation.splitBaseUrl('https://gateway.example:9443');

    expect(split.address, 'gateway.example');
    expect(split.port, '9443');
    expect(split.baseUrl, 'https://gateway.example:9443');
    expect(split.detectedPortFromAddress, isTrue);
  });

  test('builds trimmed connection payload and omits blank token', () {
    const presentation = GatewayConnectionPresentation();

    final withToken = presentation.connectRequest(
      baseUrl: '  http://127.0.0.1:7319  ',
      token: '  secret-token  ',
    );
    final withoutToken = presentation.connectRequest(
      baseUrl: '  ws://127.0.0.1:7319  ',
      token: '   ',
    );

    expect(withToken.baseUrl, 'http://127.0.0.1:7319');
    expect(withToken.token, 'secret-token');
    expect(withoutToken.baseUrl, 'ws://127.0.0.1:7319');
    expect(withoutToken.token, isNull);
  });
}
