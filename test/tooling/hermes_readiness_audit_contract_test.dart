import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Hermes readiness audit helper names pure-Hermes blockers', () {
    final script = File('scripts/audit_hermes_readiness.sh');
    final audit = File('docs/runbooks/hermes-readiness-audit.md');
    expect(script.existsSync(), isTrue);
    expect(audit.existsSync(), isTrue);

    final scriptText = script.readAsStringSync();
    final auditText = audit.readAsStringSync();

    for (final blocker in [
      'Hermes platform workflow is not visible to gh',
      'no online Android device/emulator',
      'Android automated voice-loop receipt missing',
      'Windows desktop native-host build receipt missing',
      'iOS simulator native-host build receipt missing',
      'macOS desktop native-host build receipt missing',
      'full live provider-backed Hermes chat/voice smoke receipt missing',
      'Hermes realtime/server audio receipt missing',
      'Hermes config editing/admin remains deferred',
      'Hermes memory UI remains deferred',
      'Hermes jobs/schedules admin remains deferred',
      'Hermes messaging gateways remain deferred',
      'Hermes persona/SOUL editing remains deferred',
      'Hermes attachments/media remain deferred',
      'Hermes files/context folders remain deferred',
      'Hermes raw diagnostics/log export remains deferred',
      'Hermes multi-endpoint/profile management available locally',
    ]) {
      expect(scriptText, contains(blocker), reason: blocker);
    }

    expect(scriptText, contains('NAVIVOX_HERMES_SERVER_AUDIO_RECEIPT'));
    expect(
      scriptText,
      contains('build/receipts/hermes-server-audio-smoke.json'),
    );
    expect(auditText, contains('npm run hermes:server-audio-receipt'));
    expect(scriptText, contains("kind=hermes_server_audio_smoke"));
    expect(scriptText, contains('hermes_realtime_or_audio_api'));
    expect(scriptText, contains('client_audio_to_hermes_server_audio'));
    expect(scriptText, contains('hermes_server_audio_to_client_playback'));
    expect(scriptText, contains('provider_reply_observed'));
    expect(scriptText, contains('server_audio_playback_observed'));
    expect(scriptText, contains('round_trip_observed'));
    expect(scriptText, contains("'device_stt_used', 'local_tts_only'"));
    expect(scriptText, contains("missing.append(f'{key}=false')"));
    expect(
      auditText,
      contains('`device_stt_used=false`, `local_tts_only=false`'),
    );
    expect(
      auditText,
      contains('manual evidence recorder, not an implementation'),
    );
    expect(
      scriptText,
      contains('Hermes realtime/server audio receipt present'),
    );
    expect(scriptText, contains('not Android physical mic'));
    expect(scriptText, contains('npm run platform:workflow-smoke'));
    expect(scriptText, contains('NAVIVOX_PLATFORM_WORKFLOW_RECEIPT'));
    expect(
      scriptText,
      contains('platform workflow/native-host receipt present'),
    );
    expect(
      scriptText,
      contains('platform workflow receipt is present but incomplete'),
    );
    expect(scriptText, contains('missing_required_artifacts must be empty'));
    expect(scriptText, contains('invalid_required_artifacts must be empty'));
    expect(scriptText, contains('missing_required_jobs must be empty'));
    expect(scriptText, contains('invalid_required_jobs must be empty'));
    expect(scriptText, contains('artifact_details'));
    expect(scriptText, contains('job_details'));
    expect(scriptText, contains('size_in_bytes>0'));
    expect(scriptText, contains('expired=false'));
    expect(scriptText, contains('archive_download_url'));
    expect(scriptText, contains('job_details:{job_name}:status=completed'));
    expect(scriptText, contains('job_details:{job_name}:conclusion=success'));
    expect(scriptText, contains('run_status=completed'));
    expect(scriptText, contains('head_sha must match current git HEAD'));
    expect(
      scriptText,
      contains('Windows desktop native-host build receipt recorded'),
    );
    expect(
      scriptText,
      contains('iOS simulator native-host build receipt recorded'),
    );
    expect(
      scriptText,
      contains('macOS desktop native-host build receipt recorded'),
    );
    expect(
      scriptText,
      contains(
        'Hermes platform workflow publication is covered by the recorded successful workflow receipt',
      ),
    );
    expect(
      scriptText,
      contains('workflow dispatch without successful gh run view'),
    );
    expect(
      scriptText,
      contains('NAVIVOX_WATCH_WORKFLOW=false only proves dispatch'),
    );
    expect(
      scriptText,
      contains('workflow_list="\$(gh workflow list 2>&1 || true)"'),
    );
    expect(
      scriptText,
      contains('gh_auth_status="\$(gh auth status 2>&1 || true)"'),
    );
    expect(
      scriptText,
      contains('active gh token scopes do not include workflow'),
    );
    expect(
      scriptText,
      contains(
        'future workflow-file updates may require refreshed credentials',
      ),
    );
    expect(
      scriptText,
      contains('existing published workflow receipts can still be watched'),
    );
    expect(scriptText, contains('Visible workflows'));
    expect(scriptText, contains('not native-host receipt evidence'));
    expect(scriptText, contains('not a provider-smoke receipt'));
    expect(scriptText, contains("receipt.get('status') != 'passed'"));
    expect(
      scriptText,
      contains(
        "receipt.get('coverage') != 'typed text plus deterministic transcript voice'",
      ),
    );
    expect(scriptText, contains("receipt.get('playwright_retries') != 0"));
    expect(scriptText, contains("missing.append('head_sha')"));
    expect(scriptText, contains('head_sha must match current git HEAD'));
    expect(scriptText, contains("missing.append('base_url')"));
    expect(
      scriptText,
      contains('base_url must omit userinfo, query, and fragment'),
    );
    expect(
      scriptText,
      contains('base_url must be an origin without copied route/path state'),
    );
    expect(scriptText, contains("'platform workflow publication'"));
    expect(scriptText, contains("'deferred Hermes Desktop parity surfaces'"));
    expect(scriptText, contains("'provider-backed Hermes typed text turn'"));
    expect(scriptText, contains("'deterministic transcript voice turn'"));
    expect(scriptText, contains("evidence_for:{item}"));
    expect(scriptText, contains("not_evidence_for:{item}"));
    expect(scriptText, contains("receipt.get('timestamp_utc')"));
    expect(
      scriptText,
      contains(
        'present but not a complete passing no-retry typed-text/transcript-voice receipt',
      ),
    );
    expect(scriptText, contains('npm run hermes:provider-smoke:local'));
    expect(scriptText, contains('configured model/provider credentials'));
    expect(
      scriptText,
      contains(
        'deterministic transcript voice is not physical microphone/server audio evidence',
      ),
    );
    expect(
      scriptText,
      contains('Objective checklist (read-only; not completion evidence)'),
    );
    expect(scriptText, contains('provider-backed Hermes chat/voice'));
    expect(scriptText, contains('Android automated voice path'));
    expect(
      scriptText,
      contains(
        'deterministic transcript + fake TTS evidence and not physical-mic evidence',
      ),
    );
    expect(
      scriptText,
      contains('successful native-host runner jobs/artifacts'),
    );
    expect(
      scriptText,
      contains('current voice path is device STT -> Hermes text'),
    );
    expect(scriptText, contains('Deferred Hermes surfaces: config admin'));
    expect(scriptText, contains('Android debug APK sha256'));
    expect(
      scriptText,
      contains('artifact identity only; not live Android or mic evidence'),
    );
    expect(scriptText, contains('docs/runbooks/android/live-mic-smoke.md'));
    expect(scriptText, contains('docs/runbooks/android/release-handoff.md'));
    expect(scriptText, contains('scripts/record_android_live_mic_receipt.sh'));
    expect(scriptText, contains('android-hermes-voice-loop-smoke.json'));
    expect(
      scriptText,
      contains('Android automated voice-loop receipt present'),
    );
    expect(
      scriptText,
      contains(
        'deterministic transcript capture plus fake TTS continuous re-arm',
      ),
    );
    expect(scriptText, contains('fake TTS playback callback'));
    expect(scriptText, contains('Android live microphone receipt present'));
    expect(
      scriptText,
      contains('real spoken Android mic loop receipt recorded'),
    );
    expect(scriptText, contains('online device alone is not a pass'));
    expect(scriptText, contains('distinct_rearmed_turn_observed'));
    expect(scriptText, contains('head_sha'));
    expect(scriptText, contains('head_sha must match current git HEAD'));
    expect(scriptText, contains('device_id must be a physical Android device'));
    expect(scriptText, contains('android_target_type=physical_device'));
    expect(scriptText, contains('device_properties'));
    expect(
      scriptText,
      contains("'manufacturer', 'model', 'sdk', 'fingerprint'"),
    );
    expect(scriptText, contains("device_properties.{key}"));
    expect(scriptText, contains('device_properties.is_emulator=false'));
    expect(scriptText, contains('package_info'));
    expect(
      scriptText,
      contains('package_info.package_name=com.trebuchetdynamics.navivox'),
    );
    expect(scriptText, contains('package_info.installed=true'));
    expect(scriptText, contains('package_info.record_audio_granted=true'));
    expect(scriptText, contains("'version_name', 'version_code'"));
    expect(scriptText, contains("package_info.{key}"));
    expect(scriptText, contains('physical_device_observed'));
    expect(scriptText, contains('physical_mic_observed'));
    expect(scriptText, contains('synthetic_audio_used=false'));
    expect(scriptText, contains('audio_input_path'));
    expect(scriptText, contains('physical_android_microphone'));
    expect(scriptText, contains('local_device_stt_to_hermes_text'));
    expect(scriptText, contains('provider_backed_hermes_text_reply'));
    expect(scriptText, contains('tts_observed_before_rearm'));
    expect(scriptText, contains('hermes_url_sanitized'));
    expect(scriptText, contains('hermes_url must be a valid http(s) origin'));
    expect(
      scriptText,
      contains('hermes_url must omit userinfo, query, and fragment'),
    );
    expect(
      scriptText,
      contains('hermes_url must be an origin without copied route/path state'),
    );
    expect(scriptText, contains('provider_reply_observed'));
    expect(
      scriptText,
      contains('must contain a short observed non-sensitive excerpt'),
    );
    expect(scriptText, contains('must be 240 characters or less'));
    expect(scriptText, contains('must not contain secret-looking values'));
    expect(scriptText, contains('basic\\s+\\S+'));
    expect(scriptText, contains('cookie|set-cookie'));
    expect(scriptText, contains('://[^/\\s@]+@'));
    expect(scriptText, contains('gh[pousr]_'));
    expect(scriptText, contains('xox[abprs]-'));
    expect(scriptText, contains('eyJ[a-z0-9_-]'));
    expect(scriptText, contains('second_spoken_phrase must differ'));
    expect(
      scriptText,
      contains('provider_reply_observed must differ from spoken phrases'),
    );
    expect(scriptText, contains('distinct second spoken turn after re-arm'));
    expect(scriptText, contains('npm run android:live-mic-receipt'));
    expect(scriptText, contains('Flutter connected devices'));
    expect(scriptText, contains('start an audio-capable target'));
    expect(scriptText, contains('Flutter emulator inventory'));
    expect(scriptText, contains('not an online/audio receipt'));
    expect(scriptText, contains('Android emulator acceleration check'));
    expect(scriptText, contains('not audio/live-mic evidence'));
    expect(scriptText, contains('-accel-check'));
    expect(scriptText, isNot(contains('real Gormes')));
    expect(scriptText, isNot(contains('durable reconnect')));
    expect(scriptText, contains('must not be used as a completion receipt'));
    expect(scriptText, contains('Completion verdict: NOT COMPLETE'));
    expect(scriptText, contains('block_physical_mic'));
    expect(scriptText, contains('block_receipt'));
    expect(scriptText, contains('block_server_audio'));
    expect(scriptText, contains('block_deferred_surface'));
    expect(
      scriptText,
      contains(
        "printf 'Completion verdict: NOT COMPLETE; %s blocker(s) remain.",
      ),
    );
    expect(scriptText, contains('Do not promote proxy evidence'));
    expect(scriptText, contains('tests, APK hashes, configured Hermes home'));
    expect(scriptText, contains('workflow YAML, or dispatch-only output'));

    expect(auditText, contains('current pure-Hermes Navivox companion goal'));
    expect(auditText, contains('Current completion audit verdict'));
    expect(
      auditText,
      contains('The active Hermes companion goal is **not complete**'),
    );
    expect(auditText, contains('Objective item'));
    expect(auditText, contains('Concrete artifact/evidence inspected'));
    expect(auditText, contains('Android physical spoken mic receipt'));
    expect(auditText, contains('Android automated voice-loop receipt'));
    expect(auditText, contains('Windows/iOS/macOS host receipts'));
    expect(auditText, contains('Publish platform workflow'));
    expect(auditText, contains('Hermes realtime/server audio'));
    expect(auditText, contains('Deferred Hermes Desktop parity'));
    expect(auditText, contains('Polish/hardening'));
    expect(
      auditText,
      contains(
        'Covered for no-human Android voice-loop mechanics; not physical-mic/provider/server-audio evidence',
      ),
    );
    expect(auditText, contains('Covered.'));
    expect(
      auditText,
      contains(
        'Partially covered; remaining surfaces deferred/read-only by policy',
      ),
    );
    expect(auditText, contains('not whole-goal completion evidence by itself'));
    expect(auditText, contains('deterministic transcript voice only'));
    expect(auditText, contains('API connect/session rendering only'));
    expect(auditText, contains('not chat/voice provider smoke'));
    expect(auditText, contains('KVM-backed `fractal_test` emulator'));
    expect(
      auditText,
      contains('Readiness/prep covered; real spoken audio not covered'),
    );
    expect(auditText, contains('NAVIVOX_ANDROID_SKIP_BUILD=1'));
    expect(auditText, contains('installed/launched/granted mic permission'));
    expect(auditText, contains('adb devices` had no attached Android devices'));
    expect(
      auditText,
      contains('`flutter devices` listed only Linux desktop and Chrome web'),
    );
    expect(
      auditText,
      contains('build/receipts/android-hermes-voice-loop-smoke.json'),
    );
    expect(
      auditText,
      contains('Covered for no-human Android Flutter voice-loop mechanics'),
    );
    expect(auditText, contains('docs/runbooks/android/live-mic-smoke.md'));
    expect(
      auditText,
      contains(
        'npm run hermes:readiness-audit` prints the current APK SHA-256',
      ),
    );
    expect(
      auditText,
      contains('build/native units and artifact identity only'),
    );
    expect(auditText, contains('hosted receipts are covered'));
    expect(auditText, contains('Windows desktop build'));
    expect(auditText, contains('iOS simulator build'));
    expect(auditText, contains('macOS desktop build'));
    expect(auditText, contains('non-expired `navivox-windows-debug-bundle`'));
    expect(auditText, contains('non-expired `navivox-ios-simulator-app`'));
    expect(auditText, contains('non-expired `navivox-macos-debug-app`'));
    expect(auditText, contains('68 Chromium tests'));
    expect(
      auditText,
      contains('flutter build web --release -t lib/main_e2e.dart'),
    );
    expect(auditText, contains('produced `build/web`'));
    expect(
      auditText,
      contains('published and visible as `Hermes platform smoke`'),
    );
    expect(auditText, contains('build/receipts/hermes-platform-workflow.json'));
    expect(auditText, contains('successful watched receipt'));
    expect(
      auditText,
      contains('When Android is missing, the helper prints `flutter devices`'),
    );
    expect(auditText, contains('emulator -accel-check'));
    expect(
      auditText,
      contains(
        'not Android\n  voice-loop or physical live-mic receipt evidence',
      ),
    );
    expect(auditText, contains('Provider-backed smoke receipt'));
    expect(auditText, contains('configured Hermes home presence is only'));
    expect(auditText, contains('configured model/provider\n  credentials'));
    expect(
      auditText,
      contains('not physical microphone or Hermes server-audio evidence'),
    );
    expect(auditText, contains('current `HEAD`'));
    expect(auditText, contains('sanitized origin-only `base_url`'));
    expect(auditText, contains('explicit `evidence_for` labels'));
    expect(auditText, contains('Do not count as completion'));
    expect(auditText, contains('Android `live-mic-prep` by itself'));
    expect(auditText, contains('Workflow YAML by itself'));
    expect(auditText, contains('Workflow dispatch by itself'));
    expect(auditText, contains('NAVIVOX_WATCH_WORKFLOW=false'));
    expect(auditText, contains('missing visible run id or unwatched run'));
    expect(auditText, contains('build/receipts/hermes-platform-workflow.json'));
    expect(
      auditText,
      contains('watched successful run with required artifacts'),
    );
    expect(auditText, contains('gh run view'));
    expect(
      auditText,
      contains('Installed-Hermes live connect smoke by itself'),
    );
    expect(auditText, contains('not provider/model\n  behavior'));
    expect(auditText, contains('Provider transcript voice by itself'));
    expect(auditText, contains('Configured Hermes home presence by itself'));
    expect(auditText, contains('npm run hermes:provider-smoke:local'));
    expect(auditText, isNot(contains('real Gormes')));
    expect(auditText, isNot(contains('Gormes durable reconnect')));
  });
}
