import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('testing plan points historical draft at active Hermes smoke gates', () {
    final text = File('docs/product/testing-plan.md').readAsStringSync();

    for (final snippet in [
      '## Current Hermes smoke matrix',
      'flutter analyze',
      'flutter test --concurrency=1',
      'flutter build web --release -t lib/main_e2e.dart',
      'npm run hermes:live-smoke',
      'npm run hermes:provider-smoke:local',
      'npm run android:voice-smoke',
      'npm run android:hermes-voice-loop-smoke',
      'npm run android:live-mic-prep',
      '../runbooks/android/live-mic-smoke.md',
      'npm run android:durable-key-smoke',
      'Not whole-goal completion evidence by itself; run strict readiness audit',
      'npm run platform:workflow-smoke',
      'published `Hermes platform smoke` workflow',
      'build/receipts/hermes-platform-workflow.json',
      'current-head Windows/iOS/macOS native-host job and artifact evidence',
      'Workflow YAML or dispatch-only output is not a receipt',
      'npm run hermes:readiness-audit',
      'NAVIVOX_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit',
      'Informational only; strict mode must fail while blockers remain.',
      'Completion verdict: NOT COMPLETE',
      'Android physical-mic, Hermes server-audio, or deferred-surface blockers',
      'must not promote proxy evidence',
      'tests, APK hashes, configured Hermes home, workflow YAML, or dispatch-only output',
    ]) {
      expect(text, contains(snippet), reason: snippet);
    }
  });
}
