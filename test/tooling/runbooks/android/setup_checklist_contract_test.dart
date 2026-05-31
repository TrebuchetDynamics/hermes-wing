import 'package:flutter_test/flutter_test.dart';

import '../shared/runbook_contract_helpers.dart';

void main() {
  test('Android setup checklist documents device paths and safe tokens', () {
    final text = readRunbookContractWithSharedPolicy(
      'docs/runbooks/android/setup-checklist.md',
    );

    expectRunbookContainsAll(text, [
      '# Android Setup Checklist',
      'flutter doctor',
      'flutter doctor --android-licenses',
      'flutter devices',
      'flutter run -d <device-id>',
      'adb reverse tcp:<port> tcp:<port>',
      'http://127.0.0.1:<port>',
      'http://10.0.2.2:<port>',
      'gormes navivox connect-info',
      'LAN, VPN, or Tailscale',
      'Do not paste tokens',
      '## 5. Continuous voice smoke',
    ]);
    expect(
      text,
      contains('adb install -r build/app/outputs/flutter-apk/app-debug.apk'),
    );
    expect(
      text,
      contains(
        'adb shell cmd package query-services -a android.speech.RecognitionService',
      ),
    );
    expectRunbookContainsAll(text, ['Continuous voice ready']);
    expectRunbookHasNoSecretPlaceholders(text);
  });
}
