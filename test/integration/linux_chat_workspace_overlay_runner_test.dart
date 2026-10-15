import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Linux overlay runner rejects incomplete or malformed receipt', () {
    final result = Process.runSync('python3', [
      '-B',
      'integration_test/run_linux_chat_workspace_overlay.py',
      '--self-check',
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('Overlay native receipt self-check passed'));
  });
}
