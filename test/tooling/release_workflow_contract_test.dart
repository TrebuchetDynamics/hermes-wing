import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release workflow actions are pinned to immutable commits', () {
    final workflow = File(
      '.github/workflows/release-alpha.yml',
    ).readAsStringSync();
    final actionReferences = RegExp(
      r'uses:\s+[^\s@]+@([^\s#]+)',
    ).allMatches(workflow);

    expect(actionReferences, isNotEmpty);
    for (final reference in actionReferences) {
      expect(
        reference.group(1),
        matches(RegExp(r'^[0-9a-f]{40}$')),
        reason: reference.group(0),
      );
    }
  });

  test('release verifier rejects unsafe or incomplete artifacts', () async {
    final verifier = File(
      'scripts/verify_release_artifacts.sh',
    ).readAsStringSync();
    expect(verifier, contains('APK must have exactly one signing certificate'));
    expect(verifier, contains('AAB must have exactly one signing certificate'));
    expect(verifier, contains('MAX_MEMBERS'));
    expect(verifier, contains('MAX_EXPANDED_BYTES'));
    expect(verifier, contains('unsafe archive entry type'));
    expect(verifier, contains('hard links are not allowed'));
    expect(verifier, contains('duplicate archive path'));
    expect(
      verifier,
      contains('checksum manifest does not exactly cover expected artifacts'),
    );
    expect(verifier, contains('AAB contains unsigned payload entries'));
    expect(verifier, contains("jarsigner -verify -verbose"));

    if (Platform.isWindows) return;
    final temp = await Directory.systemTemp.createTemp(
      'wing-release-verifier-',
    );
    addTearDown(() => temp.delete(recursive: true));

    final result = await Process.run(
      'bash',
      ['scripts/verify_release_artifacts.sh', temp.path, 'v0.1.0-alpha.1'],
      environment: {'WING_RELEASE_CERT_SHA256': '00'},
    );

    expect(result.exitCode, 1);
    expect(result.stderr, contains('does not match the allowlist'));
  });

  test('alpha artifacts require repository validation', () {
    final workflow = File(
      '.github/workflows/release-alpha.yml',
    ).readAsStringSync();

    expect(workflow, contains('  validation:\n'));
    expect(
      workflow,
      contains('dart format --output=none --set-exit-if-changed'),
    );
    expect(workflow, contains('flutter analyze'));
    expect(workflow, contains('flutter test --coverage --concurrency=1'));
    expect(workflow, contains('npm audit --audit-level=high'));
    expect(
      RegExp(r'  android:\n(?:.|\n)*?    needs: validation').hasMatch(workflow),
      isTrue,
    );
    expect(
      RegExp(r'  linux:\n(?:.|\n)*?    needs: validation').hasMatch(workflow),
      isTrue,
    );
  });

  test('alpha release publishes signed Android install formats', () {
    final workflow = File(
      '.github/workflows/release-alpha.yml',
    ).readAsStringSync();

    expect(workflow, contains('flutter build apk --release'));
    expect(workflow, contains('flutter build appbundle --release'));
    expect(workflow, contains('hermes-wing-android.apk.sha256'));
    expect(workflow, contains('hermes-wing-android.aab.sha256'));
    expect(workflow, contains('hermes-wing-android.apk\n'));
    expect(workflow, contains('hermes-wing-android.aab\n'));
  });

  test('exact artifacts are verified and smoked before publication', () {
    final workflow = File(
      '.github/workflows/release-alpha.yml',
    ).readAsStringSync();

    expect(
      RegExp(
        r'  verify-artifacts:\n(?:.|\n)*?    needs: \[android, linux, web, wing-link\]',
      ).hasMatch(workflow),
      isTrue,
    );
    expect(
      workflow,
      contains(r'./scripts/verify_release_artifacts.sh dist "$TAG"'),
    );
    expect(workflow, contains('name: hermes-wing-verified-release'));
    expect(workflow, contains('  android-artifact-smoke:\n'));
    expect(workflow, contains(r'test "${#actual_signers[@]}" -eq 1'));
    expect(workflow, contains('adb install hermes-wing-android.apk'));
    expect(
      workflow,
      contains('com.trebuchetdynamics.hermes.wing/.MainActivity'),
    );
    expect(workflow, contains('  wing-link-macos-smoke:\n'));
    expect(workflow, contains('  wing-link-windows-smoke:\n'));
    expect(workflow, contains('android-artifact-smoke-receipt'));
    expect(workflow, contains('wing-link-macos-smoke-receipt'));
    expect(workflow, contains('wing-link-windows-smoke-receipt'));
    expect(
      RegExp(
        r'wing-link-checksums\.sha256(?:.|\n)*?'
        r'checksum manifest does not exactly cover expected artifacts',
      ).allMatches(workflow),
      hasLength(3),
    );
    expect(
      RegExp(
        r'  publish:\n(?:.|\n)*?    needs:\n'
        r'      - verify-artifacts\n'
        r'      - android-artifact-smoke\n'
        r'      - wing-link-macos-smoke\n'
        r'      - wing-link-windows-smoke',
      ).hasMatch(workflow),
      isTrue,
    );
    expect(
      workflow.indexOf('verify_release_artifacts.sh'),
      lessThan(workflow.indexOf('gh release create')),
    );
  });

  test('alpha release publishes the tested web build', () {
    final workflow = File(
      '.github/workflows/release-alpha.yml',
    ).readAsStringSync();

    expect(
      RegExp(r'  web:\n(?:.|\n)*?    needs: validation').hasMatch(workflow),
      isTrue,
    );
    expect(workflow, contains('flutter build web --release'));
    expect(workflow, contains('hermes-wing-web.tar.gz.sha256'));
    expect(workflow, contains('name: hermes-wing-verified-release'));
  });

  test('alpha tag matches the app version before platform builds', () {
    final workflow = File(
      '.github/workflows/release-alpha.yml',
    ).readAsStringSync();

    final versionCheck = workflow.indexOf('Validate tag against app version');
    expect(versionCheck, greaterThan(0));
    expect(versionCheck, lessThan(workflow.indexOf('  android:\n')));
    expect(
      workflow,
      contains(r"awk '/^version:/{print $2; exit}' pubspec.yaml"),
    );
    expect(workflow, contains(r'app_version=${app_version%%+*}'));
    expect(workflow, contains(r'tag_prefix="v${app_version}-alpha."'));
    expect(workflow, contains(r'tag_suffix=${TAG#$tag_prefix}'));
    expect(workflow, contains(r'"$tag_suffix" =~ ^[0-9]+$'));
  });

  test('existing alpha release fails before platform builds', () {
    final workflow = File(
      '.github/workflows/release-alpha.yml',
    ).readAsStringSync();

    final duplicateCheck = workflow.indexOf('gh release view');
    expect(duplicateCheck, greaterThan(0));
    expect(duplicateCheck, lessThan(workflow.indexOf('  android:\n')));
    expect(workflow.lastIndexOf('gh release view'), duplicateCheck);
  });
}
