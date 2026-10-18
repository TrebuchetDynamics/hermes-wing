import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/models/hermes_skill.dart';
import '../../../core/hermes/models/hermes_toolset.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/wing_empty_state.dart';
import '../../../shared/widgets/wing_gateway_picker.dart';
import '../../../shared/widgets/wing_gateway_switch.dart';
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
  bool _refreshing = false;
  int _refreshGeneration = 0;
  HermesChannel? _inventoryChannel;
  Object? _inventoryContext;
  Object _inventoryOwner = Object();
  Object? _presentationContext;
  Object _presentationOwner = Object();
  Object _skillsOwner = Object();
  Object _toolsetsOwner = Object();
  bool? _skillsReadable;
  bool? _toolsetsReadable;

  @override
  void dispose() {
    _inventoryChannel?.removeListener(_inventoryOwnerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(hermesChannelProvider);
    _bindInventoryOwner(channel);
    ref.listen(hermesChannelProvider, (previous, next) {
      if (!identical(previous, next)) {
        setState(() => _bindInventoryOwner(next));
      }
    });
    final directory = ref.watch(hermesGatewayDirectoryProvider);
    final strings = AppLocalizations.of(context);
    final state = channel.state;
    final owner = _inventoryOwner;
    final canRefresh = _canRefreshInventory(state);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.toolsTitle),
        actions: [
          if (canRefresh)
            IconButton(
              key: const ValueKey('tools-refresh'),
              tooltip: strings.toolsRefreshAction,
              onPressed: _refreshing
                  ? null
                  : () => unawaited(_refreshInventory(channel, owner, strings)),
              icon: _refreshing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          const AppShellMenuButton(),
        ],
      ),
      body: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: Listenable.merge([channel, directory]),
          builder: (context, _) => Column(
            children: [
              if (directory.gateways.isNotEmpty)
                WingGatewayPicker(
                  fieldKey: const ValueKey('tools-gateway-picker'),
                  directory: directory,
                  helpText: strings.toolsGatewayHelp,
                  enabled: _switchingGatewayId == null,
                  onSelected: (id) =>
                      unawaited(_selectGateway(directory, id, strings)),
                ),
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
                // Search and disclosure belong to this client/host/profile,
                // not to inventory content or capability-document identity.
                child: _ToolsBody(
                  key: ValueKey(_presentationOwner),
                  skillsOwner: _skillsOwner,
                  toolsetsOwner: _toolsetsOwner,
                  state: channel.state,
                  strings: strings,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshInventory(
    HermesChannel channel,
    Object owner,
    AppLocalizations strings,
  ) async {
    if (!_isInventoryOwner(channel, owner) || _refreshing) return;
    final generation = ++_refreshGeneration;
    setState(() {
      _refreshing = true;
      _actionError = null;
    });
    try {
      await channel.loadToolInventory();
    } catch (_) {
      if (_isInventoryOwner(channel, owner) &&
          generation == _refreshGeneration) {
        setState(() => _actionError = strings.toolsRefreshFailed);
      }
    } finally {
      if (_isInventoryOwner(channel, owner) &&
          generation == _refreshGeneration) {
        setState(() => _refreshing = false);
      }
    }
  }

  Future<void> _selectGateway(
    HermesGatewayDirectory directory,
    String gatewayId,
    AppLocalizations strings,
  ) async {
    setState(() {
      _switchingGatewayId = gatewayId;
      _refreshGeneration++;
      _refreshing = false;
      _actionError = null;
    });
    await completeWingGatewaySwitch(
      context: context,
      directory: directory,
      gatewayId: gatewayId,
      onFailure: () =>
          setState(() => _actionError = strings.gatewayConnectFailed),
      onFinished: () => setState(() => _switchingGatewayId = null),
    );
  }

  bool _canRefreshInventory(HermesChannelState state) =>
      state.isConnected &&
      !state.isSelectingProfile &&
      (state.canReadSkills || state.canReadToolsets);

  void _bindInventoryOwner(HermesChannel channel) {
    if (!identical(channel, _inventoryChannel)) {
      _inventoryChannel?.removeListener(_inventoryOwnerChanged);
      _inventoryChannel = channel;
      _inventoryContext = null;
      channel.addListener(_inventoryOwnerChanged);
    }
    _syncInventoryOwner();
  }

  bool _syncInventoryOwner() {
    final channel = _inventoryChannel!;
    final state = channel.state;
    final context = (
      channel,
      state.connectedBaseUrl,
      state.selectedProfileId,
      state.status,
      state.isSelectingProfile,
      state.canReadSkills,
      state.canReadToolsets,
    );
    final presentationContext = (
      channel,
      state.connectedBaseUrl,
      state.selectedProfileId,
      state.status,
      state.isSelectingProfile,
    );
    if (_presentationContext != presentationContext) {
      _presentationContext = presentationContext;
      _presentationOwner = Object();
    }
    if (_skillsReadable != state.canReadSkills) {
      _skillsReadable = state.canReadSkills;
      _skillsOwner = Object();
    }
    if (_toolsetsReadable != state.canReadToolsets) {
      _toolsetsReadable = state.canReadToolsets;
      _toolsetsOwner = Object();
    }
    if (_inventoryContext == context) return false;
    _inventoryContext = context;
    _inventoryOwner = Object();
    _refreshGeneration++;
    _refreshing = false;
    _actionError = null;
    return true;
  }

  void _inventoryOwnerChanged() {
    // Invalidate cached controls even when loss/restoration precedes a frame.
    if (_syncInventoryOwner() && mounted) setState(() {});
  }

  bool _isInventoryOwner(HermesChannel channel, Object owner) {
    if (!mounted) return false;
    final current = ref.read(hermesChannelProvider);
    _bindInventoryOwner(current);
    return identical(channel, current) &&
        identical(owner, _inventoryOwner) &&
        _canRefreshInventory(current.state);
  }
}

class _ToolsBody extends StatelessWidget {
  const _ToolsBody({
    super.key,
    required this.state,
    required this.strings,
    required this.skillsOwner,
    required this.toolsetsOwner,
  });

  final Object skillsOwner;
  final Object toolsetsOwner;

  final HermesChannelState state;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    if (state.status == HermesConnectionStatus.connecting ||
        state.isSelectingProfile) {
      return WingSkeletonList(
        semanticLabel: AppLocalizations.of(context).toolsLoading,
      );
    }
    if (state.status != HermesConnectionStatus.connected) {
      if (state.status == HermesConnectionStatus.error) {
        return WingEmptyState(
          icon: Icons.cloud_off_outlined,
          liveRegion: true,
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

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(
                key: const ValueKey('tools-tab-skills'),
                text: strings.chatStatusSkillsLabel,
              ),
              Tab(
                key: const ValueKey('tools-tab-toolsets'),
                text: strings.toolsetsTitle,
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _SkillsInventorySection(
                  key: ValueKey(skillsOwner),
                  advertised: skillsAdvertised,
                  loadFailed: state.optionalResourceErrors.containsKey(
                    HermesOptionalResource.skills,
                  ),
                  details: state.skillDetails,
                  fallbackNames: state.skills,
                  strings: strings,
                ),
                _ToolsetsInventorySection(
                  key: ValueKey(toolsetsOwner),
                  advertised: toolsetsAdvertised,
                  loadFailed: state.optionalResourceErrors.containsKey(
                    HermesOptionalResource.toolsets,
                  ),
                  details: state.toolsets,
                  fallbackNames: state.enabledToolsets,
                  strings: strings,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillsInventorySection extends StatefulWidget {
  const _SkillsInventorySection({
    super.key,
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

class _SkillsInventorySectionState extends State<_SkillsInventorySection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.strings.installedSkillsTitle,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                // Keep the editor's semantic owner stable when filtering removes
                // every result; result text must not merge into its input label.
                Semantics(
                  container: true,
                  child: TextField(
                    key: const ValueKey('installed-skills-search'),
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: widget.strings.searchInstalledSkillsLabel,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              key: const ValueKey('installed-skills-clear'),
                              tooltip:
                                  widget.strings.clearInstalledSkillsSearch,
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.clear),
                            ),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                const SizedBox(height: 8),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Semantics(
                      container: true,
                      child: Text(widget.strings.noSkillsMatchBody),
                    ),
                  )
                else
                  for (var index = 0; index < filtered.length; index++)
                    Semantics(
                      container: true,
                      child: ListTile(
                        key: ValueKey(
                          'installed-skill-${filtered[index].name}-$index',
                        ),
                        contentPadding: EdgeInsets.zero,
                        title: Text(filtered[index].name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (filtered[index].description.isNotEmpty)
                              Text(filtered[index].description),
                            if (filtered[index].category.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                filtered[index].category,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolsetsInventorySection extends StatefulWidget {
  const _ToolsetsInventorySection({
    super.key,
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

class _ToolsetsInventorySectionState extends State<_ToolsetsInventorySection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final _expanded = <String>{};
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: details.isEmpty
          ? widget.strings.enabledToolsetsTitle
          : widget.strings.toolsetsTitle,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                Semantics(
                  container: true,
                  child: TextField(
                    key: const ValueKey('toolsets-search'),
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: widget.strings.searchToolsetsLabel,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              key: const ValueKey('toolsets-clear'),
                              tooltip: widget.strings.clearToolsetsSearch,
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.clear),
                            ),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                const SizedBox(height: 8),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Semantics(
                      container: true,
                      child: Text(widget.strings.noToolsetsMatchBody),
                    ),
                  )
                else
                  for (var index = 0; index < filtered.length; index++)
                    Semantics(
                      container: true,
                      child: _ToolsetTile(
                        key: ValueKey((filtered[index].name, index)),
                        toolset: filtered[index],
                        expanded: _expanded.contains(filtered[index].name),
                        onExpansionChanged: (value) {
                          if (value) {
                            _expanded.add(filtered[index].name);
                          } else {
                            _expanded.remove(filtered[index].name);
                          }
                        },
                        index: index,
                        strings: widget.strings,
                      ),
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolsetTile extends StatelessWidget {
  const _ToolsetTile({
    super.key,
    required this.expanded,
    required this.onExpansionChanged,
    required this.toolset,
    required this.index,
    required this.strings,
  });

  final bool expanded;
  final ValueChanged<bool> onExpansionChanged;
  final HermesToolset toolset;
  final int index;
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
        key: ValueKey('toolset-${toolset.name}-$index'),
        contentPadding: EdgeInsets.zero,
        title: Text(toolset.displayName),
        subtitle: subtitle,
      );
    }
    return ExpansionTile(
      key: ValueKey(('toolset-${toolset.name}-$index', expanded)),
      initiallyExpanded: expanded,
      onExpansionChanged: onExpansionChanged,
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
