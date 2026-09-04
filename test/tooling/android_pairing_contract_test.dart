import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android cleartext policy permits only local development endpoints', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final config = File(
      'android/app/src/main/res/xml/network_security_config.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:usesCleartextTraffic="false"'));
    expect(
      manifest,
      contains('android:networkSecurityConfig="@xml/network_security_config"'),
    );
    expect(config, contains('<base-config cleartextTrafficPermitted="false"'));
    for (final host in ['localhost', '127.0.0.1', '::1', '10.0.2.2']) {
      expect(
        config,
        contains('<domain includeSubdomains="false">$host</domain>'),
      );
    }
  });

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
    expect(
      source,
      contains('intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()'),
    );
    expect(source, isNot(contains('intent.getStringExtra(Intent.EXTRA_TEXT)')));
    expect(source, contains('override fun onDestroy()'));
    expect(source, contains('qr_image_cancelled'));
  });
}
