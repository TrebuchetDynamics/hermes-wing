import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../integration_test/support/profile_footer_native_fixture.dart';
import '../shared/widgets/app_shell_navigation_groups_test.dart' as navigation;
import '../shared/widgets/app_shell_profile_footer_test.dart' as footer;

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
  testWidgets('Painted footer oracle rejects a missing focus indicator', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1280, 720);
    await footer.pumpFooter(
      tester,
      footer.DisplayChannel(footer.displayState()),
    );
    await navigation.reach(tester, footer.manage);
    await tester.pump(const Duration(milliseconds: 350));
    expect(
      await expectPaintedProfileFooterFocus(tester),
      greaterThanOrEqualTo(24),
    );
    await navigation.reach(tester, find.bySemanticsLabel('Settings'));
    await tester.pump(const Duration(milliseconds: 350));
    await expectLater(
      expectPaintedProfileFooterFocus(tester),
      throwsA(isA<TestFailure>()),
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Native footer journey oracle runs in widget harness', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final receipt = await runProfileFooterJourney(tester, (size) async {
      tester.view.physicalSize = size;
    });
    expect(receipt['phases'], hasLength(4));
    expect(receipt['recovery'], hasLength(4));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
