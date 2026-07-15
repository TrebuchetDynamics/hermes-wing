import 'package:flutter/material.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../l10n/app_localizations.dart';

/// Write-only credential entry for a single provider.
///
/// The phone is a key-setter, never a key-reader: this sheet renders only the
/// provider's write-only presence (`configured` + masked [HermesProvider.keyHint])
/// and an obscured input for a NEW value. It never displays — and is never
/// given — a stored raw key. Set forwards the typed value to
/// [HermesChannel.setProviderCredential]; the value is transmitted write-only
/// and is never echoed back into observable state.
class ProviderCredentialSheet extends StatefulWidget {
  const ProviderCredentialSheet({
    required this.channel,
    required this.provider,
    super.key,
  });

  final HermesChannel channel;
  final HermesProvider provider;

  @override
  State<ProviderCredentialSheet> createState() =>
      _ProviderCredentialSheetState();
}

class _ProviderCredentialSheetState extends State<ProviderCredentialSheet> {
  final _valueController = TextEditingController();
  late String _envVar;
  String? _error;
  String? _validationDetail;
  bool _validationOk = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _envVar = widget.provider.envVars.isNotEmpty
        ? widget.provider.envVars.first
        : '';
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  HermesProvider get _provider => widget.provider;

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) await Navigator.of(context).maybePop();
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = AppLocalizations.of(context).credentialOperationFailed,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _set() async {
    final value = _valueController.text;
    if (value.isEmpty) {
      setState(
        () => _error = AppLocalizations.of(context).credentialValueRequired,
      );
      return;
    }
    await _runAction(
      () => widget.channel.setProviderCredential(
        slug: _provider.slug,
        envVar: _envVar,
        value: value,
      ),
    );
  }

  Future<void> _remove() async {
    await _runAction(
      () => widget.channel.removeProviderCredential(
        slug: _provider.slug,
        envVar: _envVar,
      ),
    );
  }

  Future<void> _validate() async {
    setState(() {
      _busy = true;
      _error = null;
      _validationDetail = null;
    });
    try {
      final probe = await widget.channel.validateProviderCredential(
        slug: _provider.slug,
      );
      if (!mounted) return;
      setState(() {
        _validationOk = probe.ok;
        _validationDetail = probe.detail;
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = AppLocalizations.of(context).credentialOperationFailed,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final label = _provider.label.isEmpty ? _provider.slug : _provider.label;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              strings.credentialSheetTitle(label),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(strings.credentialWriteOnlyNotice),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: Icon(
                    _provider.configured
                        ? Icons.check_circle_outline
                        : Icons.remove_circle_outline,
                    size: 18,
                  ),
                  label: Text(
                    _provider.configured
                        ? strings.credentialConfiguredStatus
                        : strings.credentialNotConfiguredStatus,
                  ),
                ),
                // Masked last-4-only hint — the single sanctioned disclosure.
                if (_provider.keyHint != null)
                  Chip(
                    avatar: const Icon(Icons.password_outlined, size: 18),
                    label: Text(
                      strings.providerKeyHintLabel(_provider.keyHint!),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.provider.envVars.length > 1) ...[
              DropdownButtonFormField<String>(
                initialValue: _envVar,
                decoration: InputDecoration(
                  labelText: strings.credentialEnvVarLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final envVar in widget.provider.envVars)
                    DropdownMenuItem<String>(
                      value: envVar,
                      child: Text(envVar),
                    ),
                ],
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _envVar = value ?? _envVar),
              ),
              const SizedBox(height: 16),
            ] else if (_envVar.isNotEmpty) ...[
              Text('${strings.credentialEnvVarLabel}: $_envVar'),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _valueController,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: strings.credentialValueLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_validationDetail != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Row(
                  children: [
                    Icon(
                      _validationOk
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      size: 18,
                      color: _validationOk
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_validationDetail!)),
                  ],
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(context).maybePop(),
                  child: Text(strings.cancelAction),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _validate,
                  icon: const Icon(Icons.verified_outlined),
                  label: Text(strings.validateCredentialAction),
                ),
                if (_provider.configured)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    onPressed: _busy ? null : _remove,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(strings.removeCredentialAction),
                  ),
                FilledButton.icon(
                  onPressed: _busy ? null : _set,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(strings.setCredentialAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
