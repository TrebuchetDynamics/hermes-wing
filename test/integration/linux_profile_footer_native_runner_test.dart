import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../integration_test/support/profile_footer_native_fixture.dart';

void main() {
  test('Linux profile-footer runner rejects incomplete proof', () {
    final result = Process.runSync('python3', [
      '-B',
      'integration_test/run_linux_profile_footer_native.py',
      '--self-check',
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('profile-footer runner self-check passed'));
  });
  testWidgets('Native footer journey oracle runs in widget harness', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final receipt = await runProfileFooterJourney(tester, (size) async {
      tester.view.physicalSize = size;
    });
    expect(receipt['phases'], hasLength(4));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
