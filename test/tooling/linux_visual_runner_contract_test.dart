import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late File manifest;
  late File calls;

  setUp(() async {
    root = Directory.systemTemp.createTempSync('linux-visual-runner-');
    Directory('${root.path}/scripts').createSync();
    File(
      'scripts/run_linux_live_visual.sh',
    ).copySync('${root.path}/scripts/run_linux_live_visual.sh');
    manifest = File('${root.path}/agent manifest.json')
      ..writeAsStringSync('[{"token":"non-secret-fixture-marker"}]');
    calls = File('${root.path}/calls');
    final wrappers = {
      'dbus-run-session': '[[ "\$1" == -- ]] || exit 97; shift; exec "\$@"',
      'xvfb-run': 'shift 3; exec "\$@"',
      'gnome-keyring-daemon':
          'while read -r line; do :; done; exit "\${KEYRING_EXIT:-0}"',
      'findmnt': 'exit 1',
      'flutter': '''printf '%s\\n' "\$@" > "\$CALLS"
printf '%s\\n' "\$XDG_CONFIG_HOME" "\$XDG_DATA_HOME" "\$XDG_CACHE_HOME" "\$XDG_RUNTIME_DIR" > "\$ROOTS"
[[ -f "\$WING_LIVE_PROFILE_MANIFEST" ]] || exit 98
[[ -z "\${WING_LIVE_LINK_MANIFEST+x}" && -z "\${WING_LIVE_LINK_BINARY+x}" ]] || exit 99
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
    int keyringExit = 0,
  }) => Process.run(
    '/bin/bash',
    ['${root.path}/scripts/run_linux_live_visual.sh'],
    includeParentEnvironment: false,
    environment: {
      'PATH': '${root.path}:/usr/bin:/bin',
      'TMPDIR': root.path,
      'CALLS': calls.path,
      'ROOTS': '${root.path}/roots',
      'FAKE_EXIT': '$exitCode',
      'KEYRING_EXIT': '$keyringExit',
      'WING_VISUAL_OUTPUT': '${root.path}/output',
      if (!missing) 'WING_LIVE_PROFILE_MANIFEST': path ?? manifest.path,
    },
  );

  test(
    'Agent-only admission preserves isolated storage and teardown',
    () async {
      final result = await run();
      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(calls.readAsLinesSync(), [
        'test',
        '-d',
        'linux',
        'integration_test/linux_live_visual_test.dart',
        '--reporter',
        'expanded',
      ]);
      expect(calls.readAsStringSync(), isNot(contains(manifest.path)));
      expect(
        calls.readAsStringSync(),
        isNot(contains('non-secret-fixture-marker')),
      );
      final roots = File('${root.path}/roots').readAsLinesSync();
      expect(roots, hasLength(4));
      expect(roots.toSet(), hasLength(4));
      for (final path in roots) {
        expect(path, startsWith('${root.path}/wing-visual-keyring.'));
        expect(Directory(path).existsSync(), isFalse);
      }
    },
  );

  test('exact Flutter failure survives wrappers and teardown', () async {
    expect((await run(exitCode: 37)).exitCode, 37);
    expect(calls.existsSync(), isTrue);
  });

  test('keyring failure stops before Flutter', () async {
    expect((await run(keyringExit: 41)).exitCode, 41);
    expect(calls.existsSync(), isFalse);
  });

  test(
    'missing, absent, directory and symlink manifests fail closed',
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
      expect(Directory('${root.path}/output').existsSync(), isFalse);
    },
  );

  test('group or other access fails before external wrappers', () async {
    for (final mode in ['640', '604']) {
      expect((await Process.run('chmod', [mode, manifest.path])).exitCode, 0);
      expect((await run()).exitCode, 2);
      expect(calls.existsSync(), isFalse);
    }
  });
}
