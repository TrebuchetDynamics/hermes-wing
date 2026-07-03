import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Hermes platform smoke runbook preserves host and voice boundaries', () {
    final text = File(
      'docs/runbooks/hermes-platform-smoke.md',
    ).readAsStringSync();

    for (final snippet in [
      '# Hermes platform smoke checklist',
      'flutter analyze',
      'flutter test --concurrency=1',
      '1016 tests',
      'flutter build web --release -t lib/main_e2e.dart',
      'flutter build apk --debug',
      '453e746d9773b466a7393ec73713943a49276f4bee4465d18a3d083e5cb5ab0a',
      'artifact identity only; not live Android, mic, or reconnect evidence',
      'npm run linux:release-build',
      'Windows and iOS builds must run on their host platforms/CI\nrunners',
      '.github/workflows/hermes-platform-smoke.yml',
      'npm run platform:workflow-smoke',
      'A local YAML file is not enough',
      'visible workflows (`pages-build-deployment` only)',
      'latest local reprobe exited 1',
      'flutter build ios --simulator\n  --debug` exits 64',
      'Could not find an option named "--simulator"',
      'no native-host\nWindows/iOS/hosted Android receipt is present yet',
      'NAVIVOX_WATCH_WORKFLOW=false',
      'only proves dispatch',
      'the helper exits 4 and still does not count as a platform receipt',
      'successful Windows/iOS/Android/Linux job receipts from `gh run view`',
      'NAVIVOX_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit',
      'Completion verdict: NOT COMPLETE',
      'Do not promote proxy evidence',
      'tests,\nAPK hashes, configured Hermes home, workflow YAML, or dispatch-only output',
      'npm run hermes:live-smoke',
      'API connect/session rendering only',
      'not provider/model evidence',
      'not a chat/voice provider smoke',
      'not physical microphone evidence',
      'not\nwhole-goal completion evidence by itself',
      'strict readiness audit before any completion claim',
      'npm run hermes:provider-smoke',
      'npm run hermes:provider-smoke:local',
      'This is still transcript voice, not physical microphone or Hermes server audio,\nand not whole-goal completion evidence by itself',
      'android/live-mic-smoke.md',
      'npm run android:voice-smoke',
      'not a substitute for listening to real microphone input',
      'not whole-goal\ncompletion evidence by itself',
      'strict\nreadiness audit before any completion claim',
      'npm run android:hermes-voice-loop-smoke',
      'KVM-backed `fractal_test`',
      'deterministic Android UI loop mechanics only',
      'not a provider-backed reply receipt',
      'not\nHermes realtime/server audio, and not whole-goal completion evidence by itself',
      'still does not prove physical microphone audio input',
      'npm run android:live-mic-prep',
      'NAVIVOX_ANDROID_SKIP_BUILD=1',
      'installed/launched/granted microphone permission',
      'This prep command is not a\npass receipt and not whole-goal completion evidence by itself',
      'npm run android:durable-key-smoke',
      'NAVIVOX_ANDROID_TEST_TIMEOUT_SECONDS=900',
      'durable credential issuance and silent reconnect remain future work',
      'It is not\nwhole-goal completion evidence by itself',
      'It does not prove Gormes durable credential issuance or\nreconnect end to end',
    ]) {
      expect(text, contains(snippet), reason: snippet);
    }
  });
}
