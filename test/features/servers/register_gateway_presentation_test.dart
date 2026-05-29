import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/servers/registration/register_gateway_presentation.dart';

void main() {
  test('exposes register gateway field and boundary copy', () {
    const presentation = RegisterGatewayPresentation();

    expect(presentation.title, 'Register gateway');
    expect(
      presentation.instructions,
      'Run `gormes navivox connect-info --json` on the server, then enter its base URL and auth token here.',
    );
    expect(presentation.gatewayLabelFieldLabel, 'Gateway label');
    expect(
      presentation.gatewayLabelHelperText,
      'Screen-reader friendly name for this device.',
    );
    expect(presentation.baseUrlFieldLabel, 'Base URL');
    expect(presentation.baseUrlHintText, 'http://127.0.0.1:7319');
    expect(presentation.tokenFieldLabel, 'Auth token (optional)');
    expect(
      presentation.tokenHelperText,
      'Stored by the gateway connection layer only.',
    );
    expect(presentation.boundaryTitle, 'Current boundary');
    expect(
      presentation.boundarySubtitle,
      'This test connects the current session now; persistent multi-gateway connection storage is the next protocol slice.',
    );
  });

  test('validates supported Gormes gateway URL schemes', () {
    const presentation = RegisterGatewayPresentation();

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

  test('builds trimmed connection payload and omits blank token', () {
    const presentation = RegisterGatewayPresentation();

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

  test('reports button and connection result copy', () {
    expect(
      const RegisterGatewayPresentation().testButtonLabel,
      'Test connection',
    );
    expect(
      const RegisterGatewayPresentation(testing: true).testButtonLabel,
      'Testing',
    );

    const presentation = RegisterGatewayPresentation();
    final request = presentation.connectRequest(
      baseUrl: 'http://127.0.0.1:7319',
      token: '',
    );

    expect(
      presentation.connectionPassedMessage(request),
      'Connection test passed for http://127.0.0.1:7319',
    );
    expect(
      presentation.connectionFailedMessage('boom'),
      'Connection test failed: boom',
    );
  });
}
