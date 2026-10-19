part of '../screens/hermes_chat_screen.dart';

// Only visited presentation identities live here. Transcripts, runs and approvals
// remain with the channel/Agent; a dormant owner must be restored before control.
class _HermesWorkspaceTab {
  const _HermesWorkspaceTab(this.key, this.origin, this.title, this.hostLabel);
  final HermesComposerDraftKey key;
  final String? origin;
  final String title;
  final String? hostLabel;
}

extension _HermesChatSessionWorkspace on _HermesChatScreenState {
  void _rememberWorkspaceTab(HermesChannel channel) {
    // Native serve selection currently retires its single lifecycle without a
    // terminal readback barrier. Do not offer tabs over history-only reads.
    if (channel.state.isServeReadOnly ||
        _editingConnection ||
        _profileSwitchPending ||
        _gatewayDirectory.isActivating ||
        channel.state.isSelectingProfile) {
      return;
    }
    final key = _composerDraftKey(channel.state);
    final session = channel.state.activeSession;
    if (key == null || session == null) {
      return;
    }
    _workspaceTabs[key] = _HermesWorkspaceTab(
      key,
      channel.state.connectedBaseUrl,
      _safeHermesUiPreview(session.title ?? session.id, maxLength: 96),
      _gatewayDirectory.activeContact?.gatewayLabel,
    );
    while (_workspaceTabs.length > 32) {
      _workspaceTabs.remove(
        _workspaceTabs.keys.firstWhere((candidate) => candidate != key),
      );
    }
  }

  bool _workspaceOwnerMatches(_HermesWorkspaceTab tab, HermesChannel channel) {
    final state = channel.state;
    final contact = _gatewayDirectory.activeContactId;
    return identical(ref.read(hermesChannelProvider), channel) &&
        state.isConnected &&
        !state.isServeReadOnly &&
        !state.isSelectingProfile &&
        !_profileSwitchPending &&
        !_sessionRestorationUnsettled &&
        state.connectedBaseUrl == tab.origin &&
        (contact?.gatewayId ?? state.connectedBaseUrl ?? 'direct') ==
            tab.key.gatewayId &&
        (state.selectedProfileId ?? contact?.profileId) == tab.key.profileId;
  }

  Future<void> _openWorkspaceTab(_HermesWorkspaceTab tab) async {
    if (!mounted ||
        _workspaceOpening ||
        !identical(_workspaceTabs[tab.key], tab)) {
      return;
    }
    final channel = ref.read(hermesChannelProvider);
    if (channel.state.isServeReadOnly) return;
    final directory = _gatewayDirectory;
    if (_workspaceOwnerMatches(tab, channel) &&
        channel.state.activeSessionId == tab.key.sessionId) {
      return;
    }
    final generation = _composerOwnerGeneration;
    _setState(() => _workspaceOpening = true);
    bool sameSource() =>
        mounted &&
        identical(ref.read(hermesChannelProvider), channel) &&
        identical(_gatewayDirectory, directory);
    try {
      if (!_workspaceOwnerMatches(tab, channel)) {
        if (!await _confirmLeaveActiveContact(channel) ||
            !sameSource() ||
            generation != _composerOwnerGeneration) {
          return;
        }
        _voiceInputController.pause();
        _followUps.clear();
        _approvals.clearPending();
        final contact = GatewayContactId(
          gatewayId: tab.key.gatewayId,
          profileId: tab.key.profileId ?? 'default',
        );
        final config = directory.configForGateway(tab.key.gatewayId);
        if (config != null &&
            config.baseUrl == tab.origin &&
            directory.contacts.any((candidate) => candidate.id == contact)) {
          await directory.activate(
            contact,
            preferredSessionId: tab.key.sessionId,
          );
          if (!sameSource() ||
              !_workspaceOwnerMatches(tab, channel) ||
              channel.state.activeSessionId != tab.key.sessionId) {
            return;
          }
        } else {
          // Unsaved direct connections can re-home only within this origin.
          // Never acquire another host's credential or invent a fallback session.
          if (directory.activeContactId != null ||
              channel.state.connectedBaseUrl != tab.origin ||
              tab.key.gatewayId != tab.origin ||
              tab.key.profileId == null) {
            throw StateError('Workspace owner is unavailable.');
          }
          await channel.selectProfile(
            tab.key.profileId!,
            deferSessionSelection: true,
          );
          if (!sameSource() || !_workspaceOwnerMatches(tab, channel)) return;
          await channel.restoreSession(
            tab.key.sessionId,
            canAccept: () =>
                sameSource() && _workspaceOwnerMatches(tab, channel),
          );
        }
      } else {
        await channel.selectSession(
          tab.key.sessionId,
          canAccept: () => sameSource() && _workspaceOwnerMatches(tab, channel),
        );
      }
      if (!sameSource() ||
          !_workspaceOwnerMatches(tab, channel) ||
          channel.state.activeSessionId != tab.key.sessionId) {
        return;
      }
      _rememberWorkspaceTab(channel);
      await _scheduleDesktopComposerFocus(
        canFocus: () =>
            sameSource() &&
            _workspaceOwnerMatches(tab, channel) &&
            channel.state.activeSessionId == tab.key.sessionId,
      );
    } catch (_) {
      if (mounted && sameSource()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_hermesStrings(context).chatWorkspaceOpenFailed),
          ),
        );
      }
    } finally {
      _workspaceOpening = false;
      if (mounted) _setState(() {});
    }
  }

  Future<void> _removeWorkspaceTab(
    _HermesWorkspaceTab tab,
    HermesChannel channel,
  ) async {
    _workspaceTabs.remove(tab.key);
    if (_workspaceOwnerMatches(tab, channel) &&
        channel.state.activeSessionId == tab.key.sessionId) {
      channel.clearActiveSession();
      final next = _workspaceTabs.values.lastOrNull;
      if (next != null) await _openWorkspaceTab(next);
    }
    if (mounted) _setState(() {});
  }

  Future<void> _closeWorkspaceTab(_HermesWorkspaceTab tab) async {
    if (!mounted ||
        _workspaceOpening ||
        _workspaceClosing ||
        !identical(_workspaceTabs[tab.key], tab)) {
      return;
    }
    final channel = ref.read(hermesChannelProvider);
    if (channel.state.isServeReadOnly) return;
    var invalidated = false;
    final target = _isTurnActive(channel.state)
        ? channel.activeTurnInterruptionTarget
        : null;
    final strings = _hermesStrings(context);
    bool owns() =>
        mounted &&
        !invalidated &&
        _workspaceOwnerMatches(tab, channel) &&
        channel.state.activeSessionId == tab.key.sessionId;
    bool canStopNow() {
      final capabilities = channel.state.capabilities;
      if (!owns() || capabilities == null || target == null) return false;
      final policy = HermesTransportPolicy(capabilities);
      return target.matches(channel.activeTurnInterruptionTarget) &&
          target.runId != null &&
          policy.supportsRunStop &&
          policy.supportsRunStatus;
    }

    final current = owns();
    final running = current && _isTurnActive(channel.state);
    final uncertain = current && channel.state.hasUnreconciledRun;
    if (current && !running && !uncertain) {
      await _removeWorkspaceTab(tab, channel);
      return;
    }
    // Reconciliation changes readiness, not ownership. Observe resource loss
    // synchronously so A→B→A cannot revive A's dialog or late Stop result.
    void observe() {
      if (!owns()) invalidated = true;
    }

    final directory = _gatewayDirectory;
    channel.addListener(observe);
    directory.addListener(observe);
    final subscription = ref.listenManual(
      hermesChannelProvider,
      (_, _) => observe(),
    );
    final navigator = Navigator.of(context, rootNavigator: true);
    DialogRoute<bool>? dialogRoute;
    var disposed = false;
    void disposeClose() {
      if (disposed) return;
      disposed = true;
      invalidated = true;
      subscription.close();
      channel.removeListener(observe);
      directory.removeListener(observe);
      _workspaceCloseDisposals.remove(disposeClose);
      final route = dialogRoute;
      if (route != null && route.isActive) {
        // Chat can disappear below its root dialog during a build. Remove only
        // this owned route after Navigator unlocks, never a replacement overlay.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (navigator.mounted && route.isActive) navigator.removeRoute(route);
        });
      }
    }

    _workspaceCloseDisposals.add(disposeClose);
    _setState(() => _workspaceClosing = true);
    var pending = false;
    var failed = false;
    var open = false;
    try {
      final route = DialogRoute<bool>(
        context: context,
        themes: InheritedTheme.capture(from: context, to: navigator.context),
        barrierDismissible: false,
        traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, update) => AnimatedBuilder(
            animation: Listenable.merge([channel, _gatewayDirectory]),
            builder: (context, _) {
              final canStop = canStopNow();
              return PopScope(
                canPop: !pending,
                child: AlertDialog(
                  title: Text(strings.chatWorkspaceCloseTitle(tab.title)),
                  content: Text(
                    !current
                        ? strings.chatWorkspaceReopenBody
                        : failed || uncertain
                        ? strings.chatWorkspaceCloseUncertain
                        : canStop
                        ? strings.chatWorkspaceStopCloseBody
                        : strings.chatWorkspaceStopUnavailable,
                    key: ValueKey(
                      !current
                          ? 'hermes-workspace-reopen'
                          : failed || uncertain
                          ? 'hermes-workspace-close-uncertain'
                          : canStop
                          ? 'hermes-workspace-stop-explanation'
                          : 'hermes-workspace-stop-unavailable',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: pending
                          ? null
                          : () => Navigator.pop(dialogContext, false),
                      child: Text(strings.chatWorkspaceKeepOpen),
                    ),
                    if (!current)
                      FilledButton(
                        onPressed: pending
                            ? null
                            : () {
                                open = true;
                                Navigator.pop(dialogContext, false);
                              },
                        child: Text(strings.chatLayoutOpenSessionAction),
                      ),
                    if (current && !canStop)
                      TextButton(
                        onPressed: pending || !owns()
                            ? null
                            : () async {
                                if (pending || !owns()) return;
                                update(() => pending = true);
                                try {
                                  await _reconnect(channel);
                                } finally {
                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext, false);
                                  }
                                }
                              },
                        child: Text(strings.chatErrorReconnectAction),
                      ),
                    if (canStop)
                      FilledButton(
                        key: const ValueKey('hermes-workspace-stop-close'),
                        onPressed: pending
                            ? null
                            : () async {
                                if (!canStopNow()) return;
                                update(() => pending = true);
                                var confirmed = false;
                                try {
                                  confirmed = await channel.stopTurn(target!);
                                } catch (_) {
                                  /* Unknown is not stopped. */
                                }
                                if (!dialogContext.mounted) return;
                                if (confirmed &&
                                    owns() &&
                                    !channel.state.hasUnreconciledRun &&
                                    !_isTurnActive(channel.state)) {
                                  _approvals.dismissStoppedTurn(target!);
                                  Navigator.pop(dialogContext, true);
                                } else {
                                  update(() {
                                    pending = false;
                                    failed = true;
                                  });
                                }
                              },
                        child: Text(strings.chatWorkspaceStopClose),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      dialogRoute = route;
      final close = await navigator.push(route);
      if (close == true && owns()) await _removeWorkspaceTab(tab, channel);
      if (open && mounted) await _openWorkspaceTab(tab);
    } finally {
      disposeClose();
      _workspaceClosing = false;
      if (mounted) _setState(() {});
    }
  }

  Widget _buildWorkspaceTabs(HermesChannel channel) {
    final state = channel.state;
    final selected = _composerDraftKey(state);
    final strings = _hermesStrings(context);
    return SizedBox(
      height: 64,
      child: Semantics(
        container: true,
        label: strings.chatWorkspaceTabsLabel,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final tab in _workspaceTabs.values)
                Padding(
                  key: ValueKey(('hermes-workspace-tab', tab.key)),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ChoiceChip(
                        key: _workspaceOwnerMatches(tab, channel)
                            ? ValueKey(
                                'hermes-active-session-chip-${tab.key.sessionId}',
                              )
                            : null,
                        selected: tab.key == selected,
                        showCheckmark: false,
                        tooltip: strings.chatWorkspaceTabLabel(
                          tab.title,
                          tab.key.profileId ?? 'default',
                          tab.hostLabel ?? strings.chatShellHermesTitle,
                        ),
                        avatar:
                            _workspaceOwnerMatches(tab, channel) &&
                                state.isSessionStreaming(tab.key.sessionId)
                            ? const Icon(Icons.autorenew, size: 18)
                            : _workspaceOwnerMatches(tab, channel) &&
                                  _unreadCompletedSessionIds.contains(
                                    tab.key.sessionId,
                                  )
                            ? Icon(
                                Icons.mark_chat_unread_outlined,
                                key: ValueKey(
                                  'hermes-active-session-new-reply-${tab.key.sessionId}',
                                ),
                                size: 18,
                                semanticLabel: strings.chatRailNewReplyLabel,
                              )
                            : const Icon(Icons.chat_bubble_outline, size: 18),
                        label: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 190),
                          child: Text(
                            tab.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onSelected: _workspaceOpening
                            ? null
                            : (_) => unawaited(_openWorkspaceTab(tab)),
                      ),
                      IconButton(
                        key: ValueKey(('hermes-workspace-close', tab.key)),
                        tooltip: strings.chatWorkspaceCloseTitle(tab.title),
                        onPressed: _workspaceOpening || _workspaceClosing
                            ? null
                            : () => unawaited(_closeWorkspaceTab(tab)),
                        icon: const Icon(Icons.close, size: 18),
                      ),
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
