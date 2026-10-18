import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GitHub Pages deploys a landing page and scoped web client', () {
    final workflow = File('.github/workflows/pages.yml').readAsStringSync();
    final landing = File('site/index.html').readAsStringSync();

    expect(workflow, contains('pages: write'));
    expect(workflow, contains('id-token: write'));
    expect(workflow, contains('actions/configure-pages@'));
    expect(
      workflow,
      contains('flutter build web --release --base-href /hermes-wing/app/'),
    );
    expect(workflow, contains('site/index.html'));
    expect(workflow, contains('build/pages/app'));
    expect(workflow, contains('actions/upload-pages-artifact@'));
    expect(workflow, contains('path: build/pages'));
    expect(workflow, contains('actions/deploy-pages@'));
    expect(workflow, contains('Verify deployed landing and web app'));
    expect(workflow, contains("github.ref == 'refs/heads/main'"));
    expect(workflow, contains("github.event_name == 'push'"));
    expect(workflow, contains("github.event_name == 'workflow_dispatch'"));
    expect(workflow, isNot(contains('pull_request')));
    final workflowScope = workflow.split('jobs:').first;
    expect(workflowScope, isNot(contains('pages: write')));
    expect(workflowScope, isNot(contains('id-token: write')));
    expect(workflowScope, isNot(contains('concurrency:')));
    expect(workflow, contains('      group: pages'));
    expect(workflow, contains('      cancel-in-progress: true'));
    expect(workflow, contains('node site/pages-artifact.mjs stamp'));
    expect(workflow, contains('node site/pages-artifact.mjs verify'));
    expect(workflow, contains(r'PAGES_EXPECTED_REVISION="${GITHUB_SHA}"'));
    expect(workflow, contains(r'mktemp -d "${RUNNER_TEMP}/wing-pages.XXXXXX"'));
    expect(workflow, contains('--bind 127.0.0.1'));
    expect(workflow, contains(r'kill "${server_pid:-}"'));
    expect(workflow, contains(r'rm -rf "$pages_stage"'));
    for (final input in [
      'package.json',
      'package-lock.json',
      'playwright.config.mjs',
      'playwright/tests/regression/pages-landing.spec.mjs',
      'scripts/generate_readme_assets.mjs',
      'test/tooling/pages_artifact_test.mjs',
      'test/tooling/readme_assets_contract_test.dart',
      'test/tooling/wing_branding_assets_test.dart',
      'README.md',
      'docs/README.md',
      'docs/getting-started.md',
    ]) {
      expect(workflow, contains('"$input"'), reason: input);
    }
    expect(
      workflow,
      contains('cp site/assets/app-icon.png build/pages/assets/app-icon.png'),
    );
    expect(File('site/assets/app-icon.png').existsSync(), isTrue);

    expect(landing, contains('<main'));
    expect(landing, contains('Hermes Wing'));
    expect(landing, contains('Hermes Agent'));
    expect(landing, contains('href="app/"'));
    expect(
      landing,
      contains('https://github.com/TrebuchetDynamics/hermes-wing'),
    );
    expect(landing, contains('Alpha software'));
  });
}
