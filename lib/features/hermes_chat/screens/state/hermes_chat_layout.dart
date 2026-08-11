part of '../hermes_chat_screen.dart';

extension _HermesChatScreenLayout on _HermesChatScreenState {
  Widget _buildConnectForm(
    BuildContext context,
    HermesChannel channel,
    HermesChannelState state,
  ) {
    final connecting = state.status == HermesConnectionStatus.connecting;
    final canConnect =
        !connecting && _isValidHermesBaseUrl(_connectionForm.baseUrl.text);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final strings = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: AutofillGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Icon(
                          Icons.cloud_outlined,
                          size: 28,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.chatLayoutConnectTitle,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            strings.chatLayoutConnectBody,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                FutureBuilder<List<HermesEndpointConfig>>(
                  future: _endpointProfilesFuture,
                  builder: (context, snapshot) {
                    final profiles = snapshot.data ?? const [];
                    if (profiles.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _EndpointProfileChips(
                        profiles: profiles,
                        connecting: connecting,
                        onSelect: _selectEndpointProfile,
                        onRename: (profile) =>
                            unawaited(_renameEndpointProfile(context, profile)),
                        onDelete: (profile) =>
                            unawaited(_deleteEndpointProfile(profile)),
                      ),
                    );
                  },
                ),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          strings.chatLayoutVpsConnectionTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          strings.chatLayoutVpsConnectionBody,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        if (!kIsWeb &&
                            defaultTargetPlatform ==
                                TargetPlatform.android) ...[
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            key: const ValueKey('hermes-open-qr-scanner'),
                            onPressed: () => context.push(AppRoutes.enroll),
                            icon: const Icon(Icons.qr_code_scanner),
                            label: Text(strings.chatLayoutScanQrAction),
                          ),
                        ],
                        if (!kIsWeb &&
                            defaultTargetPlatform == TargetPlatform.linux) ...[
                          const SizedBox(height: 16),
                          FilledButton.tonalIcon(
                            key: const ValueKey('hermes-open-local-setup'),
                            onPressed: () => context.push(AppRoutes.localSetup),
                            icon: const Icon(Icons.computer_outlined),
                            label: Text(strings.localSetupAction),
                          ),
                        ],
                        const SizedBox(height: 20),
                        TextField(
                          key: const ValueKey('hermes-base-url-field'),
                          controller: _connectionForm.baseUrl,
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.url],
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            labelText: strings.chatLayoutServerUrlLabel,
                            hintText: strings.chatLayoutServerUrlHint,
                            helperText: strings.chatLayoutServerUrlHelper,
                            helperMaxLines: 2,
                            prefixIcon: const Icon(Icons.language_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          key: const ValueKey('hermes-api-key-field'),
                          controller: _connectionForm.apiKey,
                          obscureText: _connectionForm.obscureApiKey,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            labelText: strings.chatLayoutAccessTokenLabel,
                            helperText: strings.chatLayoutAccessTokenHelper,
                            helperMaxLines: 2,
                            prefixIcon: const Icon(Icons.key_outlined),
                            suffixIcon: IconButton(
                              key: const ValueKey('hermes-api-key-visibility'),
                              tooltip: _connectionForm.obscureApiKey
                                  ? strings.chatLayoutShowAccessTokenTooltip
                                  : strings.chatLayoutHideAccessTokenTooltip,
                              onPressed: _connectionForm.toggleApiKeyVisibility,
                              icon: Icon(
                                _connectionForm.obscureApiKey
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          key: const ValueKey('hermes-profile-label-field'),
                          controller: _connectionForm.label,
                          textInputAction: TextInputAction.done,
                          onSubmitted: canConnect
                              ? (_) => unawaited(_connect(channel))
                              : null,
                          decoration: InputDecoration(
                            labelText: strings.chatLayoutVpsNameLabel,
                            hintText: strings.chatLayoutVpsNameHint,
                            helperText: strings.chatLayoutVpsNameHelper,
                            prefixIcon: const Icon(Icons.label_outline),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.lock_outline,
                                size: 20,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  strings.chatLayoutTokenStorageBody,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (state.status == HermesConnectionStatus.error &&
                            state.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          _HermesConnectError(error: state.errorMessage!),
                        ],
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          key: const ValueKey('hermes-connect-button'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                          onPressed: canConnect
                              ? () => unawaited(_connect(channel))
                              : null,
                          icon: connecting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.arrow_forward),
                          label: Text(
                            connecting
                                ? strings.chatLayoutConnectingAction
                                : strings.chatLayoutConnectAction,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  margin: EdgeInsets.zero,
                  child: ExpansionTile(
                    key: const ValueKey('hermes-developer-shortcuts'),
                    leading: const Icon(Icons.developer_mode_outlined),
                    title: Text(strings.chatLayoutDevShortcutsTitle),
                    subtitle: Text(strings.chatLayoutDevShortcutsBody),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (!_isAndroid)
                              ActionChip(
                                key: const ValueKey('hermes-preset-local'),
                                avatar: const Icon(
                                  Icons.computer_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  strings.chatLayoutPresetThisDeviceLabel,
                                ),
                                onPressed: connecting
                                    ? null
                                    : () => _applyEndpointPreset(
                                        'http://127.0.0.1:8642',
                                      ),
                              ),
                            ActionChip(
                              key: const ValueKey('hermes-preset-android'),
                              avatar: const Icon(
                                Icons.android_outlined,
                                size: 18,
                              ),
                              label: Text(
                                strings.chatLayoutPresetAndroidEmulatorLabel,
                              ),
                              onPressed: connecting
                                  ? null
                                  : () => _applyEndpointPreset(
                                      'http://10.0.2.2:8642',
                                    ),
                            ),
                            ActionChip(
                              key: const ValueKey('hermes-preset-remote'),
                              avatar: const Icon(Icons.refresh, size: 18),
                              label: Text(strings.chatLayoutPresetClearAction),
                              onPressed: connecting
                                  ? null
                                  : () => _applyEndpointPreset(''),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _hermesBaseUrlHint,
                          style: TextStyle(fontSize: 12),
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
    );
  }

  Widget _buildChat(
    BuildContext context,
    HermesChannel channel,
    HermesChannelState state,
  ) {
    final activeApprovals = _approvals.activeFor(state.activeSessionId);
    final pendingApproval = activeApprovals.firstOrNull;
    final pendingApprovalCount = activeApprovals.length;
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
              onDeleteSelected: (sessions) =>
                  unawaited(_deleteSessions(context, channel, sessions)),
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
            !_isHermesRunStillActiveError(state.errorMessage!) &&
            canSendTurns &&
            !isTurnActive &&
            _retryableFailedUserText(state) != null
        ? () => _retryLastFailedTurn(channel)
        : null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final strings = AppLocalizations.of(context);
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
            : strings.chatLayoutModelFallbackLabel;

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
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Card(
                  key: const ValueKey('hermes-chat-transport-unavailable'),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(strings.chatLayoutTransportUnavailableBody),
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
                onManageProvidersError: () => context.go(AppRoutes.providers),
              ),
            ),
            if (_voiceInputController.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Semantics(
                  key: const ValueKey('hermes-voice-error'),
                  container: true,
                  liveRegion: true,
                  label: _voiceInputController.error!,
                  child: ExcludeSemantics(
                    child: Text(
                      _voiceInputController.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ),
            if (_followUps.isNotEmpty)
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
                        child: Text(strings.chatLayoutOpenSessionAction),
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
                          SnackBar(
                            content: Text(
                              strings.chatLayoutFollowUpsCopiedBody,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_outlined),
                      label: Text(strings.chatLayoutCopyAction),
                    ),
                    TextButton(
                      key: const ValueKey('hermes-queued-follow-up-send-now'),
                      onPressed: _canSendQueuedFollowUp(state)
                          ? () => _sendQueuedFollowUpIfIdle(channel)
                          : null,
                      child: Text(strings.chatLayoutSendNowAction),
                    ),
                    TextButton(
                      key: const ValueKey('hermes-queued-follow-up-cancel'),
                      onPressed: () =>
                          unawaited(_confirmClearQueuedFollowUps(context)),
                      child: Text(strings.chatLayoutCancelAllAction),
                    ),
                  ],
                ),
              ),
            if (_followUps.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  _followUps.error!,
                  key: const ValueKey('hermes-queued-follow-up-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (canSendTurns)
              WingTipCard(
                tip: WingTip.voice,
                text: AppLocalizations.of(context).tipVoice,
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
    required VoidCallback onManageProvidersError,
  }) {
    if (state.activeSessionId == null) {
      final strings = AppLocalizations.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _canCreateSession(state)
                ? strings.chatLayoutNoSessionsBody
                : strings.chatLayoutNoSessionsNoCreateBody,
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
      respondingApprovalId: _approvals.answeringId,
      onResolveApproval: (decision) =>
          unawaited(_resolveApproval(channel, decision, pendingApproval!)),
      onDismissApproval: () => _dismissApproval(pendingApproval!),
      onReplyTurn: _replyToTurn,
      onCopyTranscriptText: () => unawaited(
        _copyTranscript(context, channel.state, _TranscriptCopyFormat.text),
      ),
      onCopyTranscriptMarkdown: () => unawaited(
        _copyTranscript(context, channel.state, _TranscriptCopyFormat.markdown),
      ),
      enableDesktopContextMenu: _usesDesktopKeyboardShortcuts,
      chatError: chatError,
      onRetryError: onRetryError,
      onReconnectError: onReconnectError,
      onReauthorizeError: onReauthorizeError,
      onManageProvidersError: onManageProvidersError,
    );
  }

  void _replyToTurn(HermesChatTurn turn) {
    // ponytail: plain Markdown quote until Hermes exposes reply metadata.
    final quote = _safeHermesUiPreview(
      turn.text.trim(),
      maxLength: 320,
    ).replaceAll('\n', '\n> ');
    final draft = _composerController.text.trim();
    final text = '> $quote\n\n${draft.isEmpty ? '' : draft}';
    _composerController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Widget _buildComposer(
    BuildContext context,
    HermesChannel channel,
    HermesChannelState state,
    bool canSendTurns,
    bool isTurnActive,
  ) {
    final strings = AppLocalizations.of(context);
    final modelLabel = state.models.isEmpty
        ? state.capabilities?.model ?? strings.chatLayoutModelFallbackLabel
        : state.models.first;
    final voiceLabel = _voiceInputController.continuousEnabled
        ? strings.chatLayoutVoiceLoopOnLabel
        : strings.chatLayoutVoiceReadyLabel;
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
                    isTurnActive || canRetry || !canSendTurns ? strip : null,
                  ),
          );
        },
      ),
    );
  }

  List<_LocalSlashCommand> _matchingLocalSlashCommands(
    AppLocalizations strings,
    HermesChannelState state,
  ) {
    final draft = _composerController.text.trimLeft();
    if (!draft.startsWith('/') || draft.substring(1).contains(RegExp(r'\s'))) {
      return const [];
    }
    final query = draft.substring(1).toLowerCase();
    return _localSlashCommands(
      strings,
      state,
    ).where((item) => item.command.substring(1).startsWith(query)).toList();
  }

  Widget? _buildLocalSlashCommandSuggestions(
    BuildContext context,
    HermesChannel channel,
  ) {
    if (_stagedAttachment != null || _isTurnActive(channel.state)) {
      return null;
    }
    final strings = _hermesStrings(context);
    final commands = _matchingLocalSlashCommands(strings, channel.state);
    if (commands.isEmpty) return null;
    return Card(
      key: const ValueKey('hermes-local-command-suggestions'),
      margin: const EdgeInsets.only(bottom: 6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 232),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text(
                strings.localCommandsTitle,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 6),
                children: [
                  for (final command in commands)
                    ListTile(
                      key: ValueKey('hermes-local-command-${command.id}'),
                      dense: true,
                      leading: Icon(command.icon),
                      title: Text(command.command),
                      subtitle: Text(command.description),
                      onTap: () => _runLocalSlashCommand(command, channel),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _runLocalSlashCommand(
    _LocalSlashCommand command,
    HermesChannel channel,
  ) {
    if (_isTurnActive(channel.state)) return false;
    _composerController.clear();
    switch (command.id) {
      case 'new':
        unawaited(_createSession(context, channel));
      case 'sessions':
        _showSessionsPanel(context, channel);
      case 'clear':
        break;
      case 'settings':
        context.go(AppRoutes.settings);
      case 'tools' || 'skills':
        context.go(AppRoutes.tools);
      case 'gateway':
        context.go(AppRoutes.gateway);
      case 'office':
        context.go(AppRoutes.office);
      case 'profiles':
        context.go(AppRoutes.profiles);
      case 'providers' || 'model':
        context.go(AppRoutes.providers);
      case 'schedules':
        context.go(AppRoutes.schedules);
      case 'help':
        unawaited(_showLocalSlashCommandHelp(context, channel));
      case 'persona':
        unawaited(_showCurrentPersona(context, channel));
      case 'version':
        final strings = AppLocalizations.of(context);
        final health = channel.state.detailedHealth;
        final platform = health?.platform.trim() ?? '';
        final version = health?.version?.trim() ?? '';
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(
              platform.isEmpty
                  ? strings.gatewayVersionUnavailable
                  : strings.gatewayVersionSummary(
                      _safeHermesUiPreview(platform, maxLength: 64),
                      version.isEmpty
                          ? strings.gatewayVersionUnknown
                          : _safeHermesUiPreview(version, maxLength: 64),
                    ),
            ),
          ),
        );
      case 'usage':
        final turns = channel.state.activeMessages;
        final usageIndex = turns.lastIndexWhere((turn) => turn.usage != null);
        final usage = usageIndex < 0 ? null : turns[usageIndex].usage;
        final strings = AppLocalizations.of(context);
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(
              usage == null
                  ? strings.noRunTokenUsageMessage
                  : strings.runTokenUsageSemantics(
                      usage.inputTokens,
                      usage.outputTokens,
                      usage.totalTokens,
                    ),
            ),
          ),
        );
      default:
        return false;
    }
    return true;
  }

  Future<void> _showLocalSlashCommandHelp(
    BuildContext context,
    HermesChannel channel,
  ) async {
    final strings = AppLocalizations.of(context);
    final commands = _localSlashCommands(strings, channel.state);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          key: const ValueKey('hermes-local-command-help'),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  strings.localCommandsHelpTitle,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 4),
              Text(strings.localCommandsHelpBody),
              const SizedBox(height: 12),
              for (final command in commands)
                ListTile(
                  leading: Icon(command.icon),
                  title: Text(command.command),
                  subtitle: Text(command.description),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCurrentPersona(
    BuildContext context,
    HermesChannel channel,
  ) async {
    final profileId = channel.state.selectedProfileId;
    if (profileId == null || !channel.state.canReadProfileSoul) return;
    final strings = AppLocalizations.of(context);
    try {
      final soul = await channel.readProfileSoul(profileId);
      if (!context.mounted || channel.state.selectedProfileId != profileId) {
        return;
      }
      final selected = channel.state.selectedProfile;
      final profileLabel = selected == null || selected.displayName.isEmpty
          ? profileId
          : selected.displayName;
      final content = soul.soul.trim();
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
            ),
            child: SingleChildScrollView(
              key: const ValueKey('hermes-profile-persona'),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      strings.profilePersonaTitle(
                        _safeHermesUiPreview(profileLabel, maxLength: 64),
                      ),
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    content.isEmpty
                        ? strings.profilePersonaEmptyBody
                        : _safeHermesUiPreview(content, maxLength: 16384),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            strings.profilePersonaLoadFailed(_safeHermesUiError(error)),
          ),
        ),
      );
    }
  }

  bool _runExactLocalSlashCommand(String text, HermesChannel channel) {
    if (_isTurnActive(channel.state)) return false;
    final commandText = text.trim().toLowerCase();
    final strings = AppLocalizations.of(context);
    for (final command in _localSlashCommands(strings, channel.state)) {
      if (command.command == commandText) {
        return _runLocalSlashCommand(command, channel);
      }
    }
    return false;
  }

  List<_LocalSlashCommand> _localSlashCommands(
    AppLocalizations strings,
    HermesChannelState state,
  ) => [
    if (state.canCreateSessions)
      _LocalSlashCommand(
        id: 'new',
        command: '/new',
        description: strings.localCommandNewDescription,
        icon: Icons.add_comment_outlined,
      ),
    _LocalSlashCommand(
      id: 'sessions',
      command: '/sessions',
      description: strings.localCommandSessionsDescription,
      icon: Icons.forum_outlined,
    ),
    _LocalSlashCommand(
      id: 'clear',
      command: '/clear',
      description: strings.localCommandClearDescription,
      icon: Icons.backspace_outlined,
    ),
    _LocalSlashCommand(
      id: 'settings',
      command: '/settings',
      description: strings.localCommandSettingsDescription,
      icon: Icons.settings_outlined,
    ),
    _LocalSlashCommand(
      id: 'usage',
      command: '/usage',
      description: strings.localCommandUsageDescription,
      icon: Icons.data_usage_outlined,
    ),
    _LocalSlashCommand(
      id: 'help',
      command: '/help',
      description: strings.localCommandHelpDescription,
      icon: Icons.help_outline,
    ),
    _LocalSlashCommand(
      id: 'tools',
      command: '/tools',
      description: strings.localCommandToolsDescription,
      icon: Icons.build_outlined,
    ),
    _LocalSlashCommand(
      id: 'skills',
      command: '/skills',
      description: strings.localCommandSkillsDescription,
      icon: Icons.extension_outlined,
    ),
    _LocalSlashCommand(
      id: 'gateway',
      command: '/gateway',
      description: strings.localCommandGatewayDescription,
      icon: Icons.dns_outlined,
    ),
    _LocalSlashCommand(
      id: 'office',
      command: '/office',
      description: strings.localCommandOfficeDescription,
      icon: Icons.apartment_outlined,
    ),
    _LocalSlashCommand(
      id: 'profiles',
      command: '/profiles',
      description: strings.localCommandAgentsDescription,
      icon: Icons.support_agent_outlined,
    ),
    _LocalSlashCommand(
      id: 'providers',
      command: '/providers',
      description: strings.localCommandProvidersDescription,
      icon: Icons.hub_outlined,
    ),
    _LocalSlashCommand(
      id: 'model',
      command: '/model',
      description: strings.localCommandModelDescription,
      icon: Icons.memory_outlined,
    ),
    _LocalSlashCommand(
      id: 'schedules',
      command: '/schedules',
      description: strings.localCommandSchedulesDescription,
      icon: Icons.schedule_outlined,
    ),
    if (state.canReadProfileSoul && state.selectedProfileId != null)
      _LocalSlashCommand(
        id: 'persona',
        command: '/persona',
        description: strings.localCommandPersonaDescription,
        icon: Icons.psychology_outlined,
      ),
    if (state.canReadDetailedHealth)
      _LocalSlashCommand(
        id: 'version',
        command: '/version',
        description: strings.localCommandVersionDescription,
        icon: Icons.info_outline,
      ),
  ];

  Widget _buildMobileComposer(
    BuildContext context,
    HermesChannel channel,
    HermesChannelState state,
    bool canSendTurns,
    Widget? strip,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = AppLocalizations.of(context);
    if (_voiceInputController.continuousEnabled) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (strip != null) ...[strip, const SizedBox(height: 6)],
          _buildVoiceModeSurface(context),
        ],
      );
    }
    final hasPayload =
        _composerController.text.trim().isNotEmpty || _stagedAttachment != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (strip != null) ...[strip, const SizedBox(height: 6)],
        ?_buildLocalSlashCommandSuggestions(context, channel),
        if (_stagedAttachment != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: _buildPendingAttachment(),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          key: const ValueKey('hermes-composer-surface'),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildComposerMenuButton(context, channel, canSendTurns),
              _buildEmojiButton(canSendTurns),
              Expanded(
                child: TextField(
                  key: const ValueKey('hermes-composer-field'),
                  controller: _composerController,
                  enabled: canSendTurns,
                  minLines: 1,
                  maxLines: 4,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    labelText: _voiceInputController.speaking
                        ? strings.chatLayoutComposerSpeakingHint
                        : canSendTurns
                        ? strings.chatLayoutComposerHint
                        : strings.chatLayoutComposerUnavailableHint,
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onSubmitted: (_) => _sendComposerText(channel),
                ),
              ),
              _buildAttachmentButton(channel, canSendTurns),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: hasPayload
                    ? _buildSendButton(channel, canSendTurns)
                    : _buildMicButton(canSendTurns),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceModeSurface(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strings = AppLocalizations.of(context);
    final phase = _voiceInputController.capturing
        ? strings.chatLayoutListeningLabel
        : _voiceInputController.speaking
        ? strings.chatLayoutSpeakingLabel
        : strings.chatLayoutHandsFreeLabel;
    final icon = _voiceInputController.capturing
        ? Icons.mic_rounded
        : _voiceInputController.speaking
        ? Icons.volume_up_rounded
        : Icons.record_voice_over_rounded;
    final liveTranscript = _voiceInputController.liveTranscript;
    return Semantics(
      container: true,
      liveRegion: true,
      label: '${strings.chatLayoutHandsFreeVoiceLabel}: $phase',
      child: Container(
        key: const ValueKey('hermes-voice-mode-surface'),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.primary.withValues(alpha: 0.38)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: [
            if (_voiceInputController.capturing &&
                _voiceInputController.soundLevel?.isNaN == false)
              _VoiceWaveform(level: _voiceInputController.soundLevel)
            else
              Icon(icon, color: colors.onPrimaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.chatLayoutHandsFreeVoiceLabel,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    liveTranscript ?? phase,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filled(
              key: const ValueKey('hermes-voice-mode-end-button'),
              tooltip: strings.closeAction,
              icon: const Icon(Icons.close_rounded),
              onPressed: _voiceInputController.pause,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopComposerCommandBar(
    BuildContext context,
    HermesChannel channel,
    HermesChannelState state,
    bool canSendTurns,
    Widget strip,
  ) {
    if (_voiceInputController.continuousEnabled) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          strip,
          const SizedBox(height: 6),
          _buildVoiceModeSurface(context),
        ],
      );
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strings = AppLocalizations.of(context);
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
          ?_buildLocalSlashCommandSuggestions(context, channel),
          if (_stagedAttachment != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: _buildPendingAttachment(),
            ),
            const SizedBox(height: 6),
          ],
          TextField(
            key: const ValueKey('hermes-composer-field'),
            controller: _composerController,
            enabled: canSendTurns,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: _voiceInputController.speaking
                  ? strings.chatLayoutComposerSpeakingHint
                  : canSendTurns
                  ? strings.chatLayoutComposerHint
                  : strings.chatLayoutComposerTransportUnavailableHint,
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
              _buildContinuousVoiceSwitch(canSendTurns),
              const SizedBox(width: 4),
              Expanded(child: strip),
              const SizedBox(width: 8),
              ..._composerIconButtons(channel, canSendTurns),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComposerMenuButton(
    BuildContext context,
    HermesChannel channel,
    bool canSendTurns,
  ) {
    final settings = ref.watch(wingVoiceSettingsProvider);
    final handsFreeAvailable = canSendTurns && settings.continuousVoiceEnabled;
    final handsFreeActive = _voiceInputController.continuousEnabled;
    final strings = AppLocalizations.of(context);
    return PopupMenuButton<_ComposerMenuAction>(
      key: const ValueKey('hermes-composer-menu-button'),
      tooltip: strings.chatLayoutChatMenuTooltip,
      icon: const Icon(Icons.menu_rounded),
      onSelected: (action) {
        switch (action) {
          case _ComposerMenuAction.sessions:
            _showSessionsPanel(context, channel);
          case _ComposerMenuAction.handsFree:
            _setContinuousVoice(!handsFreeActive);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _ComposerMenuAction.sessions,
          child: ListTile(
            leading: const Icon(Icons.forum_outlined),
            title: Text(strings.chatLayoutSessionsLabel),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        CheckedPopupMenuItem(
          value: _ComposerMenuAction.handsFree,
          enabled: handsFreeAvailable,
          checked: handsFreeActive,
          child: Text(strings.chatLayoutHandsFreeVoiceLabel),
        ),
      ],
    );
  }

  Widget _buildEmojiButton(bool canSendTurns) {
    return IconButton(
      key: const ValueKey('hermes-emoji-button'),
      tooltip: AppLocalizations.of(context).chatLayoutEmojiTitle,
      icon: const Icon(Icons.sentiment_satisfied_alt_outlined),
      onPressed: canSendTurns ? () => unawaited(_showEmojiPicker()) : null,
    );
  }

  Future<void> _showEmojiPicker() async {
    final emoji = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: 260,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  AppLocalizations.of(sheetContext).chatLayoutEmojiTitle,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 52,
                  ),
                  itemCount: _composerEmojis.length,
                  itemBuilder: (_, index) {
                    final value = _composerEmojis[index];
                    return Semantics(
                      label: AppLocalizations.of(
                        sheetContext,
                      ).chatLayoutInsertEmojiLabel(value),
                      button: true,
                      child: InkResponse(
                        key: ValueKey('hermes-emoji-$index'),
                        radius: 24,
                        onTap: () => Navigator.of(sheetContext).pop(value),
                        child: Center(
                          child: Text(
                            value,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (emoji == null || !mounted) return;
    final value = _composerController.value;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;
    _composerController.value = TextEditingValue(
      text: value.text.replaceRange(start, end, emoji),
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
  }

  void _setContinuousVoice(bool value) {
    ref.read(wingVoiceSettingsProvider.notifier).setSpeakRepliesEnabled(value);
    if (value) {
      unawaited(_voiceInputController.enableContinuous());
    } else {
      _voiceInputController.pause();
    }
  }

  Widget _buildContinuousVoiceSwitch(bool canSendTurns) {
    final settings = ref.watch(wingVoiceSettingsProvider);
    final voiceEnabled = settings.continuousVoiceEnabled;
    final active = _voiceInputController.continuousEnabled;
    final strings = AppLocalizations.of(context);
    final label = _voiceInputController.capturing
        ? strings.chatLayoutListeningLabel
        : _voiceInputController.speaking
        ? strings.chatLayoutSpeakingLabel
        : strings.chatLayoutHandsFreeLabel;
    return Semantics(
      label: strings.chatLayoutContinuousVoiceLabel,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hands-free voice is an eyes-free surface, so the capture state has
          // to be announced rather than only rendered.
          Semantics(
            container: true,
            liveRegion: true,
            label: label,
            child: ExcludeSemantics(child: Text(label)),
          ),
          Switch(
            key: const ValueKey('hermes-continuous-voice-switch'),
            value: active,
            onChanged: canSendTurns && voiceEnabled
                ? _setContinuousVoice
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingAttachment() {
    final colors = Theme.of(context).colorScheme;
    final strings = AppLocalizations.of(context);
    final name = _safeHermesUiPreview(_stagedAttachment!.name, maxLength: 40);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: strings.chatLayoutAttachedFileLabel(name),
      child: Container(
        key: const ValueKey('hermes-pending-attachment'),
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(
                _stagedAttachment is StagedImageAttachment
                    ? Icons.image_outlined
                    : Icons.description_outlined,
                color: colors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: ExcludeSemantics(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, overflow: TextOverflow.ellipsis),
                    Text(
                      strings.chatLayoutReadyToSendLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: strings.chatLayoutRemoveAttachmentTooltip,
              icon: const Icon(Icons.close_rounded, size: 20),
              visualDensity: VisualDensity.compact,
              onPressed: () => _setState(() => _stagedAttachment = null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentButton(HermesChannel channel, bool canSendTurns) {
    return IconButton(
      key: const ValueKey('hermes-attachment-button'),
      tooltip: AppLocalizations.of(context).chatLayoutAttachFileTooltip,
      icon: const Icon(Icons.attach_file),
      onPressed: canSendTurns && !_isTurnActive(channel.state)
          ? () => unawaited(_pickAttachment())
          : null,
    );
  }

  Widget _buildMicButton(bool canSendTurns) {
    if (_voiceInputController.capturing) {
      return IconButton.filled(
        key: const ValueKey('hermes-mic-button'),
        tooltip: AppLocalizations.of(context).chatLayoutHandsFreeLabel,
        icon: _VoiceWaveform(
          level: _voiceInputController.soundLevel,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        onPressed: _voiceInputController.pause,
      );
    }
    if (_voiceInputController.speaking) {
      return IconButton.filledTonal(
        key: const ValueKey('hermes-tts-stop-button'),
        tooltip: AppLocalizations.of(context).chatLayoutStopSpeakingTooltip,
        icon: const Icon(Icons.volume_up_rounded),
        onPressed: _voiceInputController.pause,
      );
    }
    final voiceEnabled = ref.watch(
      wingVoiceSettingsProvider.select(
        (settings) => settings.continuousVoiceEnabled,
      ),
    );
    // The tooltip must not own the long-press gesture: long-press dictates
    // into the composer for review instead of sending immediately, so the
    // tooltip is hover/manual only. Because that moves the tooltip off the
    // button, the icon carries the accessible name so the button node keeps
    // announcing more than "button".
    final micLabel = AppLocalizations.of(context).chatLayoutHandsFreeVoiceLabel;
    final micButton = Tooltip(
      message: micLabel,
      triggerMode: TooltipTriggerMode.manual,
      child: IconButton.filledTonal(
        key: const ValueKey('hermes-mic-button'),
        icon: Icon(Icons.mic_rounded, semanticLabel: micLabel),
        onPressed: !canSendTurns || !voiceEnabled
            ? null
            : () => _setContinuousVoice(true),
      ),
    );
    if (_voiceInputController.capturing || !canSendTurns || !voiceEnabled) {
      return micButton;
    }
    return GestureDetector(
      onLongPress: () => unawaited(_voiceInputController.captureDraft()),
      child: micButton,
    );
  }

  Widget _buildSendButton(HermesChannel channel, bool canSendTurns) {
    final hasPayload =
        _composerController.text.trim().isNotEmpty || _stagedAttachment != null;
    return IconButton.filled(
      key: const ValueKey('hermes-send-button'),
      tooltip: AppLocalizations.of(context).chatLayoutSendTooltip,
      icon: const Icon(Icons.arrow_upward_rounded),
      onPressed: canSendTurns && hasPayload
          ? () => _sendComposerText(channel)
          : null,
    );
  }

  List<Widget> _composerIconButtons(HermesChannel channel, bool canSendTurns) =>
      [
        _buildAttachmentButton(channel, canSendTurns),
        _buildMicButton(canSendTurns),
        _buildSendButton(channel, canSendTurns),
      ];
}

class _VoiceWaveform extends StatelessWidget {
  const _VoiceWaveform({this.level, this.color});

  final double? level;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final barColor = color ?? Theme.of(context).colorScheme.onPrimaryContainer;
    final activity = _normalizedLevel(level);
    return ExcludeSemantics(
      child: SizedBox(
        key: const ValueKey('hermes-voice-waveform'),
        width: 28,
        height: 28,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [0.55, 0.8, 1.0, 0.8, 0.55]
              .map(
                (weight) => AnimatedContainer(
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.easeOut,
                  constraints: BoxConstraints.tightFor(
                    width: 3,
                    height: 5 + 19 * activity * weight,
                  ),
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }

  double _normalizedLevel(double? value) {
    if (value == null) return 0;
    // Darwin reports average power in dB; Android and other backends expose
    // their own RMS-like scale.
    final normalized = switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => (value + 60) / 60,
      _ => (value + 2) / 12,
    };
    return normalized.clamp(0.0, 1.0);
  }
}
