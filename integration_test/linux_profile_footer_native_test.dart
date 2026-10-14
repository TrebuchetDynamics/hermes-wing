import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/profile_footer_native_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Linux passive footer keyboard management return and reconnect', (
    tester,
  ) async {
    final root = Platform.environment['WING_LOCAL_ROOT'];
    if (!Platform.isLinux ||
        root == null ||
        Platform.environment['HOME'] != '$root/home' ||
        Platform.environment['XDG_CONFIG_HOME'] != '$root/config' ||
        Platform.environment['XDG_DATA_HOME'] != '$root/data' ||
        Platform.environment['XDG_CACHE_HOME'] != '$root/cache' ||
        Platform.environment['DBUS_SESSION_BUS_ADDRESS'] != null) {
      throw StateError('Use the isolated profile-footer runner.');
    }
    final receipt = await runProfileFooterJourney(
      tester,
      binding.setSurfaceSize,
    );
    File(
      '$root/cache/profile-footer.json',
    ).writeAsStringSync(jsonEncode({...receipt, 'native_pid': pid}));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
  });
}
