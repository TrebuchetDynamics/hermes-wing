import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const speechToTextFork = 'third_party/speech_to_text';
  // Pinned baselines documented in the fork README/CHANGELOG files. Keep these
  // in sync with third_party/ when a fork is rebased or dropped.
  const speechToTextPin = '22367e5ac5e9c4427ff7179ad0b4d0336168a302';

  test('vendored speech_to_text is pinned by path in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      pubspec,
      contains('speech_to_text:\n    path: third_party/speech_to_text'),
      reason: 'speech_to_text must remain a vendored path dependency',
    );
  });

  test('speech_to_text fork docs exist and record the upstream pin', () {
    final readme = File('$speechToTextFork/README.md').readAsStringSync();
    final changelog = File('$speechToTextFork/CHANGELOG.md').readAsStringSync();

    expect(readme, contains('https://github.com/csdcorp/speech_to_text'));
    expect(
      readme,
      contains(speechToTextPin),
      reason: 'fork README must document the pinned upstream commit',
    );
    expect(readme, contains('7.4.0'));
    expect(
      changelog,
      contains(speechToTextPin),
      reason: 'fork CHANGELOG must document the pinned upstream commit',
    );
    expect(changelog, contains('7.4.0'));
  });

  test('documented speech_to_text patch file still exists', () {
    // The fork README inventories this file; a relocation or deletion of the
    // patched file is fork drift that must be documented and re-diffed.
    expect(
      File(
        '$speechToTextFork/android/src/main/kotlin/'
        'com/csdcorp/speech_to_text/SpeechToTextPlugin.kt',
      ).existsSync(),
      isTrue,
      reason: 'fork README inventories SpeechToTextPlugin.kt',
    );
  });
}
