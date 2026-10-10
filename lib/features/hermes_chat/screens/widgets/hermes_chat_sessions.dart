part of '../hermes_chat_screen.dart';

// Presentation state only; session authority remains with the channel.
class _HermesSessionListState {
  final selectedIds = <String>{};
  String query = '';
  String? selectedSource;
  bool selecting = false;

  void reconcile(HermesChannelState state) {
    if (selectedSource != null &&
        !state.sessions.any((session) => session.source == selectedSource)) {
      selectSource(null);
    }
    if (!state.canDeleteSessions) {
      cancelSelection();
      return;
    }
    final hadSelection = selectedIds.isNotEmpty;
    final selectableIds = {
      for (final session in state.sessions)
        if (!state.isSessionStreaming(session.id)) session.id,
    };
    selectedIds.removeWhere((id) => !selectableIds.contains(id));
    if (hadSelection && selectedIds.isEmpty) selecting = false;
  }

  void selectSource(String? source) {
    selectedSource = source;
    selectedIds.clear();
  }

  void selectAll(List<HermesSession> sessions, HermesChannelState state) {
    selectedIds
      ..clear()
      ..addAll(
        sessions
            .where((session) => !state.isSessionStreaming(session.id))
            .map((session) => session.id),
      );
  }

  void cancelSelection() {
    selecting = false;
    selectedIds.clear();
  }

  void setSelected(String id, bool selected) {
    if (selected) {
      selectedIds.add(id);
    } else {
      selectedIds.remove(id);
    }
  }

  List<HermesSession> selectedSessions(List<HermesSession> sessions) => [
    for (final session in sessions)
      if (selectedIds.contains(session.id)) session,
  ];
}

({String? selectedSource, List<HermesSession> sessions}) _filterHermesSessions(
  List<HermesSession> sessions, {
  required List<String> sourceOptions,
  required String? selectedSource,
  required String query,
  required String? activeSessionId,
}) {
  final source = sourceOptions.contains(selectedSource) ? selectedSource : null;
  final sourceSessions = source == null
      ? sessions
      : sessions
            .where((session) => session.source == source)
            .toList(growable: false);
  final normalizedQuery = query.trim().toLowerCase();
  return (
    selectedSource: source,
    sessions: normalizedQuery.isEmpty
        ? sourceSessions
        : sourceSessions
              .where(
                (session) => _sessionMatchesQuery(
                  session,
                  normalizedQuery,
                  activeSessionId,
                ),
              )
              .toList(growable: false),
  );
}

class _HermesSessionSourceFilter extends StatelessWidget {
  const _HermesSessionSourceFilter({
    required this.keyPrefix,
    required this.sources,
    required this.selectedSource,
    required this.onChanged,
  });

  final String keyPrefix;
  final List<String> sources;
  final String? selectedSource;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = _hermesStrings(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: strings.chatRailSourceFilterLabel,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            key: ValueKey('$keyPrefix-source-filter'),
            value: selectedSource,
            isExpanded: true,
            items: [
              DropdownMenuItem<String?>(
                key: ValueKey('$keyPrefix-source-all'),
                value: null,
                child: Text(strings.chatRailAllSourcesLabel),
              ),
              for (final (index, source) in sources.indexed)
                DropdownMenuItem<String?>(
                  key: ValueKey('$keyPrefix-source-option-$index'),
                  value: source,
                  child: Text(_sessionSourceLabel(context, source)),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _HermesSessionLoadMoreButton extends StatelessWidget {
  const _HermesSessionLoadMoreButton({
    required this.state,
    required this.onPressed,
    required this.buttonKey,
  });

  final HermesChannelState state;
  final VoidCallback onPressed;
  final Key buttonKey;

  @override
  Widget build(BuildContext context) {
    if (!state.hasMoreSessions && !state.isLoadingMoreSessions) {
      return const SizedBox.shrink();
    }
    final strings = _hermesStrings(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: OutlinedButton.icon(
        key: buttonKey,
        onPressed: state.isLoadingMoreSessions ? null : onPressed,
        icon: state.isLoadingMoreSessions
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.expand_more),
        label: Text(
          state.isLoadingMoreSessions
              ? strings.chatRailLoadingMoreSessionsAction
              : strings.chatRailLoadMoreSessionsAction,
        ),
      ),
    );
  }
}

// Volatile disclosure belongs to the rendered channel/host/profile, not a session.
mixin _HermesSessionDisclosure<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  late HermesChannel _disclosureChannel;
  late final ProviderSubscription<HermesChannel> _disclosureSubscription;
  Object? _disclosureOwner;
  int _disclosureGeneration = 0;
  bool _pinnedExpanded = true;
  bool _chatsExpanded = true;

  @override
  void initState() {
    super.initState();
    _disclosureChannel = ref.read(hermesChannelProvider);
    _disclosureChannel.addListener(_checkDisclosureOwner);
    _checkDisclosureOwner();
    _disclosureSubscription = ref.listenManual(hermesChannelProvider, (
      _,
      next,
    ) {
      _disclosureChannel.removeListener(_checkDisclosureOwner);
      _disclosureChannel = next;
      _disclosureChannel.addListener(_checkDisclosureOwner);
      _checkDisclosureOwner();
    });
  }

  void _checkDisclosureOwner() {
    final state = _disclosureChannel.state;
    final owner = (
      _disclosureChannel,
      state.connectedBaseUrl,
      state.selectedProfileId,
    );
    if (owner == _disclosureOwner) return;
    _disclosureOwner = owner;
    _disclosureGeneration++;
    if (!_pinnedExpanded || !_chatsExpanded) {
      setState(() {
        _pinnedExpanded = true;
        _chatsExpanded = true;
      });
    }
  }

  Widget _disclosureHeading(_HermesSessionGroup group) {
    final pinned = group.key == 'pinned';
    final generation = _disclosureGeneration;
    return MergeSemantics(
      key: ValueKey('hermes-session-disclosure-${group.key}'),
      child: Semantics(
        expanded: pinned ? _pinnedExpanded : _chatsExpanded,
        child: TextButton(
          style: TextButton.styleFrom(alignment: Alignment.centerLeft),
          onPressed: () {
            if (!mounted) return;
            _checkDisclosureOwner();
            if (generation != _disclosureGeneration) return;
            setState(() {
              if (pinned) {
                _pinnedExpanded = !_pinnedExpanded;
              } else {
                _chatsExpanded = !_chatsExpanded;
              }
            });
          },
          child: Row(
            children: [
              Icon(
                (pinned ? _pinnedExpanded : _chatsExpanded)
                    ? Icons.expand_more
                    : Icons.chevron_right,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(group.label)),
            ],
          ),
        ),
      ),
    );
  }

  List<_HermesSessionGroup> _disclosedGroups(
    List<HermesSession> sessions,
    AppLocalizations strings,
    Set<String> pinnedIds,
  ) {
    final groups = _sessionGroups(
      sessions,
      strings: strings,
      pinnedSessionIds: pinnedIds,
    );
    return [
      for (final group in groups.where((group) => group.key == 'pinned'))
        _HermesSessionGroup(
          group.key,
          group.label,
          _pinnedExpanded ? group.sessions : const [],
        ),
      _HermesSessionGroup('chats', strings.chatRailChatsGroupLabel, const []),
      if (_chatsExpanded) ...groups.where((group) => group.key != 'pinned'),
    ];
  }

  @override
  void dispose() {
    _disclosureGeneration++;
    _disclosureSubscription.close();
    _disclosureChannel.removeListener(_checkDisclosureOwner);
    super.dispose();
  }
}

class _HermesSessionRail extends ConsumerStatefulWidget {
  const _HermesSessionRail({
    required this.state,
    required this.canCreate,
    required this.onCreate,
    required this.onLoadMore,
    required this.onSelect,
    required this.onRename,
    required this.onFork,
    required this.onDelete,
    required this.onDeleteSelected,
    required this.pinnedSessionIds,
    required this.unreadCompletedSessionIds,
    required this.onTogglePinned,
  });

  final HermesChannelState state;
  final bool canCreate;
  final VoidCallback onCreate;
  final VoidCallback onLoadMore;
  final ValueChanged<HermesSession> onSelect;
  final ValueChanged<HermesSession> onRename;
  final ValueChanged<HermesSession> onFork;
  final ValueChanged<HermesSession> onDelete;
  final ValueChanged<List<HermesSession>> onDeleteSelected;
  final Set<String> pinnedSessionIds;
  final Set<String> unreadCompletedSessionIds;
  final ValueChanged<HermesSession> onTogglePinned;

  @override
  ConsumerState<_HermesSessionRail> createState() => _HermesSessionRailState();
}

class _HermesSessionRailState extends ConsumerState<_HermesSessionRail>
    with _HermesSessionDisclosure<_HermesSessionRail> {
  final _searchController = TextEditingController();
  final _listState = _HermesSessionListState();

  @override
  void didUpdateWidget(covariant _HermesSessionRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    _listState.reconcile(widget.state);
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
    final sortedSourceOptions = _sortedSessionSources(context, allSessions);
    final filtered = _filterHermesSessions(
      allSessions,
      sourceOptions: sortedSourceOptions,
      selectedSource: _listState.selectedSource,
      query: _listState.query,
      activeSessionId: widget.state.activeSessionId,
    );
    final selectedSource = filtered.selectedSource;
    final sessions = filtered.sessions;
    return SizedBox(
      key: const ValueKey('hermes-session-rail'),
      width: 280,
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
                    if (!_listState.selecting)
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
                  child: _listState.selecting
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              strings.chatRailSelectedCountLabel(
                                _listState.selectedIds.length,
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
                                      _listState.selectAll(
                                        sessions,
                                        widget.state,
                                      );
                                    });
                                  },
                                  child: Text(strings.chatRailSelectAllAction),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _listState.cancelSelection();
                                    });
                                  },
                                  child: Text(strings.cancelAction),
                                ),
                                FilledButton.icon(
                                  key: const ValueKey(
                                    'hermes-session-rail-delete-selected',
                                  ),
                                  onPressed: _listState.selectedIds.isEmpty
                                      ? null
                                      : () => widget.onDeleteSelected(
                                          _listState.selectedSessions(
                                            allSessions,
                                          ),
                                        ),
                                  icon: const Icon(Icons.delete_outline),
                                  label: Text(
                                    strings.chatRailDeleteCountAction(
                                      _listState.selectedIds.length,
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
                            onPressed: () =>
                                setState(() => _listState.selecting = true),
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
                      suffixIcon: _listState.query.isEmpty
                          ? null
                          : IconButton(
                              key: const ValueKey(
                                'hermes-session-rail-search-clear',
                              ),
                              tooltip: strings.chatRailClearSearchTooltip,
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _listState.query = '');
                              },
                            ),
                    ),
                    onChanged: (value) =>
                        setState(() => _listState.query = value),
                  ),
                ),
                if (sortedSourceOptions.length > 1)
                  _HermesSessionSourceFilter(
                    keyPrefix: 'hermes-session-rail',
                    sources: sortedSourceOptions,
                    selectedSource: selectedSource,
                    onChanged: (source) =>
                        setState(() => _listState.selectSource(source)),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    _sessionCountSummary(
                      strings: strings,
                      visibleCount: sessions.length,
                      totalCount: allSessions.length,
                      query: _listState.query,
                      filtered: selectedSource != null,
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
                          _safeHermesUiPreview(
                            _listState.query.trim(),
                            maxLength: 64,
                          ),
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
                      for (final group in _disclosedGroups(
                        sessions,
                        strings,
                        widget.pinnedSessionIds,
                      )) ...[
                        if (group.key == 'pinned' || group.key == 'chats')
                          _disclosureHeading(group)
                        else
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
                            unread: widget.unreadCompletedSessionIds.contains(
                              session.id,
                            ),
                            canRename: _canRename,
                            canFork:
                                _canFork &&
                                !widget.state.isSessionStreaming(session.id),
                            canDelete:
                                _canDelete &&
                                !widget.state.isSessionStreaming(session.id),
                            selectionMode: _listState.selecting,
                            selected: _listState.selectedIds.contains(
                              session.id,
                            ),
                            selectable: !widget.state.isSessionStreaming(
                              session.id,
                            ),
                            onSelectionChanged: (selected) {
                              setState(() {
                                _listState.setSelected(session.id, selected);
                              });
                            },
                            onSelect: widget.onSelect,
                            onRename: widget.onRename,
                            onFork: widget.onFork,
                            onDelete: widget.onDelete,
                            pinned: widget.pinnedSessionIds.contains(
                              session.id,
                            ),
                            onTogglePinned: widget.onTogglePinned,
                            highlightQuery: _listState.query,
                          ),
                      ],
                    ],
                  ),
                ),
              _HermesSessionLoadMoreButton(
                state: widget.state,
                onPressed: widget.onLoadMore,
                buttonKey: const ValueKey('hermes-session-rail-load-more'),
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
    required this.hasUnreconciledRun,
    required this.switchableSessions,
    required this.streamingSessionIds,
    required this.unreadCompletedSessionIds,
    required this.onSelectSession,
  });

  final HermesSession session;
  final int messageCount;
  final String modelLabel;
  final bool isTurnActive;
  final bool canSendTurns;
  final bool hasUnreconciledRun;
  final List<HermesSession> switchableSessions;
  final Set<String> streamingSessionIds;
  final Set<String> unreadCompletedSessionIds;
  final ValueChanged<HermesSession> onSelectSession;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final strings = _hermesStrings(context);
    final statusLabel = isTurnActive
        ? strings.chatRailStatusStreamingLabel
        : hasUnreconciledRun
        ? strings.chatErrorRunStillActiveTitle
        : canSendTurns
        ? strings.chatRailStatusReadyLabel
        : strings.chatRailStatusTransportUnavailableLabel;
    final statusIcon = isTurnActive
        ? Icons.autorenew
        : hasUnreconciledRun
        ? Icons.hourglass_top
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            Widget titleChip() => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );

            Widget sessionSwitcher() {
              if (switchableSessions.length < 2) return titleChip();
              return Tooltip(
                message: strings.chatRailCycleActiveSessionsTooltip,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final candidate in switchableSessions) ...[
                        ChoiceChip(
                          key: ValueKey(
                            'hermes-active-session-chip-${candidate.id}',
                          ),
                          selected: candidate.id == session.id,
                          showCheckmark: false,
                          avatar: streamingSessionIds.contains(candidate.id)
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : unreadCompletedSessionIds.contains(candidate.id)
                              ? Icon(
                                  Icons.mark_chat_unread_outlined,
                                  key: ValueKey(
                                    'hermes-active-session-new-reply-${candidate.id}',
                                  ),
                                  size: 16,
                                  semanticLabel: strings.chatRailNewReplyLabel,
                                )
                              : const Icon(Icons.chat_bubble_outline, size: 16),
                          label: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: Text(
                              _safeHermesUiPreview(
                                candidate.title ?? candidate.id,
                                maxLength: 96,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          onSelected: (_) => onSelectSession(candidate),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              );
            }

            final showStatus =
                isTurnActive || hasUnreconciledRun || !canSendTurns;
            final showModel =
                modelLabel != strings.chatLayoutModelFallbackLabel;
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
                  SizedBox(width: titleWidth, child: sessionSwitcher()),
                  if (showStatus) statusChip,
                  if (showModel) modelChip,
                  count,
                ],
              );
            }
            return Row(
              children: [
                Flexible(flex: 3, child: sessionSwitcher()),
                const SizedBox(width: 10),
                if (showStatus) ...[statusChip, const SizedBox(width: 8)],
                if (showModel) ...[modelChip, const SizedBox(width: 8)],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
              fontWeight: FontWeight.w500,
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
    const icons = [
      Icons.chat_bubble_outline,
      Icons.extension_outlined,
      Icons.code,
      Icons.history,
    ];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.waving_hand_outlined,
                size: 28,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                strings.chatRailEmptyStateTitle,
                key: const ValueKey('hermes-empty-state-title'),
                style: theme.textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                strings.chatRailEmptyStateBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              for (var index = 0; index < prompts.length; index++) ...[
                ListTile(
                  key: ValueKey('hermes-empty-prompt-${prompts[index]}'),
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(icons[index], size: 20),
                  trailing: const Icon(Icons.north_east, size: 16),
                  title: Text(prompts[index]),
                  onTap: canSendTurns
                      ? () => onPromptSelected(prompts[index])
                      : null,
                ),
                if (index < prompts.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HermesComposerStrip extends StatelessWidget {
  const _HermesComposerStrip({
    required this.modelLabel,
    required this.isTurnActive,
    required this.canSendTurns,
    required this.hasUnreconciledRun,
    required this.canRetry,
    required this.onStop,
    required this.onRetry,
    required this.onSelectModel,
  });

  final String modelLabel;
  final bool isTurnActive;
  final bool canSendTurns;
  final bool hasUnreconciledRun;
  final bool canRetry;
  final VoidCallback onStop;
  final VoidCallback onRetry;
  final VoidCallback? onSelectModel;

  @override
  Widget build(BuildContext context) {
    final strings = _hermesStrings(context);
    // Keep dynamically inserted Stop/Retry controls in the strip's toolbar slot.
    return FocusTraversalGroup(
      child: SingleChildScrollView(
        key: const ValueKey('hermes-composer-strip'),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (isTurnActive)
              ActionChip(
                key: const ValueKey('hermes-composer-stop-chip'),
                avatar: const Icon(Icons.stop_circle_outlined, size: 18),
                label: Text(strings.chatRailStopAction),
                onPressed: onStop,
              )
            else if (canRetry)
              ActionChip(
                key: const ValueKey('hermes-composer-retry-chip'),
                avatar: const Icon(Icons.refresh, size: 18),
                label: Text(strings.retryAction),
                onPressed: onRetry,
              ),
            if (isTurnActive || canRetry) const SizedBox(width: 8),
            Tooltip(
              message: strings.chatComposerModelPickerTooltip,
              child: ActionChip(
                key: const ValueKey('hermes-composer-model-chip'),
                avatar: const Icon(Icons.memory_outlined, size: 18),
                label: Text(_safeHermesUiPreview(modelLabel, maxLength: 32)),
                onPressed: onSelectModel,
              ),
            ),
            if (!isTurnActive && (hasUnreconciledRun || !canSendTurns)) ...[
              const SizedBox(width: 8),
              _ComposerChip(
                icon: hasUnreconciledRun
                    ? Icons.hourglass_top
                    : canSendTurns
                    ? Icons.bolt_outlined
                    : Icons.block,
                label: hasUnreconciledRun
                    ? strings.chatErrorRunStillActiveTitle
                    : canSendTurns
                    ? strings.chatRailStatusReadyLabel
                    : strings.chatRailStatusTransportUnavailableLabel,
              ),
            ],
          ],
        ),
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

class HermesSessionsPanel extends ConsumerStatefulWidget {
  const HermesSessionsPanel({
    super.key,
    this.autofocusSearch = false,
    this.canLoadMore = true,
    this.inventoryFailed = false,
    required this.state,
    required this.canCreate,
    required this.onCreate,
    required this.onLoadMore,
    required this.onSelect,
    required this.onRename,
    required this.onFork,
    required this.onDelete,
    required this.onDeleteSelected,
    required this.pinnedSessionIds,
    required this.unreadCompletedSessionIds,
    required this.onTogglePinned,
  });

  final HermesChannelState state;
  final bool canCreate;
  final VoidCallback onCreate;
  final VoidCallback onLoadMore;
  final ValueChanged<HermesSession> onSelect;
  final ValueChanged<HermesSession> onRename;
  final ValueChanged<HermesSession> onFork;
  final ValueChanged<HermesSession> onDelete;
  final ValueChanged<List<HermesSession>> onDeleteSelected;
  final Set<String> pinnedSessionIds;
  final Set<String> unreadCompletedSessionIds;
  final ValueChanged<HermesSession> onTogglePinned;

  @override
  ConsumerState<HermesSessionsPanel> createState() =>
      _HermesSessionsPanelState();
  final bool autofocusSearch;
  final bool canLoadMore;
  final bool inventoryFailed;
}

class _HermesSessionsPanelState extends ConsumerState<HermesSessionsPanel>
    with _HermesSessionDisclosure<HermesSessionsPanel> {
  final _searchController = TextEditingController();
  final _listState = _HermesSessionListState();
  (Size, double)? _viewport;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_revealFocus);
  }

  void _revealFocus() {
    final focus = FocusManager.instance.primaryFocus;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || FocusManager.instance.primaryFocus != focus) return;
      final focused = focus?.context;
      var inside = identical(focused, context);
      focused?.visitAncestorElements((ancestor) {
        if (identical(ancestor, context)) inside = true;
        return !inside;
      });
      if (inside && focused != null) {
        Scrollable.ensureVisible(focused, alignment: 0.5);
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewport = (
      MediaQuery.sizeOf(context),
      MediaQuery.textScalerOf(context).scale(14),
    );
    if (_viewport == viewport) return;
    _viewport = viewport;
    // Focus can survive resize while its old scroll offset leaves it clipped.
    // Reveal only the current panel's focus after the new layout has settled.
    _revealFocus();
  }

  @override
  void didUpdateWidget(covariant HermesSessionsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _listState.reconcile(widget.state);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_revealFocus);
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
    final sortedSourceOptions = _sortedSessionSources(context, allSessions);
    final filtered = _filterHermesSessions(
      allSessions,
      sourceOptions: sortedSourceOptions,
      selectedSource: _listState.selectedSource,
      query: _listState.query,
      activeSessionId: widget.state.activeSessionId,
    );
    final selectedSource = filtered.selectedSource;
    final sessions = filtered.sessions;
    return SafeArea(
      key: const ValueKey('hermes-sessions-panel'),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: FocusTraversalGroup(
          child: CustomScrollView(
            key: const ValueKey('hermes-sessions-list'),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final title = Text(
                            strings.chatRailHermesSessionsTitle,
                            style: Theme.of(context).textTheme.titleLarge,
                          );
                          final create =
                              widget.canCreate && !_listState.selecting
                              ? FilledButton.icon(
                                  key: const ValueKey('hermes-sessions-new'),
                                  onPressed: widget.onCreate,
                                  icon: const Icon(Icons.add_comment_outlined),
                                  label: Text(strings.chatRailNewSessionAction),
                                )
                              : null;
                          if (constraints.maxWidth < 400 ||
                              MediaQuery.textScalerOf(context).scale(14) > 18) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                title,
                                if (create != null) ...[
                                  const SizedBox(height: 8),
                                  create,
                                ],
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: title),
                              if (create != null) ...[
                                const SizedBox(width: 8),
                                create,
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                    if (_canDelete && allSessions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: _listState.selecting
                            ? Wrap(
                                alignment: WrapAlignment.end,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Text(
                                    strings.chatRailSelectedCountLabel(
                                      _listState.selectedIds.length,
                                    ),
                                  ),
                                  TextButton(
                                    key: const ValueKey(
                                      'hermes-sessions-select-all',
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _listState.selectAll(
                                          sessions,
                                          widget.state,
                                        );
                                      });
                                    },
                                    child: Text(
                                      strings.chatRailSelectAllAction,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _listState.cancelSelection();
                                      });
                                    },
                                    child: Text(strings.cancelAction),
                                  ),
                                  FilledButton.icon(
                                    key: const ValueKey(
                                      'hermes-sessions-delete-selected',
                                    ),
                                    onPressed: _listState.selectedIds.isEmpty
                                        ? null
                                        : () => widget.onDeleteSelected(
                                            _listState.selectedSessions(
                                              allSessions,
                                            ),
                                          ),
                                    icon: const Icon(Icons.delete_outline),
                                    label: Text(
                                      strings.chatRailDeleteCountAction(
                                        _listState.selectedIds.length,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  key: const ValueKey('hermes-sessions-select'),
                                  onPressed: () => setState(
                                    () => _listState.selecting = true,
                                  ),
                                  icon: const Icon(Icons.checklist_outlined),
                                  label: Text(strings.chatRailSelectAction),
                                ),
                              ),
                      ),
                    if (allSessions.isNotEmpty || widget.autofocusSearch) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: TextField(
                          key: const ValueKey('hermes-session-search-field'),
                          autofocus: widget.autofocusSearch,
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: strings.chatRailSearchSessionsLabel,
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _listState.query.isEmpty
                                ? null
                                : IconButton(
                                    key: const ValueKey(
                                      'hermes-session-search-clear',
                                    ),
                                    tooltip: strings.chatRailClearSearchTooltip,
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _listState.query = '');
                                    },
                                  ),
                          ),
                          onChanged: (value) =>
                              setState(() => _listState.query = value),
                        ),
                      ),
                      if (sortedSourceOptions.length > 1)
                        _HermesSessionSourceFilter(
                          keyPrefix: 'hermes-session',
                          sources: sortedSourceOptions,
                          selectedSource: selectedSource,
                          onChanged: (source) =>
                              setState(() => _listState.selectSource(source)),
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
                              query: _listState.query,
                              filtered: selectedSource != null,
                            ),
                            key: const ValueKey('hermes-session-count-summary'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (allSessions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      widget.inventoryFailed
                          ? strings.shellSessionFailed
                          : strings.chatRailNoHermesSessionsBody,
                    ),
                  ),
                )
              else if (sessions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      strings.chatRailNoHermesSessionsMatchBody(
                        _safeHermesUiPreview(
                          _listState.query.trim(),
                          maxLength: 64,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverList.list(
                  children: [
                    for (final group in _disclosedGroups(
                      sessions,
                      strings,
                      widget.pinnedSessionIds,
                    )) ...[
                      if (group.key == 'pinned' || group.key == 'chats')
                        _disclosureHeading(group)
                      else
                        Padding(
                          key: ValueKey('hermes-session-group-${group.key}'),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
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
                          unread: widget.unreadCompletedSessionIds.contains(
                            session.id,
                          ),
                          canRename: _canRename,
                          canFork:
                              _canFork &&
                              !widget.state.isSessionStreaming(session.id),
                          canDelete:
                              _canDelete &&
                              !widget.state.isSessionStreaming(session.id),
                          selectionMode: _listState.selecting,
                          selected: _listState.selectedIds.contains(session.id),
                          selectable: !widget.state.isSessionStreaming(
                            session.id,
                          ),
                          onSelectionChanged: (selected) {
                            setState(() {
                              _listState.setSelected(session.id, selected);
                            });
                          },
                          onSelect: widget.onSelect,
                          onRename: widget.onRename,
                          onFork: widget.onFork,
                          onDelete: widget.onDelete,
                          pinned: widget.pinnedSessionIds.contains(session.id),
                          onTogglePinned: widget.onTogglePinned,
                          highlightQuery: _listState.query,
                        ),
                    ],
                  ],
                ),
              if (widget.canLoadMore)
                SliverToBoxAdapter(
                  child: _HermesSessionLoadMoreButton(
                    state: widget.state,
                    onPressed: widget.onLoadMore,
                    buttonKey: const ValueKey('hermes-sessions-load-more'),
                  ),
                ),
            ],
          ),
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
  bool filtered = false,
}) {
  if (!filtered && query.trim().isEmpty) {
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
  Set<String> pinnedSessionIds = const {},
  DateTime? now,
}) {
  final reference = (now ?? DateTime.now()).toLocal();
  final sorted = _recentFirst(sessions);
  final pinned = [
    for (final session in sorted)
      if (pinnedSessionIds.contains(session.id)) session,
  ];
  final grouped = <String, List<HermesSession>>{};
  for (final session in sorted) {
    if (pinnedSessionIds.contains(session.id)) continue;
    final key = _sessionDateGroup(session, reference);
    (grouped[key] ??= []).add(session);
  }
  return [
    if (pinned.isNotEmpty)
      _HermesSessionGroup('pinned', strings.chatRailPinnedGroupLabel, pinned),
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

List<String> _sortedSessionSources(
  BuildContext context,
  List<HermesSession> sessions,
) {
  final sources = sessions.map((session) => session.source).toSet()
    ..removeWhere((source) => source.trim().isEmpty);
  return sources.toList(growable: false)..sort(
    (left, right) => _sessionSourceLabel(context, left).toLowerCase().compareTo(
      _sessionSourceLabel(context, right).toLowerCase(),
    ),
  );
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

List<RegExpMatch> _sessionSearchMatches(String text, String query) {
  final needle = query.trim();
  if (needle.isEmpty) return const [];
  return RegExp(
    RegExp.escape(needle),
    caseSensitive: false,
  ).allMatches(text).toList(growable: false);
}

Text _sessionSearchText(
  BuildContext context, {
  required Key key,
  required String text,
  required String query,
  required int maxLines,
}) {
  final matches = _sessionSearchMatches(text, query);
  if (matches.isEmpty) {
    return Text(
      text,
      key: key,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  final highlightStyle = TextStyle(
    color: Theme.of(context).colorScheme.onTertiaryContainer,
    backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
    fontWeight: FontWeight.w700,
  );
  final spans = <InlineSpan>[];
  var offset = 0;
  for (final match in matches) {
    if (match.start > offset) {
      spans.add(TextSpan(text: text.substring(offset, match.start)));
    }
    spans.add(
      TextSpan(
        text: text.substring(match.start, match.end),
        style: highlightStyle,
      ),
    );
    offset = match.end;
  }
  if (offset < text.length) {
    spans.add(TextSpan(text: text.substring(offset)));
  }
  return Text.rich(
    TextSpan(children: spans),
    key: key,
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
  );
}

class _HermesSessionTile extends ConsumerStatefulWidget {
  const _HermesSessionTile({
    required this.session,
    required this.active,
    required this.streaming,
    required this.failed,
    required this.unread,
    required this.canRename,
    required this.canFork,
    required this.canDelete,
    required this.onSelect,
    required this.onRename,
    required this.onFork,
    required this.onDelete,
    required this.pinned,
    required this.onTogglePinned,
    required this.highlightQuery,
    this.selectionMode = false,
    this.selected = false,
    this.selectable = true,
    this.onSelectionChanged,
  });

  final HermesSession session;
  final bool active;
  final bool streaming;
  final bool failed;
  final bool unread;
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
  final bool pinned;
  final ValueChanged<HermesSession> onTogglePinned;
  final String highlightQuery;

  @override
  ConsumerState<_HermesSessionTile> createState() => _HermesSessionTileState();
}

class _HermesSessionTileState extends ConsumerState<_HermesSessionTile> {
  late HermesChannel _channel;
  late final ProviderSubscription<HermesChannel> _channelSubscription;
  Object? _copyOwner;
  int _copyGeneration = 0;
  int? _menuGeneration;
  bool _idCopyPending = false;
  String? _idCopyFeedback;

  @override
  void initState() {
    super.initState();
    _channel = ref.read(hermesChannelProvider);
    _channel.addListener(_checkCopyOwner);
    _checkCopyOwner();
    _channelSubscription = ref.listenManual(hermesChannelProvider, (_, next) {
      _channel.removeListener(_checkCopyOwner);
      _channel = next;
      _channel.addListener(_checkCopyOwner);
      _checkCopyOwner();
    });
  }

  void _checkCopyOwner() {
    final state = _channel.state;
    final owner = (
      _channel,
      state.connectedBaseUrl,
      state.selectedProfileId,
      state.activeSessionId,
      state.status,
      state.isSelectingProfile,
      widget.session.id,
      state.sessions.any((row) => row.id == widget.session.id),
    );
    if (owner == _copyOwner) return;
    _copyOwner = owner;
    _copyGeneration++;
    if (_idCopyFeedback != null) setState(() => _idCopyFeedback = null);
  }

  @override
  void didUpdateWidget(covariant _HermesSessionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkCopyOwner();
  }

  @override
  void dispose() {
    _channelSubscription.close();
    _channel.removeListener(_checkCopyOwner);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _HermesSessionTile(
      :session,
      :active,
      :streaming,
      :failed,
      :unread,
      :canRename,
      :canFork,
      :canDelete,
      :onSelect,
      :onRename,
      :onFork,
      :onDelete,
      :pinned,
      :onTogglePinned,
      :highlightQuery,
      :selectionMode,
      :selected,
      :selectable,
      :onSelectionChanged,
    ) = widget;
    final strings = _hermesStrings(context);
    final title = _safeHermesUiPreview(
      session.title ?? session.id,
      maxLength: 96,
    );
    final preview = session.preview == null
        ? null
        : _safeHermesUiPreview(session.preview!, maxLength: 160);
    final prioritizePreview =
        preview != null &&
        _sessionSearchMatches(preview, highlightQuery).isNotEmpty;
    final subtitle = [
      if (prioritizePreview) preview,
      _sessionSourceLabel(context, session.source),
      if (session.model?.trim().isNotEmpty ?? false)
        _safeHermesUiPreview(session.model!.trim(), maxLength: 80),
      strings.chatRailTileMessageCountLabel(session.messageCount),
      if (unread) strings.chatRailNewReplyLabel,
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
      if (!prioritizePreview && preview != null) preview,
    ].join(' • ');
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
          : unread
          ? Icon(
              Icons.mark_chat_unread_outlined,
              key: ValueKey('hermes-session-new-reply-${session.id}'),
              color: Theme.of(context).colorScheme.primary,
              semanticLabel: strings.chatRailNewReplyLabel,
            )
          : active
          ? const Icon(Icons.check_circle_outline)
          : const Icon(Icons.chat_bubble_outline),
      title: _sessionSearchText(
        context,
        key: ValueKey('hermes-session-title-${session.id}'),
        text: title,
        query: highlightQuery,
        maxLines: 1,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sessionSearchText(
            context,
            key: ValueKey('hermes-session-subtitle-${session.id}'),
            text: subtitle,
            query: highlightQuery,
            maxLines: 2,
          ),
          if (_idCopyFeedback != null)
            Semantics(liveRegion: true, child: Text(_idCopyFeedback!)),
        ],
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
              onOpened: () => _menuGeneration = _copyGeneration,
              onCanceled: () => _menuGeneration = null,
              onSelected: (value) async {
                switch (value) {
                  case 'copy-id':
                    if (!mounted) return;
                    final generation = _menuGeneration;
                    _menuGeneration = null;
                    _checkCopyOwner();
                    if (_idCopyPending || generation != _copyGeneration) return;
                    if (_channel.state.isSelectingProfile ||
                        !_channel.state.sessions.any(
                          (row) => row.id == session.id,
                        )) {
                      return;
                    }
                    _idCopyPending = true;
                    setState(() => _idCopyFeedback = null);
                    final copied = await _writeSessionDetailsClipboard(
                      session.id,
                    );
                    _idCopyPending = false;
                    if (!mounted || generation != _copyGeneration) return;
                    // Keep feedback in the row: a compact modal hides the
                    // underlying Scaffold's snackbar from accessibility.
                    setState(
                      () => _idCopyFeedback = copied
                          ? strings.chatRailCopiedSessionIdBody
                          : strings.chatRailCopySessionIdFailedBody,
                    );
                  case 'pin':
                    onTogglePinned(session);
                  case 'details':
                    unawaited(_showSessionDetails(context, session, active));
                  case 'copy':
                    final copied = await _writeSessionDetailsClipboard(
                      _sessionDetailsSummary(context, session, active),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      SnackBar(
                        content: Text(
                          copied
                              ? strings.chatRailCopiedSessionDetailsBody
                              : strings.chatRailCopySessionDetailsFailedBody,
                        ),
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
                  value: 'pin',
                  child: Text(
                    pinned
                        ? strings.chatRailUnpinSessionAction
                        : strings.chatRailPinSessionAction,
                  ),
                ),
                PopupMenuItem(
                  value: 'details',
                  child: Text(strings.chatRailViewDetailsAction),
                ),
                PopupMenuItem(
                  value: 'copy',
                  child: Text(strings.chatRailCopyDetailsAction),
                ),
                PopupMenuItem(
                  value: 'copy-id',
                  child: Text(strings.chatRailCopySessionIdAction),
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

  Future<bool> _writeSessionDetailsClipboard(String summary) async {
    try {
      await Clipboard.setData(ClipboardData(text: summary));
      return true;
    } catch (_) {
      // Platform diagnostics may contain sensitive data; show only fixed copy.
      return false;
    }
  }

  Future<void> _showSessionDetails(
    BuildContext context,
    HermesSession session,
    bool active,
  ) {
    final summary = _sessionDetailsSummary(context, session, active);
    var copyFailed = false;
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
              StatefulBuilder(
                builder: (copyContext, setCopyState) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        final copied = await _writeSessionDetailsClipboard(
                          summary,
                        );
                        if (!copyContext.mounted || !context.mounted) return;
                        if (!copied) {
                          setCopyState(() => copyFailed = true);
                          return;
                        }
                        Navigator.of(copyContext).pop();
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
                        _hermesStrings(copyContext).chatRailCopyDetailsAction,
                      ),
                    ),
                    if (copyFailed) ...[
                      const SizedBox(height: 8),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _hermesStrings(
                            copyContext,
                          ).chatRailCopySessionDetailsFailedBody,
                        ),
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
