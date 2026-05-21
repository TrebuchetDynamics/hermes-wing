part of '../transcript_surface.dart';

class _MessageBody extends StatelessWidget {
  const _MessageBody({required this.message, this.textColor});

  final NavivoxChatMessage message;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return switch (message.kind) {
      NavivoxMessageKind.text => Text(
        message.text ?? '',
        style: TextStyle(color: textColor, fontSize: 15),
      ),
      NavivoxMessageKind.toolCall => _ToolCallBody(
        toolCall: message.toolCall!,
        textColor: textColor,
      ),
      NavivoxMessageKind.voice => _VoiceBody(
        voice: message.voice!,
        textColor: textColor,
      ),
      NavivoxMessageKind.safetyWarning => _SafetyNoticeBody(
        notice: message.safetyNotice!,
        approval: false,
        textColor: textColor,
      ),
      NavivoxMessageKind.approvalRequest => _SafetyNoticeBody(
        notice: message.safetyNotice!,
        approval: true,
        textColor: textColor,
      ),
    };
  }
}

class _ToolCallBody extends StatelessWidget {
  const _ToolCallBody({required this.toolCall, this.textColor});

  final NavivoxToolCall toolCall;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (toolCall.status) {
      'started' => Colors.orange,
      'finished' => Colors.green,
      'failed' => Colors.red,
      _ => Colors.grey,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.build_circle,
              size: 16,
              color: textColor?.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              toolCall.name,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                toolCall.status,
                style: TextStyle(color: statusColor, fontSize: 11),
              ),
            ),
          ],
        ),
        if (toolCall.summary.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            toolCall.summary,
            style: TextStyle(
              color: textColor?.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
        for (final artifact in toolCall.artifacts) ...[
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.attachment,
                size: 14,
                color: textColor?.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          artifact.title,
                          style: TextStyle(
                            color: textColor?.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          artifact.kind,
                          style: TextStyle(
                            color: textColor?.withValues(alpha: 0.55),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    if (artifact.summary != null &&
                        artifact.summary!.isNotEmpty)
                      Text(
                        artifact.summary!,
                        style: TextStyle(
                          color: textColor?.withValues(alpha: 0.65),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SafetyNoticeBody extends StatelessWidget {
  const _SafetyNoticeBody({
    required this.notice,
    required this.approval,
    this.textColor,
  });

  final NavivoxSafetyNotice notice;
  final bool approval;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = approval
        ? theme.colorScheme.tertiary
        : theme.colorScheme.error;
    return Container(
      key: ValueKey(
        approval ? 'approval-required-card' : 'safety-warning-card',
      ),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                approval ? Icons.verified_user_outlined : Icons.warning_amber,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 6),
              Text(
                approval ? 'Approval required' : 'Safety warning',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              if (!approval && notice.severity != null) ...[
                const SizedBox(width: 8),
                Text(
                  notice.severity!,
                  style: TextStyle(color: accent, fontSize: 11),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            notice.message,
            style: TextStyle(color: textColor, fontSize: 13),
          ),
          if (notice.risk != null && notice.risk!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              notice.risk!,
              style: TextStyle(
                color: textColor?.withValues(alpha: 0.75),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VoiceBody extends StatelessWidget {
  const _VoiceBody({required this.voice, this.textColor});

  final NavivoxVoiceMessage voice;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        VoiceMorphSurface(
          state: VoiceMorphState.speaking,
          intensity: voice.confidence,
          size: 40,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Voice message',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            Text(
              '${voice.duration.inSeconds}s',
              style: TextStyle(
                color: textColor?.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
            if (voice.transcript.isNotEmpty)
              Text(
                voice.transcript,
                style: TextStyle(
                  color: textColor?.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ],
    );
  }
}
