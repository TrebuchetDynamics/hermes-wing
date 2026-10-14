import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Linux persistence runner rejects incomplete or mutating receipts', () {
    final result = Process.runSync('python3', [
      '-B',
      'integration_test/run_linux_shell_persistence.py',
      '--self-check',
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout,
      contains('shell-persistence runner self-check passed'),
    );
  });
}
