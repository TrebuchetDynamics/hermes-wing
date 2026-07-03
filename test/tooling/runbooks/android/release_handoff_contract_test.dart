import 'package:flutter_test/flutter_test.dart';

import '../shared/runbook_contract_helpers.dart';

void main() {
  test('Android release handoff documents safe local install artifacts', () {
    final text = readRunbookContractWithSharedPolicy(
      'docs/runbooks/android/release-handoff.md',
    );

    expectRunbookContainsAll(text, [
      '# Android Release Handoff',
      'flutter build apk --debug',
      'build/app/outputs/flutter-apk/app-debug.apk',
      'flutter install -d <device-id>',
      'adb install -r',
      'flutter build appbundle --release',
      'build/app/outputs/bundle/release/app-release.aab',
      'pairing secrets contract',
      'Do not paste tokens',
      'trusted tester',
      '## Continuous voice smoke after install',
    ]);
    expect(
      text,
      contains(
        'adb shell cmd package query-services -a android.speech.RecognitionService',
      ),
    );
    expectRunbookContainsAll(text, [
      'microphone permission',
      'Continuous voice ready',
      '## Continuous voice blocker handoff',
      'Run id: `voice-readiness-smoke-2026-05-27`',
      'Latest local debug APK',
      'sha256 453e746d9773b466a7393ec73713943a49276f4bee4465d18a3d083e5cb5ab0a',
      'docs/runbooks/android/live-mic-smoke.md',
      'configured Hermes Agent API with real provider/model credentials',
      'provider-backed reply',
      'Installing the APK is not a physical-audio receipt',
      'flutter devices` lists only Linux desktop and Chrome',
      '/dev/kvm',
    ]);
    expect(
      text,
      contains(
        'Android recognizer, microphone permission, and gateway profile STT are separate checks',
      ),
    );
    expectRunbookContainsAll(text, ['physical USB-debuggable Android device']);
    expectRunbookHasNoSecretPlaceholders(text);
  });
}
