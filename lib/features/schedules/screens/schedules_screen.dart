import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/models/hermes_job.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/wing_empty_state.dart';
import '../../../shared/widgets/wing_gateway_picker.dart';
import '../../../shared/widgets/wing_skeleton.dart';
import '../../hermes_chat/gateways/hermes_gateway_directory.dart';
import '../../hermes_chat/providers/hermes_channel_provider.dart';

/// Gateway- and profile-scoped read-only schedule inventory. Mutating jobs and
/// Kanban tasks remains hidden until Hermes advertises exact scoped contracts
/// for those operations.
class SchedulesScreen extends ConsumerStatefulWidget {
  const SchedulesScreen({super.key});

  @override
  ConsumerState<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends ConsumerState<SchedulesScreen> {
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
        final canRefresh = _jobsAdvertised(channel.state);
        return Scaffold(
          appBar: AppBar(
            title: Text(strings.schedulesTitle),
            actions: [
              if (canRefresh)
                IconButton(
                  key: const ValueKey('schedules-refresh-button'),
                  tooltip: strings.schedulesRefreshTooltip,
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
              const AppShellMenuButton(),
            ],
          ),
          body: Column(
            children: [
              if (directory.gateways.isNotEmpty)
                WingGatewayPicker(
                  fieldKey: const ValueKey('schedules-gateway-picker'),
                  directory: directory,
                  helpText: strings.schedulesGatewayHelp,
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
                child: _SchedulesBody(
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
      await channel.loadJobs();
    } catch (_) {
      if (mounted) setState(() => _refreshFailed = true);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }
}

class _SchedulesBody extends StatelessWidget {
  const _SchedulesBody({
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
      return WingSkeletonList(semanticLabel: strings.schedulesLoading);
    }
    if (state.status != HermesConnectionStatus.connected) {
      if (state.status == HermesConnectionStatus.error) {
        return WingEmptyState(
          icon: Icons.cloud_off_outlined,
          title: strings.schedulesUnavailableTitle,
          body: strings.schedulesConnectionErrorBody,
        );
      }
      return WingEmptyState(
        icon: Icons.hub_outlined,
        title: strings.gatewaySelectPromptTitle,
        body: strings.schedulesConnectionRequiredBody,
      );
    }
    if (!_jobsAdvertised(state)) {
      return WingEmptyState(
        icon: Icons.lock_outline,
        title: strings.schedulesUnavailableTitle,
        body: strings.schedulesUnavailableBody,
      );
    }
    if (refreshFailed ||
        state.optionalResourceErrors.containsKey(HermesOptionalResource.jobs)) {
      return WingEmptyState(
        icon: Icons.sync_problem_outlined,
        title: strings.schedulesUnavailableTitle,
        body: strings.schedulesLoadFailedBody,
      );
    }

    final jobs = [...state.jobs]..sort(_compareJobs);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Text(
          strings.schedulesTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(strings.schedulesSubtitle),
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
                Expanded(child: Text(strings.schedulesReadOnlyNote)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (jobs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
            child: Text(
              strings.schedulesEmptyBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          )
        else
          for (final job in jobs) ...[
            _ScheduleCard(job: job, strings: strings),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.job, required this.strings});

  final HermesJob job;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final stateLabel = _jobState(job, strings);
    final schedule = job.scheduleDisplay?.trim();
    final nextRun = _formatTimestamp(context, job.nextRunAt);
    final lastRun = _formatTimestamp(context, job.lastRunAt);
    final hasError = job.lastError?.trim().isNotEmpty ?? false;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _safePreview(job.displayName, 120),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 12),
                Chip(label: Text(stateLabel)),
              ],
            ),
            if (schedule != null && schedule.isNotEmpty) ...[
              const SizedBox(height: 10),
              _ScheduleDetail(
                label: strings.scheduleExpressionLabel,
                value: _safePreview(schedule, 160),
              ),
            ],
            if (nextRun != null) ...[
              const SizedBox(height: 8),
              _ScheduleDetail(
                label: strings.scheduleNextRunLabel,
                value: nextRun,
              ),
            ],
            if (lastRun != null) ...[
              const SizedBox(height: 8),
              _ScheduleDetail(
                label: strings.scheduleLastRunLabel,
                value: lastRun,
              ),
            ],
            if (hasError) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(strings.scheduleLastErrorNotice)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScheduleDetail extends StatelessWidget {
  const _ScheduleDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 88,
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

bool _jobsAdvertised(HermesChannelState state) =>
    state.status == HermesConnectionStatus.connected && state.canReadJobs;

int _compareJobs(HermesJob a, HermesJob b) {
  if (a.enabled != b.enabled) return a.enabled ? -1 : 1;
  final aNext = DateTime.tryParse(a.nextRunAt ?? '');
  final bNext = DateTime.tryParse(b.nextRunAt ?? '');
  if (aNext != null && bNext != null) {
    final comparison = aNext.compareTo(bNext);
    if (comparison != 0) return comparison;
  } else if (aNext != null) {
    return -1;
  } else if (bNext != null) {
    return 1;
  }
  return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
}

String _jobState(HermesJob job, AppLocalizations strings) {
  return switch (job.state?.trim().toLowerCase()) {
    'active' => strings.scheduleActive,
    'paused' => strings.schedulePaused,
    'completed' => strings.scheduleCompleted,
    _ => job.enabled ? strings.scheduleEnabled : strings.scheduleDisabled,
  };
}

String? _formatTimestamp(BuildContext context, String? source) {
  if (source == null || source.trim().isEmpty) return null;
  final parsed = DateTime.tryParse(source);
  if (parsed == null) return _safePreview(source, 96);
  final local = parsed.toLocal();
  final material = MaterialLocalizations.of(context);
  final date = material.formatMediumDate(local);
  final time = material.formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  return '$date, $time';
}

String _safePreview(String value, int maxLength) {
  final normalized = value
      .replaceAll(RegExp(r'[\u0000-\u001f\u007f]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (normalized.length <= maxLength) return normalized;
  return '${normalized.substring(0, maxLength - 1)}…';
}
