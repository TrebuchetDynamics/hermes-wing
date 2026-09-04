import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';

void main() {
  test(
    'cache restores contacts offline and removes one gateway only',
    () async {
      SharedPreferences.setMockInitialValues({});
      final cache = GatewayContactCache();
      final contacts = [
        const GatewayContact(
          id: GatewayContactId(gatewayId: 'a', profileId: 'p1'),
          gatewayLabel: 'Alpha',
          profileName: 'One',
          sessionCount: 0,
          availability: GatewayAvailability.online,
        ),
        const GatewayContact(
          id: GatewayContactId(gatewayId: 'b', profileId: 'p2'),
          gatewayLabel: 'Beta',
          profileName: 'Two',
          sessionCount: 0,
          availability: GatewayAvailability.online,
        ),
      ];

      await cache.save(contacts);
      await cache.removeGateway('a');
      final restored = await cache.load();

      expect(restored, hasLength(1));
      expect(restored.single.id.gatewayId, 'b');
      expect(restored.single.availability, GatewayAvailability.offline);
    },
  );

  test('cached negative session counts are clamped to zero', () async {
    SharedPreferences.setMockInitialValues({
      'wing.hermes.gateway_contacts.v1': jsonEncode([
        {'gatewayId': 'alpha', 'profileId': 'default', 'sessionCount': -1},
      ]),
    });

    final contacts = await GatewayContactCache().load();

    expect(contacts.single.sessionCount, 0);
  });

  test('cache round-trips the active contact and session selection', () async {
    SharedPreferences.setMockInitialValues({});
    final cache = GatewayContactCache();
    const selection = GatewayContactSelection(
      contactId: GatewayContactId(gatewayId: 'alpha', profileId: 'coder'),
      sessionId: 'session-2',
    );

    await cache.saveSelection(selection);
    final restored = await cache.loadSelection();

    expect(restored?.contactId, selection.contactId);
    expect(restored?.sessionId, selection.sessionId);
  });

  test(
    'removing the selected gateway clears its remembered selection',
    () async {
      SharedPreferences.setMockInitialValues({});
      final cache = GatewayContactCache();
      await cache.saveSelection(
        const GatewayContactSelection(
          contactId: GatewayContactId(gatewayId: 'alpha', profileId: 'coder'),
          sessionId: 'session-2',
        ),
      );

      await cache.removeGateway('alpha');

      expect(await cache.loadSelection(), isNull);
    },
  );

  for (final malformed in <String>[
    '{"gatewayId":"alpha","profileId":[]}',
    '{"gatewayId":{},"profileId":"coder"}',
    '{"gatewayId":7,"profileId":"coder"}',
    '{"gatewayId":true,"profileId":"coder"}',
    '{"gatewayId":" ","profileId":"coder"}',
    '{"gatewayId":"alpha","profileId":" "}',
    '{"gatewayId":"alpha","profileId":"coder","sessionId":[]}',
    '{"gatewayId":"alpha","profileId":"coder","sessionId":false}',
  ]) {
    test('malformed remembered selection fails closed: $malformed', () async {
      SharedPreferences.setMockInitialValues({
        'wing.hermes.gateway_contact_selection.v1': malformed,
      });

      expect(await GatewayContactCache().loadSelection(), isNull);
    });
  }
}
