import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parity inventory names every requested Desktop surface', () {
    final text = File(
      'docs/product/hermes-desktop-parity.md',
    ).readAsStringSync();
    for (final term in const [
      'Skills/Discover',
      'Memory',
      'Saved models',
      'Schedule create/edit',
      'Messaging gateway administration',
      'Toolset enable/disable',
      'Standalone Soul/persona',
      'Kanban/task planning',
      'Backup/import',
      'Account/OAuth',
      'SSH/Docker/WSL',
      'Web preview',
      'Office 3D',
      'Auto-updates',
      'Full Desktop slash-command catalog',
    ]) {
      expect(text, contains(term), reason: term);
    }
  });
}
