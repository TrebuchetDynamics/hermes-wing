import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/hermes/channel/hermes_api_channel.dart';
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
  bool _serveAdoption = false;
  bool Function()? _ownsConnection;
  int _generation = 0;
  int get attemptId => _generation;

  Future<bool> connectSsh(
    SshConnectionRequest input, {
    required ManagedSshHostKeyVerifier verifyHostKey,
  }) async {
    if (_pending || _tunnel != null) return false;
    if (input.transport == SshAgentTransport.serve &&
        (kIsWeb ||
            defaultTargetPlatform != TargetPlatform.android ||
            channel is! HermesApiChannel ||
            input.agentBearerToken == null ||
            input.agentBearerToken!.isEmpty)) {
      throw const ManagedSshException(ManagedSshFailure.invalidConfiguration);
    }
    _serveAdoption = input.transport == SshAgentTransport.serve;
    final generation = ++_generation;
    _pending = true;
    _replacement = false;
    _sawConnecting = false;
    _ownsConnection = null;
    void acquired(bool Function() isCurrent) {
      if (generation == _generation) _ownsConnection = isCurrent;
    }

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
      // Subscribe before Agent acquisition: SSH loss must fence held bootstrap
      // reads too, not only a connection already displayed as connected.
      unawaited(
        tunnel.done.then((_) {
          if (generation != _generation || !identical(_tunnel, tunnel)) return;
          if (_pending) {
            unawaited(cancel());
          } else {
            _tunnel = null;
            _adopted = false;
            ++_generation;
            if ((channel is! HermesApiChannel ||
                    (_ownsConnection?.call() ?? false)) &&
                channel.state.connectedBaseUrl == tunnel.agentUri.toString()) {
              unawaited(channel.disconnect());
            }
          }
        }),
      );
      _adopting = true;
      if (_serveAdoption) {
        await (channel as HermesApiChannel).connectForwardedServeReads(
          baseUrl: tunnel.agentUri.toString(),
          credential: token!,
          canAccept: () =>
              generation == _generation &&
              identical(_tunnel, tunnel) &&
              (_ownsConnection?.call() ?? true),
          onAcquire: acquired,
        );
      } else if (channel is HermesApiChannel) {
        await (channel as HermesApiChannel).connect(
          baseUrl: tunnel.agentUri.toString(),
          apiKey: token,
          onAcquire: acquired,
        );
      } else {
        await channel.connect(
          baseUrl: tunnel.agentUri.toString(),
          apiKey: token,
        );
      }
      if (generation != _generation) {
        await tunnel.dispose();
        return false;
      }
      if ((channel is HermesApiChannel &&
              !(_ownsConnection?.call() ?? false)) ||
          !channel.state.isConnected ||
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
      if (channel is HermesApiChannel && !(_ownsConnection?.call() ?? false)) {
        _replacement = true;
        unawaited(cancel());
        return;
      }
      final state = channel.state;
      if (state.status == HermesConnectionStatus.connecting &&
          !_sawConnecting) {
        _sawConnecting = true;
      } else if (state.status == HermesConnectionStatus.connecting ||
          (state.isConnected &&
              state.connectedBaseUrl != tunnel.agentUri.toString()) ||
          (state.status == HermesConnectionStatus.disconnected &&
              (!_serveAdoption || _sawConnecting))) {
        _replacement = true;
        unawaited(cancel());
      }
    }
    if (_adopted &&
        tunnel != null &&
        ((channel is HermesApiChannel && !(_ownsConnection?.call() ?? false)) ||
            !channel.state.isConnected ||
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
    final ownsConnection = _ownsConnection;
    _ownsConnection = null;
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
        (channel is! HermesApiChannel || (ownsConnection?.call() ?? false)) &&
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
