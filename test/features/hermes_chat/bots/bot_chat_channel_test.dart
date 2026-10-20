import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/client/hermes_web_read_client.dart';

import '../../../../integration_test/support/bot_chat_fixture.dart';
import '../../../../integration_test/support/local_serve_read_fixture.dart';

Future<bool> open(HermesApiChannel channel, {bool background = false}) =>
    channel.openBotChat(background: background);

void main() {
  late BotChatFixture fixture;
  late HermesApiChannel channel;
  Completer<void>? saving, saveGate;
  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    fixture = BotChatFixture();
    await fixture.start();
    channel = HermesApiChannel();
    saving = saveGate = null;
    await channel.connectForwardedServeReads(
      baseUrl: fixture.origin,
      credential: LocalServeReadFixture.token,
      canAccept: () => true,
      onAcquire: (_) {},
      persistRecovery: (_) async {
        if (!(saving?.isCompleted ?? true)) saving!.complete();
        await saveGate?.future;
      },
    );
    fixture.canonical.add({
      'role': 'assistant',
      'row_id': 1,
      'text': 'Synthetic Bot history',
    });
  });
  tearDown(() async {
    channel.dispose();
    await fixture.close();
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'exact hidden registry tip wins over the ordinary recent conversation',
    () async {
      expect(await open(channel), true);
      expect(channel.state.activeSessionId, 'bot-tip');
      expect(channel.state.activeMessages.single.text, 'Synthetic Bot history');
      expect(channel.state.activeSession!.title, 'Bot Chat');
      expect(
        channel.state.sessions.any((s) => s.id == 'default-session'),
        true,
      );
      expect(channel.state.visibleSessions.map((s) => s.id), [
        'default-session',
      ]);
      final reads = fixture.profilesRead.length;
      expect(await open(channel), true);
      expect(fixture.profilesRead.length, greaterThan(reads));
      expect(fixture.profilesRead, everyElement('default'));
      expect(fixture.count('session.create'), 0);
      expect(fixture.count('prompt.submit'), 0);
    },
  );

  test(
    'failed or contradictory empty lookup creates nothing and keeps the source',
    () async {
      fixture.lookupError = true;
      await expectLater(open(channel), throwsA(isA<HermesWebReadException>()));
      expect(channel.state.activeSessionId, 'default-session');
      fixture.lookupError = false;
      await open(channel);
      fixture.registryId = null;
      await expectLater(open(channel), throwsA(isA<HermesWebReadException>()));
      expect(channel.state.activeSessionId, 'bot-tip');
      expect(fixture.count('session.create'), 0);
    },
  );

  test(
    'confirmed absence materializes one hidden canonical chat without inference',
    () async {
      fixture.registryId = null;
      fixture.canonical.clear();
      expect(await open(channel), true);
      expect(channel.state.activeSessionId, 'new-bot');
      expect(fixture.count('session.create'), 1);
      expect(fixture.count('session.title'), 1);
      expect(fixture.count('prompt.submit'), 0);
    },
  );

  test('concurrent opens adopt the peer title-conflict winner', () async {
    fixture.registryId = null;
    fixture.conflict = true;
    expect(await Future.wait([open(channel), open(channel)]), [true, true]);
    expect(channel.state.activeSessionId, 'peer-bot');
    expect(fixture.count('session.create'), 1);
    expect(fixture.count('prompt.submit'), 0);
  });

  test(
    'late lookup cannot mint or select after a profile replacement',
    () async {
      fixture.registryId = null;
      fixture.lookupStarted = Completer<void>();
      fixture.lookupGate = Completer<void>();
      final pending = open(channel);
      await fixture.lookupStarted!.future;
      await channel.selectProfile('demo');
      fixture.lookupGate!.complete();
      expect(await pending, false);
      expect(channel.state.selectedProfileId, 'demo');
      expect(channel.state.activeSessionId, 'demo-session');
      expect(fixture.count('session.create'), 0);
      expect(fixture.count('session.resume'), 0);
    },
  );

  test(
    'background refresh never creates or steals foreground selection',
    () async {
      await open(channel);
      fixture.lookupStarted = Completer<void>();
      fixture.lookupGate = Completer<void>();
      final pending = open(channel, background: true);
      await fixture.lookupStarted!.future;
      await channel.selectSession('default-session');
      fixture.lookupGate!.complete();
      expect(await pending, false);
      expect(channel.state.activeSessionId, 'default-session');
      fixture.registryId = null;
      expect(await open(channel, background: true), false);
      expect(fixture.count('session.create'), 0);
    },
  );

  test('source completion does not revive an older pending Bot open', () async {
    await channel.enableLocalServeChat();
    final source = fixture.sockets.single;
    fixture.lookupStarted = Completer<void>();
    fixture.lookupGate = Completer<void>();
    final pending = open(channel);
    await fixture.lookupStarted!.future;
    await channel.sendText('Synthetic explicit source turn');
    final terminal = Completer<void>();
    void observe() {
      if (channel.state.serveChat?.running == false &&
          channel.state.hasUnreconciledRun &&
          !terminal.isCompleted) {
        terminal.complete();
      }
    }

    channel.addListener(observe);
    source.add(
      jsonEncode({
        'jsonrpc': '2.0',
        'method': 'event',
        'params': {
          'type': 'message.complete',
          'session_id': 'runtime-default-session',
          'seq': ++fixture.sequence,
          'payload': {'text': 'Synthetic source completion'},
        },
      }),
    );
    await terminal.future.timeout(const Duration(seconds: 10));
    channel.removeListener(observe);
    await channel.enableLocalServeChat();
    fixture.lookupGate!.complete();
    expect(await pending, false);
    expect(channel.state.activeSessionId, 'default-session');
    expect(channel.state.serveChat!.canSubmit, true);
    expect(fixture.count('prompt.submit'), 1);
  });

  test('staged reopen cannot withdraw the active Bot approval', () async {
    await open(channel);
    final source = fixture.sockets.single;
    fixture.holdHistory = Completer<void>();
    addTearDown(() {
      if (!fixture.holdHistory!.isCompleted) fixture.holdHistory!.complete();
    });
    fixture.historyStarted = Completer<void>();
    fixture.replyReceived = Completer<void>();
    final result = open(
      channel,
    ).then<Object>((value) => value, onError: (Object error) => error);
    await fixture.historyStarted!.future;
    final candidate = fixture.sockets.last;
    // Candidate receives the shared request before the source can invalidate it.
    fixture.approval(session: 'bot-tip');
    await Future.any([
      candidate.done,
      fixture.replyReceived!.future,
    ]).timeout(const Duration(seconds: 10));
    expect(fixture.replies, isEmpty);
    expect(await result, isA<HermesWebReadException>());
    final approval = channel.approvalRequests.first;
    fixture.approval(session: 'bot-tip', socket: source);
    final request = await approval.timeout(const Duration(seconds: 10));
    await channel.respondToApproval(
      approvalId: request.id,
      decision: HermesApprovalDecision.once,
      runId: request.runId,
      origin: request,
    );
    expect(channel.state.activeSessionId, 'bot-tip');
    expect(channel.state.serveChat!.canSubmit, true);
    expect(fixture.count('approval.respond'), 1);
    expect(fixture.count('prompt.submit'), 0);
    fixture.holdHistory!.complete();
  });

  test(
    'Bot adoption retires pending reader flags and permits ordinary pagination retry',
    () async {
      fixture.pageStarted = Completer<void>();
      fixture.pageGate = Completer<void>();
      Object? lateFailure;
      final pending = channel.loadMoreSessions().catchError((Object error) {
        lateFailure = error;
      });
      await fixture.pageStarted!.future;
      expect(channel.state.isLoadingMoreSessions, true);
      expect(await open(channel), true);
      fixture.pageGate!.complete();
      await pending;
      expect(channel.state.isLoadingMoreSessions, false);
      expect(lateFailure, isNull);
      await channel.loadMoreSessions();
      expect(channel.state.visibleSessions.map((s) => s.id), [
        'default-session',
        'default-extra',
      ]);
      expect(channel.state.activeSessionId, 'bot-tip');
    },
  );

  test(
    'persisted hidden state of registry and tip is required before adoption',
    () async {
      fixture.tipHidden = false;
      await expectLater(open(channel), throwsA(isA<HermesWebReadException>()));
      fixture.tipHidden = true;
      fixture.registryId = null;
      fixture.hidden = false;
      await expectLater(open(channel), throwsA(isA<HermesWebReadException>()));
      await expectLater(open(channel), throwsA(isA<HermesWebReadException>()));
      expect(channel.state.activeSessionId, 'default-session');
      expect(fixture.count('session.create'), 1);
      expect(fixture.count('prompt.submit'), 0);
    },
  );

  test(
    'unsettled target replay or missing history leaves the source usable',
    () async {
      await channel.enableLocalServeChat();
      final source = channel.state.serveChat;
      fixture.replayMissing = true;
      await expectLater(open(channel), throwsA(isA<UnsupportedError>()));
      expect(channel.state.activeSessionId, 'default-session');
      expect(channel.state.serveChat, same(source));
      fixture.replayMissing = false;
      fixture.approvalInReplay = true;
      await expectLater(open(channel), throwsA(isA<HermesWebReadException>()));
      expect(channel.state.serveChat, same(source));
      expect(fixture.replies, isEmpty);
      expect(fixture.count('approval.respond'), 0);
      fixture.approvalInReplay = false;
      fixture.reportedCount = 1;
      fixture.canonical.clear();
      await expectLater(open(channel), throwsA(isA<HermesWebReadException>()));
      expect(channel.state.activeSessionId, 'default-session');
      expect(channel.state.serveChat, same(source));
    },
  );

  test(
    'recovery persistence blocks Send and reports failure without raw detail',
    () async {
      saving = Completer<void>();
      saveGate = Completer<void>();
      final pending = open(channel);
      await saving!.future;
      await expectLater(
        channel.sendText('Synthetic not sent'),
        throwsStateError,
      );
      final failure = expectLater(pending, throwsStateError);
      saveGate!.completeError(StateError('Synthetic private storage detail'));
      await failure;
      expect(channel.state.serveChat, isNull);
      expect(channel.state.hasUnreconciledRun, true);
      expect(
        channel.state.errorMessage,
        isNot(contains('private storage detail')),
      );
      expect(fixture.count('prompt.submit'), 0);
    },
  );

  test(
    'denied canonical operation cannot replace authenticated ordinary chat',
    () async {
      await channel.enableLocalServeChat();
      final source = channel.state.serveChat;
      fixture.denied = true;
      await expectLater(open(channel), throwsA(isA<UnsupportedError>()));
      expect(channel.state.activeSessionId, 'default-session');
      expect(channel.state.serveChat, same(source));
      expect(fixture.count('session.create'), 0);
    },
  );
}
