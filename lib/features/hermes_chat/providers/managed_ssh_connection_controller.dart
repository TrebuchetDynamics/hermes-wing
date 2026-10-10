import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/hermes/channel/hermes_channel.dart';
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
  void Function()? _clearAuthentication;
  bool _adopting = false;
  bool _adopted = false;
  bool _sawConnecting = false;
  bool _replacement = false;
  int _generation = 0;
  int get attemptId => _generation;

  Future<bool> connectSsh(
    SshConnectionRequest input, {
    required ManagedSshHostKeyVerifier verifyHostKey,
  }) async {
    if (_pending || _tunnel != null) return false;
    final generation = ++_generation;
    _pending = true;
    _replacement = false;
    _sawConnecting = false;
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
      await channel.connect(baseUrl: tunnel.agentUri.toString(), apiKey: token);
      if (generation != _generation) {
        await tunnel.dispose();
        return false;
      }
      if (!channel.state.isConnected ||
          channel.state.connectedBaseUrl != tunnel.agentUri.toString()) {
        await cancel();
        return false;
      }
      _adopting = false;
      _adopted = true;
      unawaited(
        tunnel.done.then((_) {
          if (identical(_tunnel, tunnel)) {
            _tunnel = null;
            _adopted = false;
            if (channel.state.connectedBaseUrl == tunnel.agentUri.toString()) {
              unawaited(channel.disconnect());
            }
          }
        }),
      );
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
      _adopted = false;
      _tunnel = null;
      unawaited(tunnel.dispose());
    }
  }

  Future<void> cancel({int? attemptId}) async {
    if (attemptId != null && attemptId != _generation) return;
    if (!_pending && _tunnel == null) return;
    final cancellation = ++_generation;
    _clearAuthentication?.call();
    _clearAuthentication = null;
    final state = channel.state;
    final tunnel = _tunnel;
    _tunnel = null;
    final adopting = _adopting;
    _adopting = false;
    _adopted = false;
    _pending = false;
    if (tunnel != null) {
      await tunnel.dispose();
    } else {
      await forward.disconnect();
    }
    if (cancellation == _generation &&
        adopting &&
        !_replacement &&
        identical(state, channel.state) &&
        (state.status == HermesConnectionStatus.connecting ||
            state.status == HermesConnectionStatus.error ||
            state.connectedBaseUrl == tunnel?.agentUri.toString())) {
      await channel.disconnect();
    }
  }

  void dispose() {
    channel.removeListener(_changed);
    unawaited(cancel());
  }
}
