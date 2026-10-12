import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/models/hermes_capabilities.dart';

import '../../../l10n/app_localizations.dart';
import '../../../router/routes/app_routes.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/wing_empty_state.dart';
import '../../../shared/widgets/wing_metadata.dart';
import '../../../shared/widgets/wing_gateway_picker.dart';
import '../../../shared/widgets/wing_skeleton.dart';
import '../../hermes_chat/gateways/hermes_gateway_directory.dart';
import '../../hermes_chat/providers/hermes_channel_provider.dart';
import '../providers/profile_selection_provider.dart';
import '../widgets/profile_editor_sheet.dart';

class ProfilesScreen extends ConsumerStatefulWidget {
  const ProfilesScreen({super.key, this.startSetup = false});

  final bool startSetup;

  @override
  ConsumerState<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends ConsumerState<ProfilesScreen> {
  late HermesGatewayDirectory _directory;
  late HermesChannel _channel;
  Object? _searchSource;
  Object _searchOwner = Object();
  Object? _connectionSource;
  Object _connectionOwner = Object();
  final _editorSourceChanges = ValueNotifier<Object>(Object());
  bool _sourceCheckScheduled = false;
  bool _setupOpened = false;
  String? _actionError;
  String? _switchingGatewayId;
  String? _switchingProfileId;
  bool _chatRouteOpen = false;

  @override
  void initState() {
    super.initState();
    _directory = ref.read(hermesGatewayDirectoryProvider);
    _channel = ref.read(hermesChannelProvider);
    _directory.addListener(_scheduleProfileSourceCheck);
    _channel.addListener(_scheduleProfileSourceCheck);
    _scheduleProfileSourceCheck();
  }

  @override
  void dispose() {
    _directory.removeListener(_scheduleProfileSourceCheck);
    _channel.removeListener(_scheduleProfileSourceCheck);
    _editorSourceChanges.dispose();
    super.dispose();
  }

  Object get _currentConnectionSource {
    final gateway = _directory.managementGatewayId;
    final config = gateway == null
        ? null
        : _directory.configForGateway(gateway);
    final state = _channel.state;
    return (
      gateway,
      config?.baseUrl,
      config?.apiKey,
      state.connectedBaseUrl,
      state.isConnected,
      _directory.activeContactId?.gatewayId,
    );
  }

  Object get _currentProfileSource {
    final state = _channel.state;
    return (
      _currentConnectionSource,
      _canReadProfiles(state.capabilities),
      state.canReadModelOptions,
      state.canEditProfileSoul,
      _canMutateProfile('profile_create', 'POST', '/api/profiles'),
      _canMutateProfile('profile_update', 'PATCH', '/api/profiles/{name}'),
      _canMutateProfile('profile_delete', 'DELETE', '/api/profiles/{name}'),
    );
  }

  bool _canMutateProfile(String name, String method, String path) =>
      _canUseEndpoint(
        _channel.state.capabilities,
        scope: 'profiles:write',
        name: name,
        method: method,
        path: path,
      );

  void _scheduleProfileSourceCheck() {
    _profileSearchKey();
    if (_sourceCheckScheduled) return;
    _sourceCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sourceCheckScheduled = false;
      if (mounted) setState(() {});
    });
  }

  Key _profileSearchKey() {
    // Compare credentials privately, never place them or an endpoint in UI keys.
    // Observe every notification, including A -> B -> A before the next frame.
    final connection = (_directory, _channel, _currentConnectionSource);
    if (_connectionSource != connection) {
      _connectionSource = connection;
      _connectionOwner = Object();
    }
    final source = (_directory, _channel, _currentProfileSource);
    if (_searchSource != source) {
      _searchSource = source;
      _searchOwner = Object();
      _actionError = null;
      _editorSourceChanges.value = _searchOwner;
    }
    return ObjectKey(_searchOwner);
  }

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(hermesChannelProvider);
    final directory = ref.watch(hermesGatewayDirectoryProvider);
    ref.listen(hermesChannelProvider, (previous, next) {
      if (identical(previous, next)) return;
      _channel.removeListener(_scheduleProfileSourceCheck);
      _channel = next;
      _channel.addListener(_scheduleProfileSourceCheck);
      _scheduleProfileSourceCheck();
    });
    ref.listen(hermesGatewayDirectoryProvider, (previous, next) {
      if (identical(previous, next)) return;
      _directory.removeListener(_scheduleProfileSourceCheck);
      _directory = next;
      _directory.addListener(_scheduleProfileSourceCheck);
      _scheduleProfileSourceCheck();
    });
    final strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.agentsTitle),
        actions: const [AppShellMenuButton()],
      ),
      body: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: Listenable.merge([channel, directory]),
          builder: (context, _) => Column(
            children: [
              if (directory.gateways.isNotEmpty)
                WingGatewayPicker(
                  fieldKey: const ValueKey('agents-gateway-picker'),
                  directory: directory,
                  selectedGatewayId: directory.managementGatewayId,
                  helpText: AppLocalizations.of(
                    context,
                  ).agentsGatewayPickerHelp,
                  enabled: _switchingGatewayId == null,
                  onSelected: (id) => unawaited(_selectGateway(directory, id)),
                ),
              if (_actionError != null)
                MaterialBanner(
                  content: Semantics(
                    liveRegion: true,
                    child: Text(_actionError!),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => setState(() => _actionError = null),
                      child: Text(strings.doneAction),
                    ),
                  ],
                ),
              Expanded(
                child: _ProfilesSearch(
                  key: _profileSearchKey(),
                  strings: strings,
                  builder: (query, search) => _buildBody(
                    context,
                    channel,
                    directory,
                    strings,
                    query,
                    search,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    HermesChannel channel,
    HermesGatewayDirectory directory,
    AppLocalizations strings,
    String query,
    Widget search,
  ) {
    final state = channel.state;
    final activeGatewayId = directory.managementGatewayId;
    final selectedAgent =
        directory.activeContactId?.gatewayId == activeGatewayId;
    final capabilities = selectedAgent ? state.capabilities : null;
    if (selectedAgent && state.status == HermesConnectionStatus.connecting) {
      return WingSkeletonList(semanticLabel: strings.agentsLoading);
    }
    if (selectedAgent && state.status == HermesConnectionStatus.error) {
      return WingEmptyState(
        icon: Icons.cloud_off_outlined,
        liveRegion: true,
        title: strings.agentsConnectionError,
        body: strings.gatewayConnectionRecoveryBody,
        actionLabel: strings.openChatAction,
        onAction: () => context.go(AppRoutes.hermes),
      );
    }
    if (!selectedAgent || state.status != HermesConnectionStatus.connected) {
      return WingEmptyState(
        icon: Icons.hub_outlined,
        title: strings.gatewaySelectPromptTitle,
        body: strings.agentsConnectionRequiredBody,
        actionLabel: activeGatewayId == null
            ? null
            : strings.gatewayChatConnectAction,
        onAction: activeGatewayId == null || _switchingGatewayId != null
            ? null
            : () => unawaited(_selectGateway(directory, activeGatewayId)),
      );
    }
    if (!_canReadProfiles(capabilities)) {
      return WingEmptyState(
        icon: Icons.lock_outline,
        title: strings.agentsUnavailableTitle,
        body: strings.agentsUnavailableBody,
      );
    }

    final mutationOwner = _searchOwner;
    bool currentMutationOwner() {
      if (!mounted ||
          !identical(directory, ref.read(hermesGatewayDirectoryProvider)) ||
          !identical(channel, ref.read(hermesChannelProvider))) {
        return false;
      }
      _profileSearchKey();
      return identical(mutationOwner, _searchOwner);
    }

    final profiles = state.profiles;
    final visibleProfiles = profiles
        .where(
          (profile) => [
            profile.id,
            profile.displayName,
            profile.description,
            profile.model,
          ].any((value) => value.toLowerCase().contains(query)),
        )
        .toList();
    final canCreate = _canUseEndpoint(
      capabilities,
      scope: 'profiles:write',
      name: 'profile_create',
      method: 'POST',
      path: '/api/profiles',
    );
    final selectedId = effectiveSelectedProfileId(state);
    Future<void> openCreate() => _openEditor(
      channel: channel,
      profiles: profiles,
      isMutationOwnerCurrent: currentMutationOwner,
    );
    if (widget.startSetup && !_setupOpened && canCreate) {
      _setupOpened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (currentMutationOwner()) unawaited(openCreate());
      });
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _ProfilesHeader(
          subtitle: strings.agentsSubtitle,
          readOnly: !(capabilities?.auth.allows('profiles:write') ?? false),
          readOnlyLabel: strings.readOnlyAccess,
          action: canCreate
              ? FilledButton.icon(
                  onPressed: openCreate,
                  icon: const Icon(Icons.add),
                  label: Text(strings.newAgent),
                )
              : null,
        ),
        const SizedBox(height: 16),
        search,
        const SizedBox(height: 8),
        Text(strings.profilesSearchHelp),
        const SizedBox(height: 16),
        if (profiles.isEmpty)
          WingEmptyState(
            icon: Icons.support_agent_outlined,
            title: strings.agentsEmptyTitle,
            body: strings.agentsEmptyBody,
          )
        else if (visibleProfiles.isEmpty)
          WingEmptyState(
            icon: Icons.search_off,
            liveRegion: true,
            title: strings.profilesSearchNoMatchesTitle,
            body: strings.profilesSearchNoMatchesBody,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900 ? 2 : 1;
              final gap = 12.0;
              final cardWidth = columns == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - gap) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (var index = 0; index < profiles.length; index++)
                    if (visibleProfiles.contains(profiles[index]))
                      SizedBox(
                        width: cardWidth,
                        child: _ProfileCard(
                          profile: profiles[index],
                          selected: profiles[index].id == selectedId,
                          canEdit: _canUseEndpoint(
                            capabilities,
                            scope: 'profiles:write',
                            name: 'profile_update',
                            method: 'PATCH',
                            path: '/api/profiles/{name}',
                          ),
                          canDelete:
                              profiles[index].id != 'default' &&
                              _canUseEndpoint(
                                capabilities,
                                scope: 'profiles:write',
                                name: 'profile_delete',
                                method: 'DELETE',
                                path: '/api/profiles/{name}',
                              ),
                          strings: strings,
                          switching: _switchingProfileId == profiles[index].id,
                          onChat: _switchingProfileId == null
                              ? () => _selectProfile(channel, profiles[index])
                              : null,
                          onEdit: () => _openEditor(
                            isMutationOwnerCurrent: currentMutationOwner,
                            channel: channel,
                            profiles: profiles,
                            profile: profiles[index],
                            canEditSoul: state.canEditProfileSoul,
                            canDelete:
                                profiles[index].id != 'default' &&
                                _canUseEndpoint(
                                  capabilities,
                                  scope: 'profiles:write',
                                  name: 'profile_delete',
                                  method: 'DELETE',
                                  path: '/api/profiles/{name}',
                                ),
                          ),
                          onDelete: () => _openEditor(
                            isMutationOwnerCurrent: currentMutationOwner,
                            channel: channel,
                            profiles: profiles,
                            profile: profiles[index],
                            canDelete: true,
                          ),
                        ),
                      ),
                ],
              );
            },
          ),
      ],
    );
  }

  Future<void> _selectGateway(
    HermesGatewayDirectory directory,
    String gatewayId,
  ) async {
    setState(() {
      _switchingGatewayId = gatewayId;
      _actionError = null;
    });
    try {
      directory.selectManagementGateway(gatewayId);
      await directory.activateGateway(gatewayId);
    } catch (_) {
      if (mounted) {
        setState(
          () => _actionError = AppLocalizations.of(
            context,
          ).agentsGatewayConnectError,
        );
      }
    } finally {
      if (mounted) setState(() => _switchingGatewayId = null);
    }
  }

  Future<void> _openEditor({
    required HermesChannel channel,
    required List<HermesProfile> profiles,
    HermesProfile? profile,
    bool canEditSoul = false,
    bool canDelete = false,
    bool Function()? isMutationOwnerCurrent,
  }) async {
    if (!(isMutationOwnerCurrent?.call() ?? true)) return;
    _profileSearchKey();
    final editorOwner = _searchOwner;
    bool currentOwner() {
      if (!mounted ||
          !identical(channel, ref.read(hermesChannelProvider)) ||
          !(isMutationOwnerCurrent?.call() ?? true)) {
        return false;
      }
      _profileSearchKey();
      return identical(editorOwner, _searchOwner) &&
          identical(channel, _channel);
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => ProfileEditorSheet(
        channel: channel,
        profiles: profiles,
        profile: profile,
        canEditSoul: canEditSoul,
        ownerChanges: _editorSourceChanges,
        isOwnerCurrent: currentOwner,
        canDelete: canDelete,
      ),
    );
    // Channel mutations reconcile Agent profiles with connection fencing.
  }

  Future<void> _selectProfile(
    HermesChannel channel,
    HermesProfile profile,
  ) async {
    final profileId = profile.id;
    if (_switchingProfileId != null) return;
    final directory = ref.read(hermesGatewayDirectoryProvider);
    _profileSearchKey();
    final owner = _connectionOwner;
    bool currentOwner() {
      if (!mounted ||
          !identical(channel, ref.read(hermesChannelProvider)) ||
          !identical(directory, ref.read(hermesGatewayDirectoryProvider))) {
        return false;
      }
      _profileSearchKey();
      return identical(owner, _connectionOwner);
    }

    setState(() {
      _switchingProfileId = profileId;
      _actionError = null;
    });
    try {
      if (directory.activeContactId == null) {
        await channel.selectProfile(profileId);
      } else {
        await directory.selectProfileOnActiveGateway(
          profileId,
          discoveredProfile: profile,
        );
      }
      if (currentOwner() && channel.state.selectedProfileId == profileId) {
        unawaited(_openChat());
      }
    } catch (_) {
      if (currentOwner()) {
        setState(() {
          _actionError = AppLocalizations.of(context).profileOperationFailed;
        });
      }
    } finally {
      if (mounted && _switchingProfileId == profileId) {
        setState(() => _switchingProfileId = null);
      }
    }
  }

  Future<void> _openChat() async {
    if (_chatRouteOpen) return;
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    setState(() => _chatRouteOpen = true);
    try {
      await router.push<void>(AppRoutes.hermes);
    } finally {
      if (mounted) setState(() => _chatRouteOpen = false);
    }
  }
}

bool _canReadProfiles(HermesCapabilityDocument? capabilities) =>
    _canUseEndpoint(
      capabilities,
      scope: 'profiles:read',
      name: 'profiles',
      method: 'GET',
      path: '/api/profiles',
    );

bool _canUseEndpoint(
  HermesCapabilityDocument? capabilities, {
  required String scope,
  required String name,
  required String method,
  required String path,
}) =>
    capabilities != null &&
    capabilities.supportsSchema &&
    capabilities.auth.allows(scope) &&
    capabilities.advertisesScopedEndpoint(name, method, path, scope) &&
    (!capabilities.endpoints[name]!.profileScoped ||
        capabilities.profileContext.isSupportedQueryContext) &&
    capabilities.endpoints[name]!.requiredScopes.every(
      capabilities.auth.allows,
    );

class _ProfilesSearch extends StatefulWidget {
  const _ProfilesSearch({
    super.key,
    required this.strings,
    required this.builder,
  });

  final AppLocalizations strings;
  final Widget Function(String query, Widget search) builder;

  @override
  State<_ProfilesSearch> createState() => _ProfilesSearchState();
}

class _ProfilesSearchState extends State<_ProfilesSearch> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(
    _controller.text.toLowerCase(),
    Semantics(
      container: true,
      explicitChildNodes: true,
      child: TextField(
        key: const ValueKey('profiles-search'),
        controller: _controller,
        decoration: InputDecoration(
          labelText: widget.strings.profilesSearchLabel,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: widget.strings.profilesSearchClear,
                  onPressed: () => setState(_controller.clear),
                  icon: const Icon(Icons.clear),
                ),
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() {}),
      ),
    ),
  );
}

class _ProfilesHeader extends StatelessWidget {
  const _ProfilesHeader({
    required this.subtitle,
    required this.readOnly,
    required this.readOnlyLabel,
    this.action,
  });

  final String subtitle;
  final bool readOnly;
  final String readOnlyLabel;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (readOnly) ...[
                const SizedBox(height: 10),
                WingMetadata(
                  avatar: const Icon(Icons.visibility_outlined, size: 18),
                  label: Text(readOnlyLabel),
                ),
              ],
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.selected,
    required this.canEdit,
    required this.canDelete,
    required this.strings,
    required this.switching,
    required this.onChat,
    required this.onEdit,
    required this.onDelete,
  });

  final HermesProfile profile;
  final bool selected;
  final bool canEdit;
  final bool canDelete;
  final AppLocalizations strings;
  final bool switching;
  final VoidCallback? onChat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = profile.displayName.isEmpty
        ? profile.id
        : profile.displayName;
    final semanticsLabel = [
      displayName,
      strings.agentStableId(profile.id),
      if (selected) strings.profileActiveChat,
      if (profile.id == 'default') strings.defaultAgent,
    ].join(', ');

    final inlineChat =
        MediaQuery.sizeOf(context).width >= 360 &&
        MediaQuery.textScalerOf(context).scale(1) <= 1.3;
    final chatAction = Semantics(
      container: true,
      button: true,
      label: strings.chatWithNamedAgent(displayName),
      onTap: onChat,
      child: ExcludeSemantics(
        child: FilledButton.tonalIcon(
          key: ValueKey('agent-chat-${profile.id}'),
          onPressed: onChat,
          icon: switching
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chat_bubble_outline),
          label: Text(
            switching ? strings.switchingAgent : strings.chatWithAgent,
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      selected: selected,
      label: semanticsLabel,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    child: Text(
                      displayName.characters.first.toUpperCase(),
                      semanticsLabel: '',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 3),
                        Text(
                          strings.agentStableId(profile.id),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (inlineChat) ...[const SizedBox(width: 12), chatAction],
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  if (selected)
                    WingMetadata(
                      avatar: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(strings.profileActiveChat),
                    ),
                  if (profile.id == 'default')
                    WingMetadata(label: Text(strings.defaultAgent)),
                  WingMetadata(
                    avatar: const Icon(Icons.psychology_outlined, size: 14),
                    label: Text(
                      profile.model.isEmpty
                          ? strings.agentNoModel
                          : profile.model,
                    ),
                  ),
                  WingMetadata(
                    avatar: const Icon(Icons.extension_outlined, size: 14),
                    label: Text(strings.agentSkillsCount(profile.skillsCount)),
                  ),
                  WingMetadata(
                    avatar: Icon(
                      profile.gatewayRunning
                          ? Icons.check_circle_outline
                          : Icons.pause_circle_outline,
                      size: 18,
                    ),
                    label: Text(
                      profile.gatewayRunning
                          ? strings.agentGatewayRunning
                          : strings.agentGatewayOff,
                    ),
                  ),
                ],
              ),
              if (profile.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(profile.description),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (!inlineChat) chatAction,
                  if (canEdit)
                    Semantics(
                      container: true,
                      button: true,
                      label: strings.editNamedAgent(displayName),
                      onTap: onEdit,
                      child: ExcludeSemantics(
                        child: OutlinedButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(strings.editAgent),
                        ),
                      ),
                    ),
                  if (canDelete)
                    Semantics(
                      container: true,
                      button: true,
                      label: strings.deleteNamedAgent(displayName),
                      onTap: onDelete,
                      child: ExcludeSemantics(
                        child: TextButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline),
                          label: Text(strings.deleteAgent),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
