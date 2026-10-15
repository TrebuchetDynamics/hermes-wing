import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Linux Persona runner rejects missing or malformed journey proof', () {
    final result = Process.runSync('python3', [
      '-B',
      'integration_test/run_linux_persona_conflict.py',
      '--self-check',
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('Persona native receipt self-check passed'));
  });
}
