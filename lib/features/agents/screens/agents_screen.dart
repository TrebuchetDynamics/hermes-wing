import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/models/hermes_capabilities.dart';
import '../../../core/wing_link/wing_link_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/routes/app_routes.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/wing_empty_state.dart';
import '../../../shared/widgets/wing_gateway_picker.dart';
import '../../../shared/widgets/wing_skeleton.dart';
import '../../hermes_chat/gateways/hermes_gateway_directory.dart';
import '../../hermes_chat/providers/hermes_channel_provider.dart';
import '../providers/profile_selection_provider.dart';
import '../widgets/profile_editor_sheet.dart';

typedef WingLinkClientBuilder =
    WingLinkClient Function({required Uri origin, required String token});

final wingLinkClientBuilderProvider = Provider<WingLinkClientBuilder>(
  (ref) =>
      ({required origin, required token}) =>
          WingLinkClient(origin: origin, token: token),
);

class AgentsScreen extends ConsumerStatefulWidget {
  const AgentsScreen({super.key});

  @override
  ConsumerState<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends ConsumerState<AgentsScreen> {
  String? _actionError;
  String? _switchingGatewayId;
  String? _switchingProfileId;
  String? _wingLinkGatewayId;
  WingLinkClient? _wingLinkClient;
  List<WingLinkProfile>? _wingLinkProfiles;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final directory = ref.read(hermesGatewayDirectoryProvider);
      final gatewayId = directory.activeContactId?.gatewayId;
      if (gatewayId != null) {
        unawaited(
          _loadWingLinkProfiles(directory, gatewayId).catchError((_) {
            if (mounted) {
              setState(
                () => _actionError = AppLocalizations.of(
                  context,
                ).agentsLocalLoadError,
              );
            }
          }),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(hermesChannelProvider);
    final directory = ref.watch(hermesGatewayDirectoryProvider);
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
                  helpText: AppLocalizations.of(
                    context,
                  ).agentsGatewayPickerHelp,
                  enabled: _switchingGatewayId == null,
                  onSelected: (id) => unawaited(_selectGateway(directory, id)),
                ),
              Expanded(child: _buildBody(context, channel, directory, strings)),
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
  ) {
    final state = channel.state;
    final capabilities = state.capabilities;
    final activeGatewayId = directory.activeContactId?.gatewayId;
    final usingWingLink =
        _wingLinkClient != null && _wingLinkGatewayId == activeGatewayId;

    if (state.status == HermesConnectionStatus.connecting ||
        usingWingLink && _wingLinkProfiles == null) {
      return WingSkeletonList(semanticLabel: strings.agentsLoading);
    }
    if (state.status == HermesConnectionStatus.error) {
      return WingEmptyState(
        icon: Icons.cloud_off_outlined,
        title: strings.agentsConnectionError,
        body: state.errorMessage ?? strings.profileOperationFailed,
      );
    }
    if (state.status != HermesConnectionStatus.connected) {
      return WingEmptyState(
        icon: Icons.hub_outlined,
        title: strings.gatewaySelectPromptTitle,
        body: strings.agentsConnectionRequiredBody,
      );
    }
    if (!_canReadProfiles(capabilities) && !usingWingLink) {
      return WingEmptyState(
        icon: Icons.lock_outline,
        title: strings.agentsUnavailableTitle,
        body: strings.agentsUnavailableBody,
      );
    }

    final wingLinkRows = usingWingLink
        ? _wingLinkProfiles ?? const <WingLinkProfile>[]
        : const <WingLinkProfile>[];
    final wingLinkRowsById = {for (final row in wingLinkRows) row.id: row};
    final profiles = usingWingLink
        ? [
            for (final row in wingLinkRows)
              HermesProfile(
                id: row.id,
                displayName: row.name,
                revision: row.revision,
                description: row.description,
                model: row.model,
                skillsCount: row.skillsCount,
                gatewayRunning: row.gatewayState == 'running',
              ),
          ]
        : state.profiles;
    bool isWingLinkRow(HermesProfile profile) => usingWingLink;
    bool hasStableLocalName(HermesProfile profile) =>
        wingLinkRowsById[profile.id]?.source != 'api';
    bool canUseHermesProfileContext(HermesProfile profile) =>
        profile.id == 'default' ||
        capabilities?.profileContext.isSupportedQueryContext == true;
    // Seed the default profile for display when nothing is selected yet, so
    // the UI has profile context on mount. This is a pure derivation and never
    // triggers an active-profile network call.
    final selectedId = effectiveSelectedProfileId(state);
    final canCreateNatively = _canUseEndpoint(
      capabilities,
      scope: 'profiles:write',
      name: 'profile_create',
      method: 'POST',
      path: '/api/profiles',
    );
    final createViaWingLink = usingWingLink;
    final canCreate = createViaWingLink || canCreateNatively;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        _AgentsHeader(
          title: strings.agentsTitle,
          subtitle: strings.agentsSubtitle,
          readOnly:
              !createViaWingLink &&
              !(capabilities?.auth.allows('profiles:write') ?? false),
          readOnlyLabel: strings.readOnlyAccess,
          action: canCreate
              ? FilledButton.icon(
                  onPressed: () => _openEditor(
                    channel: channel,
                    profiles: profiles,
                    stableNames: createViaWingLink,
                    onCreate: createViaWingLink
                        ? (name, cloneFrom) async {
                            await _wingLinkClient!.createProfile(
                              name: name,
                              cloneFrom: cloneFrom,
                            );
                            await _loadWingLinkProfiles(
                              directory,
                              activeGatewayId!,
                            );
                          }
                        : null,
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(strings.newAgent),
                )
              : null,
        ),
        if (_actionError != null) ...[
          const SizedBox(height: 16),
          MaterialBanner(
            content: Text(_actionError!),
            actions: [
              TextButton(
                onPressed: () => setState(() => _actionError = null),
                child: Text(strings.doneAction),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        if (profiles.isEmpty)
          WingEmptyState(
            icon: Icons.support_agent_outlined,
            title: strings.agentsEmptyTitle,
            body: strings.agentsEmptyBody,
          )
        else
          for (var index = 0; index < profiles.length; index++) ...[
            if (index > 0) const SizedBox(height: 12),
            _AgentCard(
              profile: profiles[index],
              managedByWingLink:
                  isWingLinkRow(profiles[index]) &&
                  wingLinkRowsById[profiles[index].id]?.source != 'api',
              gatewayStateUnknown:
                  isWingLinkRow(profiles[index]) &&
                  wingLinkRowsById[profiles[index].id]?.gatewayState ==
                      'unknown',
              selected: profiles[index].id == selectedId,
              canEdit: isWingLinkRow(profiles[index])
                  ? wingLinkRowsById[profiles[index].id]?.canRename ?? false
                  : _canUseEndpoint(
                      capabilities,
                      scope: 'profiles:write',
                      name: 'profile_update',
                      method: 'PATCH',
                      path: '/api/profiles/{name}',
                    ),
              canDelete: isWingLinkRow(profiles[index])
                  ? wingLinkRowsById[profiles[index].id]?.canDelete ?? false
                  : profiles[index].id != 'default' &&
                        _canUseEndpoint(
                          capabilities,
                          scope: 'profiles:write',
                          name: 'profile_delete',
                          method: 'DELETE',
                          path: '/api/profiles/{name}',
                        ),
              strings: strings,
              switching: _switchingProfileId == profiles[index].id,
              onChat: isWingLinkRow(profiles[index])
                  ? canUseHermesProfileContext(profiles[index])
                        ? profiles[index].id == 'default'
                              ? () => GoRouter.maybeOf(
                                  context,
                                )?.go(AppRoutes.hermes)
                              : () => _selectProfile(channel, profiles[index])
                        : null
                  : _switchingProfileId == null
                  ? () => _selectProfile(channel, profiles[index])
                  : null,
              onEdit: () => _openEditor(
                channel: channel,
                profiles: profiles,
                profile: profiles[index],
                stableNames:
                    isWingLinkRow(profiles[index]) &&
                    hasStableLocalName(profiles[index]),
                canEditSoul:
                    canUseHermesProfileContext(profiles[index]) &&
                    _canUseEndpoint(
                      capabilities,
                      scope: 'profiles:read',
                      name: 'profile_soul',
                      method: 'GET',
                      path: '/api/profiles/{name}/soul',
                    ) &&
                    _canUseEndpoint(
                      capabilities,
                      scope: 'profiles:write',
                      name: 'profile_soul_update',
                      method: 'PUT',
                      path: '/api/profiles/{name}/soul',
                    ),
                canDelete: isWingLinkRow(profiles[index])
                    ? wingLinkRowsById[profiles[index].id]?.canDelete ?? false
                    : profiles[index].id != 'default' &&
                          _canUseEndpoint(
                            capabilities,
                            scope: 'profiles:write',
                            name: 'profile_delete',
                            method: 'DELETE',
                            path: '/api/profiles/{name}',
                          ),
                onRename: isWingLinkRow(profiles[index])
                    ? (id, name, revision) async {
                        await _wingLinkClient!.renameProfile(
                          id: id,
                          name: name,
                          revision:
                              wingLinkRowsById[id]?.renameRevision ?? revision,
                        );
                        await _loadWingLinkProfiles(
                          directory,
                          activeGatewayId!,
                        );
                      }
                    : null,
                onDelete: isWingLinkRow(profiles[index])
                    ? (id, revision) async {
                        await _wingLinkClient!.deleteProfile(
                          id: id,
                          revision:
                              wingLinkRowsById[id]?.deleteRevision ?? revision,
                        );
                        await _loadWingLinkProfiles(
                          directory,
                          activeGatewayId!,
                        );
                      }
                    : null,
              ),
              onDelete: () => _openEditor(
                channel: channel,
                profiles: profiles,
                profile: profiles[index],
                stableNames:
                    isWingLinkRow(profiles[index]) &&
                    hasStableLocalName(profiles[index]),
                canDelete: true,
                onDelete: isWingLinkRow(profiles[index])
                    ? (id, revision) async {
                        await _wingLinkClient!.deleteProfile(
                          id: id,
                          revision:
                              wingLinkRowsById[id]?.deleteRevision ?? revision,
                        );
                        await _loadWingLinkProfiles(
                          directory,
                          activeGatewayId!,
                        );
                      }
                    : null,
              ),
            ),
          ],
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
      await directory.activateGateway(gatewayId);
      await _loadWingLinkProfiles(directory, gatewayId);
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

  Future<void> _loadWingLinkProfiles(
    HermesGatewayDirectory directory,
    String gatewayId,
  ) async {
    final config = directory.configForGateway(gatewayId);
    final originValue = config?.wingLinkOrigin?.trim() ?? '';
    final token = config?.wingLinkToken?.trim() ?? '';
    final origin = Uri.tryParse(originValue);
    if (origin == null || origin.host.isEmpty || token.isEmpty) {
      if (mounted) {
        setState(() {
          _wingLinkGatewayId = null;
          _wingLinkClient = null;
          _wingLinkProfiles = null;
        });
      }
      return;
    }
    final client = ref.read(wingLinkClientBuilderProvider)(
      origin: origin,
      token: token,
    );
    if (mounted) {
      setState(() {
        _wingLinkGatewayId = gatewayId;
        _wingLinkClient = client;
        _wingLinkProfiles = null;
      });
    }
    try {
      final profiles = await client.listProfiles();
      if (!mounted || _wingLinkGatewayId != gatewayId) return;
      setState(() => _wingLinkProfiles = profiles);
    } catch (_) {
      if (mounted && _wingLinkGatewayId == gatewayId) {
        setState(() {
          _wingLinkGatewayId = null;
          _wingLinkClient = null;
          _wingLinkProfiles = null;
        });
      }
      rethrow;
    }
  }

  Future<void> _openEditor({
    required HermesChannel channel,
    required List<HermesProfile> profiles,
    HermesProfile? profile,
    bool canEditSoul = false,
    bool canDelete = false,
    bool stableNames = false,
    ProfileCreateCallback? onCreate,
    ProfileRenameCallback? onRename,
    ProfileDeleteCallback? onDelete,
  }) async {
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
        canDelete: canDelete,
        stableNames: stableNames,
        onCreate: onCreate,
        onRename: onRename,
        onDelete: onDelete,
      ),
    );
  }

  Future<void> _selectProfile(
    HermesChannel channel,
    HermesProfile profile,
  ) async {
    final profileId = profile.id;
    if (_switchingProfileId != null) return;
    setState(() {
      _switchingProfileId = profileId;
      _actionError = null;
    });
    try {
      final directory = ref.read(hermesGatewayDirectoryProvider);
      if (directory.activeContactId == null) {
        await channel.selectProfile(profileId);
      } else {
        await directory.selectProfileOnActiveGateway(
          profileId,
          discoveredProfile: profile,
        );
      }
      if (mounted) GoRouter.maybeOf(context)?.go(AppRoutes.hermes);
    } catch (_) {
      if (mounted) {
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
    capabilities.advertisesScopedEndpoint(name, method, path, scope);

class _AgentsHeader extends StatelessWidget {
  const _AgentsHeader({
    required this.title,
    required this.subtitle,
    required this.readOnly,
    required this.readOnlyLabel,
    this.action,
  });

  final String title;
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
              Text(title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(subtitle, style: theme.textTheme.bodyLarge),
              if (readOnly) ...[
                const SizedBox(height: 10),
                Chip(
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

class _AgentCard extends StatelessWidget {
  const _AgentCard({
    required this.profile,
    required this.managedByWingLink,
    required this.gatewayStateUnknown,
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
  final bool managedByWingLink;
  final bool gatewayStateUnknown;
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
      if (selected) strings.selectedAgent,
      if (profile.id == 'default') strings.defaultAgent,
    ].join(', ');

    return Semantics(
      container: true,
      selected: selected,
      label: semanticsLabel,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    child: Text(
                      displayName.characters.first.toUpperCase(),
                      semanticsLabel: '',
                    ),
                  ),
                  const SizedBox(width: 14),
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
                  if (selected)
                    Chip(
                      avatar: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(strings.selectedAgent),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (profile.id == 'default')
                    Chip(label: Text(strings.defaultAgent)),
                  if (managedByWingLink)
                    Chip(
                      avatar: const Icon(Icons.link_outlined, size: 18),
                      label: Text(strings.managedByWingLink),
                    ),
                  Chip(
                    avatar: const Icon(Icons.psychology_outlined, size: 18),
                    label: Text(
                      profile.model.isEmpty
                          ? strings.agentNoModel
                          : profile.model,
                    ),
                  ),
                  Chip(
                    avatar: const Icon(Icons.extension_outlined, size: 18),
                    label: Text(strings.agentSkillsCount(profile.skillsCount)),
                  ),
                  Chip(
                    avatar: Icon(
                      gatewayStateUnknown
                          ? Icons.help_outline
                          : profile.gatewayRunning
                          ? Icons.check_circle_outline
                          : Icons.pause_circle_outline,
                      size: 18,
                    ),
                    label: Text(
                      gatewayStateUnknown
                          ? strings.agentGatewayUnknown
                          : profile.gatewayRunning
                          ? strings.agentGatewayRunning
                          : strings.agentGatewayOff,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Semantics(
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.chat_bubble_outline),
                        label: Text(
                          switching
                              ? strings.switchingAgent
                              : strings.chatWithAgent,
                        ),
                      ),
                    ),
                  ),
                  if (canEdit)
                    Semantics(
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
