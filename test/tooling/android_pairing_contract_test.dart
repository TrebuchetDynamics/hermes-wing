import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android launch pairing payload has a one-shot consume path', () {
    final source = File(
      'android/app/src/main/kotlin/com/trebuchetdynamics/hermes/wing/MainActivity.kt',
    ).readAsStringSync();

    expect(source, contains('consumeInitialConnectIntent'));
    expect(
      source,
      contains('initialConnectIntent.also { initialConnectIntent = null }'),
    );
    expect(source, contains('initialConnectIntent = payload'));
  });
}
