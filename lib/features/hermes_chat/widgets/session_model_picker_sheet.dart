import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/hermes/models/hermes_model_options.dart';
import '../../../l10n/app_localizations.dart';

/// Selects only from the Agent-owned inventory, for one session, not a profile.
class SessionModelPickerSheet extends StatefulWidget {
  const SessionModelPickerSheet({
    required this.options,
    required this.onLock,
    this.currentSessionModel,
    super.key,
  });
  final HermesModelOptions options;
  final HermesSessionModelLock? currentSessionModel;
  final Future<void> Function(String provider, String model) onLock;

  @override
  State<SessionModelPickerSheet> createState() =>
      _SessionModelPickerSheetState();
}

class _SessionModelPickerSheetState extends State<SessionModelPickerSheet> {
  late List<HermesModelOptionProvider> _providers;
  final _search = TextEditingController();
  String? _filter;
  String? _provider;
  String? _model;
  String? _error;
  bool _busy = false;
  int _inventoryGeneration = 0;
  String get _currentProvider =>
      widget.currentSessionModel?.provider ?? widget.options.currentProvider;
  String get _currentModel =>
      widget.currentSessionModel?.model ?? widget.options.currentModel;

  HermesModelOptionProvider? get _selectedProvider =>
      _providers.where((p) => p.slug == _provider).firstOrNull;
  bool get _selectionAvailable =>
      _model != null && (_selectedProvider?.models.contains(_model) ?? false);

  @override
  void initState() {
    super.initState();
    _providers = widget.options.selectableProviders;
    // A confirmed session identity is distinct from catalog eligibility. If it
    // is no longer selectable, keep it unavailable rather than revert silently.
    if (widget.currentSessionModel != null) {
      _provider = _currentProvider;
      _model = _currentModel;
      return;
    }
    final initial =
        _providers.where((p) => p.slug == _currentProvider).firstOrNull ??
        _providers.firstOrNull;
    _provider = initial?.slug;
    _model = initial?.models.contains(_currentModel) == true
        ? _currentModel
        : initial?.models.firstOrNull;
  }

  @override
  void didUpdateWidget(covariant SessionModelPickerSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.options, widget.options)) {
      _providers = widget.options.selectableProviders;
      _inventoryGeneration++;
      // Do not silently replace a stale draft selection with another identity.
      if (!_providers.any((p) => p.slug == _filter)) _filter = null;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _cancel() {
    if (!_busy) Navigator.of(context).maybePop();
  }

  Future<void> _lock() async {
    final provider = _provider;
    final model = _model;
    if (_busy || !_selectionAvailable || provider == null || model == null) {
      return;
    }
    final generation = _inventoryGeneration;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onLock(provider, model);
      if (!mounted) return;
      if (generation != _inventoryGeneration) {
        throw StateError('Inventory changed');
      }
      Navigator.of(context).pop();
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
    final query = _search.text.trim().toLowerCase();
    final rows = <({HermesModelOptionProvider provider, String model})>[];
    for (final provider in _providers) {
      if (_filter != null && provider.slug != _filter) continue;
      final providerMatches =
          provider.label.toLowerCase().contains(query) ||
          provider.slug.toLowerCase().contains(query);
      for (final model in provider.models) {
        if (providerMatches || model.toLowerCase().contains(query)) {
          rows.add((provider: provider, model: model));
        }
      }
    }
    bool isCurrent(({HermesModelOptionProvider provider, String model}) row) =>
        row.provider.slug == _currentProvider && row.model == _currentModel;
    // Stable partition; draft changes never reorder focused rows.
    final visible = [
      ...rows.where(isCurrent),
      ...rows.where((row) => !isCurrent(row)),
    ];
    final selected = _selectedProvider;

    return PopScope(
      canPop: !_busy,
      child: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): _cancel},
        child: FocusTraversalGroup(
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
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
                      Text(strings.sessionModelCatalogEmpty)
                    else ...[
                      TextField(
                        key: const ValueKey('session-model-search'),
                        controller: _search,
                        enabled: !_busy,
                        autofocus: MediaQuery.sizeOf(context).width >= 600,
                        maxLength: 200,
                        decoration: InputDecoration(
                          labelText: strings.sessionModelSearch,
                          counterText: '',
                          prefixIcon: const Icon(Icons.search),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: strings.sessionModelClearSearch,
                            onPressed: _busy || _search.text.isEmpty
                                ? null
                                : () {
                                    _search.clear();
                                    setState(() {});
                                  },
                            icon: const Icon(Icons.clear),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        key: ValueKey('session-model-filter-$_filter'),
                        initialValue: _filter ?? '',
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: strings.modelProviderLabel,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: '',
                            child: Text(strings.sessionModelAllProviders),
                          ),
                          for (final provider in _providers)
                            DropdownMenuItem(
                              value: provider.slug,
                              child: Text(
                                provider.label.isEmpty
                                    ? provider.slug
                                    : provider.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: _busy
                            ? null
                            : (value) => setState(
                                () => _filter = value == '' ? null : value,
                              ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy || (query.isEmpty && _filter == null)
                              ? null
                              : () {
                                  _search.clear();
                                  setState(() => _filter = null);
                                },
                          child: Text(strings.sessionModelResetFilters),
                        ),
                      ),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          strings.sessionModelResultCount(visible.length),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 240,
                        child: visible.isEmpty
                            ? Center(child: Text(strings.sessionModelNoResults))
                            : ListView.builder(
                                key: const ValueKey('session-model-results'),
                                itemCount: visible.length,
                                itemBuilder: (context, index) {
                                  final row = visible[index];
                                  final isSelected =
                                      row.provider.slug == _provider &&
                                      row.model == _model;
                                  return Semantics(
                                    container: true,
                                    selected: isSelected,
                                    child: ListTile(
                                      key: ValueKey(
                                        'session-model-${row.provider.slug}/${row.model}',
                                      ),
                                      enabled: !_busy,
                                      title: Text(row.model),
                                      subtitle: Text(
                                        '${row.provider.label} (${row.provider.slug})',
                                      ),
                                      trailing: isSelected
                                          ? const Icon(Icons.check)
                                          : null,
                                      onTap: _busy
                                          ? null
                                          : () => setState(() {
                                              _provider = row.provider.slug;
                                              _model = row.model;
                                              _error = null;
                                            }),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 12),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _selectionAvailable
                              ? strings.sessionModelSelected(
                                  '${selected!.label} ($_provider)',
                                  _model!,
                                )
                              : strings.sessionModelSelectionUnavailable,
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
                          onPressed: _busy ? null : _cancel,
                          child: Text(strings.cancelAction),
                        ),
                        FilledButton.icon(
                          onPressed: _busy || !_selectionAvailable
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
            ),
          ),
        ),
      ),
    );
  }
}
