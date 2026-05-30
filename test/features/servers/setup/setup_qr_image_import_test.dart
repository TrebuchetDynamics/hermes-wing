import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/servers/screens/setup_screen.dart';

import '../../shared/test_finders.dart';

void main() {
  testWidgets(
    'QR image import fills setup fields without rendering the token',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SetupScreen(
              qrImageImporter: () async => const SetupQrImageImport(
                baseUrl: 'http://10.0.2.2:8765',
                token: 'nvbx_from_qr_picture',
              ),
            ),
          ),
        ),
      );

      final importButton = find.bySemanticsLabel('Import QR image');
      await tester.ensureVisible(importButton);
      await tester.tap(importButton);
      await tester.pumpAndSettle();

      final addressField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Gateway address'),
      );
      final portField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Port'),
      );
      final tokenField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Pairing token'),
      );

      expect(addressField.controller?.text, '10.0.2.2');
      expect(portField.controller?.text, '8765');
      expect(tokenField.controller?.text, 'nvbx_from_qr_picture');
      expect(tokenField.obscureText, isTrue);
      expect(find.text('Imported QR connection details.'), findsOneWidget);
      expect(visibleTextContaining('nvbx_from_qr_picture'), findsNothing);
    },
  );

  test('parses Navivox QR URI payloads', () {
    final result = parseNavivoxQrPayload(
      'navivox://connect?base_url=http%3A%2F%2F10.0.2.2%3A8765&token=nvbx_uri_token',
    );

    expect(result?.baseUrl, 'http://10.0.2.2:8765');
    expect(result?.token, 'nvbx_uri_token');
  });

  test('parses Gormes navivox pair QR descriptor rest token', () {
    final result = parseNavivoxQrPayload(
      'navivox://connect?base_url=http%3A%2F%2F127.0.0.1%3A8765&websocket_url=ws%3A%2F%2F127.0.0.1%3A8765%2Fv1%2Fnavivox%2Fstream&auth_mode=pairing_token&exposure_mode=local&token_required=true&rest_token=nvbx_pair_rest_token&server_id=local&profile_id=mineru',
    );

    expect(result?.baseUrl, 'http://127.0.0.1:8765');
    expect(result?.token, 'nvbx_pair_rest_token');
    expect(result?.serverId, 'local');
    expect(result?.profileId, 'mineru');
  });

  test('derives pair base URL from websocket-only QR descriptors', () {
    final result = parseNavivoxQrPayload(
      'navivox://connect?websocket_url=ws%3A%2F%2F127.0.0.1%3A8765%2Fv1%2Fnavivox%2Fstream&auth_mode=pairing_token&token_required=true&rest_token=nvbx_ws_only_token',
    );

    expect(result?.baseUrl, 'http://127.0.0.1:8765');
    expect(result?.token, 'nvbx_ws_only_token');
  });

  test('parses connect-info JSON payloads', () {
    final result = parseNavivoxQrPayload('''
{
  "base_url": "http://100.64.1.2:8765",
  "token": "nvbx_json_token"
}
''');

    expect(result?.baseUrl, 'http://100.64.1.2:8765');
    expect(result?.token, 'nvbx_json_token');
  });

  test('parses Gormes pair JSON descriptors with websocket URL', () {
    final result = parseNavivoxQrPayload('''
{
  "websocket_url": "ws://127.0.0.1:8765/v1/navivox/stream",
  "auth_mode": "pairing_token",
  "token_required": true,
  "rest_token": "nvbx_pair_json_token"
}
''');

    expect(result?.baseUrl, 'http://127.0.0.1:8765');
    expect(result?.token, 'nvbx_pair_json_token');
  });
}
