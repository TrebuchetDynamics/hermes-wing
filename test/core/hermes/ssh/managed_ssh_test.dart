import 'dart:async';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/ssh/managed_ssh.dart';
import 'package:wing/core/hermes/ssh/ssh_forward_unsupported.dart' as browser;

void main() {
  test('browser explicitly rejects managed raw TCP forwarding', () async {
    final service = browser.ManagedSshForward();
    await expectLater(
      service.connect(
        configuration: ManagedSshConfig(
          host: 'example.invalid',
          username: 'test',
          agentPort: 8080,
        ),
        authentication: const ManagedSshCredentials(),
      ),
      throwsA(
        isA<ManagedSshException>().having(
          (e) => e.failure,
          'failure',
          ManagedSshFailure.unsupportedPlatform,
        ),
      ),
    );
    expect(service.activeTunnel, isNull);
    await service.disconnect();
    await service.dispose();
  });
  test(
    'cancel fences and destroys a late dial result without authentication',
    () async {
      final dial = Completer<SSHSocket>();
      final service = ManagedSshForward(dial: (_, _, {timeout}) => dial.future);
      final pending = service.connect(
        configuration: ManagedSshConfig(
          host: 'example.invalid',
          username: 'test',
          agentPort: 8080,
        ),
        authentication: const ManagedSshCredentials(),
      );
      final expectation = expectLater(
        pending,
        throwsA(
          isA<ManagedSshException>().having(
            (e) => e.failure,
            'failure',
            ManagedSshFailure.cancelled,
          ),
        ),
      );
      await service.disconnect();
      await expectation;
      final late = FakeSocket();
      dial.complete(late);
      await Future<void>.delayed(Duration.zero);
      expect(late.destroyed, isTrue);
      expect(service.activeTunnel, isNull);
      await service.dispose();
    },
  );
  test(
    'timeout fences late dial and allows retry without leaking raw errors',
    () async {
      final dial = Completer<SSHSocket>();
      var calls = 0;
      final service = ManagedSshForward(
        dial: (_, _, {timeout}) {
          calls++;
          return calls == 1
              ? dial.future
              : Future.error(StateError('private endpoint and credential'));
        },
      );
      final config = ManagedSshConfig(
        host: 'example.invalid',
        username: 'test',
        agentPort: 8080,
      );
      await expectLater(
        service.connect(
          configuration: config,
          authentication: const ManagedSshCredentials(),
          timeout: const Duration(milliseconds: 10),
        ),
        throwsA(
          isA<ManagedSshException>().having(
            (e) => e.failure,
            'failure',
            ManagedSshFailure.timeout,
          ),
        ),
      );
      final late = FakeSocket();
      dial.complete(late);
      await Future<void>.delayed(Duration.zero);
      expect(late.destroyed, isTrue);
      await expectLater(
        service.connect(
          configuration: config,
          authentication: const ManagedSshCredentials(),
        ),
        throwsA(
          isA<ManagedSshException>().having(
            (e) => e.toString(),
            'redaction',
            'Managed SSH: connection',
          ),
        ),
      );
      await service.dispose();
    },
  );
  test(
    'concurrent connect is rejected and disposed service cannot reopen',
    () async {
      final dial = Completer<SSHSocket>();
      final service = ManagedSshForward(dial: (_, _, {timeout}) => dial.future);
      final config = ManagedSshConfig(
        host: 'example.invalid',
        username: 'test',
        agentPort: 8080,
      );
      final pending = service.connect(
        configuration: config,
        authentication: const ManagedSshCredentials(),
      );
      final cancelled = expectLater(
        pending,
        throwsA(isA<ManagedSshException>()),
      );
      await expectLater(
        service.connect(
          configuration: config,
          authentication: const ManagedSshCredentials(),
        ),
        throwsA(
          isA<ManagedSshException>().having(
            (e) => e.failure,
            'failure',
            ManagedSshFailure.busy,
          ),
        ),
      );
      await service.dispose();
      await cancelled;
      await expectLater(
        service.connect(
          configuration: config,
          authentication: const ManagedSshCredentials(),
        ),
        throwsA(
          isA<ManagedSshException>().having(
            (e) => e.failure,
            'failure',
            ManagedSshFailure.disposed,
          ),
        ),
      );
      final late = FakeSocket();
      dial.complete(late);
      await Future<void>.delayed(Duration.zero);
      expect(late.destroyed, isTrue);
    },
  );
  test(
    'configuration rejects URL hosts, control characters and invalid ports',
    () {
      for (final host in ['', 'https://example.invalid', 'host\n', 'a' * 254]) {
        expect(
          () => ManagedSshConfig(host: host, username: 'test', agentPort: 8080),
          throwsA(isA<ManagedSshException>()),
        );
      }
      for (final port in [0, -1, 65536]) {
        expect(
          () => ManagedSshConfig(
            host: 'example.invalid',
            username: 'test',
            agentPort: port,
          ),
          throwsA(isA<ManagedSshException>()),
        );
      }
      final config = ManagedSshConfig(
        host: 'example.invalid',
        username: 'test',
        agentPort: 8080,
      );
      expect(config.sshPort, 22);
      expect(config.toString(), isNot(contains('example.invalid')));
    },
  );
}

class FakeSocket implements SSHSocket {
  bool destroyed = false;
  @override
  void destroy() {
    destroyed = true;
  }

  @override
  Future<void> close() async {
    destroy();
  }

  @override
  Future<void> get done => Future.value();
  @override
  Future<void> flush() async {}
  @override
  StreamSink<List<int>> get sink => throw UnimplementedError();
  @override
  Stream<Uint8List> get stream => throw UnimplementedError();
}
