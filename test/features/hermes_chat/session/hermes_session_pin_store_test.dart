import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/session/hermes_session_pin_store.dart';

void main() {
  test('pins persist for only their gateway profile', () async {
    SharedPreferences.setMockInitialValues({});
    const alpha = GatewayContactId(gatewayId: 'alpha', profileId: 'default');
    const beta = GatewayContactId(gatewayId: 'beta', profileId: 'default');
    final first = HermesSessionPinStore();
    await first.load();

    await first.toggle(alpha, 'session-1');

    final restored = HermesSessionPinStore();
    await restored.load();
    expect(restored.isPinned(alpha, 'session-1'), isTrue);
    expect(restored.isPinned(beta, 'session-1'), isFalse);
  });
}
