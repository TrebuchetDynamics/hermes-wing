import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/setup/hermes_endpoint_store.dart';
import '../../../core/hermes/models/hermes_health.dart';
import '../../../core/hermes/models/hermes_metadata_text.dart';
import '../../../core/wing_link/models/wing_link_device.dart';
import '../../../core/wing_link/wing_link_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/wing_empty_state.dart';
import '../../../shared/widgets/wing_gateway_switch.dart';
import '../../../shared/widgets/wing_skeleton.dart';
import '../../hermes_chat/gateways/hermes_gateway_directory.dart';
import '../../hermes_chat/providers/hermes_channel_provider.dart';
import '../widgets/saved_connections_section.dart';

typedef GatewayWingLinkClientBuilder =
    WingLinkClient Function(HermesEndpointConfig config);

/// Gateway-selected, bounded, read-only health. Lifecycle, logs, and messaging
/// platform administration are deliberately absent until dedicated scoped
/// contracts are advertised.
class GatewayScreen extends ConsumerStatefulWidget {
  const GatewayScreen({super.key, this.wingLinkClientBuilder});

  final GatewayWingLinkClientBuilder? wingLinkClientBuilder;

  @override
  ConsumerState<GatewayScreen> createState() => _GatewayScreenState();
}

class _GatewayScreenState extends ConsumerState<GatewayScreen> {
  String? _switchingGatewayId;
  String? _actionError;
  bool _refreshing = false;
  bool _refreshFailed = false;
  bool _disconnecting = false;
  bool _revokingDevice = false;
  bool _deviceRevoked = false;
  bool _approvalPending = false;
  int _refreshGeneration = 0;
  String? _refreshBaseUrl;
  String? _trustGatewayId;
  HermesEndpointConfig? _trustConfig;
  Future<_WingLinkTrustState>? _trustFuture;

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(hermesChannelProvider);
    final directory = ref.watch(hermesGatewayDirectoryProvider);
    final strings = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([channel, directory]),
      builder: (context, _) {
        final activeGatewayId = directory.managementGatewayId;
        final selectedHost = directory.hosts
            .where((host) => host.containsGateway(activeGatewayId))
            .firstOrNull;
        final connectedGatewayId = directory.activeContactId?.gatewayId;
        final selectedChat =
            connectedGatewayId == activeGatewayId ||
            selectedHost?.containsGateway(connectedGatewayId) == true;
        final chatConnected = selectedChat && channel.state.isConnected;
        final canRefresh =
            chatConnected && _detailedHealthAdvertised(channel.state);
        final refreshing =
            _refreshing && channel.state.connectedBaseUrl == _refreshBaseUrl;
        final activeGateway = activeGatewayId == null
            ? null
            : directory.gateways
                  .where((gateway) => gateway.id == activeGatewayId)
                  .firstOrNull;
        final activeConfig = activeGatewayId == null
            ? null
            : directory.configForGateway(activeGatewayId);
        final trustFuture =
            activeGatewayId == null ||
                activeConfig == null ||
                (activeConfig.wingLinkOrigin?.isEmpty ?? true) ||
                (activeConfig.wingLinkToken?.isEmpty ?? true)
            ? null
            : _trustFor(activeGatewayId, activeConfig);
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
                IconButton(
                  key: const ValueKey('gateway-refresh-button'),
                  tooltip: strings.gatewayStatusRefreshTooltip,
                  onPressed: refreshing
                      ? null
                      : () => unawaited(_refresh(channel)),
                  icon: refreshing
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
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
                              Text(
                                trustFuture != null
                                    ? strings.gatewayManagementIndependent
                                    : strings.gatewaySavedConnectionHelp,
                              ),
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
                    if (trustFuture != null && activeConfig != null)
                      _WingLinkTrustCard(
                        future: trustFuture,
                        strings: strings,
                        revoked: _deviceRevoked,
                        approvalPending: _approvalPending,
                        revoking: _revokingDevice,
                        onRevoke: () => unawaited(
                          _confirmSelfRevoke(activeConfig, strings),
                        ),
                      ),
                    if (selectedChat &&
                        channel.state.status !=
                            HermesConnectionStatus.disconnected)
                      _GatewayBody(
                        state: channel.state,
                        strings: strings,
                        refreshFailed: _refreshFailed,
                        onRetry: () => unawaited(_refresh(channel)),
                        trust: null,
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

  WingLinkClient _wingLinkClient(HermesEndpointConfig config) {
    final builder = widget.wingLinkClientBuilder;
    if (builder != null) return builder(config);
    return WingLinkClient(
      origin: Uri.parse(config.wingLinkOrigin!),
      token: config.wingLinkToken!,
      hostFingerprint: config.wingLinkHostFingerprint,
    );
  }

  Future<_WingLinkTrustState> _trustFor(
    String gatewayId,
    HermesEndpointConfig config,
  ) {
    if (config.wingLinkOrigin == null || config.wingLinkToken == null) {
      return Future.error(
        const WingLinkException('Wing Link is not configured'),
      );
    }
    if (_trustGatewayId != gatewayId ||
        _trustConfig != config ||
        _trustFuture == null) {
      _trustGatewayId = gatewayId;
      _trustConfig = config;
      _deviceRevoked = false;
      _approvalPending = false;
      _trustFuture = _loadTrust(_wingLinkClient(config), config);
    }
    return _trustFuture!;
  }

  Future<_WingLinkTrustState> _loadTrust(
    WingLinkClient client,
    HermesEndpointConfig config,
  ) async {
    try {
      final values = await Future.wait<Object>([
        client.getMetadata(),
        client.getCurrentDevice(),
      ]);
      final metadata = values[0] as WingLinkMetadata;
      final savedFingerprint = config.wingLinkHostFingerprint;
      if (savedFingerprint != null &&
          metadata.hostFingerprint != savedFingerprint) {
        throw const _WingLinkTrustLoadException(
          _WingLinkTrustFailure.changedIdentity,
        );
      }
      return _WingLinkTrustState(
        metadata: metadata,
        device: values[1] as WingLinkDevice,
      );
    } on WingLinkUpgradeRequired {
      throw const _WingLinkTrustLoadException(
        _WingLinkTrustFailure.upgradeRequired,
      );
    } catch (error) {
      if (error is _WingLinkTrustLoadException) rethrow;
      if (error is WingLinkHttpException && error.statusCode == 401) {
        throw const _WingLinkTrustLoadException(
          _WingLinkTrustFailure.credentialExpired,
        );
      }
      rethrow;
    }
  }

  Future<void> _confirmSelfRevoke(
    HermesEndpointConfig config,
    AppLocalizations strings,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.gatewayTrustRevokeTitle),
        content: Text(strings.gatewayTrustRevokeBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancelAction),
          ),
          FilledButton(
            key: const ValueKey('gateway-trust-revoke-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.gatewayTrustRevokeAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _revokingDevice = true);
    try {
      await _wingLinkClient(config).revokeCurrentDevice();
      final gatewayId = config.id;
      if (gatewayId == null || gatewayId.isEmpty) {
        throw StateError('Saved gateway identity is unavailable.');
      }
      await ref
          .read(hermesGatewayDirectoryProvider)
          .clearWingLinkEnrollment(gatewayId);
      if (mounted) {
        setState(() => _deviceRevoked = true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.gatewayTrustRevoked)));
      }
    } on WingLinkApprovalRequired {
      if (mounted) setState(() => _approvalPending = true);
    } catch (_) {
      if (mounted) {
        setState(() => _actionError = strings.gatewayTrustUnavailable);
      }
    } finally {
      if (mounted) setState(() => _revokingDevice = false);
    }
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
    await completeWingGatewaySwitch(
      context: context,
      directory: directory,
      gatewayId: gatewayId,
      onFailure: () =>
          setState(() => _actionError = strings.gatewayConnectFailed),
      onFinished: () => setState(() {
        _switchingGatewayId = null;
        if (directory.activeContactId?.gatewayId != gatewayId) {
          _actionError = strings.gatewayConnectFailed;
        }
      }),
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

  Future<void> _refresh(HermesChannel channel) async {
    final generation = ++_refreshGeneration;
    final connectedBaseUrl = channel.state.connectedBaseUrl;
    bool isCurrent() =>
        mounted &&
        generation == _refreshGeneration &&
        channel.state.isConnected &&
        channel.state.connectedBaseUrl == connectedBaseUrl;
    setState(() {
      _refreshing = true;
      _refreshBaseUrl = connectedBaseUrl;
      _refreshFailed = false;
    });
    try {
      await channel.loadDetailedHealth();
    } catch (_) {
      if (isCurrent()) setState(() => _refreshFailed = true);
    } finally {
      if (isCurrent()) {
        setState(() {
          _refreshing = false;
          _refreshBaseUrl = null;
        });
      }
    }
  }
}

class _GatewayBody extends StatelessWidget {
  const _GatewayBody({
    required this.state,
    required this.strings,
    required this.refreshFailed,
    required this.onRetry,
    required this.trust,
  });

  final HermesChannelState state;
  final AppLocalizations strings;
  final bool refreshFailed;
  final VoidCallback onRetry;
  final Widget? trust;

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
    final detailedFailed =
        refreshFailed ||
        state.optionalResourceErrors.containsKey(
          HermesOptionalResource.detailedHealth,
        );
    final health = detailedAdvertised && !detailedFailed
        ? state.detailedHealth ?? state.basicHealth
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
        : detailedFailed || state.detailedHealth == null
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
        if (trust case final trust?) ...[const SizedBox(height: 16), trust],
      ],
    );
  }
}

enum _WingLinkTrustFailure {
  changedIdentity,
  upgradeRequired,
  credentialExpired,
}

class _WingLinkTrustLoadException implements Exception {
  const _WingLinkTrustLoadException(this.failure);

  final _WingLinkTrustFailure failure;
}

class _WingLinkTrustState {
  const _WingLinkTrustState({required this.metadata, required this.device});

  final WingLinkMetadata metadata;
  final WingLinkDevice device;
}

class _WingLinkTrustCard extends StatelessWidget {
  const _WingLinkTrustCard({
    required this.future,
    required this.strings,
    required this.revoked,
    required this.approvalPending,
    required this.revoking,
    required this.onRevoke,
  });

  final Future<_WingLinkTrustState> future;
  final AppLocalizations strings;
  final bool revoked;
  final bool approvalPending;
  final bool revoking;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) => Card(
    key: const ValueKey('gateway-trust-card'),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<_WingLinkTrustState>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Semantics(
              liveRegion: true,
              child: Text(strings.gatewayTrustLoading),
            );
          }
          final trust = snapshot.data;
          if (trust == null) {
            final error = snapshot.error;
            final message = switch (error) {
              _WingLinkTrustLoadException(
                failure: _WingLinkTrustFailure.changedIdentity,
              ) =>
                strings.gatewayTrustChangedIdentity,
              _WingLinkTrustLoadException(
                failure: _WingLinkTrustFailure.upgradeRequired,
              ) =>
                strings.gatewayTrustUpgradeRequired,
              _WingLinkTrustLoadException(
                failure: _WingLinkTrustFailure.credentialExpired,
              ) =>
                strings.gatewayTrustCredentialExpired,
              _ => strings.gatewayTrustUnavailable,
            };
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.gatewayTrustTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    message,
                    key: const ValueKey('gateway-trust-error'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(strings.gatewayTrustHostInstructions),
              ],
            );
          }
          final metadata = trust.metadata;
          final device = trust.device;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.gatewayTrustTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _StatusRow(label: strings.gatewayTrustDevice, value: device.name),
              ExpansionTile(
                key: const PageStorageKey('gateway-trust-details'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 12),
                shape: const Border(),
                collapsedShape: const Border(),
                title: Text(strings.gatewayTrustDetails),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusRow(
                    label: strings.gatewayTrustFingerprint,
                    value: metadata.hostFingerprint,
                  ),
                  const SizedBox(height: 10),
                  _StatusRow(
                    label: strings.gatewayTrustProtocol,
                    value:
                        'v${metadata.protocolGeneration} · ${metadata.supportedProtocolGenerations.join(', ')}',
                  ),
                  const SizedBox(height: 10),
                  _StatusRow(
                    label: strings.gatewayTrustDevice,
                    value: '${device.name} · ${device.id}',
                  ),
                  const SizedBox(height: 10),
                  _StatusRow(
                    label: strings.gatewayTrustScopes,
                    value: device.scopes.join(', '),
                  ),
                  const SizedBox(height: 12),
                  Text(strings.gatewayTrustHostInstructions),
                ],
              ),
              const SizedBox(height: 12),
              if (approvalPending)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    strings.gatewayTrustApprovalPending,
                    key: const ValueKey('gateway-trust-approval-pending'),
                  ),
                )
              else if (revoked)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    strings.gatewayTrustRevoked,
                    key: const ValueKey('gateway-trust-revoked'),
                  ),
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    key: const ValueKey('gateway-trust-revoke'),
                    onPressed: revoking ? null : onRevoke,
                    icon: revoking
                        ? SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              semanticsLabel: strings.gatewayTrustRevoking,
                            ),
                          )
                        : const Icon(Icons.phonelink_erase_outlined),
                    label: Text(strings.gatewayTrustRevokeAction),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
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
    state.canReadDetailedHealth;
