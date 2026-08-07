part of '../hermes_chat_screen.dart';

class _HermesSessionRail extends StatefulWidget {
  const _HermesSessionRail({
    required this.state,
    required this.canCreate,
    required this.onCreate,
    required this.onSelect,
    required this.onRename,
    required this.onFork,
    required this.onDelete,
    required this.onDeleteSelected,
  });

  final HermesChannelState state;
  final bool canCreate;
  final VoidCallback onCreate;
  final ValueChanged<HermesSession> onSelect;
  final ValueChanged<HermesSession> onRename;
  final ValueChanged<HermesSession> onFork;
  final ValueChanged<HermesSession> onDelete;
  final ValueChanged<List<HermesSession>> onDeleteSelected;

  @override
  State<_HermesSessionRail> createState() => _HermesSessionRailState();
}

class _HermesSessionRailState extends State<_HermesSessionRail> {
  final _searchController = TextEditingController();
  final _selectedSessionIds = <String>{};
  String _query = '';
  var _selecting = false;

  @override
  void didUpdateWidget(covariant _HermesSessionRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.state.canDeleteSessions) {
      _selectedSessionIds.clear();
      _selecting = false;
      return;
    }
    final hadSelection = _selectedSessionIds.isNotEmpty;
    final selectableIds = {
      for (final session in widget.state.sessions)
        if (!widget.state.isSessionStreaming(session.id)) session.id,
    };
    _selectedSessionIds.removeWhere((id) => !selectableIds.contains(id));
    if (hadSelection && _selectedSessionIds.isEmpty) _selecting = false;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _canRename => widget.state.canUpdateSessions;

  bool get _canDelete => widget.state.canDeleteSessions;

  bool get _canFork => widget.state.canForkSessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = _hermesStrings(context);
    final allSessions = widget.state.sessions;
    final query = _query.trim().toLowerCase();
    final sessions = query.isEmpty
        ? allSessions
        : allSessions
              .where(
                (session) => _sessionMatchesQuery(
                  session,
                  query,
                  widget.state.activeSessionId,
                ),
              )
              .toList(growable: false);
    return SizedBox(
      key: const ValueKey('hermes-session-rail'),
      width: 320,
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        child: SafeArea(
          right: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.chatRailSessionsTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!_selecting)
                      FilledButton.icon(
                        key: const ValueKey('hermes-session-rail-new'),
                        onPressed: widget.canCreate ? widget.onCreate : null,
                        icon: const Icon(Icons.add),
                        label: Text(strings.chatRailNewSessionAction),
                      ),
                  ],
                ),
              ),
              if (_canDelete && allSessions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _selecting
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              strings.chatRailSelectedCountLabel(
                                _selectedSessionIds.length,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                TextButton(
                                  key: const ValueKey(
                                    'hermes-session-rail-select-all',
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedSessionIds
                                        ..clear()
                                        ..addAll(
                                          sessions
                                              .where(
                                                (session) => !widget.state
                                                    .isSessionStreaming(
                                                      session.id,
                                                    ),
                                              )
                                              .map((session) => session.id),
                                        );
                                    });
                                  },
                                  child: Text(strings.chatRailSelectAllAction),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _selecting = false;
                                      _selectedSessionIds.clear();
                                    });
                                  },
                                  child: Text(strings.cancelAction),
                                ),
                                FilledButton.icon(
                                  key: const ValueKey(
                                    'hermes-session-rail-delete-selected',
                                  ),
                                  onPressed: _selectedSessionIds.isEmpty
                                      ? null
                                      : () => widget.onDeleteSelected([
                                          for (final session in allSessions)
                                            if (_selectedSessionIds.contains(
                                              session.id,
                                            ))
                                              session,
                                        ]),
                                  icon: const Icon(Icons.delete_outline),
                                  label: Text(
                                    strings.chatRailDeleteCountAction(
                                      _selectedSessionIds.length,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            key: const ValueKey('hermes-session-rail-select'),
                            onPressed: () => setState(() => _selecting = true),
                            icon: const Icon(Icons.checklist_outlined),
                            label: Text(strings.chatRailSelectAction),
                          ),
                        ),
                ),
              if (allSessions.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    key: const ValueKey('hermes-session-rail-search-field'),
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: strings.chatRailSearchSessionsLabel,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              key: const ValueKey(
                                'hermes-session-rail-search-clear',
                              ),
                              tooltip: strings.chatRailClearSearchTooltip,
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    _sessionCountSummary(
                      strings: strings,
                      visibleCount: sessions.length,
                      totalCount: allSessions.length,
                      query: _query,
                    ),
                    key: const ValueKey('hermes-session-rail-count-summary'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              if (allSessions.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        strings.chatRailNoSessionsBody,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else if (sessions.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        strings.chatRailNoSessionsMatchBody(
                          _safeHermesUiPreview(_query.trim(), maxLength: 64),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    key: const ValueKey('hermes-session-rail-list'),
                    children: [
                      for (final group in _sessionGroups(
                        sessions,
                        strings: _hermesStrings(context),
                      )) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                          child: Text(
                            group.label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        for (final session in group.sessions)
                          _HermesSessionTile(
                            session: session,
                            active: session.id == widget.state.activeSessionId,
                            streaming: widget.state.isSessionStreaming(
                              session.id,
                            ),
                            failed: widget.state.isSessionReplyFailed(
                              session.id,
                            ),
                            canRename: _canRename,
                            canFork:
                                _canFork &&
                                !widget.state.isSessionStreaming(session.id),
                            canDelete:
                                _canDelete &&
                                !widget.state.isSessionStreaming(session.id),
                            selectionMode: _selecting,
                            selected: _selectedSessionIds.contains(session.id),
                            selectable: !widget.state.isSessionStreaming(
                              session.id,
                            ),
                            onSelectionChanged: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedSessionIds.add(session.id);
                                } else {
                                  _selectedSessionIds.remove(session.id);
                                }
                              });
                            },
                            onSelect: widget.onSelect,
                            onRename: widget.onRename,
                            onFork: widget.onFork,
                            onDelete: widget.onDelete,
                          ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HermesActiveSessionBar extends StatelessWidget {
  const _HermesActiveSessionBar({
    required this.session,
    required this.messageCount,
    required this.modelLabel,
    required this.isTurnActive,
    required this.canSendTurns,
  });

  final HermesSession session;
  final int messageCount;
  final String modelLabel;
  final bool isTurnActive;
  final bool canSendTurns;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final strings = _hermesStrings(context);
    final statusLabel = isTurnActive
        ? strings.chatRailStatusStreamingLabel
        : canSendTurns
        ? strings.chatRailStatusReadyLabel
        : strings.chatRailStatusTransportUnavailableLabel;
    final statusIcon = isTurnActive
        ? Icons.autorenew
        : canSendTurns
        ? Icons.bolt_outlined
        : Icons.block;

    return Semantics(
      label: strings.chatRailActiveHermesSessionLabel,
      child: Container(
        key: const ValueKey('hermes-active-session-bar'),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.86),
          border: Border(
            bottom: BorderSide(
              color: colors.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            Widget titleChip() => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.36),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _safeHermesUiPreview(
                        session.title ?? session.id,
                        maxLength: 96,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            );

            final activeLabel = Text(
              strings.chatRailActiveLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            );
            final statusChip = _HermesTopBarChip(
              icon: statusIcon,
              label: statusLabel,
            );
            final modelChip = _HermesTopBarChip(
              icon: Icons.memory_outlined,
              label: _safeHermesUiPreview(modelLabel, maxLength: 28),
            );
            final count = Text(
              strings.chatRailMessageCountLabel(messageCount),
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            );
            final scaled = MediaQuery.textScalerOf(context).scale(14) > 18;
            if (constraints.maxWidth < 900 || scaled) {
              final titleWidth = constraints.maxWidth.clamp(160.0, 360.0);
              return Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  activeLabel,
                  SizedBox(width: titleWidth, child: titleChip()),
                  statusChip,
                  modelChip,
                  count,
                ],
              );
            }
            return Row(
              children: [
                activeLabel,
                const SizedBox(width: 10),
                Flexible(flex: 3, child: titleChip()),
                const SizedBox(width: 10),
                statusChip,
                const SizedBox(width: 8),
                modelChip,
                const SizedBox(width: 8),
                count,
                const Spacer(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HermesTopBarChip extends StatelessWidget {
  const _HermesTopBarChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HermesEmptyState extends StatelessWidget {
  const _HermesEmptyState({
    required this.canSendTurns,
    required this.onPromptSelected,
  });

  final bool canSendTurns;
  final ValueChanged<String> onPromptSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = _hermesStrings(context);
    final prompts = [
      strings.chatRailPromptSummarizeHelpLabel,
      strings.chatRailPromptListSkillsLabel,
      strings.chatRailPromptPlanTaskLabel,
      strings.chatRailPromptExplainSessionLabel,
    ];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                'H',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              strings.chatRailEmptyStateTitle,
              key: const ValueKey('hermes-empty-state-title'),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.chatRailEmptyStateBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final prompt in prompts)
                  ActionChip(
                    key: ValueKey('hermes-empty-prompt-$prompt'),
                    avatar: const Icon(Icons.auto_awesome, size: 18),
                    label: Text(prompt),
                    onPressed: canSendTurns
                        ? () => onPromptSelected(prompt)
                        : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HermesComposerStrip extends StatelessWidget {
  const _HermesComposerStrip({
    required this.modelLabel,
    required this.voiceLabel,
    required this.isTurnActive,
    required this.canSendTurns,
    required this.canRetry,
    required this.onStop,
    required this.onRetry,
  });

  final String modelLabel;
  final String voiceLabel;
  final bool isTurnActive;
  final bool canSendTurns;
  final bool canRetry;
  final VoidCallback onStop;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = _hermesStrings(context);
    return SingleChildScrollView(
      key: const ValueKey('hermes-composer-strip'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ComposerChip(
            icon: Icons.memory_outlined,
            label: _safeHermesUiPreview(modelLabel, maxLength: 32),
          ),
          const SizedBox(width: 8),
          _ComposerChip(icon: Icons.keyboard_voice_outlined, label: voiceLabel),
          const SizedBox(width: 8),
          if (isTurnActive)
            ActionChip(
              key: const ValueKey('hermes-composer-stop-chip'),
              avatar: const Icon(Icons.stop_circle_outlined, size: 18),
              label: Text(strings.chatRailStopAction),
              onPressed: onStop,
            )
          else
            _ComposerChip(
              icon: canSendTurns ? Icons.bolt_outlined : Icons.block,
              label: canSendTurns
                  ? strings.chatRailStatusReadyLabel
                  : strings.chatRailStatusTransportUnavailableLabel,
            ),
          if (canRetry) ...[
            const SizedBox(width: 8),
            ActionChip(
              key: const ValueKey('hermes-composer-retry-chip'),
              avatar: const Icon(Icons.refresh, size: 18),
              label: Text(strings.retryAction),
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

class _ComposerChip extends StatelessWidget {
  const _ComposerChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _HermesSessionsPanel extends StatefulWidget {
  const _HermesSessionsPanel({
    required this.state,
    required this.canCreate,
    required this.onCreate,
    required this.onSelect,
    required this.onRename,
    required this.onFork,
    required this.onDelete,
    required this.onDeleteSelected,
  });

  final HermesChannelState state;
  final bool canCreate;
  final VoidCallback onCreate;
  final ValueChanged<HermesSession> onSelect;
  final ValueChanged<HermesSession> onRename;
  final ValueChanged<HermesSession> onFork;
  final ValueChanged<HermesSession> onDelete;
  final ValueChanged<List<HermesSession>> onDeleteSelected;

  @override
  State<_HermesSessionsPanel> createState() => _HermesSessionsPanelState();
}

class _HermesSessionsPanelState extends State<_HermesSessionsPanel> {
  final _searchController = TextEditingController();
  final _selectedSessionIds = <String>{};
  var _query = '';
  var _selecting = false;

  @override
  void didUpdateWidget(covariant _HermesSessionsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.state.canDeleteSessions) {
      _selectedSessionIds.clear();
      _selecting = false;
      return;
    }
    final hadSelection = _selectedSessionIds.isNotEmpty;
    final selectableIds = {
      for (final session in widget.state.sessions)
        if (!widget.state.isSessionStreaming(session.id)) session.id,
    };
    _selectedSessionIds.removeWhere((id) => !selectableIds.contains(id));
    if (hadSelection && _selectedSessionIds.isEmpty) _selecting = false;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _canRename => widget.state.canUpdateSessions;

  bool get _canDelete => widget.state.canDeleteSessions;

  bool get _canFork => widget.state.canForkSessions;

  @override
  Widget build(BuildContext context) {
    final strings = _hermesStrings(context);
    final allSessions = widget.state.sessions;
    final query = _query.trim().toLowerCase();
    final sessions = query.isEmpty
        ? allSessions
        : allSessions
              .where(
                (session) => _sessionMatchesQuery(
                  session,
                  query,
                  widget.state.activeSessionId,
                ),
              )
              .toList(growable: false);
    return SafeArea(
      key: const ValueKey('hermes-sessions-panel'),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          children: [
            ListTile(
              title: Text(
                strings.chatRailHermesSessionsTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              trailing: widget.canCreate && !_selecting
                  ? FilledButton.icon(
                      key: const ValueKey('hermes-sessions-new'),
                      onPressed: widget.onCreate,
                      icon: const Icon(Icons.add_comment_outlined),
                      label: Text(strings.chatRailNewSessionAction),
                    )
                  : null,
            ),
            if (_canDelete && allSessions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _selecting
                    ? Wrap(
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Text(
                            strings.chatRailSelectedCountLabel(
                              _selectedSessionIds.length,
                            ),
                          ),
                          TextButton(
                            key: const ValueKey('hermes-sessions-select-all'),
                            onPressed: () {
                              setState(() {
                                _selectedSessionIds
                                  ..clear()
                                  ..addAll(
                                    sessions
                                        .where(
                                          (session) => !widget.state
                                              .isSessionStreaming(session.id),
                                        )
                                        .map((session) => session.id),
                                  );
                              });
                            },
                            child: Text(strings.chatRailSelectAllAction),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selecting = false;
                                _selectedSessionIds.clear();
                              });
                            },
                            child: Text(strings.cancelAction),
                          ),
                          FilledButton.icon(
                            key: const ValueKey(
                              'hermes-sessions-delete-selected',
                            ),
                            onPressed: _selectedSessionIds.isEmpty
                                ? null
                                : () => widget.onDeleteSelected([
                                    for (final session in allSessions)
                                      if (_selectedSessionIds.contains(
                                        session.id,
                                      ))
                                        session,
                                  ]),
                            icon: const Icon(Icons.delete_outline),
                            label: Text(
                              strings.chatRailDeleteCountAction(
                                _selectedSessionIds.length,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          key: const ValueKey('hermes-sessions-select'),
                          onPressed: () => setState(() => _selecting = true),
                          icon: const Icon(Icons.checklist_outlined),
                          label: Text(strings.chatRailSelectAction),
                        ),
                      ),
              ),
            if (allSessions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  key: const ValueKey('hermes-session-search-field'),
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: strings.chatRailSearchSessionsLabel,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            key: const ValueKey('hermes-session-search-clear'),
                            tooltip: strings.chatRailClearSearchTooltip,
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _sessionCountSummary(
                      strings: strings,
                      visibleCount: sessions.length,
                      totalCount: allSessions.length,
                      query: _query,
                    ),
                    key: const ValueKey('hermes-session-count-summary'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
            if (allSessions.isEmpty)
              Expanded(
                child: Center(
                  child: Text(strings.chatRailNoHermesSessionsBody),
                ),
              )
            else if (sessions.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    strings.chatRailNoHermesSessionsMatchBody(
                      _safeHermesUiPreview(_query.trim(), maxLength: 64),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  key: const ValueKey('hermes-sessions-list'),
                  children: [
                    for (final group in _sessionGroups(
                      sessions,
                      strings: _hermesStrings(context),
                    )) ...[
                      Padding(
                        key: ValueKey('hermes-session-group-${group.key}'),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          group.label,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      for (final session in group.sessions)
                        _HermesSessionTile(
                          session: session,
                          active: session.id == widget.state.activeSessionId,
                          streaming: widget.state.isSessionStreaming(
                            session.id,
                          ),
                          failed: widget.state.isSessionReplyFailed(session.id),
                          canRename: _canRename,
                          canFork:
                              _canFork &&
                              !widget.state.isSessionStreaming(session.id),
                          canDelete:
                              _canDelete &&
                              !widget.state.isSessionStreaming(session.id),
                          selectionMode: _selecting,
                          selected: _selectedSessionIds.contains(session.id),
                          selectable: !widget.state.isSessionStreaming(
                            session.id,
                          ),
                          onSelectionChanged: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedSessionIds.add(session.id);
                              } else {
                                _selectedSessionIds.remove(session.id);
                              }
                            });
                          },
                          onSelect: widget.onSelect,
                          onRename: widget.onRename,
                          onFork: widget.onFork,
                          onDelete: widget.onDelete,
                        ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _sessionCountSummary({
  required AppLocalizations strings,
  required int visibleCount,
  required int totalCount,
  required String query,
}) {
  if (query.trim().isEmpty) {
    return strings.chatRailSessionCountLabel(totalCount);
  }
  return strings.chatRailShowingSessionCountLabel(totalCount, visibleCount);
}

bool _sessionMatchesQuery(
  HermesSession session,
  String query,
  String? activeSessionId,
) {
  final groupTokens = session.id == activeSessionId
      ? const ['active', 'active session']
      : session.parentSessionId != null
      ? const ['forked', 'forked session', 'forked sessions']
      : const ['other', 'other session', 'other sessions'];
  return [
    session.title,
    session.id,
    session.preview,
    session.parentSessionId,
    session.lastActive,
    ...groupTokens,
  ].whereType<String>().any(
    (value) =>
        _safeHermesSessionSearchText(value).toLowerCase().contains(query),
  );
}

List<_HermesSessionGroup> _sessionGroups(
  List<HermesSession> sessions, {
  required AppLocalizations strings,
  DateTime? now,
}) {
  final reference = (now ?? DateTime.now()).toLocal();
  final grouped = <String, List<HermesSession>>{};
  for (final session in _recentFirst(sessions)) {
    final key = _sessionDateGroup(session, reference);
    (grouped[key] ??= []).add(session);
  }
  return [
    for (final group in [
      (key: 'today', label: strings.sessionsToday),
      (key: 'yesterday', label: strings.sessionsYesterday),
      (key: 'this-week', label: strings.sessionsThisWeek),
      (key: 'earlier', label: strings.sessionsEarlier),
    ])
      if (grouped[group.key]?.isNotEmpty ?? false)
        _HermesSessionGroup(group.key, group.label, grouped[group.key]!),
  ];
}

String _sessionDateGroup(HermesSession session, DateTime now) {
  final parsed = DateTime.tryParse(session.lastActive ?? '')?.toLocal();
  if (parsed == null) return 'earlier';
  if (_isSameDay(parsed, now)) return 'today';

  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  if (_isSameDay(parsed, yesterday)) return 'yesterday';

  final weekAgo = now.subtract(const Duration(days: 7));
  return parsed.isBefore(weekAgo) ? 'earlier' : 'this-week';
}

bool _isSameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

List<HermesSession> _recentFirst(List<HermesSession> sessions) {
  final sorted = List<HermesSession>.of(sessions);
  sorted.sort((a, b) {
    final recency = _sessionTimestamp(b).compareTo(_sessionTimestamp(a));
    if (recency != 0) return recency;
    return (a.title ?? a.id).compareTo(b.title ?? b.id);
  });
  return sorted;
}

int _sessionTimestamp(HermesSession session) {
  final parsed = DateTime.tryParse(session.lastActive ?? '');
  return parsed?.millisecondsSinceEpoch ?? 0;
}

class _HermesSessionGroup {
  const _HermesSessionGroup(this.key, this.label, this.sessions);

  final String key;
  final String label;
  final List<HermesSession> sessions;
}

String _sessionSourceLabel(BuildContext context, String source) {
  final normalized = source.trim().replaceAll(RegExp(r'[_-]+'), ' ');
  return _safeHermesUiPreview(
    normalized.isEmpty
        ? _hermesStrings(context).sessionUnknownSource
        : normalized,
    maxLength: 48,
  );
}

String _sessionLastActiveLabel(BuildContext context, String value) {
  final parsed = DateTime.tryParse(value)?.toLocal();
  if (parsed == null) return _safeHermesUiPreview(value, maxLength: 80);
  final localizations = MaterialLocalizations.of(context);
  final date = localizations.formatShortDate(parsed);
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(parsed),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  return '$date, $time';
}

bool _hasHermesExtendedSessionMetadata(HermesSession session) =>
    session.toolCallCount != null ||
    session.apiCallCount != null ||
    session.inputTokens != null ||
    session.outputTokens != null ||
    session.cacheReadTokens != null ||
    session.cacheWriteTokens != null ||
    session.reasoningTokens != null ||
    session.actualCostUsd != null ||
    session.estimatedCostUsd != null ||
    session.startedAt != null ||
    session.endedAt != null ||
    session.endReason != null ||
    session.hasSystemPrompt != null ||
    session.hasModelConfig != null;

List<String> _hermesExtendedSessionMetadataLines(
  AppLocalizations strings,
  HermesSession session,
) => [
  if (session.toolCallCount != null)
    strings.chatRailDetailToolCallsLabel(session.toolCallCount!),
  if (session.apiCallCount != null)
    strings.chatRailDetailApiCallsLabel(session.apiCallCount!),
  if (session.inputTokens != null)
    strings.chatRailDetailInputTokensLabel(session.inputTokens!),
  if (session.outputTokens != null)
    strings.chatRailDetailOutputTokensLabel(session.outputTokens!),
  if (session.cacheReadTokens != null)
    strings.chatRailDetailCacheReadTokensLabel(session.cacheReadTokens!),
  if (session.cacheWriteTokens != null)
    strings.chatRailDetailCacheWriteTokensLabel(session.cacheWriteTokens!),
  if (session.reasoningTokens != null)
    strings.chatRailDetailReasoningTokensLabel(session.reasoningTokens!),
  if (session.actualCostUsd != null)
    strings.chatRailDetailActualCostLabel(
      _formatSessionCost(session.actualCostUsd!),
    ),
  if (session.estimatedCostUsd != null)
    strings.chatRailDetailEstimatedCostLabel(
      _formatSessionCost(session.estimatedCostUsd!),
    ),
  if (session.startedAt != null)
    strings.chatRailDetailStartedLabel(
      _safeHermesUiPreview(session.startedAt!, maxLength: 120),
    ),
  if (session.endedAt != null)
    strings.chatRailDetailEndedLabel(
      _safeHermesUiPreview(session.endedAt!, maxLength: 120),
    ),
  if (session.endReason != null)
    strings.chatRailDetailEndReasonLabel(
      _safeHermesUiPreview(session.endReason!, maxLength: 80),
    ),
  if (session.hasSystemPrompt != null)
    strings.chatRailDetailSystemPromptSnapshotLabel(
      session.hasSystemPrompt!
          ? strings.chatRailDetailYesLabel
          : strings.chatRailDetailNoLabel,
    ),
  if (session.hasModelConfig != null)
    strings.chatRailDetailModelConfigSnapshotLabel(
      session.hasModelConfig!
          ? strings.chatRailDetailYesLabel
          : strings.chatRailDetailNoLabel,
    ),
];

class _HermesSessionTile extends StatelessWidget {
  const _HermesSessionTile({
    required this.session,
    required this.active,
    required this.streaming,
    required this.failed,
    required this.canRename,
    required this.canFork,
    required this.canDelete,
    required this.onSelect,
    required this.onRename,
    required this.onFork,
    required this.onDelete,
    this.selectionMode = false,
    this.selected = false,
    this.selectable = true,
    this.onSelectionChanged,
  });

  final HermesSession session;
  final bool active;
  final bool streaming;
  final bool failed;
  final bool canRename;
  final bool canFork;
  final bool canDelete;
  final bool selectionMode;
  final bool selected;
  final bool selectable;
  final ValueChanged<bool>? onSelectionChanged;
  final ValueChanged<HermesSession> onSelect;
  final ValueChanged<HermesSession> onRename;
  final ValueChanged<HermesSession> onFork;
  final ValueChanged<HermesSession> onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = _hermesStrings(context);
    return ListTile(
      key: ValueKey('hermes-session-row-${session.id}'),
      selected: selectionMode ? selected : active,
      leading: selectionMode
          ? Checkbox(
              value: selected,
              onChanged: selectable
                  ? (value) => onSelectionChanged?.call(value ?? false)
                  : null,
            )
          : streaming
          ? SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(
                key: ValueKey('hermes-session-streaming-${session.id}'),
                strokeWidth: 2.5,
                semanticsLabel: strings.sessionStreamingReply,
              ),
            )
          : failed
          ? Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              semanticLabel: strings.sessionReplyFailed,
            )
          : active
          ? const Icon(Icons.check_circle_outline)
          : const Icon(Icons.chat_bubble_outline),
      title: Text(
        _safeHermesUiPreview(session.title ?? session.id, maxLength: 96),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          _sessionSourceLabel(context, session.source),
          if (session.model?.trim().isNotEmpty ?? false)
            _safeHermesUiPreview(session.model!.trim(), maxLength: 80),
          strings.chatRailTileMessageCountLabel(session.messageCount),
          if (streaming)
            strings.sessionStreamingReply
          else if (failed)
            strings.sessionReplyFailed,
          if (session.parentSessionId != null)
            strings.chatRailForkedFromLabel(
              _safeHermesUiPreview(session.parentSessionId!, maxLength: 80),
            ),
          if (session.lastActive != null)
            strings.chatRailLastActiveLabel(
              _sessionLastActiveLabel(context, session.lastActive!),
            ),
          if (session.preview != null)
            _safeHermesUiPreview(session.preview!, maxLength: 160),
        ].join(' • '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: selectionMode
          ? selectable
                ? () => onSelectionChanged?.call(!selected)
                : null
          : () => onSelect(session),
      trailing: selectionMode
          ? null
          : PopupMenuButton<String>(
              key: ValueKey('hermes-session-menu-${session.id}'),
              tooltip: strings.chatRailSessionActionsTooltip,
              onSelected: (value) {
                switch (value) {
                  case 'details':
                    unawaited(_showSessionDetails(context, session, active));
                  case 'copy':
                    unawaited(
                      Clipboard.setData(
                        ClipboardData(
                          text: _sessionDetailsSummary(
                            context,
                            session,
                            active,
                          ),
                        ),
                      ),
                    );
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      SnackBar(
                        content: Text(strings.chatRailCopiedSessionDetailsBody),
                      ),
                    );
                  case 'rename':
                    onRename(session);
                  case 'fork':
                    onFork(session);
                  case 'delete':
                    onDelete(session);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'details',
                  child: Text(strings.chatRailViewDetailsAction),
                ),
                PopupMenuItem(
                  value: 'copy',
                  child: Text(strings.chatRailCopyDetailsAction),
                ),
                if (canRename)
                  PopupMenuItem(
                    value: 'rename',
                    child: Text(strings.chatRailRenameAction),
                  ),
                if (canFork)
                  PopupMenuItem(
                    value: 'fork',
                    child: Text(strings.chatRailBranchAction),
                  ),
                if (canDelete)
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(strings.chatRailDeleteAction),
                  ),
              ],
            ),
    );
  }

  Future<void> _showSessionDetails(
    BuildContext context,
    HermesSession session,
    bool active,
  ) {
    final summary = _sessionDetailsSummary(context, session, active);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          key: const ValueKey('hermes-session-details-sheet'),
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _hermesStrings(sheetContext).chatRailSessionDetailsTitle,
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              SelectableText(summary),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: summary));
                  if (!sheetContext.mounted) return;
                  Navigator.of(sheetContext).pop();
                  if (!context.mounted) return;
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    SnackBar(
                      content: Text(
                        _hermesStrings(
                          context,
                        ).chatRailCopiedSessionDetailsBody,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_outlined),
                label: Text(
                  _hermesStrings(sheetContext).chatRailCopyDetailsAction,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _sessionDetailsSummary(
    BuildContext context,
    HermesSession session,
    bool active,
  ) {
    final strings = _hermesStrings(context);
    final buffer = StringBuffer()
      ..writeln(strings.chatRailSessionDetailsHeaderLabel)
      ..writeln(
        strings.chatRailDetailTitleLabel(
          _safeHermesUiPreview(session.title ?? session.id, maxLength: 96),
        ),
      )
      ..writeln(
        strings.chatRailDetailIdLabel(
          _safeHermesUiPreview(session.id, maxLength: 120),
        ),
      )
      ..writeln(
        strings.sessionSourceLabel(
          _sessionSourceLabel(context, session.source),
        ),
      )
      ..writeln(
        strings.sessionModelLabel(
          session.model?.trim().isNotEmpty == true
              ? _safeHermesUiPreview(session.model!.trim(), maxLength: 120)
              : strings.sessionModelNotReported,
        ),
      )
      ..writeln(strings.chatRailDetailActiveLabel('$active'))
      ..writeln(strings.chatRailDetailMessagesLabel(session.messageCount));
    for (final line in _hermesExtendedSessionMetadataLines(strings, session)) {
      buffer.writeln(line);
    }
    if (session.parentSessionId != null) {
      buffer.writeln(
        strings.chatRailDetailForkedFromLabel(
          _safeHermesUiPreview(session.parentSessionId!, maxLength: 120),
        ),
      );
    }
    if (session.lastActive != null) {
      buffer.writeln(
        strings.chatRailDetailLastActiveLabel(
          _safeHermesUiPreview(session.lastActive!, maxLength: 120),
        ),
      );
    }
    return buffer.toString().trimRight();
  }
}

String _formatSessionCost(double value) {
  final fixed = value.toStringAsFixed(6);
  final withoutTrailingZeroes = fixed.replaceFirst(RegExp(r'0+$'), '');
  return withoutTrailingZeroes.endsWith('.')
      ? '${withoutTrailingZeroes}00'
      : withoutTrailingZeroes;
}
