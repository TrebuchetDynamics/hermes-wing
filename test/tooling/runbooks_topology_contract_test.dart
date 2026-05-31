import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('runbook index, moved runbooks, and root compatibility facades stay valid', () {
    final docsIndex = File('docs/README.md').readAsStringSync();
    final expectedRunbooks = [
      'docs/runbooks/termux/gormes-bootstrap.md',
      'docs/runbooks/android/setup-checklist.md',
      'docs/runbooks/android/pairing-handoff-smoke.md',
      'docs/runbooks/android/pairing-handoff-instrumentation.md',
      'docs/runbooks/android/durable-keystore-smoke.md',
      'docs/runbooks/android/release-handoff.md',
      'docs/runbooks/shared/android-device-and-secret-contracts.md',
      'docs/runbooks/web-qa/dl-mphmcspi-bb46a2.md',
    ];

    for (final path in expectedRunbooks) {
      expect(File(path).existsSync(), isTrue, reason: '$path should exist');
      final link = path.replaceFirst('docs/', '');
      expect(docsIndex, contains(']($link)'), reason: 'docs index should link $link');
    }

    final compatibilityFacades = <String, String>{
      'docs/runbooks/android-durable-keystore-smoke.md': 'android/durable-keystore-smoke.md',
      'docs/runbooks/android-pairing-handoff-instrumentation.md': 'android/pairing-handoff-instrumentation.md',
      'docs/runbooks/android-pairing-handoff-smoke.md': 'android/pairing-handoff-smoke.md',
      'docs/runbooks/android-release-handoff.md': 'android/release-handoff.md',
      'docs/runbooks/android-setup-checklist.md': 'android/setup-checklist.md',
      'docs/runbooks/termux-gormes-bootstrap.md': 'termux/gormes-bootstrap.md',
      'docs/runbooks/web-qa-dl-mphmcspi-bb46a2.md': 'web-qa/dl-mphmcspi-bb46a2.md',
    };

    for (final entry in compatibilityFacades.entries) {
      final text = File(entry.key).readAsStringSync();
      expect(text, contains('Moved to'));
      expect(text, contains('(${entry.value})'));
    }
  });
}
