import 'package:flutter_test/flutter_test.dart';

import 'package:navivox/core/session/persistence/contracts/saved_connection_fields.dart';

void main() {
  group('SavedConnectionFields.fromInput', () {
    test('clears blank optional values', () {
      final fields = SavedConnectionFields.fromInput(
        baseUrl: ' https://gateway.example/api ',
        webSocketUrl: '   ',
        gatewayId: null,
      );

      expect(fields.baseUrl, 'https://gateway.example');
      expect(fields.webSocketUrl, isNull);
      expect(fields.gatewayId, isNull);
    });

    test('rejects blank base URL', () {
      expect(
        () => SavedConnectionFields.fromInput(baseUrl: '   '),
        throwsArgumentError,
      );
    });
  });
}
