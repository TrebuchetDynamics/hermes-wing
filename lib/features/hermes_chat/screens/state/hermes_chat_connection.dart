part of '../hermes_chat_screen.dart';

extension _HermesChatScreenConnection on _HermesChatScreenState {
  void _stopActiveTurn(HermesChannel channel) {
    channel.stopActiveTurn();
    _setState(() => _continuousVoiceEnabled = false);
    _stopSpeaking();
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
              const Text(
                'No files, photos, transcripts, or local paths are uploaded from this control.',
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const ValueKey('hermes-attachments-close'),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
    } catch (_) {
      if (!mounted) return;
      _setState(() {
        if (_answeringApprovalId == approvalId) {
          _answeringApprovalId = null;
        }
      });
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
  }

  Future<void> _deleteEndpointProfile(HermesEndpointConfig profile) async {
    final id = profile.id;
    if (id == null || id.trim().isEmpty) return;
    await ref.read(hermesEndpointStoreProvider).deleteProfile(id);
    if (_baseUrlController.text.trim() == profile.baseUrl) {
      _baseUrlController.clear();
      _apiKeyController.clear();
    }
    _refreshEndpointProfiles();
  }

  Future<void> _connect(HermesChannel channel) async {
    final baseUrl = hermesPublicEndpointBaseUrl(_baseUrlController.text);
    final apiKey = _apiKeyController.text.trim();
    await _connectToEndpoint(
      channel,
      baseUrl: baseUrl,
      apiKey: apiKey.isEmpty ? null : apiKey,
      persistOnSuccess: true,
    );
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
    await channel.connect(
      baseUrl: normalizedBaseUrl,
      apiKey: normalizedApiKey?.isEmpty == true ? null : normalizedApiKey,
    );
    if (attemptId != _connectAttemptId ||
        hermesPublicEndpointBaseUrl(_baseUrlController.text) !=
            normalizedBaseUrl ||
        _apiKeyController.text.trim() != (normalizedApiKey ?? '') ||
        channel.state.status != HermesConnectionStatus.connected) {
      return;
    }
    if (persistOnSuccess) {
      await ref
          .read(hermesEndpointStoreProvider)
          .save(
            baseUrl: normalizedBaseUrl,
            apiKey: normalizedApiKey?.isEmpty == true ? null : normalizedApiKey,
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
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
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
