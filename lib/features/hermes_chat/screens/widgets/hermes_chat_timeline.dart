part of '../hermes_chat_screen.dart';

enum _TranscriptContextAction { copyText, copyMarkdown }

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
    required this.controller,
    required this.turns,
    required this.pendingApproval,
    required this.pendingApprovalCount,
    required this.canRespondToApprovals,
    required this.respondingApprovalId,
    required this.onResolveApproval,
    required this.onDismissApproval,
    required this.onReplyTurn,
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
  final List<HermesChatTurn> turns;
  final HermesApprovalRequest? pendingApproval;
  final int pendingApprovalCount;
  final bool canRespondToApprovals;
  final String? respondingApprovalId;
  final ValueChanged<HermesApprovalDecision> onResolveApproval;
  final VoidCallback onDismissApproval;
  final ValueChanged<HermesChatTurn> onReplyTurn;
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
    final rows = <Widget>[];
    for (var index = 0; index < turns.length; index++) {
      final turn = turns[index];
      if (turn.kind == HermesTurnKind.text &&
          turn.status != HermesTurnStatus.streaming &&
          turn.text.trim().isEmpty) {
        continue;
      }
      if (turn.kind == HermesTurnKind.reasoning) {
        rows.add(_ReasoningCard(turn: turn));
      } else if (turn.kind == HermesTurnKind.toolCall &&
          turn.toolCall != null) {
        final group = <HermesChatTurn>[turn];
        while (index + 1 < turns.length &&
            turns[index + 1].kind == HermesTurnKind.toolCall &&
            turns[index + 1].toolCall != null) {
          group.add(turns[++index]);
        }
        rows.add(_ToolActivityGroup(turns: group));
      } else {
        rows.add(
          _TurnBubble(
            turn: turn,
            onReply: onReplyTurn,
            onCopyTranscriptText: onCopyTranscriptText,
            onCopyTranscriptMarkdown: onCopyTranscriptMarkdown,
            enableDesktopContextMenu: enableDesktopContextMenu,
          ),
        );
      }
    }

    final approval = pendingApproval;
    if (approval != null) {
      rows.add(
        _ApprovalBanner(
          request: approval,
          pendingCount: pendingApprovalCount,
          responding: approval.id.trim() == respondingApprovalId,
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
      onSecondaryTapDown: !enableDesktopContextMenu || turns.isEmpty
          ? null
          : (details) => unawaited(
              _showTranscriptContextMenu(context, details.globalPosition),
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
        child: ListView(
          key: const ValueKey('hermes-transcript'),
          controller: controller,
          reverse: true,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
          children: rows.reversed.toList(growable: false),
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
  const _AssistantTimelineItem({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) return child;
        final colorScheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.18),
                  child: Text(
                    'H',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
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
  const _ReasoningCard({required this.turn});

  final HermesChatTurn turn;

  @override
  Widget build(BuildContext context) {
    return _AssistantTimelineItem(
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
                  child: HermesRichText(turn.text, selectable: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolActivityGroup extends StatelessWidget {
  const _ToolActivityGroup({required this.turns});

  final List<HermesChatTurn> turns;

  @override
  Widget build(BuildContext context) {
    final tools = turns.map((turn) => turn.toolCall!).toList();
    final running = tools.any((tool) => tool.status == 'running');
    final failed = tools.any((tool) => tool.status == 'failed');
    final icon = failed
        ? Icons.error_outline
        : running
        ? Icons.hourglass_top_outlined
        : Icons.check_circle_outline;
    final strings = AppLocalizations.of(context);
    final status = failed
        ? strings.chatTranscriptToolStatusNeedsAttentionLabel
        : running
        ? strings.chatTranscriptToolStatusRunningLabel
        : strings.chatTranscriptToolStatusCompletedLabel;
    final title = tools.length == 1
        ? strings.chatTranscriptToolActivitySingleTitle(
            _safeHermesUiPreview(tools.single.name, maxLength: 48),
          )
        : strings.chatTranscriptToolActivityCountTitle(tools.length);

    return _AssistantTimelineItem(
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            key: ValueKey('hermes-tool-activity-${turns.first.id}'),
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ExpansionTile(
              initiallyExpanded: running || failed,
              leading: Icon(icon),
              title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(status),
              children: [
                for (final turn in turns)
                  _ToolActivityRow(turnId: turn.id, toolCall: turn.toolCall!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolActivityRow extends StatelessWidget {
  const _ToolActivityRow({required this.turnId, required this.toolCall});

  final String turnId;
  final HermesToolCall toolCall;

  @override
  Widget build(BuildContext context) {
    final icon = switch (toolCall.status) {
      'completed' => Icons.check_circle_outline,
      'failed' => Icons.error_outline,
      _ => Icons.hourglass_top_outlined,
    };
    final detail = toolCall.result ?? toolCall.preview;
    return ListTile(
      key: ValueKey('hermes-tool-turn-$turnId'),
      dense: true,
      leading: Icon(icon),
      title: Text(
        _safeHermesUiPreview(toolCall.name, maxLength: 80),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: detail != null
          ? Text(
              _safeHermesUiPreview(detail, maxLength: 160),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            )
          : null,
    );
  }
}

enum _TurnAction { copy, reply, copyTranscriptText, copyTranscriptMarkdown }

class _TurnBubble extends StatelessWidget {
  const _TurnBubble({
    required this.turn,
    required this.onReply,
    required this.onCopyTranscriptText,
    required this.onCopyTranscriptMarkdown,
    required this.enableDesktopContextMenu,
  });

  final HermesChatTurn turn;
  final ValueChanged<HermesChatTurn> onReply;
  final VoidCallback onCopyTranscriptText;
  final VoidCallback onCopyTranscriptMarkdown;
  final bool enableDesktopContextMenu;

  @override
  Widget build(BuildContext context) {
    final isUser = turn.author == HermesTurnAuthor.user;
    final streaming = turn.status == HermesTurnStatus.streaming;
    final usage = isUser ? null : turn.usage;
    final structuredError = isUser
        ? null
        : _structuredAssistantError(turn.text);
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
                  child: isUser
                      ? Text(
                          turn.text,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(height: 1.35),
                        )
                      : structuredError != null
                      ? _StructuredAssistantError(structuredError)
                      : HermesRichText(turn.text, selectable: false),
                ),
                if (streaming) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    height: 12,
                    width: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
                const SizedBox(width: 8),
                Text(
                  MaterialLocalizations.of(context).formatTimeOfDay(
                    TimeOfDay.fromDateTime(turn.createdAt.toLocal()),
                    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(
                      context,
                    ),
                  ),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.72),
                  ),
                ),
              ],
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
          ],
        ),
      ),
    );
    final interactiveBubble = GestureDetector(
      onLongPress: () => _showActions(context),
      onSecondaryTapDown: enableDesktopContextMenu
          ? (details) =>
                unawaited(_showDesktopActions(context, details.globalPosition))
          : null,
      child: bubble,
    );
    if (isUser) return interactiveBubble;
    return _AssistantTimelineItem(child: interactiveBubble);
  }

  Future<void> _showActions(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    final action = await showModalBottomSheet<_TurnAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.reply_outlined),
              title: Text(strings.chatTranscriptReplyAction),
              onTap: () => Navigator.pop(context, _TurnAction.reply),
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: Text(strings.chatTranscriptCopyAction),
              onTap: () => Navigator.pop(context, _TurnAction.copy),
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
        PopupMenuItem(
          key: const ValueKey('hermes-context-reply-message'),
          value: _TurnAction.reply,
          child: Text(strings.chatTranscriptReplyAction),
        ),
        PopupMenuItem(
          key: const ValueKey('hermes-context-copy-message'),
          value: _TurnAction.copy,
          child: Text(strings.chatTranscriptCopyAction),
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
        await Clipboard.setData(ClipboardData(text: turn.text));
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
        onReply(turn);
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
