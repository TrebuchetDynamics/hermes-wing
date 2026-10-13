import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
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
