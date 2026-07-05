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
      'Required manual smoke',
      'strict goal closeout must keep the Android physical-mic blocker open',
      'npm run android:live-mic-prep',
      'NAVIVOX_ANDROID_DEVICE_ID=<device-id>',
      'NAVIVOX_ANDROID_HERMES_URL=<android-reachable-hermes-url>',
      'physical Android device',
      'emulators can exercise\n  prep/regression helpers but cannot close this live-mic receipt',
      'RECORD_AUDIO',
      'It is not a\npass receipt',
      '`flutter emulators --launch fractal_test`',
      'crashed with exit `-6`',
      'emulator -avd fractal_test -no-snapshot',
      'gpu swiftshader_indirect -no-window',
      'pulseaudio: Failed to initialize PA context',
      'prep evidence only',
      'adb devices',
      'flutter devices',
      'an `emulator-*` target is not accepted for the live-mic receipt',
      'real provider/model credentials',
      'Tap Speak',
      'unique phrase aloud',
      'provider-backed Hermes reply',
      'capture → Hermes reply → TTS → re-arm',
      'proves a distinct re-armed capture',
      'NAVIVOX_ANDROID_SECOND_SPOKEN_PHRASE',
      'NAVIVOX_ANDROID_PHYSICAL_DEVICE_OBSERVED=true',
      'NAVIVOX_ANDROID_PHYSICAL_MIC_OBSERVED=true',
      'NAVIVOX_ANDROID_SYNTHETIC_AUDIO_USED=false',
      'synthetic/generated transcript or host playback tooling',
      'build/receipts/android-live-mic-smoke.json',
      'strips\n   URL userinfo, query strings, fragments, and copied route/path state from the',
      'records the current git `HEAD`',
      'records Android device properties from\n   `adb shell getprop`',
      'records installed Navivox package/version details from\n   `pm path` and `dumpsys package`',
      'rejects secret-looking or overlong spoken\n   phrases/provider reply excerpts',
      '240\n   characters or less',
      'explicit physical-device\n   and physical-mic manual observation gate',
      'reject emulator targets for this\n   live-mic receipt',
      'require `NAVIVOX_ANDROID_SYNTHETIC_AUDIO_USED=false`',
      'physical_android_microphone',
      'local_device_stt_to_hermes_text',
      'provider_backed_hermes_text_reply',
      'tts_observed_before_rearm',
      'provider reply excerpt to differ from both spoken\n   phrases',
      '`head_sha` to match the current git `HEAD`',
      'manufacturer/model/SDK/fingerprint device properties',
      'android_target_type=physical_device',
      'device_properties.is_emulator=false',
      'Navivox package to be installed with version metadata',
      '`RECORD_AUDIO` granted',
      'NAVIVOX_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit',
      'Completion verdict: NOT COMPLETE',
      'do not promote this Android physical-mic\n   receipt',
      'passing tests, APK hashes, configured Hermes home, workflow YAML, or\n   dispatch-only output',
      'Do not count as completion',
      'npm run android:voice-smoke',
      'npm run android:hermes-voice-loop-smoke',
      'Provider transcript smoke by itself',
      'Synthetic/generated host audio playback',
      'emulator audio routes',
      'Direct\n  transcript injection remains non-physical automated evidence',
      'cmd: Failure calling service package: Broken pipe (32)',
      'Unable to\nstart the app on the device',
      'Flutter emulator launcher exit `-6`',
      'headless direct-launch form',
      'not microphone evidence',
      'scripts/prepare_android_live_mic_smoke.sh',
      'integration_test/android_device_speech_smoke_test.dart',
      'integration_test/hermes_continuous_voice_android_smoke_test.dart',
    ]);
    expectRunbookHasNoSecretPlaceholders(text);

    expect(script, contains('RECORD_AUDIO'));
    expect(script, contains('Manual evidence still required'));
    expect(script, contains('does not\nprove physical microphone capture'));
    expect(platformRunbook, contains('android/live-mic-smoke.md'));
    expect(
      platformRunbook,
      contains('Required physical-mic evidence still requires'),
    );
  });
}
