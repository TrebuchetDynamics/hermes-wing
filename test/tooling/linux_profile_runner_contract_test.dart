import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late File manifest;
  late File calls;

  setUp(() async {
    root = Directory.systemTemp.createTempSync('linux-profile-runner-');
    Directory('${root.path}/scripts').createSync();
    File(
      'scripts/run_linux_live_e2e.sh',
    ).copySync('${root.path}/scripts/run_linux_live_e2e.sh');
    manifest = File('${root.path}/agent manifest.json')
      ..writeAsStringSync('[{"token":"non-secret-fixture-marker"}]');
    calls = File('${root.path}/calls');
    final flutter = File('${root.path}/flutter')
      ..writeAsStringSync('''#!/bin/bash
printf '%s\\n' "\$@" > "\$CALLS"
[[ -f "\$WING_LIVE_PROFILE_MANIFEST" ]] || exit 98
[[ -z "\${WING_LIVE_LINK_MANIFEST+x}" && -z "\${WING_LIVE_LINK_BINARY+x}" && -z "\${WING_LINK_STATE+x}" ]] || exit 99
exit "\${FAKE_EXIT:-0}"
''');
    final xvfb = File('${root.path}/xvfb-run')
      ..writeAsStringSync('''#!/bin/bash
printf '%s\\n' "\$1" > "\$XVFB_CALLS"
shift
exec "\$@"
''');
    for (final file in [flutter, xvfb]) {
      expect((await Process.run('chmod', ['700', file.path])).exitCode, 0);
    }
    expect((await Process.run('chmod', ['600', manifest.path])).exitCode, 0);
  });

  tearDown(() => root.deleteSync(recursive: true));

  Future<ProcessResult> run({
    String? path,
    bool missing = false,
    String display = ':fixture',
    int exitCode = 0,
  }) => Process.run(
    '/bin/bash',
    ['${root.path}/scripts/run_linux_live_e2e.sh'],
    includeParentEnvironment: false,
    environment: {
      'PATH': '${root.path}:/usr/bin:/bin',
      'DISPLAY': display,
      'CALLS': calls.path,
      'XVFB_CALLS': '${root.path}/xvfb-calls',
      'FAKE_EXIT': '$exitCode',
      if (!missing) 'WING_LIVE_PROFILE_MANIFEST': path ?? manifest.path,
    },
  );

  test('Agent manifest alone invokes only the surviving journey', () async {
    final result = await run();
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(calls.readAsLinesSync(), [
      'test',
      '-d',
      'linux',
      'integration_test/linux_real_profiles_e2e_test.dart',
      '--reporter',
      'expanded',
    ]);
    expect(
      calls.readAsStringSync(),
      isNot(contains('non-secret-fixture-marker')),
    );
    expect(calls.readAsStringSync(), isNot(contains(manifest.path)));
    expect(File('${root.path}/xvfb-calls').existsSync(), isFalse);
  });

  test('propagates the exact Flutter failure', () async {
    expect((await run(exitCode: 37)).exitCode, 37);
    expect(calls.existsSync(), isTrue);
  });

  test('headless mode uses the wrapper and preserves failure', () async {
    expect((await run(display: '', exitCode: 41)).exitCode, 41);
    expect(File('${root.path}/xvfb-calls').readAsLinesSync(), ['-a']);
    expect(calls.existsSync(), isTrue);
  });

  test('missing or absent manifest fails before Flutter', () async {
    expect((await run(missing: true)).exitCode, isNot(0));
    expect((await run(path: '${root.path}/absent')).exitCode, 2);
    expect(calls.existsSync(), isFalse);
  });

  test('directory and symlink manifests fail before Flutter', () async {
    expect((await run(path: root.path)).exitCode, 2);
    final link = Link('${root.path}/manifest-link')..createSync(manifest.path);
    expect((await run(path: link.path)).exitCode, 2);
    expect(calls.existsSync(), isFalse);
  });

  test('group or other permissions fail before Flutter', () async {
    for (final mode in ['640', '604']) {
      expect((await Process.run('chmod', [mode, manifest.path])).exitCode, 0);
      expect((await run()).exitCode, 2);
      expect(calls.existsSync(), isFalse);
    }
  });
}
