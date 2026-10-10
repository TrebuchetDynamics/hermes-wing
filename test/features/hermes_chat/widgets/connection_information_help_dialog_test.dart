import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'platform_local_connection_panel_test.dart' show pumpEntry, key;
import 'platform_local_connection_behavior_test.dart'
    show activate, keyboardActivate, capture, loadCaptureFonts;

void main() {
  testWidgets('production chooser offers safe selectable connection help', (
    tester,
  ) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
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
    final (channel, store, _) = await pumpEntry(tester, TargetPlatform.android);
    for (final mode in ['local', 'ssh', 'remote']) {
      await activate(tester, 'hermes-connection-mode-$mode');
      expect(key('connection-information-help'), findsOneWidget);
      if (mode == 'remote') {
        await tester.enterText(
          key('hermes-base-url-field'),
          'https://private.example.invalid',
        );
        await tester.enterText(
          key('hermes-api-key-field'),
          'synthetic-secret-not-for-copy',
        );
      }
      await keyboardActivate(tester, 'connection-information-help');
      final widget = tester.widget<SelectableText>(
        key('connection-information-help-text'),
      );
      final strings = AppLocalizations.of(
        tester.element(key('connection-information-help-text')),
      );
      expect(widget.data, strings.connectionInformationHelpText);
      expect(
        widget.data,
        contains('SSH authentication is separate from Agent authentication'),
      );
      expect(widget.data, contains('whoami'));
      expect(widget.data, contains('hostname -I'));
      expect(widget.data, contains('ss -ltn'));
      await activate(tester, 'connection-information-copy');
      expect(copied.last, strings.connectionInformationHelpText);
      expect(copied.last, isNot(contains('synthetic-secret-not-for-copy')));
      expect(copied.last, isNot(contains('private.example.invalid')));
      await activate(tester, 'connection-information-close');
      expect(key('connection-information-help-text'), findsNothing);
      var restored = false;
      FocusManager.instance.primaryFocus?.context?.visitAncestorElements((
        element,
      ) {
        if (element.widget.key ==
            const ValueKey('connection-information-help')) {
          restored = true;
        }
        return !restored;
      });
      expect(restored, isTrue);
    }
    expect(copied, hasLength(3));
    expect(channel.state.isConnected, isFalse);
    expect(store.saveCalls, isEmpty);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  for (final size in [const Size(390, 844), const Size(1280, 1000)]) {
    testWidgets('help scrolls and renders at $size with 200 percent text', (
      tester,
    ) async {
      await loadCaptureFonts(tester);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpEntry(tester, TargetPlatform.android, textScale: 2);
      await keyboardActivate(tester, 'connection-information-help');
      expect(key('connection-information-help-text'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture(tester, 'help-${size.width.toInt()}');
      await keyboardActivate(tester, 'connection-information-copy');
      await keyboardActivate(tester, 'connection-information-close');
      expect(key('connection-information-help-text'), findsNothing);
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
