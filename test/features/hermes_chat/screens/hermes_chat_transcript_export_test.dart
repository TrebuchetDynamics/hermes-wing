import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/client/hermes_session_history_export.dart';
import 'package:wing/core/hermes/models/hermes_web_reads.dart';
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
    Future<bool> Function()? confirmOverwrite,
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

class HistoryChannel extends FakeHermesChannel
    implements HermesSessionHistoryExportChannel {
  @override
  bool get canExportSessionHistory => true;
  int reads = 0;
  bool failRead = false;
  Completer<void>? readGate;
  @override
  HermesSessionHistoryExportAttempt beginSessionHistoryExport() =>
      HermesSessionHistoryExportAttempt(
        sessionId: state.activeSessionId!,
        title: 'Captured',
        isCurrent: () => true,
        readPage: (offset) async {
          reads++;
          if (readGate != null) await readGate!.future;
          if (failRead) throw StateError('private failure');
          return HermesWebRawHistoryPage.fromJson(
            {
              'session_id': 'sess_1',
              'profile': 'default',
              'messages': [
                {
                  'id': 1,
                  'session_id': 'ancestor',
                  'content': {'text': 'raw 日本語'},
                  'role': 'tool',
                },
              ],
              'pagination': {
                'limit': 500,
                'offset': offset,
                'order': 'oldest',
                'returned': 1,
              },
            },
            'default',
            offset: offset,
          );
        },
      );
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
  testWidgets('whole preparation deadline discards even a late page', (
    tester,
  ) async {
    final gate = Completer<HermesWebRawHistoryPage>();
    final attempt = HermesSessionHistoryExportAttempt(
      sessionId: 'requested',
      title: null,
      isCurrent: () => true,
      readPage: (_) => gate.future,
    );
    Object? failure;
    unawaited(
      attempt.collect().then<void>(
        (_) => fail('must not finish'),
        onError: (Object e) {
          failure = e;
        },
      ),
    );
    await tester.pump(const Duration(seconds: 60));
    expect(failure, isA<HermesWebReadException>());
    expect(attempt.isCurrent, isFalse);
    gate.complete(
      HermesWebRawHistoryPage.fromJson(
        {
          'session_id': 'requested',
          'profile': 'default',
          'messages': [],
          'pagination': {
            'limit': 500,
            'offset': 0,
            'order': 'oldest',
            'returned': 0,
          },
        },
        'default',
        offset: 0,
      ),
    );
    await tester.pump();
    expect(attempt.isCurrent, isFalse);
  });

  testWidgets(
    'private paged JSON needs consent, then separate Save with frozen raw bytes',
    (tester) async {
      final channel = HistoryChannel()..replaceTranscript(history(1));
      addTearDown(channel.dispose);
      final saver = Saver();
      await open(tester, channel, saver: saver);
      await actions(tester);
      final action = find.byKey(const ValueKey('hermes-export-history-json'));
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.textContaining('not a frozen snapshot'), findsOneWidget);
      expect(channel.reads, 0);
      expect(saver.writes, isEmpty);
      await tester.tap(
        find.byKey(const ValueKey('hermes-prepare-history-json')),
      );
      await tester.pumpAndSettle();
      expect(channel.reads, 1);
      expect(saver.writes, isEmpty);
      await tester.tap(find.byKey(const ValueKey('hermes-save-history-json')));
      await tester.pumpAndSettle();
      final snapshot = saver.writes.single;
      expect(snapshot.filename, 'hermes-session.json');
      expect((jsonDecode(utf8.decode(snapshot.bytes)) as Map)['messages'], [
        {
          'id': 1,
          'session_id': 'ancestor',
          'content': {'text': 'raw 日本語'},
          'role': 'tool',
        },
      ]);
      expect(channel.loadEarlierMessagesCalls, 0);
      channel.replaceTranscript(history(2));
      await tester.pumpAndSettle();
      expect(find.textContaining('History export was discarded'), findsNothing);
      await channel.selectSession('other');
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Transcript download requested.'),
        findsNothing,
      );
      expect(saver.writes, hasLength(1));
    },
  );
  for (final outcome in [
    'cancel',
    'owner',
    'dispose',
    'failure',
    'cancelReady',
    'ownerPicker',
    'saveCancel',
  ]) {
    testWidgets('paged $outcome discards private bytes without partial save', (
      tester,
    ) async {
      final channel = HistoryChannel()..replaceTranscript(history(1));
      addTearDown(channel.dispose);
      final saver = Saver();
      await open(tester, channel, saver: saver);
      await actions(tester);
      final action = find.byKey(const ValueKey('hermes-export-history-json'));
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      channel.readGate = Completer<void>();
      channel.failRead = outcome == 'failure';
      await tester.tap(
        find.byKey(const ValueKey('hermes-prepare-history-json')),
      );
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      if (outcome == 'cancelReady' ||
          outcome == 'ownerPicker' ||
          outcome == 'saveCancel') {
        channel.readGate!.complete();
        await tester.pumpAndSettle();
        final cachedSave = tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('hermes-save-history-json')),
            )
            .onPressed!;
        if (outcome == 'cancelReady') {
          await tester.tap(
            find.byKey(const ValueKey('hermes-cancel-history-json')),
          );
          // Route disposal is delayed by its reverse animation. A retained
          // callback must already be inert in that very same frame.
          cachedSave();
        } else if (outcome == 'saveCancel') {
          saver.cancel = true;
          cachedSave();
        } else {
          saver.gate = Completer<void>();
          cachedSave();
          await tester.pump();
          await channel.selectSession('other');
          saver.gate!.complete();
        }
      }
      if (outcome == 'cancel') {
        await tester.tap(
          find.byKey(const ValueKey('hermes-cancel-history-json')),
        );
      }
      if (outcome == 'owner') await channel.selectSession('other');
      if (outcome == 'dispose') await tester.pumpWidget(const SizedBox());
      await tester.pump();
      if (!channel.readGate!.isCompleted) channel.readGate!.complete();
      await tester.pumpAndSettle();
      expect(saver.writes, isEmpty);
      if (outcome == 'saveCancel') {
        expect(find.text('Save cancelled before writing.'), findsOneWidget);
      }
      expect(
        find.byKey(const ValueKey('hermes-save-history-json')),
        findsNothing,
      );
      expect(find.textContaining('private failure'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

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
