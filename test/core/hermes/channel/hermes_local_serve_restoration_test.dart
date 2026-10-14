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
  late SecureHermesServeRecoveryStore store;
  late HermesApiChannel channel;
  setUp(() async {
    HttpOverrides.global = null;
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    FlutterSecureStorage.setMockInitialValues({});
    fixture = LocalServeChatFixture();
    await fixture.start();
    store = SecureHermesServeRecoveryStore();
    channel = HermesApiChannel(serveRecoveryStore: store);
    await channel.connectLocalServeReads(
      baseUrl: fixture.origin,
      credential: LocalServeReadFixture.token,
    );
    await channel.selectProfile('demo');
    await channel.enableLocalServeChat();
  });
  tearDown(() async {
    channel.dispose();
    await fixture.close();
    debugDefaultTargetPlatformOverride = null;
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
