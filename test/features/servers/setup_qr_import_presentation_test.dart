import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/servers/setup/setup_qr_import_presentation.dart';

void main() {
  const presentation = SetupQrImportPresentation();

  test('parses canonical Navivox pairing descriptor through core semantics', () {
    final result = presentation.parsePayload(
      'navivox://connect?'
      'websocket_url=wss%3A%2F%2Fgateway.example%3A8765%2Fv1%2Fnavivox%2Fstream&'
      'auth_mode=pairing_token&'
      'token_required=true&'
      'rest_token=nvbx_core_descriptor_token',
    );

    expect(result?.baseUrl, 'https://gateway.example:8765');
    expect(
      result?.webSocketUrl,
      'wss://gateway.example:8765/v1/navivox/stream',
    );
    expect(result?.token, 'nvbx_core_descriptor_token');
  });

  test('parses setup compatibility payloads', () {
    final uriResult = presentation.parsePayload(
      'navivox://connect?base_url=http%3A%2F%2F10.0.2.2%3A8765&token=nvbx_uri_token',
    );
    expect(uriResult?.baseUrl, 'http://10.0.2.2:8765');
    expect(uriResult?.token, 'nvbx_uri_token');

    final jsonResult = presentation.parsePayload('''
{
  "entries": [
    {
      "websocket_url": "ws://127.0.0.1:8765/v1/navivox/stream",
      "rest_token": "nvbx_json_entry_token"
    }
  ]
}
''');
    expect(jsonResult?.baseUrl, 'http://127.0.0.1:8765');
    expect(jsonResult?.webSocketUrl, 'ws://127.0.0.1:8765/v1/navivox/stream');
    expect(jsonResult?.token, 'nvbx_json_entry_token');

    final textResult = presentation.parsePayload(
      'Run gormes navivox connect-info, then use http://100.64.1.2:8765 and pairing token: nvbx_text_token.',
    );
    expect(textResult?.baseUrl, 'http://100.64.1.2:8765');
    expect(textResult?.token, 'nvbx_text_token');
  });

  test('ignores empty or unrelated payloads', () {
    expect(presentation.parsePayload('   '), isNull);
    expect(presentation.parsePayload('not a Navivox QR'), isNull);
  });
}
