import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hermes/channel/hermes_channel.dart';

import '../../../core/hermes/models/hermes_health.dart';
import '../../../core/hermes/models/hermes_metadata_text.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/wing_empty_state.dart';
import '../../../shared/widgets/wing_gateway_switch.dart';
import '../../../shared/widgets/wing_skeleton.dart';
import '../../hermes_chat/gateways/hermes_gateway_directory.dart';
import '../../hermes_chat/providers/hermes_channel_provider.dart';
import '../widgets/saved_connections_section.dart';

/// Gateway-selected, bounded, read-only health. Lifecycle, logs, and messaging
/// platform administration are deliberately absent until dedicated scoped
/// contracts are advertised.
class GatewayScreen extends ConsumerStatefulWidget {
  const GatewayScreen({super.key});

  @override
  ConsumerState<GatewayScreen> createState() => _GatewayScreenState();
}

class _GatewayScreenState extends ConsumerState<GatewayScreen> {
  String? _switchingGatewayId;
  String? _actionError;
  bool _refreshing = false;
  bool _refreshFailed = false;
  bool _disconnecting = false;
  int _refreshGeneration = 0;
  HermesChannel? _healthChannel;
  HermesGatewayDirectory? _healthDirectory;
  Object? _healthContext;
  Object _healthOwner = Object();
  final _healthDisplayReads =
      Expando<
        ({String? origin, String? profile, HermesHealthStatus? health})
      >();
  ({HermesChannel channel, String? origin, String? profile})?
  _healthDataContext;
  HermesConnectionStatus? _healthStatus;
  HermesHealthStatus? _detailedHealth;

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(hermesChannelProvider);
    final directory = ref.watch(hermesGatewayDirectoryProvider);
    _bindHealthOwner(channel, directory);
    ref.listen(hermesChannelProvider, (previous, next) {
      if (!identical(previous, next)) {
        setState(
          () =>
              _bindHealthOwner(next, ref.read(hermesGatewayDirectoryProvider)),
        );
      }
    });
    ref.listen(hermesGatewayDirectoryProvider, (previous, next) {
      if (!identical(previous, next)) {
        setState(() => _bindHealthOwner(ref.read(hermesChannelProvider), next));
      }
    });
    final strings = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([channel, directory]),
      builder: (context, _) {
        final activeGatewayId = directory.managementGatewayId;

        final connectedGatewayId = directory.activeContactId?.gatewayId;
        final selectedChat = _selectedChat(directory);
        final chatConnected = selectedChat && channel.state.isConnected;
        final canRefresh = _canRefreshHealth(channel, directory);
        final refreshing = _refreshing;
        final activeGateway = activeGatewayId == null
            ? null
            : directory.gateways
                  .where((gateway) => gateway.id == activeGatewayId)
                  .firstOrNull;
        final activeConfig = activeGatewayId == null
            ? null
            : directory.configForGateway(activeGatewayId);

        return Scaffold(
          appBar: AppBar(
            title: Text(strings.gatewayStatusTitle),
            actions: [
              if (selectedChat && connectedGatewayId != null)
                TextButton.icon(
                  key: const ValueKey('gateway-disconnect-button'),
                  label: Text(strings.chatConnectionDisconnectAction),
                  onPressed: _disconnecting
                      ? null
                      : () => unawaited(
                          _confirmDisconnect(
                            directory,
                            connectedGatewayId,
                            activeGateway?.label ?? connectedGatewayId,
                            strings,
                          ),
                        ),
                  icon: _disconnecting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.link_off),
                ),
              if (canRefresh)
                // Preserve the child's keyboard focus while keeping a named,
                // disabled button exposed during the pending read.
                Tooltip(
                  message: strings.gatewayStatusRefreshTooltip,
                  excludeFromSemantics: true,
                  child: MergeSemantics(
                    child: Semantics(
                      button: true,
                      enabled: !refreshing,
                      label: strings.gatewayStatusRefreshTooltip,
                      child: IconButton(
                        key: const ValueKey('gateway-refresh-button'),
                        onPressed: refreshing
                            ? null
                            : () => unawaited(_refresh()),
                        icon: refreshing
                            ? const ExcludeSemantics(
                                child: SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : const Icon(Icons.refresh),
                      ),
                    ),
                  ),
                ),
              const AppShellMenuButton(),
            ],
          ),
          body: Column(
            children: [
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
                child: ListView(
                  key: const ValueKey('gateway-body-list'),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    SavedConnectionsSection(directory: directory),
                    if (activeConfig != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chatConnected
                                    ? strings.gatewayChatConnected
                                    : strings.gatewayChatDisconnected,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(strings.gatewaySavedConnectionHelp),
                              if (!chatConnected) ...[
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  key: const ValueKey(
                                    'gateway-connect-chat-button',
                                  ),
                                  onPressed:
                                      _switchingGatewayId != null ||
                                          _disconnecting
                                      ? null
                                      : () => unawaited(
                                          _selectGateway(
                                            directory,
                                            activeGatewayId!,
                                            strings,
                                          ),
                                        ),
                                  icon: const Icon(Icons.chat_bubble_outline),
                                  label: Text(strings.gatewayChatConnectAction),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    if (selectedChat &&
                        channel.state.status !=
                            HermesConnectionStatus.disconnected)
                      _GatewayBody(
                        key: ObjectKey(_healthOwner),
                        state: channel.state,
                        detailedHealth: _detailedHealth,
                        strings: strings,
                        refreshFailed: _refreshFailed,
                        onRetry: canRefresh && !refreshing
                            ? () => unawaited(_refresh())
                            : null,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
      _refreshFailed = false;
    });
    final channel = ref.read(hermesChannelProvider);
    await completeWingGatewaySwitch(
      context: context,
      directory: directory,
      channel: channel,
      isCurrentOwner: () =>
          identical(ref.read(hermesChannelProvider), channel) &&
          identical(ref.read(hermesGatewayDirectoryProvider), directory),
      gatewayId: gatewayId,
      onFailure: (kind) => setState(() {
        _actionError = wingGatewayConnectionFailureMessage(strings, kind);
      }),
      onFinished: () => setState(() => _switchingGatewayId = null),
    );
  }

  Future<void> _confirmDisconnect(
    HermesGatewayDirectory directory,
    String gatewayId,
    String gatewayLabel,
    AppLocalizations strings,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.chatConnectionDisconnectTitle),
        content: Text(strings.chatConnectionDisconnectBody(gatewayLabel)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancelAction),
          ),
          FilledButton(
            key: const ValueKey('gateway-disconnect-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.chatConnectionDisconnectAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _disconnecting = true;
      _actionError = null;
    });
    try {
      if (directory.activeContactId?.gatewayId == gatewayId) {
        await directory.showDirectory();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _actionError = strings.gatewayChatDisconnectFailed);
      }
    } finally {
      if (mounted) setState(() => _disconnecting = false);
    }
  }

  bool _selectedChat(HermesGatewayDirectory directory) {
    final selected = directory.managementGatewayId;
    final connected = directory.activeContactId?.gatewayId;
    return connected == selected ||
        directory.hosts.any(
          (host) =>
              host.containsGateway(selected) && host.containsGateway(connected),
        );
  }

  bool _canRefreshHealth(
    HermesChannel channel,
    HermesGatewayDirectory directory,
  ) =>
      _selectedChat(directory) &&
      !channel.state.isSelectingProfile &&
      _detailedHealthAdvertised(channel.state);

  void _bindHealthOwner(
    HermesChannel channel,
    HermesGatewayDirectory directory,
  ) {
    if (!identical(_healthChannel, channel) ||
        !identical(_healthDirectory, directory)) {
      _healthChannel?.removeListener(_healthOwnerChanged);
      _healthDirectory?.removeListener(_healthOwnerChanged);
      _healthChannel = channel;
      _healthDirectory = directory;
      channel.addListener(_healthOwnerChanged);
      directory.addListener(_healthOwnerChanged);
    }
    _syncHealthOwner();
  }

  bool _syncHealthOwner() {
    final channel = _healthChannel!;
    final directory = _healthDirectory!;
    final state = channel.state;
    final context = (
      channel,
      directory,
      state.connectedBaseUrl,
      state.selectedProfileId,
      state.status,
      state.isSelectingProfile,
      directory.managementGatewayId,
      directory.activeContactId,
      _canRefreshHealth(channel, directory),
    );
    if (_healthContext == context) return false;
    final dataContext = (
      channel: channel,
      origin: state.connectedBaseUrl,
      profile: state.selectedProfileId,
    );
    final displayRead = _healthDisplayReads[channel];
    final bootstrap =
        displayRead == null ||
        (identical(_healthDataContext?.channel, channel) &&
            _healthStatus == HermesConnectionStatus.connecting &&
            state.isConnected);

    // Shared loader failures have no management-owner provenance. Keep only the
    // last successful display read for this Agent identity; never mutate the channel.
    _detailedHealth =
        displayRead != null &&
            displayRead.origin == dataContext.origin &&
            displayRead.profile == dataContext.profile &&
            _channelHealthFailed(state)
        ? displayRead.health
        : state.detailedHealth;
    _healthDataContext = dataContext;
    _rememberHealthDisplayRead();
    _healthStatus = state.status;
    _healthContext = context;
    _healthOwner = Object();
    _refreshGeneration++;
    _refreshing = false;
    _refreshFailed = bootstrap && _channelHealthFailed(state);
    return true;
  }

  bool _channelHealthFailed(HermesChannelState state) => state
      .optionalResourceErrors
      .containsKey(HermesOptionalResource.detailedHealth);

  void _rememberHealthDisplayRead() {
    final context = _healthDataContext!;
    // Weak, screen-lifetime display cache only; no errors or Agent-owned state writes.
    _healthDisplayReads[context.channel] = (
      origin: context.origin,
      profile: context.profile,
      health: _detailedHealth,
    );
  }

  void _healthOwnerChanged() {
    // Observe every notification, including loss/restoration before a frame.
    // Ordinary health updates with the same authorized owner do not cancel UI work.
    final transferred = _syncHealthOwner();
    final state = _healthChannel!.state;
    if (!transferred && !_channelHealthFailed(state)) {
      _detailedHealth = state.detailedHealth;
      _rememberHealthDisplayRead();
    }
    if (transferred && mounted) setState(() {});
  }

  @override
  void dispose() {
    _healthChannel?.removeListener(_healthOwnerChanged);
    _healthDirectory?.removeListener(_healthOwnerChanged);
    super.dispose();
  }

  Future<void> _refresh() async {
    final channel = ref.read(hermesChannelProvider);
    final directory = ref.read(hermesGatewayDirectoryProvider);
    _bindHealthOwner(channel, directory);
    if (_refreshing || !_canRefreshHealth(channel, directory)) return;
    final generation = ++_refreshGeneration;
    final owner = _healthOwner;
    bool isCurrent() =>
        mounted &&
        generation == _refreshGeneration &&
        identical(owner, _healthOwner) &&
        identical(channel, ref.read(hermesChannelProvider)) &&
        identical(directory, ref.read(hermesGatewayDirectoryProvider)) &&
        _canRefreshHealth(channel, directory);
    setState(() {
      _refreshing = true;
    });
    try {
      await channel.loadDetailedHealth();
      if (isCurrent()) {
        setState(() {
          _detailedHealth = channel.state.detailedHealth;
          _rememberHealthDisplayRead();
          _refreshFailed = false;
        });
      }
    } catch (_) {
      if (isCurrent()) setState(() => _refreshFailed = true);
    } finally {
      if (isCurrent()) {
        setState(() {
          _refreshing = false;
        });
      }
    }
  }
}

class _GatewayBody extends StatelessWidget {
  const _GatewayBody({
    super.key,
    required this.state,
    required this.detailedHealth,
    required this.strings,
    required this.refreshFailed,
    required this.onRetry,
  });

  final HermesChannelState state;
  final HermesHealthStatus? detailedHealth;
  final AppLocalizations strings;
  final bool refreshFailed;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.status == HermesConnectionStatus.connecting) {
      return WingSkeletonList(
        semanticLabel: AppLocalizations.of(context).gatewayLoading,
      );
    }
    if (state.status != HermesConnectionStatus.connected) {
      if (state.status == HermesConnectionStatus.error) {
        return WingEmptyState(
          icon: Icons.cloud_off_outlined,
          liveRegion: true,
          title: strings.gatewayStatusUnavailableTitle,
          body: strings.gatewayStatusConnectionErrorBody,
        );
      }
      return WingEmptyState(
        icon: Icons.hub_outlined,
        title: strings.gatewaySelectPromptTitle,
        body: strings.gatewayStatusConnectionRequiredBody,
      );
    }
    final detailedAdvertised = _detailedHealthAdvertised(state);
    final detailedFailed = refreshFailed;
    final health = detailedAdvertised && !detailedFailed
        ? detailedHealth ?? state.basicHealth
        : state.basicHealth;
    if (health == null) {
      return WingEmptyState(
        icon: detailedAdvertised
            ? Icons.sync_problem_outlined
            : Icons.lock_outline,
        liveRegion: detailedAdvertised,
        title: strings.gatewayStatusUnavailableTitle,
        body: detailedAdvertised
            ? strings.gatewayStatusLoadFailedBody
            : strings.gatewayStatusUnavailableBody,
        actionLabel: detailedAdvertised ? strings.retryAction : null,
        onAction: detailedAdvertised ? onRetry : null,
      );
    }
    final fallbackNotice = !detailedAdvertised
        ? strings.gatewayStatusBasicOnlyBody
        : detailedFailed || detailedHealth == null
        ? strings.gatewayStatusDetailedFallbackBody
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(strings.gatewayStatusSubtitle),
        const SizedBox(height: 16),
        _HealthCard(
          health: health,
          strings: strings,
          showDetailedFields: fallbackNotice == null,
        ),
        const SizedBox(height: 8),
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      fallbackNotice == null
                          ? Icons.visibility_outlined
                          : Icons.info_outline,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        fallbackNotice ?? strings.gatewayStatusReadOnlyNote,
                        style: fallbackNotice == null
                            ? Theme.of(context).textTheme.bodySmall
                            : null,
                      ),
                    ),
                  ],
                ),
                if (detailedAdvertised && detailedFailed) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      key: const ValueKey('gateway-status-inline-retry'),
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: Text(strings.retryAction),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (health.readiness case final readiness?
            when !readiness.isAbsent && readiness.checks.isNotEmpty) ...[
          const SizedBox(height: 16),
          _ReadinessCard(readiness: readiness, strings: strings),
        ],
        if (health.platforms.isNotEmpty) ...[
          const SizedBox(height: 16),
          _PlatformsCard(platforms: health.platforms, strings: strings),
        ],
      ],
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({
    required this.health,
    required this.strings,
    required this.showDetailedFields,
  });

  final HermesHealthStatus health;
  final AppLocalizations strings;
  final bool showDetailedFields;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  health.isOk
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_outlined,
                  color: health.isOk ? colors.primary : colors.error,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    health.isOk
                        ? strings.gatewayHealthy
                        : strings.gatewayNeedsAttention,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _StatusRow(
              label: strings.gatewayPlatformLabel,
              value: boundedHermesMetadataText(health.platform, 80),
            ),
            if (health.version?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: 10),
              _StatusRow(
                label: strings.gatewayVersionLabel,
                value: boundedHermesMetadataText(health.version!, 80),
              ),
            ],
            if (showDetailedFields &&
                (health.gatewayState?.trim().isNotEmpty ?? false)) ...[
              const SizedBox(height: 10),
              _StatusRow(
                label: strings.gatewayRuntimeStateLabel,
                value: boundedHermesMetadataText(health.gatewayState!, 80),
              ),
            ],
            if (showDetailedFields) ...[
              const SizedBox(height: 10),
              _StatusRow(
                label: strings.gatewayActiveAgentsLabel,
                value: health.activeAgents.toString(),
              ),
            ],
            if (health.gatewayBusy case final busy?
                when showDetailedFields) ...[
              const SizedBox(height: 10),
              _StatusRow(
                label: strings.gatewayWorkStateLabel,
                value: busy ? strings.gatewayBusy : strings.gatewayIdle,
              ),
            ],
            if (health.gatewayDrainable case final drainable?
                when showDetailedFields) ...[
              const SizedBox(height: 10),
              _StatusRow(
                label: strings.gatewayDrainableLabel,
                value: drainable ? strings.gatewayYes : strings.gatewayNo,
              ),
            ],
            if (health.updatedAt case final updatedAt?
                when showDetailedFields) ...[
              const SizedBox(height: 10),
              _StatusRow(
                label: strings.gatewayUpdatedLabel,
                value: boundedHermesMetadataText(updatedAt, 80),
              ),
            ],
            if (health.pid case final pid? when showDetailedFields) ...[
              const SizedBox(height: 10),
              _StatusRow(
                label: strings.gatewayProcessIdLabel,
                value: pid.toString(),
              ),
            ],
            if (health.exitReason case final exitReason?
                when showDetailedFields) ...[
              const SizedBox(height: 10),
              _StatusRow(
                label: strings.gatewayExitReasonLabel,
                value: boundedHermesMetadataText(exitReason, 160),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.readiness, required this.strings});

  final HermesGatewayReadiness readiness;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.gatewayRuntimeReadinessTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < readiness.checks.length; index++) ...[
            if (index > 0) const SizedBox(height: 10),
            _StatusRow(
              label: _readinessLabel(readiness.checks[index].id, strings),
              value: _readinessValue(readiness.checks[index], strings),
            ),
          ],
        ],
      ),
    ),
  );
}

class _PlatformsCard extends StatelessWidget {
  const _PlatformsCard({required this.platforms, required this.strings});

  final List<HermesGatewayPlatformStatus> platforms;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.gatewayMessagingPlatformsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < platforms.length; index++) ...[
            if (index > 0) const SizedBox(height: 10),
            _StatusRow(
              label: boundedHermesMetadataText(platforms[index].name, 80),
              value: boundedHermesMetadataText(platforms[index].status, 80),
            ),
          ],
        ],
      ),
    ),
  );
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 112,
        child: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(child: Text(value)),
    ],
  );
}

String _readinessLabel(String id, AppLocalizations strings) => switch (id) {
  'state_db' => strings.gatewayStateDatabaseLabel,
  'config' => strings.gatewayConfigurationLabel,
  'model' => strings.gatewayModelReadinessLabel,
  'disk' => strings.gatewayDiskReadinessLabel,
  'gateway' => strings.gatewayRuntimeReadinessLabel,
  'background_queues' => strings.gatewayBackgroundQueuesLabel,
  _ => boundedHermesMetadataText(id, 80),
};

String _readinessValue(
  HermesGatewayReadinessCheck check,
  AppLocalizations strings,
) {
  final parts = <String>[
    check.status.toLowerCase() == 'ok'
        ? strings.gatewayHealthy
        : strings.gatewayNeedsAttention,
    if (check.detail case final detail?) boundedHermesMetadataText(detail, 160),
    if (check.usedPercent case final usedPercent?)
      strings.gatewayReadinessDiskUsage(usedPercent.toStringAsFixed(1)),
    if (check.runtimeState case final state?)
      boundedHermesMetadataText(state, 80),
    if (check.connectedPlatforms case final connected?
        when check.configuredPlatforms != null)
      strings.gatewayReadinessPlatformCounts(
        connected,
        check.configuredPlatforms!,
      ),
    if (check.activeApiRuns case final activeRuns?
        when check.processCompletions != null &&
            check.activeDelegations != null)
      strings.gatewayReadinessQueueCounts(
        activeRuns,
        check.processCompletions!,
        check.activeDelegations!,
      ),
  ];
  return parts.join(' · ');
}

bool _detailedHealthAdvertised(HermesChannelState state) =>
    state.status == HermesConnectionStatus.connected &&
    !state.isSelectingProfile &&
    state.canReadDetailedHealth;
