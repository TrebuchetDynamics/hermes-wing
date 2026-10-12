import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
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
