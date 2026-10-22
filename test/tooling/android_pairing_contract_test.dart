import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android transport permits user-reviewed encrypted VPN endpoints', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final config = File(
      'android/app/src/main/res/xml/network_security_config.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:usesCleartextTraffic="true"'));
    expect(
      manifest,
      contains('android:networkSecurityConfig="@xml/network_security_config"'),
    );
    expect(config, contains('<base-config cleartextTrafficPermitted="true"'));
    for (final host in ['localhost', '127.0.0.1', '::1', '10.0.2.2']) {
      expect(
        config,
        contains('<domain includeSubdomains="false">$host</domain>'),
      );
    }
  });

  test('Android retired input signals are content-free and consumed once', () {
    final source = File(
      'android/app/src/main/kotlin/com/trebuchetdynamics/hermes/wing/MainActivity.kt',
    ).readAsStringSync();

    expect(source, contains('consumeInitialConnectIntent'));
    expect(
      source,
      contains('initialConnectInput.also { initialConnectInput = false }'),
    );
    expect(source, contains('connectIntentEvents?.success(true)'));
    for (final retired in [
      'PairingHandoffIntentParser',
      'EXTRA_TEXT',
      'data?.toString()',
      'scanQrCode',
      'importQrImage',
      'mlkit',
    ]) {
      expect(source, isNot(contains(retired)), reason: retired);
    }
  });
}
