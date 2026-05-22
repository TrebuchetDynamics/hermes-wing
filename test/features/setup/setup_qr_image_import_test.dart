import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/servers/screens/setup_screen.dart';

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

      await tester.tap(find.byTooltip('Import QR image'));
      await tester.pumpAndSettle();

      final baseUrlField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Gateway base URL'),
      );
      final tokenField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Pairing token'),
      );

      expect(baseUrlField.controller?.text, 'http://10.0.2.2:8765');
      expect(tokenField.controller?.text, 'nvbx_from_qr_picture');
      expect(tokenField.obscureText, isTrue);
      expect(find.text('Imported QR connection details.'), findsOneWidget);
      expect(_visibleTextContaining('nvbx_from_qr_picture'), findsNothing);
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
      'navivox://connect?base_url=http%3A%2F%2F127.0.0.1%3A8765&websocket_url=ws%3A%2F%2F127.0.0.1%3A8765%2Fv1%2Fnavivox%2Fstream&auth_mode=pairing_token&exposure_mode=local&token_required=true&rest_token=nvbx_pair_rest_token',
    );

    expect(result?.baseUrl, 'http://127.0.0.1:8765');
    expect(result?.token, 'nvbx_pair_rest_token');
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
}

Finder _visibleTextContaining(String needle) {
  return find.byWidgetPredicate((widget) {
    if (widget is! Text) return false;
    final data = widget.data;
    if (data == null) return false;
    return data.contains(needle);
  });
}
