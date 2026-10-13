import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late File manifest;
  late File calls;

  setUp(() async {
    root = Directory.systemTemp.createTempSync('linux-feature-runner-');
    Directory('${root.path}/scripts').createSync();
    for (final name in ['features']) {
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
  [[ -f "\$WING_LIVE_PROFILE_MANIFEST" ]] || exit 99
  [[ -z "\${WING_LIVE_LINK_MANIFEST+x}" && -z "\${WING_LIVE_LINK_BINARY+x}" && -z "\${WING_LINK_STATE+x}" && -z "\${WING_LIVE_DIRECTORY_ROOT+x}" ]] || exit 99
  [[ ! -e "\$WING_LINUX_TEST_ROOT/grant-root" ]] || exit 99
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
    int exitCode = 0,
    int wrapperExit = 0,
  }) => Process.run(
    '/bin/bash',
    ['${root.path}/scripts/run_linux_live_features_e2e.sh'],
    includeParentEnvironment: false,
    environment: {
      'PATH': '${root.path}:/usr/bin:/bin',
      'TMPDIR': root.path,
      'CALLS': calls.path,
      'ROOTS': '${root.path}/roots',
      'FAKE_EXIT': '$exitCode',
      'WRAPPER_EXIT': '$wrapperExit',
      if (!missing) 'WING_LIVE_PROFILE_MANIFEST': path ?? manifest.path,
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

  test('Agent-only admission preserves setup and cleanup', () async {
    final result = await run();
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(calls.readAsLinesSync(), [
      'test',
      '-d',
      'linux',
      'integration_test/linux_live_feature_journeys_test.dart',
      '--reporter',
      'expanded',
    ]);
    final roots = File('${root.path}/roots').readAsLinesSync();
    expect(roots, hasLength(2));
    expect(roots.first, startsWith('${root.path}/wing-linux-coverage.'));
    expect(roots.last, '${roots.first}/config');
    expectCleanup();
  });

  test('Agent-only preserves exact Flutter and wrapper failures', () async {
    expect((await run(exitCode: 37)).exitCode, 37);
    expect(calls.existsSync(), isTrue);
    expectCleanup();
    calls.deleteSync();
    expect((await run(wrapperExit: 41)).exitCode, 41);
    expect(calls.existsSync(), isFalse);
    expectCleanup();
  });

  test(
    'Agent-only rejects missing, absent, directory and symlink manifests',
    () async {
      expect((await run(missing: true)).exitCode, isNot(0));
      for (final path in [
        '${root.path}/absent',
        root.path,
        (Link('${root.path}/manifest-link')..createSync(manifest.path)).path,
      ]) {
        expect((await run(path: path)).exitCode, 2);
      }
      expect(calls.existsSync(), isFalse);
      expectCleanup();
    },
  );

  test('Agent-only rejects group and other manifest access', () async {
    for (final mode in ['640', '604']) {
      expect((await Process.run('chmod', [mode, manifest.path])).exitCode, 0);
      expect((await run()).exitCode, 2);
      expect(calls.existsSync(), isFalse);
      expectCleanup();
    }
  });
}
