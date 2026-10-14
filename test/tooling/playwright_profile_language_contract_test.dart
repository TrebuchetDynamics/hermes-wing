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

    expect(surfaces, contains('Welcome to Hermes Wing'));
    expect(screenshots, contains('Welcome to Hermes Wing'));
    expect(
      surfaces,
      contains(
        'getByRole("button", { name: "Connect to Remote Hermes", exact: true }).click()',
      ),
    );
    expect(surfaces, contains('name: /^Hermes Agent URL/'));
    expect(
      surfaces,
      contains(
        'getByRole("button", { name: "Paste pairing link" })).toHaveCount(0)',
      ),
    );
    expect(surfaces, contains('openConnected(page, "/profiles")'));
    expect(surfaces, contains('Profiles unavailable'));
    expect(surfaces, contains('getByText("New Agent")).toHaveCount(0)'));
    expect(
      surfaces,
      contains(
        'Update Hermes Agent and reconnect this gateway with profile permissions.',
      ),
    );

    for (final stale in [
      'Add gateway or profile',
      'Connect one profile manually',
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
