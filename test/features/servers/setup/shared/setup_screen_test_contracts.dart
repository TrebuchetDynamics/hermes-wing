import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const setupUrlLabel = 'Gateway URL';
const setupTokenLabel = 'Pairing token';
const setupConnectLabel = 'Connect and talk';
const setupImportQrLabel = 'Scan or import QR';
const setupEnterManuallyLabel = 'Enter manually';
const setupTokenVisibilityButtonKey = ValueKey('setup-token-visibility-button');

Finder setupUrlField() => find.widgetWithText(TextField, setupUrlLabel);
Finder setupTokenField() => find.widgetWithText(TextField, setupTokenLabel);
Finder setupConnectAction() => find.text(setupConnectLabel);
Finder setupImportQrAction() => find.bySemanticsLabel(setupImportQrLabel);
Finder setupTokenVisibilityButton() =>
    find.byKey(setupTokenVisibilityButtonKey);

/// Expands the "Enter manually" expansion tile so URL/token fields are visible.
Future<void> expandManualEntry(WidgetTester tester) async {
  await tester.tap(find.text(setupEnterManuallyLabel));
  await tester.pumpAndSettle();
}

Future<void> enterSetupUrl(WidgetTester tester, String url) async {
  await tester.enterText(setupUrlField(), url);
}

Future<void> enterSetupToken(WidgetTester tester, String token) async {
  await tester.enterText(setupTokenField(), token);
}

Future<void> tapSetupConnect(WidgetTester tester) async {
  await tester.ensureVisible(setupConnectAction());
  await tester.tap(setupConnectAction());
}

TextField setupUrlTextField(WidgetTester tester) {
  return tester.widget<TextField>(setupUrlField());
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
