import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public profile and provider controls use Agent authority only', () {
    final profiles = File(
      'lib/features/profiles/screens/profiles_screen.dart',
    ).readAsStringSync();
    final editor = File(
      'lib/features/profiles/widgets/profile_editor_sheet.dart',
    ).readAsStringSync();
    final providers = File(
      'lib/features/providers/screens/providers_screen.dart',
    ).readAsStringSync();

    final gatewayDirectory = File(
      'lib/features/hermes_chat/gateways/hermes_gateway_directory.dart',
    ).readAsStringSync();

    expect(profiles, isNot(contains('wingLinkProfileCompatibilityEnabled')));
    expect(profiles, isNot(contains('WingLinkClient(')));
    expect(profiles, isNot(contains('directory.refresh()')));
    expect(profiles, contains('channel: channel,'));
    expect(editor, contains('channel.createProfile('));
    expect(editor, contains('channel.renameProfile('));
    expect(editor, contains('channel.deleteProfile('));
    expect(providers, isNot(contains('WingLinkProvider')));
    for (final source in [profiles, editor, providers, gatewayDirectory]) {
      expect(source, isNot(contains('core/wing_link/')));
      expect(source, isNot(contains('WingLinkClient(')));
    }
    expect(gatewayDirectory, isNot(contains('WingLinkProfileLoader')));
    expect(gatewayDirectory, isNot(contains('_loadWingLinkProfiles')));
  });

  test('retained Link client and service keep compatibility safety checks', () {
    final wingLinkClient = File(
      'lib/core/wing_link/wing_link_client.dart',
    ).readAsStringSync();
    final server = File('wing_link/internal/app/serve.go').readAsStringSync();
    expect(
      wingLinkClient,
      contains(
        "Future<void> verifyPendingCredential() async {\n"
        "    _decode(await _get(_uri('/v1/status'), _headers));\n"
        '  }',
      ),
    );
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
