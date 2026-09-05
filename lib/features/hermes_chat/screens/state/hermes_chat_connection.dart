part of '../hermes_chat_screen.dart';

extension _HermesChatScreenConnection on _HermesChatScreenState {
  void _stopActiveTurn(HermesChannel channel) {
    final target = channel.activeTurnInterruptionTarget;
    channel.stopActiveTurn();
    if (target != null) _approvals.dismissStoppedTurn(target);
    _voiceInputController.pause();
  }

  String _deferredSurfaceSummary({
    required String title,
    required String detail,
    required String exclusion,
  }) => '$title\nStatus: Deferred\n$detail\n$exclusion';

  Future<void> _resolveApproval(
    HermesChannel channel,
    HermesApprovalDecision decision,
    HermesApprovalRequest request,
  ) => _approvals.resolve(decision, request);

  void _dismissApproval(HermesApprovalRequest request) =>
      _approvals.dismiss(request);

  void _selectEndpointProfile(HermesEndpointConfig profile) {
    _connectionForm.applyProfile(
      baseUrl: profile.baseUrl,
      apiKey: profile.apiKey,
      label: profile.label,
    );
  }

  void _applyEndpointPreset(String baseUrl) {
    _connectionForm.clear(keepBaseUrl: baseUrl);
  }

  Future<void> _renameEndpointProfile(
    BuildContext context,
    HermesEndpointConfig profile,
  ) async {
    final id = profile.id;
    if (id == null || id.trim().isEmpty) return;
    var draftLabel = _safeHermesRenameDefault(profile.label ?? '');
    final nextLabel = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final strings = AppLocalizations.of(dialogContext);
        return AlertDialog(
          key: const ValueKey('hermes-endpoint-profile-rename-dialog'),
          title: Text(strings.chatConnectionRenameProfileTitle),
          content: TextFormField(
            key: const ValueKey('hermes-endpoint-profile-rename-field'),
            initialValue: draftLabel,
            autofocus: true,
            decoration: InputDecoration(
              labelText: strings.chatConnectionProfileLabelLabel,
              helperText: strings.chatConnectionProfileLabelHelper,
            ),
            onChanged: (value) => draftLabel = value,
            onFieldSubmitted: (value) =>
                Navigator.of(dialogContext).pop(value.trim()),
          ),
          actions: [
            TextButton(
              key: const ValueKey('hermes-endpoint-profile-rename-cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(strings.cancelAction),
            ),
            FilledButton(
              key: const ValueKey('hermes-endpoint-profile-rename-save'),
              onPressed: () =>
                  Navigator.of(dialogContext).pop(draftLabel.trim()),
              child: Text(strings.saveAction),
            ),
          ],
        );
      },
    );
    if (nextLabel == null || nextLabel.trim() == (profile.label ?? '').trim()) {
      return;
    }
    try {
      await ref
          .read(hermesEndpointStoreProvider)
          .save(
            baseUrl: profile.baseUrl,
            apiKey: profile.apiKey,
            label: nextLabel.trim().isEmpty ? null : nextLabel.trim(),
            profileId: id,
          );
      _refreshEndpointProfiles();
      unawaited(ref.read(hermesGatewayDirectoryProvider).reload());
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            ).chatConnectionRenameProfileErrorBody(_safeHermesUiError(error)),
          ),
        ),
      );
    }
  }

  Future<void> _deleteEndpointProfile(HermesEndpointConfig profile) async {
    final id = profile.id;
    if (id == null || id.trim().isEmpty) return;
    await ref.read(hermesEndpointStoreProvider).deleteProfile(id);
    if (hermesPublicEndpointBaseUrl(_connectionForm.baseUrl.text) ==
        hermesPublicEndpointBaseUrl(profile.baseUrl)) {
      _connectionForm.clear();
    }
    _refreshEndpointProfiles();
    unawaited(ref.read(hermesGatewayDirectoryProvider).reload());
  }

  Future<void> _connect(HermesChannel channel) async {
    final baseUrl = hermesPublicEndpointBaseUrl(_connectionForm.baseUrl.text);
    final apiKey = _connectionForm.apiKey.text.trim();
    if (hermesEndpointRequiresCleartextCredentialWarning(
      baseUrl,
      apiKey: apiKey,
    )) {
      final confirmed = await _confirmCleartextCredentialUse(baseUrl);
      if (!confirmed || !mounted) return;
    }
    await _connectToEndpoint(
      channel,
      baseUrl: baseUrl,
      apiKey: apiKey.isEmpty ? null : apiKey,
      persistOnSuccess: true,
    );
  }

  Future<bool> _confirmCleartextCredentialUse(String baseUrl) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            final strings = AppLocalizations.of(dialogContext);
            return AlertDialog(
              key: const ValueKey('hermes-cleartext-credential-warning'),
              title: Text(strings.chatConnectionCleartextWarningTitle),
              content: Text(
                strings.chatConnectionCleartextWarningBody(
                  _safeHermesUiPreview(baseUrl, maxLength: 120),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(strings.cancelAction),
                ),
                FilledButton(
                  key: const ValueKey('hermes-cleartext-credential-confirm'),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(strings.chatConnectionContinueAction),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _reconnect(HermesChannel channel) async {
    if (_reconnectInFlight) return;
    _reconnectInFlight = true;
    try {
      await _reconnectOnce(channel);
    } finally {
      _reconnectInFlight = false;
    }
  }

  Future<void> _reconnectOnce(HermesChannel channel) async {
    final saved = await ref.read(hermesEndpointStoreProvider).load();
    final stateBaseUrl = channel.state.connectedBaseUrl;
    final controllerBaseUrl = hermesPublicEndpointBaseUrl(
      _connectionForm.baseUrl.text,
    );
    final baseUrl = stateBaseUrl?.trim().isNotEmpty == true
        ? stateBaseUrl!.trim()
        : saved?.baseUrl.trim().isNotEmpty == true
        ? saved!.baseUrl
        : controllerBaseUrl;
    final savedBaseUrl = saved?.baseUrl;
    final savedMatchesTarget =
        savedBaseUrl != null &&
        hermesPublicEndpointBaseUrl(savedBaseUrl) ==
            hermesPublicEndpointBaseUrl(baseUrl);
    final apiKey = savedMatchesTarget
        ? saved?.apiKey
        : _connectionForm.apiKey.text.trim().isEmpty
        ? null
        : _connectionForm.apiKey.text.trim();
    _connectionForm.baseUrl.text = baseUrl;
    _connectionForm.apiKey.text = apiKey ?? '';
    await _connectToEndpoint(
      channel,
      baseUrl: baseUrl,
      apiKey: apiKey,
      persistOnSuccess: false,
    );
  }

  Future<void> _reauthorize(HermesChannel channel) async {
    final baseUrl =
        channel.state.connectedBaseUrl ??
        hermesPublicEndpointBaseUrl(_connectionForm.baseUrl.text);
    _connectionForm.abandonAttempt();
    await channel.disconnect();
    _connectionForm.baseUrl.text = baseUrl;
    _connectionForm.apiKey.clear();
    _setState(() => _editingConnection = true);
    _refreshEndpointProfiles();
  }

  Future<void> _connectToEndpoint(
    HermesChannel channel, {
    required String baseUrl,
    String? apiKey,
    required bool persistOnSuccess,
  }) async {
    final attempt = _connectionForm.beginAttempt(
      baseUrl: baseUrl,
      apiKey: apiKey,
    );
    bool ownsAttempt() =>
        mounted &&
        !_connectionForm.isStale(attempt) &&
        identical(ref.read(hermesChannelProvider), channel);
    await channel.connect(
      baseUrl: attempt.baseUrl,
      apiKey: attempt.storedApiKey,
    );
    if (!ownsAttempt() ||
        channel.state.status != HermesConnectionStatus.connected) {
      return;
    }
    if (persistOnSuccess) {
      _setState(() => _editingConnection = false);
      await ref
          .read(hermesEndpointStoreProvider)
          .save(
            baseUrl: attempt.baseUrl,
            apiKey: attempt.storedApiKey,
            label: attempt.storedLabel,
          );
      // Secure storage can finish after a newer connection has taken ownership.
      if (!ownsAttempt()) return;
      _refreshEndpointProfiles();
      await channel.disconnect();
      if (!ownsAttempt()) return;
      unawaited(ref.read(hermesGatewayDirectoryProvider).reload());
    }
  }

  Future<void> _confirmDisconnect(
    BuildContext context,
    HermesChannel channel,
  ) async {
    final activeContact = ref
        .read(hermesGatewayDirectoryProvider)
        .activeContact;
    final target = activeContact?.gatewayLabel ?? _connectionForm.baseUrl.text;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final strings = AppLocalizations.of(dialogContext);
        return AlertDialog(
          key: const ValueKey('hermes-disconnect-confirm-dialog'),
          title: Text(strings.chatConnectionDisconnectTitle),
          content: Text(
            strings.chatConnectionDisconnectBody(
              _safeHermesUiPreview(target, maxLength: 120),
            ),
          ),
          actions: [
            TextButton(
              key: const ValueKey('hermes-disconnect-cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(strings.cancelAction),
            ),
            FilledButton(
              key: const ValueKey('hermes-disconnect-confirm'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(strings.chatConnectionDisconnectAction),
            ),
          ],
        );
      },
    );
    if (confirmed == true) await _disconnect(channel);
  }

  Future<void> _disconnect(HermesChannel channel) async {
    final directory = ref.read(hermesGatewayDirectoryProvider);
    final activeContact = directory.activeContact;
    if (activeContact != null) {
      await directory.removeGateway(activeContact.id.gatewayId);
    } else {
      await channel.disconnect();
      await ref.read(hermesEndpointStoreProvider).clear();
    }
    _refreshEndpointProfiles();
  }

  void _showDiagnosticsDialog(BuildContext context, HermesChannelState state) {
    final diagnostics = hermesDiagnosticsExport(state);
    final rawLogsSummary = _rawLogsDeferredSummary();
    showDialog<void>(
      context: context,
      builder: (context) {
        final strings = AppLocalizations.of(context);
        return AlertDialog(
          insetPadding: const EdgeInsets.all(16),
          contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
          title: Text(strings.chatConnectionDiagnosticsTitle),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.capabilities != null) ...[
                    _HermesCapabilityStrip(
                      capabilities: state.capabilities!,
                      detailedHealth: state.detailedHealth,
                      models: state.models,
                      skills: state.skills,
                      enabledToolsets: state.enabledToolsets,
                      jobs: state.jobs,
                      optionalResourceErrors: state.optionalResourceErrors,
                    ),
                    const SizedBox(height: 12),
                  ],
                  SelectableText(
                    diagnostics,
                    key: const ValueKey('hermes-diagnostics-text'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              key: const ValueKey('hermes-raw-logs-status-copy'),
              onPressed: () {
                unawaited(
                  Clipboard.setData(ClipboardData(text: rawLogsSummary)),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(strings.chatConnectionRawLogStatusCopiedBody),
                  ),
                );
              },
              icon: const Icon(Icons.copy_outlined),
              label: Text(strings.chatConnectionCopyRawLogStatusAction),
            ),
            TextButton(
              key: const ValueKey('hermes-diagnostics-copy'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: diagnostics));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(strings.chatConnectionDiagnosticsCopiedBody),
                  ),
                );
              },
              child: Text(strings.chatConnectionCopyAction),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.closeAction),
            ),
          ],
        );
      },
    );
  }

  String _rawLogsDeferredSummary() {
    return _deferredSurfaceSummary(
      title: 'Raw diagnostics/log export',
      detail:
          'Raw logs, transcripts, credentials, tool payloads, and local paths remain excluded from Hermes Wing mobile diagnostics.',
      exclusion:
          'No raw log export control is enabled until a safe Hermes redaction contract exists.',
    );
  }

  void _showSessionsPanel(BuildContext context, HermesChannel channel) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final pinContact = _sessionPinContact(channel.state);
        return ListenableBuilder(
          listenable: Listenable.merge([channel, _sessionPins]),
          builder: (_, _) => _HermesSessionsPanel(
            state: channel.state,
            canCreate: _canCreateSession(channel.state),
            pinnedSessionIds: {
              for (final session in channel.state.sessions)
                if (_sessionPins.isPinned(pinContact, session.id)) session.id,
            },
            unreadCompletedSessionIds: _unreadCompletedSessionIds,
            onTogglePinned: (session) =>
                unawaited(_sessionPins.toggle(pinContact, session.id)),
            onCreate: () {
              Navigator.of(sheetContext).pop();
              unawaited(_createSession(context, channel));
            },
            onLoadMore: () => unawaited(channel.loadMoreSessions()),
            onSelect: (session) {
              Navigator.of(sheetContext).pop();
              unawaited(_selectSession(context, channel, session));
            },
            onRename: (session) {
              Navigator.of(sheetContext).pop();
              unawaited(_renameSession(context, channel, session));
            },
            onFork: (session) {
              Navigator.of(sheetContext).pop();
              unawaited(_forkSession(context, channel, session));
            },
            onDelete: (session) {
              Navigator.of(sheetContext).pop();
              unawaited(_deleteSession(context, channel, session));
            },
            onDeleteSelected: (sessions) {
              Navigator.of(sheetContext).pop();
              unawaited(_deleteSessions(context, channel, sessions));
            },
          ),
        );
      },
    );
  }
}
