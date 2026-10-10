import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/ssh/managed_ssh.dart';

// Opt-in real SSH, no personal runtime or SSH credentials. Start the owned
// Python fixture in support/ and pass MANAGED_SSH_FIXTURE=<ready.json>.
void main() {
  final path = Platform.environment['MANAGED_SSH_FIXTURE'];
  Map<String, dynamic> fixture = {};
  late ManagedSshConfig config;
  ManagedSshForward? service;
  setUp(() async {
    if (path == null) return;
    fixture =
        jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
    config = ManagedSshConfig(
      host: '127.0.0.1',
      username: fixture['username'] as String,
      sshPort: fixture['ssh_port'] as int,
      agentPort: fixture['http_port'] as int,
    );
    service = ManagedSshForward();
  });
  tearDown(() async {
    await service?.dispose();
  });
  bool trusted(ManagedSshConfig target, ManagedSshHostKey key) =>
      target == config &&
      key.algorithm == 'ssh-ed25519' &&
      const ListEquality().equals(
        key.sha256,
        (fixture['host_sha256_bytes'] as List).cast<int>(),
      );

  test('no verifier rejects host before password disclosure', () async {
    var requests = 0;
    await expectLater(
      service!.connect(
        configuration: config,
        authentication: ManagedSshCredentials(
          password: () {
            requests++;
            return null;
          },
        ),
      ),
      throwsA(
        isA<ManagedSshException>().having(
          (e) => e.failure,
          'failure',
          ManagedSshFailure.hostKeyRejected,
        ),
      ),
    );
    expect(requests, 0);
    expect(service!.activeTunnel, isNull);
  }, skip: path == null);
  test('mismatched reviewed key fails closed', () async {
    await expectLater(
      service!.connect(
        configuration: config,
        authentication: const ManagedSshCredentials(),
        verifyHostKey: (_, _) => false,
      ),
      throwsA(
        isA<ManagedSshException>().having(
          (e) => e.failure,
          'failure',
          ManagedSshFailure.hostKeyRejected,
        ),
      ),
    );
  }, skip: path == null);
  test('wrong password has typed secret-free authentication error', () async {
    await expectLater(
      service!.connect(
        configuration: config,
        authentication: ManagedSshCredentials(
          password: () => 'invalid-fixture-password',
        ),
        verifyHostKey: trusted,
      ),
      throwsA(
        isA<ManagedSshException>()
            .having(
              (e) => e.failure,
              'failure',
              ManagedSshFailure.authentication,
            )
            .having(
              (e) => e.toString(),
              'redaction',
              isNot(contains('invalid-fixture-password')),
            ),
      ),
    );
  }, skip: path == null);
  test('cancel while reviewing host fences delayed approval', () async {
    final review = Completer<bool>();
    final entered = Completer<void>();
    var requests = 0;
    final pending = service!.connect(
      configuration: config,
      authentication: ManagedSshCredentials(
        password: () {
          requests++;
          return null;
        },
      ),
      verifyHostKey: (_, _) {
        entered.complete();
        return review.future;
      },
    );
    final rejected = expectLater(
      pending,
      throwsA(
        isA<ManagedSshException>().having(
          (e) => e.failure,
          'failure',
          ManagedSshFailure.cancelled,
        ),
      ),
    );
    await entered.future;
    await service!.disconnect();
    await rejected;
    review.complete(true);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(requests, 0);
    expect(service!.activeTunnel, isNull);
  }, skip: path == null);
  test(
    'transport loss closes loopback listener and completes lease',
    () async {
      late SSHSocket transport;
      service = ManagedSshForward(
        dial: (host, port, {timeout}) async {
          transport = await SSHSocket.connect(host, port, timeout: timeout);
          return transport;
        },
      );
      final tunnel = await service!.connect(
        configuration: config,
        authentication: ManagedSshCredentials(
          password: () =>
              File(fixture['password_file'] as String).readAsString(),
        ),
        verifyHostKey: trusted,
      );
      transport.destroy();
      await tunnel.done.timeout(const Duration(seconds: 5));
      expect(service!.activeTunnel, isNull);
      await expectLater(
        Socket.connect('127.0.0.1', tunnel.agentUri.port),
        throwsA(isA<SocketException>()),
      );
    },
    skip: path == null,
  );
  test('old disposed lease cannot close a replacement connection', () async {
    final auth = ManagedSshCredentials(
      password: () => File(fixture['password_file'] as String).readAsString(),
    );
    final old = await service!.connect(
      configuration: config,
      authentication: auth,
      verifyHostKey: trusted,
    );
    await old.dispose();
    final replacement = await service!.connect(
      configuration: config,
      authentication: auth,
      verifyHostKey: trusted,
    );
    await old.dispose();
    expect(service!.activeTunnel, same(replacement));
    final client = HttpClient();
    try {
      final response = await (await client.getUrl(
        replacement.agentUri,
      )).close();
      expect(await utf8.decoder.bind(response).join(), 'owned-ssh-fixture\n');
    } finally {
      client.close(force: true);
    }
  }, skip: path == null);
  for (final mode in ['key', 'password']) {
    test(
      'real $mode SSH forwards owned HTTP and closes ephemeral lease',
      () async {
        final auth = mode == 'key'
            ? ManagedSshCredentials(
                privateKey: () =>
                    File(fixture['client_key_file'] as String).readAsString(),
              )
            : ManagedSshCredentials(
                password: () =>
                    File(fixture['password_file'] as String).readAsString(),
              );
        final tunnel = await service!.connect(
          configuration: config,
          authentication: auth,
          verifyHostKey: trusted,
        );
        expect(tunnel.agentUri.host, '127.0.0.1');
        expect(tunnel.agentUri.port, isNot(config.agentPort));
        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 5);
        try {
          final response = await (await client.getUrl(tunnel.agentUri)).close();
          expect(response.statusCode, 200);
          expect(
            await utf8.decoder.bind(response).join(),
            'owned-ssh-fixture\n',
          );
        } finally {
          client.close(force: true);
        }
        await tunnel.dispose();
        await tunnel.done;
        expect(service!.activeTunnel, isNull);
        await expectLater(
          Socket.connect('127.0.0.1', tunnel.agentUri.port),
          throwsA(isA<SocketException>()),
        );
      },
      skip: path == null,
    );
  }
}

class ListEquality {
  const ListEquality();
  bool equals(List<int> a, List<int> b) =>
      a.length == b.length &&
      Iterable<int>.generate(a.length).every((i) => a[i] == b[i]);
}
