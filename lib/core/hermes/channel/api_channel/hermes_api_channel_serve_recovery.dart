part of '../hermes_api_channel.dart';

extension _ServeRecoveryExtension on HermesApiChannel {
  Future<void> _forgetServeRecovery() async {
    _serveRecovery = null;
    _serveRecoveryGeneration++;
    final operation = _servePersistenceTail.then(
      (_) => _serveRecoveryStore?.clear(),
    );
    _servePersistenceTail = operation.catchError((Object _) {});
    await operation;
  }

  Future<void> _persistServeRecovery(
    HermesServeLifecycle lifecycle, {
    bool uncertain = false,
  }) async {
    if (!_serveOwnerIsCurrent) {
      throw const HermesWebReadException(HermesWebFailureKind.stale);
    }
    final c = lifecycle.recovery;
    final selection = HermesServeRecoverySelection(
      HermesWebRecovery(
        profile: c.profile,
        origin: c.origin,
        runtimeSessionId: c.runtimeSessionId,
        storedSessionId: c.storedSessionId,
        epoch: c.epoch,
        sequence: c.sequence,
        uncertain: uncertain || c.uncertain,
      ),
      _serveCredential!,
    );
    _serveRecovery = selection;
    final persist = !_serveTransient;
    final operation = _servePersistenceTail.then((_) async {
      if (identical(lifecycle, _serveLifecycle) && _serveOwnerIsCurrent) {
        if (persist) {
          await _serveRecoveryStore?.save(selection);
        } else {
          await _persistForwardedRecovery?.call(selection.checkpoint);
        }
      }
    });
    _servePersistenceTail = operation.catchError((Object _) {});
    await operation;
    if (!identical(lifecycle, _serveLifecycle) || !_serveOwnerIsCurrent) {
      throw const HermesWebReadException(HermesWebFailureKind.stale);
    }
  }

  /// Restores a deliberately enabled conversation, never a pending mutation.
  Future<bool> _restoreSavedServeConversation() async {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.linux ||
        _serveRecoveryStore == null) {
      return false;
    }
    final generation = _serveRecoveryGeneration;
    final connection = _connectionGeneration;
    HermesServeRecoverySelection? selection;
    try {
      selection = await _serveRecoveryStore.load();
    } catch (_) {
      if (generation != _serveRecoveryGeneration ||
          connection != _connectionGeneration) {
        return false;
      }
      _setState(
        const HermesChannelState(
          status: HermesConnectionStatus.error,
          isServeReadOnly: true,
          errorMessage:
              'Saved local conversation is unavailable. Retry secure storage explicitly.',
        ),
      );
      return true;
    }
    if (selection == null ||
        generation != _serveRecoveryGeneration ||
        connection != _connectionGeneration) {
      return false;
    }
    _serveRecovery = selection;
    await _retryServeRecovery();
    return true;
  }

  Future<void> _retryServeRecovery() async {
    final selection = _serveRecovery;
    if (selection == null || _serveRestorationPending) return;
    _serveRestorationPending = true;
    try {
      final c = selection.checkpoint;
      final connection = _connectionGeneration + 1;
      await _connectServeReads(
        c.origin.toString(),
        selection.credential,
        profile: c.profile,
        storedSession: c.storedSessionId,
        transient: _serveTransient,
        remoteGateway: _serveRemoteGateway,
        persistRecovery: _persistForwardedRecovery,
        canAccept: _serveTransient
            ? _serveCanAccept
            : () => identical(selection, _serveRecovery),
      );
      if (!identical(selection, _serveRecovery) ||
          connection != _connectionGeneration) {
        return;
      }
      if (!_state.isConnected) {
        _setState(
          _state.copyWith(
            isServeReadOnly: true,
            connectedBaseUrl: c.origin.toString(),
            selectedProfileId: c.profile,
            activeSessionId: c.storedSessionId,
            hasUnreconciledRun: true,
          ),
        );
        return;
      }
      await _qualifyServeChat();
    } finally {
      _serveRestorationPending = false;
    }
  }
}
