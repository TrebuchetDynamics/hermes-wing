part of '../screens/hermes_chat_screen.dart';

enum _SessionMutation { rename, fork, delete }

extension _HermesChatScreenSessionActions on _HermesChatScreenState {
  Future<void> _withSessionSettlementOwner(
    HermesChannel channel,
    Future<void> Function(bool Function() isCurrent) action,
  ) async {
    final owner = channel.state;
    final directory = _gatewayDirectory;
    final contact = directory.activeContactId;
    var invalidated = false;
    bool isCurrent() =>
        !invalidated &&
        mounted &&
        identical(ref.read(hermesChannelProvider), channel) &&
        directory.activeContactId == contact &&
        !_profileSwitchPending &&
        channel.state.isConnected &&
        !channel.state.isSelectingProfile &&
        channel.state.connectedBaseUrl == owner.connectedBaseUrl &&
        channel.state.selectedProfileId == owner.selectedProfileId;
    void observe() {
      // Owner loss is permanent, including loss/return before the next frame.
      // Active-session changes belong to create/open itself, not this fence.
      if (!isCurrent()) invalidated = true;
    }

    if (!isCurrent()) return;
    channel.addListener(observe);
    directory.addListener(observe);
    final subscription = ref.listenManual(
      hermesChannelProvider,
      (_, _) => observe(),
    );
    void disposeOwner() {
      invalidated = true;
      subscription.close();
      channel.removeListener(observe);
      directory.removeListener(observe);
      _sessionSettlementDisposals.remove(disposeOwner);
    }

    _sessionSettlementDisposals.add(disposeOwner);
    try {
      await action(isCurrent);
    } finally {
      if (_sessionSettlementDisposals.contains(disposeOwner)) disposeOwner();
    }
  }

  Future<void> _withSessionMutationIntent(
    HermesChannel channel,
    List<HermesSession> sessions,
    _SessionMutation operation,
    Future<void> Function(
      bool Function() isCurrent,
      bool Function(String) submit,
    )
    action,
  ) async {
    final owner = channel.state;
    final contact = _gatewayDirectory.activeContactId;
    final pending = sessions.map((session) => session.id).toSet();
    var invalidated = false;
    bool isCurrent() =>
        !invalidated &&
        mounted &&
        identical(ref.read(hermesChannelProvider), channel) &&
        _gatewayDirectory.activeContactId == contact &&
        !_sessionRestorationUnsettled &&
        !_profileSwitchPending &&
        channel.state.isConnected &&
        !channel.state.isSelectingProfile &&
        channel.state.connectedBaseUrl == owner.connectedBaseUrl &&
        channel.state.selectedProfileId == owner.selectedProfileId &&
        switch (operation) {
          _SessionMutation.rename => channel.state.canUpdateSessions,
          _SessionMutation.fork => channel.state.canForkSessions,
          _SessionMutation.delete => channel.state.canDeleteSessions,
        };
    bool known(String id) =>
        channel.state.sessions.any((session) => session.id == id) &&
        (operation == _SessionMutation.rename ||
            !channel.state.isSessionStreaming(id));
    void observe() {
      // Returning to A before the next frame never revives A's intent.
      // Submitted rows may disappear as a result of our own deletion.
      if (!isCurrent() || pending.any((id) => !known(id))) invalidated = true;
    }

    bool submit(String id) {
      observe();
      return isCurrent() && pending.remove(id);
    }

    observe();
    if (!isCurrent() || pending.isEmpty) return;
    channel.addListener(observe);
    _gatewayDirectory.addListener(observe);
    final subscription = ref.listenManual(
      hermesChannelProvider,
      (_, _) => observe(),
    );
    void disposeIntent() {
      invalidated = true;
      subscription.close();
      channel.removeListener(observe);
      _gatewayDirectory.removeListener(observe);
      _sessionMutationDisposals.remove(disposeIntent);
    }

    _sessionMutationDisposals.add(disposeIntent);
    try {
      await action(isCurrent, submit);
    } finally {
      if (_sessionMutationDisposals.contains(disposeIntent)) disposeIntent();
    }
  }

  Future<void> _createSession(
    BuildContext context,
    HermesChannel channel,
  ) async {
    if (_sessionRestorationUnsettled) return;
    await _withSessionSettlementOwner(channel, (isCurrent) async {
      try {
        await channel.createSession();
        if (!isCurrent()) return;
        _refreshActiveGatewayContact();
      } catch (error) {
        if (!context.mounted || !isCurrent()) return;
        final strings = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.chatSessionActionCreateFailedBody(
                _safeHermesUiError(error),
              ),
            ),
          ),
        );
      }
    });
  }

  Future<void> _selectSession(
    BuildContext context,
    HermesChannel channel,
    HermesSession session,
  ) async {
    if (!_canChooseRestorationSession(channel)) return;
    await _withSessionSettlementOwner(channel, (isCurrent) async {
      try {
        _gatewayDirectory.supersedeSessionRestoration();
        await channel.selectSession(session.id);
        if (context.mounted &&
            isCurrent() &&
            channel.state.activeSessionId == session.id) {
          await _scheduleDesktopComposerFocus(
            canFocus: () =>
                isCurrent() && channel.state.activeSessionId == session.id,
          );
        }
      } catch (error) {
        if (!context.mounted || !isCurrent()) return;
        final strings = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.chatSessionActionOpenFailedBody(
                _safeHermesUiError(error),
              ),
            ),
          ),
        );
      }
    });
  }

  Future<void> _renameSession(
    BuildContext context,
    HermesChannel channel,
    HermesSession session,
  ) => _withSessionMutationIntent(channel, [session], _SessionMutation.rename, (
    isCurrent,
    submit,
  ) async {
    final currentTitle = session.title ?? '';
    var draftTitle = _safeHermesRenameDefault(currentTitle);
    final nextTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        final strings = AppLocalizations.of(context);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final normalized = draftTitle.trim();
            final canSave = normalized.isNotEmpty && normalized != currentTitle;
            void save() {
              if (canSave) Navigator.of(context).pop(normalized);
            }

            return AlertDialog(
              title: Text(strings.chatSessionActionRenameTitle),
              content: TextFormField(
                key: const ValueKey('hermes-session-title-field'),
                initialValue: draftTitle,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: strings.chatSessionActionTitleFieldLabel,
                ),
                onChanged: (value) {
                  draftTitle = value;
                  setDialogState(() {});
                },
                onFieldSubmitted: (_) => save(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(strings.cancelAction),
                ),
                FilledButton(
                  key: const ValueKey('hermes-session-title-save'),
                  onPressed: canSave ? save : null,
                  child: Text(strings.saveAction),
                ),
              ],
            );
          },
        );
      },
    );
    final title = nextTitle?.trim();
    if (title == null || title.isEmpty || title == currentTitle) return;
    if (!submit(session.id)) return;
    try {
      await channel.renameSession(sessionId: session.id, title: title);
      if (!isCurrent()) return;
      _refreshActiveGatewayContact();
    } catch (error) {
      if (!context.mounted || !isCurrent()) return;
      final strings = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.chatSessionActionRenameFailedBody(
              _safeHermesUiError(error),
            ),
          ),
        ),
      );
    }
  });

  Future<void> _forkSession(
    BuildContext context,
    HermesChannel channel,
    HermesSession session,
  ) => _withSessionMutationIntent(channel, [session], _SessionMutation.fork, (
    isCurrent,
    submit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final strings = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(strings.chatSessionActionBranchTitle),
          content: Text(
            strings.chatSessionActionBranchBody(
              _safeHermesUiPreview(session.title ?? session.id, maxLength: 96),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.cancelAction),
            ),
            FilledButton(
              key: const ValueKey('hermes-session-branch-confirm'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.chatSessionActionBranchConfirmAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !submit(session.id)) return;
    try {
      await channel.forkSession(session.id);
      if (!isCurrent()) return;
      _refreshActiveGatewayContact();
      if (!context.mounted) return;
      final strings = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.chatSessionActionBranchCreatedBody)),
      );
    } catch (error) {
      if (!context.mounted || !isCurrent()) return;
      final strings = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.chatSessionActionBranchFailedBody(
              _safeHermesUiError(error),
            ),
          ),
        ),
      );
    }
  });

  Future<void> _deleteSessions(
    BuildContext context,
    HermesChannel channel,
    List<HermesSession> sessions,
  ) async {
    final selected = <HermesSession>[];
    final seen = <String>{};
    for (final session in sessions) {
      if (seen.add(session.id) &&
          channel.state.sessions.any((item) => item.id == session.id) &&
          !channel.state.isSessionStreaming(session.id)) {
        selected.add(session);
      }
    }
    if (selected.isEmpty) return;
    await _withSessionMutationIntent(
      channel,
      selected,
      _SessionMutation.delete,
      (isCurrent, submit) async {
        final count = selected.length;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            final strings = AppLocalizations.of(context);
            return AlertDialog(
              title: Text(strings.chatSessionActionDeleteManyTitle(count)),
              content: Text(strings.chatSessionActionDeleteManyBody),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(strings.cancelAction),
                ),
                FilledButton(
                  key: const ValueKey('hermes-sessions-delete-confirm'),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(strings.chatSessionActionDeleteAction),
                ),
              ],
            );
          },
        );
        if (confirmed != true) return;

        var deleted = 0;
        final draftOwner = _activeComposerDraftKey;
        for (final session in selected) {
          if (!isCurrent()) return;
          if (channel.state.isSessionStreaming(session.id) ||
              !channel.state.sessions.any((item) => item.id == session.id)) {
            continue;
          }
          if (!submit(session.id)) return;
          try {
            await channel.deleteSession(session.id);
            if (!isCurrent()) return;
            _forgetComposerSession(draftOwner, session.id);
            deleted += 1;
          } catch (_) {
            // Keep deleting the remaining selected sessions. The final bounded
            // summary reports partial failure without exposing server payloads.
          }
        }
        if (!isCurrent()) return;
        _refreshActiveGatewayContact();
        if (!context.mounted) return;
        final strings = AppLocalizations.of(context);
        final message = deleted == count
            ? strings.chatSessionActionDeletedCountBody(deleted)
            : strings.chatSessionActionDeletedPartialBody(
                deleted,
                count,
                count - deleted,
              );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  Future<void> _deleteSession(
    BuildContext context,
    HermesChannel channel,
    HermesSession session,
  ) => _withSessionMutationIntent(channel, [session], _SessionMutation.delete, (
    isCurrent,
    submit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final strings = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(strings.chatSessionActionDeleteTitle),
          content: Text(
            strings.chatSessionActionDeleteBody(
              _safeHermesUiPreview(session.title ?? session.id, maxLength: 96),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.cancelAction),
            ),
            FilledButton(
              key: const ValueKey('hermes-session-delete-confirm'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.chatSessionActionDeleteAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !submit(session.id)) return;
    try {
      final draftOwner = _activeComposerDraftKey;
      await channel.deleteSession(session.id);
      if (!isCurrent()) return;
      _forgetComposerSession(draftOwner, session.id);
      _refreshActiveGatewayContact();
    } catch (error) {
      if (!context.mounted || !isCurrent()) return;
      final strings = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.chatSessionActionDeleteFailedBody(
              _safeHermesUiError(error),
            ),
          ),
        ),
      );
    }
  });
}
