import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../integration_test/support/local_serve_read_journey.dart';

void main() {
  testWidgets(
    'Local production reads: denial, unsupported, cancel and explicit retry',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;

      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      try {
        await runLocalServeReadJourney(tester);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
