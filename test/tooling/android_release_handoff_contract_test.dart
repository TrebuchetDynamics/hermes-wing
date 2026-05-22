import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android release handoff documents safe local install artifacts', () {
    final handoff = File('docs/android-release-handoff.md');

    expect(handoff.existsSync(), isTrue);

    final text = handoff.readAsStringSync();

    expect(text, contains('# Android Release Handoff'));
    expect(text, contains('flutter build apk --debug'));
    expect(text, contains('build/app/outputs/flutter-apk/app-debug.apk'));
    expect(text, contains('flutter install -d <device-id>'));
    expect(text, contains('adb install -r'));
    expect(text, contains('flutter build appbundle --release'));
    expect(text, contains('build/app/outputs/bundle/release/app-release.aab'));
    expect(text, contains('Do not ship pairing tokens'));
    expect(text, contains('trusted tester'));
    expect(text, isNot(contains('nvbx_')));
  });
}
