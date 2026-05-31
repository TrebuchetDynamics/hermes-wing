import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/gateway/client/gateway_config_admin_policy.dart';

void main() {
  group('navivoxConfigEditUnavailableMessage', () {
    test('keeps config and secret edit unavailable messages distinct', () {
      expect(
        navivoxConfigEditUnavailableMessage(secret: false),
        'Config editing is not available on this channel yet.',
      );
      expect(
        navivoxConfigEditUnavailableMessage(secret: true),
        'Secret editing is not available on this channel yet.',
      );
    });
  });
}
