import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/local_setup/models/termux_bootstrap_command.dart';
import 'package:wing/features/local_setup/screens/termux_hermes_setup_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

class _MemoryAssetBundle extends CachingAssetBundle {
  _MemoryAssetBundle(this.metadata);

  final Map<String, Object?> metadata;

  @override
  Future<ByteData> load(String key) async {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(metadata)));
    return ByteData.sublistView(bytes);
  }
}

Map<String, Object?> _validMetadata() => {
  'available': true,
  'tag': 'v0.1.0-alpha.9',
  'installer_commit': '0123456789abcdef0123456789abcdef01234567',
  'installer_sha256': List.filled(64, 'a').join(),
  'asset_sha256': List.filled(64, 'b').join(),
  'asset_size': 1234567,
};

Widget _testApp(Map<String, Object?> metadata, {double textScale = 1}) =>
    DefaultAssetBundle(
      bundle: _MemoryAssetBundle(metadata),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const TermuxHermesSetupScreen(),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('copies only the validated release-pinned command after a tap', (
    tester,
  ) async {
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
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

    final metadata = _validMetadata();
    await tester.pumpWidget(_testApp(metadata));
    await tester.pumpAndSettle();

    expect(find.text('Install Hermes Agent on this phone'), findsOneWidget);
    expect(find.textContaining('official verified installer'), findsOneWidget);
    expect(clipboardText, isNull);

    await tester.tap(find.byKey(const ValueKey('termux-copy-command')));
    await tester.pump();

    expect(clipboardText, TermuxBootstrapCommand.fromJson(metadata).command);
    expect(find.textContaining('Setup command copied'), findsOneWidget);
    for (final forbidden in [
      'API_SERVER_KEY',
      'Bearer',
      'wing://connect',
      'code=',
      '/data/data/',
    ]) {
      expect(find.textContaining(forbidden), findsNothing);
      expect(clipboardText, isNot(contains(forbidden)));
    }
  });

  testWidgets('clipboard failure shows an explicit recovery message', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          throw PlatformException(code: 'clipboard-unavailable');
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

    await tester.pumpWidget(_testApp(_validMetadata()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('termux-copy-command')));
    await tester.pump();

    expect(find.textContaining('could not be copied'), findsOneWidget);
    expect(find.textContaining('Setup command copied'), findsNothing);
  });

  testWidgets('unqualified build disables command copy', (tester) async {
    await tester.pumpWidget(_testApp({'available': false}));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('termux-copy-command')),
    );
    expect(button.onPressed, isNull);
    expect(
      find.text('This build cannot install the matching Wing Link release.'),
      findsOneWidget,
    );
  });

  testWidgets('actions remain reachable at 320dp and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp(_validMetadata(), textScale: 2));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final semantics = tester.ensureSemantics();
    final installButton = find.byKey(const ValueKey('termux-install'));
    for (
      var attempt = 0;
      attempt < 8 && installButton.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(find.byType(ListView), const Offset(0, -150));
      await tester.pump();
    }
    expect(installButton, findsOneWidget);
    expect(tester.getSize(installButton).height, greaterThanOrEqualTo(48));
    expect(tester.widget<FilledButton>(installButton).onPressed, isNotNull);
    expect(find.bySemanticsLabel('Install Termux'), findsOneWidget);

    final copyButton = find.byKey(const ValueKey('termux-copy-command'));
    await tester.scrollUntilVisible(copyButton, 100);
    expect(copyButton, findsOneWidget);
    expect(tester.getSize(copyButton).height, greaterThanOrEqualTo(48));
    expect(tester.widget<FilledButton>(copyButton).onPressed, isNotNull);
    expect(find.bySemanticsLabel('Copy setup command'), findsOneWidget);
    final tierNotice = find.textContaining(
      'Android may stop background processes',
    );
    for (
      var attempt = 0;
      attempt < 12 && tierNotice.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();
    }
    expect(tierNotice, findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
