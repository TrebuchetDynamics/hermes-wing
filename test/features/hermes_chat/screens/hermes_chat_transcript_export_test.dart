import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/features/hermes_chat/export/hermes_transcript_export.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';

class Saver implements HermesTranscriptSaver {
  @override
  bool supported = true;
  final snapshots = <HermesTranscriptExport>[];
  final writes = <HermesTranscriptExport>[];
  Completer<void>? gate;
  Completer<void>? startedWriteGate;
  bool fail = false;
  bool cancel = false;
  @override
  Future<HermesTranscriptExportResult> save(
    HermesTranscriptExport snapshot, {
    required bool Function() canWrite,
  }) async {
    snapshots.add(snapshot);
    final started = startedWriteGate;
    if (started != null) {
      if (!canWrite()) return HermesTranscriptExportResult.cancelled;
      // Model a platform write admitted before its asynchronous settlement.
      writes.add(snapshot);
      await started.future;
      return HermesTranscriptExportResult.saved;
    }
    if (gate != null) await gate!.future;
    if (cancel || !canWrite()) return HermesTranscriptExportResult.cancelled;
    if (fail) throw StateError('synthetic error /tmp/private-file.txt');
    writes.add(snapshot);
    return HermesTranscriptExportResult.downloadStarted;
  }
}

List<HermesChatTurn> history([int count = 250]) => List.generate(
  count,
  (i) => HermesChatTurn(
    id: 'synthetic-$i',
    sessionId: 'sess_1',
    author: i.isEven ? HermesTurnAuthor.user : HermesTurnAuthor.assistant,
    createdAt: DateTime.utc(2026),
    text: 'Synthetic loaded turn $i — 日本語 😀',
  ),
);

Future<void> open(
  WidgetTester tester,
  FakeHermesChannel channel, {
  Saver? saver,
  double scale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        if (saver != null)
          hermesTranscriptSaverProvider.overrideWithValue(saver),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const HermesChatScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> actions(WidgetTester tester, {bool compact = false}) async {
  if (compact) {
    await tester.tap(find.byKey(const ValueKey('hermes-more-actions-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy transcript'));
  } else {
    await tester.tap(
      find.byKey(const ValueKey('hermes-copy-transcript-button')),
    );
  }
  await tester.pumpAndSettle();
}

Future<void> save(WidgetTester tester, [String format = 'text']) async {
  final action = find.byKey(ValueKey('hermes-save-transcript-$format'));
  await tester.ensureVisible(action);
  await tester.tap(action);
  await tester.pumpAndSettle();
}

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
    }),
  );
  testWidgets(
    'unsupported native runner explains availability without fake save',
    (tester) async {
      final channel = FakeHermesChannel()..replaceTranscript(history());
      addTearDown(channel.dispose);
      await open(tester, channel, saver: Saver()..supported = false);
      await actions(tester);
      expect(
        find.text('File export is available in the browser and on Linux only.'),
        findsOneWidget,
      );
      expect(find.text('Save as text'), findsNothing);
      expect(channel.loadEarlierMessagesCalls, 0);
    },
  );
  for (final format in ['text', 'markdown']) {
    testWidgets(
      '$format export equals existing copy for all 250 loaded Unicode turns',
      (tester) async {
        final channel = FakeHermesChannel(
          sessionsWithEarlierMessages: {'sess_1'},
        )..replaceTranscript(history());
        final saver = Saver();
        addTearDown(channel.dispose);
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String;
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
        await open(tester, channel, saver: saver);
        await actions(tester);
        expect(saver.writes, isEmpty);
        expect(
          find.textContaining('Older unfetched history is not included'),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(ValueKey('hermes-copy-transcript-$format')),
        );
        await tester.pumpAndSettle();
        await actions(tester);
        await save(tester, format);
        final result = utf8.decode(saver.writes.single.bytes);
        expect(result, copied);
        expect(
          RegExp('Synthetic loaded turn [0-9]+').allMatches(result).length,
          250,
        );
        expect(result, contains('日本語 😀'));
        expect(
          saver.writes.single.filename,
          'hermes-transcript.${format == 'text' ? 'txt' : 'md'}',
        );
        expect(channel.loadEarlierMessagesCalls, 0);
        expect(channel.sentImageDataUrls, isEmpty);
      },
    );
  }
  testWidgets(
    'metadata, text, tool payload and attachment use shared copy redaction',
    (tester) async {
      final channel = FakeHermesChannel();
      channel.replaceSessions(const [
        HermesSession(
          id: 'sess_1',
          source: 'synthetic',
          title: 'Authorization: Bearer synthetic-value',
          model: '/tmp/model.txt',
          endReason: 'token=synthetic-value',
          hasSystemPrompt: true,
        ),
      ], activeSessionId: 'sess_1');
      channel.replaceTranscript([
        history(1).single.copyWith(
          text:
              '**Keep** <script>inert()</script> Authorization: Bearer synthetic-value /tmp/example.txt',
          attachment: const HermesTurnAttachment(
            name: '/tmp/example.txt',
            kind: HermesAttachmentKind.file,
          ),
        ),
        HermesChatTurn(
          id: 'tool',
          sessionId: 'sess_1',
          author: HermesTurnAuthor.system,
          createdAt: DateTime.utc(2026),
          kind: HermesTurnKind.toolCall,
          toolCall: const HermesToolCall(
            name: 'synthetic',
            status: 'completed',
            result: 'synthetic-value',
          ),
        ),
      ]);
      final saver = Saver();
      addTearDown(channel.dispose);
      await open(tester, channel, saver: saver);
      await actions(tester);
      await save(tester, 'markdown');
      final text = utf8.decode(saver.writes.single.bytes);
      expect(text, isNot(contains('synthetic-value')));
      expect(text, isNot(contains('/tmp/')));
      expect(text, contains('[redacted]'));
      expect(text, contains('[redacted-path]'));
      expect(text, contains('**Keep** <script>inert()</script>'));
      expect(text, contains('Hermes host activity'));
      expect(text, isNot(contains('result:')));
    },
  );
  for (final stage in ['before', 'during']) {
    for (final owner in ['session', 'profile', 'origin']) {
      testWidgets('$owner change $stage save cannot write another owner', (
        tester,
      ) async {
        final channel = FakeHermesChannel()..replaceTranscript(history(2));
        final saver = Saver()..gate = Completer<void>();
        addTearDown(channel.dispose);
        await open(tester, channel, saver: saver);
        await actions(tester);
        if (stage == 'during') await save(tester);
        if (owner == 'session') {
          await channel.createSession();
        }
        if (owner == 'profile') {
          await channel.selectProfile('synthetic-profile');
        }
        if (owner == 'origin') {
          await channel.connect(baseUrl: 'http://127.0.0.1:12345');
        }
        channel.replaceTranscript(
          history(1).map((t) => t.copyWith(text: 'NEW OWNER')).toList(),
        );
        await tester.pumpAndSettle();
        if (stage == 'before') await save(tester);
        saver.gate!.complete();
        await tester.pumpAndSettle();
        expect(saver.writes, isEmpty);
        if (stage == 'before') {
          expect(saver.snapshots, isEmpty);
        } else {
          expect(
            utf8.decode(saver.snapshots.single.bytes),
            isNot(contains('NEW OWNER')),
          );
        }
        expect(
          find.textContaining('Transcript download requested.'),
          findsNothing,
        );
      });
    }
  }
  testWidgets(
    'snapshot includes updates up to confirmation, freezes after; overlapping actions write once',
    (tester) async {
      final channel = FakeHermesChannel()..replaceTranscript(history(1));
      final saver = Saver()..gate = Completer<void>();
      addTearDown(channel.dispose);
      await open(tester, channel, saver: saver);
      await actions(tester);
      channel.replaceTranscript(history(2));
      await tester.pumpAndSettle();
      final tile = tester.widget<ListTile>(
        find.byKey(const ValueKey('hermes-save-transcript-text')),
      );
      tile.onTap!();
      tile.onTap!();
      await tester.pumpAndSettle();
      channel.replaceTranscript(history(3));
      await actions(tester);
      expect(find.text('Save as text'), findsNothing);
      saver.gate!.complete();
      await tester.pumpAndSettle();
      expect(saver.writes.length, 1);
      expect(
        utf8.decode(saver.writes.single.bytes),
        contains('Synthetic loaded turn 1'),
      );
      expect(
        utf8.decode(saver.writes.single.bytes),
        isNot(contains('Synthetic loaded turn 2')),
      );
    },
  );
  for (final outcome in ['cancel', 'dispose', 'fail', 'oversize']) {
    testWidgets('$outcome produces no write or false success', (tester) async {
      final channel = FakeHermesChannel()..replaceTranscript(history(1));
      final saver = Saver()
        ..cancel = outcome == 'cancel'
        ..fail = outcome == 'fail';
      if (outcome == 'dispose') saver.gate = Completer<void>();
      if (outcome == 'oversize') {
        channel.replaceTranscript([
          HermesChatTurn(
            id: 'large',
            sessionId: 'sess_1',
            author: HermesTurnAuthor.system,
            kind: HermesTurnKind.toolCall,
            createdAt: DateTime.utc(2026),
            text: 'x' * (hermesTranscriptExportByteLimit + 1),
            toolCall: const HermesToolCall(
              name: 'synthetic',
              status: 'completed',
            ),
          ),
        ]);
      }
      addTearDown(channel.dispose);
      await open(tester, channel, saver: saver);
      await actions(tester);
      await save(tester);
      if (outcome == 'dispose') {
        await tester.pumpWidget(const SizedBox());
        saver.gate!.complete();
        await tester.pumpAndSettle();
      }
      expect(saver.writes, isEmpty);
      expect(
        find.textContaining('Transcript download requested.'),
        findsNothing,
      );
      expect(find.textContaining('/tmp/private-file'), findsNothing);
      if (outcome == 'oversize') {
        expect(find.textContaining('too large to export'), findsOneWidget);
      }
      if (outcome == 'fail') {
        expect(find.textContaining('could not be exported'), findsOneWidget);
        saver.fail = false;
        await actions(tester);
        await save(tester);
        expect(saver.writes.length, 1);
      }
      expect(tester.takeException(), isNull);
    });
  }
  for (final width in [390.0, 1280.0]) {
    for (final format in ['text', 'markdown']) {
      testWidgets('delayed same-owner saved export $format $width', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final channel = FakeHermesChannel()..replaceTranscript(history(2));
        addTearDown(channel.dispose);
        final gate = Completer<void>();
        final saver = Saver()..startedWriteGate = gate;
        await open(tester, channel, saver: saver);
        final strings = AppLocalizations.of(
          tester.element(find.byType(HermesChatScreen)),
        );
        await actions(tester, compact: width == 390);
        await save(tester, format);
        expect(saver.writes.length, 1);
        expect(find.text(strings.transcriptExportSaved), findsNothing);
        gate.complete();
        await tester.pumpAndSettle();
        expect(find.text(strings.transcriptExportSaved), findsOneWidget);
        expect(find.text(strings.transcriptExportFailed), findsNothing);
        expect(
          find.text(strings.transcriptExportDownloadStarted),
          findsNothing,
        );
        expect(saver.snapshots.length, 1);
        expect(saver.writes.length, 1);
        expect(tester.takeException(), isNull);
      });
      for (final transition in [
        'session',
        'profile',
        'origin',
        'replacement',
        'roundtrip',
        'dispose',
        'none',
      ]) {
        testWidgets('delayed export rejection $transition $format $width', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final channel = FakeHermesChannel()..replaceTranscript(history(2));
          addTearDown(channel.dispose);
          final gate = Completer<void>();
          final saver = Saver()..startedWriteGate = gate;
          final container = ProviderContainer(
            overrides: [
              hermesChannelProvider.overrideWithValue(channel),
              hermesTranscriptSaverProvider.overrideWithValue(saver),
            ],
          );
          addTearDown(container.dispose);
          final page = ValueNotifier<Widget>(const HermesChatScreen());
          addTearDown(page.dispose);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: ValueListenableBuilder<Widget>(
                  valueListenable: page,
                  builder: (_, child, _) => child,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final strings = AppLocalizations.of(
            tester.element(find.byType(HermesChatScreen)),
          );
          await actions(tester, compact: width == 390);
          await save(tester, format);
          expect(saver.writes.length, 1, reason: 'Write already admitted');
          final snapshot = saver.writes.single;
          final original = channel.state;
          if (transition == 'session' || transition == 'roundtrip') {
            await channel.selectSession('synthetic-other');
            if (transition == 'roundtrip') {
              await channel.selectSession(original.activeSessionId!);
              expect(channel.state.activeSessionId, original.activeSessionId);
              expect(
                channel.state.selectedProfileId,
                original.selectedProfileId,
              );
              expect(channel.state.connectedBaseUrl, original.connectedBaseUrl);
            }
          } else if (transition == 'profile') {
            await channel.selectProfile('synthetic-profile');
          } else if (transition == 'origin') {
            await channel.connect(baseUrl: 'http://127.0.0.1:12345');
          } else if (transition == 'replacement') {
            final replacement = FakeHermesChannel()
              ..replaceTranscript(history(2));
            addTearDown(replacement.dispose);
            expect(replacement.state.activeSessionId, original.activeSessionId);
            expect(
              replacement.state.selectedProfileId,
              original.selectedProfileId,
            );
            expect(
              replacement.state.connectedBaseUrl,
              original.connectedBaseUrl,
            );
            container.updateOverrides([
              hermesChannelProvider.overrideWithValue(replacement),
              hermesTranscriptSaverProvider.overrideWithValue(saver),
            ]);
          } else if (transition == 'dispose') {
            page.value = const SizedBox();
          }
          await tester.pumpAndSettle();
          gate.completeError(StateError('synthetic-write-rejected'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text(strings.transcriptExportSaved), findsNothing);
          expect(
            find.text(strings.transcriptExportDownloadStarted),
            findsNothing,
          );
          expect(find.textContaining('synthetic-write-rejected'), findsNothing);
          expect(
            find.text(strings.transcriptExportFailed),
            transition == 'none' ? findsOneWidget : findsNothing,
          );
          expect(saver.snapshots, [snapshot]);
          expect(saver.writes, [snapshot]);
          await tester.pump(const Duration(seconds: 5));
          await tester.pumpAndSettle();
          expect(saver.snapshots, [snapshot], reason: 'No automatic replay');
          if (transition == 'none') {
            saver.startedWriteGate = null;
            await actions(tester, compact: width == 390);
            await save(tester, format);
            expect(saver.snapshots.length, 2);
            expect(saver.writes.length, 2);
            expect(saver.writes.last.bytes, snapshot.bytes);
            expect(saver.writes.last.filename, snapshot.filename);
            expect(find.text(strings.transcriptExportFailed), findsNothing);
            expect(
              find.text(strings.transcriptExportDownloadStarted),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          }
        });
      }
    }
  }
  testWidgets('sheet cancellation does not export', (tester) async {
    final channel = FakeHermesChannel()..replaceTranscript(history(1));
    final saver = Saver();
    addTearDown(channel.dispose);
    await open(tester, channel, saver: saver);
    await actions(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(saver.writes, isEmpty);
  });
  testWidgets(
    '390px 200% sheet is scrollable, semantic and keyboard operable',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      final channel = FakeHermesChannel()..replaceTranscript(history(1));
      final saver = Saver();
      addTearDown(channel.dispose);
      await open(tester, channel, saver: saver, scale: 2);
      await actions(tester, compact: true);
      final target = find.byKey(
        const ValueKey('hermes-save-transcript-markdown'),
      );
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Save as Markdown'), findsOneWidget);
      var reached = false;
      for (var i = 0; i < 12; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        final tile = FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<ListTile>();
        if (tile?.key == const ValueKey('hermes-save-transcript-markdown')) {
          reached = true;
          break;
        }
      }
      expect(reached, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(saver.writes.single.format, HermesTranscriptExportFormat.markdown);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
}
