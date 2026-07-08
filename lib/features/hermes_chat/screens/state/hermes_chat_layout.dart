part of '../hermes_chat_screen.dart';

extension _HermesChatScreenLayout on _HermesChatScreenState {
  Widget _buildConnectForm(
    BuildContext context,
    HermesChannel channel,
    HermesChannelState state,
  ) {
    final connecting = state.status == HermesConnectionStatus.connecting;
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Connect to Hermes Agent',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<HermesEndpointConfig>>(
                  future: _endpointProfilesFuture,
                  builder: (context, snapshot) => _EndpointProfileChips(
                    profiles: snapshot.data ?? const [],
                    connecting: connecting,
                    onSelect: _selectEndpointProfile,
                    onDelete: (profile) =>
                        unawaited(_deleteEndpointProfile(profile)),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      key: const ValueKey('hermes-preset-local'),
                      label: const Text('Local Hermes'),
                      onPressed: connecting
                          ? null
                          : () => _baseUrlController.text =
                                'http://127.0.0.1:8642',
                    ),
                    ActionChip(
                      key: const ValueKey('hermes-preset-android'),
                      label: const Text('Android emulator'),
                      onPressed: connecting
                          ? null
                          : () => _baseUrlController.text =
                                'http://10.0.2.2:8642',
                    ),
                    ActionChip(
                      key: const ValueKey('hermes-preset-remote'),
                      label: const Text('Remote/LAN'),
                      onPressed: connecting
                          ? null
                          : () => _baseUrlController.clear(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('hermes-base-url-field'),
                  controller: _baseUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Hermes API base URL',
                    helperText: _hermesBaseUrlHint,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('hermes-api-key-field'),
                  controller: _apiKeyController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'API key (optional)',
                  ),
                ),
                const SizedBox(height: 16),
                if (state.status == HermesConnectionStatus.error &&
                    state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HermesConnectError(error: state.errorMessage!),
                  ),
                ElevatedButton(
                  key: const ValueKey('hermes-connect-button'),
                  onPressed: connecting
                      ? null
                      : () => unawaited(_connect(channel)),
                  child: connecting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Connect'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChat(
    BuildContext context,
    HermesChannel channel,
    HermesChannelState state,
  ) {
    final pendingApproval = _pendingApprovals.isEmpty
        ? null
        : _pendingApprovals.first;
    final pendingApprovalCount = _pendingApprovals.length;
    final hasActiveSession = state.activeSessionId != null;
    final canSendTurns = _canSendTurns(state);
    final canRespondToApprovals = _canRespondToApprovals(state);
    final isTurnActive = _isTurnActive(state);

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSessionRail = constraints.maxWidth >= 900;
        final chatPane = _buildChatPane(
          context: context,
          channel: channel,
          state: state,
          pendingApproval: pendingApproval,
          pendingApprovalCount: pendingApprovalCount,
          canRespondToApprovals: canRespondToApprovals,
          hasActiveSession: hasActiveSession,
          canSendTurns: canSendTurns,
          isTurnActive: isTurnActive,
        );

        if (!showSessionRail) return chatPane;

        return Row(
          children: [
            _HermesSessionRail(
              state: state,
              canCreate: _canCreateSession(state),
              onCreate: () => unawaited(_createSession(context, channel)),
              onSelect: (session) =>
                  unawaited(_selectSession(context, channel, session)),
              onRename: (session) =>
                  unawaited(_renameSession(context, channel, session)),
              onFork: (session) =>
                  unawaited(_forkSession(context, channel, session)),
              onDelete: (session) =>
                  unawaited(_deleteSession(context, channel, session)),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: chatPane),
          ],
        );
      },
    );
  }

  Widget _buildChatPane({
    required BuildContext context,
    required HermesChannel channel,
    required HermesChannelState state,
    required HermesApprovalRequest? pendingApproval,
    required int pendingApprovalCount,
    required bool canRespondToApprovals,
    required bool hasActiveSession,
    required bool canSendTurns,
    required bool isTurnActive,
  }) {
    final errorRetry =
        state.errorMessage != null &&
            canSendTurns &&
            !isTurnActive &&
            _retryableFailedUserText(state) != null
        ? () => _retryLastFailedTurn(channel)
        : null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final activeSession = state.activeSession;
        final showActiveSessionBar =
            constraints.maxWidth >= 600 && activeSession != null;
        final sessionModelLabel =
            activeSession?.model?.trim().isNotEmpty == true
            ? activeSession!.model!.trim()
            : state.models.isNotEmpty
            ? state.models.first
            : state.capabilities?.model.trim().isNotEmpty == true
            ? state.capabilities!.model.trim()
            : 'Hermes model';

        return Column(
          children: [
            if (showActiveSessionBar)
              _HermesActiveSessionBar(
                session: activeSession,
                messageCount: state.activeMessages.length,
                modelLabel: sessionModelLabel,
                isTurnActive: isTurnActive,
                canSendTurns: canSendTurns,
              ),
            if (hasActiveSession && !canSendTurns)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Card(
                  key: ValueKey('hermes-chat-transport-unavailable'),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Hermes did not advertise a supported chat transport for this endpoint.',
                    ),
                  ),
                ),
              ),
            Expanded(
              child: _buildTranscriptArea(
                context: context,
                channel: channel,
                state: state,
                canSendTurns: canSendTurns,
                pendingApproval: pendingApproval,
                pendingApprovalCount: pendingApprovalCount,
                canRespondToApprovals: canRespondToApprovals,
                chatError: state.errorMessage,
                onRetryError: errorRetry,
                onReconnectError: () => unawaited(_reconnect(channel)),
                onReauthorizeError: () => unawaited(_reauthorize(channel)),
              ),
            ),
            if (_voiceError != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  _voiceError!,
                  key: const ValueKey('hermes-voice-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_queuedFollowUps.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: MaterialBanner(
                  key: const ValueKey('hermes-queued-follow-up'),
                  content: Text(_queuedFollowUpSummary(state)),
                  actions: [
                    if (_canOpenQueuedFollowUpSession(state))
                      TextButton(
                        key: const ValueKey(
                          'hermes-queued-follow-up-open-session',
                        ),
                        onPressed: () => unawaited(
                          _openQueuedFollowUpSession(context, channel),
                        ),
                        child: const Text('Open session'),
                      ),
                    TextButton.icon(
                      key: const ValueKey('hermes-queued-follow-up-copy'),
                      onPressed: () {
                        unawaited(
                          Clipboard.setData(
                            ClipboardData(
                              text: _queuedFollowUpDetailsSummary(state),
                            ),
                          ),
                        );
                        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Copied redacted Hermes queued follow-ups.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('Copy'),
                    ),
                    TextButton(
                      key: const ValueKey('hermes-queued-follow-up-send-now'),
                      onPressed: _canSendQueuedFollowUp(state)
                          ? () => _sendQueuedFollowUpIfIdle(channel)
                          : null,
                      child: const Text('Send now'),
                    ),
                    TextButton(
                      key: const ValueKey('hermes-queued-follow-up-cancel'),
                      onPressed: () =>
                          unawaited(_confirmClearQueuedFollowUps(context)),
                      child: const Text('Cancel all'),
                    ),
                  ],
                ),
              ),
            if (_queuedFollowUpError != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  _queuedFollowUpError!,
                  key: const ValueKey('hermes-queued-follow-up-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            _buildComposer(context, channel, state, canSendTurns, isTurnActive),
          ],
        );
      },
    );
  }

  Widget _buildTranscriptArea({
    required BuildContext context,
    required HermesChannel channel,
    required HermesChannelState state,
    required bool canSendTurns,
    required HermesApprovalRequest? pendingApproval,
    required int pendingApprovalCount,
    required bool canRespondToApprovals,
    required String? chatError,
    required VoidCallback? onRetryError,
    required VoidCallback onReconnectError,
    required VoidCallback onReauthorizeError,
  }) {
    if (state.activeSessionId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _canCreateSession(state)
                ? 'No Hermes sessions. Create a new session to start chatting.'
                : 'No Hermes sessions are available, and this endpoint did not advertise session creation.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (state.activeMessages.isEmpty &&
        pendingApproval == null &&
        chatError == null) {
      return _HermesEmptyState(
        canSendTurns: canSendTurns,
        onPromptSelected: (prompt) {
          _composerController.text = prompt;
          _sendComposerText(channel);
        },
      );
    }

    return _HermesTranscriptList(
      controller: _transcriptScrollController,
      turns: state.activeMessages,
      pendingApproval: pendingApproval,
      pendingApprovalCount: pendingApprovalCount,
      canRespondToApprovals: canRespondToApprovals,
      respondingApprovalId: _answeringApprovalId,
      onResolveApproval: (decision) =>
          unawaited(_resolveApproval(channel, decision)),
      onDismissApproval: _dismissCurrentApproval,
      chatError: chatError,
      onRetryError: onRetryError,
      onReconnectError: onReconnectError,
      onReauthorizeError: onReauthorizeError,
    );
  }

  Widget _buildComposer(
    BuildContext context,
    HermesChannel channel,
    HermesChannelState state,
    bool canSendTurns,
    bool isTurnActive,
  ) {
    final modelLabel = state.models.isEmpty
        ? state.capabilities?.model ?? 'Hermes model'
        : state.models.first;
    final voiceLabel = _continuousVoiceEnabled
        ? 'Voice loop on'
        : 'Voice ready';
    final canRetry =
        canSendTurns &&
        !isTurnActive &&
        _retryableFailedUserText(state) != null;
    final strip = _HermesComposerStrip(
      modelLabel: modelLabel,
      voiceLabel: voiceLabel,
      isTurnActive: isTurnActive,
      canSendTurns: canSendTurns,
      canRetry: canRetry,
      onStop: () => _stopActiveTurn(channel),
      onRetry: () => _retryLastFailedTurn(channel),
      onDiagnostics: () => _showDiagnosticsDialog(context, state),
    );

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useDesktopCommandBar = constraints.maxWidth >= 720;
          return Padding(
            padding: EdgeInsets.fromLTRB(8, useDesktopCommandBar ? 6 : 8, 8, 8),
            child: useDesktopCommandBar
                ? _buildDesktopComposerCommandBar(
                    context,
                    channel,
                    state,
                    canSendTurns,
                    strip,
                  )
                : _buildMobileComposer(
                    context,
                    channel,
                    state,
                    canSendTurns,
                    strip,
                  ),
          );
        },
      ),
    );
  }

  Widget _buildMobileComposer(
    BuildContext context,
    HermesChannel channel,
    HermesChannelState state,
    bool canSendTurns,
    Widget strip,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        strip,
        const SizedBox(height: 6),
        Row(
          children: [
            _buildContinuousVoiceSwitch(channel, canSendTurns),
            Expanded(
              child: TextField(
                key: const ValueKey('hermes-composer-field'),
                controller: _composerController,
                enabled: canSendTurns,
                decoration: InputDecoration(
                  hintText: canSendTurns
                      ? 'Message Hermes…'
                      : 'Chat transport unavailable',
                ),
                onSubmitted: (_) => _sendComposerText(channel),
              ),
            ),
            ..._composerIconButtons(context, channel, state, canSendTurns),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopComposerCommandBar(
    BuildContext context,
    HermesChannel channel,
    HermesChannelState state,
    bool canSendTurns,
    Widget strip,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      key: const ValueKey('hermes-desktop-command-bar'),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('hermes-composer-field'),
            controller: _composerController,
            enabled: canSendTurns,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: canSendTurns
                  ? 'Message Hermes…'
                  : 'Chat transport unavailable',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(horizontal: 2),
            ),
            onSubmitted: (_) => _sendComposerText(channel),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildContinuousVoiceSwitch(channel, canSendTurns),
              const SizedBox(width: 4),
              Expanded(child: strip),
              const SizedBox(width: 8),
              ..._composerIconButtons(context, channel, state, canSendTurns),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContinuousVoiceSwitch(HermesChannel channel, bool canSendTurns) {
    return Semantics(
      label: 'Continuous voice — device STT to Hermes text',
      child: Switch(
        key: const ValueKey('hermes-continuous-voice-switch'),
        value: _continuousVoiceEnabled,
        onChanged: canSendTurns
            ? (value) {
                _setState(() => _continuousVoiceEnabled = value);
                if (value) {
                  unawaited(_captureOnce(channel));
                } else {
                  _stopSpeaking();
                }
              }
            : null,
      ),
    );
  }

  List<Widget> _composerIconButtons(
    BuildContext context,
    HermesChannel channel,
    HermesChannelState state,
    bool canSendTurns,
  ) {
    return [
      if (state.capabilities != null)
        IconButton(
          key: const ValueKey('hermes-attachments-button'),
          tooltip: 'Attachments/media status',
          icon: const Icon(Icons.attach_file_outlined),
          onPressed: () =>
              _showAttachmentsDeferred(context, state.capabilities!),
        ),
      IconButton(
        key: const ValueKey('hermes-mic-button'),
        tooltip: 'Speak — device STT to Hermes text',
        icon: _capturing
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.mic_none_outlined),
        onPressed: _capturing || !canSendTurns
            ? null
            : () => unawaited(_captureOnce(channel)),
      ),
      IconButton(
        key: const ValueKey('hermes-send-button'),
        tooltip: 'Send',
        icon: const Icon(Icons.send_outlined),
        onPressed: canSendTurns ? () => _sendComposerText(channel) : null,
      ),
    ];
  }
}
