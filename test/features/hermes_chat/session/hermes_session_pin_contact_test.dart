import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/session/hermes_session_pin_contact.dart';

void main() {
  test(
    'direct pins are stable for an exact endpoint and separate profile/path',
    () {
      GatewayContactId? owner(String url, [String profile = 'default']) =>
          hermesSessionPinContact(
            savedContact: null,
            baseUrl: url,
            profileId: profile,
          );
      const endpoint = 'https://agent.example.invalid/p/alpha';
      expect(owner(endpoint), owner(endpoint));
      expect(
        owner(endpoint),
        isNot(owner('https://other.example.invalid/p/alpha')),
      );
      expect(
        owner(endpoint),
        isNot(owner('https://agent.example.invalid/p/beta')),
      );
      expect(owner(endpoint), isNot(owner(endpoint, 'other')));
      expect(owner(endpoint)!.gatewayId, isNot(contains('example.invalid')));
      expect(owner(endpoint)!.gatewayId, isNot('direct'));
    },
  );

  test(
    'saved identities stay intact and missing direct identity cannot pin',
    () {
      const saved = GatewayContactId(
        gatewayId: 'saved-opaque',
        profileId: 'alpha',
      );
      expect(
        hermesSessionPinContact(
          savedContact: saved,
          baseUrl: null,
          profileId: null,
        ),
        same(saved),
      );
      expect(
        hermesSessionPinContact(
          savedContact: null,
          baseUrl: null,
          profileId: null,
        ),
        isNull,
      );
      expect(
        hermesSessionPinContact(
          savedContact: null,
          baseUrl: '  ',
          profileId: 'alpha',
        ),
        isNull,
      );
    },
  );
}
