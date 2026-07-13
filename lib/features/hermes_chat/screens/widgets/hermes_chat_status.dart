part of '../hermes_chat_screen.dart';

class _HermesCapabilityStrip extends StatelessWidget {
  const _HermesCapabilityStrip({
    required this.capabilities,
    this.detailedHealth,
    this.models = const [],
    this.skills = const [],
    this.enabledToolsets = const [],
    this.jobs = const [],
    this.optionalResourceErrors = const {},
  });

  final HermesCapabilityDocument capabilities;
  final HermesHealthStatus? detailedHealth;
  final List<String> models;
  final List<String> skills;
  final List<String> enabledToolsets;
  final List<HermesJob> jobs;
  final Map<HermesOptionalResource, String> optionalResourceErrors;

  void _showList(BuildContext context, String title, List<String> items) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final item in items)
                ListTile(
                  title: Text(
                    _safeHermesUiPreview(item, maxLength: 96),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showOptionalResourceErrors(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unavailable Hermes inventory'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in optionalResourceErrors.entries)
              ListTile(
                title: Text(_optionalResourceLabel(entry.key)),
                subtitle: Text(_safeHermesUiError(entry.value)),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _optionalResourceLabel(HermesOptionalResource resource) =>
      switch (resource) {
        HermesOptionalResource.detailedHealth => 'Detailed health',
        HermesOptionalResource.models => 'Models',
        HermesOptionalResource.skills => 'Skills',
        HermesOptionalResource.toolsets => 'Toolsets',
        HermesOptionalResource.jobs => 'Jobs',
      };

  void _showJobs(BuildContext context) {
    final jobsAdminAdvertised =
        capabilities.supportsFeature('jobs_admin') &&
        capabilities.advertisesEndpoint('jobs', 'GET', '/api/jobs');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hermes jobs'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  jobsAdminAdvertised
                      ? 'Read-only inventory. Hermes advertises jobs admin, but Navivox has not enabled mobile create/edit/delete scheduling.'
                      : 'Read-only inventory. Mobile create/edit/delete scheduling is not available.',
                  key: const ValueKey('hermes-jobs-read-only-note'),
                ),
              ),
              for (final job in jobs)
                ListTile(
                  title: Text(
                    _safeHermesUiPreview(job.displayName, maxLength: 96),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(_jobSummary(job)),
                  trailing: IconButton(
                    key: ValueKey('hermes-job-copy-${job.id}'),
                    tooltip: 'Copy job details',
                    icon: const Icon(Icons.copy_outlined),
                    onPressed: () {
                      unawaited(
                        Clipboard.setData(
                          ClipboardData(text: _jobDetailsSummary(job)),
                        ),
                      );
                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                        const SnackBar(
                          content: Text('Copied redacted Hermes job details.'),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _jobSummary(HermesJob job) {
    final parts = <String>[
      job.enabled ? 'Enabled' : 'Disabled',
      if (job.state?.trim().isNotEmpty ?? false)
        'State: ${_safeHermesUiPreview(job.state!, maxLength: 48)}',
      if (job.scheduleDisplay?.trim().isNotEmpty ?? false)
        'Schedule: ${_safeHermesUiPreview(job.scheduleDisplay!, maxLength: 80)}',
      if (job.nextRunAt?.trim().isNotEmpty ?? false)
        'Next: ${_safeHermesUiPreview(job.nextRunAt!, maxLength: 48)}',
      if (job.lastRunAt?.trim().isNotEmpty ?? false)
        'Last: ${_safeHermesUiPreview(job.lastRunAt!, maxLength: 48)}',
      if (job.lastError?.trim().isNotEmpty ?? false)
        'Last error: ${_safeHermesUiPreview(job.lastError!, maxLength: 96)}',
    ];
    return parts.join(' • ');
  }

  String _jobDetailsSummary(HermesJob job) {
    final buffer = StringBuffer()
      ..writeln('Hermes job')
      ..writeln(
        'Name: ${_safeHermesUiPreview(job.displayName, maxLength: 120)}',
      )
      ..writeln('ID: ${_safeHermesUiPreview(job.id, maxLength: 120)}')
      ..writeln('Enabled: ${job.enabled}');
    if (job.state?.trim().isNotEmpty ?? false) {
      buffer.writeln(
        'State: ${_safeHermesUiPreview(job.state!, maxLength: 80)}',
      );
    }
    if (job.scheduleDisplay?.trim().isNotEmpty ?? false) {
      buffer.writeln(
        'Schedule: ${_safeHermesUiPreview(job.scheduleDisplay!, maxLength: 120)}',
      );
    }
    if (job.nextRunAt?.trim().isNotEmpty ?? false) {
      buffer.writeln(
        'Next: ${_safeHermesUiPreview(job.nextRunAt!, maxLength: 80)}',
      );
    }
    if (job.lastRunAt?.trim().isNotEmpty ?? false) {
      buffer.writeln(
        'Last: ${_safeHermesUiPreview(job.lastRunAt!, maxLength: 80)}',
      );
    }
    if (job.lastError?.trim().isNotEmpty ?? false) {
      buffer.write(
        'Last error: ${_safeHermesUiPreview(job.lastError!, maxLength: 240)}',
      );
    }
    return buffer.toString().trimRight();
  }

  void _showSurfaceReadiness(BuildContext context) {
    final items = hermesSurfaceReadiness(capabilities);
    final summary = _surfaceReadinessSummary(items);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hermes surface readiness'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'No mobile config, memory, schedule, gateway, or persona mutation controls are enabled.',
                  key: ValueKey('hermes-admin-surfaces-note'),
                ),
              ),
              for (final item in items)
                ListTile(
                  title: Text(item.title),
                  subtitle: Text(item.detail),
                  trailing: Text(item.status.label),
                ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            key: const ValueKey('hermes-surfaces-copy'),
            onPressed: () {
              unawaited(Clipboard.setData(ClipboardData(text: summary)));
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                const SnackBar(
                  content: Text('Copied Hermes surface readiness summary.'),
                ),
              );
            },
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Copy summary'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _surfaceReadinessSummary(List<HermesSurfaceReadiness> items) {
    final buffer = StringBuffer('Hermes surface readiness');
    for (final item in items) {
      buffer.writeln();
      buffer.write(
        '- ${_safeHermesUiPreview(item.title, maxLength: 80)}: ${item.status.label} — ${_safeHermesUiPreview(item.detail, maxLength: 240)}',
      );
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final policy = HermesTransportPolicy(capabilities);
    final surfaceItems = hermesSurfaceReadiness(capabilities);
    final deferredCount = surfaceItems
        .where((item) => item.status == HermesSurfaceStatus.deferred)
        .length;
    final blockedCount = surfaceItems
        .where((item) => item.status == HermesSurfaceStatus.blocked)
        .length;
    final chips = <Widget>[
      if (policy.supportsRunsTransport)
        const Chip(label: Text('Runs SSE enabled')),
      if (!policy.supportsRunsTransport && policy.supportsSessionChatStream)
        const Chip(label: Text('Session chat streaming enabled')),
      const Chip(label: Text('Voice: device STT → Hermes')),
      if (detailedHealth?.version case final version?)
        Chip(
          label: Text(
            'Version: ${_safeHermesUiPreview(version, maxLength: 48)}',
          ),
        ),
      if (detailedHealth?.gatewayState case final gatewayState?)
        Chip(
          label: Text(
            'Gateway: ${_safeHermesUiPreview(gatewayState, maxLength: 48)}',
          ),
        ),
      if (detailedHealth != null)
        Chip(label: Text('Active agents: ${detailedHealth!.activeAgents}')),
      if (models.isNotEmpty)
        ActionChip(
          key: const ValueKey('hermes-models-chip'),
          label: Text(
            'Models: ${models.take(2).map((model) => _safeHermesUiPreview(model, maxLength: 48)).join(', ')}',
          ),
          onPressed: () => _showList(context, 'Hermes models', models),
        ),
      if (skills.isNotEmpty)
        ActionChip(
          key: const ValueKey('hermes-skills-chip'),
          label: Text('Skills: ${skills.length}'),
          onPressed: () => _showList(context, 'Hermes skills', skills),
        ),
      if (enabledToolsets.isNotEmpty)
        ActionChip(
          key: const ValueKey('hermes-toolsets-chip'),
          label: Text('Toolsets enabled: ${enabledToolsets.length}'),
          onPressed: () =>
              _showList(context, 'Hermes toolsets', enabledToolsets),
        ),
      if (jobs.isNotEmpty)
        ActionChip(
          key: const ValueKey('hermes-jobs-chip'),
          label: Text('Jobs: ${jobs.length}'),
          onPressed: () => _showJobs(context),
        ),
      if (optionalResourceErrors.isNotEmpty)
        ActionChip(
          key: const ValueKey('hermes-inventory-errors-chip'),
          avatar: const Icon(Icons.warning_amber_outlined),
          label: Text(
            'Inventory unavailable: ${optionalResourceErrors.length}',
          ),
          onPressed: () => _showOptionalResourceErrors(context),
        ),
      ActionChip(
        key: const ValueKey('hermes-surfaces-chip'),
        label: Text(
          'Surfaces: $deferredCount deferred · $blockedCount blocked',
        ),
        onPressed: () => _showSurfaceReadiness(context),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Card(
        key: const ValueKey('hermes-capability-strip'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Hermes Agent ${_safeHermesUiPreview(capabilities.model, maxLength: 96)}',
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: chips),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApprovalBanner extends StatelessWidget {
  const _ApprovalBanner({
    required this.request,
    required this.pendingCount,
    required this.responding,
    required this.canRespond,
    required this.onDecide,
    required this.onDismissMalformed,
  });

  final HermesApprovalRequest request;
  final int pendingCount;
  final bool responding;
  final bool canRespond;
  final ValueChanged<HermesApprovalDecision> onDecide;
  final VoidCallback onDismissMalformed;

  @override
  Widget build(BuildContext context) {
    final risk = request.risk;
    final hasApprovalId = request.id.trim().isNotEmpty;
    final canAnswer = canRespond && hasApprovalId;
    final colorScheme = Theme.of(context).colorScheme;
    return _AssistantTimelineItem(
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            key: const ValueKey('hermes-approval-banner'),
            color: colorScheme.errorContainer,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security_outlined, color: colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pendingCount > 1
                              ? '$pendingCount pending approvals'
                              : 'Hermes approval requested',
                          key: const ValueKey('hermes-approval-pending-count'),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_safeHermesUiPreview(request.prompt, maxLength: 240)),
                  if (risk != null)
                    Text('Risk: ${_safeHermesUiPreview(risk, maxLength: 120)}'),
                  if (!canRespond) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Hermes did not advertise approval responses for this run.',
                      key: ValueKey('hermes-approval-response-unavailable'),
                    ),
                  ] else if (!hasApprovalId) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Hermes sent this approval without an approval id, so it cannot be answered.',
                      key: ValueKey('hermes-approval-id-missing'),
                    ),
                  ],
                  if (responding) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(
                      key: ValueKey('hermes-approval-responding'),
                    ),
                    const SizedBox(height: 4),
                    const Text('Answering Hermes approval…'),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        key: const ValueKey('hermes-approval-review'),
                        onPressed: responding
                            ? null
                            : () => _showApprovalSheet(context),
                        icon: const Icon(Icons.security_outlined),
                        label: const Text('Review'),
                      ),
                      if (!hasApprovalId)
                        TextButton(
                          key: const ValueKey(
                            'hermes-approval-dismiss-malformed',
                          ),
                          onPressed: responding ? null : onDismissMalformed,
                          child: const Text('Dismiss'),
                        ),
                      TextButton(
                        key: const ValueKey('hermes-approval-deny'),
                        onPressed: responding || !canAnswer
                            ? null
                            : () => onDecide(HermesApprovalDecision.deny),
                        child: const Text('Deny'),
                      ),
                      OutlinedButton(
                        key: const ValueKey('hermes-approval-session'),
                        onPressed: responding || !canAnswer
                            ? null
                            : () => unawaited(_confirmSessionAllow(context)),
                        child: const Text('Allow for session'),
                      ),
                      OutlinedButton(
                        key: const ValueKey('hermes-approval-always'),
                        onPressed: responding || !canAnswer
                            ? null
                            : () => unawaited(_confirmAlwaysAllow(context)),
                        child: const Text('Always allow'),
                      ),
                      FilledButton(
                        key: const ValueKey('hermes-approval-once'),
                        onPressed: responding || !canAnswer
                            ? null
                            : () => onDecide(HermesApprovalDecision.once),
                        child: const Text('Approve once'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSessionAllow(
    BuildContext context, {
    bool closeSheetOnConfirm = false,
  }) async {
    final risk = request.risk;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('hermes-approval-session-confirm-dialog'),
        title: const Text('Allow this for the session?'),
        content: Text(
          '${_safeHermesUiPreview(request.prompt, maxLength: 240)}'
          '${risk == null ? '' : '\nRisk: ${_safeHermesUiPreview(risk, maxLength: 160)}'}\n\n'
          'This may approve matching requests for the current Hermes session.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('hermes-approval-session-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('hermes-approval-session-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Allow for session'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (closeSheetOnConfirm && context.mounted) {
      Navigator.of(context).pop();
    }
    onDecide(HermesApprovalDecision.session);
  }

  Future<void> _confirmAlwaysAllow(
    BuildContext context, {
    bool closeSheetOnConfirm = false,
  }) async {
    final risk = request.risk;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('hermes-approval-always-confirm-dialog'),
        title: const Text('Always allow this Hermes approval?'),
        content: Text(
          '${_safeHermesUiPreview(request.prompt, maxLength: 240)}'
          '${risk == null ? '' : '\nRisk: ${_safeHermesUiPreview(risk, maxLength: 160)}'}\n\n'
          'This may approve matching future requests without asking again.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('hermes-approval-always-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('hermes-approval-always-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Always allow'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (closeSheetOnConfirm && context.mounted) {
      Navigator.of(context).pop();
    }
    onDecide(HermesApprovalDecision.always);
  }

  void _showApprovalSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final risk = request.risk;
        final hasApprovalId = request.id.trim().isNotEmpty;
        final canAnswer = canRespond && hasApprovalId;
        final safePrompt = _safeHermesUiText(request.prompt);
        final promptTruncated = safePrompt.length > 600;
        final safeRisk = risk == null ? null : _safeHermesUiText(risk);
        final riskTruncated = (safeRisk?.length ?? 0) > 240;
        final safeToolCallId = _safeHermesUiText(request.toolCallId);
        final approvalSummary = _approvalReviewSummary(
          safePrompt: safePrompt,
          safeRisk: safeRisk,
          safeToolCallId: safeToolCallId,
          hasApprovalId: hasApprovalId,
        );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              key: const ValueKey('hermes-approval-sheet-scroll'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Review Hermes approval',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  if (pendingCount > 1) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Reviewing 1 of $pendingCount pending approvals',
                      key: const ValueKey(
                        'hermes-approval-sheet-pending-count',
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SelectableText(
                    _safeHermesUiPreview(safePrompt, maxLength: 600),
                    key: const ValueKey('hermes-approval-sheet-prompt'),
                  ),
                  if (promptTruncated)
                    const Text(
                      'Prompt preview truncated for mobile review.',
                      key: ValueKey('hermes-approval-sheet-prompt-truncated'),
                    ),
                  if (safeRisk != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Risk: ${_safeHermesUiPreview(safeRisk, maxLength: 240)}',
                      key: const ValueKey('hermes-approval-sheet-risk'),
                    ),
                    if (riskTruncated)
                      const Text(
                        'Risk preview truncated for mobile review.',
                        key: ValueKey('hermes-approval-sheet-risk-truncated'),
                      ),
                  ],
                  if (request.toolCallId.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Tool call: ${_safeHermesUiPreview(safeToolCallId, maxLength: 160)}',
                    ),
                  ],
                  if (!canRespond) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Decision buttons are disabled because Hermes did not advertise /v1/runs/{run_id}/approval.',
                    ),
                  ] else if (!hasApprovalId) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Decision buttons are disabled because Hermes did not include an approval id.',
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        key: const ValueKey('hermes-approval-sheet-copy'),
                        onPressed: () {
                          unawaited(
                            Clipboard.setData(
                              ClipboardData(text: approvalSummary),
                            ),
                          );
                          ScaffoldMessenger.maybeOf(sheetContext)?.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Copied redacted Hermes approval details.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_outlined),
                        label: const Text('Copy details'),
                      ),
                      TextButton(
                        key: const ValueKey('hermes-approval-sheet-close'),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text('Close'),
                      ),
                      if (!hasApprovalId)
                        TextButton(
                          key: const ValueKey(
                            'hermes-approval-sheet-dismiss-malformed',
                          ),
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            onDismissMalformed();
                          },
                          child: const Text('Dismiss'),
                        ),
                      TextButton(
                        key: const ValueKey('hermes-approval-sheet-deny'),
                        onPressed: canAnswer
                            ? () {
                                Navigator.of(sheetContext).pop();
                                onDecide(HermesApprovalDecision.deny);
                              }
                            : null,
                        child: const Text('Deny'),
                      ),
                      OutlinedButton(
                        key: const ValueKey('hermes-approval-sheet-session'),
                        onPressed: canAnswer
                            ? () => unawaited(
                                _confirmSessionAllow(
                                  sheetContext,
                                  closeSheetOnConfirm: true,
                                ),
                              )
                            : null,
                        child: const Text('Allow for session'),
                      ),
                      OutlinedButton(
                        key: const ValueKey('hermes-approval-sheet-always'),
                        onPressed: canAnswer
                            ? () => unawaited(
                                _confirmAlwaysAllow(
                                  sheetContext,
                                  closeSheetOnConfirm: true,
                                ),
                              )
                            : null,
                        child: const Text('Always allow'),
                      ),
                      FilledButton(
                        key: const ValueKey('hermes-approval-sheet-once'),
                        onPressed: canAnswer
                            ? () {
                                Navigator.of(sheetContext).pop();
                                onDecide(HermesApprovalDecision.once);
                              }
                            : null,
                        child: const Text('Approve once'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _approvalReviewSummary({
    required String safePrompt,
    required String? safeRisk,
    required String safeToolCallId,
    required bool hasApprovalId,
  }) {
    final buffer = StringBuffer()
      ..writeln('Hermes approval review')
      ..writeln('Prompt: ${_safeHermesUiPreview(safePrompt, maxLength: 600)}');
    if (safeRisk != null) {
      buffer.writeln('Risk: ${_safeHermesUiPreview(safeRisk, maxLength: 240)}');
    }
    if (safeToolCallId.trim().isNotEmpty) {
      buffer.writeln(
        'Tool call: ${_safeHermesUiPreview(safeToolCallId, maxLength: 160)}',
      );
    }
    buffer
      ..writeln('Approval id present: $hasApprovalId')
      ..write('Pending approvals: $pendingCount');
    return buffer.toString();
  }
}
