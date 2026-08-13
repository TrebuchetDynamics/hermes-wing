import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default web e2e isolates browser suites by spec file', () {
    final runner = File('playwright/scripts/run_tests.sh').readAsStringSync();

    for (final spec in [
      'browser-surfaces.spec.mjs',
      'chat-tts.spec.mjs',
      'hermes-lifecycle.spec.mjs',
      'hermes-live-say-hi.spec.mjs',
      'hermes-smoke.spec.mjs',
      'e2e-screenshots.spec.mjs',
    ]) {
      expect(runner, contains(spec));
    }
    expect(
      runner,
      isNot(
        contains('npx playwright test --config=playwright.config.mjs 2>&1'),
      ),
      reason: 'bare discovery retains one browser process across every suite',
    );
  });
}
