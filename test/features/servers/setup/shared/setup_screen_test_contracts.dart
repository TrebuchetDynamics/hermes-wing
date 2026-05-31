import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const setupAddressLabel = 'Gateway address';
const setupPortLabel = 'Port';
const setupTokenLabel = 'Pairing token';
const setupConnectLabel = 'Connect and talk';
const setupImportQrLabel = 'Import QR image';
const setupTokenVisibilityButtonKey = ValueKey('setup-token-visibility-button');

Finder setupAddressField() => find.widgetWithText(TextField, setupAddressLabel);
Finder setupPortField() => find.widgetWithText(TextField, setupPortLabel);
Finder setupTokenField() => find.widgetWithText(TextField, setupTokenLabel);
Finder setupConnectAction() => find.text(setupConnectLabel);
Finder setupImportQrAction() => find.bySemanticsLabel(setupImportQrLabel);
Finder setupTokenVisibilityButton() => find.byKey(setupTokenVisibilityButtonKey);

Future<void> enterSetupAddress(WidgetTester tester, String address) async {
  await tester.enterText(setupAddressField(), address);
}

Future<void> enterSetupPort(WidgetTester tester, String port) async {
  await tester.enterText(setupPortField(), port);
}

Future<void> enterSetupToken(WidgetTester tester, String token) async {
  await tester.enterText(setupTokenField(), token);
}

Future<void> tapSetupConnect(WidgetTester tester) async {
  await tester.ensureVisible(setupConnectAction());
  await tester.tap(setupConnectAction());
}

TextField setupAddressTextField(WidgetTester tester) {
  return tester.widget<TextField>(setupAddressField());
}

TextField setupPortTextField(WidgetTester tester) {
  return tester.widget<TextField>(setupPortField());
}

TextField setupTokenTextField(WidgetTester tester) {
  return tester.widget<TextField>(setupTokenField());
}

class ClipboardCapture {
  final copiedTexts = <String>[];

  void install(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedTexts.add(
            (call.arguments as Map<Object?, Object?>)['text']! as String,
          );
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }
}
