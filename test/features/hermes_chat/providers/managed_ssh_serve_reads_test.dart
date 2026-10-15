import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/setup/secure_hermes_serve_recovery_store.dart';
import 'package:wing/core/hermes/ssh/managed_ssh.dart';
import 'package:wing/core/hermes/ssh/ssh_connection_request.dart';
import 'package:wing/features/hermes_chat/providers/managed_ssh_connection_controller.dart';

import '../../../../integration_test/support/local_serve_chat_fixture.dart';
import '../../../../integration_test/support/local_serve_read_fixture.dart';

class _Forward extends ManagedSshForward {
  _Forward(this.origin);
  final String origin;
  final lost = Completer<void>();
  int closes = 0;

  @override
  Future<ManagedSshTunnel> connect({
    required ManagedSshConfig configuration,
    required ManagedSshCredentials authentication,
    ManagedSshHostKeyVerifier? verifyHostKey,
    Duration timeout = const Duration(seconds: 20),
  }) async => ManagedSshTunnel(
    agentUri: Uri.parse(origin),
    done: lost.future,
    close: () async {
      closes++;
    },
  );

  @override
  Future<void> disconnect() async {}
}

class _Store implements HermesServeRecoveryStore {
  int saves = 0;
  @override
  Future<void> clear() async {}
  @override
  Future<HermesServeRecoverySelection?> load() async => null;
  @override
  Future<void> save(HermesServeRecoverySelection selection) async {
    saves++;
  }
}

void main() {
  late LocalServeChatFixture fixture;
  late HermesApiChannel channel;
  late _Forward forward;
  late ManagedSshConnectionController controller;
  late _Store store;

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    fixture = LocalServeChatFixture();
    await fixture.start();
    store = _Store();
    channel = HermesApiChannel(serveRecoveryStore: store);
    forward = _Forward(fixture.origin);
    controller = ManagedSshConnectionController(forward, channel);
  });
  tearDown(() async {
    await controller.cancel();
    controller.dispose();
    channel.dispose();
    await fixture.close();
    debugDefaultTargetPlatformOverride = null;
  });

  Future<bool> connect({bool serveReads = true, String? token}) =>
      controller.connectSsh(
        SshConnectionRequest(
          host: 'example.invalid',
          sshPort: 22,
          username: 'tester',
          password: 'synthetic-password',
          agentPort: 8642,
          agentBearerToken: token ?? LocalServeReadFixture.token,
        ),
        serveReads: serveReads,
        verifyHostKey: (_, _) async => true,
      );

  test(
    'Android explicit serve selection loads exact profile/history without mutation',
    () async {
      expect(await connect(), isTrue);
      expect(channel.state.isServeReadOnly, isTrue);
      expect(channel.state.selectedProfileId, 'default');
      expect(channel.state.activeSessionId, 'default-session');
      expect(channel.state.activeMessages.last.text, 'default fixture answer');
      await channel.selectProfile('demo');
      expect(channel.state.activeSessionId, 'demo-session');
      expect(channel.state.activeMessages.last.text, 'demo fixture answer');
      await expectLater(channel.sendText('not sent'), throwsStateError);
      expect(fixture.requests.every((r) => r.startsWith('GET ')), isTrue);
      expect(store.saves, 0);
    },
  );

  test('API remains default and does not guess serve after failure', () async {
    expect(await connect(serveReads: false), isFalse);
    expect(fixture.requests, isNot(contains('GET /api/profiles')));
    expect(channel.state.isConnected, isFalse);
  });

  test(
    'serve credential denial closes its lease without protocol fallback',
    () async {
      expect(await connect(token: 'synthetic-denied'), isFalse);
      expect(forward.closes, 1);
      expect(channel.state.isConnected, isFalse);
      expect(fixture.requests, ['GET /api/profiles']);
    },
  );

  test(
    'tunnel loss fences held profiles and leaves no credential for Retry',
    () async {
      fixture.holdProfiles = Completer<void>();
      fixture.profilesRequested = Completer<void>();
      final pending = connect();
      await fixture.profilesRequested!.future;
      forward.lost.complete();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      fixture.holdProfiles!.complete();
      expect(await pending, isFalse);
      await channel.retryLocalServeConversation();
      expect(channel.state.isConnected, isFalse);
      expect(fixture.requests, ['GET /api/profiles']);
      expect(forward.closes, 1);
    },
  );

  test('late serve adoption cannot replace a newer origin or owner', () async {
    final replacement = LocalServeReadFixture();
    await replacement.start();
    addTearDown(replacement.close);
    fixture.holdProfiles = Completer<void>();
    fixture.profilesRequested = Completer<void>();
    final pending = connect();
    await fixture.profilesRequested!.future;
    await channel.connectLocalServeReads(
      baseUrl: replacement.origin,
      credential: LocalServeReadFixture.token,
    );
    fixture.holdProfiles!.complete();
    expect(await pending, isFalse);
    expect(channel.state.connectedBaseUrl, replacement.origin);
    expect(channel.state.isConnected, isTrue);
    expect(forward.closes, 1);
    expect(fixture.requests, ['GET /api/profiles']);
  });

  test(
    'forwarded reads cannot negotiate chat or persist the ephemeral port',
    () async {
      expect(await connect(), isTrue);
      fixture.denyTicket = true;
      await channel.enableLocalServeChat();
      expect(channel.state.serveChat, isNull);
      expect(store.saves, 0);
      fixture.denyTicket = false;
      await channel.enableLocalServeChat();
      expect(channel.state.serveChat, isNull);
      expect(channel.canEnableLocalServeChat, isFalse);
      expect(fixture.requests.every((r) => r.startsWith('GET ')), isTrue);
      await controller.cancel();
      await channel.connectLocalServeReads(
        baseUrl: fixture.origin,
        credential: LocalServeReadFixture.token,
      );
      expect(channel.canEnableLocalServeChat, isTrue);
      await channel.enableLocalServeChat();
      expect(channel.state.serveChat!.canSubmit, isTrue);
      expect(store.saves, 1);
      expect(fixture.count('prompt.submit'), 0);
      expect(fixture.count('approval.respond'), 0);
      expect(fixture.count('session.stop'), 0);
    },
  );
}
