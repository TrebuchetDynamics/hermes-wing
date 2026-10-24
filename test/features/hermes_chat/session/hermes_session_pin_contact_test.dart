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
          savedBaseUrl: 'https://agent.example.invalid',
          baseUrl: 'https://agent.example.invalid',
          profileId: 'alpha',
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

  test(
    'stale saved endpoint or profile falls back to the current exact owner',
    () {
      const saved = GatewayContactId(
        gatewayId: 'saved-opaque',
        profileId: 'alpha',
      );
      GatewayContactId? owner({
        String? savedUrl = 'https://first.example.invalid',
        String? actualUrl = 'https://second.example.invalid',
        String? profile = 'alpha',
      }) => hermesSessionPinContact(
        savedContact: saved,
        savedBaseUrl: savedUrl,
        baseUrl: actualUrl,
        profileId: profile,
      );
      final direct = hermesSessionPinContact(
        savedContact: null,
        baseUrl: 'https://second.example.invalid',
        profileId: 'alpha',
      );
      expect(owner(), direct);
      expect(owner(savedUrl: null), direct);
      expect(
        owner(savedUrl: 'https://second.example.invalid', profile: 'beta'),
        isNot(saved),
      );
      expect(owner(savedUrl: 'https://second.example.invalid'), same(saved));
      expect(owner(actualUrl: null), isNull);
    },
  );
}
