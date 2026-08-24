import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('browser surfaces use canonical profile terminology', () {
    final surfaces = File(
      'playwright/tests/regression/browser-surfaces.spec.mjs',
    ).readAsStringSync();
    final screenshots = File(
      'playwright/tests/screenshots/e2e-screenshots.spec.mjs',
    ).readAsStringSync();

    expect(surfaces, contains('Add gateway or profile'));
    expect(screenshots, contains('Add gateway or profile'));
    expect(surfaces, contains('No Hermes profiles available'));
    expect(surfaces, contains('openConnected(page, "/profiles")'));
    expect(surfaces, contains('Profiles unavailable'));
    expect(surfaces, contains('Connect one profile manually'));

    for (final stale in [
      'Add gateway or agent',
      'No Hermes agents available',
      'openConnected(page, "/agents")',
      'Agents unavailable',
      'Scan QR code',
    ]) {
      expect(surfaces, isNot(contains(stale)));
      expect(screenshots, isNot(contains(stale)));
    }
  });
}
