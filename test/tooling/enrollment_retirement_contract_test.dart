import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
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
