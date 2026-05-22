import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android setup checklist documents device paths and safe tokens', () {
    final checklist = File('docs/android-setup-checklist.md');

    expect(checklist.existsSync(), isTrue);

    final text = checklist.readAsStringSync();

    expect(text, contains('# Android Setup Checklist'));
    expect(text, contains('flutter doctor'));
    expect(text, contains('flutter doctor --android-licenses'));
    expect(text, contains('flutter devices'));
    expect(text, contains('flutter run -d <device-id>'));
    expect(text, contains('adb reverse tcp:<port> tcp:<port>'));
    expect(text, contains('http://127.0.0.1:<port>'));
    expect(text, contains('http://10.0.2.2:<port>'));
    expect(text, contains('gormes navivox connect-info'));
    expect(text, contains('LAN, VPN, or Tailscale'));
    expect(text, contains('Do not paste tokens'));
    expect(text, isNot(contains('nvbx_')));
  });
}
