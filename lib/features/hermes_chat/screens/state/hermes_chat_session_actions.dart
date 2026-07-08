part of '../hermes_chat_screen.dart';

extension _HermesChatScreenSessionActions on _HermesChatScreenState {
  Future<void> _createSession(
    BuildContext context,
    HermesChannel channel,
  ) async {
    try {
      await channel.createSession();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not create session: ${_safeHermesUiError(error)}',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open session: ${_safeHermesUiError(error)}'),
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
      builder: (context) => AlertDialog(
        title: const Text('Rename session'),
        content: TextFormField(
          key: const ValueKey('hermes-session-title-field'),
          initialValue: draftTitle,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Session title'),
          onChanged: (value) => draftTitle = value,
          onFieldSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('hermes-session-title-save'),
            onPressed: () => Navigator.of(context).pop(draftTitle.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final title = nextTitle?.trim();
    if (title == null || title.isEmpty || title == currentTitle) return;
    try {
      await channel.renameSession(sessionId: session.id, title: title);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not rename session: ${_safeHermesUiError(error)}',
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
    try {
      await channel.forkSession(session.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not fork session: ${_safeHermesUiError(error)}'),
        ),
      );
    }
  }

  Future<void> _deleteSession(
    BuildContext context,
    HermesChannel channel,
    HermesSession session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete session?'),
        content: Text(
          'Delete "${_safeHermesUiPreview(session.title ?? session.id, maxLength: 96)}" from Hermes?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('hermes-session-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await channel.deleteSession(session.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete session: ${_safeHermesUiError(error)}',
          ),
        ),
      );
    }
  }
}
