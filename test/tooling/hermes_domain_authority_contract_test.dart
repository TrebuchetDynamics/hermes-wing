import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<String> _linkConsumers(Directory root) => root
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'))
    .where((file) => !file.path.startsWith('${root.path}/core/wing_link/'))
    .where(
      (file) => RegExp(
        r'wing_link/|wing_link\w*\.dart|\bWingLink\w*|\bwingLinkClient\w*',
      ).hasMatch(file.readAsStringSync()),
    )
    .map((file) => file.path)
    .toList();

void main() {
  test('complete client outside retained core uses Agent authority only', () {
    expect(_linkConsumers(Directory('lib')), isEmpty);
  });

  test('client guard rejects Link consumers outside the exact retained core', () {
    final root = Directory.systemTemp.createTempSync('agent-authority-');
    addTearDown(() => root.deleteSync(recursive: true));
    File('${root.path}/core/wing_link/client.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('WingLinkClient()');
    expect(_linkConsumers(root), isEmpty);
    for (final entry in {
      'app/caller.dart':
          "import 'package:wing/core/wing_link/wing_link_client.dart';",
      'router/export.dart': "export '../core/wing_link/wing_link_client.dart';",
      'shared/conditional.dart':
          "import 'stub.dart' if (dart.library.io) '../core/wing_link/wing_link_transport.dart';",
      'core/hermes/caller.dart': 'WingLinkClient ()',
      'features/profiles/caller.dart': 'WingLinkProfile profile;',
      'main_fixture.dart': 'wingLinkClientBuilder()',
      'core/wing_link_extra/caller.dart': 'WingLinkTransport()',
    }.entries) {
      final file = File('${root.path}/${entry.key}')
        ..createSync(recursive: true)
        ..writeAsStringSync(entry.value);
      expect(_linkConsumers(root), [file.path], reason: entry.key);
      file.deleteSync();
    }
    File('${root.path}/core/hermes/storage.dart').writeAsStringSync(
      "final legacyKey = 'wing.hermes.profile_wing_link_token.';",
    );
    expect(_linkConsumers(root), isEmpty);
  });

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
