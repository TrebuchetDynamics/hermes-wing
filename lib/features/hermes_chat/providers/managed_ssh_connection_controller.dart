import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/channel/hermes_api_channel.dart';
import '../../../core/hermes/ssh/managed_ssh.dart';
import '../../../core/hermes/ssh/ssh_connection_request.dart';
import 'hermes_channel_provider.dart';
import 'managed_ssh_provider.dart';

final managedSshConnectionControllerProvider = Provider((ref) {
  final controller = ManagedSshConnectionController(
    ref.watch(managedSshForwardProvider),
    ref.watch(hermesChannelProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

/// Owns only an ephemeral forwarding lease, never a saved Agent endpoint.
class ManagedSshConnectionController {
  ManagedSshConnectionController(this.forward, this.channel) {
    channel.addListener(_changed);
  }
  final ManagedSshForward forward;
  final HermesChannel channel;
  ManagedSshTunnel? _tunnel;
  bool _pending = false;
  bool _cancelling = false;
  Future<void>? _cancellation;
  bool _disposed = false;
  void Function()? _clearAuthentication;
  bool _adopting = false;
  bool _adopted = false;
  bool _sawConnecting = false;
  bool _tunnelLost = false;
  bool _replacement = false;
  int _generation = 0;
  int get attemptId => _generation;

  Future<bool> connectSsh(
    SshConnectionRequest input, {
    required ManagedSshHostKeyVerifier verifyHostKey,
    bool serveReads = false,
  }) async {
    if (_disposed || _cancelling || _pending || _tunnel != null) return false;
    final generation = ++_generation;
    _pending = true;
    _replacement = false;
    _sawConnecting = false;
    _tunnelLost = false;
    String? password = input.password;
    String? privateKey = input.privateKey;
    String? passphrase = input.passphrase;
    String? token = input.agentBearerToken;
    void clearAuthentication() {
      password = null;
      privateKey = null;
      passphrase = null;
      token = null;
    }

    _clearAuthentication = clearAuthentication;
    try {
      final tunnel = await forward.connect(
        configuration: ManagedSshConfig(
          host: input.host,
          username: input.username,
          sshPort: input.sshPort,
          agentPort: input.agentPort,
        ),
        authentication: input.privateKey == null
            ? ManagedSshCredentials(password: () => password)
            : ManagedSshCredentials(
                privateKey: () => privateKey,
                passphrase: () => passphrase,
              ),
        verifyHostKey: (config, key) async {
          if (generation != _generation) return false;
          final accepted = await verifyHostKey(config, key);
          return generation == _generation && accepted;
        },
      );
      if (generation != _generation) {
        await tunnel.dispose();
        return false;
      }
      _tunnel = tunnel;
      _adopting = true;
      // Loss must revoke pending Agent adoption, not only an already-connected lease.
      unawaited(
        tunnel.done.then((_) {
          if (!identical(_tunnel, tunnel)) return;
          if (_adopting) {
            _tunnelLost = true;
            clearAuthentication();
            // connect may still be awaiting preflight; revoke its first connecting state.
            if (_sawConnecting) unawaited(cancel(attemptId: generation));
            return;
          }
          unawaited(cancel(attemptId: generation));
        }),
      );
      if (serveReads) {
        final target = channel;
        if (target is! HermesApiChannel || token == null) {
          throw const ManagedSshException(ManagedSshFailure.connection);
        }
        await target.connectForwardedServeReads(
          baseUrl: tunnel.agentUri.toString(),
          credential: token!,
          canAccept: () =>
              generation == _generation &&
              identical(_tunnel, tunnel) &&
              !_tunnelLost &&
              !_replacement,
        );
      } else {
        await channel.connect(
          baseUrl: tunnel.agentUri.toString(),
          apiKey: token,
        );
      }
      if (generation != _generation) return false;
      if (!channel.state.isConnected ||
          channel.state.connectedBaseUrl != tunnel.agentUri.toString()) {
        await cancel();
        return false;
      }
      _adopting = false;
      _adopted = true;
      return true;
    } catch (error) {
      if (generation == _generation) await cancel();
      if (error is ManagedSshException) rethrow;
      throw const ManagedSshException(ManagedSshFailure.connection);
    } finally {
      clearAuthentication();
      if (identical(_clearAuthentication, clearAuthentication)) {
        _clearAuthentication = null;
      }
      if (generation == _generation) _pending = false;
    }
  }

  void _changed() {
    final tunnel = _tunnel;
    if (_pending && !_adopting && !_adopted) {
      _replacement = true;
      unawaited(cancel());
      return;
    }
    if (_adopting && tunnel != null) {
      final state = channel.state;
      if (state.status == HermesConnectionStatus.connecting &&
          !_sawConnecting) {
        _sawConnecting = true;
        if (_tunnelLost) unawaited(cancel());
      } else if (state.status == HermesConnectionStatus.connecting ||
          (state.isConnected &&
              state.connectedBaseUrl != tunnel.agentUri.toString()) ||
          state.status == HermesConnectionStatus.disconnected) {
        _replacement = true;
        unawaited(cancel());
      }
    }
    if (_adopted &&
        tunnel != null &&
        (!channel.state.isConnected ||
            channel.state.connectedBaseUrl != tunnel.agentUri.toString())) {
      // The channel has moved on; retire only our lease before admitting retry.
      _replacement = true;
      unawaited(cancel());
    }
  }

  Future<void> cancel({int? attemptId}) {
    if (attemptId != null && attemptId != _generation) {
      return Future<void>.value();
    }
    final cancellation = _cancellation;
    if (cancellation != null) return cancellation;
    if (!_pending && _tunnel == null) return Future<void>.value();
    _cancelling = true;
    // Publish before disconnect synchronously notifies reentrant callers.
    final completion = Completer<void>();
    _cancellation = completion.future;
    completion.complete(
      _cancel().whenComplete(() {
        _cancellation = null;
        _cancelling = false;
      }),
    );
    return completion.future;
  }

  Future<void> _cancel() async {
    ++_generation;
    _clearAuthentication?.call();
    _clearAuthentication = null;
    final state = channel.state;
    final tunnel = _tunnel;
    _tunnel = null;
    final adopting = _adopting;
    final adopted = _adopted;
    _adopting = false;
    _adopted = false;
    _pending = false;
    // Retire Agent authentication before releasing a reusable local port.
    try {
      if ((adopting || adopted) &&
          !_replacement &&
          identical(state, channel.state) &&
          (state.status == HermesConnectionStatus.connecting ||
              state.status == HermesConnectionStatus.error ||
              state.connectedBaseUrl == tunnel?.agentUri.toString())) {
        await channel.disconnect();
      }
    } finally {
      if (tunnel != null) {
        await tunnel.dispose();
      } else {
        await forward.disconnect();
      }
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    channel.removeListener(_changed);
    unawaited(cancel());
  }
}
