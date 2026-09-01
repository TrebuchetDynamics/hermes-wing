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
    expect(
      workflow,
      contains('<title>Hermes Wing — Hermes Agent everywhere</title>'),
    );
    expect(workflow, contains('app/flutter_bootstrap.js'));
    expect(workflow, contains('app/main.dart.js'));
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
