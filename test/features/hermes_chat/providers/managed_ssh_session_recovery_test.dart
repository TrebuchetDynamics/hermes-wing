import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:wing/core/hermes/setup/secure_managed_ssh_recovery_store.dart';
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
  int connects = 0;

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
    connects++;
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
  TestWidgetsFlutterBinding.ensureInitialized();
  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  const slot = SecureManagedSshRecoveryStore.key;
  final store = SecureManagedSshRecoveryStore();
  final savedTarget = ManagedSshConfig(
    host: 'example.invalid',
    username: 'tester',
    agentPort: 8642,
  );
  final values = <String, String>{};
  Completer<void>? holdStorage;
  Completer<void>? storageRequested;
  var failStorage = false;
  late _Fixture first, replacement;
  late HermesApiChannel channel;
  late _Forward forward;
  late ManagedSshConnectionController controller;

  setUp(() async {
    // These are isolated loopback HTTP fixtures, not widget-test HTTP mocks.
    HttpOverrides.global = null;
    values.clear();
    holdStorage = null;
    storageRequested = null;
    failStorage = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async {
          final key = call.arguments['key'] as String;
          if (key != slot) return null;
          if (!(storageRequested?.isCompleted ?? true)) {
            storageRequested!.complete();
          }
          await holdStorage?.future;
          if (failStorage) {
            throw PlatformException(code: 'synthetic-storage-failure');
          }
          if (call.method == 'write') {
            values[key] = call.arguments['value'] as String;
          }
          return call.method == 'read' ? values[key] : null;
        });
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
    if (!(holdStorage?.isCompleted ?? true)) {
      holdStorage!.complete();
    }
    if (!(replacement.holdHistory?.isCompleted ?? true)) {
      replacement.holdHistory!.complete();
    }
    await controller.cancel();
    controller.dispose();
    channel.dispose();
    await first.close();
    await replacement.close();
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
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
      transport: SshAgentTransport.serve,
    ),
    verifyHostKey: (_, _) async => true,
  );

  Future<void> selectOwner() async {
    expect(await connect(), isTrue);
    await channel.selectProfile('demo');
    await channel.selectSession('demo-session');
    expect(channel.state.activeSessionId, 'demo-session');
  }

  Future<void> enablePersistence() async {
    controller.dispose();
    controller = ManagedSshConnectionController(
      forward,
      channel,
      recoveryStore: store,
    );
  }

  Future<void> awaitSavedOwner() async {
    for (var i = 0; i < 1000; i++) {
      final saved = await store.load(savedTarget, SshAgentTransport.serve);
      if (saved?.session == 'demo-session') return;
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    fail('settled owner was not saved');
  }

  Future<void> recreate() async {
    await controller.cancel();
    controller.dispose();
    channel.dispose();
    channel = HermesApiChannel();
    forward = _Forward(replacement.origin);
    controller = ManagedSshConnectionController(
      forward,
      channel,
      recoveryStore: store,
    );
  }

  test(
    'recreated controller restores secure exact owner after a new authenticated lease',
    () async {
      await enablePersistence();
      await selectOwner();
      await awaitSavedOwner();
      expect(values[slot], isNot(contains(first.origin)));
      expect(values[slot], isNot(contains(LocalServeReadFixture.token)));
      await recreate();
      expect(replacement.requests, isEmpty);
      expect(await connect(), isTrue);
      expect(channel.state.selectedProfileId, 'demo');
      expect(channel.state.activeSessionId, 'demo-session');
      expect(channel.state.activeMessages.last.text, 'demo fixture answer');
      expect(channel.state.serveChat, isNull);
      expect(forward.connects, 1);
      expect(replacement.requests, [
        'GET /api/profiles',
        'GET /api/sessions',
        'GET /api/sessions/demo-session/messages',
      ]);
    },
  );

  for (final changed in ['host', 'port', 'username', 'agentPort']) {
    test(
      'recreated controller cannot import saved owner after $changed changes',
      () async {
        await enablePersistence();
        await selectOwner();
        await awaitSavedOwner();
        await recreate();
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
        await Future<void>.delayed(const Duration(milliseconds: 10));
        // Each exact target keeps its own pointer; the original is untouched.
        final saved = await store.load(savedTarget, SshAgentTransport.serve);
        expect(saved?.profile, 'demo');
        expect(saved?.session, 'demo-session');
      },
    );
  }

  test(
    'cancel during secure recovery cannot dial or replace a newer owner',
    () async {
      await enablePersistence();
      holdStorage = Completer<void>();
      storageRequested = Completer<void>();
      final pending = connect();
      await storageRequested!.future;
      await controller.cancel();
      await channel.connectLocalServeReads(
        baseUrl: replacement.origin,
        credential: LocalServeReadFixture.token,
      );
      holdStorage!.complete();
      expect(await pending, isFalse);
      expect(forward.connects, 0);
      expect(channel.state.connectedBaseUrl, replacement.origin);
    },
  );

  for (final missing in ['profile', 'session']) {
    test(
      'recreated controller preserves missing exact $missing for explicit retry',
      () async {
        await enablePersistence();
        await selectOwner();
        await awaitSavedOwner();
        final raw = values[slot];
        await recreate();
        if (missing == 'profile') {
          replacement.profiles.remove('demo');
        }
        replacement.denyHistory = missing == 'session';
        await expectLater(connect(), throwsA(isA<ManagedSshAgentException>()));
        expect(values[slot], raw);
        expect(channel.state.isConnected, isFalse);
        if (missing == 'profile') {
          replacement.profiles.add('demo');
        }
        replacement.denyHistory = false;
        expect(await connect(), isTrue);
        expect(channel.state.selectedProfileId, 'demo');
        expect(channel.state.activeSessionId, 'demo-session');
      },
    );
  }

  test(
    'unavailable secure owner refuses before forwarding and preserves saved bytes',
    () async {
      await enablePersistence();
      final raw = values[slot];
      failStorage = true;
      await expectLater(connect(), throwsA(isA<ManagedSshException>()));
      expect(forward.connects, 0);
      expect(first.requests, isEmpty);
      expect(values[slot], raw);
      failStorage = false;
      expect(await connect(), isTrue);
    },
  );

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
      await expectLater(connect(), throwsA(isA<ManagedSshAgentException>()));
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
    await expectLater(connect(), throwsA(isA<ManagedSshAgentException>()));
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
