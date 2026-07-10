part of '../hermes_chat_screen.dart';

extension _HermesChatScreenConnection on _HermesChatScreenState {
  void _stopActiveTurn(HermesChannel channel) {
    channel.stopActiveTurn();
    _voiceInputController.pause();
  }

  void _showAttachmentsDeferred(
    BuildContext context,
    HermesCapabilityDocument capabilities,
  ) {
    final advertised =
        capabilities.supportsFeature('attachments_api') ||
        capabilities.supportsFeature('multimodal_chat');
    final detail = advertised
        ? 'Hermes advertises attachments or multimodal chat, but Navivox has not wired mobile-safe upload controls yet.'
        : 'Hermes did not advertise a mobile-safe attachments API. Navivox keeps this chat text-only plus device STT transcripts.';
    const exclusion =
        'No files, photos, transcripts, or local paths are uploaded from this control.';
    final summary = _deferredSurfaceSummary(
      title: 'Hermes attachments/media',
      detail: detail,
      exclusion: exclusion,
    );
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hermes attachments/media',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(detail, key: const ValueKey('hermes-attachments-detail')),
              const SizedBox(height: 8),
              const Text(exclusion),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      key: const ValueKey('hermes-attachments-copy'),
                      onPressed: () {
                        unawaited(
                          Clipboard.setData(ClipboardData(text: summary)),
                        );
                        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Copied Hermes attachments/media status.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('Copy status'),
                    ),
                    TextButton(
                      key: const ValueKey('hermes-attachments-close'),
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
    );
  }

  void _showFilesContextDeferred(
    BuildContext context,
    HermesCapabilityDocument capabilities,
  ) {
    final advertised =
        capabilities.supportsFeature('files_api') ||
        capabilities.supportsFeature('context_folders_api') ||
        capabilities.supportsFeature('workspace_files');
    final detail = advertised
        ? 'Hermes advertises file or context-folder capabilities, but Navivox has not wired mobile-safe file/context controls yet.'
        : 'Hermes did not advertise a mobile-safe files/context folders API. Navivox keeps workspace paths hidden.';
    const exclusion =
        'No local file paths, folder names, transcripts, or workspace contents are uploaded from this control.';
    final summary = _deferredSurfaceSummary(
      title: 'Hermes files/context folders',
      detail: detail,
      exclusion: exclusion,
    );
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hermes files/context folders',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  detail,
                  key: const ValueKey('hermes-files-context-detail'),
                ),
                const SizedBox(height: 8),
                const Text(exclusion),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        key: const ValueKey('hermes-files-context-copy'),
                        onPressed: () {
                          unawaited(
                            Clipboard.setData(ClipboardData(text: summary)),
                          );
                          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Copied Hermes files/context status.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_outlined),
                        label: const Text('Copy status'),
                      ),
                      TextButton(
                        key: const ValueKey('hermes-files-context-close'),
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

  String _deferredSurfaceSummary({
    required String title,
    required String detail,
    required String exclusion,
  }) => '$title\nStatus: Deferred\n$detail\n$exclusion';

  Future<void> _resolveApproval(
    HermesChannel channel,
    HermesApprovalDecision decision,
  ) async {
    if (_pendingApprovals.isEmpty || _answeringApprovalId != null) return;
    final request = _pendingApprovals.first;
    final approvalId = request.id.trim();
    if (approvalId.isEmpty) return;
    final approvalSessionId = _approvalSessionId;
    _setState(() => _answeringApprovalId = approvalId);
    try {
      await channel.respondToApproval(
        approvalId: approvalId,
        decision: decision,
      );
      if (!mounted) return;
      _setState(() {
        final stillSameSession = _approvalSessionId == approvalSessionId;
        if (stillSameSession &&
            _pendingApprovals.isNotEmpty &&
            _approvalRequestKey(_pendingApprovals.first) ==
                _approvalRequestKey(request)) {
          _pendingApprovals.removeFirst();
        }
        if (_answeringApprovalId == approvalId) {
          _answeringApprovalId = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      _setState(() {
        if (_answeringApprovalId == approvalId) {
          _answeringApprovalId = null;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not answer Hermes approval: ${_safeHermesUiError(error)}',
          ),
        ),
      );
    }
  }

  void _dismissCurrentApproval() {
    if (_pendingApprovals.isEmpty) return;
    _setState(() {
      _pendingApprovals.removeFirst();
      _answeringApprovalId = null;
    });
  }

  void _selectEndpointProfile(HermesEndpointConfig profile) {
    _baseUrlController.text = profile.baseUrl;
    _apiKeyController.text = profile.apiKey ?? '';
    _profileLabelController.text = profile.label ?? '';
  }

  void _applyEndpointPreset(String baseUrl) {
    _baseUrlController.text = baseUrl;
    _apiKeyController.clear();
    _profileLabelController.clear();
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
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('hermes-endpoint-profile-rename-dialog'),
        title: const Text('Rename Hermes profile'),
        content: TextFormField(
          key: const ValueKey('hermes-endpoint-profile-rename-field'),
          initialValue: draftLabel,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Profile label',
            helperText: 'Leave blank to show the endpoint URL.',
          ),
          onChanged: (value) => draftLabel = value,
          onFieldSubmitted: (value) =>
              Navigator.of(dialogContext).pop(value.trim()),
        ),
        actions: [
          TextButton(
            key: const ValueKey('hermes-endpoint-profile-rename-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('hermes-endpoint-profile-rename-save'),
            onPressed: () => Navigator.of(dialogContext).pop(draftLabel.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
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
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not rename Hermes profile: ${_safeHermesUiError(error)}',
          ),
        ),
      );
    }
  }

  Future<void> _deleteEndpointProfile(HermesEndpointConfig profile) async {
    final id = profile.id;
    if (id == null || id.trim().isEmpty) return;
    await ref.read(hermesEndpointStoreProvider).deleteProfile(id);
    if (_baseUrlController.text.trim() == profile.baseUrl) {
      _baseUrlController.clear();
      _apiKeyController.clear();
      _profileLabelController.clear();
    }
    _refreshEndpointProfiles();
  }

  Future<void> _connect(HermesChannel channel) async {
    final baseUrl = hermesPublicEndpointBaseUrl(_baseUrlController.text);
    final apiKey = _apiKeyController.text.trim();
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
          builder: (dialogContext) => AlertDialog(
            key: const ValueKey('hermes-cleartext-credential-warning'),
            title: const Text('Send API key without TLS?'),
            content: Text(
              'The endpoint ${_safeHermesUiPreview(baseUrl, maxLength: 120)} uses plain HTTP. '
              'Continue only on a trusted VPN, Tailscale network, or isolated LAN. Prefer HTTPS for remote Hermes endpoints.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                key: const ValueKey('hermes-cleartext-credential-confirm'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _reconnect(HermesChannel channel) async {
    final saved = await ref.read(hermesEndpointStoreProvider).load();
    final stateBaseUrl = channel.state.connectedBaseUrl;
    final controllerBaseUrl = hermesPublicEndpointBaseUrl(
      _baseUrlController.text,
    );
    final baseUrl = stateBaseUrl?.trim().isNotEmpty == true
        ? stateBaseUrl!.trim()
        : saved?.baseUrl.trim().isNotEmpty == true
        ? saved!.baseUrl
        : controllerBaseUrl;
    final apiKey = saved?.baseUrl == baseUrl
        ? saved?.apiKey
        : _apiKeyController.text.trim().isEmpty
        ? null
        : _apiKeyController.text.trim();
    _baseUrlController.text = baseUrl;
    _apiKeyController.text = apiKey ?? '';
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
        hermesPublicEndpointBaseUrl(_baseUrlController.text);
    _connectAttemptId += 1;
    await channel.disconnect();
    _baseUrlController.text = baseUrl;
    _apiKeyController.clear();
    _refreshEndpointProfiles();
  }

  Future<void> _connectToEndpoint(
    HermesChannel channel, {
    required String baseUrl,
    String? apiKey,
    required bool persistOnSuccess,
  }) async {
    final attemptId = ++_connectAttemptId;
    final normalizedBaseUrl = hermesPublicEndpointBaseUrl(baseUrl);
    final normalizedApiKey = apiKey?.trim();
    final profileLabel = _safeHermesUiText(_profileLabelController.text).trim();
    await channel.connect(
      baseUrl: normalizedBaseUrl,
      apiKey: normalizedApiKey?.isEmpty == true ? null : normalizedApiKey,
    );
    if (attemptId != _connectAttemptId ||
        hermesPublicEndpointBaseUrl(_baseUrlController.text) !=
            normalizedBaseUrl ||
        _apiKeyController.text.trim() != (normalizedApiKey ?? '') ||
        _safeHermesUiText(_profileLabelController.text).trim() !=
            profileLabel ||
        channel.state.status != HermesConnectionStatus.connected) {
      return;
    }
    if (persistOnSuccess) {
      await ref
          .read(hermesEndpointStoreProvider)
          .save(
            baseUrl: normalizedBaseUrl,
            apiKey: normalizedApiKey?.isEmpty == true ? null : normalizedApiKey,
            label: profileLabel.isEmpty ? null : profileLabel,
          );
      _refreshEndpointProfiles();
    }
  }

  Future<void> _confirmDisconnect(
    BuildContext context,
    HermesChannel channel,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('hermes-disconnect-confirm-dialog'),
        title: const Text('Disconnect from Hermes?'),
        content: Text(
          'Disconnect from ${_safeHermesUiPreview(_baseUrlController.text, maxLength: 120)} '
          'and remove this saved endpoint/API key from this device. Other saved '
          'Hermes profiles remain available.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('hermes-disconnect-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('hermes-disconnect-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _disconnect(channel);
  }

  Future<void> _disconnect(HermesChannel channel) async {
    await channel.disconnect();
    await ref.read(hermesEndpointStoreProvider).clear();
    _refreshEndpointProfiles();
  }

  void _showDiagnosticsDialog(BuildContext context, HermesChannelState state) {
    final diagnostics = hermesDiagnosticsExport(state);
    final rawLogsSummary = _rawLogsDeferredSummary();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.all(16),
        contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
        title: const Text('Hermes diagnostics'),
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
              unawaited(Clipboard.setData(ClipboardData(text: rawLogsSummary)));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Raw-log status copied')),
              );
            },
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Copy raw-log status'),
          ),
          TextButton(
            key: const ValueKey('hermes-diagnostics-copy'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: diagnostics));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Hermes diagnostics copied')),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _rawLogsDeferredSummary() {
    return _deferredSurfaceSummary(
      title: 'Raw diagnostics/log export',
      detail:
          'Raw logs, transcripts, credentials, tool payloads, and local paths remain excluded from Navivox mobile diagnostics.',
      exclusion:
          'No raw log export control is enabled until a safe Hermes redaction contract exists.',
    );
  }

  void _showSessionsPanel(BuildContext context, HermesChannel channel) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => _HermesSessionsPanel(
        state: channel.state,
        canCreate: _canCreateSession(channel.state),
        onCreate: () {
          Navigator.of(sheetContext).pop();
          unawaited(_createSession(context, channel));
        },
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
      ),
    );
  }
}
