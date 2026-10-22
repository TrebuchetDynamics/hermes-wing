import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/widgets/connection_access_help.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'platform_local_connection_panel_test.dart' show pumpEntry, key;
import 'platform_local_connection_behavior_test.dart' show activate;

void main() {
  testWidgets('public request leaves form, connection and secrets untouched', (
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
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await activate(tester, 'hermes-connection-mode-remote');
    await tester.enterText(
      key('hermes-base-url-field'),
      'https://private.example.invalid/p/exact',
    );
    await tester.enterText(
      key('hermes-api-key-field'),
      'synthetic-not-for-clipboard',
    );
    await activate(tester, 'connection-access-help');
    final s = AppLocalizations.of(
      tester.element(find.byType(ConnectionAccessHelp)),
    );
    expect(copied, isEmpty);
    await activate(tester, 'connection-access-copy');
    expect(copied, [s.connectionAccessRequest]);
    expect(copied.single, isNot(contains('private.example.invalid')));
    expect(copied.single, isNot(contains('synthetic-not-for-clipboard')));
    expect(find.text(s.connectionAccessCopied), findsOneWidget);
    await tester.tap(find.text(s.connectionInformationClose));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(key('hermes-base-url-field')).controller!.text,
      'https://private.example.invalid/p/exact',
    );
    expect(
      tester.widget<TextField>(key('hermes-api-key-field')).controller!.text,
      'synthetic-not-for-clipboard',
    );
    expect(channel.state.isConnected, isFalse);
    expect(store.saveCalls, isEmpty);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  for (final width in [390.0, 1280.0]) {
    testWidgets('help handles clipboard denial at 200 percent text $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            throw PlatformException(code: 'denied');
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
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showConnectionAccessHelp(context),
                child: const Text('Open help'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open help'));
      await tester.pumpAndSettle();
      await activate(tester, 'connection-access-copy');
      expect(
        find.byKey(const ValueKey('connection-access-notice')),
        findsOneWidget,
      );
      expect(find.textContaining('Could not copy'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
