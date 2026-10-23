import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/setup/secure_hermes_serve_recovery_store.dart';

import '../../../../integration_test/support/local_serve_chat_fixture.dart';
import '../../../../integration_test/support/local_serve_read_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LocalServeChatFixture fixture;
  late _DelayedRecoveryStore store;
  late HermesApiChannel channel;
  setUp(() async {
    HttpOverrides.global = null;
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    FlutterSecureStorage.setMockInitialValues({});
    fixture = LocalServeChatFixture();
    addTearDown(() => fixture.close());
    await fixture.start();
    store = _DelayedRecoveryStore();
    channel = HermesApiChannel(serveRecoveryStore: store);
    addTearDown(() => channel.dispose());
    await channel.connectLocalServeReads(
      baseUrl: fixture.origin,
      credential: LocalServeReadFixture.token,
    );
    await channel.selectProfile('demo');
    await channel.enableLocalServeChat();
  });

  test(
    'restart denial retains exact owner and Retry makes no mutation replay',
    () async {
      fixture.dropSubmit = true;
      await expectLater(
        channel.sendText('synthetic uncertain turn'),
        throwsA(isA<Exception>()),
      );
      final saved = (await store.load())!;
      expect(saved.checkpoint.profile, 'demo');
      expect(saved.checkpoint.storedSessionId, 'demo-session');
      expect(saved.checkpoint.runtimeSessionId, 'runtime-demo-session');
      expect(saved.checkpoint.origin.toString(), fixture.origin);
      expect(saved.checkpoint.uncertain, true);
      channel.dispose();
      channel = HermesApiChannel(serveRecoveryStore: store);
      fixture.denyHistory = true;
      expect(await channel.restoreSavedLocalServeConversation(), true);
      expect(channel.state.activeSessionId, 'demo-session');
      expect(channel.state.selectedProfileId, 'demo');
      expect(channel.state.serveChat, isNull);
      expect((await store.load())!.checkpoint.uncertain, true);
      fixture.denyHistory = false;
      fixture.dropSubmit = false;
      fixture.holdHistory = Completer<void>();
      final retry = channel.retryLocalServeConversation();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(channel.state.serveChat?.canSubmit, isNot(true));
      fixture.holdHistory!.complete();
      await retry;
      expect(channel.state.serveChat!.canSubmit, true);
      expect(
        channel.state.activeMessages.single.text,
        'synthetic uncertain turn',
      );
      expect(fixture.count('prompt.submit'), 1);
      expect(fixture.count('approval.respond'), 0);
      expect(fixture.count('session.interrupt'), 0);
      await channel.sendText('later deliberate turn');
      expect(fixture.count('prompt.submit'), 2);
      await channel.disconnect();
      expect(await store.load(), isNull);
    },
  );

  test(
    'unknown Stop remains owned while running, recovery never repeats Stop',
    () async {
      await channel.sendText('synthetic stop turn');
      fixture.dropStop = true;
      expect(
        await channel.stopTurn(channel.activeTurnInterruptionTarget!),
        false,
      );
      fixture.running = true;
      await channel.retryLocalServeConversation();
      expect(channel.state.serveChat!.canSubmit, false);
      expect(channel.state.hasUnreconciledRun, true);
      expect((await store.load())!.checkpoint.uncertain, true);
      fixture.running = false;
      await channel.retryLocalServeConversation();
      expect(channel.state.serveChat!.canSubmit, true);
      expect(fixture.count('session.interrupt'), 1);
      expect(fixture.count('prompt.submit'), 1);
    },
  );

  test(
    'overlapping public Stops reserve one interrupt before saving',
    () async {
      await channel.sendText('synthetic concurrent stop');
      final target = channel.activeTurnInterruptionTarget!;
      store.hold = Completer<void>();
      final first = channel.stopTurn(target);
      final second = channel.stopTurn(target);
      channel.stopActiveTurn();
      await store.entered.future;
      expect(channel.state.serveChat!.stopRequested, true);
      expect(fixture.count('session.interrupt'), 0);
      store.hold!.complete();
      expect(await first, true);
      expect(await second, false);
      expect(fixture.count('session.interrupt'), 1);
      expect(await channel.stopTurn(target), false);
      expect((await store.load())!.checkpoint.uncertain, true);
    },
  );

  test('terminal event during Stop save prevents the interrupt', () async {
    await channel.sendText('synthetic terminal race');
    store.hold = Completer<void>();
    final stop = channel.stopTurn(channel.activeTurnInterruptionTarget!);
    await store.entered.future;
    final terminal = Completer<void>();
    void observeTerminal() {
      if (channel.state.serveChat?.running == false && !terminal.isCompleted) {
        terminal.complete();
      }
    }

    channel.addListener(observeTerminal);
    fixture.event('message.complete', {
      'text': 'synthetic completed',
      'status': 'complete',
    }, session: 'demo-session');
    await terminal.future;
    channel.removeListener(observeTerminal);
    store.hold!.complete();
    expect(await stop, false);
    expect(fixture.count('session.interrupt'), 0);
    expect(channel.state.serveChat!.running, false);
    expect(channel.state.serveChat!.stopRequested, false);
    expect(channel.state.hasUnreconciledRun, true);
  });

  test('owner change during Stop save prevents the old interrupt', () async {
    await channel.sendText('synthetic owner race');
    store.hold = Completer<void>();
    final stop = channel.stopTurn(channel.activeTurnInterruptionTarget!);
    await store.entered.future;
    await channel.selectProfile('default');
    store.hold!.complete();
    expect(await stop, false);
    expect(fixture.count('session.interrupt'), 0);
    expect(channel.state.selectedProfileId, 'default');
    expect(channel.state.serveChat, isNull);
  });

  test('an abandoned connection cannot erase remembered ownership', () async {
    final before = (await store.load())!.checkpoint;
    final requests = fixture.requests.length;
    await channel.connectLocalServeReads(
      baseUrl: fixture.origin,
      credential: LocalServeReadFixture.token,
      canAccept: () => false,
    );
    expect(
      (await store.load())!.checkpoint.storedSessionId,
      before.storedSessionId,
    );
    expect(fixture.requests.length, requests);
    expect(channel.state.selectedProfileId, 'demo');
  });

  test('late restoration cannot replace a new explicit owner', () async {
    channel.dispose();
    channel = HermesApiChannel(serveRecoveryStore: store);
    fixture.holdHistory = Completer<void>();
    final restoration = channel.restoreSavedLocalServeConversation();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    await channel.disconnect();
    fixture.holdHistory!.complete();
    await restoration;
    expect(channel.state.isConnected, false);
    expect(await store.load(), isNull);
  });
}

class _DelayedRecoveryStore extends SecureHermesServeRecoveryStore {
  Completer<void>? hold;
  final entered = Completer<void>();

  @override
  Future<void> save(HermesServeRecoverySelection selection) async {
    if (hold != null) {
      if (!entered.isCompleted) entered.complete();
      await hold!.future;
    }
    await super.save(selection);
  }
}
