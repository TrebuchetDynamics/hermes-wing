import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/hermes/channel/hermes_api_channel.dart';
import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/setup/secure_managed_ssh_recovery_store.dart';
import '../../../core/hermes/ssh/managed_ssh.dart';
import '../../../core/hermes/ssh/ssh_connection_request.dart';
import 'hermes_channel_provider.dart';
import 'managed_ssh_provider.dart';

final managedSshConnectionControllerProvider = Provider((ref) {
  final controller = ManagedSshConnectionController(
    ref.watch(managedSshForwardProvider),
    ref.watch(hermesChannelProvider),
    recoveryStore: ref.watch(managedSshRecoveryStoreProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

final managedSshRecoveryStoreProvider = Provider<ManagedSshRecoveryStore>(
  (ref) => SecureManagedSshRecoveryStore(),
);

/// A captured Agent-stage failure, independent of channel state after teardown.
class ManagedSshAgentException extends ManagedSshException {
  const ManagedSshAgentException(this.kind)
    : super(ManagedSshFailure.connection);
  final HermesConnectionFailureKind kind;
}

/// Owns a forwarding lease and a navigation pointer, never Agent domain state.
class ManagedSshConnectionController {
  ManagedSshConnectionController(
    this.forward,
    this.channel, {
    this.recoveryStore,
  }) {
    channel.addListener(_changed);
  }
  final ManagedSshForward forward;
  final HermesChannel channel;
  final ManagedSshRecoveryStore? recoveryStore;
  ManagedSshRecovery? _recovery;
  ManagedSshConfig? _configuration;
  SshAgentTransport? _transport;
  ManagedSshHostKey? _hostKey;
  HermesChannelState? _interruptedState;
  Future<void> _saveTail = Future.value();
  Future<void> _lastSave = Future.value();
  String? _lastSaved;
  bool _disposed = false;
  ManagedSshRecovery? get recoveryTarget => _recovery;
  bool get needsSshReconnect => identical(_interruptedState, channel.state);
  ManagedSshTunnel? _tunnel;
  bool _pending = false;
  bool _cancelling = false;
  Future<void>? _cancellation;
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
    if (_disposed || _cancelling || _pending || _tunnel != null) return false;
    if (input.transport == SshAgentTransport.serve &&
        (kIsWeb ||
            defaultTargetPlatform != TargetPlatform.android ||
            channel is! HermesApiChannel ||
            input.agentBearerToken == null ||
            input.agentBearerToken!.isEmpty)) {
      throw const ManagedSshException(ManagedSshFailure.invalidConfiguration);
    }
    // The /p/{profile} prefix belongs only to the advertised API multiplexer,
    // never to the separately authenticated native serve surface.
    if (input.transport == SshAgentTransport.serve &&
        input.agentProfile != null) {
      throw const ManagedSshException(ManagedSshFailure.invalidConfiguration);
    }
    final configuration = ManagedSshConfig(
      host: input.host,
      username: input.username,
      sshPort: input.sshPort,
      agentPort: input.agentPort,
      agentProfile: input.agentProfile,
    );
    _serveAdoption = input.transport == SshAgentTransport.serve;
    final generation = ++_generation;
    _pending = true;
    _replacement = false;
    _sawConnecting = false;
    _ownsConnection = null;
    _interruptedState = null;
    _configuration = configuration;
    _transport = input.transport;
    _hostKey = null;
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
    Future<void>? lostCleanup;
    int? lostRetirement;
    bool Function()? lostIntent;
    bool Function() captureRetirement() {
      if (channel is HermesApiChannel) {
        return (channel as HermesApiChannel).captureConnectionIntent();
      }
      final state = channel.state;
      return () => identical(state, channel.state);
    }

    try {
      if (recoveryStore != null) await _saveTail;
      final ManagedSshRecovery? saved;
      try {
        saved = recoveryStore != null
            ? await recoveryStore!.load(configuration, input.transport)
            : (_recovery?.matches(configuration, input.transport) == true
                  ? _recovery
                  : null);
      } catch (_) {
        throw const ManagedSshException(ManagedSshFailure.recoveryUnavailable);
      }
      if (generation != _generation) return false;
      _recovery = saved;
      final tunnel = await forward.connect(
        configuration: configuration,
        authentication: input.privateKey == null
            ? ManagedSshCredentials(password: () => password)
            : ManagedSshCredentials(
                privateKey: () => privateKey,
                passphrase: () => passphrase,
              ),
        verifyHostKey: (config, key) async {
          if (generation != _generation) return false;
          // A changed fingerprint cannot reuse a saved conversation pointer.
          if (saved != null &&
              (key.algorithm != saved.hostKey.algorithm ||
                  !listEquals(key.sha256, saved.hostKey.sha256))) {
            return false;
          }
          final accepted = await verifyHostKey(config, key);
          if (generation != _generation || !accepted) return false;
          _hostKey = key;
          return true;
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
            // This is a failed current attempt, not a user's cancellation.
            lostCleanup = cancel().catchError((Object _) {});
            lostRetirement = _generation;
            lostIntent = captureRetirement();
          } else {
            final owns = _ownsConnection;
            if (channel is HermesApiChannel && owns != null) {
              (channel as HermesApiChannel).interruptForwardedConnection(owns);
              _interruptedState = channel.state;
            } else if (channel.state.connectedBaseUrl ==
                tunnel.agentUri.toString()) {
              unawaited(channel.disconnect());
            }
            // Retire the lost lease through cancellation so Connect stays
            // closed until cleanup settles; the channel was handled above.
            _replacement = true;
            unawaited(cancel());
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
          profile: saved?.profile ?? 'default',
          storedSession: saved?.session,
          deferSessionSelection: saved != null && saved.session == null,
          uncertain: saved?.uncertain ?? false,
          persistRecovery: (checkpoint) => _remember(
            profile: checkpoint.profile,
            session: checkpoint.storedSessionId,
            uncertain: checkpoint.uncertain,
            canonical: true,
          ),
        );
      } else if (channel is HermesApiChannel) {
        await (channel as HermesApiChannel).connectForwardedApi(
          baseUrl: tunnel.agentUri.toString(),
          apiKey: token,
          onAcquire: acquired,
          canAccept: () =>
              generation == _generation && identical(_tunnel, tunnel),
          deferSessionSelection: saved != null,
          forwardedRunOwner: ManagedSshRecovery.runOwner(
            configuration,
            _hostKey!,
          ),
          uncertainSession: saved?.uncertain == true ? saved?.session : null,
          uncertainProfile: saved?.profile,
          uncertainSessions: saved?.unresolvedSessions ?? const {},
          persistForwardedRecovery: (profile, session, uncertain) => _remember(
            profile: profile ?? 'default',
            session: session,
            uncertain: uncertain,
            canonical: true,
          ),
        );
      } else {
        await channel.connect(
          baseUrl: tunnel.agentUri.toString(),
          apiKey: token,
        );
      }
      // Only cancellation advances the generation here, and it owns disposal.
      if (generation != _generation) return false;
      if ((channel is HermesApiChannel &&
              !(_ownsConnection?.call() ?? false)) ||
          !channel.state.isConnected ||
          channel.state.connectedBaseUrl != tunnel.agentUri.toString()) {
        if (channel is HermesApiChannel &&
            !(_ownsConnection?.call() ?? false)) {
          await cancel();
          return false;
        }
        throw ManagedSshAgentException(
          channel.state.connectionFailureKind ??
              HermesConnectionFailureKind.unknown,
        );
      }
      if (!_serveAdoption && saved != null) {
        if (saved.profile != (channel.state.selectedProfileId ?? 'default')) {
          await channel.selectProfile(
            saved.profile,
            deferSessionSelection: true,
          );
        }
        if (generation != _generation || !(_ownsConnection?.call() ?? true)) {
          return false;
        }
        if (saved.session != null &&
            !await channel.restoreSession(
              saved.session!,
              canAccept: () =>
                  generation == _generation &&
                  (_ownsConnection?.call() ?? true),
            )) {
          await cancel();
          return false;
        }
      }
      _adopting = false;
      _adopted = true;
      await _rememberCurrent();
      return generation == _generation;
    } catch (error) {
      if (generation != _generation) return false;
      final failure = error is ManagedSshException
          ? error
          : ManagedSshException(
              error is HermesRecoveryStorageException
                  ? ManagedSshFailure.recoveryUnavailable
                  : ManagedSshFailure.connection,
            );
      final cleanup = cancel();
      final retirement = _generation;
      final retirementIsCurrent = captureRetirement();
      try {
        await cleanup;
      } catch (_) {
        // Teardown failure must not replace the original allowlisted cause.
      }
      if (_disposed ||
          _replacement ||
          retirement != _generation ||
          !retirementIsCurrent()) {
        return false;
      }
      throw failure;
    } finally {
      clearAuthentication();
      if (identical(_clearAuthentication, clearAuthentication)) {
        _clearAuthentication = null;
      }
      if (generation == _generation) _pending = false;
      if (lostCleanup != null) {
        await lostCleanup;
        if (!_disposed &&
            !_replacement &&
            lostRetirement == _generation &&
            (lostIntent?.call() ?? false)) {
          throw const ManagedSshException(ManagedSshFailure.connection);
        }
      }
    }
  }

  Future<void> _rememberCurrent() => _remember(
    profile: channel.state.selectedProfileId ?? 'default',
    session: channel.state.activeSessionId,
    // API uncertainty changes only at its pre-send/authoritative callbacks,
    // never from an informational streaming or idle presentation update.
    uncertain:
        _serveAdoption &&
        (channel.state.hasUnreconciledRun ||
            channel.state.serveChat?.running == true ||
            (channel.state.activeSessionId != null &&
                channel.state.isSessionStreaming(
                  channel.state.activeSessionId!,
                ))),
  );

  Future<void> _remember({
    String? profile,
    String? session,
    required bool uncertain,
    bool canonical = false,
  }) async {
    final config = _configuration;
    final transport = _transport;
    final key = _hostKey;
    if (config == null ||
        transport == null ||
        key == null ||
        profile == null ||
        !(_ownsConnection?.call() ?? true)) {
      return;
    }
    final unresolved = {...?_recovery?.unresolvedSessions};
    if (session != null) {
      if (uncertain) {
        unresolved.add((profile, session));
      } else if (canonical) {
        unresolved.remove((profile, session));
      }
    }
    final selection = ManagedSshRecovery(
      configuration: config,
      transport: transport,
      hostKey: key,
      profile: profile,
      session: session,
      uncertain: session != null && unresolved.contains((profile, session)),
      uncertainSessions: unresolved,
    );
    _recovery = selection;
    final encoded = jsonEncode(selection.toJson());
    if (encoded == _lastSaved) {
      await _lastSave;
      return;
    }
    _lastSaved = encoded;
    // Captured old-owner pointers may finish saving, but never mutate a newer
    // channel. Serialization makes the newest same-host selection win on disk.
    final operation = _saveTail.then((_) => recoveryStore?.save(selection));
    _lastSave = operation;
    _saveTail = operation.catchError((Object _) {
      if (_lastSaved == encoded) _lastSaved = null;
    });
    try {
      await operation;
    } catch (_) {
      throw const ManagedSshException(ManagedSshFailure.recoveryUnavailable);
    }
  }

  void _changed() {
    final tunnel = _tunnel;
    if (_adopted &&
        channel.state.isConnected &&
        channel.state.connectedBaseUrl == tunnel?.agentUri.toString()) {
      // A later deliberate operation retries failed secure writes; no raw
      // storage exception or automatic Agent mutation escapes this listener.
      unawaited(_rememberCurrent().catchError((Object _) {}));
    }
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
      // The channel has moved on; retire only our lease before admitting retry.
      _replacement = true;
      unawaited(cancel());
    }
  }

  Future<void> cancel({int? attemptId}) {
    if (attemptId != null && attemptId != _generation) {
      return Future<void>.value();
    }
    final pending = _cancellation;
    if (pending != null) return pending;
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
    final cancellation = ++_generation;
    _clearAuthentication?.call();
    _clearAuthentication = null;
    final state = channel.state;
    final tunnel = _tunnel;
    _tunnel = null;
    final adopting = _adopting || _adopted;
    final ownsConnection = _ownsConnection;
    _ownsConnection = null;
    _adopting = false;
    _adopted = false;
    _pending = false;
    // Revoke the captured owner synchronously, before close can yield to
    // same-owner status/stream completions. A replacement guard is distinct
    // from immutable informational state equality.
    final disconnect =
        cancellation == _generation &&
            adopting &&
            !_replacement &&
            (channel is HermesApiChannel
                ? (ownsConnection?.call() ?? false)
                : identical(state, channel.state)) &&
            (state.status == HermesConnectionStatus.connecting ||
                state.status == HermesConnectionStatus.error ||
                state.connectedBaseUrl == tunnel?.agentUri.toString())
        ? channel.disconnect()
        : Future<void>.value();
    // Retire Agent authentication before releasing a reusable local port.
    try {
      await disconnect;
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
