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
      '[2/3] Installing',
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
  });
}
