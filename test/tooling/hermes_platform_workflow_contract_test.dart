import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'platform workflow dispatch helper reports invisible workflow evidence',
    () {
      final helper = File('scripts/run_hermes_platform_workflow.sh');
      expect(helper.existsSync(), isTrue);
      final text = helper.readAsStringSync();

      expect(
        text,
        contains('workflow_list="\$(gh workflow list 2>&1 || true)"'),
      );
      expect(text, contains('Visible workflows:'));
      expect(
        text,
        contains('Publish .github/workflows/hermes-platform-smoke.yml'),
      );
      expect(text, contains('exit 2'));
      expect(
        text,
        contains('NAVIVOX_WATCH_WORKFLOW=false did not wait for job results'),
      );
      expect(
        text,
        contains('Collect successful Windows/iOS/Android/Linux job receipts'),
      );
      expect(text, contains('no run id was visible yet'));
      expect(text, contains('This is not a platform receipt'));
      expect(text, contains('exit 4'));
    },
  );

  test('Hermes platform workflow preserves native-host receipt jobs', () {
    final workflow = File('.github/workflows/hermes-platform-smoke.yml');
    expect(workflow.existsSync(), isTrue);
    final text = workflow.readAsStringSync();

    expect(text, contains('"on":'));
    expect(text, contains('workflow_dispatch:'));
    expect(text, contains('timeout-minutes:'));

    expect(text, contains('linux-web-android:'));
    expect(text, contains('flutter analyze'));
    expect(text, contains('flutter test --concurrency=1'));
    expect(text, contains('flutter build apk --debug'));
    expect(text, contains('flutter build linux --release'));
    expect(text, contains('navivox-android-debug-apk'));
    expect(text, contains('navivox-linux-release-bundle'));

    expect(text, contains('provider-hermes-smoke:'));
    expect(text, contains('NAVIVOX_PROVIDER_HERMES_URL'));
    expect(text, contains('NAVIVOX_PROVIDER_HERMES_API_KEY'));
    expect(text, contains('npm run hermes:provider-smoke'));

    expect(text, contains('android-emulator-smoke:'));
    expect(text, contains('./scripts/run_android_voice_smoke.sh'));
    expect(text, contains('./scripts/run_android_hermes_voice_loop_smoke.sh'));
    expect(text, contains('./scripts/run_android_durable_key_smoke.sh'));

    expect(text, contains('windows-build:'));
    expect(text, contains('runs-on: windows-latest'));
    expect(text, contains('flutter build windows --debug'));
    expect(text, contains('navivox-windows-debug-bundle'));

    expect(text, contains('ios-simulator-build:'));
    expect(text, contains('runs-on: macos-latest'));
    expect(text, contains('flutter build ios --simulator --debug'));
    expect(text, contains('navivox-ios-simulator-app'));
  });
}
