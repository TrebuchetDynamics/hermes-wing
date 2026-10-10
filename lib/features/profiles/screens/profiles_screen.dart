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
import '../../../shared/widgets/wing_metadata.dart';
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
  final _editorSourceChanges = ValueNotifier<Object>(Object());
  ({String? gateway, String? origin, String? token, String? pin, bool native})?
  _profileSource;
  bool _sourceCheckScheduled = false;
  bool _profileLoadFailed = false;
  bool _setupOpened = false;
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

  ({String? gateway, String? origin, String? token, String? pin, bool native})
  get _currentProfileSource {
    final gateway = _directory.managementGatewayId;
    final config = gateway == null
        ? null
        : _directory.configForGateway(gateway);
    return (
      gateway: gateway,
      origin: config?.wingLinkOrigin,
      token: config?.wingLinkToken,
      pin: config?.wingLinkHostFingerprint,
      native:
          _channel.state.isConnected &&
          _directory.activeContactId?.gatewayId == gateway &&
          _canReadProfiles(_channel.state.capabilities),
    );
  }

  void _scheduleProfileSourceCheck() {
    _profileSearchKey();
    if (_sourceCheckScheduled) return;
    _sourceCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sourceCheckScheduled = false;
      if (mounted) unawaited(_syncProfileSource());
    });
  }

  Key _profileSearchKey() {
    // Compare credentials privately, never place them or an endpoint in UI keys.
    // Observe every notification, including A -> B -> A before the next frame.
    final source = (
      _directory,
      _channel,
      _currentProfileSource,
      _currentProfileSource.native ? _channel.state.connectedBaseUrl : null,
      ref.read(wingLinkClientBuilderProvider),
    );
    if (_searchSource != source) {
      _searchSource = source;
      _searchOwner = Object();
      _profileSource = null;
      _actionError = null;
      _profileLoadFailed = false;
      ++_wingLinkLoadGeneration;
      _editorSourceChanges.value = _searchOwner;
    }
    return ObjectKey(_searchOwner);
  }

  Future<void> _syncProfileSource({bool force = false}) async {
    final source = _currentProfileSource;
    if (!force && source == _profileSource) return;
    setState(() {
      _profileSource = source;
      if (_profileLoadFailed) _actionError = null;
      _profileLoadFailed = false;
    });
    final gatewayId = source.gateway;
    if (gatewayId == null) {
      ++_wingLinkLoadGeneration;
      setState(() {
        _wingLinkGatewayId = null;
        _wingLinkClient = null;
        _wingLinkProfiles = null;
      });
      return;
    }
    try {
      await _loadWingLinkProfiles(_directory, gatewayId);
    } catch (_) {
      if (!mounted || source != _currentProfileSource) return;
      setState(() {
        _profileLoadFailed = true;
        _actionError = AppLocalizations.of(context).agentsLocalLoadError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(hermesChannelProvider);
    final directory = ref.watch(hermesGatewayDirectoryProvider);
    ref.watch(wingLinkClientBuilderProvider);
    ref.listen(hermesChannelProvider, (previous, next) {
      if (identical(previous, next)) return;
      _channel.removeListener(_scheduleProfileSourceCheck);
      _channel = next;
      _channel.addListener(_scheduleProfileSourceCheck);
      _profileSource = null;
      _scheduleProfileSourceCheck();
    });
    ref.listen(hermesGatewayDirectoryProvider, (previous, next) {
      if (identical(previous, next)) return;
      _directory.removeListener(_scheduleProfileSourceCheck);
      _directory = next;
      _directory.addListener(_scheduleProfileSourceCheck);
      _profileSource = null;
      _scheduleProfileSourceCheck();
    });
    ref.listen(wingLinkClientBuilderProvider, (previous, next) {
      if (identical(previous, next)) return;
      _profileSource = null;
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
                    if (_profileLoadFailed)
                      TextButton(
                        onPressed: () =>
                            unawaited(_syncProfileSource(force: true)),
                        child: Text(strings.retryAction),
                      ),
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
    final usingWingLink =
        !_canReadProfiles(capabilities) &&
        _profileSource == _currentProfileSource &&
        _wingLinkClient != null &&
        _wingLinkGatewayId == activeGatewayId;

    if (!usingWingLink &&
            selectedAgent &&
            state.status == HermesConnectionStatus.connecting ||
        usingWingLink && _wingLinkProfiles == null) {
      return WingSkeletonList(semanticLabel: strings.agentsLoading);
    }
    if (!usingWingLink &&
        selectedAgent &&
        state.status == HermesConnectionStatus.error) {
      return WingEmptyState(
        icon: Icons.cloud_off_outlined,
        liveRegion: true,
        title: strings.agentsConnectionError,
        body: strings.gatewayConnectionRecoveryBody,
        actionLabel: strings.openChatAction,
        onAction: () => context.go(AppRoutes.hermes),
      );
    }
    if (!usingWingLink &&
        (!selectedAgent || state.status != HermesConnectionStatus.connected)) {
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
    final mutationOwner = _searchOwner;
    final mutationClient = _wingLinkClient;

    bool currentMutationOwner() {
      if (!mounted) return false;
      // Provider replacement can precede the next widget frame/listener flush.
      if (!identical(directory, ref.read(hermesGatewayDirectoryProvider)) ||
          !identical(channel, ref.read(hermesChannelProvider))) {
        return false;
      }
      _profileSearchKey();
      return identical(mutationOwner, _searchOwner) &&
          identical(directory, _directory) &&
          identical(channel, _channel) &&
          identical(mutationClient, _wingLinkClient);
    }

    ProfileRenameCallback renameManaged(HermesProfile profile) {
      final actionRevision =
          wingLinkRowsById[profile.id]?.renameRevision ?? profile.revision;
      return ({required profileId, required name, required revision}) async {
        if (!currentMutationOwner() || profileId != profile.id) return;
        await _runWingLinkMutation(
          directory,
          activeGatewayId!,
          currentMutationOwner,
          () async {
            final renamed = await mutationClient!.renameProfile(
              id: profile.id,
              name: name,
              revision: actionRevision,
            );
            if (!currentMutationOwner()) return;
            await directory.reconcileManagedProfileRename(
              sourceGatewayId: activeGatewayId,
              previousProfileId: profile.id,
              profileId: renamed.id,
              displayName: renamed.name,
            );
          },
        );
        if (currentMutationOwner()) {
          await _loadWingLinkProfiles(
            directory,
            activeGatewayId,
            existingClient: mutationClient,
          );
        }
      };
    }

    ProfileDeleteCallback deleteManaged(HermesProfile profile) {
      final actionRevision =
          wingLinkRowsById[profile.id]?.deleteRevision ?? profile.revision;
      return (id, revision, {idempotencyKey}) async {
        if (!currentMutationOwner() || id != profile.id) return;
        await _runWingLinkMutation(
          directory,
          activeGatewayId!,
          currentMutationOwner,
          () => mutationClient!.deleteProfile(
            id: profile.id,
            revision: actionRevision,
            idempotencyKey: idempotencyKey,
          ),
        );
        if (currentMutationOwner()) {
          await _loadWingLinkProfiles(
            directory,
            activeGatewayId,
            existingClient: mutationClient,
          );
        }
      };
    }

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
    bool hasStableLocalName(HermesProfile profile) =>
        wingLinkRowsById[profile.id]?.source != 'api';

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
    // Inventory order is not chat identity. A managed host can stay selected
    // while chat is disconnected or connected to another enrolled endpoint.
    final activeContact = directory.activeContactId;
    final selectedId = state.status != HermesConnectionStatus.connected
        ? null
        : usingWingLink
        ? profiles
              .where(
                (profile) =>
                    activeContact != null &&
                    profile.id == activeContact.profileId &&
                    enrolledGatewayIdsByProfile[profile.id] ==
                        activeContact.gatewayId,
              )
              .firstOrNull
              ?.id
        : effectiveSelectedProfileId(state);
    VoidCallback? wingLinkChatAction(HermesProfile profile) {
      final enrolledGatewayId = enrolledGatewayIdsByProfile[profile.id];
      if (enrolledGatewayId == null) return null;
      return () => unawaited(
        _openEnrolledProfileChat(directory, profile, enrolledGatewayId),
      );
    }

    final creationClient = createViaWingLink ? _wingLinkClient : null;
    Future<void> openCreate() => _openEditor(
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
              await creationClient!.createProfile(
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
    );
    if (widget.startSetup && !_setupOpened && createViaWingLink) {
      _setupOpened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            directory.managementGatewayId != activeGatewayId ||
            _wingLinkClient != creationClient) {
          return;
        }
        unawaited(openCreate());
      });
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _ProfilesHeader(
          subtitle: strings.agentsSubtitle,
          readOnly:
              !createViaWingLink &&
              !(capabilities?.auth.allows('profiles:write') ?? false),
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
                              ? enrolledGatewayIdsByProfile[profiles[index]
                                        .id] !=
                                    null
                              : null,
                          selected: profiles[index].id == selectedId,
                          canEdit: isWingLinkRow(profiles[index])
                              ? wingLinkRowsById[profiles[index].id]
                                        ?.canRename ??
                                    false
                              : _canUseEndpoint(
                                  capabilities,
                                  scope: 'profiles:write',
                                  name: 'profile_update',
                                  method: 'PATCH',
                                  path: '/api/profiles/{name}',
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
                          strings: strings,
                          switching: _switchingProfileId == profiles[index].id,
                          onChat: isWingLinkRow(profiles[index])
                              ? wingLinkChatAction(profiles[index])
                              : _switchingProfileId == null
                              ? () => _selectProfile(channel, profiles[index])
                              : null,
                          onBrowseDirectories:
                              isWingLinkRow(profiles[index]) &&
                                  wingLinkRowsById[profiles[index].id]
                                          ?.source !=
                                      'api'
                              ? () => unawaited(_browseWingLinkDirectories())
                              : null,
                          onEdit: () => _openEditor(
                            isMutationOwnerCurrent: currentMutationOwner,
                            channel: channel,
                            profiles: profiles,
                            profile: profiles[index],
                            stableNames:
                                isWingLinkRow(profiles[index]) &&
                                hasStableLocalName(profiles[index]),
                            canEditSoul:
                                !usingWingLink && state.canEditProfileSoul,
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
                                ? renameManaged(profiles[index])
                                : null,
                            onDelete: isWingLinkRow(profiles[index])
                                ? deleteManaged(profiles[index])
                                : null,
                          ),
                          onDelete: () => _openEditor(
                            isMutationOwnerCurrent: currentMutationOwner,
                            channel: channel,
                            profiles: profiles,
                            profile: profiles[index],
                            stableNames:
                                isWingLinkRow(profiles[index]) &&
                                hasStableLocalName(profiles[index]),
                            canDelete: true,
                            onDelete: isWingLinkRow(profiles[index])
                                ? deleteManaged(profiles[index])
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
      directory.selectManagementGateway(gatewayId);
      final config = directory.configForGateway(gatewayId);
      if (!wingLinkProfileCompatibilityEnabled ||
          config?.wingLinkToken == null) {
        await directory.activateGateway(gatewayId);
      }
      await _syncProfileSource();
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
    String gatewayId, {
    WingLinkClient? existingClient,
  }) async {
    final generation = ++_wingLinkLoadGeneration;
    final source = _currentProfileSource;
    final channel = ref.read(hermesChannelProvider);
    if (!wingLinkProfileCompatibilityEnabled ||
        (channel.state.isConnected &&
            directory.activeContactId?.gatewayId == gatewayId &&
            _canReadProfiles(channel.state.capabilities))) {
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
    final client =
        existingClient ??
        ref.read(wingLinkClientBuilderProvider)(
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
          source != _currentProfileSource ||
          _wingLinkGatewayId != gatewayId) {
        return;
      }
      if (channel.state.isConnected &&
          directory.activeContactId?.gatewayId == gatewayId &&
          _canReadProfiles(channel.state.capabilities)) {
        setState(() {
          _wingLinkGatewayId = null;
          _wingLinkClient = null;
          _wingLinkProfiles = null;
        });
        return;
      }
      setState(() => _wingLinkProfiles = profiles);
    } catch (error) {
      if (!mounted ||
          generation != _wingLinkLoadGeneration ||
          source != _currentProfileSource ||
          _wingLinkGatewayId != gatewayId) {
        return;
      }
      setState(() {
        if (error is WingLinkHttpException &&
            (error.statusCode == 401 || error.statusCode == 403)) {
          _searchOwner = Object();
        }
        _wingLinkGatewayId = null;
        _wingLinkClient = null;
        _wingLinkProfiles = null;
      });
      rethrow;
    }
  }

  Future<void> _reloadWingLinkProfilesAfterCreate(
    HermesGatewayDirectory directory,
    String gatewayId,
  ) async {
    final client = _wingLinkClient;
    if (client == null) return;
    final generation = _wingLinkLoadGeneration;
    final source = _currentProfileSource;
    try {
      final profiles = await client.listProfiles();
      if (!mounted ||
          generation != _wingLinkLoadGeneration ||
          source != _currentProfileSource ||
          directory.managementGatewayId != gatewayId ||
          _wingLinkGatewayId != gatewayId ||
          _wingLinkClient != client) {
        return;
      }
      setState(() => _wingLinkProfiles = profiles);
    } catch (error) {
      if (!mounted ||
          generation != _wingLinkLoadGeneration ||
          source != _currentProfileSource ||
          _wingLinkClient != client) {
        return;
      }
      setState(() {
        if (error is WingLinkHttpException &&
            (error.statusCode == 401 || error.statusCode == 403)) {
          _searchOwner = Object();
          _wingLinkClient = null;
          _wingLinkProfiles = null;
          _profileLoadFailed = true;
        }
        _actionError = AppLocalizations.of(context).agentsLocalLoadError;
      });
    }
  }

  Future<void> _runWingLinkMutation(
    HermesGatewayDirectory directory,
    String gatewayId,
    bool Function() isOwnerCurrent,
    Future<void> Function() mutation,
  ) async {
    try {
      await mutation();
    } on WingLinkPreconditionFailed {
      if (!isOwnerCurrent()) rethrow;
      final client = _wingLinkClient;
      try {
        await _loadWingLinkProfiles(
          directory,
          gatewayId,
          existingClient: client,
        );
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
    bool Function()? isMutationOwnerCurrent,
  }) async {
    if (!(isMutationOwnerCurrent?.call() ?? true)) return;
    _profileSearchKey();
    final editorOwner = _searchOwner;
    final catalogClient = _wingLinkClient;
    bool currentOwner() =>
        mounted &&
        identical(editorOwner, _searchOwner) &&
        identical(channel, _channel) &&
        (profile == null ||
            (identical(catalogClient, _wingLinkClient) &&
                (isMutationOwnerCurrent?.call() ?? true)));
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
        ownerChanges: canEditSoul || profile != null
            ? _editorSourceChanges
            : null,
        isOwnerCurrent: canEditSoul || profile != null ? currentOwner : null,
        canDelete: canDelete,
        stableNames: stableNames,
        canConfigure: canConfigure,

        loadModelOptions: stableNames
            ? catalogClient?.getProfileModelOptions
            : null,
        onCreate: onCreate,
        onRename: onRename,
        onDelete: onDelete,
      ),
    );
    if (currentOwner() && !stableNames) {
      await ref.read(hermesGatewayDirectoryProvider).refresh();
    }
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
      if (!mounted) return;
      if (!_channel.state.isConnected ||
          directory.activeContactId?.gatewayId != gatewayId) {
        setState(
          () => _actionError = AppLocalizations.of(
            context,
          ).agentsGatewayConnectError,
        );
        return;
      }
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
    capabilities.advertisesScopedEndpoint(name, method, path, scope) &&
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
                  if (managedByWingLink)
                    WingMetadata(
                      avatar: const Icon(Icons.link_outlined, size: 18),
                      label: Text(strings.managedByWingLink),
                    ),
                  if (enrolled case final enrolled?)
                    WingMetadata(
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
                  if (onBrowseDirectories != null)
                    OutlinedButton.icon(
                      key: ValueKey('agent-browse-folders-${profile.id}'),
                      onPressed: onBrowseDirectories,
                      icon: const Icon(Icons.folder_open_outlined),
                      label: Text(strings.profileBrowseFoldersAction),
                    ),
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
