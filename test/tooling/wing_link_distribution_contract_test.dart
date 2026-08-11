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

  test(
    'release installer requires out-of-band digest and is transactional',
    () {
      final installer = File('install-wing-link-release.sh');
      expect(installer.existsSync(), isTrue);
      final text = installer.readAsStringSync();

      expect(text, contains('--sha256'));
      expect(text, contains('--size'));
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
    },
  );

  test('source installer defaults to the Termux prefix and PIE build', () {
    final installer = File('install-wing-link.sh').readAsStringSync();

    expect(installer, contains('TERMUX_VERSION'));
    expect(installer, contains(r'${PREFIX}/bin'));
    expect(installer, contains('-buildmode=pie'));
  });
}
