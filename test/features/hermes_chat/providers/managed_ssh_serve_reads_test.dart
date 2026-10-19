import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/setup/secure_hermes_serve_recovery_store.dart';
import 'package:wing/core/hermes/ssh/managed_ssh.dart';
import 'package:wing/core/hermes/ssh/ssh_connection_request.dart';
import 'package:wing/features/hermes_chat/providers/managed_ssh_connection_controller.dart';

import '../../../../integration_test/support/local_serve_chat_fixture.dart';
import '../../../../integration_test/support/local_serve_read_fixture.dart';

class _ServeFixture extends LocalServeChatFixture {
  int? rejection;
  @override
  Future<bool> handleExtra(HttpRequest request) async {
    if (rejection == null) return super.handleExtra(request);
    request.response.statusCode = rejection!;
    await request.response.close();
    return true;
  }
}

class _Forward extends ManagedSshForward {
  _Forward(this.origin);
  final String origin;
  final lost = Completer<void>();
  int closes = 0;
  Completer<void>? closeGate;

  @override
  Future<ManagedSshTunnel> connect({
    required ManagedSshConfig configuration,
    required ManagedSshCredentials authentication,
    ManagedSshHostKeyVerifier? verifyHostKey,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (!await (verifyHostKey?.call(
          configuration,
          ManagedSshHostKey('ssh-ed25519', List.filled(32, 7)),
        ) ??
        false)) {
      throw const ManagedSshException(ManagedSshFailure.hostKeyRejected);
    }
    return ManagedSshTunnel(
      agentUri: Uri.parse(origin),
      done: lost.future,
      close: () async {
        closes++;
        await closeGate?.future;
      },
    );
  }

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

Future<void> until(bool Function() condition) async {
  for (var i = 0; i < 2000 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(condition(), isTrue);
}

void main() {
  late _ServeFixture fixture;
  late HermesApiChannel channel;
  late _Forward forward;
  late ManagedSshConnectionController controller;
  late _Store store;

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    fixture = _ServeFixture();
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
          transport: serveReads
              ? SshAgentTransport.serve
              : SshAgentTransport.advertisedApi,
        ),
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
    await expectLater(
      connect(serveReads: false),
      throwsA(isA<ManagedSshAgentException>()),
    );
    expect(fixture.requests, isNot(contains('GET /api/profiles')));
    expect(channel.state.isConnected, isFalse);
  });

  for (final status in [401, 403, 404]) {
    test(
      'serve rejection $status retains its category after settled lease cleanup',
      () async {
        fixture.rejection = status;
        forward.closeGate = Completer<void>();
        var settled = false;
        final result = expectLater(
          connect(),
          throwsA(
            isA<ManagedSshAgentException>().having(
              (e) => e.kind,
              'kind',
              status == 404
                  ? HermesConnectionFailureKind.incompatibleResponse
                  : HermesConnectionFailureKind.authentication,
            ),
          ),
        ).then((_) => settled = true);
        await until(() => forward.closes == 1);
        expect(channel.state.status, HermesConnectionStatus.disconnected);
        expect(settled, isFalse);
        forward.closeGate!.complete();
        await result;
        expect(channel.state.isConnected, isFalse);
        expect(fixture.requests, ['GET /api/profiles']);
        expect(store.saves, 0);
      },
    );
  }

  test(
    'tunnel loss fences held profiles and leaves no credential for Retry',
    () async {
      fixture.holdProfiles = Completer<void>();
      fixture.profilesRequested = Completer<void>();
      final pending = expectLater(
        connect(),
        throwsA(isA<ManagedSshException>()),
      );
      await fixture.profilesRequested!.future;
      forward.lost.complete();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      fixture.holdProfiles!.complete();
      await pending;
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

  test('failed local reads retain the existing explicit Retry entry', () async {
    fixture.unsupported = true;
    await channel.connectLocalServeReads(
      baseUrl: fixture.origin,
      credential: LocalServeReadFixture.token,
    );
    expect(channel.state.isServeReadOnly, isTrue);
    expect(channel.state.isConnected, isFalse);
    expect(channel.canEnableLocalServeChat, isTrue);
    fixture.unsupported = false;
    await channel.retryLocalServeConversation();
    expect(channel.state.isConnected, isTrue);
    expect(channel.state.serveChat, isNull);
    expect(fixture.minted, 0);
  });

  for (final replace in [false, true]) {
    test(
      'held chat qualification is revoked by lease loss/replacement=$replace',
      () async {
        expect(await connect(), isTrue);
        fixture.holdHistory = Completer<void>();
        addTearDown(() {
          if (!fixture.holdHistory!.isCompleted) {
            fixture.holdHistory!.complete();
          }
        });
        final pending = channel.enableLocalServeChat();
        await until(() => fixture.count('session.history') == 1);
        if (replace) {
          final replacement = LocalServeReadFixture();
          await replacement.start();
          addTearDown(replacement.close);
          await channel.connectLocalServeReads(
            baseUrl: replacement.origin,
            credential: LocalServeReadFixture.token,
          );
          expect(channel.state.connectedBaseUrl, replacement.origin);
        } else {
          forward.lost.complete();
          await until(() => !channel.state.isConnected);
        }
        fixture.holdHistory!.complete();
        await pending;
        expect(channel.state.serveChat, isNull);
        await expectLater(channel.sendText('not sent'), throwsStateError);
        expect(fixture.count('prompt.submit'), 0);
        expect(fixture.count('approval.respond'), 0);
        expect(fixture.count('session.interrupt'), 0);
        expect(store.saves, 0);
        await until(() => forward.closes == 1);
        if (!replace) {
          await channel.retryLocalServeConversation();
          expect(fixture.minted, 1);
          // The interrupted lease stays an error until deliberate SSH reconnect.
          expect(channel.state.isConnected, isFalse);
          expect(channel.state.serveChat, isNull);
        }
      },
    );
  }

  test(
    'forwarded approval and Stop retain captured owner and reject stale actions',
    () async {
      expect(await connect(), isTrue);
      final approvals = <HermesApprovalRequest>[];
      final subscription = channel.approvalRequests.listen(approvals.add);
      addTearDown(subscription.cancel);
      await channel.enableLocalServeChat();
      await channel.sendText('deliberate fixture');
      fixture.approval();
      await until(() => approvals.isNotEmpty);
      final request = approvals.single;
      await channel.respondToApproval(
        approvalId: request.id,
        decision: HermesApprovalDecision.once,
        runId: request.runId,
        origin: request,
      );
      final answer = fixture.rpc.singleWhere(
        (r) => r['method'] == 'approval.respond',
      );
      expect(answer['params']['profile'], 'default');
      expect(answer['params']['session_id'], 'runtime-default-session');
      final target = channel.activeTurnInterruptionTarget!;
      expect(await channel.stopTurn(target), isTrue);
      expect(channel.state.serveChat!.running, isTrue);
      expect(channel.state.serveChat!.stopRequested, isTrue);
      await channel.selectProfile('demo');
      expect(await channel.stopTurn(target), isFalse);
      await expectLater(
        channel.respondToApproval(
          approvalId: request.id,
          decision: HermesApprovalDecision.once,
          runId: request.runId,
          origin: request,
        ),
        throwsStateError,
      );
      expect(fixture.count('prompt.submit'), 1);
      expect(fixture.count('approval.respond'), 1);
      expect(fixture.count('session.interrupt'), 1);
      expect(store.saves, 0);
    },
  );

  test(
    'forwarded uncertain Send reconciles deliberately without replay or persistence',
    () async {
      expect(await connect(), isTrue);
      await channel.enableLocalServeChat();
      fixture.dropSubmit = true;
      await expectLater(
        channel.sendText('uncertain fixture'),
        throwsA(isA<Exception>()),
      );
      await until(() => channel.state.hasUnreconciledRun);
      expect(channel.state.serveChat!.canSubmit, isFalse);
      fixture.dropSubmit = false;
      await channel.retryLocalServeConversation();
      expect(channel.state.serveChat!.canSubmit, isTrue);
      expect(channel.state.activeMessages.single.text, 'uncertain fixture');
      expect(fixture.minted, 2);
      expect(fixture.count('prompt.submit'), 1);
      expect(fixture.count('approval.respond'), 0);
      expect(fixture.count('session.interrupt'), 0);
      expect(store.saves, 0);
    },
  );

  test(
    'forwarded chat requires fresh ticket and exact negotiation without persistence',
    () async {
      expect(await connect(), isTrue);
      expect(channel.canEnableLocalServeChat, isTrue);
      expect(fixture.minted, 0);
      fixture.denyTicket = true;
      await channel.enableLocalServeChat();
      expect(channel.state.isConnected, isTrue);
      expect(channel.state.serveChat, isNull);
      await expectLater(channel.sendText('not sent'), throwsStateError);
      fixture.denyTicket = false;
      fixture.exclusive = false;
      await channel.enableLocalServeChat();
      expect(channel.state.serveChat, isNull);
      await expectLater(channel.sendText('not sent'), throwsStateError);
      fixture.exclusive = true;
      await channel.enableLocalServeChat();
      expect(channel.state.serveChat!.canSubmit, isTrue);
      expect(fixture.minted, 2);
      expect(fixture.count('prompt.submit'), 0);
      await channel.selectProfile('demo');
      expect(channel.state.serveChat, isNull);
      await channel.enableLocalServeChat();
      await channel.sendText('deliberate fixture');
      final submit = fixture.rpc.singleWhere(
        (r) => r['method'] == 'prompt.submit',
      );
      expect(submit['params']['profile'], 'demo');
      expect(submit['params']['session_id'], 'runtime-demo-session');
      expect(fixture.count('prompt.submit'), 1);
      expect(store.saves, 0);
      await controller.cancel();
      await channel.retryLocalServeConversation();
      expect(channel.state.isConnected, isFalse);
      expect(fixture.minted, 3);
      expect(store.saves, 0);
    },
  );
}
