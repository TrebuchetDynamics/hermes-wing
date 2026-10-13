import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../integration_test/support/local_setup_enrollment_native_fixture.dart';

void main() {
  for (final width in [390.0, 1280.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'production Local enrollment $width text $scale',
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
          expect(receipt['inspect'], 4);
          expect(receipt['picker_calls'], 2);
          for (final key in [
            'chooser_cancel_preserved',
            'metadata_missing_default_selected',
            'saved_owner_preserved',
            'inert_legacy_preserved',
          ]) {
            expect(receipt[key], true, reason: key);
          }
          expect(receipt['legacy_reads'], 0);
          expect(receipt['legacy_deletes'], 0);
          expect(receipt['link_operations'], 0);
          expect(receipt['mutations'], 0);
          expect(receipt['forbidden_reads'], 0);
        },
        variant: TargetPlatformVariant.only(TargetPlatform.linux),
      );
    }
  }
}
