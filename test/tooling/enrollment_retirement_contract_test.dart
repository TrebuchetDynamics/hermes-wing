import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all assembled production consumers stay Agent-only', () {
    expect(_managementConsumers(Directory('lib')), isEmpty);
  });

  test('native product-control fixtures stay Agent-only', () {
    expect(_managementConsumers(Directory('integration_test')), isEmpty);
  });

  test('native fixture guard retains only the standalone service check', () {
    final parent = Directory.systemTemp.createTempSync('native-consumers-');
    addTearDown(() => parent.deleteSync(recursive: true));
    final root = Directory('${parent.path}/integration_test')..createSync();
    File(
      '${root.path}/linux_live_directory_service_test.dart',
    ).writeAsStringSync('WingLinkClient()');
    for (final relative in [
      'linux_live_directory_service_test_extra.dart',
      'support/linux_live_directory_service_test.dart',
      'core/wing_link/client.dart',
      'android_secure_storage_regression_test.dart',
      'linux_secure_storage_integration_test.dart',
    ]) {
      final file = File('${root.path}/$relative')..createSync(recursive: true);
      const retention = "const row = {'wingLinkToken': 'retained'};";
      file.writeAsStringSync(retention);
      expect(_managementConsumers(root), isEmpty);
      for (final source in [
        "import 'package:wing/core/wing_link/wing_link_client.dart';",
        "export '../lib/core/wing_link/wing_link_client.dart';",
        'final client = WingLinkClient();',
        'final client = wingLinkClientBuilder();',
      ]) {
        file.writeAsStringSync('$retention\n$source');
        expect(_managementConsumers(root), [
          file.path,
        ], reason: '$relative: $source');
      }
      file.deleteSync();
    }
  });

  test('standalone service exception is exact across path separators', () {
    for (final separator in ['/', r'\']) {
      final root = ['workspace', 'integration_test'].join(separator);
      String path(String relative) =>
          '$root$separator${relative.replaceAll('/', separator)}';
      for (final rootPath in [
        root,
        root.replaceAll(r'\', '/'),
        'integration_test',
      ]) {
        final file = rootPath == 'integration_test'
            ? 'integration_test${separator}linux_live_directory_service_test.dart'
            : path('linux_live_directory_service_test.dart');
        expect(_isRetainedManagementSource(rootPath, file), isTrue);
      }
      for (final relative in [
        'linux_live_directory_service_test_extra.dart',
        'support/linux_live_directory_service_test.dart',
        'core/wing_link/client.dart',
        'android_secure_storage_regression_test.dart',
        'linux_secure_storage_integration_test.dart',
      ]) {
        expect(
          _isRetainedManagementSource(root, path(relative)),
          isFalse,
          reason: relative,
        );
      }
      expect(
        _isRetainedManagementSource(
          '${root}_extra',
          '${root}_extra${separator}linux_live_directory_service_test.dart',
        ),
        isFalse,
      );
    }
  });

  test('management guard rejects directives and runtime client references', () {
    final root = Directory.systemTemp.createTempSync('management-consumers-');
    addTearDown(() => root.deleteSync(recursive: true));
    final storage = File(
      '${root.path}/core/hermes/setup/secure_hermes_endpoint_store.dart',
    )..createSync(recursive: true);
    const retention = '''
const tokenSlot = 'wing.hermes.profile_wing_link_token.';
const row = <String, Object?>{};
final retained = {'wingLinkOrigin': row['wingLinkOrigin'],
  'wingLinkToken': row['wingLinkToken'], 'wingLinkDeviceId': row['wingLinkDeviceId']};
String _wingLinkTokenKey(String id) => '\$tokenSlot\$id';
''';
    storage.writeAsStringSync(retention);
    final retainedClient = File('${root.path}/core/wing_link/client.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('WingLinkClient()');
    expect(_managementConsumers(root), isEmpty);
    for (final source in [
      "import 'wing_link_client.dart';",
      "export 'wing_link_transport.dart';",
      "import '../../core/wing_link/wing_link_client.dart';",
      "export '../core/wing_link/models/wing_link_device.dart';",
      "import 'package:wing/core/wing_link/wing_link_client.dart' as link;",
      "export 'package:wing/core/wing_link/wing_link_client.dart';",
      "import 'stub.dart' if (dart.library.io) 'core/wing_link/wing_link_client.dart';",
      "export 'stub.dart' if (dart.library.io) 'package:wing/core/wing_link/wing_link_client.dart';",
      'final client = WingLinkClient();',
      'final client = link.WingLinkClient.named();',
      'final client = wingLinkClientBuilder();',
      'WingLinkClient? client;',
    ]) {
      storage.writeAsStringSync('$retention\n$source');
      expect(_managementConsumers(root), [storage.path], reason: source);
    }
    storage.writeAsStringSync(retention);
    // A similarly named feature directory is not the retained implementation.
    final consumer = File('${root.path}/features/core/wing_link/caller.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(retainedClient.readAsStringSync());
    expect(_managementConsumers(root), [consumer.path]);
    consumer.deleteSync();
    expect(_managementConsumers(root), isEmpty);
  });

  test('retained management subtree exclusion is separator-independent', () {
    for (final separator in ['/', r'\']) {
      final root = ['workspace', 'lib'].join(separator);
      String path(String relative) =>
          '$root$separator${relative.replaceAll('/', separator)}';
      for (final rootPath in [root, root.replaceAll(r'\', '/')]) {
        expect(
          _isRetainedManagementSource(
            rootPath,
            path('core/wing_link/client.dart'),
          ),
          isTrue,
        );
      }
      for (final relative in [
        'core/wing_link_extra/client.dart',
        'features/core/wing_link/client.dart',
        'core/hermes/setup/secure_hermes_endpoint_store.dart',
      ]) {
        expect(
          _isRetainedManagementSource(root, path(relative)),
          isFalse,
          reason: path(relative),
        );
      }
    }
  });

  test('Linux transport journey stays Agent-only with SSE coverage', () {
    final source = File(
      'integration_test/linux_transport_boundary_test.dart',
    ).readAsStringSync();
    for (final forbidden in [
      'core/wing_link/',
      'WingLink',
      'wingLink',
      'Wing Link',
      'link_transport',
    ]) {
      expect(source, isNot(contains(forbidden)), reason: forbidden);
    }
    for (final retained in [
      "import '../test/core/hermes/client/platform/hermes_api_transport_io_test.dart'",
      'as agent_transport;',
      "import '../test/core/hermes/sse/hermes_sse_event_decoder_test.dart' as sse;",
      'IntegrationTestWidgetsFlutterBinding.ensureInitialized();',
      "group('native Agent transport', agent_transport.main);",
      "group('native SSE framing', sse.main);",
    ]) {
      expect(source, contains(retained), reason: retained);
    }
    final runner = File('scripts/run_linux_e2e.sh').readAsStringSync();
    expect(
      runner,
      contains(
        'for target in linux_fixture_e2e_test.dart linux_http_e2e_test.dart linux_transport_boundary_test.dart; do',
      ),
    );
    expect(
      runner,
      contains(r'flutter test -d linux "integration_test/$target"'),
    );
  });

  test('Android live regression cannot restore management profile cleanup', () {
    expect(
      File('scripts/maestro/gateway_profiles_qa.yaml').existsSync(),
      isFalse,
    );
    final source = File(
      'scripts/run_android_maestro_regression.sh',
    ).readAsStringSync();
    for (final forbidden in [
      'gateway_profiles_qa.yaml',
      'WING_QA_PROFILE_FIXTURE',
      'wing-link',
      'hermes profile',
      'cleanup_status',
    ]) {
      expect(source, isNot(contains(forbidden)), reason: forbidden);
    }
    for (final match in RegExp(
      r'^\s+(\S+\.yaml)$',
      multiLine: true,
    ).allMatches(source)) {
      final path = match.group(1)!;
      final flow = File(path).readAsStringSync();
      for (final forbidden in [
        'Wing Link',
        'wing-link',
        'WING_QA_PROFILE_FIXTURE',
      ]) {
        expect(flow, isNot(contains(forbidden)), reason: path);
      }
    }
    final providers = File(
      'scripts/maestro/providers_models_unsupported_qa.yaml',
    ).readAsStringSync();
    for (final retained in [
      'Providers unavailable',
      'Read-only access',
      'Primary runtime model',
      r'- assertNotVisible: "^Create$"',
      r'- assertNotVisible: "^Manage credential$"',
      r'- assertNotVisible: "^Choose model$"',
    ]) {
      expect(providers, contains(retained), reason: retained);
    }
  });

  test(
    'Android live runner preserves identity, order and suite status offline',
    () async {
      final root = Directory.systemTemp.createTempSync('android-runner-');
      addTearDown(() => root.deleteSync(recursive: true));
      Directory('${root.path}/scripts').createSync();
      final runner = File(
        'scripts/run_android_maestro_regression.sh',
      ).copySync('${root.path}/scripts/runner.sh');
      final args = File('${root.path}/args');
      final cleanup = File('${root.path}/cleanup');
      final maestro = File('${root.path}/fake-maestro')
        ..writeAsStringSync(r'''#!/bin/bash
printf '%s\n' "$@" > "$QA_ARGS"
exit "$QA_STATUS"
''');
      // Sentinels prevent a restored cleanup path from reaching a personal runtime.
      for (final name in ['wing-link', 'hermes']) {
        File('${root.path}/$name').writeAsStringSync(r'''#!/bin/bash
printf '%s\n' "$0 $*" >> "$QA_CLEANUP"
exit 0
''');
      }
      final permissions = await Process.run('chmod', [
        '+x',
        maestro.path,
        '${root.path}/wing-link',
        '${root.path}/hermes',
      ]);
      expect(permissions.exitCode, 0);
      for (final status in [0, 17]) {
        for (final device in ['', 'offline-device']) {
          final result = await Process.run(
            'bash',
            [runner.path],
            environment: {
              'PATH': '${root.path}:/usr/bin:/bin',
              'MAESTRO_BIN': maestro.path,
              'WING_QA_GATEWAY_LABEL': 'Offline gateway',
              'WING_QA_PROFILE_LABEL': 'offline-profile',
              'WING_QA_DEVICE': device,
              'WING_QA_PROFILE_FIXTURE': 'maestroqa123',
              'QA_ARGS': args.path,
              'QA_CLEANUP': cleanup.path,
              'QA_STATUS': '$status',
            },
            includeParentEnvironment: false,
          );
          expect(result.exitCode, status, reason: '${result.stderr}');
          expect(cleanup.existsSync(), isFalse);
          expect(args.readAsLinesSync(), [
            if (device.isNotEmpty) ...['--device', device],
            'test',
            '-e',
            'WING_QA_GATEWAY_LABEL=Offline gateway',
            '-e',
            'WING_QA_PROFILE_LABEL=offline-profile',
            '.maestro/real-gateway-regression.yaml',
            'scripts/maestro/session_branch_qa.yaml',
            'scripts/maestro/session_bulk_selection_qa.yaml',
            'scripts/maestro/session_metadata_qa.yaml',
            'scripts/maestro/tools_inventory_qa.yaml',
            'scripts/maestro/gateway_status_qa.yaml',
            'scripts/maestro/gateway_connection_settings_qa.yaml',
            'scripts/maestro/providers_models_unsupported_qa.yaml',
            'scripts/maestro/schedules_unsupported_qa.yaml',
            'scripts/maestro/office_workspace_qa.yaml',
            'scripts/maestro/chat_concurrent_sessions_qa.yaml',
            'scripts/maestro/chat_process_recovery_qa.yaml',
            'scripts/maestro/chat_ux_qa.yaml',
          ]);
        }
      }
    },
  );

  test('obsolete Android pairing-success harness cannot return', () {
    expect(
      File('.maestro/android-pairing-same-device.yaml').existsSync(),
      isFalse,
    );
  });

  test(
    'Android production fixture uses direct enrollment and retains recovery',
    () {
      final source = File(
        'scripts/maestro/android_fixture_regression.yaml',
      ).readAsStringSync();
      for (final forbidden in [
        'Add your first Hermes profile',
        'Add gateway or profile',
        'QR code',
        'pairing link',
        'Connect one profile manually',
        'This device',

        'PAIRING_',
        'wing-link',
      ]) {
        expect(source, isNot(contains(forbidden)), reason: forbidden);
      }
      var previous = -1;
      for (final step in [
        "visible: 'Welcome to Hermes Wing'",
        "- tapOn: 'Connect to Remote Hermes'",
        "- assertVisible: 'VPN / NetBird / Tailscale'",
        '- back',
        "- assertVisible: 'Welcome to Hermes Wing'",
        "- tapOn: 'Connect to Remote Hermes'",
        "- tapOn: 'VPN / NetBird / Tailscale'",
        "text: '(?s).*Hermes Agent URL.*'",
        r"- inputText: '${WING_QA_FIXTURE_ORIGIN}'",
        "- inputText: 'Android fixture'",
        "text: 'Add Hermes'",
        "visible: '(?s).*Endpoint contact.*'",
        "- tapOn: '(?s).*Android fixture.*'",
        "visible: '(?s).*Message Hermes.*'",
        "- inputText: 'ANDROID NATIVE FIRST'",
        "- tapOn: 'Approve once'",
        "visible: '(?s).*Hermes echo: ANDROID NATIVE FIRST.*'",
        "- inputText: 'ANDROID NATIVE SECOND'",
        "- tapOn: 'Approve once'",
        "visible: '(?s).*Hermes echo: ANDROID NATIVE SECOND.*'",
        '- stopApp',
        '- launchApp',
        "visible: '(?s).*Hermes echo: ANDROID NATIVE SECOND.*'",
        '- setOrientation: LANDSCAPE_LEFT',
        "- assertVisible: '(?s).*Hermes echo: ANDROID NATIVE SECOND.*'",
        '- setOrientation: PORTRAIT',
        "- inputText: 'ANDROID NATIVE STOP'",
        "visible: 'Approve once'",
        "- tapOn: 'Stop'",
        "notVisible: 'Stop'",
        "- inputText: 'ANDROID NATIVE RECOVERED'",
        "- tapOn: 'Approve once'",
        "visible: '(?s).*Hermes echo: ANDROID NATIVE RECOVERED.*'",
        "- assertNotVisible: '(?s).*HttpException.*'",
      ]) {
        final next = source.indexOf(step, previous + 1);
        expect(next, greaterThan(previous), reason: step);
        previous = next;
      }
    },
  );

  test('all-feature Maestro fixture cannot restore management or pairing', () {
    final source = File(
      'integration_test/hermes_features_maestro_main.dart',
    ).readAsStringSync();
    for (final forbidden in [
      'core/wing_link/',
      'WingLink',
      'trustClient',
      'trustMode',
      'Management revoked:',
      'Pairing fixture',
      'Changed host identity',
      'Expired device credential',
      'Unsupported protocol',
      'pairing input',
      'Prepare fixture paste',
    ]) {
      expect(source, isNot(contains(forbidden)), reason: forbidden);
    }
    final runner = File(
      'scripts/run_android_maestro_features.sh',
    ).readAsStringSync();
    for (final obsolete in [
      'pairing.yaml',
      'gateway_trust.yaml',
      'trust_errors.yaml',
      'computer_setup.yaml',
    ]) {
      expect(File('scripts/maestro/fixture/$obsolete').existsSync(), isFalse);
      expect(runner, isNot(contains(obsolete)));
    }
    for (final flow in [
      'legacy_input_rejection.yaml',
      'gateway_read_only.yaml',
    ]) {
      expect(runner, contains(flow));
      final yaml = File('scripts/maestro/fixture/$flow').readAsStringSync();
      expect(yaml, isNot(contains('Wing Link')));
      expect(yaml, isNot(contains('Pairing fixture')));
    }
    for (final retained in [
      'approvals_recovery.yaml',
      'attachment_picker_race.yaml',
      'gateway_connection.yaml',
    ]) {
      expect(runner, contains(retained));
    }
  });

  test('saved endpoint public contract is Agent-only', () {
    for (final path in [
      'lib/core/hermes/setup/hermes_endpoint_store.dart',
      'lib/features/hermes_chat/gateways/hermes_gateway_directory.dart',
      'lib/main_e2e.dart',
      'lib/main_connection_production_matrix_e2e.dart',
    ]) {
      expect(
        _restoresEndpointManagement(File(path).readAsStringSync()),
        isFalse,
        reason: path,
      );
    }
    final storage = File(
      'lib/core/hermes/setup/secure_hermes_endpoint_store.dart',
    ).readAsStringSync();
    expect(storage, isNot(contains('key: _wingLinkTokenKey(id),')));
    expect(storage, isNot(contains('core/wing_link/')));
  });

  test(
    'saved endpoint guard rejects restored management fields and clients',
    () {
      for (final source in [
        'final String? wingLinkToken;',
        'String? wingLinkOrigin,',
        'wingLinkDeviceId: device,',
        'WingLinkClient()',
        "import 'core/wing_link/wing_link_client.dart';",
      ]) {
        expect(_restoresEndpointManagement(source), isTrue, reason: source);
      }
      expect(_restoresEndpointManagement('String? apiKey,'), isFalse);
    },
  );

  test('obsolete Linux revoke/re-pair product journey cannot return', () {
    expect(
      File(
        'integration_test/linux_live_security_recovery_test.dart',
      ).existsSync(),
      isFalse,
    );
    final runner = File(
      'scripts/run_linux_live_security_e2e.sh',
    ).readAsStringSync();
    for (final forbidden in [
      'linux_live_security_recovery_test.dart',
      'WING_LIVE_',
      'WING_LINK_STATE',
      'WING_HERMES_HOME',
      'xvfb-run',
      'flutter test',
    ]) {
      expect(runner, isNot(contains(forbidden)), reason: forbidden);
    }
  });

  test(
    'Linux Agent features cannot restore retained service prerequisites',
    () {
      final source = File(
        'integration_test/linux_live_feature_journeys_test.dart',
      ).readAsStringSync();
      final runner = File(
        'scripts/run_linux_live_features_e2e.sh',
      ).readAsStringSync();
      for (final forbidden in [
        'core/wing_link/',
        'WingLink',
        'wingLink',
        'WING_LIVE_LINK_',
        'WING_LINK_STATE',
        'WING_LIVE_DIRECTORY_ROOT',
        'directories',
      ]) {
        expect(source, isNot(contains(forbidden)), reason: forbidden);
        expect(runner, isNot(contains(forbidden)), reason: forbidden);
      }
      for (final retained in [
        'client.createSession',
        'client.deleteSession',
        'client.listSessionsPage',
        'hermes-session-search-field',
        'hermes-session-title-save',
        'Copy details',
        'Unpin',
        'Load more sessions',
        'container.dispose',
        'channel.dispose',
        'activateGateway',
        'tools-refresh',
        'installed-skills-search',
        'toolsets-search',
        'office-agent-search',
        'office-refresh',
        'office-open-',
        'Providers unavailable',
        'Schedules unavailable',
        'Persona editing unavailable',
        'profile_soul_update',
      ]) {
        expect(source, contains(retained), reason: retained);
      }
    },
  );

  test('retained directory service safety remains separate and intact', () {
    final source = File(
      'integration_test/linux_live_directory_service_test.dart',
    ).readAsStringSync();
    final runner = File(
      'scripts/run_linux_live_directory_service_e2e.sh',
    ).readAsStringSync();
    expect(source, isNot(contains('core/hermes/')));
    expect(runner, isNot(contains('WING_LIVE_PROFILE_MANIFEST')));
    for (final retained in [
      'requireLinuxLiveDirectoryRoot',
      'requireLinuxTestRoot',
      'WingLinkClient',
      "['directories', 'grant', root]",
      "['directories', 'revoke', id]",
      'addTearDown',
      'lessThanOrEqualTo(32)',
      'limit: 1',
      'hasLength(1)',
      'page.nextOffset, isNull',
      "isNot(contains('private-file.txt'))",
      'for (final handle in [granted.handle, child.handle])',
      'WingLinkHttpException',
      '410',
      'row.handle == granted.handle',
    ]) {
      expect(source, contains(retained), reason: retained);
    }
    for (final retained in [
      'WING_LIVE_LINK_MANIFEST',
      'WING_LIVE_LINK_BINARY',
      'WING_LINK_STATE',
      'cleanup_coverage',
      'trap cleanup_coverage EXIT',
      '.wing-linux-test-owner',
      'linux-picker-sample.txt',
      'WING_LIVE_DIRECTORY_ROOT',
      'linux_live_directory_service_test.dart',
    ]) {
      expect(runner, contains(retained), reason: retained);
    }
  });

  test('retained Linux visual tour cannot restore Link prerequisites', () {
    final source = File(
      'integration_test/linux_live_visual_test.dart',
    ).readAsStringSync();
    final runner = File('scripts/run_linux_live_visual.sh').readAsStringSync();
    for (final forbidden in [
      'core/wing_link/',
      'WingLink',
      'wingLink',
      'WING_LIVE_LINK_',
      'removeProfile',
      'createdProfile',
      'pairing-entry',
      'pairing-paste-dialog',
      'gateway-trust-actions',
      'gateway-revoke-confirmation',
      'profile-directory-browser',
    ]) {
      expect(source, isNot(contains(forbidden)), reason: forbidden);
      expect(runner, isNot(contains(forbidden)), reason: forbidden);
    }
    for (final retained in [
      'secretValues.any',
      "RegExp(r'/(home|Users|tmp)/')",
      'EditableText',
      'channel.createSession',
      'channel.deleteSession',
      'channel.disconnect',
      'channel.connect',
      'channel.selectSession',
      'chat-model-picker',
      'chat-reconnected',
      'direct-agent-entry',
      'container.dispose()',
      'channel.dispose()',
      'store.clear()',
    ]) {
      expect(source, contains(retained), reason: retained);
    }
  });

  test('obsolete Linux Link profile journey cannot return', () {
    expect(
      File('integration_test/linux_live_wing_link_test.dart').existsSync(),
      isFalse,
    );
    final runner = File('scripts/run_linux_live_e2e.sh').readAsStringSync();
    for (final forbidden in [
      'linux_live_wing_link_test.dart',
      'WING_LIVE_LINK_MANIFEST',
      'WING_LIVE_LINK_BINARY',
      'WING_LINK_STATE',
    ]) {
      expect(runner, isNot(contains(forbidden)), reason: forbidden);
    }
  });

  test(
    'product and fixtures cannot restore the retired local host cluster',
    () {
      for (final path in ['lib', 'test', 'integration_test']) {
        expect(_obsoleteLocalHost(Directory(path)), isEmpty, reason: path);
      }
    },
  );

  test('local host guard rejects restored files, imports and symbols', () {
    final root = Directory.systemTemp.createTempSync('local-host-retirement-');
    addTearDown(() => root.deleteSync(recursive: true));
    for (final entry in {
      'local_wing_link_host.dart': '',
      'local_wing_link_process.dart': '',
      'local_wing_link_platform_io.dart': '',
      'local_wing_link_platform_stub.dart': '',
      'import.dart': "import 'local_wing_link_host.dart';",
      'export.dart': "export 'local_wing_link_process.dart';",
      'conditional.dart':
          "import 'stub.dart' if (dart.library.io) 'local_wing_link_platform_io.dart';",
      'host.dart': 'LocalWingLinkHost()',
      'inspection.dart': 'LocalHermesInspection()',
      'result.dart': 'LocalHermesSetupResult()',
    }.entries) {
      final file = File('${root.path}/${entry.key}')
        ..writeAsStringSync(entry.value);
      expect(_obsoleteLocalHost(root), [file.path]);
      file.deleteSync();
    }
    expect(_obsoleteLocalHost(root), isEmpty);
  });

  test('production cannot restore obsolete client compatibility authority', () {
    expect(_obsoleteClientAuthority(Directory('lib')), isEmpty);
  });

  test('client authority guard rejects a restored file, import or flag', () {
    final root = Directory.systemTemp.createTempSync('client-authority-');
    addTearDown(() => root.deleteSync(recursive: true));
    for (final entry in {
      'hermes_domain_authority.dart': '',
      'caller.dart': "import 'hermes_domain_authority.dart';",
      'flag.dart': 'const wingLinkProfileCompatibilityEnabled = true;',
    }.entries) {
      final file = File('${root.path}/${entry.key}')
        ..writeAsStringSync(entry.value);
      expect(_obsoleteClientAuthority(root), [file.path]);
      file.deleteSync();
    }
    expect(_obsoleteClientAuthority(root), isEmpty);
  });

  test('saved host controls cannot restore legacy metadata projection', () {
    for (final path in [
      'lib/features/hermes_chat/gateways/hermes_gateway_directory.dart',
      'lib/features/hermes_chat/gateways/gateway_contact.dart',
      'lib/features/gateway/widgets/saved_connections_section.dart',
    ]) {
      final source = File(path).readAsStringSync();
      for (final forbidden in [
        'managedByWingLink',
        'wing-link:',
        '_hostOverview',
        '_hostLabel',
        '_agentAuthorityBaseUrl',
        '_hostAvailability',
      ]) {
        expect(source, isNot(contains(forbidden)), reason: '$path: $forbidden');
      }
    }
  });

  test(
    'product and fixtures cannot restore dormant gateway enrollment seams',
    () {
      for (final root in ['lib', 'test', 'integration_test']) {
        final sources = Directory(root)
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .where(
              (file) => !file.path.endsWith(
                'enrollment_retirement_contract_test.dart',
              ),
            );
        for (final file in sources) {
          final source = file.readAsStringSync();
          for (final forbidden in [
            'clearWingLinkEnrollment',
            'PendingWingLinkCredentialRecovery',
            'pendingCredentialRecovery',
            'reconcileManagedProfileRename',
            'enrolledGatewayIdForManagedProfile',
          ]) {
            expect(
              source.contains(forbidden),
              isFalse,
              reason: '${file.path}: $forbidden',
            );
          }
        }
      }
    },
  );

  test('product and fixtures cannot restore the retired directory browser', () {
    final sources = [
      ...Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')),
      File('integration_test/linux_live_feature_journeys_test.dart'),
      File('integration_test/hermes_features_maestro_main.dart'),
      File('integration_test/linux_feature_regression_test.dart'),
    ];
    for (final file in sources) {
      final source = file.readAsStringSync();
      for (final forbidden in [
        'profile_directory_browser_sheet',
        'showProfileDirectoryBrowser',
        'DirectoryRootsLoader',
        'ChildDirectoriesLoader',
        'Directories fixture',
        'Directory pages:',
        'Revoke directory grant',
      ]) {
        expect(source, isNot(contains(forbidden)), reason: file.path);
      }
    }
    for (final path in [
      'scripts/maestro/fixture/local_setup_accessibility.yaml',
      'scripts/maestro/fixture/soul_directories.yaml',
    ]) {
      final source = File(path).readAsStringSync();
      for (final forbidden in [
        'Directories fixture',
        'Fixture root',
        'Fixture folder',
        'Directory pages:',
        'Revoke directory grant',
      ]) {
        expect(source, isNot(contains(forbidden)), reason: path);
      }
    }
  });

  test('profile editor has no legacy management approval dependency', () {
    final source = File(
      'lib/features/profiles/widgets/profile_editor_sheet.dart',
    ).readAsStringSync();
    for (final forbidden in [
      'core/wing_link/',
      'WingLink',
      '_PendingProfileApproval',
      '_pendingApproval',
      '_approvalExpiryTimer',
    ]) {
      expect(source, isNot(contains(forbidden)), reason: forbidden);
    }
  });

  test(
    'Profiles and Connections screens have no legacy builder dependency',
    () {
      for (final path in [
        'lib/features/profiles/screens/profiles_screen.dart',
        'lib/features/gateway/screens/gateway_screen.dart',
      ]) {
        final source = File(path).readAsStringSync();
        for (final forbidden in [
          'core/wing_link/',
          'WingLinkClient',
          'wingLinkClientBuilder',
        ]) {
          expect(source, isNot(contains(forbidden)), reason: path);
        }
      }
    },
  );

  test('local setup and fixtures cannot construct legacy management', () {
    final sources = [
      ...Directory('lib/features/local_setup')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')),
      File('lib/main_connection_production_matrix_e2e.dart'),
      if (File('lib/main_local_setup_recovery_e2e.dart').existsSync())
        File('lib/main_local_setup_recovery_e2e.dart'),
    ];
    for (final file in sources) {
      final source = file.readAsStringSync();
      for (final forbidden in [
        'core/wing_link/',
        'LocalWingLinkHost',
        'localWingLinkHostProvider',
        'localHermesSetupControllerProvider',
        'LocalHermesSetupController',
        'LocalHermesSetupStatus',
        'SetupRecoveryFixture',
      ]) {
        expect(source, isNot(contains(forbidden)), reason: file.path);
      }
    }
  });

  test('Agent client cannot expose dormant enrollment exchange surfaces', () {
    final sources = Directory('lib/core/hermes')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in sources) {
      final source = file.readAsStringSync();
      for (final forbidden in [
        'inspectEnrollment',
        'exchangeEnrollment',
        '_postJsonUnauthenticated',
        'enrollmentInspectUri',
        'enrollmentExchangeUri',
        'HermesEnrollmentPreview',
        'HermesIssuedOperatorToken',
        'HermesIssuedConnection',
        '/v1/operator/enrollments/',
      ]) {
        expect(source, isNot(contains(forbidden)), reason: file.path);
      }
    }
  });

  test('production enrollment cannot construct legacy management exchange', () {
    final sources = Directory('lib/features/enrollment')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in sources) {
      final source = file.readAsStringSync();
      for (final forbidden in [
        'HermesEnrollmentController',
        'HermesEnrollmentPayload',
        'EnrollmentReadiness',
        'ComputerSetupGuide',
        'enrollmentTransportFailure',
        'core/wing_link/',
        'inspectEnrollment',
        'exchangeEnrollment',
        'hermesEndpointStoreProvider',
      ]) {
        expect(source, isNot(contains(forbidden)), reason: file.path);
      }
    }
    final provider = File(
      'lib/features/enrollment/providers/hermes_enrollment_provider.dart',
    ).readAsStringSync();
    expect(provider, contains('hermesConnectIntentSourceProvider'));
    expect(provider, contains('MethodChannelHermesConnectIntentSource()'));
  });
}

List<String> _managementConsumers(Directory root) => root
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'))
    .where((file) => !_isRetainedManagementSource(root.path, file.path))
    .where((file) {
      final source = file.readAsStringSync();
      return RegExp(
            r'''\b(?:import|export)\s+[^;]*['"][^'"]*wing_link[^'"]*['"]''',
          ).hasMatch(source) ||
          RegExp(r'\b(?:WingLink\w*|wingLinkClient\w*)\b').hasMatch(source);
    })
    .map((file) => file.path)
    .toList();

bool _isRetainedManagementSource(String root, String file) {
  final rootPath = root.replaceAll(r'\', '/');
  final filePath = file.replaceAll(r'\', '/');
  // Keep standalone service safety coverage until the service itself is retired.
  return rootPath.split('/').last == 'integration_test'
      ? filePath == '$rootPath/linux_live_directory_service_test.dart'
      : filePath.startsWith('$rootPath/core/wing_link/');
}

List<String> _obsoleteLocalHost(Directory root) => root
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'))
    .where(
      (file) => !file.path.endsWith('enrollment_retirement_contract_test.dart'),
    )
    .where((file) {
      final source = file.readAsStringSync();
      return file.path.contains('local_wing_link_') ||
          source.contains('local_wing_link_') ||
          source.contains('LocalWingLink') ||
          source.contains('LocalHermesInspection') ||
          source.contains('LocalHermesSetupResult');
    })
    .map((file) => file.path)
    .toList();

List<String> _obsoleteClientAuthority(Directory root) => root
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'))
    .where((file) {
      final source = file.readAsStringSync();
      return file.path.endsWith('hermes_domain_authority.dart') ||
          source.contains('hermes_domain_authority.dart') ||
          source.contains('wingLinkProfileCompatibilityEnabled');
    })
    .map((file) => file.path)
    .toList();

bool _restoresEndpointManagement(String source) =>
    RegExp(r'wingLink|WingLink|core/wing_link/').hasMatch(source);
