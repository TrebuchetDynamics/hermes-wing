part of '../hermes_chat_screen.dart';

class _HermesChatError extends StatelessWidget {
  const _HermesChatError({
    required this.error,
    this.onRetry,
    this.onReconnect,
    this.onReauthorize,
  });

  final String error;
  final VoidCallback? onRetry;
  final VoidCallback? onReconnect;
  final VoidCallback? onReauthorize;

  @override
  Widget build(BuildContext context) {
    final lower = error.toLowerCase();
    final authRejected = _isHermesAuthError(lower);
    final approvalResponseFailed = lower.contains('could not answer approval');
    final malformedApprovalRequest = lower.contains(
      'approval request was missing an approval id',
    );
    final unsupportedChatTransport = lower.contains(
      'did not advertise a supported chat transport',
    );
    final runStillActive = _isHermesRunStillActiveError(lower);
    final streamOrNetworkFailure =
        _isHermesNetworkError(lower) || lower.contains('stream');
    final runCancelled = lower.contains('hermes run was cancelled');
    final runFailed = lower.contains('hermes run failed');
    final strings = AppLocalizations.of(context);
    final (title, recovery) = authRejected
        ? (
            strings.chatErrorAuthRejectedTitle,
            strings.chatErrorAuthRejectedBody,
          )
        : approvalResponseFailed
        ? (
            strings.chatErrorApprovalResponseFailedTitle,
            strings.chatErrorApprovalResponseFailedBody,
          )
        : malformedApprovalRequest
        ? (
            strings.chatErrorMalformedApprovalTitle,
            strings.chatErrorMalformedApprovalBody,
          )
        : unsupportedChatTransport
        ? (
            strings.chatErrorUnsupportedTransportTitle,
            strings.chatErrorUnsupportedTransportBody,
          )
        : runStillActive
        ? (
            strings.chatErrorRunStillActiveTitle,
            strings.chatErrorRunStillActiveBody,
          )
        : runCancelled
        ? (
            strings.chatErrorRunCancelledTitle,
            strings.chatErrorRunCancelledBody,
          )
        : runFailed
        ? (strings.chatErrorRunFailedTitle, strings.chatErrorRunFailedBody)
        : streamOrNetworkFailure
        ? (
            strings.chatErrorStreamDroppedTitle,
            strings.chatErrorStreamDroppedBody,
          )
        : (strings.chatErrorGenericTitle, strings.chatErrorGenericBody);
    final colorScheme = Theme.of(context).colorScheme;
    return _AssistantTimelineItem(
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            key: const ValueKey('hermes-chat-error'),
            color: colorScheme.errorContainer,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error_outline, color: colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(recovery),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton.icon(
                          key: const ValueKey('hermes-chat-error-details'),
                          onPressed: () => _showHermesErrorDetailsSheet(
                            context,
                            title: title,
                            recovery: recovery,
                            error: error,
                          ),
                          icon: const Icon(Icons.article_outlined),
                          label: Text(strings.chatErrorDetailsAction),
                        ),
                        if (authRejected && onReauthorize != null)
                          OutlinedButton.icon(
                            key: const ValueKey(
                              'hermes-chat-error-reauthorize',
                            ),
                            onPressed: onReauthorize,
                            icon: const Icon(Icons.key_outlined),
                            label: Text(strings.chatErrorUpdateKeyAction),
                          )
                        else if ((runStillActive || streamOrNetworkFailure) &&
                            onReconnect != null)
                          OutlinedButton.icon(
                            key: const ValueKey('hermes-chat-error-reconnect'),
                            onPressed: onReconnect,
                            icon: const Icon(Icons.cable_outlined),
                            label: Text(strings.chatErrorReconnectAction),
                          ),
                        if (onRetry != null)
                          FilledButton.icon(
                            key: const ValueKey('hermes-chat-error-retry'),
                            onPressed: onRetry,
                            icon: const Icon(Icons.refresh),
                            label: Text(
                              strings.chatErrorRetryLastMessageAction,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _showHermesErrorDetailsSheet(
  BuildContext context, {
  required String title,
  required String recovery,
  required String error,
}) {
  final safeError = _safeHermesUiPreview(
    _safeHermesUiText(error),
    maxLength: 1200,
  );
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final strings = AppLocalizations.of(sheetContext);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            key: const ValueKey('hermes-error-details-sheet'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(sheetContext).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(recovery),
                const SizedBox(height: 12),
                Text(strings.chatErrorRedactedDetailsLabel),
                const SizedBox(height: 4),
                SelectableText(
                  safeError,
                  key: const ValueKey('hermes-error-details-text'),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.chatErrorRedactionNoteBody,
                  key: const ValueKey('hermes-error-details-redaction-note'),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        key: const ValueKey('hermes-error-details-copy'),
                        onPressed: () {
                          unawaited(
                            Clipboard.setData(ClipboardData(text: safeError)),
                          );
                          ScaffoldMessenger.maybeOf(sheetContext)?.showSnackBar(
                            SnackBar(
                              content: Text(
                                strings.chatErrorCopiedRedactedDetailsBody,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_outlined),
                        label: Text(strings.chatErrorCopyRedactedDetailsAction),
                      ),
                      TextButton(
                        key: const ValueKey('hermes-error-details-close'),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(strings.closeAction),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

bool _isHermesRunStillActiveError(String error) {
  final normalized = error.toLowerCase();
  return normalized.contains(
        'run is still active after its event stream closed',
      ) ||
      normalized.contains('hermes run is still active.');
}

String _safeHermesUiText(String text) => wingRedactSensitiveText(text);

String _safeHermesUiPreview(String text, {int maxLength = 80}) =>
    wingRedactedPreview(text, maxLength: maxLength);

class _EndpointProfileChips extends StatelessWidget {
  const _EndpointProfileChips({
    required this.profiles,
    required this.connecting,
    required this.onSelect,
    required this.onRename,
    required this.onDelete,
  });

  final List<HermesEndpointConfig> profiles;
  final bool connecting;
  final ValueChanged<HermesEndpointConfig> onSelect;
  final ValueChanged<HermesEndpointConfig> onRename;
  final ValueChanged<HermesEndpointConfig> onDelete;

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).chatErrorSavedProfilesLabel,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final profile in profiles)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: InputChip(
                        key: ValueKey(
                          'hermes-endpoint-profile-${profile.id ?? profile.baseUrl}',
                        ),
                        label: Text(
                          _safeHermesUiPreview(
                            profile.displayLabel,
                            maxLength: 48,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: connecting ? null : () => onSelect(profile),
                        onDeleted: connecting || profile.id == null
                            ? null
                            : () => unawaited(
                                _confirmDeleteProfile(context, profile),
                              ),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        tooltip: _safeHermesUiPreview(
                          profile.baseUrl,
                          maxLength: 96,
                        ),
                      ),
                    ),
                    IconButton(
                      key: ValueKey(
                        'hermes-endpoint-profile-rename-${profile.id ?? profile.baseUrl}',
                      ),
                      tooltip: AppLocalizations.of(
                        context,
                      ).chatErrorRenameProfileTooltip,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: connecting || profile.id == null
                          ? null
                          : () => onRename(profile),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmDeleteProfile(
    BuildContext context,
    HermesEndpointConfig profile,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final strings = AppLocalizations.of(dialogContext);
        return AlertDialog(
          key: const ValueKey('hermes-endpoint-profile-delete-dialog'),
          title: Text(strings.chatErrorRemoveProfileTitle),
          content: Text(
            strings.chatErrorRemoveProfileBody(
              _safeHermesUiPreview(profile.displayLabel, maxLength: 96),
              _safeHermesUiPreview(profile.baseUrl, maxLength: 120),
            ),
          ),
          actions: [
            TextButton(
              key: const ValueKey('hermes-endpoint-profile-delete-cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(strings.cancelAction),
            ),
            FilledButton(
              key: const ValueKey('hermes-endpoint-profile-delete-confirm'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(strings.chatErrorRemoveProfileAction),
            ),
          ],
        );
      },
    );
    if (confirmed == true) onDelete(profile);
  }
}

String _safeHermesRenameDefault(String text) {
  final safe = _safeHermesUiText(text);
  if (safe != text || safe.length > 96) return '';
  return safe;
}

String _safeHermesSessionSearchText(String text) {
  final safe = _safeHermesUiText(text);
  if (safe == text) return safe;
  return safe.replaceAll('[redacted]', '').trim();
}

String _safeHermesUiError(Object error) =>
    _safeHermesUiPreview(error.toString(), maxLength: 160);

bool _isHermesAuthError(String lowerCaseError) {
  return lowerCaseError.contains('401') ||
      lowerCaseError.contains('403') ||
      lowerCaseError.contains('419') ||
      lowerCaseError.contains('unauthorized') ||
      lowerCaseError.contains('forbidden') ||
      lowerCaseError.contains('expired') ||
      lowerCaseError.contains('invalid api key') ||
      lowerCaseError.contains('invalid token');
}

bool _isHermesNetworkError(String lowerCaseError) {
  return lowerCaseError.contains('socketexception') ||
      lowerCaseError.contains('clientexception') ||
      lowerCaseError.contains('handshakeexception') ||
      lowerCaseError.contains('connection refused') ||
      lowerCaseError.contains('connection reset') ||
      lowerCaseError.contains('connection aborted') ||
      lowerCaseError.contains('connection closed') ||
      lowerCaseError.contains('software caused connection abort') ||
      lowerCaseError.contains('econnrefused') ||
      lowerCaseError.contains('econnreset') ||
      lowerCaseError.contains('broken pipe') ||
      lowerCaseError.contains('failed host lookup') ||
      lowerCaseError.contains('host lookup failed') ||
      lowerCaseError.contains('temporary failure in name resolution') ||
      lowerCaseError.contains('name or service not known') ||
      lowerCaseError.contains('no route to host') ||
      lowerCaseError.contains('network is unreachable') ||
      lowerCaseError.contains('network unreachable') ||
      lowerCaseError.contains('timed out') ||
      lowerCaseError.contains('timeout');
}

class _HermesConnectError extends StatelessWidget {
  const _HermesConnectError({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final lower = error.toLowerCase();
    final strings = AppLocalizations.of(context);
    final (title, recovery) = _isHermesAuthError(lower)
        ? (strings.chatErrorConnectAuthTitle, strings.chatErrorConnectAuthBody)
        : _isHermesNetworkError(lower)
        ? (
            strings.chatErrorConnectUnreachableTitle,
            strings.chatErrorConnectUnreachableBody,
          )
        : (
            strings.chatErrorConnectGenericTitle,
            strings.chatErrorConnectGenericBody,
          );
    return Column(
      key: const ValueKey('hermes-connect-error'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        const SizedBox(height: 4),
        Text(recovery),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            key: const ValueKey('hermes-connect-error-details'),
            onPressed: () => _showHermesErrorDetailsSheet(
              context,
              title: title,
              recovery: recovery,
              error: error,
            ),
            icon: const Icon(Icons.article_outlined),
            label: Text(strings.chatErrorDetailsAction),
          ),
        ),
      ],
    );
  }
}
