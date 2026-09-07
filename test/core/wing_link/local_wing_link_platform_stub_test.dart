import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/wing_link/local_wing_link_platform_stub.dart' as stub;

void main() {
  test(
    'unavailable setup stays unavailable after repeated cancellation',
    () async {
      var progressCalls = 0;
      final operation = await stub.startLocalWingLinkSetup(
        'unused',
        (_) => progressCalls++,
      );
      await operation.cancel();
      await operation.cancel();
      final result = await operation.result;
      expect(result.exitCode, 126);
      expect(result.stdout, isEmpty);
      expect(result.stderr, isEmpty);
      expect(progressCalls, 0);
    },
  );
}
