import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('alpha releases publish Wing Link for desktop and Termux', () {
    final workflow = File(
      '.github/workflows/release-alpha.yml',
    ).readAsStringSync();

    for (final asset in [
      'wing-link-linux-amd64',
      'wing-link-linux-arm64',
      'wing-link-darwin-amd64',
      'wing-link-darwin-arm64',
      'wing-link-windows-amd64.exe',
      'wing-link-android-arm64',
    ]) {
      expect(workflow, contains(asset));
    }
    expect(workflow, contains('GOOS=android GOARCH=arm64'));
    expect(workflow, contains('-buildmode=pie'));
    expect(workflow, contains('sha256sum wing-link-*'));
    expect(workflow, contains(r'${TAG#$tag_prefix}'));
    expect(workflow, contains(r'=~ ^[0-9]+$'));
    expect(workflow, contains('needs: [android, linux, web, wing-link]'));
    final linuxCmake = File('linux/CMakeLists.txt').readAsStringSync();
    expect(linuxCmake, contains('-X main.version='));
  });

  test('release installer verifies downloads and is transactional', () {
    final installer = File('install-wing-link.sh');
    expect(installer.existsSync(), isTrue);
    expect(File('install-wing-link-release.sh').existsSync(), isFalse);
    final text = installer.readAsStringSync();

    expect(text, contains('--sha256'));
    expect(text, contains('--size'));
    expect(text, contains('wing-link-checksums.sha256'));
    expect(text, contains('sha256sum -c'));
    expect(text, contains('--max-filesize'));
    expect(text, contains('--connect-timeout'));
    expect(text, contains('--max-time'));
    expect(text, contains('run_version_probe'));
    expect(text, contains('trap rollback EXIT'));
    expect(text, contains('wing-link-android-arm64'));
    expect(text, contains(r'${PREFIX}/bin'));
    expect(text, isNot(contains('curl |')));
    expect(text, isNot(contains('wget |')));
  });

  test('installer defaults to the most recent alpha release', () async {
    final temp = await Directory.systemTemp.createTemp('wing-link-release-');
    addTearDown(() => temp.delete(recursive: true));
    final fakeBin = Directory('${temp.path}/bin')..createSync();
    final releasedBinary = File('${temp.path}/wing-link')
      ..writeAsStringSync('#!/bin/sh\nsleep 0.1\necho 1.2.3-alpha.4\n');
    await Process.run('chmod', ['+x', releasedBinary.path]);
    final curl = File('${fakeBin.path}/curl')
      ..writeAsStringSync('''#!/bin/sh
output=''
url=''
while [ "\$#" -gt 0 ]; do
  case "\$1" in
    --output) output="\$2"; shift 2; continue ;;
    http*) url="\$1" ;;
  esac
  shift
done
case "\$url" in
  *api.github.com*) printf '%s\\n' '[{"tag_name":"v1.2.3"},{"tag_name":"v1.2.3-alpha.4"},{"tag_name":"v1.2.3-alpha.3"}]' ;;
  *v1.2.3-alpha.4/wing-link-checksums.sha256)
    printf '%s  wing-link-linux-amd64\\n' "\$(sha256sum "\$FAKE_WING_LINK" | awk '{print \$1}')" > "\$output" ;;
  *v1.2.3-alpha.4/wing-link-linux-amd64) cp "\$FAKE_WING_LINK" "\$output" ;;
  *) echo "unexpected URL: \$url" >&2; exit 1 ;;
esac
''');
    await Process.run('chmod', ['+x', curl.path]);
    final installDir = Directory('${temp.path}/install');

    final install = await Process.run(
      './install-wing-link.sh',
      ['--prefix', installDir.path],
      environment: {
        'PATH': '${fakeBin.path}:${Platform.environment['PATH']}',
        'FAKE_WING_LINK': releasedBinary.path,
      },
    );

    expect(install.exitCode, 0, reason: install.stderr as String);
    expect(install.stdout, contains('v1.2.3-alpha.4'));
    expect(File('${installDir.path}/wing-link').existsSync(), isTrue);
  });

  test('release interruption restores the existing Wing Link', () async {
    final temp = await Directory.systemTemp.createTemp(
      'wing-link-release-signal-',
    );
    addTearDown(() => temp.delete(recursive: true));
    final fakeBin = Directory('${temp.path}/bin')..createSync();
    final releasedBinary = File('${temp.path}/released-wing-link')
      ..writeAsStringSync('#!/bin/sh\necho 1.2.3-alpha.4\n');
    final curl = File('${fakeBin.path}/curl')
      ..writeAsStringSync('''#!/bin/sh
output=''
while [ "\$#" -gt 0 ]; do
  if [ "\$1" = --output ]; then output="\$2"; shift 2; continue; fi
  shift
done
cp "\$FAKE_WING_LINK" "\$output"
''');
    final mv = File('${fakeBin.path}/mv')
      ..writeAsStringSync('''#!/usr/bin/env bash
target_path="\$2"
/bin/mv "\$@"
if [[ "\$target_path" == *.backup.* ]]; then kill -TERM "\$PPID"; fi
''');
    await Process.run('chmod', ['+x', releasedBinary.path, curl.path, mv.path]);
    final digestResult = await Process.run('sha256sum', [releasedBinary.path]);
    final digest = (digestResult.stdout as String).split(' ').first;
    final installDir = Directory('${temp.path}/install')..createSync();
    final destination = File('${installDir.path}/wing-link')
      ..writeAsStringSync('#!/bin/sh\necho predecessor\n');
    await Process.run('chmod', ['+x', destination.path]);

    final install = await Process.run(
      './install-wing-link.sh',
      [
        '--tag',
        'v1.2.3-alpha.4',
        '--sha256',
        digest,
        '--size',
        '${releasedBinary.lengthSync()}',
        '--prefix',
        installDir.path,
      ],
      environment: {
        'PATH': '${fakeBin.path}:${Platform.environment['PATH']}',
        'FAKE_WING_LINK': releasedBinary.path,
      },
    );

    expect(install.exitCode, isNot(0));
    expect(destination.readAsStringSync(), '#!/bin/sh\necho predecessor\n');
    expect(installDir.listSync().map((entry) => entry.path), [
      destination.path,
    ]);
  });

  test('quick setup builds Wing Link then bootstraps Hermes', () async {
    final temp = await Directory.systemTemp.createTemp('wing-link-quick-');
    addTearDown(() => temp.delete(recursive: true));
    final fakeBin = Directory('${temp.path}/bin')..createSync();
    final calls = File('${temp.path}/calls');
    final go = File('${fakeBin.path}/go')
      ..writeAsStringSync('''#!/bin/sh
output=''
while [ "\$#" -gt 0 ]; do
  if [ "\$1" = -o ]; then output="\$2"; break; fi
  shift
done
[ -n "\$output" ] || exit 2
cat > "\$output" <<'SCRIPT'
#!/bin/sh
case "\${1:-}" in
  version) echo 0.1.0-dev+test ;;
  setup)
    printf '%s\\n' setup >> "\$WING_LINK_TEST_CALLS"
    [ "\${WING_LINK_TEST_FAIL_SETUP:-}" != 1 ]
    ;;
  *) exit 2 ;;
esac
SCRIPT
chmod +x "\$output"
''');
    await Process.run('chmod', ['+x', go.path]);
    final installDir = Directory('${temp.path}/install');
    final environment = {
      'PATH': '${fakeBin.path}:${Platform.environment['PATH']}',
      'WING_LINK_TEST_CALLS': calls.path,
    };

    final install = await Process.run('./install-wing-link.sh', [
      '--build',
      '--setup',
      '--prefix',
      installDir.path,
    ], environment: environment);

    expect(install.exitCode, 0, reason: install.stderr as String);
    expect(calls.readAsStringSync(), 'setup\n');
    expect(install.stdout, contains('Hermes runtime is ready'));

    final failedInstallDir = Directory('${temp.path}/failed-install');
    final failedSetup = await Process.run(
      './install-wing-link.sh',
      ['--build', '--setup', '--prefix', failedInstallDir.path],
      environment: {...environment, 'WING_LINK_TEST_FAIL_SETUP': '1'},
    );
    expect(failedSetup.exitCode, 1);
    expect(
      File('${failedInstallDir.path}/wing-link').existsSync(),
      isTrue,
      reason: 'a setup failure must preserve the diagnostic and retry tool',
    );
    expect(failedSetup.stderr, contains('Wing Link remains installed'));
  });

  test('source build reports progress, result, and next step', () async {
    final temp = await Directory.systemTemp.createTemp('wing-link-build-');
    addTearDown(() => temp.delete(recursive: true));

    final install = await Process.run('./install-wing-link.sh', [
      '--build',
      '--prefix',
      temp.path,
    ]);

    expect(install.exitCode, 0, reason: install.stderr as String);
    for (final message in [
      'Wing Link source build',
      '[1/3] Building',
      '[2/3] Validating and installing',
      '[3/3] Verifying',
      'Installed:',
      'Version:',
      'Next:',
    ]) {
      expect(install.stdout, contains(message));
    }
    expect(
      install.stdout,
      matches(RegExp(r'Version:\s+\d+\.\d+\.\d+-dev\+[a-z0-9.]+')),
    );
    expect(install.stdout, isNot(contains('Version:   dev')));
  });

  test('source build probe failure preserves an existing Wing Link', () async {
    final temp = await Directory.systemTemp.createTemp(
      'wing-link-build-rollback-',
    );
    addTearDown(() => temp.delete(recursive: true));
    final fakeBin = Directory('${temp.path}/bin')..createSync();
    final go = File('${fakeBin.path}/go')
      ..writeAsStringSync('''#!/bin/sh
output=''
while [ "\$#" -gt 0 ]; do
  if [ "\$1" = -o ]; then output="\$2"; break; fi
  shift
done
cat > "\$output" <<'SCRIPT'
#!/bin/sh
count=0
[ ! -f "\$WING_LINK_TEST_PROBE_COUNT" ] || count="\$(cat "\$WING_LINK_TEST_PROBE_COUNT")"
count=\$((count + 1))
printf '%s' "\$count" > "\$WING_LINK_TEST_PROBE_COUNT"
[ "\$count" -lt 3 ] || exit 9
echo 0.1.0-dev+test
SCRIPT
chmod +x "\$output"
''');
    await Process.run('chmod', ['+x', go.path]);
    final installDir = Directory('${temp.path}/install')..createSync();
    final destination = File('${installDir.path}/wing-link')
      ..writeAsStringSync('#!/bin/sh\necho predecessor\n');
    final probeCount = File('${temp.path}/probe-count');
    await Process.run('chmod', ['+x', destination.path]);

    final install = await Process.run(
      './install-wing-link.sh',
      ['--build', '--prefix', installDir.path],
      environment: {
        'PATH': '${fakeBin.path}:${Platform.environment['PATH']}',
        'WING_LINK_TEST_PROBE_COUNT': probeCount.path,
      },
    );

    expect(install.exitCode, 9);
    expect(destination.readAsStringSync(), '#!/bin/sh\necho predecessor\n');
  });

  test(
    'source build interruption cannot lose predecessor or adopt candidate',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'wing-link-build-signal-',
      );
      addTearDown(() => temp.delete(recursive: true));
      final fakeBin = Directory('${temp.path}/bin')..createSync();
      final go = File('${fakeBin.path}/go')
        ..writeAsStringSync('''#!/bin/sh
output=''
while [ "\$#" -gt 0 ]; do
  if [ "\$1" = -o ]; then output="\$2"; break; fi
  shift
done
cat > "\$output" <<'SCRIPT'
#!/bin/sh
echo 0.1.0-dev+test
SCRIPT
chmod +x "\$output"
''');
      final mv = File('${fakeBin.path}/mv')
        ..writeAsStringSync('''#!/usr/bin/env bash
source_path="\$1"
target_path="\$2"
/bin/mv "\$@"
if [[ "\${WING_LINK_TEST_SIGNAL_AT:-}" == backup && "\$target_path" == *.backup.* ]]; then
  kill -TERM "\$PPID"
elif [[ "\${WING_LINK_TEST_SIGNAL_AT:-}" == adopt && "\$source_path" == *.new.* ]]; then
  kill -TERM "\$PPID"
fi
''');
      await Process.run('chmod', ['+x', go.path, mv.path]);
      final environment = {
        'PATH': '${fakeBin.path}:${Platform.environment['PATH']}',
      };

      final predecessorDir = Directory('${temp.path}/predecessor')
        ..createSync();
      final predecessor = File('${predecessorDir.path}/wing-link')
        ..writeAsStringSync('#!/bin/sh\necho predecessor\n');
      await Process.run('chmod', ['+x', predecessor.path]);
      final interruptedBackup = await Process.run(
        './install-wing-link.sh',
        ['--build', '--prefix', predecessorDir.path],
        environment: {...environment, 'WING_LINK_TEST_SIGNAL_AT': 'backup'},
      );
      expect(interruptedBackup.exitCode, isNot(0));
      expect(predecessor.readAsStringSync(), '#!/bin/sh\necho predecessor\n');
      expect(predecessorDir.listSync().map((entry) => entry.path), [
        predecessor.path,
      ]);

      final freshDir = Directory('${temp.path}/fresh');
      final interruptedAdoption = await Process.run(
        './install-wing-link.sh',
        ['--build', '--prefix', freshDir.path],
        environment: {...environment, 'WING_LINK_TEST_SIGNAL_AT': 'adopt'},
      );
      expect(interruptedAdoption.exitCode, isNot(0));
      expect(freshDir.listSync(), isEmpty);
    },
  );

  test('source build mode defaults to the Termux prefix and PIE build', () {
    final installer = File('install-wing-link.sh').readAsStringSync();

    expect(installer, contains('--build'));
    expect(installer, contains('TERMUX_VERSION'));
    expect(installer, contains(r'${PREFIX}/bin'));
    expect(installer, contains('-buildmode=pie'));
  });

  test('installer rejects conflicting modes', () async {
    final mixedMode = await Process.run('./install-wing-link.sh', [
      '--build',
      '--tag',
      'v1.2.3-alpha.4',
    ]);
    expect(mixedMode.exitCode, 2);
    expect(mixedMode.stderr, contains('cannot be combined with --build'));

    final mixedDestination = await Process.run('./install-wing-link.sh', [
      '--system',
      '--prefix',
      '/tmp/wing-link',
    ]);
    expect(mixedDestination.exitCode, 2);
    expect(mixedDestination.stderr, contains('cannot be combined'));

    final termuxSetup = await Process.run(
      './install-wing-link.sh',
      ['--setup'],
      environment: {
        ...Platform.environment,
        'TERMUX_VERSION': 'test',
        'PREFIX': '/data/data/com.termux/files/usr',
      },
    );
    expect(termuxSetup.exitCode, 2);
    expect(
      termuxSetup.stderr,
      contains('guided Termux hosting is not yet qualified'),
    );
  });
}
