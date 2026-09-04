part of '../screens/hermes_chat_screen.dart';

enum _TranscriptContextAction { copyText, copyMarkdown }

final class _TranscriptTextScaler extends TextScaler {
  const _TranscriptTextScaler(this.base, this.factor);

  final TextScaler base;
  final double factor;

  @override
  double scale(double fontSize) => base.scale(fontSize) * factor;

  @override
  // Required by TextScaler for legacy callers; scale() retains nonlinear behavior.
  // ignore: deprecated_member_use
  double get textScaleFactor => base.textScaleFactor * factor;

  @override
  bool operator ==(Object other) =>
      other is _TranscriptTextScaler &&
      other.base == base &&
      other.factor == factor;

  @override
  int get hashCode => Object.hash(base, factor);
}

RelativeRect _contextMenuPosition(BuildContext context, Offset globalPosition) {
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final localPosition = overlay.globalToLocal(globalPosition);
  return RelativeRect.fromLTRB(
    localPosition.dx,
    localPosition.dy,
    overlay.size.width - localPosition.dx,
    overlay.size.height - localPosition.dy,
  );
}

class _HermesTranscriptList extends StatelessWidget {
  const _HermesTranscriptList({
    required this.viewport,
    required this.controller,
    required this.textScale,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onScaleEnd,
    required this.turns,
    required this.canLoadEarlierMessages,
    required this.isLoadingEarlierMessages,
    required this.onLoadEarlierMessages,
    required this.profileId,
    required this.profileColor,
    required this.pendingApproval,
    required this.pendingApprovalCount,
    required this.canRespondToApprovals,
    required this.respondingApprovalId,
    required this.onResolveApproval,
    required this.onDismissApproval,
    required this.onReplyTurn,
    required this.onReadAloudTurn,
    required this.readAloudTurnId,
    required this.onStopReadAloud,
    required this.onCopyTranscriptText,
    required this.onCopyTranscriptMarkdown,
    required this.enableDesktopContextMenu,
    required this.chatError,
    required this.onRetryError,
    required this.onReconnectError,
    required this.onReauthorizeError,
    required this.onManageProvidersError,
  });

  final ScrollController controller;
  final HermesTranscriptViewportController viewport;
  final double textScale;
  final GestureScaleStartCallback onScaleStart;
  final GestureScaleUpdateCallback onScaleUpdate;
  final GestureScaleEndCallback onScaleEnd;
  final List<HermesChatTurn> turns;
  final bool canLoadEarlierMessages;
  final bool isLoadingEarlierMessages;
  final VoidCallback onLoadEarlierMessages;
  final String profileId;
  final String? profileColor;
  final HermesApprovalRequest? pendingApproval;
  final int pendingApprovalCount;
  final bool canRespondToApprovals;
  final String? respondingApprovalId;
  final ValueChanged<HermesApprovalDecision> onResolveApproval;
  final VoidCallback onDismissApproval;
  final ValueChanged<HermesChatTurn> onReplyTurn;
  final ValueChanged<HermesChatTurn>? onReadAloudTurn;
  final String? readAloudTurnId;
  final VoidCallback onStopReadAloud;
  final VoidCallback onCopyTranscriptText;
  final VoidCallback onCopyTranscriptMarkdown;
  final bool enableDesktopContextMenu;
  final String? chatError;
  final VoidCallback? onRetryError;
  final VoidCallback onReconnectError;
  final VoidCallback onReauthorizeError;
  final VoidCallback onManageProvidersError;

  @override
  Widget build(BuildContext context) {
    final visibleTurns = turns
        .where(
          (turn) =>
              turn.kind != HermesTurnKind.text ||
              turn.status == HermesTurnStatus.streaming ||
              turn.text.trim().isNotEmpty ||
              turn.attachment != null,
        )
        .toList(growable: false);
    final rows = <Widget>[];
    final uniqueIds = HermesTurnPresentationIdentity.uniqueIds(visibleTurns);
    viewport.retainRows(uniqueIds);
    if (canLoadEarlierMessages || isLoadingEarlierMessages) {
      final strings = AppLocalizations.of(context);
      rows.add(
        Padding(
          key: const ValueKey('hermes-transcript-load-earlier'),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: isLoadingEarlierMessages
                ? Semantics(
                    container: true,
                    liveRegion: true,
                    label: strings.chatTranscriptLoadingEarlierLabel,
                    child: ExcludeSemantics(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Text(strings.chatTranscriptLoadingEarlierLabel),
                        ],
                      ),
                    ),
                  )
                : OutlinedButton.icon(
                    key: const ValueKey(
                      'hermes-transcript-load-earlier-action',
                    ),
                    onPressed: onLoadEarlierMessages,
                    icon: const Icon(Icons.history),
                    label: Text(strings.chatTranscriptLoadEarlierAction),
                  ),
          ),
        ),
      );
    }
    for (var index = 0; index < visibleTurns.length; index++) {
      final turn = visibleTurns[index];
      final rowIndex = index;
      final showAssistantAvatar =
          turn.author != HermesTurnAuthor.user &&
          (index == 0 ||
              visibleTurns[index - 1].author == HermesTurnAuthor.user);
      if (turn.kind == HermesTurnKind.reasoning) {
        rows.add(
          _ReasoningCard(
            turn: turn,
            profileId: profileId,
            profileColor: profileColor,
            showAvatar: showAssistantAvatar,
          ),
        );
      } else if (turn.kind == HermesTurnKind.toolCall &&
          turn.toolCall != null) {
        final group = <HermesChatTurn>[turn];
        while (index + 1 < visibleTurns.length &&
            visibleTurns[index + 1].kind == HermesTurnKind.toolCall &&
            visibleTurns[index + 1].toolCall != null) {
          group.add(visibleTurns[++index]);
        }
        rows.add(
          _ToolActivityGroup(
            turns: group,
            profileId: profileId,
            profileColor: profileColor,
            showAvatar: showAssistantAvatar,
          ),
        );
      } else {
        rows.add(
          _TurnBubble(
            turn: turn,
            profileId: profileId,
            profileColor: profileColor,
            showAvatar: showAssistantAvatar,
            onReply: onReplyTurn,
            onReadAloud: onReadAloudTurn,
            readAloudActive: readAloudTurnId == turn.id,
            onStopReadAloud: onStopReadAloud,
            onCopyTranscriptText: onCopyTranscriptText,
            onCopyTranscriptMarkdown: onCopyTranscriptMarkdown,
            enableDesktopContextMenu: enableDesktopContextMenu,
          ),
        );
      }
      rows[rows.length - 1] = KeyedSubtree(
        key: uniqueIds.contains(turn.id)
            ? viewport.rowKey(turn.id)
            : ValueKey(
                HermesTurnPresentationIdentity.resolve(
                  visibleTurns,
                  rowIndex,
                  unique: uniqueIds,
                ),
              ),
        child: rows.last,
      );
    }

    final approval = pendingApproval;
    if (approval != null) {
      rows.add(
        _ApprovalBanner(
          request: approval,
          pendingCount: pendingApprovalCount,
          responding: approval.identityKey == respondingApprovalId,
          canRespond: canRespondToApprovals,
          onDecide: onResolveApproval,
          onDismissMalformed: onDismissApproval,
        ),
      );
    }
    final error = chatError;
    if (error != null) {
      rows.add(
        _HermesChatError(
          error: error,
          onRetry: onRetryError,
          onReconnect: onReconnectError,
          onReauthorize: onReauthorizeError,
          onManageProviders: onManageProvidersError,
        ),
      );
    }

    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onScaleStart: onScaleStart,
      onScaleUpdate: onScaleUpdate,
      onScaleEnd: onScaleEnd,
      onSecondaryTapDown: !enableDesktopContextMenu || turns.isEmpty
          ? null
          : (details) => unawaited(
              _showTranscriptContextMenu(context, details.globalPosition),
            ),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: _TranscriptTextScaler(
            MediaQuery.textScalerOf(context),
            textScale,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.alphaBlend(
                  colors.primary.withValues(alpha: 0.025),
                  colors.surface,
                ),
                colors.surface,
              ],
            ),
          ),
          child: Column(
            children: [
              ListenableBuilder(
                listenable: viewport,
                builder: (context, child) =>
                    viewport.mode == HermesViewportMode.followingLatest
                    ? const SizedBox.shrink()
                    : Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: child,
                      ),
                child: TextButton.icon(
                  key: const ValueKey('hermes-transcript-latest'),
                  onPressed: () {
                    viewport.followLatest();
                    if (controller.hasClients) {
                      controller.jumpTo(controller.position.minScrollExtent);
                    }
                  },
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  label: Text(
                    AppLocalizations.of(context).chatTranscriptLatestAction,
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  key: viewport.listKey,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: viewport.onScroll,
                    child: ListView(
                      key: const ValueKey('hermes-transcript'),
                      controller: controller,
                      reverse: true,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                      children: rows.reversed.toList(growable: false),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTranscriptContextMenu(
    BuildContext context,
    Offset globalPosition,
  ) async {
    final strings = AppLocalizations.of(context);
    final action = await showMenu<_TranscriptContextAction>(
      context: context,
      position: _contextMenuPosition(context, globalPosition),
      items: [
        PopupMenuItem(
          key: const ValueKey('hermes-context-copy-chat-text'),
          value: _TranscriptContextAction.copyText,
          child: Text(strings.chatTranscriptCopyChatTextAction),
        ),
        PopupMenuItem(
          key: const ValueKey('hermes-context-copy-chat-markdown'),
          value: _TranscriptContextAction.copyMarkdown,
          child: Text(strings.chatTranscriptCopyChatMarkdownAction),
        ),
      ],
    );
    switch (action) {
      case _TranscriptContextAction.copyText:
        onCopyTranscriptText();
      case _TranscriptContextAction.copyMarkdown:
        onCopyTranscriptMarkdown();
      case null:
        return;
    }
  }
}

class _AssistantTimelineItem extends StatelessWidget {
  const _AssistantTimelineItem({
    required this.child,
    this.profileId = 'default',
    this.profileColor,
    this.showAvatar = true,
  });

  final Widget child;
  final String profileId;
  final String? profileColor;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) return child;
        final identityColor = hermesProfileColor(
          profileId,
          advertisedColor: profileColor,
        );
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showAvatar)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: CircleAvatar(
                    key: const ValueKey('hermes-assistant-avatar'),
                    radius: 15,
                    backgroundColor: identityColor,
                    child: Text(
                      profileId.trim().isEmpty
                          ? 'H'
                          : profileId.trim().characters.first.toUpperCase(),
                      style: TextStyle(
                        color: hermesProfileForeground(identityColor),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 30),
              const SizedBox(width: 10),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

class _ReasoningCard extends StatelessWidget {
  const _ReasoningCard({
    required this.turn,
    required this.profileId,
    required this.showAvatar,
    this.profileColor,
  });

  final HermesChatTurn turn;
  final String profileId;
  final String? profileColor;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    return _AssistantTimelineItem(
      profileId: profileId,
      profileColor: profileColor,
      showAvatar: showAvatar,
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            key: ValueKey('hermes-reasoning-${turn.id}'),
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ExpansionTile(
              leading: const Icon(Icons.psychology_outlined),
              title: Text(AppLocalizations.of(context).reasoningTitle),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: HermesRichText(
                    _safeHermesUiText(turn.text),
                    selectable: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _HostToolCategory {
  web,
  browser,
  files,
  code,
  voice,
  memory,
  delegation,
  schedule,
  other,
}

_HostToolCategory _hostToolCategory(String name) {
  return switch (name.trim().toLowerCase()) {
    'web_search' || 'web_fetch' || 'fetch' => _HostToolCategory.web,
    'browse' || 'browser' => _HostToolCategory.browser,
    'read_file' ||
    'write_file' ||
    'edit_file' ||
    'list_files' ||
    'delete_file' ||
    'search_files' ||
    'read' ||
    'write' ||
    'edit' ||
    'glob' ||
    'grep' => _HostToolCategory.files,
    'execute_code' ||
    'run_code' ||
    'python' ||
    'terminal' ||
    'bash' ||
    'shell' ||
    'run_command' ||
    'run_shell' => _HostToolCategory.code,
    'speak' || 'tts' => _HostToolCategory.voice,
    'remember' || 'recall' => _HostToolCategory.memory,
    'delegate' ||
    'spawn_agent' ||
    'subagent' ||
    'subagent_fork' ||
    'workflow' ||
    'ralph' => _HostToolCategory.delegation,
    'schedule' => _HostToolCategory.schedule,
    _ => _HostToolCategory.other,
  };
}

String? _hostToolCategoryLabel(
  AppLocalizations strings,
  _HostToolCategory category,
) => switch (category) {
  _HostToolCategory.web => strings.chatTranscriptToolCategoryWeb,
  _HostToolCategory.browser => strings.chatTranscriptToolCategoryBrowser,
  _HostToolCategory.files => strings.chatTranscriptToolCategoryFiles,
  _HostToolCategory.code => strings.chatTranscriptToolCategoryCode,
  _HostToolCategory.voice => strings.chatTranscriptToolCategoryVoice,
  _HostToolCategory.memory => strings.chatTranscriptToolCategoryMemory,
  _HostToolCategory.delegation => strings.chatTranscriptToolCategoryDelegation,
  _HostToolCategory.schedule => strings.chatTranscriptToolCategorySchedule,
  _HostToolCategory.other => null,
};

IconData? _hostToolCategoryIcon(_HostToolCategory category) =>
    switch (category) {
      _HostToolCategory.web => Icons.public,
      _HostToolCategory.browser => Icons.language,
      _HostToolCategory.files => Icons.folder_outlined,
      _HostToolCategory.code => Icons.code,
      _HostToolCategory.voice => Icons.record_voice_over_outlined,
      _HostToolCategory.memory => Icons.memory_outlined,
      _HostToolCategory.delegation => Icons.account_tree_outlined,
      _HostToolCategory.schedule => Icons.schedule_outlined,
      _HostToolCategory.other => null,
    };

IconData _hostToolStatusIcon(String status) => switch (status) {
  'failed' => Icons.error_outline,
  'running' => Icons.hourglass_top_outlined,
  _ => Icons.check_circle_outline,
};

String _hostToolStatusLabel(AppLocalizations strings, String status) =>
    switch (status) {
      'failed' => strings.chatTranscriptToolStatusNeedsAttentionLabel,
      'running' => strings.chatTranscriptToolStatusRunningLabel,
      _ => strings.chatTranscriptToolStatusCompletedLabel,
    };

class _ToolActivityGroup extends StatelessWidget {
  const _ToolActivityGroup({
    required this.turns,
    required this.profileId,
    required this.showAvatar,
    this.profileColor,
  });

  final List<HermesChatTurn> turns;
  final String profileId;
  final String? profileColor;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    final tools = turns.map((turn) => turn.toolCall!).toList();
    final aggregateStatus = tools.any((tool) => tool.status == 'failed')
        ? 'failed'
        : tools.any((tool) => tool.status == 'running')
        ? 'running'
        : 'completed';
    final strings = AppLocalizations.of(context);
    final categories = tools
        .map((tool) => _hostToolCategory(tool.name))
        .toList(growable: false);
    final aggregateIcon = _hostToolStatusIcon(aggregateStatus);
    final status = _hostToolStatusLabel(strings, aggregateStatus);
    final title = tools.length == 1
        ? _hostToolCategoryLabel(strings, categories.single) ??
              strings.chatTranscriptHostActivityTitle
        : strings.chatTranscriptHostActivityCountTitle(tools.length);
    final statusText = Semantics(
      key: ValueKey('hermes-tool-activity-status-${turns.first.id}'),
      container: true,
      liveRegion: aggregateStatus != 'completed',
      child: Text(status),
    );

    return _AssistantTimelineItem(
      profileId: profileId,
      profileColor: profileColor,
      showAvatar: showAvatar,
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            key: ValueKey('hermes-tool-activity-${turns.first.id}'),
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: tools.length == 1
                ? ListTile(
                    leading: Icon(
                      _hostToolCategoryIcon(categories.single) ?? aggregateIcon,
                    ),
                    title: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: statusText,
                  )
                : ExpansionTile(
                    leading: Icon(aggregateIcon),
                    title: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: statusText,
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    children: [
                      for (final (index, tool) in tools.indexed)
                        ListTile(
                          key: ValueKey(
                            'hermes-tool-activity-step-${index + 1}',
                          ),
                          dense: true,
                          leading: Icon(
                            _hostToolCategoryIcon(categories[index]) ??
                                _hostToolStatusIcon(tool.status),
                            size: 20,
                          ),
                          title: Text(
                            _hostToolCategoryLabel(
                                  strings,
                                  categories[index],
                                ) ??
                                strings.chatTranscriptHostStepTitle(index + 1),
                          ),
                          subtitle: Text(
                            _hostToolStatusLabel(strings, tool.status),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent({
    required this.text,
    required this.attachment,
    required this.undeliveredLocalArtifact,
    required this.selectable,
  });

  final String text;
  final HermesTurnAttachment? attachment;
  final _UndeliveredLocalArtifact? undeliveredLocalArtifact;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final displayText = text;
    final safeAttachment = attachment == null
        ? null
        : _DisplayAttachment(
            name: _safeHermesUiPreview(
              attachment!.name.replaceAll(RegExp(r'\s+'), ' ').trim(),
              maxLength: 120,
            ),
            image: attachment!.kind == HermesAttachmentKind.image,
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (displayText.isNotEmpty)
          HermesRichText(displayText, selectable: selectable),
        if (displayText.isNotEmpty &&
            (undeliveredLocalArtifact != null || safeAttachment != null))
          const SizedBox(height: 8),
        if (undeliveredLocalArtifact != null)
          _UndeliveredLocalArtifactNotice(undeliveredLocalArtifact!),
        if (undeliveredLocalArtifact != null && safeAttachment != null)
          const SizedBox(height: 8),
        if (safeAttachment != null)
          _MessageAttachmentCard(attachment: safeAttachment),
      ],
    );
  }
}

enum _UndeliveredLocalArtifact { audio, media, file }

_UndeliveredLocalArtifact? _undeliveredLocalArtifact(String text) {
  if (wingContainsHostAudioReference(text)) {
    return _UndeliveredLocalArtifact.audio;
  }
  if (_mentionsExplicitMediaToken(text)) return _UndeliveredLocalArtifact.media;
  if (wingContainsHostArtifactReference(text)) {
    return _UndeliveredLocalArtifact.file;
  }
  return null;
}

bool _mentionsExplicitMediaToken(String text) =>
    wingContainsMediaDeliveryToken(text);

class _UndeliveredLocalArtifactNotice extends StatelessWidget {
  const _UndeliveredLocalArtifactNotice(this.artifact);

  final _UndeliveredLocalArtifact artifact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strings = AppLocalizations.of(context);
    final body = switch (artifact) {
      _UndeliveredLocalArtifact.audio =>
        strings.chatLocalAudioArtifactUndeliveredBody,
      _UndeliveredLocalArtifact.media =>
        strings.chatLocalMediaArtifactUndeliveredBody,
      _UndeliveredLocalArtifact.file =>
        strings.chatLocalFileArtifactUndeliveredBody,
    };
    return Semantics(
      container: true,
      label: '${strings.chatLocalArtifactUndeliveredTitle}. $body',
      child: Container(
        key: const ValueKey('hermes-undelivered-local-artifact'),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.tertiaryContainer.withValues(alpha: 0.45),
          border: Border.all(color: colors.tertiary.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 20,
              color: colors.onTertiaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.chatLocalArtifactUndeliveredTitle,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.onTertiaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageAttachmentCard extends StatelessWidget {
  const _MessageAttachmentCard({required this.attachment});

  final _DisplayAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strings = AppLocalizations.of(context);
    final attachmentLabel = attachment.image
        ? strings.chatImageAttachmentLabel(attachment.name)
        : strings.chatFileAttachmentLabel(attachment.name);
    return Semantics(
      label: attachmentLabel,
      child: Container(
        key: ValueKey('hermes-message-attachment-${attachment.name}'),
        constraints: const BoxConstraints(minWidth: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(
                attachment.image
                    ? Icons.image_outlined
                    : Icons.insert_drive_file_outlined,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    attachment.image
                        ? strings.chatImageAttachmentTypeLabel
                        : _fileTypeLabel(strings, attachment.name),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisplayAttachment {
  const _DisplayAttachment({required this.name, required this.image});

  final String name;
  final bool image;
}

String _fileTypeLabel(AppLocalizations strings, String name) {
  final dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) {
    return strings.chatFileAttachmentTypeLabel;
  }
  final extension = name.substring(dot + 1).toUpperCase();
  return extension.length <= 8
      ? strings.chatFileExtensionTypeLabel(extension)
      : strings.chatFileAttachmentTypeLabel;
}

enum _TurnAction {
  copy,
  reply,
  readAloud,
  copyTranscriptText,
  copyTranscriptMarkdown,
}

String _visibleTurnTimestamp(
  AppLocalizations strings,
  DateTime createdAt, {
  required DateTime now,
  required String olderLabel,
  required String futureLabel,
}) {
  final elapsed = now.difference(createdAt);
  if (elapsed.isNegative) return futureLabel;
  if (elapsed < const Duration(minutes: 1)) {
    return strings.chatTranscriptTimestampJustNow;
  }
  if (elapsed < const Duration(hours: 1)) {
    return strings.chatTranscriptTimestampMinutesAgo(elapsed.inMinutes);
  }
  if (elapsed < const Duration(days: 1)) {
    return strings.chatTranscriptTimestampHoursAgo(elapsed.inHours);
  }
  if (elapsed < const Duration(days: 7)) {
    return strings.chatTranscriptTimestampDaysAgo(elapsed.inDays);
  }
  return olderLabel;
}

class _TurnBubble extends StatelessWidget {
  const _TurnBubble({
    required this.turn,
    required this.profileId,
    required this.profileColor,
    required this.showAvatar,
    required this.onReply,
    required this.onReadAloud,
    required this.readAloudActive,
    required this.onStopReadAloud,
    required this.onCopyTranscriptText,
    required this.onCopyTranscriptMarkdown,
    required this.enableDesktopContextMenu,
  });

  final HermesChatTurn turn;
  final String profileId;
  final String? profileColor;
  final bool showAvatar;
  final ValueChanged<HermesChatTurn> onReply;
  final ValueChanged<HermesChatTurn>? onReadAloud;
  final bool readAloudActive;
  final VoidCallback onStopReadAloud;
  final VoidCallback onCopyTranscriptText;
  final VoidCallback onCopyTranscriptMarkdown;
  final bool enableDesktopContextMenu;

  String get _safeText => turn.author == HermesTurnAuthor.user
      ? turn.text
      : _safeHermesUiText(turn.text);

  HermesChatTurn get _safeTurn {
    final text = _safeText;
    return text == turn.text ? turn : turn.copyWith(text: text);
  }

  bool get _canReply =>
      turn.author != HermesTurnAuthor.assistant ||
      turn.status == HermesTurnStatus.completed;

  bool get _canCopy =>
      turn.status != HermesTurnStatus.streaming && _safeText.trim().isNotEmpty;

  bool get _canReadAloud =>
      onReadAloud != null &&
      turn.author == HermesTurnAuthor.assistant &&
      turn.status == HermesTurnStatus.completed &&
      _safeText.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isUser = turn.author == HermesTurnAuthor.user;
    final safeText = _safeText;
    final streaming = turn.status == HermesTurnStatus.streaming;
    final usage = isUser ? null : turn.usage;
    final structuredError = isUser ? null : _structuredAssistantError(safeText);
    final strings = AppLocalizations.of(context);
    final materialStrings = MaterialLocalizations.of(context);
    final localCreatedAt = turn.createdAt.toLocal();
    final compactTimestamp = materialStrings.formatTimeOfDay(
      TimeOfDay.fromDateTime(localCreatedAt),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final fullTimestamp = strings.chatTranscriptFullTimestamp(
      materialStrings.formatFullDate(localCreatedAt),
      compactTimestamp,
    );
    final visibleTimestamp = _visibleTurnTimestamp(
      strings,
      localCreatedAt,
      now: DateTime.now(),
      olderLabel: materialStrings.formatShortDate(localCreatedAt),
      futureLabel: compactTimestamp,
    );
    final colors = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final bubble = Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        key: ValueKey('hermes-turn-${turn.id}'),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        constraints: BoxConstraints(
          maxWidth: screenWidth < 600 ? screenWidth * 0.84 : 560,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? colors.primary.withValues(alpha: 0.22)
              : structuredError != null
              ? colors.error.withValues(alpha: 0.1)
              : colors.surfaceContainerHigh,
          border: Border.all(
            color: isUser
                ? colors.primary.withValues(alpha: 0.18)
                : structuredError != null
                ? colors.error.withValues(alpha: 0.35)
                : colors.outlineVariant.withValues(alpha: 0.32),
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 5),
            bottomRight: Radius.circular(isUser ? 5 : 16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: structuredError != null
                      ? _StructuredAssistantError(structuredError)
                      : _MessageContent(
                          text: safeText,
                          attachment: turn.attachment,
                          undeliveredLocalArtifact:
                              !isUser && turn.attachment == null
                              ? _undeliveredLocalArtifact(turn.text)
                              : null,
                          selectable: enableDesktopContextMenu,
                        ),
                ),
                if (streaming) ...[
                  const SizedBox(width: 8),
                  if (MediaQuery.disableAnimationsOf(context))
                    Icon(
                      Icons.pending_outlined,
                      key: const ValueKey('hermes-streaming-reduced-motion'),
                      size: 12,
                      color: colors.primary,
                    )
                  else
                    const SizedBox(
                      height: 12,
                      width: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
                const SizedBox(width: 8),
                Semantics(
                  key: ValueKey('hermes-turn-timestamp-${turn.id}'),
                  container: true,
                  label: fullTimestamp,
                  child: ExcludeSemantics(
                    child: Tooltip(
                      message: fullTimestamp,
                      child: Text(
                        visibleTimestamp,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: colors.onSurfaceVariant.withValues(
                            alpha: 0.72,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (enableDesktopContextMenu && _canCopy) ...[
                  const SizedBox(width: 2),
                  IconButton(
                    key: ValueKey('hermes-copy-message-${turn.id}'),
                    tooltip: strings.chatTranscriptCopyAction,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 28,
                      height: 28,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () =>
                        unawaited(_handleAction(context, _TurnAction.copy)),
                    icon: const Icon(Icons.copy_outlined, size: 15),
                  ),
                ],
              ],
            ),
            if (readAloudActive)
              Semantics(
                container: true,
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.graphic_eq, size: 16, color: colors.primary),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(
                          context,
                        ).chatTranscriptReadingAloudLabel,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(width: 2),
                      IconButton(
                        key: ValueKey('hermes-stop-read-aloud-${turn.id}'),
                        tooltip: AppLocalizations.of(
                          context,
                        ).chatTranscriptStopReadAloudAction,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: onStopReadAloud,
                        icon: const Icon(Icons.stop_circle_outlined, size: 19),
                      ),
                    ],
                  ),
                ),
              ),
            if (usage != null)
              Semantics(
                container: true,
                label: AppLocalizations.of(context).runTokenUsageSemantics(
                  usage.inputTokens,
                  usage.outputTokens,
                  usage.totalTokens,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: ExcludeSemantics(
                    child: Tooltip(
                      message: AppLocalizations.of(
                        context,
                      ).runTokenUsageTooltip,
                      child: Text(
                        AppLocalizations.of(context).runTokenUsage(
                          usage.inputTokens,
                          usage.outputTokens,
                          usage.totalTokens,
                        ),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    final interactiveBubble = GestureDetector(
      onLongPress: _canReply || _canCopy || _canReadAloud
          ? () => _showActions(context)
          : null,
      child: bubble,
    );
    final desktopInteractiveBubble = enableDesktopContextMenu
        ? Listener(
            onPointerDown: (event) {
              if (event.buttons & kSecondaryMouseButton == 0) return;
              unawaited(_showDesktopActions(context, event.position));
            },
            child: interactiveBubble,
          )
        : interactiveBubble;
    if (isUser) return desktopInteractiveBubble;
    return _AssistantTimelineItem(
      profileId: profileId,
      profileColor: profileColor,
      showAvatar: showAvatar,
      child: desktopInteractiveBubble,
    );
  }

  Future<void> _showActions(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    final action = await showModalBottomSheet<_TurnAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            if (_canReply)
              ListTile(
                leading: const Icon(Icons.reply_outlined),
                title: Text(strings.chatTranscriptReplyAction),
                onTap: () => Navigator.pop(context, _TurnAction.reply),
              ),
            if (_canCopy)
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: Text(strings.chatTranscriptCopyAction),
                onTap: () => Navigator.pop(context, _TurnAction.copy),
              ),
            if (_canReadAloud)
              ListTile(
                key: const ValueKey('hermes-read-aloud-message'),
                leading: const Icon(Icons.volume_up_outlined),
                title: Text(strings.chatTranscriptReadAloudAction),
                onTap: () => Navigator.pop(context, _TurnAction.readAloud),
              ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    await _handleAction(context, action);
  }

  Future<void> _showDesktopActions(
    BuildContext context,
    Offset globalPosition,
  ) async {
    final strings = AppLocalizations.of(context);
    final action = await showMenu<_TurnAction>(
      context: context,
      position: _contextMenuPosition(context, globalPosition),
      items: [
        if (_canReply)
          PopupMenuItem(
            key: const ValueKey('hermes-context-reply-message'),
            value: _TurnAction.reply,
            child: Text(strings.chatTranscriptReplyAction),
          ),
        if (_canCopy)
          PopupMenuItem(
            key: const ValueKey('hermes-context-copy-message'),
            value: _TurnAction.copy,
            child: Text(strings.chatTranscriptCopyAction),
          ),
        if (_canReadAloud)
          PopupMenuItem(
            key: const ValueKey('hermes-context-read-aloud-message'),
            value: _TurnAction.readAloud,
            child: Text(strings.chatTranscriptReadAloudAction),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          key: const ValueKey('hermes-context-copy-chat-text'),
          value: _TurnAction.copyTranscriptText,
          child: Text(strings.chatTranscriptCopyChatTextAction),
        ),
        PopupMenuItem(
          key: const ValueKey('hermes-context-copy-chat-markdown'),
          value: _TurnAction.copyTranscriptMarkdown,
          child: Text(strings.chatTranscriptCopyChatMarkdownAction),
        ),
      ],
    );
    if (!context.mounted || action == null) return;
    await _handleAction(context, action);
  }

  Future<void> _handleAction(BuildContext context, _TurnAction action) async {
    switch (action) {
      case _TurnAction.copy:
        if (!_canCopy) return;
        await Clipboard.setData(ClipboardData(text: _safeText));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).chatTranscriptMessageCopiedLabel,
              ),
            ),
          );
        }
      case _TurnAction.reply:
        if (_canReply) onReply(_safeTurn);
      case _TurnAction.readAloud:
        onReadAloud?.call(_safeTurn);
      case _TurnAction.copyTranscriptText:
        onCopyTranscriptText();
      case _TurnAction.copyTranscriptMarkdown:
        onCopyTranscriptMarkdown();
    }
  }
}

class _StructuredAssistantError extends StatefulWidget {
  const _StructuredAssistantError(this.message);

  final String message;

  @override
  State<_StructuredAssistantError> createState() =>
      _StructuredAssistantErrorState();
}

class _StructuredAssistantErrorState extends State<_StructuredAssistantError> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final long = widget.message.length > 160;
    return Column(
      key: const ValueKey('hermes-structured-assistant-error'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 18,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).chatTranscriptActionBlockedTitle,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          widget.message,
          maxLines: long && !_expanded ? 2 : null,
          overflow: long && !_expanded ? TextOverflow.ellipsis : null,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35),
        ),
        if (long)
          TextButton(
            key: const ValueKey('hermes-structured-error-details'),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 32),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded
                  ? AppLocalizations.of(context).chatTranscriptHideDetailsAction
                  : AppLocalizations.of(context).chatTranscriptDetailsAction,
            ),
          ),
      ],
    );
  }
}

String? _structuredAssistantError(String raw) {
  if (!raw.trimLeft().startsWith('{')) return null;
  try {
    final value = jsonDecode(raw);
    if (value is! Map || value['status'] != 'error') return null;
    final message = value['error'];
    if (message is! String || message.trim().isEmpty) return null;
    return _safeHermesUiPreview(message, maxLength: 4000);
  } on FormatException {
    return null;
  }
}
