part of '../screens/hermes_chat_screen.dart';

enum _QueuedFollowUpMenuAction { openSession, copy, sendNow, cancelAll }

extension _HermesChatScreenMessageFlow on _HermesChatScreenState {
  HermesComposerSubmission? _captureComposerSubmission() {
    final key = _activeComposerDraftKey;
    return key == null ? null : _composerDrafts.captureForSubmission(key);
  }

  void _restoreComposerSubmission(HermesComposerSubmission? submission) {
    if (submission == null ||
        submission.key != _activeComposerDraftKey ||
        !_composerDrafts.restoreSubmission(submission)) {
      return;
    }
    final text = _composerDrafts.read(submission.key).text;
    _composerController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _setState(() {});
  }

  void _sendComposerText(HermesChannel channel) {
    final composing = _composerController.value.composing;
    if (_composerCompositionActive ||
        composing.isValid && !composing.isCollapsed) {
      return;
    }
    final text = _composerController.text.trim();
    final staged = _stagedAttachment;
    if (text.isEmpty && staged == null) return;
    _scheduleTranscriptScrollToBottom(force: true);
    if (staged == null && _runExactLocalSlashCommand(text, channel)) {
      return;
    }
    if (_isTurnActive(channel.state)) {
      if (staged == null && channel.canSteerActiveTurn) {
        _rememberComposerText(text);
        final submission = _captureComposerSubmission();
        _composerController.clear();
        _setState(() => _followUps.error = null);
        unawaited(_steerActiveTurn(channel, text, submission));
        return;
      }
      if (_followUps.isFull) {
        _setState(() {
          _followUps.error = AppLocalizations.of(
            context,
          ).chatQueuedFullError(_maxQueuedFollowUps);
        });
        return;
      }
      _rememberComposerText(text);
      _composerController.clear();
      _setState(() {
        _stagedAttachment = null;
        _attachmentError = null;
        _followUps.enqueue(
          text,
          channel.state.activeSessionId,
          imageDataUrl: staged?.imageDataUrl,
          textAttachment: staged?.textContent,
          attachmentName: staged?.name,
        );
      });
      return;
    }
    _rememberComposerText(text);
    final submission = _captureComposerSubmission();
    _composerController.clear();
    _setState(() {
      _followUps.error = null;
      _stagedAttachment = null;
      _attachmentError = null;
    });
    _sendText(
      channel,
      text,
      imageDataUrl: staged?.imageDataUrl,
      textAttachment: staged?.textContent,
      attachmentName: staged?.name,
      submission: submission,
    );
  }

  ContentInsertionConfiguration get _composerContentInsertionConfiguration =>
      ContentInsertionConfiguration(
        allowedMimeTypes: _composerImageInsertionMimeTypes,
        onContentInserted: _insertComposerContent,
      );

  bool _rejectAdditionalComposerAttachment() {
    if (_stagedAttachment == null) return false;
    _showAttachmentError(
      AppLocalizations.of(context).chatAttachmentRemoveCurrentError,
    );
    return true;
  }

  void _insertComposerContent(KeyboardInsertedContent content) {
    if (_rejectAdditionalComposerAttachment()) return;
    _invalidateAttachmentPick();
    final generation = _attachmentPickGeneration;
    final strings = AppLocalizations.of(context);
    final bytes = content.data;
    if (bytes == null || bytes.isEmpty) {
      _showAttachmentError(strings.chatAttachmentInsertedImageReadError);
      return;
    }
    if (bytes.length > maxImageAttachmentInputBytes) {
      _showAttachmentError(strings.chatAttachmentImageSizeError);
      return;
    }
    final mimeType = supportedImageMimeType(bytes);
    if (mimeType == null) {
      _showAttachmentError(strings.chatAttachmentPastedImageTypeError);
      return;
    }
    final extension = switch (mimeType) {
      'image/png' => 'png',
      'image/jpeg' => 'jpg',
      'image/gif' => 'gif',
      'image/webp' => 'webp',
      _ => 'image',
    };
    final name = 'pasted-image.$extension';
    if (bytes.length <= maxImageAttachmentBytes) {
      _setState(() {
        _attachmentError = null;
        _stagedAttachment = StagedImageAttachment(
          name: name,
          bytes: bytes,
          mimeType: mimeType,
        );
      });
      return;
    }
    unawaited(
      _stageComposerImage(
        name: name,
        bytes: bytes,
        mimeType: mimeType,
        generation: generation,
      ),
    );
  }

  Future<void> _stageComposerImage({
    required String name,
    required Uint8List bytes,
    required String mimeType,
    required int generation,
  }) async {
    final normalized = await normalizeHermesImageAttachment(
      name: name,
      bytes: bytes,
      mimeType: mimeType,
    );
    if (!mounted || generation != _attachmentPickGeneration) return;
    if (normalized == null) {
      _showAttachmentError(
        AppLocalizations.of(context).chatAttachmentImageSizeError,
      );
      return;
    }
    _setState(() {
      _attachmentError = null;
      _stagedAttachment = StagedImageAttachment(
        name: normalized.name,
        bytes: normalized.bytes,
        mimeType: normalized.mimeType,
      );
    });
  }

  Future<void> _pickAttachment() async {
    if (_pickingAttachment || _rejectAdditionalComposerAttachment()) return;
    final channel = ref.read(hermesChannelProvider);
    if (!channel.state.isConnected || channel.state.activeSessionId == null) {
      return;
    }
    _syncAttachmentOwner(channel);
    final generation = ++_attachmentPickGeneration;
    bool isCurrent() => mounted && generation == _attachmentPickGeneration;
    _setState(() => _pickingAttachment = true);
    final strings = AppLocalizations.of(context);
    try {
      final file = await ref.read(hermesAttachmentPickerProvider)();
      if (file == null || !isCurrent()) return;
      final length = await file.length();
      if (!isCurrent()) return;
      final isText = isTextAttachment(name: file.name, mimeType: file.mimeType);
      if (isText && length > maxTextAttachmentBytes) {
        _showAttachmentError(strings.chatAttachmentTextSizeError);
        return;
      }
      if (!isText && length > maxImageAttachmentInputBytes) {
        _showAttachmentError(strings.chatAttachmentImageSizeError);
        return;
      }
      final bytes = await file.readAsBytes();
      if (!isCurrent()) return;
      final mimeType = supportedImageMimeType(bytes);
      if (mimeType != null) {
        await _stageComposerImage(
          name: file.name,
          bytes: bytes,
          mimeType: mimeType,
          generation: generation,
        );
        return;
      }
      if (isText) {
        final content = utf8.decode(bytes);
        if (!isCurrent()) return;
        _setState(() {
          _attachmentError = null;
          _stagedAttachment = StagedTextAttachment(
            name: file.name,
            content: content,
          );
        });
        return;
      }
      _showAttachmentError(strings.chatAttachmentUnsupportedTypeError);
    } on FormatException {
      if (isCurrent()) {
        _showAttachmentError(strings.chatAttachmentInvalidUtf8Error);
      }
    } catch (error) {
      if (isCurrent()) {
        _showAttachmentError(
          strings.chatAttachmentOpenError(_safeAttachmentErrorDetail(error)),
        );
      }
    } finally {
      if (isCurrent()) _setState(() => _pickingAttachment = false);
    }
  }

  String _safeAttachmentErrorDetail(Object error) {
    final detail = error.toString().replaceFirst(
      RegExp(r'^(?:Bad state|Exception):\s*'),
      '',
    );
    return _safeHermesUiError(detail);
  }

  void _showAttachmentError(String message) {
    _setState(() => _attachmentError = message);
  }

  bool _isTurnActive(HermesChannelState state) =>
      state.activeMessages.isNotEmpty &&
      state.activeMessages.last.status == HermesTurnStatus.streaming;

  bool _hasChatTransport(HermesChannelState state) {
    final capabilities = state.capabilities;
    if (capabilities == null) return true;
    return HermesTransportPolicy(capabilities).supportsAnyChatTransport;
  }

  bool _canSendTurns(HermesChannelState state) {
    if (state.activeSessionId == null || state.hasUnreconciledRun) return false;
    return _hasChatTransport(state);
  }

  bool _canRespondToApprovals(HermesChannelState state) {
    final capabilities = state.capabilities;
    if (capabilities == null) return true;
    return HermesTransportPolicy(capabilities).supportsRunApprovalResponse;
  }

  bool _canCreateSession(HermesChannelState state) => state.canCreateSessions;

  Future<void> _steerActiveTurn(
    HermesChannel channel,
    String text,
    HermesComposerSubmission? submission,
  ) async {
    final ownerGeneration = _composerOwnerGeneration;
    try {
      await channel.steerActiveTurn(text);
    } catch (error) {
      if (!mounted ||
          !channel.state.isConnected ||
          ownerGeneration != _composerOwnerGeneration) {
        return;
      }
      _restoreComposerSubmission(submission);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            ).chatSteerFailed(_safeHermesUiError(error)),
          ),
        ),
      );
    }
  }

  void _sendQueuedFollowUpIfIdle(HermesChannel channel) {
    final queued = _followUps.takeNextIfEligible(
      activeSessionId: channel.state.activeSessionId,
      turnActive: _isTurnActive(channel.state),
      canSendTurns: _canSendTurns(channel.state),
    );
    if (queued == null) return;
    _sendText(
      channel,
      queued.text,
      requeueOnFailure: true,
      requeueSessionId: queued.sessionId,
      imageDataUrl: queued.imageDataUrl,
      textAttachment: queued.textAttachment,
      attachmentName: queued.attachmentName,
    );
  }

  void _dropQueuedFollowUpsForMissingSessions(HermesChannelState state) {
    final knownSessionIds = state.sessions.map((session) => session.id).toSet();
    _followUps.dropForMissingSessions(knownSessionIds);
    final retained = _failedDirectTurn;
    if (retained != null && !knownSessionIds.contains(retained.sessionId)) {
      _failedDirectTurn = null;
    }
  }

  bool _canSendQueuedFollowUp(HermesChannelState state) =>
      _followUps.canSendNext(
        activeSessionId: state.activeSessionId,
        turnActive: _isTurnActive(state),
        canSendTurns: _canSendTurns(state),
      );

  bool _canOpenQueuedFollowUpSession(HermesChannelState state) =>
      _followUps.canOpenNextSession(
        activeSessionId: state.activeSessionId,
        knownSessionIds: state.sessions.map((session) => session.id).toSet(),
      );

  Future<void> _openQueuedFollowUpSession(
    BuildContext context,
    HermesChannel channel,
  ) async {
    if (!_canOpenQueuedFollowUpSession(channel.state)) return;
    final sessionId = _followUps.next?.sessionId;
    if (sessionId == null) return;
    final strings = AppLocalizations.of(context);
    try {
      await channel.selectSession(sessionId);
    } catch (error) {
      if (!context.mounted) return;
      _setState(() {
        _followUps.error = strings.chatQueuedOpenSessionError(
          _safeHermesUiError(error),
        );
      });
    }
  }

  void _retryLastFailedTurn(HermesChannel channel) {
    if (!_canSendTurns(channel.state)) return;
    final retryableText = _retryableFailedUserText(channel.state);
    if (retryableText == null) return;
    final retained = _failedDirectTurn;
    if (retained != null &&
        retained.sessionId == channel.state.activeSessionId) {
      _sendText(
        channel,
        retained.text,
        imageDataUrl: retained.imageDataUrl,
        textAttachment: retained.textAttachment,
        attachmentName: retained.attachmentName,
      );
      return;
    }
    _sendText(channel, retryableText);
  }

  void _sendText(
    HermesChannel channel,
    String text, {
    bool requeueOnFailure = false,
    String? requeueSessionId,
    String? imageDataUrl,
    String? textAttachment,
    String? attachmentName,
    HermesComposerSubmission? submission,
  }) {
    final ownerGeneration = _composerOwnerGeneration;
    final sessionId = requeueSessionId ?? channel.state.activeSessionId;
    if (!requeueOnFailure) _failedDirectTurn = null;
    if (ref.read(wingVoiceSettingsProvider).speakRepliesEnabled) {
      _voiceInputController.speakNextReply();
    }
    unawaited(
      channel
          .sendText(
            text,
            imageDataUrl: imageDataUrl,
            textAttachment: textAttachment,
            attachmentName: attachmentName,
          )
          .catchError((Object error) {
            if (!mounted ||
                !channel.state.isConnected ||
                ownerGeneration != _composerOwnerGeneration) {
              return;
            }
            _restoreComposerSubmission(submission);
            if (requeueOnFailure) {
              _setState(
                () => _followUps.requeueFailed(
                  text,
                  sessionId,
                  imageDataUrl: imageDataUrl,
                  textAttachment: textAttachment,
                  attachmentName: attachmentName,
                  message: AppLocalizations.of(
                    context,
                  ).chatQueuedSendError(_safeHermesUiError(error)),
                ),
              );
              return;
            }
            if (sessionId == null ||
                channel.state.activeSessionId != sessionId) {
              return;
            }
            _setState(() {
              _failedDirectTurn = _FailedDirectTurnPayload(
                sessionId: sessionId,
                text: text,
                imageDataUrl: imageDataUrl,
                textAttachment: textAttachment,
                attachmentName: attachmentName,
              );
            });
          }),
    );
  }

  String? _retryableFailedUserText(HermesChannelState state) {
    final turns = state.activeMessages;
    if (turns.length < 2) return null;
    final assistantTurn = turns.last;
    final userTurn = turns[turns.length - 2];
    if (assistantTurn.author != HermesTurnAuthor.assistant ||
        assistantTurn.status != HermesTurnStatus.failed ||
        userTurn.author != HermesTurnAuthor.user) {
      return null;
    }
    final text = userTurn.text.trim();
    if (text.isNotEmpty) return text;
    final retained = _failedDirectTurn;
    return retained != null &&
            retained.sessionId == state.activeSessionId &&
            retained.hasAttachment
        ? ''
        : null;
  }

  String _queuedFollowUpSummary(HermesChannelState state) {
    final strings = AppLocalizations.of(context);
    final count = _followUps.length;
    final preview = _followUps.pending
        .take(2)
        .map((queued) => _queuedFollowUpPreview(queued, strings))
        .join(' • ');
    final remaining = count - 2;
    final suffix = remaining > 0
        ? ' • ${strings.chatQueuedMore(remaining)}'
        : '';
    final waiting = !_canSendTurns(state)
        ? ' ${strings.chatQueuedWaitingForTransport}'
        : _followUps.next?.sessionId != state.activeSessionId
        ? ' ${strings.chatQueuedWaitingForOriginalSession}'
        : '';
    return '${strings.chatQueuedSummary(count, preview)}$suffix$waiting';
  }

  String _queuedFollowUpPreview(
    QueuedFollowUp queued,
    AppLocalizations strings,
  ) {
    final text = _safeHermesUiPreview(queued.text, maxLength: 48);
    final attachmentName = queued.attachmentName;
    if (attachmentName == null || attachmentName.isEmpty) return text;
    final attachment = strings.chatQueuedAttachmentPreview(
      _safeHermesUiPreview(attachmentName, maxLength: 48),
    );
    return text.isEmpty ? attachment : '$text · $attachment';
  }

  String _queuedFollowUpDetailsSummary(HermesChannelState state) {
    final buffer = StringBuffer()
      ..writeln('Hermes queued follow-ups')
      ..writeln('Queued: ${_followUps.length}')
      ..writeln(
        'Active session: ${_safeHermesUiPreview(state.activeSessionId ?? 'none', maxLength: 80)}',
      )
      ..writeln(
        'Next session: ${_safeHermesUiPreview(_followUps.next?.sessionId ?? 'none', maxLength: 80)}',
      )
      ..writeln('Can send now: ${_canSendQueuedFollowUp(state)}');
    var index = 1;
    for (final queued in _followUps.pending.take(_maxQueuedFollowUps)) {
      final text = _safeHermesUiPreview(queued.text, maxLength: 160);
      final attachment = queued.attachmentName == null
          ? ''
          : ' [attachment: ${_safeHermesUiPreview(queued.attachmentName!, maxLength: 80)}]';
      buffer.writeln('$index. $text$attachment');
      index += 1;
    }
    buffer.write('Secrets: redacted');
    return buffer.toString();
  }

  Future<void> _manageQueuedFollowUps(BuildContext context) async {
    if (_followUps.isEmpty) return;
    final strings = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final pending = _followUps.pending;
          return AlertDialog(
            key: const ValueKey('hermes-queued-follow-up-manage-dialog'),
            title: Text(strings.chatQueuedManageTitle(pending.length)),
            content: SizedBox(
              width: 420,
              height: pending.length * 72.0,
              child: ListView.separated(
                itemCount: pending.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final queued = pending[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _queuedFollowUpPreview(queued, strings),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Semantics(
                      key: ValueKey('hermes-queued-follow-up-remove-$index'),
                      button: true,
                      label: strings.chatQueuedCancelOneAction,
                      child: ExcludeSemantics(
                        child: IconButton(
                          tooltip: strings.chatQueuedCancelOneAction,
                          onPressed: () {
                            _setState(() => _followUps.removeAt(index));
                            if (_followUps.isEmpty) {
                              Navigator.of(dialogContext).pop();
                              return;
                            }
                            setDialogState(() {});
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(strings.closeAction),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmClearQueuedFollowUps(BuildContext context) async {
    if (_followUps.isEmpty) return;
    final strings = AppLocalizations.of(context);
    final count = _followUps.length;
    final preview = _followUps.pending
        .take(3)
        .map((queued) => _safeHermesUiPreview(queued.text, maxLength: 80))
        .join('\n');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('hermes-queued-follow-up-clear-dialog'),
        title: Text(strings.chatQueuedCancelTitle(count)),
        content: Text(
          '$preview'
          '${count > 3 ? '\n${strings.chatQueuedMore(count - 3)}' : ''}'
          '\n\n${strings.chatQueuedRedactedNote}',
        ),
        actions: [
          TextButton(
            key: const ValueKey('hermes-queued-follow-up-clear-keep'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.chatQueuedKeepAction),
          ),
          FilledButton(
            key: const ValueKey('hermes-queued-follow-up-clear-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.chatQueuedCancelAllAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _setState(() {
      _followUps.clear();
      _followUps.error = null;
    });
  }
}
