import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late File calls;
  late File manifest;

  setUp(() async {
    root = Directory.systemTemp.createTempSync('linux-security-runner-');
    Directory('${root.path}/scripts').createSync();
    for (final name in ['security']) {
      final source = File('scripts/run_linux_live_${name}_e2e.sh');
      if (source.existsSync()) {
        source.copySync('${root.path}/scripts/${source.uri.pathSegments.last}');
      }
    }
    calls = File('${root.path}/calls');
    manifest = File('${root.path}/private manifest.json')
      ..writeAsStringSync('not a credential manifest');
    for (final name in ['go', 'flutter', 'xvfb-run']) {
      final wrapper = File('${root.path}/$name')
        ..writeAsStringSync('''#!/bin/bash
printf '%s\\n' "\$PWD" "\$GOPROXY" "\$GOTOOLCHAIN" "\$@" > "\$CALLS"
exit "\${FAKE_EXIT:-0}"
''');
      expect((await Process.run('chmod', ['700', wrapper.path])).exitCode, 0);
    }
  });

  tearDown(() => root.deleteSync(recursive: true));

  Future<ProcessResult> run({Map<String, String> inputs = const {}}) =>
      Process.run(
        '/bin/bash',
        ['${root.path}/scripts/run_linux_live_security_e2e.sh'],
        includeParentEnvironment: false,
        environment: {
          'PATH': '${root.path}:/usr/bin:/bin',
          'TMPDIR': root.path,
          'CALLS': calls.path,
          ...inputs,
        },
      ).timeout(const Duration(seconds: 10));

  test(
    'retired runner refuses all former inputs without reading or mutation',
    () async {
      for (final mode in ['600', '640', '604']) {
        expect((await Process.run('chmod', [mode, manifest.path])).exitCode, 0);
        for (final optIn in [null, '0', '1', 'invalid']) {
          for (final path in [
            null,
            '${root.path}/absent',
            root.path,
            manifest.path,
          ]) {
            final result = await run(
              inputs: {
                'WING_LIVE_REVOKE_AND_REPAIR': ?optIn,
                if (path != null) ...{
                  'WING_LIVE_PROFILE_MANIFEST': path,
                  'WING_LIVE_LINK_MANIFEST': path,
                },
                'WING_LIVE_LINK_BINARY': '${root.path}/go',
                'WING_LINK_STATE': manifest.path,
                'WING_HERMES_HOME': root.path,
              },
            );
            expect(result.exitCode, 2, reason: '${result.stderr}');
            expect(result.stderr, contains('Retired'));
            expect(result.stderr, contains('direct Agent authentication'));
            expect(calls.existsSync(), isFalse);
            expect(manifest.readAsStringSync(), 'not a credential manifest');
          }
        }
      }
    },
  );
}
