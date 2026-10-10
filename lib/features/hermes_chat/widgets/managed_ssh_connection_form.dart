import 'package:wing/core/hermes/ssh/ssh_connection_request.dart';
import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ssh_keys/managed_ssh_generated_key_store.dart';
import '../ssh_keys/managed_ssh_key_selection.dart';

/// All visible copy is supplied by the localized parent.
@immutable
class ManagedSshConnectionLabels {
  const ManagedSshConnectionLabels({
    required this.host,
    required this.sshPort,
    required this.username,
    required this.password,
    required this.agentPort,
    required this.agentToken,
    required this.connect,
    required this.connecting,
    required this.cancel,

    required this.privateKey,
    required this.passwordChoice,
    required this.selectKey,
    required this.keyRequired,
    required this.passphrase,
    required this.passphraseRequired,
    required this.unlockFailed,
    required this.keyUnreadable,
    required this.keyTooLarge,
    required this.keyUnsupportedFormat,
    required this.keyInvalid,
    required this.selectedKey,
    required this.invalidHost,
    required this.invalidPort,
    required this.invalidUsername,
    required this.invalidPassword,
    required this.invalidToken,
    required this.failure,
  });
  final String host, sshPort, username, password, agentPort, agentToken;
  final String connect, connecting, cancel;
  final String privateKey, passwordChoice, selectKey, keyRequired;
  final String passphrase, passphraseRequired, unlockFailed;
  final String keyUnreadable,
      keyTooLarge,
      keyUnsupportedFormat,
      keyInvalid,
      selectedKey;
  final String invalidHost, invalidPort, invalidUsername, invalidPassword;
  final String invalidToken, failure;
}

@immutable
class ManagedSshGeneratedKeyLabels {
  const ManagedSshGeneratedKeyLabels({
    required this.generate,
    required this.useSaved,
    required this.consentTitle,
    required this.consentBody,
    required this.confirm,
    required this.copyPublic,
    required this.copied,
    required this.storageFailure,
    required this.selected,
    required this.generating,
  });
  final String generate, useSaved, consentTitle, consentBody, confirm;
  final String copyPublic, copied, storageFailure, selected, generating;
}

/// Connections and host trust remain owned by the parent controller.
class ManagedSshConnectionForm extends StatefulWidget {
  const ManagedSshConnectionForm({
    super.key,
    required this.labels,
    required this.onSubmit,
    required this.onCancel,
    this.busy = false,
    this.sanitizedError,
    this.pickKey = pickManagedSshKey,
    this.generatedKeyStore,
    this.generatedKeyLabels,
  });
  final ManagedSshGeneratedKeyStore? generatedKeyStore;
  final ManagedSshGeneratedKeyLabels? generatedKeyLabels;
  final ManagedSshConnectionLabels labels;
  final ManagedSshKeyPicker pickKey;
  final Future<void> Function(SshConnectionRequest) onSubmit;

  /// The parent must cancel its outstanding transport attempt when invoked.
  final VoidCallback onCancel;
  final bool busy;

  /// Only allowlisted, secret-free error copy; never raw transport exceptions.
  final String? sanitizedError;
  @override
  State<ManagedSshConnectionForm> createState() =>
      _ManagedSshConnectionFormState();
}

class _ManagedSshConnectionFormState extends State<ManagedSshConnectionForm> {
  final _form = GlobalKey<FormState>();
  bool _keyAuthentication = false;
  SelectedManagedSshKey? _selectedKey;
  String? _keyError;
  late final _generatedKeyStore =
      widget.generatedKeyStore ?? ManagedSshGeneratedKeyStore();
  String? _generatedPublicKey;
  bool _generatingKey = false;
  bool _consenting = false;
  int _keyOperation = 0;
  bool get _keyOperationBusy => _generatingKey || _consenting;
  final _host = TextEditingController();
  final _sshPort = TextEditingController(text: '22');
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _passphrase = TextEditingController();
  final _agentPort = TextEditingController(text: '8642');
  final _agentToken = TextEditingController();

  static int? _port(String text) {
    if (!RegExp(r'^[0-9]{1,5}$').hasMatch(text)) return null;
    final value = int.parse(text);
    return value >= 1 && value <= 65535 ? value : null;
  }

  static bool _validHost(String text) {
    if (text.isEmpty || text.length > 253) return false;
    if (text.contains(':')) {
      final uri = Uri.tryParse('http://[$text]');
      return uri != null && uri.host.isNotEmpty;
    }
    if (RegExp(r'^[0-9.]+$').hasMatch(text)) {
      final parts = text.split('.');
      return parts.length == 4 &&
          parts.every(
            (p) => RegExp(r'^[0-9]{1,3}$').hasMatch(p) && int.parse(p) <= 255,
          );
    }
    return text
        .split('.')
        .every(
          (p) =>
              p.length <= 63 &&
              RegExp(r'^[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?$').hasMatch(p),
        );
  }

  String? _validate(String id, String? value) {
    final v = value ?? '';
    final l = widget.labels;
    switch (id) {
      case 'host':
        return _validHost(v.trim()) ? null : l.invalidHost;
      case 'ssh-port':
      case 'agent-port':
        return _port(v) != null ? null : l.invalidPort;
      case 'username':
        return RegExp(r'^[a-zA-Z0-9_][a-zA-Z0-9_.-]{0,63}$').hasMatch(v.trim())
            ? null
            : l.invalidUsername;
      case 'passphrase':
        return v.isNotEmpty && v.length <= 4096 && !v.contains('\u0000')
            ? null
            : l.passphraseRequired;
      case 'password':
        return v.isNotEmpty && v.length <= 4096 && !v.contains('\u0000')
            ? null
            : l.invalidPassword;
      case 'agent-token':
        return v.isEmpty ||
                (v.length <= 4096 && RegExp(r'^[\x21-\x7e]+$').hasMatch(v))
            ? null
            : l.invalidToken;
      default:
        return null;
    }
  }

  bool _submitting = false;
  bool _failed = false;
  int _generation = 0;
  bool get _busy => widget.busy || _submitting;

  Future<void> _submit() async {
    if (_busy ||
        _picking ||
        _keyOperationBusy ||
        !_form.currentState!.validate()) {
      return;
    }
    if (_keyAuthentication && _selectedKey == null) {
      setState(() => _keyError = widget.labels.keyRequired);
      return;
    }
    if (_keyAuthentication && _selectedKey!.encrypted) {
      try {
        _selectedKey!.unlock(_passphrase.text);
      } catch (_) {
        setState(() {
          _clearSecrets();
          _keyError = widget.labels.unlockFailed;
        });
        return;
      }
    }
    final generation = ++_generation;
    final input = SshConnectionRequest(
      host: _host.text.trim(),
      sshPort: _port(_sshPort.text)!,
      username: _username.text.trim(),
      password: _keyAuthentication ? '' : _password.text,
      privateKey: _keyAuthentication ? _selectedKey?.pem : null,
      passphrase: _keyAuthentication && _selectedKey!.encrypted
          ? _passphrase.text
          : null,
      agentPort: _port(_agentPort.text)!,
      agentBearerToken: _agentToken.text.isEmpty ? null : _agentToken.text,
    );
    setState(() {
      _submitting = true;
      _failed = false;
      _clearKey();
    });
    try {
      await widget.onSubmit(input);
    } catch (_) {
      // Raw transport errors may contain credentials. Never render or log them.
      if (mounted && generation == _generation) _failed = true;
    } finally {
      if (mounted) {
        _clearSecrets();
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  int _pickerGeneration = 0;
  bool _picking = false;

  Future<void> _pickKey() async {
    if (_busy || _picking || _keyOperationBusy || !_keyAuthentication) return;
    _clearKey();
    final generation = ++_pickerGeneration;
    setState(() {
      _picking = true;
      _keyError = null;
    });
    try {
      final file = await widget.pickKey();
      if (!mounted || generation != _pickerGeneration || file == null) return;
      final key = await SelectedManagedSshKey.read(file);
      if (mounted && generation == _pickerGeneration) {
        setState(() => _selectedKey = key);
      }
    } catch (error) {
      if (mounted && generation == _pickerGeneration) {
        final failure = error is ManagedSshKeyException
            ? error.failure
            : ManagedSshKeyFailure.unreadable;
        setState(
          () => _keyError = switch (failure) {
            ManagedSshKeyFailure.unreadable => widget.labels.keyUnreadable,
            ManagedSshKeyFailure.tooLarge => widget.labels.keyTooLarge,
            ManagedSshKeyFailure.unsupported =>
              widget.labels.keyUnsupportedFormat,
            ManagedSshKeyFailure.invalid => widget.labels.keyInvalid,
          },
        );
      }
    } finally {
      if (mounted && generation == _pickerGeneration) {
        setState(() => _picking = false);
      }
    }
  }

  bool _retainedKeyNotice = false;

  bool _currentKeyOperation(int operation) =>
      mounted && operation == _keyOperation && _keyAuthentication && !_busy;

  Future<void> _useGeneratedKey({required bool generate}) async {
    final labels = widget.generatedKeyLabels;
    if (kIsWeb ||
        labels == null ||
        _busy ||
        _picking ||
        _keyOperationBusy ||
        !_keyAuthentication) {
      return;
    }
    _clearKey();
    final operation = ++_keyOperation;
    if (generate) {
      setState(() => _consenting = true);
      final consent = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(labels.consentTitle),
          content: Text(labels.consentBody),
          actions: [
            TextButton(
              key: const ValueKey('managed-ssh-generate-cancel'),
              autofocus: true,
              onPressed: () => Navigator.pop(context, false),
              child: Text(widget.labels.cancel),
            ),
            TextButton(
              key: const ValueKey('managed-ssh-generate-confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(labels.confirm),
            ),
          ],
        ),
      );
      if (!_currentKeyOperation(operation)) return;
      setState(() => _consenting = false);
      if (consent != true) return;
    }
    setState(() {
      _generatingKey = true;
      _keyError = null;
    });
    try {
      // generate returns only a read-back secure record, never an ephemeral key.
      final key = generate
          ? await _generatedKeyStore.generate()
          : await _generatedKeyStore.load();
      if (key != null && mounted) {
        setState(() => _retainedKeyNotice = true);
      }
      if (!_currentKeyOperation(operation)) return;
      if (key == null) {
        setState(() => _keyError = widget.labels.keyRequired);
        return;
      }
      final selected = await SelectedManagedSshKey.read(
        XFile.fromData(utf8.encode(key.privatePem), name: ''),
      );
      if (!_currentKeyOperation(operation)) return;
      setState(() {
        _selectedKey = selected;
        _generatedPublicKey = key.publicKey;
        _retainedKeyNotice = false;
      });
    } catch (_) {
      if (_currentKeyOperation(operation)) {
        setState(() => _keyError = labels.storageFailure);
      }
    } finally {
      if (mounted) setState(() => _generatingKey = false);
    }
  }

  Future<void> _copyPublicKey() async {
    final publicKey = _generatedPublicKey;
    final operation = _keyOperation;
    if (publicKey == null ||
        !_currentKeyOperation(operation) ||
        _keyOperationBusy ||
        _picking ||
        _keyError != null) {
      return;
    }
    try {
      await Clipboard.setData(ClipboardData(text: publicKey));
      if (mounted && _currentKeyOperation(operation)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.generatedKeyLabels!.copied)),
        );
      }
    } catch (_) {
      if (_currentKeyOperation(operation)) {
        setState(() => _keyError = widget.generatedKeyLabels!.storageFailure);
      }
    }
  }

  void _clearKey() {
    ++_keyOperation;
    _consenting = false;
    _generatedPublicKey = null;
    ++_pickerGeneration;
    _picking = false;
    _selectedKey = null;
    _passphrase.clear();
  }

  void _chooseAuthentication(bool key) {
    setState(() {
      _clearSecrets();
      _keyAuthentication = key;
      _keyError = null;
    });
  }

  void _cancel() {
    ++_generation;
    if (_generatedPublicKey != null) _retainedKeyNotice = true;
    _clearSecrets();
    setState(() {
      _failed = false;
    });
    widget.onCancel();
  }

  @override
  void didUpdateWidget(covariant ManagedSshConnectionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.busy && !oldWidget.busy) _clearKey();
    if (widget.sanitizedError != null &&
        widget.sanitizedError != oldWidget.sanitizedError) {
      _clearSecrets();
    }
  }

  void _clearSecrets() {
    _clearKey();
    _password.clear();
    _agentToken.clear();
  }

  @override
  void dispose() {
    _clearSecrets();
    for (final c in [
      _host,
      _sshPort,
      _username,
      _password,
      _passphrase,
      _agentPort,
      _agentToken,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _field(
    String id,
    String label,
    TextEditingController controller, {
    bool secret = false,
    bool port = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(child: Text(label)),
        const SizedBox(height: 8),
        Semantics(
          label: label,
          child: TextFormField(
            key: ValueKey('managed-ssh-$id'),
            controller: controller,
            enabled: !_busy,
            validator: (value) => _validate(id, value),
            obscureText: secret,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: port ? TextInputType.number : TextInputType.text,
            textInputAction: TextInputAction.next,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = widget.labels;
    return FocusTraversalGroup(
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final host = _field('host', l.host, _host);
                  final port = _field(
                    'ssh-port',
                    l.sshPort,
                    _sshPort,
                    port: true,
                  );
                  if (constraints.maxWidth >= 600 &&
                      MediaQuery.textScalerOf(context).scale(16) <= 24) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: host),
                        const SizedBox(width: 16),
                        Expanded(child: port),
                      ],
                    );
                  }
                  return Column(children: [host, port]);
                },
              ),
              _field('username', l.username, _username),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    key: const ValueKey('managed-ssh-auth-private-key'),
                    label: Text(l.privateKey),
                    selected: _keyAuthentication,
                    onSelected: _busy
                        ? null
                        : (_) => _chooseAuthentication(true),
                  ),
                  ChoiceChip(
                    key: const ValueKey('managed-ssh-auth-password'),
                    label: Text(l.passwordChoice),
                    selected: !_keyAuthentication,
                    onSelected: _busy
                        ? null
                        : (_) => _chooseAuthentication(false),
                  ),
                ],
              ),
              if (!_keyAuthentication)
                _field('password', l.password, _password, secret: true),
              if (_retainedKeyNotice && widget.generatedKeyLabels != null)
                Semantics(
                  liveRegion: true,
                  child: Text(widget.generatedKeyLabels!.consentBody),
                ),
              if (_keyAuthentication) ...[
                if (!kIsWeb && widget.generatedKeyLabels != null) ...[
                  OutlinedButton(
                    key: const ValueKey('managed-ssh-generate-key'),
                    onPressed: _busy || _picking || _keyOperationBusy
                        ? null
                        : () => _useGeneratedKey(generate: true),
                    child: Text(
                      _generatingKey
                          ? widget.generatedKeyLabels!.generating
                          : widget.generatedKeyLabels!.generate,
                    ),
                  ),
                  OutlinedButton(
                    key: const ValueKey('managed-ssh-use-generated-key'),
                    onPressed: _busy || _picking || _keyOperationBusy
                        ? null
                        : () => _useGeneratedKey(generate: false),
                    child: Text(widget.generatedKeyLabels!.useSaved),
                  ),
                  if (_generatedPublicKey != null) ...[
                    Text(widget.generatedKeyLabels!.selected),
                    SelectableText(
                      _generatedPublicKey!,
                      key: const ValueKey('managed-ssh-generated-public-key'),
                    ),
                    Text(_selectedKey!.fingerprint!),
                    OutlinedButton(
                      key: const ValueKey('managed-ssh-copy-public-key'),
                      onPressed: _busy || _keyOperationBusy || _keyError != null
                          ? null
                          : _copyPublicKey,
                      child: Text(widget.generatedKeyLabels!.copyPublic),
                    ),
                  ],
                ],
                OutlinedButton(
                  key: const ValueKey('managed-ssh-select-key'),
                  onPressed: _busy || _picking || _keyOperationBusy
                      ? null
                      : _pickKey,
                  child: Text(l.selectKey),
                ),
                if (_selectedKey != null && _generatedPublicKey == null) ...[
                  Text(
                    _selectedKey!.filename.isEmpty
                        ? l.selectedKey
                        : _selectedKey!.filename,
                  ),
                  if (_selectedKey!.fingerprint != null)
                    Text(_selectedKey!.fingerprint!),
                  if (_selectedKey!.encrypted)
                    _field(
                      'passphrase',
                      l.passphrase,
                      _passphrase,
                      secret: true,
                    ),
                ],
                if (_keyError != null) Text(_keyError!),
              ],
              _field('agent-port', l.agentPort, _agentPort, port: true),
              _field('agent-token', l.agentToken, _agentToken, secret: true),
              if (widget.sanitizedError != null || _failed)
                Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(widget.sanitizedError ?? l.failure),
                  ),
                ),
              FilledButton(
                onPressed: _busy || _picking || _keyOperationBusy
                    ? null
                    : _submit,
                child: Text(_busy ? l.connecting : l.connect),
              ),
              TextButton(onPressed: _cancel, child: Text(l.cancel)),
            ],
          ),
        ),
      ),
    );
  }
}
