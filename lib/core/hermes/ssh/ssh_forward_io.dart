import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import 'ssh_types.dart';

/// App-scoped owner of one ephemeral SSH lease. Native TCP only: no subprocess,
/// shell, bootstrap, credential discovery, Wing Link or Agent state mutation.
/// Disconnect cancels the pending attempt; dispose permanently closes the owner.
class ManagedSshForward {
  ManagedSshForward({ManagedSshDial? dial}) : _dial = dial ?? SSHSocket.connect;
  final ManagedSshDial _dial;
  _Attempt? _attempt;
  bool _disposed = false;
  ManagedSshTunnel? get activeTunnel => _attempt?.tunnel;

  /// Returns an authenticated SSH listener, not Agent health/API readiness.
  /// The caller still authenticates to Agent and checks its advertised API.
  /// Persist a separately reviewed SSH target/trust record, never agentUri.
  /// A missing verifier rejects every presented key; no TOFU or retry is implicit.
  Future<ManagedSshTunnel> connect({
    required ManagedSshConfig configuration,
    required ManagedSshCredentials authentication,
    ManagedSshHostKeyVerifier? verifyHostKey,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (_disposed) throw const ManagedSshException(ManagedSshFailure.disposed);
    if (_attempt != null) {
      throw const ManagedSshException(ManagedSshFailure.busy);
    }
    if (timeout <= Duration.zero || timeout > const Duration(seconds: 60)) {
      throw const ManagedSshException(ManagedSshFailure.invalidConfiguration);
    }
    final attempt = _Attempt();
    _attempt = attempt;
    final timer = Timer(timeout, () {
      _stop(attempt, ManagedSshFailure.timeout);
    });
    try {
      final dialing = _dial(
        configuration.host,
        configuration.sshPort,
        timeout: timeout,
      );
      unawaited(
        dialing.then((socket) {
          if (attempt.stopped) socket.destroy();
        }, onError: (Object _) {}),
      );
      attempt.socket = await attempt.wait(dialing);
      var credentials = authentication;
      final identities = <SSHKeyPair>[];
      var verified = false;
      var hostKeyRejected = false;
      attempt.clearSecrets = () {
        credentials = const ManagedSshCredentials();
        identities.clear();
      };
      final key = await attempt.wait(
        Future<String?>.sync(() => credentials.privateKey?.call()),
      );
      if (key != null) {
        final passphrase = await attempt.wait(
          Future<String?>.sync(() => credentials.passphrase?.call()),
        );
        try {
          identities.addAll(SSHKeyPair.fromPem(key, passphrase));
        } catch (_) {
          throw const ManagedSshException(ManagedSshFailure.authentication);
        }
      }
      if (attempt.stopped) throw ManagedSshException(attempt.failure);
      final client = SSHClient(
        attempt.socket!,
        username: configuration.username,
        identities: identities,
        handshakeTimeout: timeout,
        authTimeout: timeout,
        keepAliveInterval: const Duration(seconds: 20),
        onVerifyHostKey: (algorithm, fingerprint) async {
          hostKeyRejected = true;
          // dartssh2 4.x supplies UTF-8 OpenSSH SHA256:<base64>, not digest bytes.
          try {
            final encoded = utf8.decode(fingerprint);
            if (!encoded.startsWith('SHA256:') || verifyHostKey == null) {
              return false;
            }
            final digest = base64.decode(
              base64.normalize(encoded.substring(7)),
            );
            if (digest.length != 32) return false;
            verified = await attempt.wait(
              Future.sync(
                () => verifyHostKey(
                  configuration,
                  ManagedSshHostKey(algorithm, digest),
                ),
              ),
            );
            hostKeyRejected = !verified;
            return verified && !attempt.stopped;
          } catch (_) {
            return false;
          }
        },
        onPasswordRequest: () async {
          if (!verified || attempt.stopped) return null;
          final value = await attempt.wait(
            Future<String?>.sync(() => credentials.password?.call()),
          );
          return attempt.stopped ? null : value;
        },
      );
      attempt.client = client;
      // Loss of the SSH transport revokes the loopback lease immediately.
      unawaited(
        client.done.then(
          (_) => _stop(attempt),
          onError: (Object _) => _stop(attempt),
        ),
      );
      try {
        await attempt.wait(client.authenticated);
      } on SSHHostkeyError {
        throw const ManagedSshException(ManagedSshFailure.hostKeyRejected);
      } on SSHAuthError {
        throw ManagedSshException(
          hostKeyRejected
              ? ManagedSshFailure.hostKeyRejected
              : ManagedSshFailure.authentication,
        );
      }
      attempt.clearSecrets!();
      final binding = ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      unawaited(
        binding.then((server) {
          if (attempt.stopped) unawaited(server.close());
        }, onError: (Object _) {}),
      );
      final server = await attempt.wait(binding);
      attempt.server = server;
      final tunnel = ManagedSshTunnel(
        agentUri: Uri(scheme: 'http', host: '127.0.0.1', port: server.port),
        done: attempt.closed.future,
        close: () => _stop(attempt),
      );
      attempt.tunnel = tunnel;
      attempt.listener = server.listen(
        (socket) {
          if (attempt.stopped || attempt.sockets.length >= 16) {
            socket.destroy();
            return;
          }
          attempt.sockets.add(socket);
          unawaited(_forward(attempt, socket, configuration.agentPort));
        },
        onError: (Object _) {
          unawaited(_stop(attempt));
        },
        onDone: () {
          unawaited(_stop(attempt));
        },
      );
      return tunnel;
    } catch (error) {
      await _stop(attempt);
      if (error is ManagedSshException) rethrow;
      throw const ManagedSshException(ManagedSshFailure.connection);
    } finally {
      timer.cancel();
    }
  }

  Future<void> _forward(_Attempt attempt, Socket socket, int port) async {
    SSHForwardChannel? channel;
    try {
      final opening = attempt.client!.forwardLocal('127.0.0.1', port);
      var expired = false;
      unawaited(
        opening.then((result) {
          if (attempt.stopped || expired) result.destroy();
        }, onError: (Object _) {}),
      );
      late final SSHForwardChannel forward;
      try {
        forward = await attempt.wait<SSHForwardChannel>(
          opening.timeout(const Duration(seconds: 10)),
        );
      } on TimeoutException {
        expired = true;
        rethrow;
      }
      channel = forward;
      if (attempt.stopped) {
        forward.destroy();
        return;
      }
      attempt.channels.add(forward);
      unawaited(forward.done.then((_) {}, onError: (Object _) {}));
      final upload = () async {
        await forward.sink.addStream(socket);
        await forward.sink.close();
      }();
      final download = () async {
        await socket.addStream(forward.stream);
        await socket.flush();
        await socket.close();
        socket.destroy();
      }();
      await Future.wait([upload, download], eagerError: true);
    } catch (_) {
      // Per-channel refusal/IO failure closes only that stream, never logs bytes.
    } finally {
      socket.destroy();
      channel?.destroy();
      attempt.sockets.remove(socket);
      attempt.channels.remove(channel);
    }
  }

  Future<void> _stop(
    _Attempt attempt, [
    ManagedSshFailure failure = ManagedSshFailure.cancelled,
  ]) async {
    if (identical(_attempt, attempt)) _attempt = null;
    if (attempt.stopped) return attempt.closed.future;
    attempt.stopped = true;
    attempt.failure = failure;
    attempt.cancel.complete();
    attempt.clearSecrets?.call();
    for (final socket in attempt.sockets) {
      socket.destroy();
    }
    for (final channel in attempt.channels) {
      channel.destroy();
    }
    final client = attempt.client;
    if (client != null) unawaited(client.close());
    attempt.socket?.destroy();
    await attempt.listener?.cancel();
    await attempt.server?.close();
    attempt.closed.complete();
  }

  Future<void> disconnect() async {
    final attempt = _attempt;
    if (attempt != null) await _stop(attempt);
  }

  Future<void> dispose() async {
    _disposed = true;
    await disconnect();
  }
}

class _Attempt {
  bool stopped = false;
  ManagedSshFailure failure = ManagedSshFailure.cancelled;
  final cancel = Completer<void>();
  final closed = Completer<void>();
  SSHSocket? socket;
  SSHClient? client;
  ServerSocket? server;
  StreamSubscription<Socket>? listener;
  void Function()? clearSecrets;
  final sockets = <Socket>{};
  final channels = <SSHForwardChannel>{};
  ManagedSshTunnel? tunnel;
  Future<T> wait<T>(Future<T> future) => Future.any([
    future,
    cancel.future.then<T>((_) => throw ManagedSshException(failure)),
  ]);
}
