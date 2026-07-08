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
  });

  final HermesChannelState state;
  final bool canCreate;
  final VoidCallback onCreate;
  final ValueChanged<HermesSession> onSelect;
  final ValueChanged<HermesSession> onRename;
  final ValueChanged<HermesSession> onFork;
  final ValueChanged<HermesSession> onDelete;

  @override
  State<_HermesSessionRail> createState() => _HermesSessionRailState();
}

class _HermesSessionRailState extends State<_HermesSessionRail> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _canRename =>
      widget.state.capabilities?.advertisesEndpoint(
        'session_update',
        'PATCH',
        '/api/sessions/{session_id}',
      ) ??
      false;

  bool get _canDelete =>
      widget.state.capabilities?.advertisesEndpoint(
        'session_delete',
        'DELETE',
        '/api/sessions/{session_id}',
      ) ??
      false;

  bool get _canFork =>
      widget.state.capabilities?.advertisesEndpoint(
        'session_fork',
        'POST',
        '/api/sessions/{session_id}/fork',
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
    return Container(
      key: const ValueKey('hermes-session-rail'),
      width: 320,
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
                      'Sessions',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    key: const ValueKey('hermes-session-rail-new'),
                    onPressed: widget.canCreate ? widget.onCreate : null,
                    icon: const Icon(Icons.add),
                    label: const Text('New'),
                  ),
                ],
              ),
            ),
            if (allSessions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  key: const ValueKey('hermes-session-rail-search-field'),
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search sessions',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            key: const ValueKey(
                              'hermes-session-rail-search-clear',
                            ),
                            tooltip: 'Clear search',
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
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No sessions yet. Create one to start a Hermes chat.',
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
                      'No sessions match “${_safeHermesUiPreview(_query.trim(), maxLength: 64)}”.',
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
                      widget.state.activeSessionId,
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
                          canRename: _canRename,
                          canFork: _canFork,
                          canDelete: _canDelete,
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
    final statusLabel = isTurnActive
        ? 'Streaming'
        : canSendTurns
        ? 'Ready'
        : 'Transport unavailable';
    final statusIcon = isTurnActive
        ? Icons.autorenew
        : canSendTurns
        ? Icons.bolt_outlined
        : Icons.block;

    return Semantics(
      label: 'Active Hermes session',
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
        child: Row(
          children: [
            Text(
              'Active',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.36),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
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
              ),
            ),
            const SizedBox(width: 10),
            _HermesTopBarChip(icon: statusIcon, label: statusLabel),
            const SizedBox(width: 8),
            _HermesTopBarChip(
              icon: Icons.memory_outlined,
              label: _safeHermesUiPreview(modelLabel, maxLength: 28),
            ),
            const SizedBox(width: 8),
            Text(
              '$messageCount ${messageCount == 1 ? 'message' : 'messages'}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const Spacer(),
          ],
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

  static const _prompts = [
    'Summarize what you can help me do.',
    'List my available Hermes skills.',
    'Plan my next coding task.',
    'Explain the current session state.',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              'How can Hermes help today?',
              key: const ValueKey('hermes-empty-state-title'),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a session with text or local voice. Navivox keeps the mobile chat flow Telegram-fast while Hermes handles runs, tools, and approvals.',
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
                for (final prompt in _prompts)
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
    required this.onDiagnostics,
  });

  final String modelLabel;
  final String voiceLabel;
  final bool isTurnActive;
  final bool canSendTurns;
  final bool canRetry;
  final VoidCallback onStop;
  final VoidCallback onRetry;
  final VoidCallback onDiagnostics;

  @override
  Widget build(BuildContext context) {
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
              label: const Text('Stop'),
              onPressed: onStop,
            )
          else
            _ComposerChip(
              icon: canSendTurns ? Icons.bolt_outlined : Icons.block,
              label: canSendTurns ? 'Ready' : 'Transport unavailable',
            ),
          if (canRetry) ...[
            const SizedBox(width: 8),
            ActionChip(
              key: const ValueKey('hermes-composer-retry-chip'),
              avatar: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              onPressed: onRetry,
            ),
          ],
          const SizedBox(width: 8),
          ActionChip(
            key: const ValueKey('hermes-composer-diagnostics-chip'),
            avatar: const Icon(Icons.info_outline, size: 18),
            label: const Text('Diagnostics'),
            onPressed: onDiagnostics,
          ),
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
  });

  final HermesChannelState state;
  final bool canCreate;
  final VoidCallback onCreate;
  final ValueChanged<HermesSession> onSelect;
  final ValueChanged<HermesSession> onRename;
  final ValueChanged<HermesSession> onFork;
  final ValueChanged<HermesSession> onDelete;

  @override
  State<_HermesSessionsPanel> createState() => _HermesSessionsPanelState();
}

class _HermesSessionsPanelState extends State<_HermesSessionsPanel> {
  final _searchController = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _canRename =>
      widget.state.capabilities?.advertisesEndpoint(
        'session_update',
        'PATCH',
        '/api/sessions/{session_id}',
      ) ??
      false;

  bool get _canDelete =>
      widget.state.capabilities?.advertisesEndpoint(
        'session_delete',
        'DELETE',
        '/api/sessions/{session_id}',
      ) ??
      false;

  bool get _canFork =>
      widget.state.capabilities?.advertisesEndpoint(
        'session_fork',
        'POST',
        '/api/sessions/{session_id}/fork',
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
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
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          children: [
            ListTile(
              title: Text(
                'Hermes sessions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              trailing: widget.canCreate
                  ? FilledButton.icon(
                      key: const ValueKey('hermes-sessions-new'),
                      onPressed: widget.onCreate,
                      icon: const Icon(Icons.add_comment_outlined),
                      label: const Text('New'),
                    )
                  : null,
            ),
            if (allSessions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  key: const ValueKey('hermes-session-search-field'),
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search sessions',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            key: const ValueKey('hermes-session-search-clear'),
                            tooltip: 'Clear search',
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
              const Expanded(
                child: Center(child: Text('No Hermes sessions yet.')),
              )
            else if (sessions.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No Hermes sessions match “${_safeHermesUiPreview(_query.trim(), maxLength: 64)}”.',
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
                      widget.state.activeSessionId,
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
                          canRename: _canRename,
                          canFork: _canFork,
                          canDelete: _canDelete,
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
  required int visibleCount,
  required int totalCount,
  required String query,
}) {
  final totalLabel = totalCount == 1 ? 'session' : 'sessions';
  if (query.trim().isEmpty) return '$totalCount $totalLabel';
  return 'Showing $visibleCount of $totalCount $totalLabel';
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
  List<HermesSession> sessions,
  String? activeSessionId,
) {
  final active = <HermesSession>[];
  final forked = <HermesSession>[];
  final other = <HermesSession>[];
  for (final session in sessions) {
    if (session.id == activeSessionId) {
      active.add(session);
    } else if (session.parentSessionId != null) {
      forked.add(session);
    } else {
      other.add(session);
    }
  }
  return [
    if (active.isNotEmpty)
      _HermesSessionGroup('active', 'Active session', active),
    if (forked.isNotEmpty)
      _HermesSessionGroup('forked', 'Forked sessions', _recentFirst(forked)),
    if (other.isNotEmpty)
      _HermesSessionGroup('other', 'Other sessions', _recentFirst(other)),
  ];
}

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

class _HermesSessionTile extends StatelessWidget {
  const _HermesSessionTile({
    required this.session,
    required this.active,
    required this.canRename,
    required this.canFork,
    required this.canDelete,
    required this.onSelect,
    required this.onRename,
    required this.onFork,
    required this.onDelete,
  });

  final HermesSession session;
  final bool active;
  final bool canRename;
  final bool canFork;
  final bool canDelete;
  final ValueChanged<HermesSession> onSelect;
  final ValueChanged<HermesSession> onRename;
  final ValueChanged<HermesSession> onFork;
  final ValueChanged<HermesSession> onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('hermes-session-row-${session.id}'),
      selected: active,
      leading: active
          ? const Icon(Icons.check_circle_outline)
          : const Icon(Icons.chat_bubble_outline),
      title: Text(
        _safeHermesUiPreview(session.title ?? session.id, maxLength: 96),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          '${session.messageCount} messages',
          if (session.parentSessionId != null)
            'Forked from ${_safeHermesUiPreview(session.parentSessionId!, maxLength: 80)}',
          if (session.lastActive != null)
            'Last active ${_safeHermesUiPreview(session.lastActive!, maxLength: 80)}',
          if (session.preview != null)
            _safeHermesUiPreview(session.preview!, maxLength: 160),
        ].join(' • '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => onSelect(session),
      trailing: PopupMenuButton<String>(
        key: ValueKey('hermes-session-menu-${session.id}'),
        tooltip: 'Session actions',
        onSelected: (value) {
          switch (value) {
            case 'copy':
              unawaited(
                Clipboard.setData(
                  ClipboardData(text: _sessionDetailsSummary(session, active)),
                ),
              );
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                const SnackBar(
                  content: Text('Copied redacted Hermes session details.'),
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
          const PopupMenuItem(value: 'copy', child: Text('Copy details')),
          if (canRename)
            const PopupMenuItem(value: 'rename', child: Text('Rename')),
          if (canFork) const PopupMenuItem(value: 'fork', child: Text('Fork')),
          if (canDelete)
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }

  String _sessionDetailsSummary(HermesSession session, bool active) {
    final buffer = StringBuffer()
      ..writeln('Hermes session')
      ..writeln(
        'Title: ${_safeHermesUiPreview(session.title ?? session.id, maxLength: 96)}',
      )
      ..writeln('ID: ${_safeHermesUiPreview(session.id, maxLength: 120)}')
      ..writeln('Active: $active')
      ..writeln('Messages: ${session.messageCount}');
    if (session.parentSessionId != null) {
      buffer.writeln(
        'Forked from: ${_safeHermesUiPreview(session.parentSessionId!, maxLength: 120)}',
      );
    }
    if (session.lastActive != null) {
      buffer.writeln(
        'Last active: ${_safeHermesUiPreview(session.lastActive!, maxLength: 120)}',
      );
    }
    if (session.preview != null) {
      buffer.write(
        'Preview: ${_safeHermesUiPreview(session.preview!, maxLength: 240)}',
      );
    }
    return buffer.toString().trimRight();
  }
}
