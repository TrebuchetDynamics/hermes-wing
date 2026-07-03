import 'package:flutter_test/flutter_test.dart';

import '../shared/runbook_contract_helpers.dart';

void main() {
  test(
    'Android pairing handoff smoke keeps intent commands and token safety',
    () {
      final text = readRunbookContractWithSharedPolicy(
        'docs/runbooks/android/pairing-handoff-smoke.md',
      );

      expectRunbookContainsAll(text, [
        '# Android Pairing Handoff Smoke',
        'Manual smoke for the Android platform seam',
        'android.intent.action.VIEW',
        'android.intent.action.SEND',
        'android.intent.extra.TEXT',
        'navivox://connect?base_url=',
        'direct app-open source',
        'shared-text source',
        'shared text must not auto-connect',
        'UI and diagnostics must not display the token value',
        'Do not paste tokens',
      ]);
      expectRunbookHasNoSecretPlaceholders(text);
    },
  );

  test('Android pairing instrumentation points to canonical manual smoke', () {
    final text = readRunbookContractWithSharedPolicy(
      'docs/runbooks/android/pairing-handoff-instrumentation.md',
    );

    expectRunbookContainsAll(text, [
      '# Optional Android Pairing Handoff Instrumentation Smoke',
      'flutter test integration_test/android_pairing_handoff_smoke_test.dart -d <android-device-id>',
      'ci-secret-token-do-not-render',
      'token leak',
      'docs/runbooks/android/pairing-handoff-smoke.md',
      'Do not paste tokens',
    ]);
    expectRunbookOmitsAll(text, [
      'docs/runbooks/android-pairing-handoff-smoke.md',
    ]);
    expectRunbookHasNoSecretPlaceholders(text);
  });

  test('Android durable keystore smoke keeps reconnect secret boundaries', () {
    final text = readRunbookContractWithSharedPolicy(
      'docs/runbooks/android/durable-keystore-smoke.md',
    );

    expectRunbookContainsAll(text, [
      '# Android Durable Keystore Smoke',
      'separates keypair readiness from full Gormes durable reconnect',
      'npm run android:durable-key-smoke',
      'integration_test/durable_key_store_android_smoke_test.dart',
      'This is key storage readiness only',
      'does **not** prove durable credential',
      'Full durable reconnect closeout still required',
      'trusted Android device',
      'durable reconnect',
      'non-secret public key',
      'no pairing token is stored',
      'silently reconnects with the saved device credential',
      'reconnect readiness remains available',
      'NAVIVOX_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit',
      'Completion verdict: NOT COMPLETE',
      'do not promote this reconnect receipt',
      'key smoke, passing tests, APK hashes, configured Hermes home, workflow YAML,',
      'dispatch-only output to whole-goal completion',
      'legacy durable',
      'reconnect blocker remains open',
      'Do not paste tokens',
    ]);
    expectRunbookHasNoSecretPlaceholders(text);
  });
}
