import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('package scripts expose Hermes and platform closeout helpers', () {
    final packageJson =
        jsonDecode(File('package.json').readAsStringSync())
            as Map<String, Object?>;
    final scripts = (packageJson['scripts'] as Map).cast<String, Object?>();

    const expectedScripts = {
      'hermes:live-smoke': './scripts/run_live_hermes_smoke.sh',
      'hermes:provider-smoke': './scripts/run_provider_hermes_smoke.sh',
      'hermes:provider-smoke:local':
          './scripts/run_local_configured_hermes_provider_smoke.sh',
      'hermes:readiness-audit': './scripts/audit_hermes_readiness.sh',
      'android:voice-smoke': './scripts/run_android_voice_smoke.sh',
      'android:hermes-voice-loop-smoke':
          './scripts/run_android_hermes_voice_loop_smoke.sh',
      'android:durable-key-smoke': './scripts/run_android_durable_key_smoke.sh',
      'android:live-mic-prep': './scripts/prepare_android_live_mic_smoke.sh',
      'android:live-mic-receipt':
          './scripts/record_android_live_mic_receipt.sh',
      'platform:workflow-smoke': './scripts/run_hermes_platform_workflow.sh',
      'linux:release-build': './scripts/run_linux_release_build.sh',
    };

    for (final entry in expectedScripts.entries) {
      expect(scripts[entry.key], entry.value, reason: entry.key);
      final helperPath = entry.value.replaceFirst('./', '');
      final helper = File(helperPath);
      expect(helper.existsSync(), isTrue, reason: helperPath);
      expect(
        helper.readAsStringSync(),
        startsWith('#!/usr/bin/env bash\nset -euo pipefail'),
        reason: '$helperPath should fail closed as a bash helper',
      );
      expect(
        helper.statSync().mode & 0x49,
        isNonZero,
        reason: '$helperPath should be executable by at least one class',
      );
    }

    final androidVoiceSmoke = File(
      'scripts/run_android_voice_smoke.sh',
    ).readAsStringSync();
    final androidLoopSmoke = File(
      'scripts/run_android_hermes_voice_loop_smoke.sh',
    ).readAsStringSync();
    final androidDurableKeySmoke = File(
      'scripts/run_android_durable_key_smoke.sh',
    ).readAsStringSync();
    final androidLiveMicPrep = File(
      'scripts/prepare_android_live_mic_smoke.sh',
    ).readAsStringSync();
    final androidLiveMicReceipt = File(
      'scripts/record_android_live_mic_receipt.sh',
    ).readAsStringSync();
    for (final helperText in [
      androidVoiceSmoke,
      androidLoopSmoke,
      androidDurableKeySmoke,
      androidLiveMicPrep,
      androidLiveMicReceipt,
    ]) {
      expect(helperText, contains('not whole-goal completion evidence'));
      expect(
        helperText,
        contains('NAVIVOX_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit'),
      );
    }
    expect(androidVoiceSmoke, contains('Manual continuous-voice closeout'));
    expect(androidLoopSmoke, contains('not physical\nmicrophone audio input'));
    expect(androidLoopSmoke, contains('not provider-backed replies'));
    expect(
      androidDurableKeySmoke,
      contains('not part of active pure-Hermes readiness'),
    );
    expect(
      androidDurableKeySmoke,
      contains(
        'does not prove\nHermes chat, voice, provider, platform, or realtime/server-audio readiness',
      ),
    );
    expect(
      androidLiveMicPrep,
      contains('does not\nprove physical microphone capture'),
    );
    expect(
      androidLiveMicReceipt,
      contains('NAVIVOX_ANDROID_TTS_OBSERVED=true'),
    );
    expect(
      androidLiveMicReceipt,
      contains('NAVIVOX_ANDROID_REARM_OBSERVED=true'),
    );
    expect(
      androidLiveMicReceipt,
      contains('NAVIVOX_ANDROID_NO_SECRET_LEAKS=true'),
    );
    expect(
      androidLiveMicReceipt,
      contains('NAVIVOX_ANDROID_SECOND_SPOKEN_PHRASE must be a different'),
    );
    expect(
      androidLiveMicReceipt,
      contains(
        'NAVIVOX_ANDROID_PROVIDER_REPLY must be an observed assistant reply excerpt',
      ),
    );
    expect(androidLiveMicReceipt, contains('distinct_rearmed_turn_observed'));
    expect(androidLiveMicReceipt, contains('hermes_url_sanitized'));
    expect(androidLiveMicReceipt, contains('head_sha'));
    expect(androidLiveMicReceipt, contains('git'));
    expect(androidLiveMicReceipt, contains('rev-parse'));
    expect(androidLiveMicReceipt, contains('device_properties'));
    expect(androidLiveMicReceipt, contains('package_info'));
    expect(androidLiveMicReceipt, contains('pm_path_output'));
    expect(androidLiveMicReceipt, contains('dumpsys'));
    expect(androidLiveMicReceipt, contains('versionName'));
    expect(androidLiveMicReceipt, contains('versionCode'));
    expect(androidLiveMicReceipt, contains('record_audio_granted'));
    expect(
      androidLiveMicReceipt,
      contains(r'android\.permission\.RECORD_AUDIO'),
    );
    expect(androidLiveMicReceipt, contains('ro.product.model'));
    expect(androidLiveMicReceipt, contains('ro.build.fingerprint'));
    expect(androidLiveMicReceipt, contains('urlsplit'));
    expect(androidLiveMicReceipt, contains("rsplit('@', 1)[-1]"));
    expect(
      androidLiveMicReceipt,
      contains("urlunsplit((parts.scheme, netloc, '', '', ''))"),
    );
    expect(androidLiveMicReceipt, contains('SECRET_PATTERN'));
    expect(androidLiveMicReceipt, contains('len(value) > 240'));
    expect(androidLiveMicReceipt, contains('short non-sensitive excerpt'));
    expect(androidLiveMicReceipt, contains('record a non-sensitive excerpt'));
    expect(androidLiveMicReceipt, contains('whole-goal completion'));

    final liveSmoke = File(
      'scripts/run_live_hermes_smoke.sh',
    ).readAsStringSync();
    expect(liveSmoke, contains('API connect/session rendering only'));
    expect(liveSmoke, contains('not provider/model evidence'));
    expect(liveSmoke, contains('not a chat/voice provider smoke'));
    expect(liveSmoke, contains('not physical microphone evidence'));
    expect(liveSmoke, contains('not whole-goal completion evidence'));
    expect(
      liveSmoke,
      contains('NAVIVOX_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit'),
    );

    final providerSmoke = File(
      'scripts/run_provider_hermes_smoke.sh',
    ).readAsStringSync();
    expect(
      providerSmoke,
      contains('deterministic transcript voice only'),
      reason: 'provider smoke must not be mistaken for physical mic evidence',
    );
    expect(providerSmoke, contains('not physical microphone evidence'));
    expect(providerSmoke, contains('safe_receipt_base_url'));
    expect(providerSmoke, contains('urlsplit'));
    expect(providerSmoke, contains('platform workflow publication'));
    expect(providerSmoke, contains('deferred Hermes Desktop parity surfaces'));
    expect(
      providerSmoke,
      contains('does not prove Hermes realtime/server audio'),
    );
    expect(providerSmoke, contains('not whole-goal completion evidence'));
    expect(
      providerSmoke,
      contains('NAVIVOX_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit'),
    );
  });
}
