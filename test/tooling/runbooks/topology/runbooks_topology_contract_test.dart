import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../shared/file_contract_helpers.dart';

void main() {
  test(
    'runbook index, moved runbooks, and root compatibility facades stay valid',
    () {
      final docsIndex = readRequiredFile('docs/README.md');
      for (final snippet in [
        'NAVIVOX_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit',
        'Completion verdict: NOT COMPLETE',
        'do not treat proxy evidence',
        'tests, APK hashes, configured Hermes home, workflow YAML, or dispatch-only output',
      ]) {
        expect(docsIndex, contains(snippet), reason: snippet);
      }

      final expectedRunbooks = [
        'docs/runbooks/hermes-platform-smoke.md',
        'docs/runbooks/hermes-readiness-audit.md',
        'docs/runbooks/termux/gormes-bootstrap.md',
        'docs/runbooks/android/setup-checklist.md',
        'docs/runbooks/android/pairing-handoff-smoke.md',
        'docs/runbooks/android/pairing-handoff-instrumentation.md',
        'docs/runbooks/android/durable-keystore-smoke.md',
        'docs/runbooks/android/live-mic-smoke.md',
        'docs/runbooks/android/release-handoff.md',
        'docs/runbooks/shared/android-device-and-secret-contracts.md',
        'docs/runbooks/shared/pairing-secret-handling.md',
        'docs/runbooks/web-qa/dl-mphmcspi-bb46a2.md',
      ];

      for (final path in expectedRunbooks) {
        expect(File(path).existsSync(), isTrue, reason: '$path should exist');
        final link = path.replaceFirst('docs/', '');
        expect(
          docsIndex,
          contains(']($link)'),
          reason: 'docs index should link $link',
        );
      }

      final compatibilityFacades = <String, String>{
        'docs/runbooks/android-durable-keystore-smoke.md':
            'android/durable-keystore-smoke.md',
        'docs/runbooks/android-pairing-handoff-instrumentation.md':
            'android/pairing-handoff-instrumentation.md',
        'docs/runbooks/android-pairing-handoff-smoke.md':
            'android/pairing-handoff-smoke.md',
        'docs/runbooks/android-release-handoff.md':
            'android/release-handoff.md',
        'docs/runbooks/android-setup-checklist.md':
            'android/setup-checklist.md',
        'docs/runbooks/termux-gormes-bootstrap.md':
            'termux/gormes-bootstrap.md',
        'docs/runbooks/web-qa-dl-mphmcspi-bb46a2.md':
            'web-qa/dl-mphmcspi-bb46a2.md',
      };

      for (final path in expectedRunbooks) {
        final text = File(path).readAsStringSync();
        for (final facadePath in compatibilityFacades.keys) {
          expect(
            text,
            isNot(contains(facadePath)),
            reason:
                '$path should link canonical moved runbooks, not $facadePath',
          );
        }
      }

      for (final entry in compatibilityFacades.entries) {
        final text = File(entry.key).readAsStringSync();
        expect(text, contains('Moved to'));
        expect(text, contains('(${entry.value})'));
      }
    },
  );
}
