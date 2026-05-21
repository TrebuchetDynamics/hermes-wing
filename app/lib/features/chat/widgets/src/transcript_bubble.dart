part of '../transcript_surface.dart';

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: const ValueKey('assistant-typing-indicator'),
        margin: const EdgeInsets.only(top: 4, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TelegramBubble extends StatelessWidget {
  const _TelegramBubble({
    required this.message,
    required this.isUser,
    required this.showTail,
    required this.forwardTargets,
    required this.onForward,
    required this.textToSpeechService,
  });

  final NavivoxChatMessage message;
  final bool isUser;
  final bool showTail;
  final List<NavivoxProfileContact> forwardTargets;
  final void Function(NavivoxChatMessage message, NavivoxProfileContact target)?
  onForward;
  final TextToSpeechService? textToSpeechService;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor = isUser
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHigh;
    final textColor = isUser
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;
    final timeColor = isUser
        ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.6)
        : theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: () => _showTranscriptMessageActions(
        context: context,
        message: message,
        forwardTargets: forwardTargets,
        onForward: onForward,
        textToSpeechService: textToSpeechService,
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tailWidth = showTail ? 12.0 : 0.0;
            final maxBubbleWidth = (constraints.maxWidth - tailWidth) * 0.78;
            return Row(
              mainAxisAlignment: isUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isUser && showTail)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: CustomPaint(
                      size: const Size(8, 12),
                      painter: _BubbleTailPainter(
                        color: bubbleColor,
                        flip: false,
                      ),
                    ),
                  ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: Radius.circular(
                          isUser ? 12 : (showTail ? 4 : 12),
                        ),
                        bottomRight: Radius.circular(
                          isUser ? (showTail ? 4 : 12) : 12,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MessageBody(message: message, textColor: textColor),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8, top: 2),
                            child: Text(
                              DateFormat.Hm().format(message.createdAt),
                              style: TextStyle(color: timeColor, fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isUser && showTail)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: CustomPaint(
                      size: const Size(8, 12),
                      painter: _BubbleTailPainter(
                        color: bubbleColor,
                        flip: true,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  const _BubbleTailPainter({required this.color, required this.flip});

  final Color color;
  final bool flip;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (flip) {
      path.moveTo(size.width, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height * 0.6);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height * 0.6);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BubbleTailPainter oldDelegate) =>
      color != oldDelegate.color || flip != oldDelegate.flip;
}
