import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/shell_persistence_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Linux keyboard sidebar choice survives a real relaunch', (
    tester,
  ) async {
    final root = Platform.environment['WING_LOCAL_ROOT'];
    final phase = Platform.environment['WING_SHELL_PHASE'];
    if (!Platform.isLinux ||
        root == null ||
        Platform.environment['HOME'] != '$root/home' ||
        Platform.environment['XDG_CONFIG_HOME'] != '$root/config' ||
        Platform.environment['XDG_DATA_HOME'] != '$root/data' ||
        Platform.environment['XDG_CACHE_HOME'] != '$root/cache' ||
        Platform.environment['DBUS_SESSION_BUS_ADDRESS'] != null ||
        !['collapse', 'restore'].contains(phase)) {
      throw StateError('Use the isolated shell-persistence runner.');
    }
    await binding.setSurfaceSize(const Size(1280, 900));
    final receipt = await runShellPersistenceJourney(tester, phase!);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await runUnavailableStorageJourney(tester);
    File('$root/cache/shell-$phase.json').writeAsStringSync(
      jsonEncode({
        ...receipt,
        'native_pid': pid,
        'unavailable_storage_usable': true,
      }),
    );
    // Give the runner time to bind the receipt to the still-live GTK process.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
  });
}
