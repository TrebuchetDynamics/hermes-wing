import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/local_setup/models/termux_bootstrap_command.dart';
import 'package:wing/features/local_setup/screens/termux_hermes_setup_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

class _DeferredAssetBundle extends CachingAssetBundle {
  _DeferredAssetBundle(this.metadata);

  final Map<String, Object?> metadata;
  final release = Completer<void>();

  @override
  Future<ByteData> load(String key) async {
    await release.future;
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(metadata)));
    return ByteData.sublistView(bytes);
  }
}

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
        theme: ThemeData(platform: TargetPlatform.android),
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

Widget _packagedApp() => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: const TermuxHermesSetupScreen(),
);

Future<void> _showCommand(WidgetTester tester) async {
  final ready = find.byKey(const ValueKey('termux-ready'));
  await tester.ensureVisible(ready);
  await tester.tap(ready);
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('announces setup command preparation while metadata loads', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final bundle = _DeferredAssetBundle(_validMetadata());
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: bundle,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TermuxHermesSetupScreen(),
        ),
      ),
    );
    await tester.pump();

    await _showCommand(tester);
    final loading = find.byKey(const ValueKey('termux-command-loading'));
    expect(loading, findsOneWidget);
    await tester.ensureVisible(loading);
    await tester.pump();
    final loadingSemantics = tester.getSemantics(loading);
    expect(
      loadingSemantics.label,
      contains('Preparing the verified setup command…'),
    );
    expect(loadingSemantics.flagsCollection.isLiveRegion, isTrue);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('termux-copy-command')),
          )
          .onPressed,
      isNull,
    );

    bundle.release.complete();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('termux-command-loading')), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('termux-copy-command')),
          )
          .onPressed,
      isNotNull,
    );
    semantics.dispose();
  });

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

    expect(find.text('Set up Hermes on this phone'), findsOneWidget);
    expect(
      find.textContaining('reuses a healthy existing installation'),
      findsOneWidget,
    );
    expect(clipboardText, isNull);
    await _showCommand(tester);

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

  testWidgets('blocks duplicate command copies while clipboard is pending', (
    tester,
  ) async {
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    var copyCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copyCalls += 1;
            await gate.future;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(_testApp(_validMetadata()));
    await tester.pumpAndSettle();
    await _showCommand(tester);
    final copy = find.byKey(const ValueKey('termux-copy-command'));
    await tester.tap(copy);
    await tester.pump();

    expect(copyCalls, 1);
    expect(tester.widget<FilledButton>(copy).onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(copyCalls, 1);
    expect(find.textContaining('Setup command copied'), findsOneWidget);
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
    await _showCommand(tester);
    await tester.tap(find.byKey(const ValueKey('termux-copy-command')));
    await tester.pump();

    expect(find.textContaining('could not be copied'), findsOneWidget);
    expect(find.textContaining('Setup command copied'), findsNothing);
  });

  testWidgets('development build packages a usable verified command', (
    tester,
  ) async {
    await tester.pumpWidget(_packagedApp());
    await tester.pumpAndSettle();
    await _showCommand(tester);

    // Native asset I/O can finish after the last scheduled animation frame.
    for (var attempt = 0; attempt < 50; attempt++) {
      final action = tester.widget<FilledButton>(
        find.byKey(const ValueKey('termux-copy-command')),
      );
      if (action.onPressed != null ||
          find
              .text('This build cannot install the matching Wing Link release.')
              .evaluate()
              .isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('termux-copy-command')),
    );
    expect(button.onPressed, isNotNull);
    expect(
      find.text('This build cannot install the matching Wing Link release.'),
      findsNothing,
    );
    expect(find.textContaining('codeload.github.com'), findsOneWidget);
  });

  testWidgets('unqualified build disables command copy', (tester) async {
    await tester.pumpWidget(_testApp({'available': false}));
    await tester.pumpAndSettle();
    await _showCommand(tester);

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('termux-copy-command')),
    );
    expect(button.onPressed, isNull);
    expect(
      find.text('This build cannot install the matching Wing Link release.'),
      findsOneWidget,
    );
  });

  testWidgets('install guide action has an async callback', (tester) async {
    await tester.pumpWidget(_testApp(_validMetadata()));
    await tester.pumpAndSettle();

    final button = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('termux-install')),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets(
    'actions remain reachable at 320dp and 200 percent text',
    (tester) async {
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
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -150),
        );
        await tester.pump();
      }
      expect(installButton, findsOneWidget);
      expect(tester.getSize(installButton).height, greaterThanOrEqualTo(48));
      expect(tester.widget<OutlinedButton>(installButton).onPressed, isNotNull);
      expect(find.bySemanticsLabel('Install Termux'), findsOneWidget);

      await _showCommand(tester);
      final copyButton = find.byKey(const ValueKey('termux-copy-command'));
      await tester.ensureVisible(copyButton);
      expect(copyButton, findsOneWidget);
      expect(tester.getSize(copyButton).height, greaterThanOrEqualTo(48));
      expect(tester.widget<FilledButton>(copyButton).onPressed, isNotNull);
      expect(find.bySemanticsLabel('Copy setup command'), findsOneWidget);
      final tierNotice = find.textContaining('Android can stop Hermes');
      for (
        var attempt = 0;
        attempt < 12 && tierNotice.evaluate().isEmpty;
        attempt++
      ) {
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -300),
        );
        await tester.pump();
      }
      expect(tierNotice, findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
