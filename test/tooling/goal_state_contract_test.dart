import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GOAL_STATE preserves Hermes readiness caveats and blockers', () {
    final text = File('GOAL_STATE.md').readAsStringSync();

    for (final snippet in [
      'Active goal: **become a Hermes Agent mobile app with continuous voice\nsupport**',
      '**1016 tests pass**',
      'The current APK SHA-256 is\n  printed by `npm run hermes:readiness-audit`',
      'the hash\n  is artifact identity only',
      'docs/runbooks/android/live-mic-smoke.md',
      'scripts/audit_hermes_readiness.sh',
      'npm run hermes:readiness-audit',
      'contract suite (27 pass)',
      'Strict readiness now treats the automated Android\n   voice-loop receipt as deterministic no-human loop coverage only',
      'human-spoken physical mic ship gate remains open',
      'Provider-backed Hermes text plus deterministic transcript voice is covered',
      'Completion verdict: NOT COMPLETE',
      'Android physical-mic, Hermes server-audio, deferred-surface\n   blocker(s) remain',
      'adds `receipt` to the\n   verdict only when provider/automated/platform receipts are stale or missing',
      '`gh workflow list` shows `Hermes platform smoke`',
      'platform:workflow-smoke` now dispatches/watches the published `Hermes platform\n   smoke` workflow',
      'warning not to promote proxy',
      'tests, APK\n   hashes, configured Hermes home, workflow YAML',
      'The source of truth is the refreshed current-head\n  `build/receipts/hermes-platform-workflow.json`',
      'successful Windows desktop, iOS simulator, and macOS\n  desktop jobs/artifacts',
      'Android live-mic runbook, plus the Android voice-readiness',
      'strict readiness audit after future Android receipts',
      'not\n   to promote a single Android helper receipt or proxy evidence',
      'KVM-backed `fractal_test` launch became\n   responsive long enough for `npm run android:voice-smoke`',
      '`npm run android:live-mic-prep` to pass',
      'install/launch/mic-grant\n   prep',
      'That remains readiness and deterministic\n   transcript/TTS loop evidence only',
      'Hermes home presence remains informational only',
      'redacted error details sheet with copy-to-clipboard support for connect and\n   in-chat failures',
      'surface-readiness dialog can copy a bounded summary',
      'copy action for bounded/redacted approval\n   details',
      'copy actions for bounded/redacted session and job details',
      'require an explicit physical Android device observation',
      'reject emulator targets for the final live-mic receipt',
      'Real spoken Android microphone smoke',
      'Windows, iOS, and macOS host-platform runner evidence is now captured by\n  `build/receipts/hermes-platform-workflow.json`',
      'The platform workflow is published and visible remotely as `Hermes platform\n  smoke`',
      'Hermes realtime/server audio',
      'not-whole-goal-completion caveats',
      'Provider-backed Hermes web text and transcript-voice smoke now passes',
      'still does not prove physical microphone\ncapture or Hermes realtime/server audio',
      'not real spoken-audio\nreceipts',
    ]) {
      expect(text, contains(snippet), reason: snippet);
    }
  });
}
