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
      'Strict readiness audit now reports 15 blockers',
      'full live provider-backed chat/voice smoke is an explicit closeout blocker',
      'Completion verdict: NOT COMPLETE',
      'current OAuth\n   app token lacks GitHub `workflow` scope',
      'two local commits remain\n   ahead of `origin/main`',
      'not to promote proxy evidence',
      'tests, APK hashes, configured\n   Hermes home, workflow YAML, or dispatch-only output',
      'direct native-host reprobes on this Linux host still fail',
      'flutter build windows --debug` exits 1',
      'flutter build ios --simulator --debug` exits 64',
      'flutter build macos` exits 64',
      'Android live-mic runbook, plus\n   the Android voice-readiness, deterministic voice-loop, and live-mic-prep',
      'strict readiness audit after future Android\n   receipts',
      'not to promote a single Android helper receipt\n   or proxy evidence',
      'KVM-backed `fractal_test` launch became responsive long enough for\n   `npm run android:voice-smoke`, `npm run android:hermes-voice-loop-smoke`,',
      'and `npm run android:live-mic-prep` to pass',
      'install/launch/mic-grant\n   prep',
      'That remains readiness and deterministic\n   transcript/TTS loop evidence only',
      'home presence is informational only, not a provider-smoke receipt',
      'Real spoken Android microphone smoke',
      'Windows, iOS, and macOS host-platform build artifacts now exist on failed\n  workflow run `28714769601`',
      'The platform workflow is now published and visible remotely as `Hermes platform\n  smoke`',
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
