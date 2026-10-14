import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parity inventory retains surface coverage and Office retirement', () {
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

      'Auto-updates',
      'Full Desktop slash-command catalog',
    ]) {
      expect(text, contains(term), reason: term);
    }
    expect(
      text,
      contains(
        '| Standalone Wing Office | retired in candidate | No Office route, navigation or feature runtime; shared Agent access retained |',
      ),
    );
    expect(text, contains('not a Desktop parity gap'));
    expect(text, contains('Wing-only Office is retirement work'));
    expect(text, contains('../adr/product.md#official-desktop-features-only'));
  });
}
