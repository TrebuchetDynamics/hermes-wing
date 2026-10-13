import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../integration_test/support/local_setup_enrollment_native_fixture.dart';
import '../../integration_test/support/android_direct_setup_enrollment_fixture.dart';
import '../../integration_test/support/direct_first_run_native_fixture.dart';

void main() {
  test(
    'synthetic loopback authority rejects missing/wrong auth and other origins',
    () async {
      final fixture = AndroidDirectSetupEnrollmentFixture();
      final uri = Uri.parse(
        '${AndroidDirectSetupEnrollmentFixture.loopback}/v1/capabilities',
      );
      for (final headers in [
        <String, String>{},
        {'Authorization': 'Bearer synthetic-wrong'},
      ]) {
        await expectLater(
          fixture.get(uri, headers),
          throwsA(isA<DirectFirstRunReadDenial>()),
        );
      }
      await expectLater(
        fixture.get(
          Uri.parse('https://other.example.invalid/v1/capabilities'),
          {},
        ),
        throwsStateError,
      );
      expect(fixture.requests, isEmpty);
      expect(fixture.deniedReads.length, 2);
      expect(fixture.forbiddenReadAttempts, 1);
    },
  );
  for (final width in [320.0, 1024.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Android production direct preparation and saved owner $width text $scale',
        (tester) async {
          SharedPreferences.setMockInitialValues({});
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final receipt = await runLocalEnrollmentJourney(
            tester,
            capture: (_) async {},
          );
          for (final key in [
            'manual_preparation',
            'storage_failure_preserved',
            'saved_owner_preserved',
            'inert_legacy_preserved',
            'direct_retry',
            'no_automatic_replay',
            'direct_without_management',
          ]) {
            expect(receipt[key], true, reason: key);
          }
          expect(receipt['documentation_calls'], 3);
          for (final key in [
            'inspect',
            'picker_calls',
            'legacy_reads',
            'legacy_deletes',
            'link_operations',
            'mutations',
            'forbidden_reads',
          ]) {
            expect(receipt[key], 0, reason: key);
          }
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );
    }
  }
}
