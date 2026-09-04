import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'release evidence and CI gates verify emitted bytes and failures',
    () async {
      final result = await Process.run('node', [
        '--test',
        'test/tooling/release_evidence_test.mjs',
        'test/tooling/record_release_qualification_test.mjs',
        'test/tooling/linux_service_qualification_test.mjs',
        'test/tooling/ci_gate_test.mjs',
        'test/tooling/ci_test_receipt_test.mjs',
        'test/tooling/platform_artifact_identity_test.mjs',
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
  );

  test('release publication binds every downloaded smoke receipt', () {
    final workflow = File(
      '.github/workflows/release-alpha.yml',
    ).readAsStringSync();
    final publication = workflow.substring(workflow.indexOf('  publish:\n'));
    expect(publication, contains('- release-readiness'));
    expect(
      publication.indexOf('release_evidence.mjs aggregate dist'),
      greaterThan(publication.indexOf('pattern: "*-smoke-receipt"')),
    );
    expect(
      publication.indexOf('gh release create'),
      greaterThan(publication.indexOf('release_evidence.mjs aggregate dist')),
    );
    for (final target in ['android', 'linux', 'web', 'wing-link']) {
      expect(workflow, contains('release_evidence.mjs emit $target .'));
      expect(workflow, contains('$target-release-evidence.json'));
    }
  });

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
    expect(verifier, contains('required.is_symlink()'));
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
      environment: {
        'WING_RELEASE_CERT_SHA256': '00',
        'GITHUB_SHA': List.filled(40, 'a').join(),
      },
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
    expect(workflow, contains('node scripts/ci_test_receipt.mjs'));
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
        r'      - release-readiness\n'
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

  test('existing release fails while an exact orphan tag can recover', () {
    final workflow = File(
      '.github/workflows/release-alpha.yml',
    ).readAsStringSync();

    final validation = workflow.substring(
      workflow.indexOf('Validate tag against app version'),
      workflow.indexOf('  android:\n'),
    );
    expect(validation, contains('releases/tags/\$TAG'));
    expect(validation, contains('Release already exists: \$TAG'));
    expect(validation, contains(r'tag_revision" != "$GITHUB_SHA'));
    expect(
      validation,
      contains('Could not verify whether GitHub release exists'),
    );
    expect(validation, isNot(contains('Git tag already exists')));
    expect(workflow, contains('trap cleanup_publish_ref EXIT'));
    expect(workflow, contains(r'"$created_tag" == true'));
    expect(workflow, contains(r'"$current_revision" == "$GITHUB_SHA'));
    expect(workflow, contains(r'"$release_status" == 404'));
  });
}
