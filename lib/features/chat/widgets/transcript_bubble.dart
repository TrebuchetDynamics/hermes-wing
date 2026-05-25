import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/channel/navivox_channel.dart';
import '../../../core/protocol/navivox_event.dart';
import '../../voice/services/text_to_speech_service.dart';
import '../../voice/widgets/voice_morph_surface.dart';
import '../transcript_message_action_presentation.dart';
import '../transcript_safety_notice_presentation.dart';
import '../transcript_text_message_presentation.dart';
import '../transcript_tool_call_presentation.dart';
import '../transcript_voice_message_presentation.dart';
import 'transcript_message_action_sheet.dart';

class TranscriptBubble extends StatelessWidget {
  const TranscriptBubble({
    required this.message,
    required this.isUser,
    required this.showTail,
    this.forwardTargets = const [],
    this.onForward,
    this.textToSpeechService,
    this.onCancelActiveTurn,
    super.key,
  });

  final NavivoxChatMessage message;
  final bool isUser;
  final bool showTail;
  final List<NavivoxProfileContact> forwardTargets;
  final void Function(NavivoxChatMessage message, NavivoxProfileContact target)?
  onForward;
  final TextToSpeechService? textToSpeechService;
  final VoidCallback? onCancelActiveTurn;

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
      onLongPress: () => _showMessageActions(context),
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
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(
                          isUser ? 16 : (showTail ? 4 : 16),
                        ),
                        bottomRight: Radius.circular(
                          isUser ? (showTail ? 4 : 16) : 16,
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormat.Hm().format(message.createdAt),
                                  style: TextStyle(
                                    color: timeColor,
                                    fontSize: 11,
                                  ),
                                ),
                                if (isUser) ...[
                                  const SizedBox(width: 3),
                                  Semantics(
                                    container: true,
                                    label: 'Sent',
                                    child: ExcludeSemantics(
                                      child: Icon(
                                        Icons.done_all,
                                        size: 14,
                                        color: timeColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
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

  Future<void> _showMessageActions(BuildContext context) {
    final tts = textToSpeechService;
    final canCancel =
        onCancelActiveTurn != null &&
        message.author == NavivoxMessageAuthor.assistant;
    final presentation = TranscriptMessageActionPresentation.fromMessage(
      message,
      textToSpeechAvailable: tts != null,
      canCancelActiveTurn: canCancel,
      forwardTargets: forwardTargets,
      forwardingAvailable: onForward != null,
    );
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.52,
        minChildSize: 0.28,
        maxChildSize: 0.92,
        builder: (sheetContext, scrollController) =>
            TranscriptMessageActionSheet(
              presentation: presentation,
              scrollController: scrollController,
              onPauseStream: !canCancel
                  ? null
                  : () {
                      Navigator.of(sheetContext).pop();
                      onCancelActiveTurn?.call();
                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                        SnackBar(content: Text(presentation.pauseSnackbar)),
                      );
                    },
              onCopyText: () async {
                await Clipboard.setData(ClipboardData(text: presentation.text));
                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                  SnackBar(content: Text(presentation.copySnackbar)),
                );
              },
              onReadAloud: tts == null
                  ? null
                  : () async {
                      await tts.speak(presentation.text);
                      if (!sheetContext.mounted) return;
                      Navigator.of(sheetContext).pop();
                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                        SnackBar(content: Text(presentation.readAloudSnackbar)),
                      );
                    },
              onForward: (target) {
                Navigator.of(sheetContext).pop();
                onForward?.call(message, target);
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

class _MessageBody extends StatelessWidget {
  const _MessageBody({required this.message, this.textColor});

  final NavivoxChatMessage message;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return switch (message.kind) {
      NavivoxMessageKind.text => _TextBody(
        message: message,
        textColor: textColor,
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

class _TextBody extends StatelessWidget {
  const _TextBody({required this.message, this.textColor});

  final NavivoxChatMessage message;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final presentation = TranscriptTextMessagePresentation.fromMessage(message);
    final linkPreview = _TranscriptLinkPreview.maybeFrom(presentation.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _TelegramFormattedText(text: presentation.text, textColor: textColor),
        if (linkPreview != null) ...[
          const SizedBox(height: 8),
          _TelegramLinkPreview(linkPreview: linkPreview, textColor: textColor),
        ],
      ],
    );
  }
}

class _TelegramFormattedText extends StatelessWidget {
  const _TelegramFormattedText({required this.text, this.textColor});

  final String text;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final segments = _TelegramTextSegment.parse(text);
    if (segments.length == 1 && !segments.single.isCode) {
      return _TelegramExpandableText(text: text, textColor: textColor);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final segment in segments) ...[
          if (segment.isCode)
            _TelegramCodeBlock(segment: segment, textColor: textColor)
          else
            _TelegramExpandableText(text: segment.text, textColor: textColor),
          if (segment != segments.last) const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _TelegramTextSegment {
  const _TelegramTextSegment.text(this.text) : language = null;
  const _TelegramTextSegment.code({required this.text, this.language});

  static final _codeFencePattern = RegExp(
    r'```([A-Za-z0-9_+.-]*)\n([\s\S]*?)```',
    multiLine: true,
  );

  final String text;
  final String? language;

  bool get isCode => language != null;

  static List<_TelegramTextSegment> parse(String text) {
    final segments = <_TelegramTextSegment>[];
    var cursor = 0;
    for (final match in _codeFencePattern.allMatches(text)) {
      final before = text.substring(cursor, match.start).trim();
      if (before.isNotEmpty) segments.add(_TelegramTextSegment.text(before));
      final language = match.group(1)?.trim();
      final code = match.group(2)?.trimRight() ?? '';
      segments.add(
        _TelegramTextSegment.code(
          text: code,
          language: language == null || language.isEmpty ? 'code' : language,
        ),
      );
      cursor = match.end;
    }
    final after = text.substring(cursor).trim();
    if (after.isNotEmpty) segments.add(_TelegramTextSegment.text(after));
    return segments.isEmpty ? [_TelegramTextSegment.text(text)] : segments;
  }
}

class _TelegramCodeBlock extends StatelessWidget {
  const _TelegramCodeBlock({required this.segment, this.textColor});

  final _TelegramTextSegment segment;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = textColor ?? theme.colorScheme.onSurface;
    final background = foreground.withValues(alpha: 0.08);
    return Container(
      key: const ValueKey('transcript-code-block'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: foreground.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 10, right: 4),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: foreground.withValues(alpha: 0.10)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    segment.language ?? 'code',
                    style: TextStyle(
                      color: foreground.withValues(alpha: 0.64),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy code',
                  visualDensity: VisualDensity.compact,
                  iconSize: 16,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: segment.text));
                    if (!context.mounted) return;
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      const SnackBar(content: Text('Code copied')),
                    );
                  },
                  icon: Icon(
                    Icons.copy_rounded,
                    color: foreground.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: SelectableText(
              segment.text,
              style: TextStyle(
                color: foreground,
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TelegramExpandableText extends StatefulWidget {
  const _TelegramExpandableText({required this.text, this.textColor});

  static const collapsedMaxLines = 8;
  static const collapseCharacterThreshold = 520;
  static const collapseLineThreshold = 8;

  final String text;
  final Color? textColor;

  @override
  State<_TelegramExpandableText> createState() =>
      _TelegramExpandableTextState();
}

class _TelegramExpandableTextState extends State<_TelegramExpandableText> {
  bool _expanded = false;

  bool get _shouldCollapse =>
      widget.text.length > _TelegramExpandableText.collapseCharacterThreshold ||
      '\n'.allMatches(widget.text).length >=
          _TelegramExpandableText.collapseLineThreshold;

  @override
  void didUpdateWidget(covariant _TelegramExpandableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shouldClamp = _shouldCollapse && !_expanded;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.text,
          key: const ValueKey('transcript-expandable-text'),
          maxLines: shouldClamp
              ? _TelegramExpandableText.collapsedMaxLines
              : null,
          overflow: shouldClamp ? TextOverflow.fade : null,
          style: TextStyle(color: widget.textColor, fontSize: 15),
        ),
        if (_shouldCollapse)
          TextButton(
            key: const ValueKey('transcript-expand-text-toggle'),
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.only(top: 4),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'Show less' : 'Show more',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _TranscriptLinkPreview {
  const _TranscriptLinkPreview({
    required this.url,
    required this.host,
    required this.summary,
  });

  static final _urlPattern = RegExp(
    r'https?:\/\/[^\s<>()]+',
    caseSensitive: false,
  );

  final String url;
  final String host;
  final String summary;

  static _TranscriptLinkPreview? maybeFrom(String text) {
    final match = _urlPattern.firstMatch(text);
    if (match == null) return null;
    final url = match.group(0)!.replaceFirst(RegExp(r'[\],.!?;:]+$'), '');
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    final pathAndQuery = [
      if (uri.path.isNotEmpty) uri.path,
      if (uri.query.isNotEmpty) '?${uri.query}',
    ].join();
    return _TranscriptLinkPreview(
      url: url,
      host: uri.host,
      summary: pathAndQuery.isEmpty ? url : pathAndQuery,
    );
  }
}

class _TelegramLinkPreview extends StatelessWidget {
  const _TelegramLinkPreview({required this.linkPreview, this.textColor});

  final _TranscriptLinkPreview linkPreview;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final foreground = textColor ?? theme.colorScheme.onSurface;
    return Semantics(
      label: 'Link preview for ${linkPreview.host}',
      child: Container(
        key: const ValueKey('transcript-link-preview'),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        decoration: BoxDecoration(
          color: foreground.withValues(alpha: 0.06),
          border: Border(left: BorderSide(color: accent, width: 3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              linkPreview.host,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              linkPreview.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground.withValues(alpha: 0.72),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolCallBody extends StatelessWidget {
  const _ToolCallBody({required this.toolCall, this.textColor});

  final NavivoxToolCall toolCall;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final presentation = TranscriptToolCallPresentation.fromToolCall(toolCall);
    final statusColor = _statusColor(presentation.statusTone);
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
              presentation.name,
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
                presentation.statusLabel,
                style: TextStyle(color: statusColor, fontSize: 11),
              ),
            ),
          ],
        ),
        if (presentation.showSummary) ...[
          const SizedBox(height: 4),
          Text(
            presentation.summary,
            style: TextStyle(
              color: textColor?.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
        for (final artifact in presentation.artifacts) ...[
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
                    if (artifact.showSummary)
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

Color _statusColor(TranscriptToolCallStatusTone tone) {
  return switch (tone) {
    TranscriptToolCallStatusTone.active => Colors.orange,
    TranscriptToolCallStatusTone.success => Colors.green,
    TranscriptToolCallStatusTone.failure => Colors.red,
    TranscriptToolCallStatusTone.neutral => Colors.grey,
  };
}

Color _safetyNoticeAccent(ThemeData theme, TranscriptSafetyNoticeTone tone) {
  return switch (tone) {
    TranscriptSafetyNoticeTone.approval => theme.colorScheme.tertiary,
    TranscriptSafetyNoticeTone.warning => theme.colorScheme.error,
  };
}

IconData _safetyNoticeIcon(TranscriptSafetyNoticeTone tone) {
  return switch (tone) {
    TranscriptSafetyNoticeTone.approval => Icons.verified_user_outlined,
    TranscriptSafetyNoticeTone.warning => Icons.warning_amber,
  };
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
    final presentation = TranscriptSafetyNoticePresentation.fromNotice(
      notice,
      approval: approval,
    );
    final accent = _safetyNoticeAccent(theme, presentation.tone);
    return Container(
      key: ValueKey(presentation.cardKeyValue),
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
                _safetyNoticeIcon(presentation.tone),
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 6),
              Text(
                presentation.title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              if (presentation.showSeverity) ...[
                const SizedBox(width: 8),
                Text(
                  presentation.severityLabel!,
                  style: TextStyle(color: accent, fontSize: 11),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            presentation.message,
            style: TextStyle(color: textColor, fontSize: 13),
          ),
          if (presentation.showRisk) ...[
            const SizedBox(height: 4),
            Text(
              presentation.risk!,
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
    final presentation = TranscriptVoiceMessagePresentation.fromVoice(voice);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        VoiceMorphSurface(
          state: VoiceMorphState.speaking,
          intensity: presentation.morphIntensity,
          size: 40,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              presentation.title,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            Text(
              presentation.durationLabel,
              style: TextStyle(
                color: textColor?.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
            if (presentation.showTranscript)
              Text(
                presentation.transcript,
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
