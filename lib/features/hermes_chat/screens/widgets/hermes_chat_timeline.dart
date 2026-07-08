part of '../hermes_chat_screen.dart';

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
    required this.chatError,
    required this.onRetryError,
    required this.onReconnectError,
    required this.onReauthorizeError,
  });

  final ScrollController controller;
  final List<HermesChatTurn> turns;
  final HermesApprovalRequest? pendingApproval;
  final int pendingApprovalCount;
  final bool canRespondToApprovals;
  final String? respondingApprovalId;
  final ValueChanged<HermesApprovalDecision> onResolveApproval;
  final VoidCallback onDismissApproval;
  final String? chatError;
  final VoidCallback? onRetryError;
  final VoidCallback onReconnectError;
  final VoidCallback onReauthorizeError;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var index = 0; index < turns.length; index++) {
      final turn = turns[index];
      if (turn.kind == HermesTurnKind.toolCall && turn.toolCall != null) {
        final group = <HermesChatTurn>[turn];
        while (index + 1 < turns.length &&
            turns[index + 1].kind == HermesTurnKind.toolCall &&
            turns[index + 1].toolCall != null) {
          group.add(turns[++index]);
        }
        rows.add(_ToolActivityGroup(turns: group));
      } else {
        rows.add(_TurnBubble(turn: turn));
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
        ),
      );
    }

    return ListView(
      key: const ValueKey('hermes-transcript'),
      controller: controller,
      padding: const EdgeInsets.all(12),
      children: rows,
    );
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
    final status = failed
        ? 'Needs attention'
        : running
        ? 'Running'
        : 'Completed';
    final title = tools.length == 1
        ? 'Tool activity: ${_safeHermesUiPreview(tools.single.name, maxLength: 48)}'
        : 'Tool activity: ${tools.length} calls';

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

class _TurnBubble extends StatelessWidget {
  const _TurnBubble({required this.turn});

  final HermesChatTurn turn;

  @override
  Widget build(BuildContext context) {
    final isUser = turn.author == HermesTurnAuthor.user;
    final streaming = turn.status == HermesTurnStatus.streaming;
    final bubble = Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        key: ValueKey('hermes-turn-${turn.id}'),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(turn.text)),
            if (streaming) ...[
              const SizedBox(width: 8),
              const SizedBox(
                height: 12,
                width: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
    );
    if (isUser) return bubble;
    return _AssistantTimelineItem(child: bubble);
  }
}
