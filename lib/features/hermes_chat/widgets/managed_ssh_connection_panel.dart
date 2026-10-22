import 'package:wing/core/hermes/ssh/ssh_connection_request.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../ssh_keys/managed_ssh_key_selection.dart';
import '../ssh_keys/managed_ssh_generated_key_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/hermes/ssh/managed_ssh.dart';
import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/ssh/secure_managed_ssh_host_trust_store.dart';
import '../providers/managed_ssh_connection_controller.dart';
import 'localized_managed_ssh_connection_form.dart';
import 'managed_ssh_host_key_dialog.dart';
import '../../../core/hermes/ssh/secure_ssh_quick_connect_store.dart';

final sshQuickConnectStoreProvider = Provider<SecureSshQuickConnectStore>(
  (_) => SecureSshQuickConnectStore(),
);

class ManagedSshConnectionPanel extends ConsumerStatefulWidget {
  const ManagedSshConnectionPanel({
    super.key,
    required this.onCancel,
    this.onConnected,
    this.pickKey = pickManagedSshKey,
    this.generatedKeyStore,
  });
  final VoidCallback onCancel;
  final ManagedSshKeyPicker pickKey;
  final ManagedSshGeneratedKeyStore? generatedKeyStore;
  final VoidCallback? onConnected;
  @override
  ConsumerState<ManagedSshConnectionPanel> createState() =>
      _ManagedSshConnectionPanelState();
}

class _ManagedSshConnectionPanelState
    extends ConsumerState<ManagedSshConnectionPanel> {
  ManagedSshConnectionController? _controller;
  bool _busy = false;
  bool _adopted = false;
  int _generation = 0;
  int? _attemptId;
  String? _error;
  SshQuickConnection? _saved;
  bool _loading = true;
  bool _remember = false;
  bool _editing = false;
  bool Function()? _continueConnection;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSaved());
  }

  Future<void> _loadSaved() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final generation = ++_loadGeneration;
    final store = ref.read(sshQuickConnectStoreProvider);
    try {
      final saved = await store.load();
      if (!mounted ||
          generation != _loadGeneration ||
          !identical(store, ref.read(sshQuickConnectStoreProvider))) {
        return;
      }
      setState(() {
        _saved = saved;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context).managedSshQuickStorageFailed;
      });
    }
  }

  Future<void> _forgetSaved() async {
    if (_busy) return;
    final generation = ++_generation;
    ++_loadGeneration;
    setState(() => _busy = true);
    try {
      await ref.read(sshQuickConnectStoreProvider).forget();
      if (!mounted || generation != _generation) return;
      setState(() {
        _saved = null;
        _remember = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(
        () =>
            _error = AppLocalizations.of(context).managedSshQuickStorageFailed,
      );
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _submit(
    SshConnectionRequest input, {
    SshQuickConnection? saved,
  }) async {
    if (_busy || _loading) return;
    final generation = ++_generation;
    final strings = AppLocalizations.of(context);
    final controller = ref.read(managedSshConnectionControllerProvider);
    _controller = controller;
    setState(() {
      _busy = true;
      _error = null;
    });
    final previousAttempt = controller.attemptId;
    _attemptId = null;
    ManagedSshFailure? trustFailure;
    ManagedSshHostKey? verifiedKey;
    final remember = _remember && saved == null;
    final quickStore = ref.read(sshQuickConnectStoreProvider);
    String failureMessage(ManagedSshFailure? failure) => switch (failure) {
      ManagedSshFailure.hostKeyChanged => strings.managedSshHostKeyChanged,
      ManagedSshFailure.hostTrustUnavailable =>
        strings.managedSshHostTrustUnavailable,
      ManagedSshFailure.authentication =>
        strings.managedSshAuthenticationFailed,
      ManagedSshFailure.timeout => strings.managedSshTimeout,
      ManagedSshFailure.recoveryUnavailable =>
        strings.managedSshStorageUnavailable,
      _ => strings.managedSshFailed,
    };
    String agentFailureMessage(HermesConnectionFailureKind kind) =>
        switch (kind) {
          HermesConnectionFailureKind.authentication =>
            strings.managedSshAgentAuthenticationFailed,
          HermesConnectionFailureKind.incompatibleResponse ||
          HermesConnectionFailureKind.invalidEndpoint =>
            strings.managedSshAgentIncompatible,
          HermesConnectionFailureKind.network ||
          HermesConnectionFailureKind.timeout =>
            strings.managedSshAgentUnavailable,
          HermesConnectionFailureKind.tls => strings.connectionCheckTls,
          HermesConnectionFailureKind.unknown => strings.managedSshAgentFailed,
        };
    bool isCurrent() =>
        mounted &&
        generation == _generation &&
        controller.attemptId == previousAttempt + 1;
    try {
      final connecting = controller.connectSsh(
        input,
        verifyHostKey: (config, key) async {
          if (!isCurrent()) return false;
          if (saved != null && !saved.accepts(config, key)) {
            trustFailure = ManagedSshFailure.hostKeyChanged;
            return false;
          }
          try {
            final accepted = await const SecureManagedSshHostTrustStore().verify(
              config,
              key,
              isCurrent: isCurrent,
              review: () async {
                if (!isCurrent()) return false;
                return reviewManagedSshHostKey(
                  context,
                  host: config.host,
                  port: config.sshPort,
                  algorithm: key.algorithm,
                  fingerprint:
                      'SHA256:${base64.encode(key.sha256).replaceAll('=', '')}',
                  title: strings.managedSshHostKeyTitle,
                  explanation: strings.managedSshHostKeyBody,
                  cancelLabel: strings.cancelAction,
                  trustLabel: strings.managedSshTrustAction,
                );
              },
            );
            if (accepted && isCurrent()) verifiedKey = key;
            return accepted;
          } on ManagedSshException catch (error) {
            trustFailure = error.failure;
            return false;
          }
        },
      );
      if (controller.attemptId != previousAttempt) {
        _attemptId = controller.attemptId;
      }
      final connected = await connecting;
      if (!mounted || generation != _generation) return;
      if (connected) {
        _adopted = true;
        if (remember && input.transport == SshAgentTransport.advertisedApi) {
          final connectedState = controller.channel.state;
          bool ownsSave() =>
              isCurrent() &&
              identical(quickStore, ref.read(sshQuickConnectStoreProvider)) &&
              identical(connectedState, controller.channel.state);
          try {
            if (verifiedKey == null) throw const FormatException();
            final entry = SshQuickConnection(
              request: input,
              hostKey: verifiedKey!,
            );
            await quickStore.save(entry, isCurrent: ownsSave);
            if (!ownsSave()) return;
            _saved = entry;
          } catch (_) {
            if (!mounted || generation != _generation) return;
            _continueConnection = () =>
                mounted &&
                generation == _generation &&
                identical(connectedState, controller.channel.state);
            setState(() => _error = strings.managedSshQuickSaveFailed);
            return;
          }
        }
        if (isCurrent()) widget.onConnected?.call();
      }
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(
          () => _error = trustFailure != null
              ? failureMessage(trustFailure)
              : error is ManagedSshAgentException
              ? agentFailureMessage(error.kind)
              : failureMessage(
                  error is ManagedSshException ? error.failure : null,
                ),
        );
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  void _cancel() {
    ++_generation;
    if (!_adopted && _attemptId != null) {
      unawaited(
        _controller?.cancel(attemptId: _attemptId) ?? Future<void>.value(),
      );
    }
    widget.onCancel();
  }

  @override
  void dispose() {
    ++_generation;
    if (!_adopted && _attemptId != null) {
      unawaited(
        _controller?.cancel(attemptId: _attemptId) ?? Future<void>.value(),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final controller = ref.watch(managedSshConnectionControllerProvider);
    ref.listen(managedSshConnectionControllerProvider, (previous, next) {
      if (identical(previous, next)) return;
      ++_generation;
      final attempt = _attemptId;
      if (!_adopted && attempt != null) {
        unawaited(
          _controller?.cancel(attemptId: attempt) ?? Future<void>.value(),
        );
      }
      _controller = null;
      _attemptId = null;
      _busy = false;
      _error = null;
      _adopted = false;
    });
    ref.listen(sshQuickConnectStoreProvider, (previous, next) {
      if (identical(previous, next)) return;
      ++_generation;
      ++_loadGeneration;
      final attempt = _attemptId;
      if (!_adopted && attempt != null) {
        unawaited(
          _controller?.cancel(attemptId: attempt) ?? Future<void>.value(),
        );
      }
      _saved = null;
      _remember = false;
      _busy = false;
      _loading = true;
      unawaited(_loadSaved());
    });
    if (kIsWeb) return Text(strings.managedSshUnsupported);
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.linux) {
      return Text(strings.chatLayoutConnectionModeSshUrlHelper);
    }
    final saved = _saved;
    return SingleChildScrollView(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loading) const LinearProgressIndicator(),
        if (saved != null && !_editing) ...[
          Text(
            strings.managedSshQuickTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            '${saved.request.username}@${saved.request.host}:${saved.request.sshPort}',
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          Text(saved.request.agentProfile ?? 'default'),
          Text(strings.managedSshQuickBody),
          FilledButton.icon(
            key: const ValueKey('ssh-quick-connect'),
            onPressed: _busy || _loading
                ? null
                : () => _submit(saved.request, saved: saved),
            icon: const Icon(Icons.link),
            label: Text(
              _busy
                  ? strings.managedSshConnectingAction
                  : strings.managedSshQuickConnect,
            ),
          ),
          TextButton(
            key: const ValueKey('ssh-quick-edit'),
            onPressed: _busy
                ? null
                : () => setState(() {
                    _editing = true;
                    _remember = false;
                    _error = null;
                  }),
            child: Text(strings.managedSshQuickEdit),
          ),
        ] else ...[
          if (defaultTargetPlatform == TargetPlatform.android)
            CheckboxListTile(
              key: const ValueKey('ssh-quick-remember'),
              value: _remember,
              onChanged: _busy || _loading
                  ? null
                  : (value) => setState(() => _remember = value ?? false),
              title: Text(strings.managedSshQuickRemember),
              subtitle: Text(strings.managedSshQuickConsent),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          LocalizedManagedSshConnectionForm(
            key: ObjectKey(controller),
            initialTarget: controller.recoveryTarget,
            onSubmit: _submit,
            allowServe:
                defaultTargetPlatform == TargetPlatform.android && !_remember,
            pickKey: widget.pickKey,
            generatedKeyStore: widget.generatedKeyStore,
            onCancel: _cancel,
            busy: _busy || _loading,
            sanitizedError: _error,
          ),
        ],
        if (saved != null && !_editing)
          TextButton(
            key: const ValueKey('ssh-quick-cancel'),
            onPressed: _cancel,
            child: Text(strings.cancelAction),
          ),
        if (saved != null)
          TextButton(
            key: const ValueKey('ssh-quick-forget'),
            onPressed: _busy ? null : _forgetSaved,
            child: Text(strings.managedSshQuickForget),
          ),
        if (_error != null && saved != null && !_editing)
          Semantics(
            liveRegion: true,
            child: Text(_error!, key: const ValueKey('ssh-quick-error')),
          ),
        if (_adopted && _error == strings.managedSshQuickSaveFailed)
          TextButton(
            key: const ValueKey('ssh-quick-continue'),
            onPressed: _busy
                ? null
                : () {
                    if (_continueConnection?.call() ?? false) {
                      widget.onConnected?.call();
                    }
                  },
            child: Text(strings.managedSshQuickContinue),
          ),
      ],
      ),
    );
  }
}
