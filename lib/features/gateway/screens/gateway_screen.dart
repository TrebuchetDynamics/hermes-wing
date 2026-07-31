import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/models/hermes_health.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/wing_empty_state.dart';
import '../../../shared/widgets/wing_skeleton.dart';
import '../../hermes_chat/gateways/hermes_gateway_directory.dart';
import '../../hermes_chat/providers/hermes_channel_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(hermesChannelProvider);
    final directory = ref.watch(hermesGatewayDirectoryProvider);
    final strings = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([channel, directory]),
      builder: (context, _) {
        final canRefresh = _detailedHealthAdvertised(channel.state);
        return Scaffold(
          appBar: AppBar(
            title: Text(strings.gatewayStatusTitle),
            actions: [
              if (canRefresh)
                IconButton(
                  key: const ValueKey('gateway-refresh-button'),
                  tooltip: strings.gatewayStatusRefreshTooltip,
                  onPressed: _refreshing
                      ? null
                      : () => unawaited(_refresh(channel)),
                  icon: _refreshing
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                ),
            ],
          ),
          body: Column(
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
                child: _GatewayBody(
                  state: channel.state,
                  strings: strings,
                  refreshFailed: _refreshFailed,
                ),
              ),
            ],
          ),
        );
      },
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
            key: const ValueKey('gateway-status-picker'),
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
          Text(strings.gatewayStatusHelp),
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
      _refreshFailed = false;
    });
    try {
      await directory.activateGateway(gatewayId);
    } catch (_) {
      if (mounted) setState(() => _actionError = strings.gatewayConnectFailed);
    } finally {
      if (mounted) setState(() => _switchingGatewayId = null);
    }
  }

  Future<void> _refresh(HermesChannel channel) async {
    setState(() {
      _refreshing = true;
      _refreshFailed = false;
    });
    try {
      await channel.loadDetailedHealth();
    } catch (_) {
      if (mounted) setState(() => _refreshFailed = true);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }
}

class _GatewayBody extends StatelessWidget {
  const _GatewayBody({
    required this.state,
    required this.strings,
    required this.refreshFailed,
  });

  final HermesChannelState state;
  final AppLocalizations strings;
  final bool refreshFailed;

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
    if (!_detailedHealthAdvertised(state)) {
      return WingEmptyState(
        icon: Icons.lock_outline,
        title: strings.gatewayStatusUnavailableTitle,
        body: strings.gatewayStatusUnavailableBody,
      );
    }
    final health = state.detailedHealth;
    if (refreshFailed ||
        state.optionalResourceErrors.containsKey(
          HermesOptionalResource.detailedHealth,
        ) ||
        health == null) {
      return WingEmptyState(
        icon: Icons.sync_problem_outlined,
        title: strings.gatewayStatusUnavailableTitle,
        body: strings.gatewayStatusLoadFailedBody,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Text(
          strings.gatewayStatusTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(strings.gatewayStatusSubtitle),
        const SizedBox(height: 16),
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.visibility_outlined),
                const SizedBox(width: 12),
                Expanded(child: Text(strings.gatewayStatusReadOnlyNote)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _HealthCard(health: health, strings: strings),
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
  const _HealthCard({required this.health, required this.strings});

  final HermesHealthStatus health;
  final AppLocalizations strings;

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
              value: _safePreview(health.platform, 80),
            ),
            if (health.version?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: 10),
              _StatusRow(
                label: strings.gatewayVersionLabel,
                value: _safePreview(health.version!, 80),
              ),
            ],
            if (health.gatewayState?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: 10),
              _StatusRow(
                label: strings.gatewayRuntimeStateLabel,
                value: _safePreview(health.gatewayState!, 80),
              ),
            ],
            const SizedBox(height: 10),
            _StatusRow(
              label: strings.gatewayActiveAgentsLabel,
              value: health.activeAgents.toString(),
            ),
            if (health.gatewayBusy case final busy?) ...[
              const SizedBox(height: 10),
              _StatusRow(
                label: strings.gatewayWorkStateLabel,
                value: busy ? strings.gatewayBusy : strings.gatewayIdle,
              ),
            ],
            if (health.gatewayDrainable case final drainable?) ...[
              const SizedBox(height: 10),
              _StatusRow(
                label: strings.gatewayDrainableLabel,
                value: drainable ? strings.gatewayYes : strings.gatewayNo,
              ),
            ],
            if (health.updatedAt case final updatedAt?) ...[
              const SizedBox(height: 10),
              _StatusRow(
                label: strings.gatewayUpdatedLabel,
                value: _safePreview(updatedAt, 80),
              ),
            ],
            if (health.pid case final pid?) ...[
              const SizedBox(height: 10),
              _StatusRow(
                label: strings.gatewayProcessIdLabel,
                value: pid.toString(),
              ),
            ],
            if (health.exitReason case final exitReason?) ...[
              const SizedBox(height: 10),
              _StatusRow(
                label: strings.gatewayExitReasonLabel,
                value: _safePreview(exitReason, 160),
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
              label: _safePreview(platforms[index].name, 80),
              value: _safePreview(platforms[index].status, 80),
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
  _ => _safePreview(id, 80),
};

String _readinessValue(
  HermesGatewayReadinessCheck check,
  AppLocalizations strings,
) {
  final parts = <String>[
    check.status.toLowerCase() == 'ok'
        ? strings.gatewayHealthy
        : strings.gatewayNeedsAttention,
    if (check.detail case final detail?) _safePreview(detail, 160),
    if (check.usedPercent case final usedPercent?)
      strings.gatewayReadinessDiskUsage(usedPercent.toStringAsFixed(1)),
    if (check.runtimeState case final state?) _safePreview(state, 80),
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

String _safePreview(String value, int maxLength) {
  final normalized = value
      .replaceAll(RegExp(r'[\u0000-\u001f\u007f]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (normalized.length <= maxLength) return normalized;
  return '${normalized.substring(0, maxLength - 1)}…';
}
