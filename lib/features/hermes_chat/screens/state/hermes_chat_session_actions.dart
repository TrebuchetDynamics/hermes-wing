part of '../hermes_chat_screen.dart';

extension _HermesChatScreenSessionActions on _HermesChatScreenState {
  Future<void> _createSession(
    BuildContext context,
    HermesChannel channel,
  ) async {
    try {
      await channel.createSession();
      _refreshActiveGatewayContact();
    } catch (error) {
      if (!context.mounted) return;
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
  }

  Future<void> _selectSession(
    BuildContext context,
    HermesChannel channel,
    HermesSession session,
  ) async {
    try {
      await channel.selectSession(session.id);
    } catch (error) {
      if (!context.mounted) return;
      final strings = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.chatSessionActionOpenFailedBody(_safeHermesUiError(error)),
          ),
        ),
      );
    }
  }

  Future<void> _renameSession(
    BuildContext context,
    HermesChannel channel,
    HermesSession session,
  ) async {
    final currentTitle = session.title ?? '';
    var draftTitle = _safeHermesRenameDefault(currentTitle);
    final nextTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        final strings = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(strings.chatSessionActionRenameTitle),
          content: TextFormField(
            key: const ValueKey('hermes-session-title-field'),
            initialValue: draftTitle,
            autofocus: true,
            decoration: InputDecoration(
              labelText: strings.chatSessionActionTitleFieldLabel,
            ),
            onChanged: (value) => draftTitle = value,
            onFieldSubmitted: (value) =>
                Navigator.of(context).pop(value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.cancelAction),
            ),
            FilledButton(
              key: const ValueKey('hermes-session-title-save'),
              onPressed: () => Navigator.of(context).pop(draftTitle.trim()),
              child: Text(strings.saveAction),
            ),
          ],
        );
      },
    );
    final title = nextTitle?.trim();
    if (title == null || title.isEmpty || title == currentTitle) return;
    try {
      await channel.renameSession(sessionId: session.id, title: title);
      _refreshActiveGatewayContact();
    } catch (error) {
      if (!context.mounted) return;
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
  }

  Future<void> _forkSession(
    BuildContext context,
    HermesChannel channel,
    HermesSession session,
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
    if (confirmed != true) return;
    try {
      await channel.forkSession(session.id);
      _refreshActiveGatewayContact();
      if (!context.mounted) return;
      final strings = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.chatSessionActionBranchCreatedBody)),
      );
    } catch (error) {
      if (!context.mounted) return;
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
  }

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
    for (final session in selected) {
      if (channel.state.isSessionStreaming(session.id) ||
          !channel.state.sessions.any((item) => item.id == session.id)) {
        continue;
      }
      try {
        await channel.deleteSession(session.id);
        deleted += 1;
      } catch (_) {
        // Keep deleting the remaining selected sessions. The final bounded
        // summary reports partial failure without exposing server payloads.
      }
    }
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
  }

  Future<void> _deleteSession(
    BuildContext context,
    HermesChannel channel,
    HermesSession session,
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
    if (confirmed != true) return;
    try {
      await channel.deleteSession(session.id);
      _refreshActiveGatewayContact();
    } catch (error) {
      if (!context.mounted) return;
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
  }
}
