// GTK fixture qualification only: no live Agent, provider or physical input claim.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/providers/transcript_timestamps_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/app_router.dart';

import '../test/features/hermes_chat/support/fake_hermes_endpoint_store.dart';
import '../test/features/hermes_chat/support/fake_hermes_gateway_directory.dart';
import 'support/linux_chat_feature_fixture.dart';
import 'support/local_serve_chat_journey.dart';
import 'support/local_serve_read_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final root = requireLinuxChatRoot();
  if (!Platform.isLinux || Platform.environment['HOME'] != '$root/home') {
    throw StateError('Use the Linux campaign driver');
  }
  final restartPhase = Platform.environment['WING_LINUX_CHAT_RESTART_PHASE'];
  if (restartPhase != null) {
    registerLinuxChatRestartPhase(root, restartPhase);
    return;
  }
  // GTK's fallback PNG decoding needs shared-mime-info even with isolated XDG
  // lookup. Seed only this fixed public cache, never user settings/search roots.
  if (Platform.environment['XDG_DATA_DIRS'] != '$root/data') {
    throw StateError('Owned GTK data lookup required');
  }
  final mimeCache = File('$root/data/mime/mime.cache');
  mimeCache.parent.createSync(recursive: true);
  final mimeBytes = File('/usr/share/mime/mime.cache').readAsBytesSync();
  mimeCache.writeAsBytesSync(mimeBytes, flush: true);
  final cases = LinuxChatCases(root);
  tearDownAll(() async {
    for (final row in cases.rows) {
      row['evidence'] = {
        'mime_cache_sha256': sha256.convert(mimeBytes).toString(),
      };
    }
    await cases.publish();
  });
  final field = find.byKey(const ValueKey('hermes-composer-field'));

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> press(WidgetTester tester, String key) async {
    await tester.pump();
    final target = find.byKey(ValueKey(key));
    expect(target, findsOneWidget);
    await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
    await tester.pump();
    await tester.tap(target);
    await tester.pump();
  }

  Future<ProviderContainer> mount(
    WidgetTester tester,
    HermesApiChannel channel, {
    bool routed = false,
    Future<XFile?> Function()? picker,
  }) async {
    SharedPreferences.setMockInitialValues({
      'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
    });
    binding.testTextInput.register();
    addTearDown(binding.testTextInput.unregister);
    await binding.setSurfaceSize(const Size(1280, 1000));
    final directory = HermesGatewayDirectory(
      store: FakeHermesEndpointStore(),
      cache: FakeGatewayContactCache(),
      loader: FakeGatewaySummaryLoader({}),
      activeChannel: channel,
    );
    final container = ProviderContainer(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesEndpointStoreProvider.overrideWithValue(
          const EmptyHermesEndpointStore(),
        ),
        hermesGatewayDirectoryProvider.overrideWith((_) => directory),
        hermesVoiceCaptureServiceProvider.overrideWithValue(null),
        hermesTextToSpeechServiceProvider.overrideWithValue(null),
        if (picker != null)
          hermesAttachmentPickerProvider.overrideWithValue(picker),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      channel.dispose();
    });
    final router = routed ? container.read(routerProvider) : null;
    router?.go('/hermes');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: router != null
            ? MaterialApp.router(
                routerConfig: router,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              )
            : const MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: HermesChatScreen(),
              ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<(LinuxChatFeatureFixture, HermesApiChannel)> native(
    WidgetTester tester, {
    bool chat = false,
    bool history = false,
  }) async {
    final fixture = LinuxChatFeatureFixture();
    if (history) {
      fixture.canonical.add({
        'role': 'assistant',
        'row_id': 1,
        'text': 'Synthetic timestamp history',
      });
    }
    final channel = HermesApiChannel();
    addTearDown(() => tester.runAsync(fixture.close));
    await tester.runAsync(() async {
      await fixture.start();
      await channel.connectLocalServeReads(
        baseUrl: fixture.origin,
        credential: LocalServeReadFixture.token,
        canAccept: () => true,
      );
      if (chat) await channel.enableLocalServeChat();
    });
    await mount(tester, channel);
    return (fixture, channel);
  }

  Future<(LinuxChatApiFixture, HermesApiChannel)> api(
    WidgetTester tester,
    String scenario, {
    bool fallbackStreams = false,
    bool routed = false,
    Future<XFile?> Function()? picker,
  }) async {
    final fixture = LinuxChatApiFixture();
    addTearDown(() => tester.runAsync(fixture.close));
    final channel = HermesApiChannel();
    await tester.runAsync(() async {
      await fixture.start(fallbackStreams: fallbackStreams);
      await fixture.request('POST', '/e2e/hermes/$scenario');
      await channel.connect(baseUrl: fixture.origin);
    });
    await mount(tester, channel, routed: routed, picker: picker);
    return (fixture, channel);
  }

  Future<void> exportMenu(WidgetTester tester) async {
    await press(tester, 'hermes-copy-transcript-button');
    await tester.pumpAndSettle();
  }

  testWidgets(
    'native stream, stale approval, Stop and uncertain recovery retain exact counts',
    (tester) async {
      await cases.run(
        'chat.native-stream-stop-recovery',
        ['HD-CHAT', 'HD-APPROVAL', 'HD-STOP', 'HD-RESUME'],
        () async {
          await binding.setSurfaceSize(const Size(1280, 1000));
          binding.testTextInput.register();
          addTearDown(binding.testTextInput.unregister);
          final result = await runLocalServeChatJourney(tester);
          expect(result['sends'], 2);
          expect(result['answers'], 1);
          expect(result['stops'], 1);
          return {
            'send': result['sends'] as int,
            'approval': result['answers'] as int,
            'stop': result['stops'] as int,
            'stale_approval': 0,
          };
        },
      );
    },
  );

  testWidgets(
    'public Bot Chat adopts only canonical hidden history and restores ordinary draft',
    (tester) async {
      await cases.run(
        'chat.bot-canonical-draft',
        ['HD-BOTS', 'HD-DRAFT'],
        () async {
          final (fixture, channel) = await native(tester, chat: true);
          fixture.canonical.add({
            'role': 'assistant',
            'row_id': 1,
            'text': 'Synthetic canonical Bot history',
          });
          await tester.enterText(field, 'Synthetic ordinary draft');
          await press(tester, 'hermes-bot-chat-button');
          await waitLinuxChat(
            tester,
            () => channel.state.activeSessionId == 'bot-tip',
          );
          expect(find.text('Synthetic canonical Bot history'), findsOneWidget);
          expect(tester.widget<TextField>(field).controller!.text, isEmpty);
          expect(channel.state.visibleSessions.map((s) => s.id), [
            'default-session',
          ]);
          await tester.runAsync(() => channel.selectSession('default-session'));
          await tester.pumpAndSettle();
          expect(
            tester.widget<TextField>(field).controller!.text,
            'Synthetic ordinary draft',
          );
          expect(fixture.count('session.create'), 0);
          expect(fixture.count('prompt.submit'), 0);
          return fixture.operations;
        },
      );
    },
  );

  for (final failure in ['registry', 'hidden', 'history', 'replacement']) {
    testWidgets(
      'public Bot Chat rejects $failure adoption without creating or sending',
      (tester) async {
        await cases.run(
          'chat.bot-reject-$failure',
          ['HD-BOTS', 'HD-DRAFT'],
          () async {
            final (fixture, channel) = await native(tester, chat: true);
            await tester.enterText(field, 'Synthetic source draft');
            if (failure == 'registry') fixture.wrongRegistry = true;
            if (failure == 'hidden') fixture.tipHidden = false;
            if (failure == 'history') fixture.reportedCount = 1;
            if (failure == 'replacement') {
              fixture.lookupStarted = Completer<void>();
              fixture.lookupGate = Completer<void>();
            }
            await press(tester, 'hermes-bot-chat-button');
            await waitLinuxChat(
              tester,
              () => fixture.count('session.list') == 1,
            );
            if (failure == 'replacement') {
              await tester.runAsync(() => channel.selectProfile('demo'));
              await tester.pumpAndSettle();
              await press(tester, 'hermes-local-serve-chat');
              await waitLinuxChat(
                tester,
                () => channel.state.serveChat?.canSubmit == true,
              );
              await tester.enterText(field, 'Synthetic replacement draft');
              await tester.pump();
              expect(
                tester.widget<TextField>(field).controller!.text,
                'Synthetic replacement draft',
                reason:
                    'Replacement editor accepts input before releasing lookup',
              );
              fixture.lookupGate!.complete();
            }
            await waitLinuxChat(
              tester,
              () =>
                  find
                      .textContaining('Bot Chat could not be confirmed')
                      .evaluate()
                      .isNotEmpty ||
                  (failure == 'replacement' &&
                      channel.state.selectedProfileId == 'demo'),
            );
            // Drain the delayed response before asserting no late adoption.
            for (var i = 0; i < 20; i++) {
              await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 20)),
              );
              await tester.pump(const Duration(milliseconds: 20));
            }
            expect(
              channel.state.activeSessionId,
              failure == 'replacement' ? 'demo-session' : 'default-session',
            );
            expect(
              tester.widget<TextField>(field).controller!.text,
              failure == 'replacement'
                  ? 'Synthetic replacement draft'
                  : 'Synthetic source draft',
            );
            expect(fixture.count('session.create'), 0);
            expect(fixture.count('prompt.submit'), 0);
            return fixture.operations;
          },
        );
      },
    );
  }

  testWidgets(
    'API queue is parked on owner replacement and cannot consume the new draft',
    (tester) async {
      await cases.run(
        'chat.queue-owner-draft',
        ['HD-QUEUE', 'HD-DRAFT'],
        () async {
          final (fixture, channel) = await api(tester, 'session-restoration');
          await tester.enterText(field, 'Synthetic running turn');
          await press(tester, 'hermes-send-button');
          await waitLinuxChat(
            tester,
            () => find
                .byKey(const ValueKey('hermes-approval-banner'))
                .evaluate()
                .isNotEmpty,
          );
          for (final text in [
            'Synthetic queued first',
            'Synthetic queued second',
          ]) {
            await tester.enterText(field, text);
            await press(tester, 'hermes-send-button');
            await settle(tester);
          }
          expect(
            find.byKey(const ValueKey('hermes-queued-follow-up')),
            findsOneWidget,
          );
          await press(tester, 'hermes-queued-follow-up-manage');
          await settle(tester);
          final manager = find.byKey(
            const ValueKey('hermes-queued-follow-up-manage-dialog'),
          );
          final entries = find.descendant(
            of: manager,
            matching: find.byType(ListTile),
          );
          expect(entries, findsNWidgets(2));
          expect(
            find.descendant(
              of: entries.at(0),
              matching: find.text('Synthetic queued first'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: entries.at(1),
              matching: find.text('Synthetic queued second'),
            ),
            findsOneWidget,
          );
          await tester.tap(
            find.descendant(of: manager, matching: find.text('Close')),
          );
          await settle(tester);
          await press(tester, 'hermes-session-row-synthetic-restoration-001');
          await waitLinuxChat(
            tester,
            () => channel.state.activeSessionId == 'synthetic-restoration-001',
          );
          await tester.enterText(field, 'Synthetic replacement draft');
          await tester.runAsync(
            () => fixture.request('POST', '/v1/runs/run_1/approval', {
              'choice': 'once',
            }),
          );
          await settle(tester);
          expect(channel.state.activeSessionId, 'synthetic-restoration-001');
          expect(
            tester.widget<TextField>(field).controller!.text,
            'Synthetic replacement draft',
          );
          final receipt = await tester.runAsync(
            () => fixture.request('GET', '/e2e/hermes/session-restoration'),
          );
          expect(receipt!['mutations'], [
            {'method': 'POST', 'path': '/v1/runs'},
            {'method': 'POST', 'path': '/v1/runs/run_1/approval'},
          ]);
          return {'send': 1, 'queued': 2, 'replacement_send': 0};
        },
      );
    },
  );

  testWidgets(
    'API follow-up FIFO drains one deliberate queued turn per terminal result',
    (tester) async {
      await cases.run(
        'chat.queue-fifo',
        ['HD-QUEUE', 'HD-CHAT'],
        () async {
          final (fixture, channel) = await api(
            tester,
            'session-restoration',
            fallbackStreams: true,
          );
          await tester.enterText(field, 'Synthetic original');
          await press(tester, 'hermes-send-button');
          await waitLinuxChat(
            tester,
            () => fixture.sessionSubmissions.length == 1,
          );
          for (final text in [
            'Synthetic FIFO first',
            'Synthetic FIFO second',
          ]) {
            await tester.enterText(field, text);
            await press(tester, 'hermes-send-button');
            await settle(tester);
          }
          for (var i = 0; i < 2; i++) {
            expect(fixture.sessionSubmissions, hasLength(i + 1));
            fixture.sessionTerminals[i].complete();
            await waitLinuxChat(
              tester,
              () => fixture.sessionSubmissions.length == i + 2,
            );
          }
          fixture.sessionTerminals.last.complete();
          await waitLinuxChat(
            tester,
            () =>
                !channel.state.hasStreamingSessions &&
                find
                    .byKey(const ValueKey('hermes-queued-follow-up'))
                    .evaluate()
                    .isEmpty,
          );
          final history = await tester.runAsync(
            () => fixture.request(
              'GET',
              '/api/sessions/synthetic-restoration-000/messages',
            ),
          );
          expect(
            (history!['data'] as List)
                .where((row) => row['role'] == 'user')
                .map((row) => row['content']),
            [
              'Synthetic original',
              'Synthetic FIFO first',
              'Synthetic FIFO second',
            ],
          );
          final receipt = await tester.runAsync(
            () => fixture.request('GET', '/e2e/hermes/session-restoration'),
          );
          expect(receipt!['mutations'], isEmpty);
          expect(fixture.sessionSubmissions, [
            'Synthetic original',
            'Synthetic FIFO first',
            'Synthetic FIFO second',
          ]);
          return {
            'session_stream_send': fixture.sessionSubmissions.length,
            'terminal_results': fixture.sessionTerminals
                .where((g) => g.isCompleted)
                .length,
          };
        },
        backend: 'synthetic-loopback-http-sse',
      );
    },
  );

  testWidgets('native missing tabs attachments clarification stay unavailable', (
    tester,
  ) async {
    await cases.run(
      'chat.native-contract-gaps',
      ['HD-TABS', 'HD-ATTACH', 'HD-CLARIFY'],
      () async {
        final (fixture, channel) = await native(tester, chat: true);
        expect(
          tester
              .widget<IconButton>(
                find.byKey(const ValueKey('hermes-attachment-button')),
              )
              .onPressed,
          isNull,
        );
        expect(
          find.byKey(
            ValueKey((
              'hermes-workspace-tab',
              (
                gatewayId: fixture.origin,
                profileId: 'default',
                sessionId: 'default-session',
              ),
            )),
          ),
          findsNothing,
        );
        expect(channel.state.isServeReadOnly, true);
        fixture.sockets.last.add(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': 'synthetic-clarification',
            'method': 'clarification',
            'params': {
              'session_id': 'runtime-default-session',
              'question': 'Synthetic unavailable request',
            },
          }),
        );
        await waitLinuxChat(tester, () => fixture.replies.isNotEmpty);
        expect(fixture.replies.single, {
          'jsonrpc': '2.0',
          'id': 'synthetic-clarification',
          'error': {
            'code': -32601,
            'message': 'Unsupported internal operation',
          },
        });
        expect(
          find.byKey(const ValueKey('hermes-approval-banner')),
          findsNothing,
        );
        expect(fixture.count('prompt.submit'), 0);
        return fixture.operations;
      },
      unsupported:
          'Native serve has no qualified multi-tab/attachment/clarification contract; negative controls only.',
    );
  });

  testWidgets(
    'local slash timestamps change presentation without network mutation',
    (tester) async {
      await cases.run(
        'chat.local-timestamps',
        ['HD-COMMAND', 'HD-CHAT'],
        () async {
          final (fixture, channel) = await native(
            tester,
            chat: true,
            history: true,
          );
          final before = fixture.requests.length;
          final timestamp = find.byKey(
            ValueKey(
              'hermes-turn-timestamp-${channel.state.activeMessages.last.id}',
            ),
          );
          final labels = find.descendant(
            of: timestamp,
            matching: find.byType(Text),
          );
          expect(labels, findsNothing);
          await tester.enterText(field, '/timestamps on');
          await press(tester, 'hermes-send-button');
          await tester.pumpAndSettle();
          final context = tester.element(field);
          expect(
            ProviderScope.containerOf(
              context,
            ).read(transcriptTimestampsProvider),
            true,
          );
          expect(labels, findsOneWidget);
          await tester.enterText(field, '/ts off');
          await press(tester, 'hermes-send-button');
          await tester.pumpAndSettle();
          expect(
            ProviderScope.containerOf(
              context,
            ).read(transcriptTimestampsProvider),
            false,
          );
          expect(labels, findsNothing);
          expect(channel.state.activeSessionId, 'default-session');
          expect(fixture.requests.length, before);
          expect(fixture.count('prompt.submit'), 0);
          return fixture.operations;
        },
      );
    },
  );

  for (final outcome in ['save', 'refuse', 'cancel', 'owner']) {
    testWidgets(
      'paged JSON GTK $outcome keeps projection and destination outcomes separate',
      (tester) async {
        await cases.run(
          'chat.json-$outcome',
          ['HD-EXPORT', 'HD-DRAFT'],
          () async {
            final (fixture, channel) = await native(tester);
            final projection = channel.state.activeMessages
                .map((t) => (t.id, t.sessionId, t.author, t.text, t.createdAt))
                .toList();
            final file = File('$root/hermes-session.json');
            await tester.runAsync(
              () => file.writeAsString('synthetic existing destination'),
            );
            await exportMenu(tester);
            await press(tester, 'hermes-export-history-json');
            await tester.pumpAndSettle();
            expect(
              find.textContaining('not a frozen snapshot'),
              findsOneWidget,
            );
            expect(
              fixture.exportOffsets,
              isEmpty,
              reason: 'Consent must precede private history reads',
            );
            await press(tester, 'hermes-prepare-history-json');
            await waitLinuxChat(
              tester,
              () => find
                  .byKey(const ValueKey('hermes-save-history-json'))
                  .evaluate()
                  .isNotEmpty,
            );
            expect(fixture.exportOffsets, [0, 500]);
            await press(tester, 'hermes-save-history-json');
            await tester.runAsync(() async {
              if (outcome == 'owner') await channel.selectProfile('demo');
              await driveLinuxChatChooser(
                root,
                'hermes-session.json',
                cancel: outcome == 'cancel',
              );
            });
            await tester.pumpAndSettle();
            expect(
              file.readAsStringSync(),
              'synthetic existing destination',
              reason: 'Selecting a path is not replacement consent',
            );
            if (outcome == 'save' || outcome == 'refuse') {
              await waitLinuxChat(
                tester,
                () => find
                    .text('Save and allow replacement')
                    .evaluate()
                    .isNotEmpty,
              );
              expect(find.text('Save and allow replacement'), findsOneWidget);
              await tester.tap(
                find
                    .widgetWithText(
                      outcome == 'save' ? FilledButton : TextButton,
                      outcome == 'save'
                          ? 'Save and allow replacement'
                          : 'Cancel export',
                    )
                    .last,
              );
              await waitLinuxChat(
                tester,
                () => find
                    .text(
                      outcome == 'save'
                          ? 'Transcript saved to the selected file.'
                          : 'Save cancelled before writing.',
                    )
                    .evaluate()
                    .isNotEmpty,
              );
            }
            if (outcome == 'save') {
              final bytes = file.readAsBytesSync();
              final document = jsonDecode(utf8.decode(bytes)) as Map;
              expect(document.keys.toSet(), {
                'exported_at',
                'session_id',
                'title',
                'session',
                'message_count',
                'messages',
              });
              expect(document['session_id'], 'default-session');
              expect(document['session'], isNull);
              expect(document['message_count'], 501);
              final messages = document['messages'] as List;
              expect(messages, hasLength(501));
              expect((messages.first as Map)['session_id'], 'ancestor');
              expect((messages.last as Map)['content'], {
                'text': 'Synthetic raw 500 — 日本語 😀',
              });
              expect(
                DateTime.parse(document['exported_at'] as String).isUtc,
                true,
              );
              final expected = {
                'exported_at': document['exported_at'],
                'session_id': 'default-session',
                'title': 'default read session',
                'session': null,
                'message_count': 501,
                'messages': [
                  for (var i = 0; i < 501; i++)
                    {
                      'id': i + 1,
                      'session_id': i == 0 ? 'ancestor' : 'default-session',
                      'role': i == 500 ? 'tool' : 'assistant',
                      'content': {'text': 'Synthetic raw $i — 日本語 😀'},
                      'hidden': i == 0,
                    },
                ],
              };
              expect(bytes, utf8.encode(jsonEncode(expected)));
            } else {
              expect(file.readAsStringSync(), 'synthetic existing destination');
              expect(
                find.text('Transcript saved to the selected file.'),
                findsNothing,
              );
            }
            if (outcome != 'owner') {
              expect(
                channel.state.activeMessages.map(
                  (t) => (t.id, t.sessionId, t.author, t.text, t.createdAt),
                ),
                projection,
              );
            } else {
              expect(channel.state.activeSessionId, 'demo-session');
              expect(channel.state.activeMessages, hasLength(2));
            }
            expect(fixture.count('prompt.submit'), 0);
            return {...fixture.operations, 'writes': outcome == 'save' ? 1 : 0};
          },
          input: 'framework-controls;x11-gtk-chooser',
        );
      },
    );
  }

  for (final format in ['text', 'markdown']) {
    testWidgets(
      'loaded $format GTK save matches public copy without backfill',
      (tester) async {
        await cases.run(
          'chat.loaded-$format',
          ['HD-EXPORT'],
          () async {
            final (fixture, _) = await native(tester);
            final before = fixture.requests.length;
            await exportMenu(tester);
            await press(tester, 'hermes-copy-transcript-$format');
            await settle(tester);
            final copied = (await Clipboard.getData(
              Clipboard.kTextPlain,
            ))!.text!;
            final filename = format == 'text'
                ? 'hermes-transcript.txt'
                : 'hermes-transcript.md';
            final file = File('$root/$filename');
            if (file.existsSync()) file.deleteSync();
            await exportMenu(tester);
            await press(tester, 'hermes-save-transcript-$format');
            await tester.runAsync(() => driveLinuxChatChooser(root, filename));
            await settle(tester);
            expect(file.existsSync(), false);
            await tester.tap(
              find.widgetWithText(FilledButton, 'Save and allow replacement'),
            );
            await waitLinuxChat(
              tester,
              () => find
                  .text('Transcript saved to the selected file.')
                  .evaluate()
                  .isNotEmpty,
            );
            expect(file.readAsBytesSync(), utf8.encode(copied));
            expect(copied, contains('default fixture answer'));
            expect(fixture.requests.length, before);
            return {...fixture.operations, 'writes': 1};
          },
          input: 'framework-controls;x11-gtk-chooser;real-clipboard',
        );
      },
    );
  }

  Future<void> sessionAction(
    WidgetTester tester,
    String id,
    String action,
  ) async {
    await tester.enterText(
      find.byKey(const ValueKey('hermes-session-rail-search-field')),
      id,
    );
    await tester.pumpAndSettle();
    await press(tester, 'hermes-session-menu-$id');
    await settle(tester);
    await tester.tap(find.text(action).last);
    await tester.pumpAndSettle();
    await waitLinuxChat(
      tester,
      () => find.byType(PopupMenuItem<String>).evaluate().isEmpty,
    );
  }

  testWidgets(
    'API tabs preserve exact session drafts while public search and pagination stay read-only',
    (tester) async {
      await cases.run(
        'chat.api-tabs-search-pages',
        ['HD-TABS', 'HD-SEARCH', 'HD-DRAFT'],
        () async {
          final (fixture, channel) = await api(tester, 'session-restoration');
          final first = channel.state.activeSessionId!;
          expect(first, 'synthetic-restoration-000');
          await tester.enterText(field, 'Synthetic first-tab draft');
          await press(tester, 'hermes-session-row-synthetic-restoration-001');
          await waitLinuxChat(
            tester,
            () => channel.state.activeSessionId == 'synthetic-restoration-001',
          );
          await tester.enterText(field, 'Synthetic second-tab draft');
          final firstTab = find.byKey(
            ValueKey((
              'hermes-workspace-tab',
              (
                gatewayId: fixture.origin,
                profileId: channel.state.selectedProfileId,
                sessionId: first,
              ),
            )),
          );
          expect(firstTab, findsOneWidget);
          await tester.tap(firstTab);
          await waitLinuxChat(
            tester,
            () => channel.state.activeSessionId == first,
          );
          expect(
            tester.widget<TextField>(field).controller!.text,
            'Synthetic first-tab draft',
          );
          await tester.enterText(
            find.byKey(const ValueKey('hermes-session-rail-search-field')),
            'conversation 059',
          );
          await settle(tester);
          expect(
            find.byKey(
              const ValueKey('hermes-session-row-synthetic-restoration-059'),
            ),
            findsNothing,
          );
          await press(tester, 'hermes-session-rail-load-more');
          await waitLinuxChat(
            tester,
            () => channel.state.sessions.length == 60,
          );
          expect(
            find.byKey(
              const ValueKey('hermes-session-row-synthetic-restoration-059'),
            ),
            findsOneWidget,
          );
          expect(channel.state.activeSessionId, first);
          final receipt = await tester.runAsync(
            () => fixture.request('GET', '/e2e/hermes/session-restoration'),
          );
          expect(receipt!['mutations'], isEmpty);
          final pages = receipt['list_pages'] as List;
          expect(pages.map((p) => (p as Map)['offset']), [0, 50]);
          return {
            'list_pages': pages.length,
            'mutations': 0,
            'tab_activations': 1,
          };
        },
        backend: 'synthetic-loopback-http-sse',
      );
    },
  );

  testWidgets(
    'API public pin rename branch and delete use their rendered session identities once',
    (tester) async {
      await cases.run(
        'chat.api-session-actions',
        ['HD-SEARCH'],
        () async {
          final (fixture, channel) = await api(tester, 'session-restoration');
          const id = 'synthetic-restoration-000';
          await sessionAction(tester, id, 'Pin');
          await sessionAction(tester, id, 'Unpin');
          await sessionAction(tester, id, 'Rename');
          await tester.enterText(
            find.byKey(const ValueKey('hermes-session-title-field')),
            'Synthetic renamed',
          );
          await press(tester, 'hermes-session-title-save');
          await waitLinuxChat(
            tester,
            () => channel.state.sessions.any(
              (s) => s.id == id && s.title == 'Synthetic renamed',
            ),
          );
          await sessionAction(tester, id, 'Branch');
          await press(tester, 'hermes-session-branch-confirm');
          await waitLinuxChat(
            tester,
            () => channel.state.activeSessionId != id,
          );
          final child = channel.state.activeSessionId!;
          expect(channel.state.activeSession!.parentSessionId, id);
          await tester.enterText(
            find.byKey(const ValueKey('hermes-session-rail-search-field')),
            child,
          );
          await settle(tester);
          await sessionAction(tester, child, 'Delete');
          await press(tester, 'hermes-session-delete-confirm');
          await waitLinuxChat(
            tester,
            () => !channel.state.sessions.any((s) => s.id == child),
          );
          final receipt = await tester.runAsync(
            () => fixture.request('GET', '/e2e/hermes/session-restoration'),
          );
          expect(receipt!['mutations'], [
            {'method': 'PATCH', 'path': '/api/sessions/$id'},
            {'method': 'POST', 'path': '/api/sessions/$id/fork'},
            {'method': 'DELETE', 'path': '/api/sessions/$child'},
          ]);
          return {'rename': 1, 'fork': 1, 'delete': 1, 'pin_agent_writes': 0};
        },
        backend: 'synthetic-loopback-http-sse',
      );
    },
  );

  testWidgets(
    'API session model rejection retains selection for an explicit retry',
    (tester) async {
      await cases.run('chat.api-model-retry', ['HD-MODEL'], () async {
        final (fixture, channel) = await api(tester, 'model-picker');
        await press(tester, 'hermes-composer-model-chip');
        await settle(tester);
        await tester.enterText(
          find.byKey(const ValueKey('session-model-search')),
          'shared',
        );
        await settle(tester);
        await press(tester, 'session-model-alpha/shared');
        await settle(tester);
        await tester.tap(find.text('Use for session'));
        await tester.pump();
        await waitLinuxChat(
          tester,
          () => find
              .text('Hermes could not confirm this session model.')
              .evaluate()
              .isNotEmpty,
        );
        expect(
          find.byKey(const ValueKey('session-model-search')),
          findsOneWidget,
        );
        await tester.tap(find.text('Use for session'));
        await tester.pump();
        await waitLinuxChat(
          tester,
          () => find.text('Use a model for this session').evaluate().isEmpty,
        );
        expect(channel.state.activeSessionId, 'e2e-hermes-session');
        final receipt = await tester.runAsync(
          () => fixture.request('GET', '/e2e/hermes/model-picker'),
        );
        expect(receipt!['locks'], [
          {'provider': 'alpha', 'model': 'shared'},
          {'provider': 'alpha', 'model': 'shared'},
        ]);
        expect((receipt['selected'] as Map)['model'], 'shared');
        return {'model_lock': 2, 'implicit_retry': 0};
      }, backend: 'synthetic-loopback-http-sse');
    },
  );

  testWidgets(
    'late GTK attachment selection cannot stage against a replacement API session',
    (tester) async {
      await cases.run(
        'chat.attachment-owner',
        ['HD-ATTACH', 'HD-DRAFT'],
        () async {
          final chooserClosed = Completer<XFile?>();
          final deliverSelection = Completer<void>();
          addTearDown(() {
            if (!deliverSelection.isCompleted) deliverSelection.complete();
          });
          final (fixture, channel) = await api(
            tester,
            'session-restoration',
            picker: () async {
              final file = await openFile();
              chooserClosed.complete(file);
              await deliverSelection.future;
              return file;
            },
          );
          File(
            '$root/sample.txt',
          ).writeAsStringSync('Synthetic attachment only');
          await press(tester, 'hermes-attachment-button');
          await tester.runAsync(() async {
            await channel.selectSession('synthetic-restoration-001');
            await driveLinuxChatChooser(root, 'sample.txt', pick: true);
          });
          await waitLinuxChat(tester, () => chooserClosed.isCompleted);
          final selected = await tester.runAsync(() => chooserClosed.future);
          expect(
            selected,
            isNotNull,
            reason:
                'Cancellation must not satisfy stale selection qualification',
          );
          expect(selected!.name, 'sample.txt');
          expect(
            await tester.runAsync(selected.readAsString),
            'Synthetic attachment only',
          );
          await tester.pump();
          await tester.enterText(
            field,
            'Synthetic replacement attachment draft',
          );
          await tester.pump();
          expect(
            tester.widget<TextField>(field).controller!.text,
            'Synthetic replacement attachment draft',
          );
          deliverSelection.complete();
          await tester.runAsync(pumpEventQueue);
          await tester.pumpAndSettle();
          expect(find.text('sample.txt'), findsNothing);
          expect(
            tester.widget<TextField>(field).controller!.text,
            'Synthetic replacement attachment draft',
          );
          expect(channel.state.activeSessionId, 'synthetic-restoration-001');
          final receipt = await tester.runAsync(
            () => fixture.request('GET', '/e2e/hermes/session-restoration'),
          );
          expect(receipt!['mutations'], isEmpty);
          return {'picker': 1, 'stage_replacement': 0, 'send': 0};
        },
        backend: 'synthetic-loopback-http-sse',
        input: 'framework-controls;x11-gtk-chooser',
      );
    },
  );

  testWidgets('cached Stop callback cannot interrupt a newer API session run', (
    tester,
  ) async {
    await cases.run('chat.stale-stop', ['HD-STOP'], () async {
      final (fixture, channel) = await api(tester, 'session-restoration');
      await tester.enterText(field, 'Synthetic first active run');
      await press(tester, 'hermes-send-button');
      await waitLinuxChat(
        tester,
        () => find
            .byKey(const ValueKey('hermes-composer-stop-chip'))
            .evaluate()
            .isNotEmpty,
      );
      final staleStop = tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('hermes-composer-stop-chip')),
          )
          .onPressed!;
      await press(tester, 'hermes-session-row-synthetic-restoration-001');
      await waitLinuxChat(
        tester,
        () => channel.state.activeSessionId == 'synthetic-restoration-001',
      );
      await tester.enterText(field, 'Synthetic second active run');
      await press(tester, 'hermes-send-button');
      await waitLinuxChat(
        tester,
        () => find
            .byKey(const ValueKey('hermes-composer-stop-chip'))
            .evaluate()
            .isNotEmpty,
      );
      await waitLinuxChat(
        tester,
        () => find
            .byKey(const ValueKey('hermes-approval-banner'))
            .evaluate()
            .isNotEmpty,
      );
      staleStop();
      await settle(tester);
      final receipt = await tester.runAsync(
        () => fixture.request('GET', '/e2e/hermes/session-restoration'),
      );
      expect(receipt!['mutations'], [
        {'method': 'POST', 'path': '/v1/runs'},
        {'method': 'POST', 'path': '/v1/runs'},
      ]);
      expect(channel.state.activeSessionId, 'synthetic-restoration-001');
      await tester.runAsync(() async {
        await fixture.request('POST', '/v1/runs/run_1/stop', {});
        await fixture.request('POST', '/v1/runs/run_2/stop', {});
      });
      await waitLinuxChat(tester, () => !channel.state.hasStreamingSessions);
      return {'send': 2, 'stale_stop': 0, 'fixture_cleanup_stops': 2};
    }, backend: 'synthetic-loopback-http-sse');
  });

  testWidgets(
    'JSON consent denies frozen snapshot and atomic completeness claims',
    (tester) async {
      await cases.run(
        'chat.json-frozen-boundary',
        ['HD-EXPORT'],
        () async {
          final (fixture, _) = await native(tester);
          await exportMenu(tester);
          await press(tester, 'hermes-export-history-json');
          await settle(tester);
          expect(find.textContaining('not a frozen snapshot'), findsOneWidget);
          expect(
            find.textContaining(
              'not an Agent backup or proof of atomic completeness',
            ),
            findsOneWidget,
          );
          await press(tester, 'hermes-cancel-history-json');
          expect(fixture.exportOffsets, isEmpty);
          return fixture.operations;
        },
        unsupported:
            'Paged JSON has no frozen-snapshot/revision/atomic-completeness contract.',
      );
    },
  );

  testWidgets(
    'production HTTP SSE completion under Settings overlay retains Chat and draft',
    (tester) async {
      await cases.run(
        'chat.streaming-overlay',
        ['HD-CHAT'],
        () async {
          final (fixture, channel) = await api(
            tester,
            'reasoning-disclosure',
            routed: true,
          );
          final chat = tester.state(find.byType(HermesChatScreen));
          await tester.enterText(field, 'Synthetic overlay stream');
          await press(tester, 'hermes-send-button');
          await waitLinuxChat(
            tester,
            () => channel.state.activeMessages.any(
              (t) => t.text.contains('Synthetic old reasoning'),
            ),
          );
          await tester.enterText(field, 'Synthetic overlay draft');
          await tester.pump();
          await tester.tap(find.bySemanticsLabel('Settings').last);
          await settle(tester);
          expect(
            find.byKey(const ValueKey('chat-workspace-overlay-close')),
            findsOneWidget,
          );
          await tester.runAsync(
            () => fixture.request(
              'POST',
              '/e2e/hermes/reasoning-disclosure/complete',
            ),
          );
          await waitLinuxChat(
            tester,
            () => channel.state.activeMessages.any(
              (t) => t.text == 'Hermes echo: Synthetic overlay stream',
            ),
          );
          expect(chat.mounted, true);
          await press(tester, 'chat-workspace-overlay-close');
          await settle(tester);
          expect(tester.state(find.byType(HermesChatScreen)), same(chat));
          expect(
            find.text('Hermes echo: Synthetic overlay stream'),
            findsWidgets,
          );
          expect(
            tester.widget<TextField>(field).controller!.text,
            'Synthetic overlay draft',
          );
          final count = await tester.runAsync(
            () => fixture.request('GET', '/e2e/hermes/run-count'),
          );
          expect(count!['runCount'], 1);
          return {'send': count['runCount'] as int, 'overlay_completions': 1};
        },
        backend: 'synthetic-loopback-http-sse',
      );
    },
  );

  testWidgets(
    'two GTK processes restore the exact off-page session without replay',
    (tester) async {
      await cases.run(
        'chat.two-process-recovery',
        ['HD-RESUME'],
        () async {
          final (counts, evidence) = (await tester.runAsync(
            () => runLinuxChatRestartPair(root),
          ))!;
          cases.rows.last['restart_phases'] = evidence;
          return counts;
        },
        backend: 'synthetic-loopback-http-sse;real-preferences',
        storage: 'real-owned-preferences;synthetic-fixture-state',
        ownerCount: 1,
      );
    },
  );

  testWidgets('paged JSON cancellation discards a late HTTP page', (
    tester,
  ) async {
    await cases.run('chat.json-cancel-read', ['HD-EXPORT'], () async {
      final (fixture, _) = await native(tester);
      fixture.exportStarted = Completer<void>();
      fixture.exportGate = Completer<void>();
      fixture.exportResponded = Completer<void>();
      await exportMenu(tester);
      await press(tester, 'hermes-export-history-json');
      await tester.pumpAndSettle();
      await press(tester, 'hermes-prepare-history-json');
      await waitLinuxChat(tester, () => fixture.exportStarted!.isCompleted);
      await press(tester, 'hermes-cancel-history-json');
      fixture.exportGate!.complete();
      await tester.runAsync(() async {
        await fixture.exportResponded!.future.timeout(
          const Duration(seconds: 5),
        );
        await pumpEventQueue();
      });
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('hermes-save-history-json')),
        findsNothing,
      );
      expect(fixture.exportOffsets, [0]);
      expect(fixture.count('prompt.submit'), 0);
      return {...fixture.operations, 'writes': 0};
    });
  });
}
