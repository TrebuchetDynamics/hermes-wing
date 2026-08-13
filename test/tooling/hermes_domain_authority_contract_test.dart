import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Hermes Agent exclusively owns profile and provider domains', () {
    final authority = File('lib/core/hermes/hermes_domain_authority.dart');
    final agents = File(
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
    final server = File('wing_link/serve.go').readAsStringSync();

    expect(authority.existsSync(), isTrue);
    final authorityText = authority.readAsStringSync();
    expect(
      authorityText,
      contains('const wingLinkDomainFallbacksEnabled = false;'),
    );
    expect(agents, contains('wingLinkDomainFallbacksEnabled'));
    expect(providers, contains('wingLinkDomainFallbacksEnabled'));
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
    expect(server, contains('const wingLinkDomainFallbacksEnabled = false'));
    expect(
      server,
      contains(
        'if wingLinkDomainFallbacksEnabled && request.URL.Path == "/v1/profiles"',
      ),
    );
    expect(
      server,
      contains('if wingLinkDomainFallbacksEnabled && server.providers != nil'),
    );
  });
}
