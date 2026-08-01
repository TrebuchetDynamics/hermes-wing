import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/models/hermes_skill.dart';
import '../../../core/hermes/models/hermes_toolset.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/wing_empty_state.dart';
import '../../../shared/widgets/wing_skeleton.dart';
import '../../hermes_chat/gateways/hermes_gateway_directory.dart';
import '../../hermes_chat/providers/hermes_channel_provider.dart';

/// Read-only inventory for the optional `/v1/skills` and `/v1/toolsets`
/// surfaces. Mutating skills, toolsets, or MCP servers remains hidden until a
/// selected gateway advertises dedicated scoped administration contracts.
class ToolsScreen extends ConsumerStatefulWidget {
  const ToolsScreen({super.key});

  @override
  ConsumerState<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends ConsumerState<ToolsScreen> {
  String? _switchingGatewayId;
  String? _actionError;

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(hermesChannelProvider);
    final directory = ref.watch(hermesGatewayDirectoryProvider);
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.toolsTitle)),
      body: AnimatedBuilder(
        animation: Listenable.merge([channel, directory]),
        builder: (context, _) => Column(
          children: [
            if (directory.gateways.isNotEmpty)
              _buildGatewayPicker(directory, strings),
            if (_actionError != null)
              MaterialBanner(
                content: Text(_actionError!),
                actions: [
                  TextButton(
                    onPressed: () => setState(() => _actionError = null),
                    child: Text(strings.doneAction),
                  ),
                ],
              ),
            Expanded(
              child: _ToolsBody(state: channel.state, strings: strings),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGatewayPicker(
    HermesGatewayDirectory directory,
    AppLocalizations strings,
  ) {
    final selectedId = directory.activeContactId?.gatewayId;
    final selected =
        directory.gateways.any((gateway) => gateway.id == selectedId)
        ? selectedId
        : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            key: const ValueKey('tools-gateway-picker'),
            initialValue: selected,
            decoration: InputDecoration(
              labelText: strings.gatewayLabel,
              border: const OutlineInputBorder(),
            ),
            hint: Text(strings.selectGatewayHint),
            items: [
              for (final gateway in directory.gateways)
                DropdownMenuItem(value: gateway.id, child: Text(gateway.label)),
            ],
            onChanged: _switchingGatewayId == null
                ? (gatewayId) {
                    if (gatewayId != null && gatewayId != selected) {
                      unawaited(_selectGateway(directory, gatewayId, strings));
                    }
                  }
                : null,
          ),
          const SizedBox(height: 6),
          Text(strings.toolsGatewayHelp),
        ],
      ),
    );
  }

  Future<void> _selectGateway(
    HermesGatewayDirectory directory,
    String gatewayId,
    AppLocalizations strings,
  ) async {
    setState(() {
      _switchingGatewayId = gatewayId;
      _actionError = null;
    });
    try {
      await directory.activateGateway(gatewayId);
    } catch (_) {
      if (mounted) setState(() => _actionError = strings.gatewayConnectFailed);
    } finally {
      if (mounted) setState(() => _switchingGatewayId = null);
    }
  }
}

class _ToolsBody extends StatelessWidget {
  const _ToolsBody({required this.state, required this.strings});

  final HermesChannelState state;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    if (state.status == HermesConnectionStatus.connecting) {
      return WingSkeletonList(
        semanticLabel: AppLocalizations.of(context).toolsLoading,
      );
    }
    if (state.status != HermesConnectionStatus.connected) {
      if (state.status == HermesConnectionStatus.error) {
        return WingEmptyState(
          icon: Icons.cloud_off_outlined,
          title: strings.toolsUnavailableTitle,
          body: strings.toolsConnectionErrorBody,
        );
      }
      return WingEmptyState(
        icon: Icons.hub_outlined,
        title: strings.gatewaySelectPromptTitle,
        body: strings.toolsConnectionRequiredBody,
      );
    }

    final skillsAdvertised = state.canReadSkills;
    final toolsetsAdvertised = state.canReadToolsets;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        _SkillsInventorySection(
          advertised: skillsAdvertised,
          loadFailed: state.optionalResourceErrors.containsKey(
            HermesOptionalResource.skills,
          ),
          details: state.skillDetails,
          fallbackNames: state.skills,
          strings: strings,
        ),
        const SizedBox(height: 16),
        _ToolsetsInventorySection(
          advertised: toolsetsAdvertised,
          loadFailed: state.optionalResourceErrors.containsKey(
            HermesOptionalResource.toolsets,
          ),
          details: state.toolsets,
          fallbackNames: state.enabledToolsets,
          strings: strings,
        ),
      ],
    );
  }
}

class _SkillsInventorySection extends StatefulWidget {
  const _SkillsInventorySection({
    required this.advertised,
    required this.loadFailed,
    required this.details,
    required this.fallbackNames,
    required this.strings,
  });

  final bool advertised;
  final bool loadFailed;
  final List<HermesSkill> details;
  final List<String> fallbackNames;
  final AppLocalizations strings;

  @override
  State<_SkillsInventorySection> createState() =>
      _SkillsInventorySectionState();
}

class _SkillsInventorySectionState extends State<_SkillsInventorySection> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void didUpdateWidget(covariant _SkillsInventorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.details, widget.details) ||
        !listEquals(oldWidget.fallbackNames, widget.fallbackNames)) {
      _searchController.clear();
      _query = '';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final details = [...widget.details]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final fallbackNames = [...widget.fallbackNames]
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final message = !widget.advertised
        ? widget.strings.skillsUnavailableBody
        : widget.loadFailed
        ? widget.strings.skillsLoadFailedBody
        : details.isEmpty && fallbackNames.isEmpty
        ? widget.strings.skillsEmptyBody
        : null;
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = normalizedQuery.isEmpty
        ? details
        : details
              .where(
                (skill) =>
                    skill.name.toLowerCase().contains(normalizedQuery) ||
                    skill.description.toLowerCase().contains(normalizedQuery) ||
                    skill.category.toLowerCase().contains(normalizedQuery),
              )
              .toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.extension_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.strings.installedSkillsTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (message != null)
              Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else if (details.isEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final name in fallbackNames) Chip(label: Text(name)),
                ],
              )
            else ...[
              TextField(
                key: const ValueKey('installed-skills-search'),
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: widget.strings.searchInstalledSkillsLabel,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 8),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(widget.strings.noSkillsMatchBody),
                )
              else
                for (final skill in filtered)
                  ListTile(
                    key: ValueKey('installed-skill-${skill.name}'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(skill.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (skill.description.isNotEmpty)
                          Text(skill.description),
                        if (skill.category.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            skill.category,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToolsetsInventorySection extends StatefulWidget {
  const _ToolsetsInventorySection({
    required this.advertised,
    required this.loadFailed,
    required this.details,
    required this.fallbackNames,
    required this.strings,
  });

  final bool advertised;
  final bool loadFailed;
  final List<HermesToolset> details;
  final List<String> fallbackNames;
  final AppLocalizations strings;

  @override
  State<_ToolsetsInventorySection> createState() =>
      _ToolsetsInventorySectionState();
}

class _ToolsetsInventorySectionState extends State<_ToolsetsInventorySection> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void didUpdateWidget(covariant _ToolsetsInventorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.details, widget.details) ||
        !identical(oldWidget.fallbackNames, widget.fallbackNames)) {
      _searchController.clear();
      _query = '';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final details = [...widget.details]
      ..sort(
        (left, right) => left.displayName.toLowerCase().compareTo(
          right.displayName.toLowerCase(),
        ),
      );
    final fallbackNames = [
      ...widget.fallbackNames,
    ]..sort((left, right) => left.toLowerCase().compareTo(right.toLowerCase()));
    final message = !widget.advertised
        ? widget.strings.toolsetsUnavailableBody
        : widget.loadFailed
        ? widget.strings.toolsetsLoadFailedBody
        : details.isEmpty && fallbackNames.isEmpty
        ? widget.strings.toolsetsCatalogEmptyBody
        : null;
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? details
        : details
              .where(
                (toolset) => [
                  toolset.name,
                  toolset.label,
                  toolset.description,
                  ...toolset.tools,
                ].any((value) => value.toLowerCase().contains(query)),
              )
              .toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.build_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    details.isEmpty
                        ? widget.strings.enabledToolsetsTitle
                        : widget.strings.toolsetsTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (message != null)
              Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else if (details.isEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final name in fallbackNames) Chip(label: Text(name)),
                ],
              )
            else ...[
              TextField(
                key: const ValueKey('toolsets-search'),
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: widget.strings.searchToolsetsLabel,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 8),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(widget.strings.noToolsetsMatchBody),
                )
              else
                for (final toolset in filtered)
                  _ToolsetTile(toolset: toolset, strings: widget.strings),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToolsetTile extends StatelessWidget {
  const _ToolsetTile({required this.toolset, required this.strings});

  final HermesToolset toolset;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final status = [
      toolset.enabled ? strings.toolsetEnabled : strings.toolsetDisabled,
      toolset.configured
          ? strings.toolsetConfigured
          : strings.toolsetNotConfigured,
      strings.toolsetResolvedToolsCount(toolset.tools.length),
    ].join(' · ');
    final subtitle = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (toolset.label.isNotEmpty && toolset.label != toolset.name)
          Text(toolset.name),
        if (toolset.description.isNotEmpty) Text(toolset.description),
        const SizedBox(height: 4),
        Text(status, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
    if (toolset.tools.isEmpty) {
      return ListTile(
        key: ValueKey('toolset-${toolset.name}'),
        contentPadding: EdgeInsets.zero,
        title: Text(toolset.displayName),
        subtitle: subtitle,
      );
    }
    return ExpansionTile(
      key: ValueKey('toolset-${toolset.name}'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      title: Text(toolset.displayName),
      subtitle: subtitle,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            strings.toolsetResolvedToolsTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tool in toolset.tools) Chip(label: Text(tool)),
            ],
          ),
        ),
      ],
    );
  }
}
