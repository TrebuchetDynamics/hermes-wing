import 'package:flutter/material.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../l10n/app_localizations.dart';

String auxiliaryTaskLabel(AppLocalizations strings, String task) =>
    switch (task) {
      'vision' => strings.auxiliaryTaskVision,
      'web_extract' => strings.auxiliaryTaskWebExtract,
      'compression' => strings.auxiliaryTaskCompression,
      'skills_hub' => strings.auxiliaryTaskSkillsHub,
      'approval' => strings.auxiliaryTaskApproval,
      'mcp' => strings.auxiliaryTaskMcp,
      'title_generation' => strings.auxiliaryTaskTitleGeneration,
      'triage_specifier' => strings.auxiliaryTaskTriageSpecifier,
      'kanban_decomposer' => strings.auxiliaryTaskKanbanDecomposer,
      'profile_describer' => strings.auxiliaryTaskProfileDescriber,
      'curator' => strings.auxiliaryTaskCurator,
      _ => task,
    };

/// Slot options for a model assignment: the main slot or one existing
/// auxiliary task slot.
class _SlotOption {
  const _SlotOption({required this.label, required this.scope, this.task});

  final String label;
  final String scope;
  final String? task;
}

/// Picks a provider/model for the main or an auxiliary slot from
/// `state.modelInventory.catalog`, assigning it with the current revision as an
/// `If-Match` precondition. A refresh action triggers the one gated outbound
/// catalog fetch.
class ModelPickerSheet extends StatefulWidget {
  const ModelPickerSheet({
    required this.channel,
    required this.inventory,
    super.key,
  });

  final HermesChannel channel;
  final HermesModelInventory inventory;

  @override
  State<ModelPickerSheet> createState() => _ModelPickerSheetState();
}

class _ModelPickerSheetState extends State<ModelPickerSheet> {
  late HermesModelInventory _inventory;
  late List<_SlotOption> _slots;
  _SlotOption? _slot;
  String? _provider;
  String? _model;
  String? _error;
  bool _busy = false;

  HermesModelCatalog get _catalog => _inventory.catalog;
  HermesModelAssignment get _assignment => _inventory.assignment;

  @override
  void initState() {
    super.initState();
    _applyInventory(widget.inventory);
  }

  /// Derives the sheet's local slot/provider/model selection from
  /// [inventory]. Used both for the initial snapshot in [initState] and to
  /// re-derive local state after a successful catalog refresh, so the two
  /// paths can never drift apart.
  ///
  /// A prior in-progress selection (slot/provider/model already chosen by
  /// the user) is preserved when it still exists in the new catalog;
  /// otherwise the inventory's active/assigned value is preferred, falling
  /// back to the first available option.
  void _applyInventory(HermesModelInventory inventory) {
    _inventory = inventory;
    final catalog = inventory.catalog;
    final assignment = inventory.assignment;

    final previousSlot = _slot;
    final slots = [
      const _SlotOption(label: 'main', scope: 'main'),
      for (final aux in assignment.auxiliary)
        _SlotOption(label: aux.task, scope: 'auxiliary', task: aux.task),
    ];
    _slots = slots;
    _slot = slots.firstWhere(
      (slot) =>
          previousSlot != null &&
          slot.scope == previousSlot.scope &&
          slot.task == previousSlot.task,
      orElse: () => slots.first,
    );

    List<HermesCatalogModel> modelsFor(String? provider) {
      for (final block in catalog.providers) {
        if (block.provider == provider) return block.models;
      }
      return const [];
    }

    final previousProvider = _provider;
    if (previousProvider != null &&
        catalog.providers.any((block) => block.provider == previousProvider)) {
      _provider = previousProvider;
    } else if (assignment.activeProvider.isNotEmpty &&
        catalog.providers.any(
          (block) => block.provider == assignment.activeProvider,
        )) {
      _provider = assignment.activeProvider;
    } else {
      _provider = catalog.providers.isNotEmpty
          ? catalog.providers.first.provider
          : null;
    }

    final models = modelsFor(_provider);
    final previousModel = _model;
    if (previousModel != null && models.any((m) => m.id == previousModel)) {
      _model = previousModel;
    } else if (_provider == assignment.activeProvider &&
        assignment.activeModel.isNotEmpty &&
        models.any((m) => m.id == assignment.activeModel)) {
      _model = assignment.activeModel;
    } else {
      _model = models.isNotEmpty ? models.first.id : null;
    }
  }

  List<HermesCatalogModel> get _modelsForProvider {
    for (final block in _catalog.providers) {
      if (block.provider == _provider) return block.models;
    }
    return const [];
  }

  void _syncModel() {
    final models = _modelsForProvider;
    _model = models.isNotEmpty ? models.first.id : null;
  }

  void _syncSlotAssignment() {
    var provider = _assignment.activeProvider;
    var model = _assignment.activeModel;
    if (_slot?.scope == 'auxiliary') {
      for (final auxiliary in _assignment.auxiliary) {
        if (auxiliary.task == _slot?.task) {
          provider = auxiliary.provider;
          model = auxiliary.model;
          break;
        }
      }
    }

    if (_catalog.providers.any((block) => block.provider == provider)) {
      _provider = provider;
      final models = _modelsForProvider;
      _model = models.any((item) => item.id == model)
          ? model
          : (models.isNotEmpty ? models.first.id : null);
      return;
    }

    _provider = _catalog.providers.isNotEmpty
        ? _catalog.providers.first.provider
        : null;
    _syncModel();
  }

  Future<void> _refresh() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.channel.refreshModels();
      if (!mounted) return;
      final inventory = widget.channel.state.modelInventory;
      if (inventory != null) {
        setState(() => _applyInventory(inventory));
      }
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = AppLocalizations.of(context).modelAssignmentFailed,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _assign() async {
    final slot = _slot;
    final provider = _provider;
    final model = _model;
    if (slot == null || provider == null || model == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.channel.assignModel(
        scope: slot.scope,
        task: slot.task,
        provider: provider,
        model: model,
        revision: _assignment.revision,
      );
      if (mounted) await Navigator.of(context).maybePop();
    } catch (error) {
      if (!mounted) return;
      final strings = AppLocalizations.of(context);
      setState(() {
        _error = error.toString().contains('412')
            ? strings.modelRevisionConflict
            : strings.modelAssignmentFailed;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final models = _modelsForProvider;

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.modelPickerTitle,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : _refresh,
                  icon: const Icon(Icons.refresh),
                  label: Text(strings.refreshCatalogAction),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_catalog.providers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  strings.modelCatalogEmpty,
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
              if (_slots.length > 1) ...[
                DropdownButtonFormField<_SlotOption>(
                  initialValue: _slot,
                  decoration: InputDecoration(
                    labelText: strings.modelSlotLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final slot in _slots)
                      DropdownMenuItem<_SlotOption>(
                        value: slot,
                        child: Text(
                          slot.scope == 'main'
                              ? strings.modelSlotMain
                              : auxiliaryTaskLabel(strings, slot.label),
                        ),
                      ),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) => setState(() {
                          _slot = value;
                          _syncSlotAssignment();
                        }),
                ),
                const SizedBox(height: 16),
              ],
              DropdownButtonFormField<String>(
                initialValue: _provider,
                decoration: InputDecoration(
                  labelText: strings.modelProviderLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final block in _catalog.providers)
                    DropdownMenuItem<String>(
                      value: block.provider,
                      child: Text(block.provider),
                    ),
                ],
                onChanged: _busy
                    ? null
                    : (value) => setState(() {
                        _provider = value;
                        _syncModel();
                      }),
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
                    DropdownMenuItem<String>(
                      value: model.id,
                      child: Text(model.id),
                    ),
                ],
                onChanged: _busy || models.isEmpty
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
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(context).maybePop(),
                  child: Text(strings.cancelAction),
                ),
                FilledButton.icon(
                  onPressed: _busy || _model == null ? null : _assign,
                  icon: const Icon(Icons.check),
                  label: Text(strings.assignModelAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
