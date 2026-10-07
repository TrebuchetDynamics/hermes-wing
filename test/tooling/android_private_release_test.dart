import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('private release handoff is opt-in, isolated, and requires signing', () {
    final source = File('android/app/build.gradle.kts').readAsStringSync();
    final buildTypes = source.substring(source.indexOf('    buildTypes {'));
    final release = RegExp(
      r'release \{([\s\S]*?)\n        \}',
    ).firstMatch(buildTypes)!.group(1)!;

    expect(
      release,
      contains('environmentVariable("WING_PRIVATE_RELEASE_TEST")'),
    );
    expect(release, contains('applicationIdSuffix = ".qa.release"'));
    expect(
      release,
      contains('check(signingConfigs.findByName("release") != null)'),
    );
    expect(
      source,
      contains('applicationId = "com.trebuchetdynamics.hermes.wing"'),
    );
    expect(buildTypes, contains('applicationIdSuffix = ".qa"'));
  });
}
