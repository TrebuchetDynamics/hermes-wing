import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/local_setup_enrollment_native_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final journeys = <String, Object?>{};
  for (final width in [320.0, 1024.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Android direct setup $width text $scale', (tester) async {
        if (!Platform.isAndroid ||
            !const bool.fromEnvironment('WING_ANDROID_DIRECT_SETUP_QA')) {
          throw StateError('Use the isolated Android direct setup launcher');
        }
        // The launcher builds the separate .qa package; never clear personal data.
        await (await SharedPreferences.getInstance()).clear();
        await binding.setSurfaceSize(Size(width, 1000));
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(() => binding.setSurfaceSize(null));
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        journeys['$width-$scale'] = await runLocalEnrollmentJourney(
          tester,
          capture: (_) async {},
        );
        binding.reportData = {'android_direct_setup': journeys};
      });
    }
  }
}
