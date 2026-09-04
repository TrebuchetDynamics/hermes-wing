import 'dart:convert';
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
    expect(workflow, contains('dart run scripts/check_evidence_matrix.dart'));
    final linuxCmake = File('linux/CMakeLists.txt').readAsStringSync();
    expect(linuxCmake, contains('-X main.version='));
    expect(linuxCmake, contains('file(GLOB_RECURSE WING_LINK_GO_SOURCES'));
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

  test(
    'explicit release mode installs the most recent alpha release',
    () async {
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
        ['--release', '--prefix', installDir.path],
        environment: {
          'PATH': '${fakeBin.path}:${Platform.environment['PATH']}',
          'FAKE_WING_LINK': releasedBinary.path,
        },
      );

      expect(install.exitCode, 0, reason: install.stderr as String);
      expect(install.stdout, contains('v1.2.3-alpha.4'));
      expect(File('${installDir.path}/wing-link').existsSync(), isTrue);
    },
  );

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

  test('default mode builds Wing Link then bootstraps Hermes', () async {
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
      '--prefix',
      installDir.path,
    ], environment: environment);

    expect(install.exitCode, 0, reason: install.stderr as String);
    expect(calls.readAsStringSync(), 'setup\n');
    expect(install.stdout, contains('Hermes Agent gateway is running'));
    expect(
      install.stdout,
      contains('Required next step (unless already configured): hermes setup'),
    );

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

  test('installer distinguishes local and remote pairing prerequisites', () {
    final installer = File('install-wing-link.sh').readAsStringSync();

    expect(installer, contains('pair --local --same-device'));
    expect(installer, contains('Android with Tailscale: wing-link pair'));
    expect(installer, contains('WING_HERMES_URL'));
    expect(installer, isNot(contains('then pair Hermes Wing')));
    expect(installer, isNot(contains('allow-external-apps')));
    expect(installer, isNot(contains('com.termux.RUN_COMMAND')));
  });

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

    final oversized = await Process.run('./install-wing-link.sh', [
      '--tag',
      'v1.2.3-alpha.4',
      '--sha256',
      List.filled(64, 'a').join(),
      '--size',
      '52428801',
    ]);
    expect(oversized.exitCode, 2);
    expect(oversized.stderr, contains('50 MiB'));
  });

  test('signed Android artifacts contain canonical Termux metadata', () {
    final workflow = File(
      '.github/workflows/release-alpha.yml',
    ).readAsStringSync();
    final verifier = File(
      'scripts/verify_release_artifacts.sh',
    ).readAsStringSync();
    final defaultMetadata = File(
      'assets/config/termux_bootstrap.json',
    ).readAsStringSync();

    expect(jsonDecode(defaultMetadata), {'available': false});
    expect(workflow, contains('needs: [validation, wing-link]'));
    expect(workflow, contains('name: wing-link-release'));
    expect(workflow, contains('assets/config/termux_bootstrap.json'));
    expect(workflow, contains('50 * 1024 * 1024'));
    expect(
      workflow,
      contains('git ls-remote --exit-code --refs --tags origin'),
    );
    expect(workflow, contains(r'tag_lookup_status=$?'));
    expect(workflow, contains(r'tag_revision" != "$GITHUB_SHA'));
    expect(workflow, contains('Could not verify whether Git tag exists'));
    expect(
      workflow,
      contains('Could not verify whether GitHub release exists'),
    );
    expect(workflow, contains('created_tag=false'));
    expect(workflow, contains('trap cleanup_publish_ref EXIT'));
    expect(
      workflow,
      contains(r'gh api --method POST "repos/$GITHUB_REPOSITORY/git/refs"'),
    );
    expect(workflow, contains(r'-f ref="refs/tags/$TAG"'));
    expect(workflow, contains(r'-f sha="$GITHUB_SHA"'));
    expect(
      workflow,
      contains(
        r'gh api --method DELETE "repos/$GITHUB_REPOSITORY/git/refs/tags/$TAG"',
      ),
    );
    expect(workflow, contains(r'"$created_tag" == true'));
    expect(workflow, contains(r'"$release_status" == 404'));
    expect(workflow, contains('--verify-tag'));
    expect(workflow, contains(r'gh release create "$TAG" dist/*'));
    expect(
      workflow.indexOf(
        r'gh api --method POST "repos/$GITHUB_REPOSITORY/git/refs"',
      ),
      lessThan(workflow.indexOf(r'gh release create "$TAG" dist/*')),
    );
    expect(workflow, isNot(contains(r'--target "$GITHUB_SHA"')));
    expect(workflow, contains('len(installer_bytes) <= 1024 * 1024'));
    expect(workflow, isNot(contains('--dart-define=WING_TERMUX')));
    expect(
      verifier,
      contains('assets/flutter_assets/assets/config/termux_bootstrap.json'),
    );
    expect(verifier, contains('APK and AAB Termux bootstrap metadata differ'));
    expect(verifier, contains('installer_sha256'));
    expect(verifier, contains('len(installer_bytes) <= 1024 * 1024'));
    expect(verifier, contains('asset_sha256'));
  });

  test(
    'Termux setup starts loopback services and prints code-free pairing',
    () async {
      final temp = await Directory.systemTemp.createTemp('wing-link-termux-');
      addTearDown(() => temp.delete(recursive: true));
      final prefix = Directory('${temp.path}/usr')..createSync(recursive: true);
      Directory('${prefix.path}/bin').createSync();
      final home = Directory('${temp.path}/home')..createSync();
      final fakeBin = Directory('${temp.path}/fake-bin')..createSync();
      final calls = File('${temp.path}/calls');
      final health = File('${temp.path}/healthy');
      final identity = File('${temp.path}/identity');
      final releasedBinary = File('${temp.path}/wing-link')
        ..writeAsStringSync('''#!/bin/sh
case "\${1:-}" in
  version) echo 1.2.3-alpha.4 ;;
  setup)
    if [ ! -f "\$WING_LINK_TEST_IDENTITY" ]; then
      printf 'stable-identity\\n' > "\$WING_LINK_TEST_IDENTITY"
      printf 'identity-created\\n' >> "\$WING_LINK_TEST_CALLS"
    fi
    printf 'setup\\n' >> "\$WING_LINK_TEST_CALLS"
    ;;
  serve) printf 'serve %s %s\\n' "\$2" "\$3" >> "\$WING_LINK_TEST_CALLS"; touch "\$WING_LINK_TEST_HEALTH" ;;
  pair) printf 'pair %s %s\\n' "\$2" "\$3" >> "\$WING_LINK_TEST_CALLS" ;;
  *) exit 2 ;;
esac
''');
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
  http://127.0.0.1:8654/healthz) [ -f "\$WING_LINK_TEST_HEALTH" ] ;;
  *wing-link-android-arm64) cp "\$FAKE_WING_LINK" "\$output" ;;
  *) echo "unexpected URL: \$url" >&2; exit 1 ;;
esac
''');
      final nohup = File('${fakeBin.path}/nohup')
        ..writeAsStringSync('#!/bin/sh\nexec "\$@"\n');
      final uname = File('${fakeBin.path}/uname')
        ..writeAsStringSync('''#!/bin/sh
if [ "\${1:-}" = -m ]; then echo aarch64; else echo Linux; fi
''');
      final installer = File('${temp.path}/install-wing-link.sh')
        ..writeAsStringSync(
          File('install-wing-link.sh').readAsStringSync().replaceAll(
            '/data/data/com.termux/files/usr',
            prefix.path,
          ),
        );
      await Process.run('chmod', [
        '+x',
        releasedBinary.path,
        curl.path,
        nohup.path,
        uname.path,
        installer.path,
      ]);
      final digestResult = await Process.run('sha256sum', [
        releasedBinary.path,
      ]);
      final digest = (digestResult.stdout as String).split(' ').first;

      final arguments = [
        '--tag',
        'v1.2.3-alpha.4',
        '--sha256',
        digest,
        '--size',
        '${releasedBinary.lengthSync()}',
        '--setup',
      ];
      final environment = {
        ...Platform.environment,
        'PATH': '${fakeBin.path}:${Platform.environment['PATH']}',
        'HOME': home.path,
        'PREFIX': prefix.path,
        'TERMUX_VERSION': 'test',
        'FAKE_WING_LINK': releasedBinary.path,
        'WING_LINK_TEST_CALLS': calls.path,
        'WING_LINK_TEST_HEALTH': health.path,
        'WING_LINK_TEST_IDENTITY': identity.path,
      };

      final first = await Process.run(
        installer.path,
        arguments,
        environment: environment,
      );
      final second = await Process.run(
        installer.path,
        arguments,
        environment: environment,
      );

      expect(first.exitCode, 0, reason: first.stderr as String);
      expect(second.exitCode, 0, reason: second.stderr as String);
      expect(calls.readAsLinesSync(), [
        'identity-created',
        'setup',
        'serve --listen 127.0.0.1:8654',
        'pair --local --same-device',
        'setup',
        'pair --local --same-device',
      ]);
      expect(identity.readAsStringSync(), 'stable-identity\n');
      expect(calls.readAsStringSync(), isNot(contains('systemctl')));

      final runtimeDir = Directory(
        '${home.path}/.local/state/hermes-wing-link',
      );
      runtimeDir.deleteSync(recursive: true);
      final outsideDir = Directory('${temp.path}/outside-runtime')
        ..createSync();
      Link(runtimeDir.path).createSync(outsideDir.path);
      calls.writeAsStringSync('');
      final linkedDirectory = await Process.run(
        installer.path,
        arguments,
        environment: environment,
      );
      expect(linkedDirectory.exitCode, isNot(0));
      expect(
        linkedDirectory.stderr,
        contains('runtime directory must not be a symlink'),
      );
      expect(calls.readAsLinesSync(), ['setup']);

      Link(runtimeDir.path).deleteSync();
      runtimeDir.createSync(recursive: true);
      final outsideLog = File('${temp.path}/outside.log')..createSync();
      Link('${runtimeDir.path}/wing-link.log').createSync(outsideLog.path);
      calls.writeAsStringSync('');
      final linkedLog = await Process.run(
        installer.path,
        arguments,
        environment: environment,
      );
      expect(linkedLog.exitCode, isNot(0));
      expect(linkedLog.stderr, contains('log file must not be a symlink'));
      expect(calls.readAsLinesSync(), ['setup']);
    },
  );
}
