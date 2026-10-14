import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/shell_compact_return_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Linux compact return retains sidebar intent and draft', (
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
      throw StateError('Use the isolated shell compact-return runner.');
    }
    final receipt = await runShellCompactReturnJourney(
      tester,
      binding.setSurfaceSize,
    );
    File(
      '$root/cache/shell-compact-return.json',
    ).writeAsStringSync(jsonEncode({...receipt, 'native_pid': pid}));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
  });
}
