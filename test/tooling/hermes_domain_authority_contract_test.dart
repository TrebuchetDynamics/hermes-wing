import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Wing Link exposes only the bounded profile compatibility domain', () {
    final authority = File('lib/core/hermes/hermes_domain_authority.dart');
    final profiles = File(
      'lib/features/profiles/screens/profiles_screen.dart',
    ).readAsStringSync();
    final providers = File(
      'lib/features/providers/screens/providers_screen.dart',
    ).readAsStringSync();
    final wingLinkClient = File(
      'lib/core/wing_link/wing_link_client.dart',
    ).readAsStringSync();
    final gatewayDirectory = File(
      'lib/features/hermes_chat/gateways/hermes_gateway_directory.dart',
    ).readAsStringSync();
    final server = File('wing_link/internal/app/serve.go').readAsStringSync();

    expect(authority.existsSync(), isTrue);
    final authorityText = authority.readAsStringSync();
    expect(
      authorityText,
      contains('const wingLinkProfileCompatibilityEnabled = true;'),
    );
    expect(profiles, contains('wingLinkProfileCompatibilityEnabled'));
    expect(providers, isNot(contains('WingLinkProvider')));
    expect(
      wingLinkClient,
      contains(
        "Future<void> verifyPendingCredential() async {\n"
        "    _decode(await _get(_uri('/v1/status'), _headers));\n"
        '  }',
      ),
    );
    expect(gatewayDirectory, isNot(contains('WingLinkProfileLoader')));
    expect(gatewayDirectory, isNot(contains('_loadWingLinkProfiles')));
    expect(
      server,
      contains('const wingLinkProfileCompatibilityEnabled = true'),
    );
    expect(
      server,
      contains(
        'if wingLinkProfileCompatibilityEnabled && request.URL.Path == "/v1/profiles"',
      ),
    );
    expect(server, isNot(contains('providerBackend')));
  });
}
