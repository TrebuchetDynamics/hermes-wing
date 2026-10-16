import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/ssh/managed_ssh.dart';
import 'package:wing/core/hermes/ssh/ssh_connection_request.dart';
import 'package:wing/features/hermes_chat/providers/managed_ssh_connection_controller.dart';

import '../../../../integration_test/support/local_serve_read_fixture.dart';

class _Fixture extends LocalServeReadFixture {
  final reads = <Uri>[];
  bool denyHistory = false;
  Completer<void>? holdHistory;
  Completer<void>? historyRequested;

  @override
  Future<bool> handleExtra(HttpRequest request) async {
    reads.add(request.uri);
    if (request.uri.path.endsWith('/messages')) {
      if (!(historyRequested?.isCompleted ?? true)) {
        historyRequested!.complete();
      }
      await holdHistory?.future;
      if (denyHistory) {
        request.response.statusCode = 404;
        await request.response.close();
        return true;
      }
    }
    if (request.uri.path != '/api/sessions') return false;
    final profile = request.uri.queryParameters['profile']!;
    request.response.headers.contentType = ContentType.json;
    request.response.write(
      jsonEncode({
        'sessions': [
          session('$profile-recent', profile),
          session('$profile-session', profile),
        ],
        'total': 2,
        'limit': int.parse(request.uri.queryParameters['limit']!),
        'offset': 0,
        'storage': {},
      }),
    );
    await request.response.close();
    return true;
  }
}

class _Forward extends ManagedSshForward {
  _Forward(this.origin);
  String origin;
  Completer<void> lost = Completer<void>();
  int closes = 0;

  @override
  Future<ManagedSshTunnel> connect({
    required ManagedSshConfig configuration,
    required ManagedSshCredentials authentication,
    ManagedSshHostKeyVerifier? verifyHostKey,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    lost = Completer<void>();
    return ManagedSshTunnel(
      agentUri: Uri.parse(origin),
      done: lost.future,
      close: () async {
        closes++;
      },
    );
  }
}

void main() {
  late _Fixture first, replacement;
  late HermesApiChannel channel;
  late _Forward forward;
  late ManagedSshConnectionController controller;

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    first = _Fixture();
    replacement = _Fixture();
    await first.start();
    await replacement.start();
    channel = HermesApiChannel();
    forward = _Forward(first.origin);
    controller = ManagedSshConnectionController(forward, channel);
  });
  tearDown(() async {
    if (!(replacement.holdHistory?.isCompleted ?? true)) {
      replacement.holdHistory!.complete();
    }
    await controller.cancel();
    controller.dispose();
    channel.dispose();
    await first.close();
    await replacement.close();
    debugDefaultTargetPlatformOverride = null;
  });

  Future<bool> connect({
    String host = 'example.invalid',
    int sshPort = 22,
    String username = 'tester',
    int agentPort = 8642,
  }) => controller.connectSsh(
    SshConnectionRequest(
      host: host,
      sshPort: sshPort,
      username: username,
      agentPort: agentPort,
      password: 'synthetic-password',
      agentBearerToken: LocalServeReadFixture.token,
    ),
    serveReads: true,
    verifyHostKey: (_, _) async => true,
  );

  Future<void> selectOwner() async {
    expect(await connect(), isTrue);
    await channel.selectProfile('demo');
    await channel.selectSession('demo-session');
    expect(channel.state.activeSessionId, 'demo-session');
  }

  for (final lost in [false, true]) {
    test(
      'explicit reconnect restores exact owner on a new port after loss=$lost without replay',
      () async {
        await selectOwner();
        if (lost) {
          forward.lost.complete();
          for (var i = 0; i < 1000 && forward.closes == 0; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 1));
          }
          expect(forward.closes, 1);
        }
        await controller.cancel();
        expect(replacement.requests, isEmpty);
        forward.origin = replacement.origin;
        expect(await connect(), isTrue);
        expect(channel.state.connectedBaseUrl, replacement.origin);
        expect(channel.state.selectedProfileId, 'demo');
        expect(channel.state.activeSessionId, 'demo-session');
        expect(channel.state.activeMessages.last.text, 'demo fixture answer');
        expect(channel.state.serveChat, isNull);
        expect(
          replacement.reads
              .where((u) => u.path == '/api/sessions')
              .single
              .queryParameters['profile'],
          'demo',
        );
        expect(replacement.requests, [
          'GET /api/profiles',
          'GET /api/sessions',
          'GET /api/sessions/demo-session/messages',
        ]);
      },
    );
  }

  for (final changed in ['host', 'port', 'username', 'agentPort']) {
    test('changed $changed cannot inherit another SSH owner', () async {
      await selectOwner();
      await controller.cancel();
      forward.origin = replacement.origin;
      expect(
        await connect(
          host: changed == 'host' ? 'other.invalid' : 'example.invalid',
          sshPort: changed == 'port' ? 2222 : 22,
          username: changed == 'username' ? 'other' : 'tester',
          agentPort: changed == 'agentPort' ? 8643 : 8642,
        ),
        isTrue,
      );
      expect(channel.state.selectedProfileId, 'default');
      expect(channel.state.activeSessionId, 'default-recent');
    });
  }

  test(
    'missing exact session fails closed and explicit retry retains its owner',
    () async {
      await selectOwner();
      await controller.cancel();
      forward.origin = replacement.origin;
      replacement.denyHistory = true;
      expect(await connect(), isFalse);
      expect(channel.state.isConnected, isFalse);
      expect(
        replacement.requests.last,
        'GET /api/sessions/demo-session/messages',
      );
      replacement.denyHistory = false;
      expect(await connect(), isTrue);
      expect(channel.state.selectedProfileId, 'demo');
      expect(channel.state.activeSessionId, 'demo-session');
    },
  );

  test('missing exact profile cannot silently select default', () async {
    await selectOwner();
    await controller.cancel();
    forward.origin = replacement.origin;
    replacement.profiles.remove('demo');
    expect(await connect(), isFalse);
    expect(channel.state.isConnected, isFalse);
    expect(replacement.requests, ['GET /api/profiles']);
    replacement.profiles.add('demo');
    expect(await connect(), isTrue);
    expect(channel.state.selectedProfileId, 'demo');
    expect(channel.state.activeSessionId, 'demo-session');
  });

  test(
    'pending profile switch does not pair new profile with old session',
    () async {
      await selectOwner();
      first.holdProfiles = Completer<void>();
      first.profilesRequested = Completer<void>();
      final switching = channel.selectProfile('default');
      await first.profilesRequested!.future;
      await controller.cancel();
      first.holdProfiles!.complete();
      await switching;
      forward.origin = replacement.origin;
      expect(await connect(), isTrue);
      expect(channel.state.selectedProfileId, 'demo');
      expect(channel.state.activeSessionId, 'demo-session');
    },
  );

  test(
    'cancelled held recovery cannot adopt or erase a replacement owner',
    () async {
      await selectOwner();
      await controller.cancel();
      forward.origin = replacement.origin;
      replacement.holdHistory = Completer<void>();
      replacement.historyRequested = Completer<void>();
      final pending = connect();
      await replacement.historyRequested!.future;
      await controller.cancel();
      await channel.connectLocalServeReads(
        baseUrl: first.origin,
        credential: LocalServeReadFixture.token,
      );
      replacement.holdHistory!.complete();
      expect(await pending, isFalse);
      expect(channel.state.connectedBaseUrl, first.origin);
      expect(channel.state.selectedProfileId, 'default');
      expect(channel.state.activeSessionId, 'default-recent');
    },
  );
}
