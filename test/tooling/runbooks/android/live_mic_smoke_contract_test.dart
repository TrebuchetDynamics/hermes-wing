import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../shared/runbook_contract_helpers.dart';

void main() {
  test('Android live microphone runbook preserves manual receipt boundary', () {
    final text = readRunbookContractWithSharedPolicy(
      'docs/runbooks/android/live-mic-smoke.md',
    );
    final script = File(
      'scripts/prepare_android_live_mic_smoke.sh',
    ).readAsStringSync();
    final platformRunbook = File(
      'docs/runbooks/hermes-platform-smoke.md',
    ).readAsStringSync();

    expectRunbookContainsAll(text, [
      '# Android Live Microphone Hermes Smoke',
      'physical-audio receipt',
      'npm run android:live-mic-prep',
      'NAVIVOX_ANDROID_DEVICE_ID=<device-id>',
      'NAVIVOX_ANDROID_HERMES_URL=<android-reachable-hermes-url>',
      'RECORD_AUDIO',
      'It is not a\npass receipt',
      'KVM-backed `fractal_test` emulator',
      'NAVIVOX_ANDROID_SKIP_BUILD=1',
      'installed/launched/granted microphone permission',
      'prep evidence only',
      'adb devices',
      'flutter devices',
      'real provider/model credentials',
      'Tap Speak',
      'unique phrase aloud',
      'provider-backed Hermes reply',
      'capture → Hermes reply → TTS → re-arm',
      'NAVIVOX_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit',
      'Completion verdict: NOT COMPLETE',
      'do not promote this Android receipt',
      'passing tests, APK hashes, configured Hermes home, workflow YAML, or\n   dispatch-only output',
      'Do not count as completion',
      'npm run android:voice-smoke',
      'npm run android:hermes-voice-loop-smoke',
      'Provider transcript smoke by itself',
      'cmd: Failure calling service package: Broken pipe (32)',
      'Unable to\nstart the app on the device',
      'not\nmicrophone evidence',
      'scripts/prepare_android_live_mic_smoke.sh',
      'integration_test/android_device_speech_smoke_test.dart',
      'integration_test/hermes_continuous_voice_android_smoke_test.dart',
    ]);
    expectRunbookHasNoSecretPlaceholders(text);

    expect(script, contains('RECORD_AUDIO'));
    expect(script, contains('Manual evidence still required'));
    expect(script, contains('does not\nprove physical microphone capture'));
    expect(platformRunbook, contains('android/live-mic-smoke.md'));
    expect(platformRunbook, contains('physical-audio receipt checklist'));
  });
}
