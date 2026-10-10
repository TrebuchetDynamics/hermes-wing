import 'package:wing/core/hermes/ssh/ssh_connection_request.dart';
import 'package:flutter/material.dart';
import '../ssh_keys/managed_ssh_key_selection.dart';
import '../ssh_keys/managed_ssh_generated_key_store.dart';
import 'package:wing/l10n/app_localizations.dart';

import 'managed_ssh_connection_form.dart';

/// Supplies product copy without storing authentication or selecting an endpoint.
class LocalizedManagedSshConnectionForm extends StatelessWidget {
  const LocalizedManagedSshConnectionForm({
    super.key,
    required this.onSubmit,
    required this.onCancel,
    this.busy = false,
    this.sanitizedError,
    this.pickKey = pickManagedSshKey,
    this.generatedKeyStore,
  });

  final Future<void> Function(SshConnectionRequest) onSubmit;
  final VoidCallback onCancel;
  final ManagedSshKeyPicker pickKey;
  final ManagedSshGeneratedKeyStore? generatedKeyStore;
  final bool busy;
  final String? sanitizedError;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return ManagedSshConnectionForm(
      labels: ManagedSshConnectionLabels(
        host: strings.managedSshHostLabel,
        sshPort: strings.managedSshPortLabel,
        username: strings.managedSshUsernameLabel,
        password: strings.managedSshPasswordLabel,
        agentPort: strings.managedSshAgentPortLabel,
        agentToken: strings.managedSshAgentTokenLabel,
        connect: strings.managedSshConnectAction,
        connecting: strings.managedSshConnectingAction,
        cancel: strings.cancelAction,

        privateKey: strings.managedSshPrivateKeyChoice,
        passwordChoice: strings.managedSshPasswordChoice,
        selectKey: strings.managedSshSelectKey,
        keyRequired: strings.managedSshKeyRequired,
        passphrase: strings.managedSshPassphrase,
        passphraseRequired: strings.managedSshPassphraseRequired,
        unlockFailed: strings.managedSshUnlockFailed,
        keyUnreadable: strings.managedSshKeyUnreadable,
        keyTooLarge: strings.managedSshKeyTooLarge,
        keyUnsupportedFormat: strings.managedSshKeyUnsupportedFormat,
        keyInvalid: strings.managedSshKeyInvalid,
        selectedKey: strings.managedSshSelectedKey,
        invalidHost: strings.managedSshInvalidHost,
        invalidPort: strings.managedSshInvalidPort,
        invalidUsername: strings.managedSshUsernameRequired,
        invalidPassword: strings.managedSshPasswordRequired,
        invalidToken: strings.managedSshInvalidToken,
        failure: strings.managedSshFailed,
      ),
      generatedKeyLabels: ManagedSshGeneratedKeyLabels(
        generate: strings.managedSshGenerateKey,
        useSaved: strings.managedSshUseGeneratedKey,
        consentTitle: strings.managedSshGenerateKeyConsentTitle,
        consentBody: strings.managedSshGenerateKeyConsentBody,
        confirm: strings.managedSshGenerateKeyConfirm,
        copyPublic: strings.managedSshCopyPublicKey,
        copied: strings.managedSshPublicKeyCopied,
        storageFailure: strings.managedSshGeneratedKeyStorageFailure,
        selected: strings.managedSshGeneratedKeySelected,
        generating: strings.managedSshGeneratingKey,
      ),
      onSubmit: onSubmit,
      pickKey: pickKey,
      generatedKeyStore: generatedKeyStore,
      onCancel: onCancel,
      busy: busy,
      sanitizedError: sanitizedError,
    );
  }
}
