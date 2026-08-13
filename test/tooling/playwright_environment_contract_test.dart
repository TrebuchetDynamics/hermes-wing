import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('specialized browser specs fail closed outside their environments', () {
    final pages = File(
      'playwright/tests/regression/pages-landing.spec.mjs',
    ).readAsStringSync();
    final release = File(
      'playwright/tests/regression/release-artifact.spec.mjs',
    ).readAsStringSync();

    expect(
      pages,
      matches(RegExp(r'test\.skip\(\s*!process\.env\.PAGES_BASE_URL')),
      reason: 'Pages smoke requires the Pages artifact server',
    );
    expect(
      release,
      matches(
        RegExp(r'test\.skip\(\s*!process\.env\.RELEASE_ARTIFACT_BASE_URL'),
      ),
      reason: 'release smoke requires an extracted release artifact server',
    );
  });
}
