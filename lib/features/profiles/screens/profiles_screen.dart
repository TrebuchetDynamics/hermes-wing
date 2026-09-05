import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/hermes_domain_authority.dart';
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
import '../widgets/profile_directory_browser_sheet.dart';
import '../widgets/profile_editor_sheet.dart';

typedef WingLinkClientBuilder =
    WingLinkClient Function({
      required Uri origin,
      required String token,
      required String? hostFingerprint,
    });

final wingLinkClientBuilderProvider = Provider<WingLinkClientBuilder>(
  (ref) =>
      ({required origin, required token, required hostFingerprint}) =>
          WingLinkClient(
            origin: origin,
            token: token,
            hostFingerprint: hostFingerprint,
          ),
);

class ProfilesScreen extends ConsumerStatefulWidget {
  const ProfilesScreen({super.key});

  @override
  ConsumerState<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends ConsumerState<ProfilesScreen> {
  String? _actionError;
  String? _switchingGatewayId;
  String? _switchingProfileId;
  bool _chatRouteOpen = false;
  String? _wingLinkGatewayId;
  WingLinkClient? _wingLinkClient;
  List<WingLinkProfile>? _wingLinkProfiles;
  int _wingLinkLoadGeneration = 0;

  @override
  void initState() {
    super.initState();
    if (!wingLinkProfileCompatibilityEnabled) return;
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
        !_canReadProfiles(capabilities) &&
        _wingLinkClient != null &&
        _wingLinkGatewayId == activeGatewayId;

    if (state.status == HermesConnectionStatus.connecting ||
        usingWingLink && _wingLinkProfiles == null) {
      return WingSkeletonList(semanticLabel: strings.agentsLoading);
    }
    if (state.status == HermesConnectionStatus.error) {
      return WingEmptyState(
        icon: Icons.cloud_off_outlined,
        liveRegion: true,
        title: strings.agentsConnectionError,
        body: strings.gatewayConnectionRecoveryBody,
        actionLabel: strings.openChatAction,
        onAction: () => context.go(AppRoutes.hermes),
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
    // Seed the displayed inventory too when Wing Link is the profile source;
    // Agent profile state is empty on that compatibility path.
    final selectedId = usingWingLink
        ? (state.selectedProfileId != null &&
                  profiles.any(
                    (profile) => profile.id == state.selectedProfileId,
                  )
              ? state.selectedProfileId
              : profiles.isEmpty
              ? null
              : profiles.any((profile) => profile.id == kDefaultProfileId)
              ? kDefaultProfileId
              : profiles.first.id)
        : effectiveSelectedProfileId(state);
    final canCreateNatively = _canUseEndpoint(
      capabilities,
      scope: 'profiles:write',
      name: 'profile_create',
      method: 'POST',
      path: '/api/profiles',
    );
    final createViaWingLink = usingWingLink;
    final canCreate = createViaWingLink || canCreateNatively;
    final enrolledGatewayIdsByProfile = <String, String?>{
      if (usingWingLink && activeGatewayId != null)
        for (final profile in profiles)
          profile.id: directory.enrolledGatewayIdForManagedProfile(
            sourceGatewayId: activeGatewayId,
            profileId: profile.id,
          ),
    };
    VoidCallback? wingLinkChatAction(HermesProfile profile) {
      final enrolledGatewayId = enrolledGatewayIdsByProfile[profile.id];
      if (enrolledGatewayId == null) return null;
      return () => unawaited(
        _openEnrolledProfileChat(directory, profile, enrolledGatewayId),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        _ProfilesHeader(
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
                    canConfigure: createViaWingLink,
                    onCreate: createViaWingLink
                        ? ({
                            required name,
                            cloneFrom,
                            description,
                            provider,
                            model,
                            providerApiKey,
                            idempotencyKey,
                          }) async {
                            await _wingLinkClient!.createProfile(
                              name: name,
                              cloneFrom: cloneFrom,
                              description: description,
                              provider: provider,
                              model: model,
                              providerApiKey: providerApiKey,
                              idempotencyKey: idempotencyKey,
                            );
                            await _reloadWingLinkProfilesAfterCreate(
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
            content: Semantics(liveRegion: true, child: Text(_actionError!)),
            actions: [
              TextButton(
                onPressed: () => setState(() => _actionError = null),
                child: Text(strings.doneAction),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        if (profiles.isEmpty)
          WingEmptyState(
            icon: Icons.support_agent_outlined,
            title: strings.agentsEmptyTitle,
            body: strings.agentsEmptyBody,
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
                    SizedBox(
                      width: cardWidth,
                      child: _ProfileCard(
                        profile: profiles[index],
                        managedByWingLink:
                            isWingLinkRow(profiles[index]) &&
                            wingLinkRowsById[profiles[index].id]?.source !=
                                'api',
                        gatewayStateUnknown:
                            isWingLinkRow(profiles[index]) &&
                            wingLinkRowsById[profiles[index].id]
                                    ?.gatewayState ==
                                'unknown',
                        enrolled: isWingLinkRow(profiles[index])
                            ? enrolledGatewayIdsByProfile[profiles[index].id] !=
                                  null
                            : null,
                        selected: profiles[index].id == selectedId,
                        canEdit: isWingLinkRow(profiles[index])
                            ? wingLinkRowsById[profiles[index].id]?.canRename ??
                                  false
                            : _canUseEndpoint(
                                capabilities,
                                scope: 'profiles:write',
                                name: 'profile_update',
                                method: 'PATCH',
                                path: '/api/profiles/{name}',
                              ),
                        canDelete: isWingLinkRow(profiles[index])
                            ? wingLinkRowsById[profiles[index].id]?.canDelete ??
                                  false
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
                            ? wingLinkChatAction(profiles[index])
                            : _switchingProfileId == null
                            ? () => _selectProfile(channel, profiles[index])
                            : null,
                        onBrowseDirectories:
                            isWingLinkRow(profiles[index]) &&
                                wingLinkRowsById[profiles[index].id]?.source !=
                                    'api'
                            ? () => unawaited(_browseWingLinkDirectories())
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
                              ? wingLinkRowsById[profiles[index].id]
                                        ?.canDelete ??
                                    false
                              : profiles[index].id != 'default' &&
                                    _canUseEndpoint(
                                      capabilities,
                                      scope: 'profiles:write',
                                      name: 'profile_delete',
                                      method: 'DELETE',
                                      path: '/api/profiles/{name}',
                                    ),
                          // Existing profile configuration is intentionally fail-closed:
                          // the released CLI cannot roll back provider credentials.
                          canConfigure: false,
                          onRename: isWingLinkRow(profiles[index])
                              ? ({
                                  required profileId,
                                  required name,
                                  required revision,
                                }) async {
                                  await _runWingLinkMutation(
                                    directory,
                                    activeGatewayId!,
                                    () => _wingLinkClient!.renameProfile(
                                      id: profileId,
                                      name: name,
                                      revision:
                                          wingLinkRowsById[profileId]
                                              ?.renameRevision ??
                                          revision,
                                    ),
                                  );
                                  await _loadWingLinkProfiles(
                                    directory,
                                    activeGatewayId,
                                  );
                                }
                              : null,
                          onDelete: isWingLinkRow(profiles[index])
                              ? (id, revision, {idempotencyKey}) async {
                                  await _runWingLinkMutation(
                                    directory,
                                    activeGatewayId!,
                                    () => _wingLinkClient!.deleteProfile(
                                      id: id,
                                      idempotencyKey: idempotencyKey,
                                      revision:
                                          wingLinkRowsById[id]
                                              ?.deleteRevision ??
                                          revision,
                                    ),
                                  );
                                  await _loadWingLinkProfiles(
                                    directory,
                                    activeGatewayId,
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
                              ? (id, revision, {idempotencyKey}) async {
                                  await _runWingLinkMutation(
                                    directory,
                                    activeGatewayId!,
                                    () => _wingLinkClient!.deleteProfile(
                                      id: id,
                                      idempotencyKey: idempotencyKey,
                                      revision:
                                          wingLinkRowsById[id]
                                              ?.deleteRevision ??
                                          revision,
                                    ),
                                  );
                                  await _loadWingLinkProfiles(
                                    directory,
                                    activeGatewayId,
                                  );
                                }
                              : null,
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
    final generation = ++_wingLinkLoadGeneration;
    final channel = ref.read(hermesChannelProvider);
    if (!wingLinkProfileCompatibilityEnabled ||
        _canReadProfiles(channel.state.capabilities)) {
      if (mounted) {
        setState(() {
          _wingLinkGatewayId = null;
          _wingLinkClient = null;
          _wingLinkProfiles = null;
        });
      }
      return;
    }
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
      hostFingerprint: config?.wingLinkHostFingerprint,
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
      if (!mounted ||
          generation != _wingLinkLoadGeneration ||
          _wingLinkGatewayId != gatewayId) {
        return;
      }
      if (_canReadProfiles(channel.state.capabilities)) {
        setState(() {
          _wingLinkGatewayId = null;
          _wingLinkClient = null;
          _wingLinkProfiles = null;
        });
        return;
      }
      setState(() => _wingLinkProfiles = profiles);
    } catch (_) {
      if (mounted &&
          generation == _wingLinkLoadGeneration &&
          _wingLinkGatewayId == gatewayId) {
        setState(() {
          _wingLinkGatewayId = null;
          _wingLinkClient = null;
          _wingLinkProfiles = null;
        });
      }
      rethrow;
    }
  }

  Future<void> _reloadWingLinkProfilesAfterCreate(
    HermesGatewayDirectory directory,
    String gatewayId,
  ) async {
    final client = _wingLinkClient;
    if (client == null) return;
    try {
      final profiles = await client.listProfiles();
      if (!mounted ||
          directory.activeContactId?.gatewayId != gatewayId ||
          _wingLinkGatewayId != gatewayId ||
          _wingLinkClient != client) {
        return;
      }
      setState(() => _wingLinkProfiles = profiles);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _actionError = AppLocalizations.of(context).agentsLocalLoadError,
      );
    }
  }

  Future<void> _runWingLinkMutation(
    HermesGatewayDirectory directory,
    String gatewayId,
    Future<void> Function() mutation,
  ) async {
    try {
      await mutation();
    } on WingLinkPreconditionFailed {
      try {
        await _loadWingLinkProfiles(directory, gatewayId);
      } catch (_) {
        // The loader already clears stale compatibility state on failure.
      }
      rethrow;
    }
  }

  Future<void> _browseWingLinkDirectories() async {
    final client = _wingLinkClient;
    if (client == null) return;
    final strings = AppLocalizations.of(context);
    try {
      final metadata = await client.getMetadata();
      if (!metadata.capabilities.contains('directories.roots.read') ||
          !metadata.capabilities.contains('directories.children.read')) {
        throw const WingLinkException('Directory capabilities unavailable');
      }
      final device = await client.getCurrentDevice();
      if (!device.scopes.contains('directories:read')) {
        throw const WingLinkException('Directory scope unavailable');
      }
      if (!mounted) return;
      await showProfileDirectoryBrowser(
        context,
        loadRoots: client.listDirectoryRoots,
        loadChildren: (handle, offset) =>
            client.listChildDirectories(handle: handle, offset: offset),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.directoryBrowserUnavailable)),
      );
    }
  }

  Future<void> _openEditor({
    required HermesChannel channel,
    required List<HermesProfile> profiles,
    HermesProfile? profile,
    bool canEditSoul = false,
    bool canDelete = false,
    bool stableNames = false,
    bool canConfigure = false,
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
        canConfigure: canConfigure,
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
      if (mounted) {
        unawaited(_openChat());
      }
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

  Future<void> _openEnrolledProfileChat(
    HermesGatewayDirectory directory,
    HermesProfile profile,
    String gatewayId,
  ) async {
    if (_switchingProfileId != null || _chatRouteOpen) return;
    setState(() {
      _switchingProfileId = profile.id;
      _actionError = null;
    });
    try {
      await directory.activateGateway(gatewayId);
      if (mounted) await _openChat();
    } catch (_) {
      if (mounted) {
        setState(
          () => _actionError = AppLocalizations.of(
            context,
          ).agentsGatewayConnectError,
        );
      }
    } finally {
      if (mounted && _switchingProfileId == profile.id) {
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
    capabilities.advertisesScopedEndpoint(name, method, path, scope);

class _ProfilesHeader extends StatelessWidget {
  const _ProfilesHeader({
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

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.managedByWingLink,
    required this.gatewayStateUnknown,
    required this.enrolled,
    required this.selected,
    required this.canEdit,
    required this.canDelete,
    required this.strings,
    required this.switching,
    required this.onChat,
    required this.onEdit,
    this.onBrowseDirectories,
    required this.onDelete,
  });

  final HermesProfile profile;
  final bool managedByWingLink;
  final bool gatewayStateUnknown;
  final bool? enrolled;
  final bool selected;
  final bool canEdit;
  final bool canDelete;
  final AppLocalizations strings;
  final bool switching;
  final VoidCallback? onChat;
  final VoidCallback? onBrowseDirectories;
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
                  if (selected)
                    Chip(
                      avatar: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(strings.selectedAgent),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (profile.id == 'default')
                    Chip(label: Text(strings.defaultAgent)),
                  if (managedByWingLink)
                    Chip(
                      avatar: const Icon(Icons.link_outlined, size: 18),
                      label: Text(strings.managedByWingLink),
                    ),
                  if (enrolled case final enrolled?)
                    Chip(
                      avatar: Icon(
                        enrolled
                            ? Icons.verified_user_outlined
                            : Icons.person_off_outlined,
                        size: 18,
                      ),
                      label: Text(
                        enrolled
                            ? strings.profileEnrolled
                            : strings.profileNotEnrolled,
                      ),
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
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
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
                  if (onBrowseDirectories != null)
                    OutlinedButton.icon(
                      key: ValueKey('agent-browse-folders-${profile.id}'),
                      onPressed: onBrowseDirectories,
                      icon: const Icon(Icons.folder_open_outlined),
                      label: Text(strings.profileBrowseFoldersAction),
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
