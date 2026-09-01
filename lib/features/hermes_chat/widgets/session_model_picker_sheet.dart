import 'package:flutter/material.dart';

import '../../../core/hermes/models/hermes_model_options.dart';
import '../../../l10n/app_localizations.dart';

/// Selects a provider/model from the Agent-owned picker inventory and asks the
/// backend to confirm it for one session. It deliberately has no profile-wide
/// assignment path.
class SessionModelPickerSheet extends StatefulWidget {
  const SessionModelPickerSheet({
    required this.options,
    required this.onLock,
    super.key,
  });

  final HermesModelOptions options;
  final Future<void> Function(String provider, String model) onLock;

  @override
  State<SessionModelPickerSheet> createState() =>
      _SessionModelPickerSheetState();
}

class _SessionModelPickerSheetState extends State<SessionModelPickerSheet> {
  late final List<HermesModelOptionProvider> _providers;
  String? _provider;
  String? _model;
  String? _error;
  bool _busy = false;

  HermesModelOptionProvider? get _selectedProvider {
    for (final provider in _providers) {
      if (provider.slug == _provider) return provider;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _providers = widget.options.selectableProviders;
    final currentProvider = widget.options.currentProvider;
    final initial = _providers.firstWhere(
      (provider) => provider.slug == currentProvider,
      orElse: () =>
          _providers.firstOrNull ??
          const HermesModelOptionProvider(slug: '', label: '', models: []),
    );
    _provider = initial.slug.isEmpty ? null : initial.slug;
    _model = initial.models.contains(widget.options.currentModel)
        ? widget.options.currentModel
        : initial.models.firstOrNull;
  }

  void _selectProvider(String? provider) {
    final next = _providers.firstWhere(
      (item) => item.slug == provider,
      orElse: () =>
          const HermesModelOptionProvider(slug: '', label: '', models: []),
    );
    setState(() {
      _provider = next.slug.isEmpty ? null : next.slug;
      _model = next.models.firstOrNull;
      _error = null;
    });
  }

  Future<void> _lock() async {
    final provider = _provider;
    final model = _model;
    if (provider == null || model == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onLock(provider, model);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(context).sessionModelLockFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final selected = _selectedProvider;
    final models = selected?.models ?? const <String>[];

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
              strings.sessionModelPickerTitle,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(strings.sessionModelPickerDescription),
            const SizedBox(height: 16),
            if (_providers.isEmpty)
              Text(strings.modelCatalogEmpty, textAlign: TextAlign.center)
            else ...[
              DropdownButtonFormField<String>(
                initialValue: _provider,
                decoration: InputDecoration(
                  labelText: strings.modelProviderLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final provider in _providers)
                    DropdownMenuItem(
                      value: provider.slug,
                      child: Text(
                        provider.label.isEmpty ? provider.slug : provider.label,
                      ),
                    ),
                ],
                onChanged: _busy ? null : _selectProvider,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _model,
                decoration: InputDecoration(
                  labelText: strings.modelNameLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final model in models)
                    DropdownMenuItem(value: model, child: Text(model)),
                ],
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _model = value),
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
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  child: Text(strings.cancelAction),
                ),
                FilledButton.icon(
                  onPressed: _busy || _provider == null || _model == null
                      ? null
                      : _lock,
                  icon: const Icon(Icons.lock_outline),
                  label: Text(strings.sessionModelLockAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
