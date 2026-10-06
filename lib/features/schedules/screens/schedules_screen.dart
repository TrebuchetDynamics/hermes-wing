import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/models/hermes_job.dart';
import '../../../core/hermes/models/hermes_metadata_text.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/wing_empty_state.dart';
import '../../../shared/widgets/wing_metadata.dart';
import '../../../shared/widgets/wing_gateway_picker.dart';
import '../../../shared/widgets/wing_gateway_switch.dart';
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
  final _searchController = TextEditingController();
  final _clearFocusNode = FocusNode();
  _ScheduleFilter _filter = _ScheduleFilter.all;
  String? _switchingGatewayId;
  String? _actionError;
  bool _refreshing = false;
  int _refreshGeneration = 0;
  bool _refreshFailed = false;
  HermesChannel? _jobsChannel;
  Object? _jobsContext;
  Object _jobsOwner = Object();

  @override
  void dispose() {
    _jobsChannel?.removeListener(_jobsOwnerChanged);
    _searchController.dispose();
    _clearFocusNode.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _filter = _ScheduleFilter.all;
    });
  }

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(hermesChannelProvider);
    _bindJobsOwner(channel);
    ref.listen(hermesChannelProvider, (previous, next) {
      if (!identical(previous, next)) {
        setState(() => _bindJobsOwner(next));
      }
    });
    final directory = ref.watch(hermesGatewayDirectoryProvider);
    final strings = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([channel, directory]),
      builder: (context, _) {
        final owner = _jobsOwner;
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
                      : () => unawaited(_refresh(channel, owner)),
                  icon: _refreshing
                      ? SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            semanticsLabel: strings.schedulesRefreshing,
                          ),
                        )
                      : const Icon(Icons.refresh),
                ),
              const AppShellMenuButton(),
            ],
          ),
          body: SafeArea(
            top: false,
            child: Column(
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
                  child: _SchedulesBody(
                    key: ObjectKey(owner),
                    state: channel.state,
                    strings: strings,
                    refreshFailed: _refreshFailed,
                    onRetry: () => _refresh(channel, owner),
                    searchController: _searchController,
                    query: _searchController.text,
                    filter: _filter,
                    onQueryChanged: (_) => setState(() {}),
                    onFilterChanged: (value) => setState(() => _filter = value),
                    clearFocusNode: _clearFocusNode,
                    onClear: () {
                      _clearFocusNode.requestFocus();
                      _clearFilters();
                    },
                  ),
                ),
              ],
            ),
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
      _refreshGeneration++;
      _refreshing = false;
      _actionError = null;
      _refreshFailed = false;
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

  void _bindJobsOwner(HermesChannel channel) {
    if (!identical(channel, _jobsChannel)) {
      _jobsChannel?.removeListener(_jobsOwnerChanged);
      _jobsChannel = channel;
      _jobsContext = null;
      channel.addListener(_jobsOwnerChanged);
    }
    _syncJobsOwner();
  }

  bool _syncJobsOwner() {
    final channel = _jobsChannel!;
    final state = channel.state;
    final context = (
      channel,
      state.connectedBaseUrl,
      state.selectedProfileId,
      state.status,
      state.isSelectingProfile,
      _jobsAdvertised(state),
    );
    if (_jobsContext == context) return false;
    _jobsContext = context;
    _jobsOwner = Object();
    _refreshGeneration++;
    _refreshing = false;
    _refreshFailed = false;
    _searchController.clear();
    _filter = _ScheduleFilter.all;
    return true;
  }

  void _jobsOwnerChanged() {
    // Observe loss/restoration synchronously, even if both precede a rebuild.
    // Inventory updates and equivalent capability documents keep local controls.
    if (_syncJobsOwner() && mounted) setState(() {});
  }

  bool _isJobsOwner(HermesChannel channel, Object owner) {
    if (!mounted) return false;
    final current = ref.read(hermesChannelProvider);
    _bindJobsOwner(current);
    return identical(channel, current) &&
        identical(owner, _jobsOwner) &&
        _jobsAdvertised(current.state);
  }

  Future<void> _refresh(HermesChannel channel, Object owner) async {
    if (!_isJobsOwner(channel, owner) || _refreshing) return;
    final generation = ++_refreshGeneration;
    setState(() {
      _refreshing = true;
      _refreshFailed = false;
    });
    try {
      await channel.loadJobs();
    } catch (_) {
      if (_isJobsOwner(channel, owner) && generation == _refreshGeneration) {
        setState(() => _refreshFailed = true);
      }
    } finally {
      if (_isJobsOwner(channel, owner) && generation == _refreshGeneration) {
        setState(() => _refreshing = false);
      }
    }
  }
}

class _SchedulesBody extends StatelessWidget {
  const _SchedulesBody({
    super.key,
    required this.state,
    required this.strings,
    required this.refreshFailed,
    required this.onRetry,
    required this.searchController,
    required this.query,
    required this.filter,
    required this.onQueryChanged,
    required this.onFilterChanged,
    required this.onClear,
    required this.clearFocusNode,
  });

  final HermesChannelState state;
  final AppLocalizations strings;
  final bool refreshFailed;
  final Future<void> Function() onRetry;
  final TextEditingController searchController;
  final String query;
  final _ScheduleFilter filter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<_ScheduleFilter> onFilterChanged;
  final VoidCallback onClear;
  final FocusNode clearFocusNode;

  @override
  Widget build(BuildContext context) {
    if (state.status == HermesConnectionStatus.connecting) {
      return WingSkeletonList(semanticLabel: strings.schedulesLoading);
    }
    if (state.status != HermesConnectionStatus.connected) {
      if (state.status == HermesConnectionStatus.error) {
        return WingEmptyState(
          icon: Icons.cloud_off_outlined,
          liveRegion: true,
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
        liveRegion: true,
        title: strings.schedulesUnavailableTitle,
        body: strings.schedulesLoadFailedBody,
        actionLabel: strings.retryAction,
        onAction: onRetry,
      );
    }

    final normalizedQuery = query.trim().toLowerCase();
    final jobs = state.jobs.where((job) {
      final matchesEnabled = switch (filter) {
        _ScheduleFilter.all => true,
        _ScheduleFilter.enabled => job.enabled,
        _ScheduleFilter.disabled => !job.enabled,
      };
      return matchesEnabled &&
          [
            boundedHermesMetadataText(job.displayName, 120),
            boundedHermesMetadataText(job.id, 128),
            boundedHermesMetadataText(job.scheduleDisplay ?? '', 160),
          ].any((value) => value.toLowerCase().contains(normalizedQuery));
    }).toList()..sort(_compareJobs);
    return RefreshIndicator(
      onRefresh: onRetry,
      semanticsLabel: strings.schedulesRefreshing,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          Text(
            strings.schedulesSubtitle,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.visibility_outlined, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.schedulesReadOnlyNote,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            key: const ValueKey('schedules-search'),
            controller: searchController,
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              labelText: strings.schedulesSearchLabel,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Text(strings.schedulesFilterLabel),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final option in _ScheduleFilter.values)
                ChoiceChip(
                  label: Text(switch (option) {
                    _ScheduleFilter.all => strings.schedulesFilterAll,
                    _ScheduleFilter.enabled => strings.scheduleEnabled,
                    _ScheduleFilter.disabled => strings.scheduleDisabled,
                  }),
                  selected: filter == option,
                  onSelected: (_) => onFilterChanged(option),
                ),
              TextButton.icon(
                key: const ValueKey('schedules-clear-filters'),
                focusNode: clearFocusNode,
                // Keep reset idempotent and focus stable. Disabling the focused
                // button can restore a detached browser text-editing client.
                onPressed: onClear,
                icon: const Icon(Icons.clear),
                label: Text(strings.schedulesClearFilters),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (state.jobs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: WingEmptyState(
                icon: Icons.event_available_outlined,
                title: strings.schedulesEmptyTitle,
                body: strings.schedulesEmptyBody,
                actionLabel: strings.schedulesRefreshTooltip,
                onAction: onRetry,
              ),
            )
          else if (jobs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: WingEmptyState(
                icon: Icons.search_off,
                liveRegion: true,
                title: strings.schedulesNoMatchesTitle,
                body: strings.schedulesNoMatchesBody,
              ),
            )
          else
            for (final job in jobs) ...[
              _ScheduleCard(job: job, strings: strings),
              const SizedBox(height: 12),
            ],
        ],
      ),
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
    final title = Text(
      boundedHermesMetadataText(job.displayName, 120),
      style: Theme.of(context).textTheme.titleMedium,
    );
    final status = WingMetadata(label: Text(stateLabel));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final largeText =
                    MediaQuery.textScalerOf(context).scale(1) > 1.3;
                if (constraints.maxWidth < 280 || largeText) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, const SizedBox(height: 10), status],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: 12),
                    status,
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            _ScheduleDetail(
              label: strings.scheduleIdLabel,
              value: boundedHermesMetadataText(job.id, 128),
            ),
            if (schedule != null && schedule.isNotEmpty) ...[
              const SizedBox(height: 10),
              _ScheduleDetail(
                label: strings.scheduleExpressionLabel,
                value: boundedHermesMetadataText(schedule, 160),
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
    state.status == HermesConnectionStatus.connected &&
    !state.isSelectingProfile &&
    state.canReadJobs;

enum _ScheduleFilter { all, enabled, disabled }

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
    'error' => strings.scheduleError,
    _ => job.enabled ? strings.scheduleEnabled : strings.scheduleDisabled,
  };
}

String? _formatTimestamp(BuildContext context, String? source) {
  if (source == null || source.trim().isEmpty) return null;
  final parsed = DateTime.tryParse(source);
  if (parsed == null) return boundedHermesMetadataText(source, 96);
  final local = parsed.toLocal();
  final material = MaterialLocalizations.of(context);
  final date = material.formatMediumDate(local);
  final time = material.formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  return '$date, $time';
}
