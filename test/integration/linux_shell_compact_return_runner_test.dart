import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Linux compact-return runner rejects malformed and missing proof', () {
    final result = Process.runSync('python3', [
      '-B',
      'integration_test/run_linux_shell_compact_return.py',
      '--self-check',
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(
      result.stdout,
      contains('shell-compact-return runner self-check passed'),
    );
  });
}
