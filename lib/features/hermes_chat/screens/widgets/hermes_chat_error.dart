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
    final streamOrNetworkFailure =
        _isHermesNetworkError(lower) || lower.contains('stream');
    final runCancelled = lower.contains('hermes run was cancelled');
    final runFailed = lower.contains('hermes run failed');
    final (title, recovery) = authRejected
        ? (
            'Hermes API rejected the saved API key.',
            'Reconnect with a fresh Hermes API key, then retry this message.',
          )
        : approvalResponseFailed
        ? (
            'Hermes could not record the approval decision.',
            'Review the request, check that the run is still active, then try the decision again.',
          )
        : malformedApprovalRequest
        ? (
            'Hermes sent an incomplete approval request.',
            'Retry when Hermes can provide an approval id for this run.',
          )
        : unsupportedChatTransport
        ? (
            'Hermes endpoint does not support chat turns.',
            'Connect to a Hermes API server that advertises session chat streaming or run events.',
          )
        : runCancelled
        ? ('Hermes run was cancelled.', 'Start a new turn when you are ready.')
        : runFailed
        ? (
            'Hermes run failed.',
            'Check Hermes, then retry this message when the run is recoverable.',
          )
        : streamOrNetworkFailure
        ? (
            'Hermes stream dropped.',
            'Check the endpoint/network and send again when Hermes is reachable.',
          )
        : ('Hermes could not finish the turn.', 'Retry when Hermes is ready.');
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
                          label: const Text('Details'),
                        ),
                        if (authRejected && onReauthorize != null)
                          OutlinedButton.icon(
                            key: const ValueKey(
                              'hermes-chat-error-reauthorize',
                            ),
                            onPressed: onReauthorize,
                            icon: const Icon(Icons.key_outlined),
                            label: const Text('Update key'),
                          )
                        else if (streamOrNetworkFailure && onReconnect != null)
                          OutlinedButton.icon(
                            key: const ValueKey('hermes-chat-error-reconnect'),
                            onPressed: onReconnect,
                            icon: const Icon(Icons.cable_outlined),
                            label: const Text('Reconnect'),
                          ),
                        if (onRetry != null)
                          FilledButton.icon(
                            key: const ValueKey('hermes-chat-error-retry'),
                            onPressed: onRetry,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry last message'),
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
    builder: (sheetContext) => SafeArea(
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
              const Text('Redacted error details'),
              const SizedBox(height: 4),
              SelectableText(
                safeError,
                key: const ValueKey('hermes-error-details-text'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Secrets, bearer tokens, API keys, cookies, and copied endpoint credentials are redacted before display.',
                key: ValueKey('hermes-error-details-redaction-note'),
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
                          const SnackBar(
                            content: Text(
                              'Copied redacted Hermes error details.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('Copy redacted details'),
                    ),
                    TextButton(
                      key: const ValueKey('hermes-error-details-close'),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _safeHermesUiText(String text) {
  var safe = text;
  safe = safe.replaceAllMapped(
    RegExp(
      r'(Authorization\s*[:=]\s*(?:Bearer|Basic)\s+)[^\s,;]+',
      caseSensitive: false,
    ),
    (match) => '${match[1]}[redacted]',
  );
  safe = safe.replaceAllMapped(
    RegExp(r'Bearer\s+[^\s,;]+', caseSensitive: false),
    (_) => 'Bearer [redacted]',
  );
  safe = safe.replaceAllMapped(
    RegExp(r'Basic\s+[^\s,;]+', caseSensitive: false),
    (_) => 'Basic [redacted]',
  );
  safe = safe.replaceAllMapped(
    RegExp(
      r'((?:Cookie|Set-Cookie|X-API-Key|X-Auth-Token)\s*[:=]\s*)[^\n\r,;]+',
      caseSensitive: false,
    ),
    (match) => '${match[1]}[redacted]',
  );
  safe = safe.replaceAllMapped(
    RegExp(r'([a-z][a-z0-9+.-]*://)([^/\s@]+@)', caseSensitive: false),
    (match) => '${match[1]}[redacted]@',
  );
  safe = safe.replaceAll(
    RegExp(r'\b[A-Z]:\\[^\s,;]+', caseSensitive: false),
    '[redacted-path]',
  );
  safe = safe.replaceAll(RegExp(r'\\\\[^\s,;]+'), '[redacted-path]');
  safe = safe.replaceAll(
    RegExp(r'/(?:home|Users|var|private|mnt|Volumes)/[^\s,;]+'),
    '[redacted-path]',
  );
  safe = safe.replaceAllMapped(
    RegExp(
      r'(api[-_ ]?key|token|secret|password|passwd|pwd|credential|credentials|auth)(\s*(?:=|:)\s*)[^\s,;]+',
      caseSensitive: false,
    ),
    (match) => '${match[1]}${match[2]}[redacted]',
  );
  safe = safe
      .replaceAll(
        RegExp(r'sk-[a-z0-9_-]{12,}', caseSensitive: false),
        'sk-[redacted]',
      )
      .replaceAll(
        RegExp(r'gh[pousr]_[a-z0-9_]{20,}', caseSensitive: false),
        'ghp_[redacted]',
      )
      .replaceAll(
        RegExp(r'xox[abprs]-[a-z0-9-]{20,}', caseSensitive: false),
        'xox-[redacted]',
      )
      .replaceAll(
        RegExp(
          r'eyJ[a-z0-9_-]{8,}\.[a-z0-9_-]{8,}\.[a-z0-9_-]{8,}',
          caseSensitive: false,
        ),
        '[redacted-jwt]',
      );
  return safe.replaceAll(
    RegExp(r'secret[-_a-z0-9.]*', caseSensitive: false),
    '[redacted]',
  );
}

String _safeHermesUiPreview(String text, {int maxLength = 80}) {
  final safe = _safeHermesUiText(text);
  if (safe.length <= maxLength) return safe;
  return '${safe.substring(0, maxLength).trimRight()}…';
}

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
          'Saved Hermes profiles',
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
                      tooltip: 'Rename Hermes profile',
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
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('hermes-endpoint-profile-delete-dialog'),
        title: const Text('Remove saved Hermes profile?'),
        content: Text(
          'Remove ${_safeHermesUiPreview(profile.displayLabel, maxLength: 96)} '
          '(${_safeHermesUiPreview(profile.baseUrl, maxLength: 120)}) from this device. '
          'Any stored API key for this profile is removed from secure storage.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('hermes-endpoint-profile-delete-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('hermes-endpoint-profile-delete-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
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
    final (title, recovery) = _isHermesAuthError(lower)
        ? (
            'Hermes API rejected the API key.',
            'Check the endpoint API key in Hermes and try again.',
          )
        : _isHermesNetworkError(lower)
        ? (
            'Hermes endpoint is unreachable.',
            'Check the base URL, network, VPN, and that Hermes API server is running.',
          )
        : ('Could not connect to Hermes.', 'Check the endpoint and try again.');
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
            label: const Text('Details'),
          ),
        ),
      ],
    );
  }
}
