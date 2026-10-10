import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/two_host_recovery_native_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final width in [1280.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('GTK two-host recovery $width text $scale', (tester) async {
        final root = Platform.environment['WING_TWO_HOST_ROOT'];
        if (root == null ||
            Platform.environment['HOME'] != '$root/home' ||
            Platform.environment['XDG_CONFIG_HOME'] != '$root/config' ||
            Platform.environment['DBUS_SESSION_BUS_ADDRESS'] != null ||
            Platform.environment['WING_LIVE_AUTH'] != null) {
          throw StateError('Use the isolated two-host launcher');
        }
        await (await SharedPreferences.getInstance()).clear();
        await binding.setSurfaceSize(Size(width, 1000));
        addTearDown(() => binding.setSurfaceSize(null));
        final result = await exerciseTwoHostRecovery(
          tester,
          scale: scale,
          capture: (state) async {
            await tester.runAsync(() async {
              await Future<void>.delayed(const Duration(milliseconds: 200));
              final capture = await Process.run('/usr/bin/import', [
                '-window',
                'root',
                '$root/cache/$state-$width-$scale.png',
              ]);
              expect(capture.exitCode, 0);
            });
          },
        );
        final file = File('$root/cache/two-host-$width-$scale.json');
        File('${file.path}.tmp').writeAsStringSync(
          jsonEncode({
            ...result,
            'native_pid': pid,
            'width': width,
            'text_scale': scale,
          }),
        );
        File('${file.path}.tmp').renameSync(file.path);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 1)),
        );
      });
    }
  }
}
