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
      expect(
        text,
        contains('gh_auth_status="\$(gh auth status 2>&1 || true)"'),
      );
      expect(
        text,
        contains("Active gh token scopes do not include 'workflow'"),
      );
      expect(text, contains('with workflow scope before pushing/publishing'));
      expect(text, contains('Visible workflows:'));
      expect(
        text,
        contains('Publish .github/workflows/hermes-platform-smoke.yml'),
      );
      expect(text, contains('exit 2'));
      expect(text, contains('NAVIVOX_PLATFORM_WORKFLOW_RECEIPT'));
      expect(text, contains('NAVIVOX_PLATFORM_WORKFLOW_RUN_ID'));
      expect(text, contains('Using existing %s run %s'));
      expect(text, contains('Platform workflow receipt written'));
      expect(text, contains('receipt_path = sys.argv[4]'));
      expect(text, contains("open(receipt_path, 'w'"));
      expect(text, contains('missing_required_artifacts'));
      expect(text, contains('invalid_required_artifacts'));
      expect(text, contains('artifact_details'));
      expect(text, contains('job_details'));
      expect(text, contains('required_native_jobs'));
      expect(text, contains('missing_required_jobs'));
      expect(text, contains('invalid_required_jobs'));
      expect(text, contains('Windows desktop build'));
      expect(text, contains('iOS simulator build'));
      expect(text, contains('macOS desktop build'));
      expect(text, contains('size_in_bytes'));
      expect(text, contains('archive_download_url'));
      expect(text, contains("run.get('status') == 'completed'"));
      expect(text, contains('Missing required native artifacts'));
      expect(text, contains('Invalid required native artifacts'));
      expect(text, contains('Missing required native jobs'));
      expect(text, contains('Invalid required native jobs'));
      expect(text, contains('sys.exit(5)'));
      expect(text, contains('navivox-windows-debug-bundle'));
      expect(text, contains('navivox-ios-simulator-app'));
      expect(text, contains('navivox-macos-debug-app'));
      expect(text, contains('whole-goal completion'));
      expect(
        text,
        contains('NAVIVOX_WATCH_WORKFLOW=false did not wait for job results'),
      );
      expect(
        text,
        contains(
          'Collect successful Windows/iOS/macOS/Android/Linux job receipts',
        ),
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

    expect(text, contains('macos-build:'));
    expect(text, contains('flutter build macos --debug'));
    expect(text, contains('navivox-macos-debug-app'));
  });
}
