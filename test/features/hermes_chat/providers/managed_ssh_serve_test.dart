import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/setup/secure_hermes_serve_recovery_store.dart';
import 'package:wing/core/hermes/ssh/managed_ssh.dart';
import 'package:wing/core/hermes/ssh/ssh_connection_request.dart';
import 'package:wing/features/hermes_chat/providers/managed_ssh_connection_controller.dart';

import '../../../../integration_test/support/local_serve_chat_fixture.dart';
import '../../../../integration_test/support/local_serve_read_fixture.dart';

class _RecoveryStore implements HermesServeRecoveryStore {
  final saved = <HermesServeRecoverySelection>[];
  Completer<void>? heldClear;
  Completer<void>? clearing;
  @override
  Future<HermesServeRecoverySelection?> load() async => null;
  @override
  Future<void> save(HermesServeRecoverySelection selection) async {
    saved.add(selection);
  }

  @override
  Future<void> clear() async {
    if (!(clearing?.isCompleted ?? true)) clearing!.complete();
    await heldClear?.future;
  }
}

// Only the SSH network boundary is substituted; Agent HTTP, ticket, RPC,
// channel/controller ownership and recovery policy are production code.
class _Forward extends ManagedSshForward {
  _Forward(this.origin);
  final String origin;
  final ended = Completer<void>();
  @override
  Future<ManagedSshTunnel> connect({
    required ManagedSshConfig configuration,
    required ManagedSshCredentials authentication,
    ManagedSshHostKeyVerifier? verifyHostKey,
    Duration timeout = const Duration(seconds: 20),
  }) async => ManagedSshTunnel(
    agentUri: Uri.parse(origin),
    done: ended.future,
    close: disconnect,
  );
  @override
  Future<void> disconnect() async {
    if (!ended.isCompleted) ended.complete();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LocalServeChatFixture fixture;
  late _RecoveryStore store;
  late HermesApiChannel channel;
  late _Forward forward;
  late ManagedSshConnectionController controller;
  setUp(() async {
    HttpOverrides.global = null;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    fixture = LocalServeChatFixture();
    await fixture.start();
    store = _RecoveryStore();
    channel = HermesApiChannel(serveRecoveryStore: store);
    forward = _Forward(fixture.origin);
    controller = ManagedSshConnectionController(forward, channel);
  });
  tearDown(() async {
    controller.dispose();
    channel.dispose();
    await fixture.close();
    debugDefaultTargetPlatformOverride = null;
  });
  Future<bool> connect({String token = LocalServeReadFixture.token}) =>
      controller.connectSsh(
        SshConnectionRequest(
          host: 'example.invalid',
          sshPort: 22,
          username: 'synthetic',
          password: 'synthetic-password',
          agentPort: 8642,
          agentBearerToken: token,
          transport: SshAgentTransport.serve,
        ),
        verifyHostKey: (_, _) => true,
      );

  test(
    'Android SSH serve reads and deliberate chat never save a transient origin',
    () async {
      expect(await connect(), true);
      expect(channel.state.isServeReadOnly, true);
      expect(channel.state.activeMessages.last.text, 'default fixture answer');
      expect(fixture.minted, 0);
      await channel.selectProfile('demo');
      expect(channel.state.selectedProfileId, 'demo');
      expect(channel.state.activeSessionId, 'demo-session');
      await channel.enableLocalServeChat();
      expect(channel.state.serveChat?.canSubmit, true);
      expect(fixture.count('prompt.submit'), 0);
      fixture.dropSubmit = true;
      await expectLater(
        channel.sendText('deliberate synthetic turn'),
        throwsA(isA<Exception>()),
      );
      expect(channel.state.hasUnreconciledRun, true);
      fixture.dropSubmit = false;
      await channel.retryLocalServeConversation();
      expect(channel.state.serveChat?.canSubmit, true);
      expect(fixture.count('prompt.submit'), 1);
      final submitted = fixture.rpc.singleWhere(
        (r) => r['method'] == 'prompt.submit',
      );
      expect(submitted['params'], containsPair('profile', 'demo'));
      expect(
        submitted['params'],
        containsPair('session_id', 'runtime-demo-session'),
      );
      expect(store.saved, isEmpty);
    },
  );

  test(
    'Android SSH separates REST authentication from ticket and owner authorization',
    () async {
      expect(await connect(token: 'synthetic-wrong-token'), false);
      expect(channel.state.isConnected, false);
      expect(fixture.minted, 0);
      forward = _Forward(fixture.origin);
      controller.dispose();
      controller = ManagedSshConnectionController(forward, channel);
      expect(await connect(), true);
      fixture.denyTicket = true;
      await channel.enableLocalServeChat();
      expect(channel.state.isConnected, true);
      expect(channel.state.serveChat, isNull);
      await expectLater(channel.sendText('not sent'), throwsStateError);
      fixture.denyTicket = false;
      fixture.resumedProfile = 'different-owner';
      await channel.enableLocalServeChat();
      expect(channel.state.serveChat, isNull);
      expect(fixture.count('prompt.submit'), 0);
      expect(fixture.count('approval.respond'), 0);
      expect(fixture.count('session.interrupt'), 0);
      expect(store.saved, isEmpty);
    },
  );

  test(
    'superseded SSH cleanup cannot adopt or disconnect a same-origin replacement',
    () async {
      fixture.unsupported = true;
      await channel.connectLocalServeReads(
        baseUrl: fixture.origin,
        credential: LocalServeReadFixture.token,
      );
      fixture.unsupported = false;
      store.heldClear = Completer<void>();
      store.clearing = Completer<void>();
      fixture.profilesRequested = Completer<void>();
      fixture.holdProfiles = Completer<void>();
      final obsolete = connect();
      await store.clearing!.future;
      final replacement = channel.retryLocalServeConversation();
      await fixture.profilesRequested!.future;
      store.heldClear!.complete();
      expect(await obsolete, false);
      fixture.holdProfiles!.complete();
      await replacement;
      expect(channel.state.isConnected, true);
      expect(channel.state.connectedBaseUrl, fixture.origin);
      expect(channel.state.activeSessionId, 'default-session');
      expect(forward.ended.isCompleted, true);
    },
  );

  test(
    'stale SSH reads cannot invalidate a replacement waiting for secure storage',
    () async {
      fixture.profilesRequested = Completer<void>();
      fixture.holdProfiles = Completer<void>();
      final obsolete = connect();
      await fixture.profilesRequested!.future;
      store.heldClear = Completer<void>();
      store.clearing = Completer<void>();
      final replacement = channel.connectLocalServeReads(
        baseUrl: fixture.origin,
        credential: LocalServeReadFixture.token,
      );
      await store.clearing!.future;
      fixture.holdProfiles!.complete();
      expect(await obsolete, false);
      store.heldClear!.complete();
      await replacement;
      expect(channel.state.isConnected, true);
      expect(channel.state.activeSessionId, 'default-session');
      expect(forward.ended.isCompleted, true);
    },
  );

  test(
    'SSH loss during serve adoption rejects late reads and cannot retry its origin',
    () async {
      fixture.profilesRequested = Completer<void>();
      fixture.holdProfiles = Completer<void>();
      final pending = connect();
      await fixture.profilesRequested!.future;
      await forward.disconnect();
      fixture.holdProfiles!.complete();
      expect(await pending, false);
      expect(channel.state.isConnected, false);
      final requests = List.of(fixture.requests);
      await channel.retryLocalServeConversation();
      expect(fixture.requests, requests);
      expect(store.saved, isEmpty);
    },
  );

  test(
    'SSH loss after chat qualification revokes only that lease without replay',
    () async {
      expect(await connect(), true);
      await channel.enableLocalServeChat();
      final disconnected = Completer<void>();
      void changed() {
        if (!channel.state.isConnected && !disconnected.isCompleted) {
          disconnected.complete();
        }
      }

      channel.addListener(changed);
      await forward.disconnect();
      await disconnected.future;
      channel.removeListener(changed);
      final requests = List.of(fixture.requests);
      await channel.retryLocalServeConversation();
      expect(fixture.requests, requests);
      expect(channel.state.serveChat, isNull);
      expect(fixture.count('prompt.submit'), 0);
      expect(fixture.count('approval.respond'), 0);
      expect(fixture.count('session.interrupt'), 0);
    },
  );
}
