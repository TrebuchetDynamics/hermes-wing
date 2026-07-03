import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GOAL_STATE preserves Hermes readiness caveats and blockers', () {
    final text = File('GOAL_STATE.md').readAsStringSync();

    for (final snippet in [
      'Active goal: **become a Hermes Agent mobile app with continuous voice\nsupport**',
      '**1016 tests pass**',
      '453e746d9773b466a7393ec73713943a49276f4bee4465d18a3d083e5cb5ab0a',
      'The APK hash is artifact identity only',
      'docs/runbooks/android/live-mic-smoke.md',
      'scripts/audit_hermes_readiness.sh',
      'npm run hermes:readiness-audit',
      'contract suite (27 pass)',
      'Strict readiness audit now reports 16 blockers',
      'full live provider-backed chat/voice smoke is an explicit closeout blocker',
      'Completion verdict: NOT COMPLETE',
      'not to promote proxy evidence',
      'tests, APK hashes, configured\n   Hermes home, workflow YAML, or dispatch-only output',
      'direct native-host reprobes on this Linux host still fail',
      'flutter build windows --debug` exits 1',
      'flutter build ios --simulator --debug` exits 64',
      'Android live-mic and durable\n   reconnect runbooks, plus the Android voice-readiness, deterministic',
      'voice-loop, durable-key, and live-mic-prep helpers',
      'strict readiness audit after future Android receipts',
      'not\n   to promote a single Android/reconnect/helper receipt or proxy evidence',
      'KVM-backed `fractal_test` launch became responsive long enough for\n   `npm run android:voice-smoke`, `npm run android:hermes-voice-loop-smoke`,',
      '`npm run android:durable-key-smoke`, and `npm run android:live-mic-prep` to',
      'install/launch/mic-grant prep',
      'That remains readiness,\n   deterministic transcript/TTS loop, and key-storage evidence only',
      'home presence is informational only, not a provider-smoke receipt',
      'Real spoken Android microphone smoke',
      'Windows and iOS/macOS host-platform builds/smokes still need successful native\n  host-runner receipts',
      'Real Android + real Gormes durable reconnect still needs end-to-end validation',
      'Hermes realtime/server audio',
      'not-whole-goal-completion\n   caveats',
      'Provider-backed Hermes web text and transcript-voice smoke now passes',
      'still does not prove physical microphone\ncapture or Hermes realtime/server audio',
      'not real spoken-audio\nreceipts',
    ]) {
      expect(text, contains(snippet), reason: snippet);
    }
  });
}
