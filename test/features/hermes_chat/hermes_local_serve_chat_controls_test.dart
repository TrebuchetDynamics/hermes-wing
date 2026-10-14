import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../integration_test/support/local_serve_chat_journey.dart';

void main() {
  testWidgets('Local production Send stream approval Stop and recovery', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    try {
      final receipt = await runLocalServeChatJourney(tester);
      await tester.pump(const Duration(seconds: 6));
      expect(receipt['sends'], 2);
      expect(receipt['answers'], 1);
      expect(receipt['stops'], 1);
      // Exact counts include denied reads and chat qualification, not only writes.
      debugPrint('Serve production control receipt: $receipt');
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
