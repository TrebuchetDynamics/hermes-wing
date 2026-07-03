import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Hermes readiness audit helper names every external blocker', () {
    final script = File('scripts/audit_hermes_readiness.sh');
    final audit = File('docs/runbooks/hermes-readiness-audit.md');
    expect(script.existsSync(), isTrue);
    expect(audit.existsSync(), isTrue);

    final scriptText = script.readAsStringSync();
    final auditText = audit.readAsStringSync();

    for (final blocker in [
      'Hermes platform workflow is not visible to gh',
      'no online Android device/emulator',
      'real spoken Android mic loop still requires manual audio/provider evidence',
      'Windows desktop native-host build receipt missing',
      'iOS simulator native-host build receipt missing',
      'full live provider-backed Hermes chat/voice smoke receipt missing',
      'Hermes realtime/server audio remains unimplemented',
      'Hermes config editing/admin remains deferred',
      'Hermes memory UI remains deferred',
      'Hermes jobs/schedules admin remains deferred',
      'Hermes messaging gateways remain deferred',
      'Hermes persona/SOUL editing remains deferred',
      'Hermes attachments/media remain deferred',
      'Hermes files/context folders remain deferred',
      'Hermes raw diagnostics/log export remains deferred',
      'Hermes multi-endpoint/profile management remains deferred',
      'full real Android + real Gormes durable reconnect after restart is not proven',
    ]) {
      expect(scriptText, contains(blocker), reason: blocker);
    }

    expect(scriptText, contains('npm run platform:workflow-smoke'));
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
    expect(scriptText, contains('Visible workflows'));
    expect(scriptText, contains('not native-host receipt evidence'));
    expect(scriptText, contains('not a provider-smoke receipt'));
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
    expect(scriptText, contains('responsive audio-capable Android target'));
    expect(
      scriptText,
      contains('successful native-host runner jobs/artifacts'),
    );
    expect(scriptText, contains('current voice path is local STT-to-text'));
    expect(scriptText, contains('Deferred Hermes surfaces: config admin'));
    expect(scriptText, contains('real Gormes restart reconnect receipt'));
    expect(scriptText, contains('Android debug APK sha256'));
    expect(
      scriptText,
      contains(
        'artifact identity only; not live Android, mic, or reconnect evidence',
      ),
    );
    expect(scriptText, contains('docs/runbooks/android/live-mic-smoke.md'));
    expect(scriptText, contains('docs/runbooks/android/release-handoff.md'));
    expect(scriptText, contains('npm run android:live-mic-prep'));
    expect(scriptText, contains('Flutter connected devices'));
    expect(scriptText, contains('not Android/audio receipt evidence'));
    expect(scriptText, contains('Flutter emulator inventory'));
    expect(scriptText, contains('not an online/audio receipt'));
    expect(scriptText, contains('Android emulator acceleration check'));
    expect(scriptText, contains('not audio/live-mic evidence'));
    expect(scriptText, contains('-accel-check'));
    expect(
      scriptText,
      contains('docs/runbooks/android/durable-keystore-smoke.md'),
    );
    expect(scriptText, contains('must not be used as a completion receipt'));
    expect(scriptText, contains('Completion verdict: NOT COMPLETE'));
    expect(
      scriptText,
      contains(
        'live provider/device/native-host/reconnect or deferred-surface blockers',
      ),
    );
    expect(scriptText, contains('Do not promote proxy evidence'));
    expect(scriptText, contains('tests, APK hashes, configured Hermes home'));
    expect(scriptText, contains('workflow YAML, or dispatch-only output'));

    expect(auditText, contains('Current completion audit verdict'));
    expect(
      auditText,
      contains('The active Hermes companion goal is **not complete**'),
    );
    expect(auditText, contains('Objective item'));
    expect(auditText, contains('Concrete artifact/evidence inspected'));
    expect(auditText, contains('Partial: provider text/transcript covered'));
    expect(
      auditText,
      contains(
        'Blocked: no current Android target for manual spoken-audio closeout',
      ),
    );
    expect(auditText, contains('Blocked: no native-host receipt'));
    expect(auditText, contains('Deferred/read-only by policy'));
    expect(
      auditText,
      contains('workflow YAML, or dispatch-only workflow output'),
    );
    expect(auditText, contains('not whole-goal completion evidence by itself'));
    expect(
      auditText,
      contains('strict readiness audit before completion claims'),
    );
    expect(auditText, contains('deterministic transcript voice only'));
    expect(auditText, contains('API connect/session rendering only'));
    expect(auditText, contains('not chat/voice provider smoke'));
    expect(auditText, contains('KVM-backed `fractal_test` emulator'));
    expect(auditText, contains('recognizer/permission readiness only'));
    expect(auditText, contains('NAVIVOX_ANDROID_SKIP_BUILD=1'));
    expect(auditText, contains('installed/launched/granted mic permission'));
    expect(
      auditText,
      contains(
        'Android readiness/prep helpers now print that their receipts/prep',
      ),
    );
    expect(auditText, contains('not provider-backed replies'));
    expect(auditText, contains('not full Gormes durable reconnect'));
    expect(auditText, contains('not whole-goal completion evidence by itself'));
    expect(auditText, contains('adb devices` had no attached Android devices'));
    expect(
      auditText,
      contains('`flutter devices` listed only Linux desktop and Chrome web'),
    );
    expect(auditText, contains('NAVIVOX_ANDROID_DEVICE_WAIT_SECONDS=1'));
    expect(auditText, contains('NAVIVOX_ANDROID_TEST_TIMEOUT_SECONDS=900'));
    expect(
      auditText,
      contains('Key readiness covered; reconnect protocol not covered'),
    );
    expect(auditText, contains('passed on 2026-07-03 with 23 tests'));
    expect(auditText, contains('--plain-name'));
    expect(
      auditText,
      contains(
        'falls back to device-bearer reconnect when stream reconnect exhausts',
      ),
    );
    expect(
      auditText,
      contains('provider reconnects automatically from saved durable gateway'),
    );
    expect(
      auditText,
      contains(
        'Deterministic loop covered; physical mic/provider loop not covered',
      ),
    );
    expect(auditText, contains('docs/runbooks/android/live-mic-smoke.md'));
    expect(
      auditText,
      contains(
        '453e746d9773b466a7393ec73713943a49276f4bee4465d18a3d083e5cb5ab0a',
      ),
    );
    expect(
      auditText,
      contains('build/native units and artifact identity only'),
    );
    expect(
      auditText,
      contains(
        'no live Android target, physical mic, or full durable reconnect receipt',
      ),
    );
    expect(auditText, contains('missing Windows host\n  receipt'));
    expect(auditText, contains('missing iOS/macOS host receipt'));
    expect(auditText, contains('flutter build windows --debug` exits 1'));
    expect(auditText, contains('only supported on Windows hosts'));
    expect(auditText, contains('flutter build ios --simulator --debug`'));
    expect(auditText, contains('Could not find an option named'));
    expect(auditText, contains('68 Chromium tests'));
    expect(
      auditText,
      contains('flutter build web --release -t lib/main_e2e.dart'),
    );
    expect(auditText, contains('produced `build/web`'));
    expect(auditText, contains('gh workflow list` recheck still shows only'));
    expect(auditText, contains('pages-build-deployment'));
    expect(
      auditText,
      contains('prints `flutter devices`, `flutter emulators`,'),
    );
    expect(auditText, contains('emulator -accel-check'));
    expect(
      auditText,
      contains('not Android/audio\n  or live-mic receipt evidence'),
    );
    expect(auditText, contains('Provider-backed smoke receipt'));
    expect(auditText, contains('configured Hermes home presence is only'));
    expect(auditText, contains('configured model/provider\n  credentials'));
    expect(
      auditText,
      contains('not physical\n  microphone or Hermes server-audio evidence'),
    );
    expect(auditText, contains('Do not count as completion'));
    expect(auditText, contains('Android `live-mic-prep` by itself'));
    expect(auditText, contains('visible workflows as blocker evidence'));
    expect(auditText, contains('not native-host receipt evidence'));
    expect(auditText, contains('Workflow YAML by itself'));
    expect(auditText, contains('Workflow dispatch by itself'));
    expect(auditText, contains('NAVIVOX_WATCH_WORKFLOW=false'));
    expect(auditText, contains('missing visible run id or unwatched run'));
    expect(auditText, contains('gh run view'));
    expect(
      auditText,
      contains('Installed-Hermes live connect smoke by itself'),
    );
    expect(auditText, contains('not provider/model\n  behavior'));
    expect(
      auditText,
      contains('not provider/model\n  behavior, chat/voice provider smoke'),
    );
    expect(auditText, contains('Provider transcript voice by itself'));
    expect(auditText, contains('Configured Hermes home presence by itself'));
    expect(auditText, contains('npm run hermes:provider-smoke:local'));
  });
}
