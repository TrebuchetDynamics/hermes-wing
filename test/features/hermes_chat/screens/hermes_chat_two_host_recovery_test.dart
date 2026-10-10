import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../integration_test/support/two_host_recovery_native_fixture.dart';

void main() {
  testWidgets(
    'public saved selection fences colliding hosts and explicit retry',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await exerciseTwoHostRecovery(tester, scale: 1, capture: (_) async {});
    },
  );
}
