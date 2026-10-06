import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../test/features/hermes_chat/support/fake_hermes_channel.dart';
import 'support/linux_test_isolation.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.shouldPropagateDevicePointerEvents = true;
  WidgetController.hitTestWarningShouldBeFatal = true;
  final root = requireLinuxTestRoot('wing-linux-native.');
  if (Platform.environment['WING_ISOLATED_NATIVE_INPUT'] != '1') {
    throw StateError('Use the isolated native-input launcher.');
  }

  Future<void> drive(
    String mode, [
    String filename = 'hermes-transcript.txt',
  ]) async {
    final result = await Process.run(
      '/usr/bin/python3',
      ['scripts/linux_native_input.py', mode],
      environment: {'WING_NATIVE_SAVE_FILENAME': filename},
    );
    expect(result.exitCode, 0, reason: 'Owned native save input failed.');
    // Only bounded, synthetic helper status; no transcript or selected path.
    debugPrint(result.stdout as String);
  }

  Future<void> actions(WidgetTester tester, double width) async {
    if (width < 480) {
      await tester.tap(
        find.byKey(const ValueKey('hermes-more-actions-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy transcript'));
    } else {
      await tester.tap(
        find.byKey(const ValueKey('hermes-copy-transcript-button')),
      );
    }
    await tester.pumpAndSettle();
  }

  Future<FakeHermesChannel> mount(WidgetTester tester, double width) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final channel = FakeHermesChannel(sessionsWithEarlierMessages: {'sess_1'})
      ..replaceTranscript(
        List.generate(
          250,
          (i) => HermesChatTurn(
            id: 'synthetic-$i',
            sessionId: 'sess_1',
            author: i.isEven
                ? HermesTurnAuthor.user
                : HermesTurnAuthor.assistant,
            createdAt: DateTime.utc(2026),
            text: 'Synthetic loaded turn $i — 日本語 😀',
          ),
        ),
      );
    addTearDown(channel.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(
            const EmptyHermesEndpointStore(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return channel;
  }

  for (final width in [390.0, 1280.0]) {
    for (final format in ['text', 'markdown']) {
      testWidgets('Linux GTK $width $format full-loaded save byte readback', (
        tester,
      ) async {
        final channel = await mount(tester, width);
        final semantics = tester.ensureSemantics();
        try {
          final extension = format == 'text' ? 'txt' : 'md';
          final file = File('$root/hermes-transcript.$extension');
          if (await file.exists()) await file.delete();
          await actions(tester, width);
          expect(
            find.textContaining('Older unfetched history is not included'),
            findsOneWidget,
          );
          await tester.tap(
            find.byKey(ValueKey('hermes-copy-transcript-$format')),
          );
          await tester.pumpAndSettle();
          final copied = (await Clipboard.getData(Clipboard.kTextPlain))!.text!;
          await actions(tester, width);
          final target = find.byKey(ValueKey('hermes-save-transcript-$format'));
          await tester.ensureVisible(target);
          expect(
            find.bySemanticsLabel(
              format == 'text' ? 'Save as text' : 'Save as Markdown',
            ),
            findsOneWidget,
          );
          await tester.tap(target);
          await tester.pump();
          await drive('save', 'hermes-transcript.$extension');
          final deadline = DateTime.now().add(const Duration(seconds: 15));
          while (!await file.exists() && DateTime.now().isBefore(deadline)) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          expect(
            await file.exists(),
            isTrue,
            reason:
                'Saved notice=${find.text("Transcript saved to the selected file.").evaluate().isNotEmpty}, failure notice=${find.textContaining("could not be exported").evaluate().isNotEmpty}',
          );
          expect(await file.readAsBytes(), utf8.encode(copied));
          expect(
            RegExp('Synthetic loaded turn [0-9]+').allMatches(copied),
            hasLength(250),
          );
          expect(copied, contains('日本語 😀'));
          await tester.pumpAndSettle();
          expect(
            find.text('Transcript saved to the selected file.'),
            findsOneWidget,
          );
          expect(channel.loadEarlierMessagesCalls, 0);
          expect(channel.sentImageDataUrls, isEmpty);
          await file.delete();
          await tester.pumpWidget(const SizedBox.shrink());
        } finally {
          semantics.dispose();
        }
      });
    }
  }

  for (final stale in [false, true]) {
    testWidgets(
      'Linux GTK cancellation or changed owner writes nothing: stale=$stale',
      (tester) async {
        final channel = await mount(tester, 1280);
        await actions(tester, 1280);
        await tester.tap(
          find.byKey(const ValueKey('hermes-save-transcript-text')),
        );
        await tester.pump();
        if (stale) await channel.createSession();
        await drive(stale ? 'save' : 'save_cancel');
        await tester.pumpAndSettle();
        expect(await File('$root/hermes-transcript.txt').exists(), isFalse);
        expect(
          find.text('Transcript saved to the selected file.'),
          findsNothing,
        );
        expect(channel.loadEarlierMessagesCalls, 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
