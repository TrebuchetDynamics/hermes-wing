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

  Future<void> _submit(SshConnectionRequest input) async {
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
          try {
            return await const SecureManagedSshHostTrustStore().verify(
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
        widget.onConnected?.call();
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
    if (kIsWeb) return Text(strings.managedSshUnsupported);
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.linux) {
      return Text(strings.chatLayoutConnectionModeSshUrlHelper);
    }
    return LocalizedManagedSshConnectionForm(
      key: ObjectKey(controller),
      initialTarget: controller.recoveryTarget,
      onSubmit: _submit,
      allowServe: defaultTargetPlatform == TargetPlatform.android,
      pickKey: widget.pickKey,
      generatedKeyStore: widget.generatedKeyStore,
      onCancel: _cancel,
      busy: _busy,
      sanitizedError: _error,
    );
  }
}
