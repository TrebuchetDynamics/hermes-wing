import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Wing Link is a local host supervisor only', () {
    final adr = File(
      'docs/adr/0044-wing-link-local-runtime-supervisor.md',
    ).readAsStringSync();
    expect(adr, contains('127.0.0.1:8654'));
    expect(adr, contains('Hermes Agent remains authoritative'));
    expect(adr, contains('Termux RUN_COMMAND'));
    expect(adr, contains('OmniRoute is optional'));
    expect(adr, contains('Recommended Donna starter profile'));
    expect(adr, contains('lacks the `distribution.yaml`'));
    expect(adr, isNot(contains('Wing Link proxies Hermes chat')));
    expect(File('CONTEXT.md').readAsStringSync(), contains('host supervisor'));
    expect(
      File('docs/security/threat-model.md').readAsStringSync(),
      contains('Wing Link control token'),
    );
  });
}
