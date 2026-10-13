import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late File manifest;
  late File calls;

  setUp(() async {
    root = Directory.systemTemp.createTempSync('linux-feature-runner-');
    Directory('${root.path}/scripts').createSync();
    for (final name in ['features', 'directory_service']) {
      final source = File('scripts/run_linux_live_${name}_e2e.sh');
      if (source.existsSync()) {
        source.copySync('${root.path}/scripts/run_linux_live_${name}_e2e.sh');
      }
    }
    Directory('${root.path}/test/fixtures').createSync(recursive: true);
    File(
      'test/fixtures/linux-picker-sample.txt',
    ).copySync('${root.path}/test/fixtures/linux-picker-sample.txt');
    manifest = File('${root.path}/private manifest.json')
      ..writeAsStringSync('{}');
    calls = File('${root.path}/calls');
    final wrappers = {
      'xvfb-run': '''[[ "\$1" == -a ]] || exit 97
[[ "\${WRAPPER_EXIT:-0}" == 0 ]] || exit "\$WRAPPER_EXIT"
shift
exec "\$@"''',
      'flutter': '''printf '%s\\n' "\$@" > "\$CALLS"
printf '%s\\n' "\$WING_LINUX_TEST_ROOT" "\$XDG_CONFIG_HOME" > "\$ROOTS"
[[ "\$XDG_CONFIG_HOME" == "\$WING_LINUX_TEST_ROOT/config" && -f "\$WING_LINUX_TEST_ROOT/.wing-linux-test-owner" ]] || exit 98
if [[ "\$SERVICE" == 1 ]]; then
  [[ -f "\$WING_LIVE_LINK_MANIFEST" && -n "\$WING_LIVE_LINK_BINARY" && -n "\$WING_LINK_STATE" ]] || exit 99
  [[ "\$WING_LIVE_DIRECTORY_ROOT" == "\$WING_LINUX_TEST_ROOT/grant-root" && -d "\$WING_LIVE_DIRECTORY_ROOT/child-folder" && -f "\$WING_LIVE_DIRECTORY_ROOT/private-file.txt" ]] || exit 99
else
  [[ -f "\$WING_LIVE_PROFILE_MANIFEST" ]] || exit 99
  [[ -z "\${WING_LIVE_LINK_MANIFEST+x}" && -z "\${WING_LIVE_LINK_BINARY+x}" && -z "\${WING_LINK_STATE+x}" && -z "\${WING_LIVE_DIRECTORY_ROOT+x}" ]] || exit 99
  [[ ! -e "\$WING_LINUX_TEST_ROOT/grant-root" ]] || exit 99
fi
exit "\${FAKE_EXIT:-0}"''',
    };
    for (final entry in wrappers.entries) {
      final file = File('${root.path}/${entry.key}')
        ..writeAsStringSync('#!/bin/bash\n${entry.value}\n');
      expect((await Process.run('chmod', ['700', file.path])).exitCode, 0);
    }
    expect((await Process.run('chmod', ['600', manifest.path])).exitCode, 0);
  });

  tearDown(() => root.deleteSync(recursive: true));

  Future<ProcessResult> run({
    String? path,
    bool missing = false,
    bool service = false,
    bool servicePrerequisites = true,
    int exitCode = 0,
    int wrapperExit = 0,
  }) => Process.run(
    '/bin/bash',
    [
      '${root.path}/scripts/run_linux_live_${service ? 'directory_service' : 'features'}_e2e.sh',
    ],
    includeParentEnvironment: false,
    environment: {
      'PATH': '${root.path}:/usr/bin:/bin',
      'TMPDIR': root.path,
      'CALLS': calls.path,
      'ROOTS': '${root.path}/roots',
      'SERVICE': service ? '1' : '0',
      'FAKE_EXIT': '$exitCode',
      'WRAPPER_EXIT': '$wrapperExit',
      if (!missing)
        (service ? 'WING_LIVE_LINK_MANIFEST' : 'WING_LIVE_PROFILE_MANIFEST'):
            path ?? manifest.path,
      if (service && servicePrerequisites) ...{
        'WING_LIVE_LINK_BINARY': '${root.path}/unused-fixture-binary',
        'WING_LINK_STATE': '${root.path}/unused-fixture-state',
      },
    },
  );

  void expectCleanup() {
    expect(
      root.listSync().whereType<Directory>().where(
        (directory) => directory.path.contains('wing-linux-coverage.'),
      ),
      isEmpty,
    );
  }

  for (final service in [false, true]) {
    final name = service ? 'retained service' : 'Agent-only';
    test('$name admission preserves setup and cleanup', () async {
      final result = await run(service: service);
      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(calls.readAsLinesSync(), [
        'test',
        '-d',
        'linux',
        'integration_test/linux_live_${service ? 'directory_service' : 'feature_journeys'}_test.dart',
        '--reporter',
        'expanded',
      ]);
      final roots = File('${root.path}/roots').readAsLinesSync();
      expect(roots, hasLength(2));
      expect(roots.first, startsWith('${root.path}/wing-linux-coverage.'));
      expect(roots.last, '${roots.first}/config');
      expectCleanup();
    });

    test('$name preserves exact Flutter and wrapper failures', () async {
      expect((await run(service: service, exitCode: 37)).exitCode, 37);
      expect(calls.existsSync(), isTrue);
      expectCleanup();
      calls.deleteSync();
      expect((await run(service: service, wrapperExit: 41)).exitCode, 41);
      expect(calls.existsSync(), isFalse);
      expectCleanup();
    });

    test(
      '$name rejects missing, absent, directory and symlink manifests',
      () async {
        expect((await run(service: service, missing: true)).exitCode, isNot(0));
        for (final path in [
          '${root.path}/absent',
          root.path,
          (Link('${root.path}/manifest-link')..createSync(manifest.path)).path,
        ]) {
          expect((await run(service: service, path: path)).exitCode, 2);
        }
        expect(calls.existsSync(), isFalse);
        expectCleanup();
      },
    );

    test('$name rejects group and other manifest access', () async {
      for (final mode in ['640', '604']) {
        expect((await Process.run('chmod', [mode, manifest.path])).exitCode, 0);
        expect((await run(service: service)).exitCode, 2);
        expect(calls.existsSync(), isFalse);
        expectCleanup();
      }
    });
  }

  test('retained service requires its binary and isolated state', () async {
    expect(
      (await run(service: true, servicePrerequisites: false)).exitCode,
      isNot(0),
    );
    expect(calls.existsSync(), isFalse);
    expectCleanup();
  });
}
