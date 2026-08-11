import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GitHub Pages deploys the scoped Hermes Wing web build', () {
    final workflow = File('.github/workflows/pages.yml').readAsStringSync();

    expect(workflow, contains('pages: write'));
    expect(workflow, contains('id-token: write'));
    expect(workflow, contains('actions/configure-pages@'));
    expect(
      workflow,
      contains('flutter build web --release --base-href /hermes-wing/'),
    );
    expect(workflow, contains('actions/upload-pages-artifact@'));
    expect(workflow, contains('path: build/web'));
    expect(workflow, contains('actions/deploy-pages@'));
    expect(workflow, contains('Verify deployed scoped assets'));
    expect(workflow, contains('<base href="/hermes-wing/">'));
    expect(workflow, contains('flutter_bootstrap.js'));
    expect(workflow, contains('main.dart.js'));
  });
}
