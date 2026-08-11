import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
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
    expect(workflow, contains('needs: [android, linux, web, wing-link]'));
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
