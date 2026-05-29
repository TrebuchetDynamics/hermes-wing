import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/channel/navivox_channel.dart';
import '../../../../core/protocol/navivox_event.dart';
import '../../../voice/services/tts/text_to_speech_service.dart';
import '../../presentation/transcript/transcript_thread_presentation.dart';
import 'transcript_bubble.dart';

class TranscriptThread extends StatelessWidget {
  const TranscriptThread({
    required this.messages,
    required this.scrollController,
    this.assistantTypingLabel,
    this.dateLabelNow,
    this.forwardTargets = const [],
    this.onForward,
    this.onInspectRunRecord,
    this.textToSpeechService,
    this.onCancelActiveTurn,
    super.key,
  });

  final List<NavivoxChatMessage> messages;
  final ScrollController scrollController;
  final String? assistantTypingLabel;
  final DateTime? dateLabelNow;
  final List<NavivoxProfileContact> forwardTargets;
  final void Function(NavivoxChatMessage message, NavivoxProfileContact target)?
  onForward;
  final FutureOr<void> Function(NavivoxChatMessage message)? onInspectRunRecord;
  final TextToSpeechService? textToSpeechService;
  final VoidCallback? onCancelActiveTurn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presentation = TranscriptThreadPresentation.fromMessages(
      messages,
      assistantTypingLabel: assistantTypingLabel,
    );
    if (presentation.showEmptyState) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              presentation.emptyStateTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    final effectiveDateLabelNow = dateLabelNow ?? DateTime.now();
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: presentation.itemCount,
      itemBuilder: (context, index) {
        if (index == presentation.rows.length) {
          return _TypingIndicator(label: presentation.typingIndicatorLabel!);
        }
        final row = presentation.rows[index];
        final previousMessage = index > 0
            ? presentation.rows[index - 1].message
            : null;
        final showDateSeparator =
            previousMessage == null ||
            !_sameCalendarDay(previousMessage.createdAt, row.message.createdAt);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDateSeparator)
              _DateSeparator(
                date: row.message.createdAt,
                now: effectiveDateLabelNow,
              ),
            if (_isSystemText(row.message))
              _SystemServiceMessage(text: row.message.text ?? '')
            else
              TranscriptBubble(
                message: row.message,
                isUser: row.isUser,
                showTail: row.showTail,
                forwardTargets: forwardTargets,
                onForward: onForward,
                onInspectRunRecord: onInspectRunRecord,
                textToSpeechService: textToSpeechService,
                onCancelActiveTurn: row.canCancelActiveTurn
                    ? onCancelActiveTurn
                    : null,
              ),
          ],
        );
      },
    );
  }
}

bool _sameCalendarDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool _isSystemText(NavivoxChatMessage message) =>
    message.author == NavivoxMessageAuthor.system &&
    message.kind == NavivoxMessageKind.text;

String _formatDateSeparatorLabel(DateTime date, DateTime now) {
  final localDate = DateTime(date.year, date.month, date.day);
  final localNow = DateTime(now.year, now.month, now.day);
  final yesterday = localNow.subtract(const Duration(days: 1));
  if (localDate == localNow) return 'Today';
  if (localDate == yesterday) return 'Yesterday';
  return DateFormat.MMMd().format(date);
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date, required this.now});

  final DateTime date;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        key: ValueKey(
          'transcript-date-separator-${date.year}-${date.month}-${date.day}',
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.86,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          _formatDateSeparatorLabel(date, now),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SystemServiceMessage extends StatelessWidget {
  const _SystemServiceMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        key: const ValueKey('transcript-system-service-message'),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.74,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

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
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(index: 0),
                SizedBox(width: 3),
                _TypingDot(index: 1),
                SizedBox(width: 3),
                _TypingDot(index: 2),
              ],
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

class _TypingDot extends StatelessWidget {
  const _TypingDot({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      key: ValueKey('assistant-typing-dot-$index'),
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.72),
        shape: BoxShape.circle,
      ),
    );
  }
}
