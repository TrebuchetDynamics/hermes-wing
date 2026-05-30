import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/channel/navivox_channel.dart';
import '../../../../core/protocol/navivox_event.dart';
import '../../../voice/services/tts/text_to_speech_service.dart';
import '../../../voice/widgets/voice_morph_surface.dart';
import '../../transcript/presentation/transcript_message_action_presentation.dart';
import '../../transcript/presentation/transcript_safety_notice_presentation.dart';
import '../../transcript/presentation/transcript_text_message_presentation.dart';
import '../../transcript/presentation/transcript_tool_call_presentation.dart';
import '../../transcript/presentation/transcript_voice_message_presentation.dart';
import 'transcript_message_action_sheet.dart';

class TranscriptBubble extends StatelessWidget {
  const TranscriptBubble({
    required this.message,
    required this.isUser,
    required this.showTail,
    this.forwardTargets = const [],
    this.onForward,
    this.onInspectRunRecord,
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
  final FutureOr<void> Function(NavivoxChatMessage message)? onInspectRunRecord;
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

    return _TelegramReactionSurface(
      isUser: isUser,
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
    final runRecordAction = onInspectRunRecord;
    final presentation = TranscriptMessageActionPresentation.fromMessage(
      message,
      textToSpeechAvailable: tts != null,
      canCancelActiveTurn: canCancel,
      forwardTargets: forwardTargets,
      forwardingAvailable: onForward != null,
      runRecordInspectionAvailable: runRecordAction != null,
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
              onInspectRunRecord: runRecordAction == null
                  ? null
                  : () async {
                      Navigator.of(sheetContext).pop();
                      await runRecordAction(message);
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

class _TelegramReactionSurface extends StatefulWidget {
  const _TelegramReactionSurface({
    required this.child,
    required this.isUser,
    required this.onLongPress,
  });

  final Widget child;
  final bool isUser;
  final VoidCallback onLongPress;

  @override
  State<_TelegramReactionSurface> createState() =>
      _TelegramReactionSurfaceState();
}

class _TelegramReactionSurfaceState extends State<_TelegramReactionSurface> {
  static const _doubleTapWindow = Duration(milliseconds: 320);
  static const _doubleTapSlop = 48.0;

  bool _hearted = false;
  DateTime? _lastTapAt;
  Offset? _lastTapPosition;

  void _handlePointerUp(Offset position) {
    final now = DateTime.now();
    final lastTapAt = _lastTapAt;
    final lastTapPosition = _lastTapPosition;
    final isDoubleTap =
        lastTapAt != null &&
        now.difference(lastTapAt) <= _doubleTapWindow &&
        lastTapPosition != null &&
        (position - lastTapPosition).distance <= _doubleTapSlop;

    _lastTapAt = now;
    _lastTapPosition = position;

    if (isDoubleTap) {
      _lastTapAt = null;
      _lastTapPosition = null;
      setState(() => _hearted = !_hearted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerUp: (event) => _handlePointerUp(event.position),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: widget.onLongPress,
        child: Column(
          crossAxisAlignment: widget.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.child,
            if (_hearted)
              Container(
                key: const ValueKey('transcript-local-reaction'),
                margin: EdgeInsets.only(
                  left: widget.isUser ? 0 : 24,
                  right: widget.isUser ? 24 : 0,
                  bottom: 2,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
                child: const Text('❤️', style: TextStyle(fontSize: 13)),
              ),
          ],
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
    if (segments.length == 1 && segments.single.isPlainText) {
      return _TelegramExpandableText(text: text, textColor: textColor);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final segment in segments) ...[
          if (segment.isCode)
            _TelegramCodeBlock(segment: segment, textColor: textColor)
          else if (segment.isQuote)
            _TelegramBlockquote(segment: segment, textColor: textColor)
          else if (segment.isBulletList)
            _TelegramBulletList(segment: segment, textColor: textColor)
          else if (segment.isNumberedList)
            _TelegramNumberedList(segment: segment, textColor: textColor)
          else
            _TelegramExpandableText(text: segment.text, textColor: textColor),
          if (segment != segments.last) const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _TelegramTextSegment {
  const _TelegramTextSegment.text(this.text)
    : language = null,
      quote = false,
      bulletItems = null,
      numberedItems = null,
      startNumber = 1;
  const _TelegramTextSegment.quote(this.text)
    : language = null,
      quote = true,
      bulletItems = null,
      numberedItems = null,
      startNumber = 1;
  const _TelegramTextSegment.bullets(this.bulletItems)
    : text = '',
      language = null,
      quote = false,
      numberedItems = null,
      startNumber = 1;
  const _TelegramTextSegment.numbered(this.numberedItems, this.startNumber)
    : text = '',
      language = null,
      quote = false,
      bulletItems = null;
  const _TelegramTextSegment.code({required this.text, this.language})
    : quote = false,
      bulletItems = null,
      numberedItems = null,
      startNumber = 1;

  static final _codeFencePattern = RegExp(
    r'```([A-Za-z0-9_+.-]*)\n([\s\S]*?)```',
    multiLine: true,
  );

  final String text;
  final String? language;
  final bool quote;
  final List<String>? bulletItems;
  final List<String>? numberedItems;
  final int startNumber;

  bool get isCode => language != null;
  bool get isQuote => quote;
  bool get isBulletList => bulletItems != null;
  bool get isNumberedList => numberedItems != null;
  bool get isPlainText =>
      !isCode && !isQuote && !isBulletList && !isNumberedList;

  static List<_TelegramTextSegment> parse(String text) {
    final segments = <_TelegramTextSegment>[];
    var cursor = 0;
    for (final match in _codeFencePattern.allMatches(text)) {
      _addTextSegments(segments, text.substring(cursor, match.start));
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
    _addTextSegments(segments, text.substring(cursor));
    return segments.isEmpty ? [_TelegramTextSegment.text(text)] : segments;
  }

  static void _addTextSegments(
    List<_TelegramTextSegment> segments,
    String source,
  ) {
    final lines = source.trim().split('\n');
    final prose = <String>[];
    final quote = <String>[];
    final bullets = <String>[];
    final numberedItems = <String>[];
    int? numberedStart;

    void flushProse() {
      final text = prose.join('\n').trim();
      if (text.isNotEmpty) segments.add(_TelegramTextSegment.text(text));
      prose.clear();
    }

    void flushQuote() {
      final text = quote.join('\n').trim();
      if (text.isNotEmpty) segments.add(_TelegramTextSegment.quote(text));
      quote.clear();
    }

    void flushBullets() {
      if (bullets.isNotEmpty) {
        segments.add(_TelegramTextSegment.bullets(List.unmodifiable(bullets)));
      }
      bullets.clear();
    }

    void flushNumbered() {
      if (numberedItems.isNotEmpty) {
        segments.add(
          _TelegramTextSegment.numbered(
            List.unmodifiable(numberedItems),
            numberedStart ?? 1,
          ),
        );
      }
      numberedItems.clear();
      numberedStart = null;
    }

    for (final line in lines) {
      final trimmed = line.trimRight();
      final numberedMatch = RegExp(
        r'^(\d+)\.\s+(.+)$',
      ).firstMatch(trimmed.trimLeft());
      if (trimmed.trim().isEmpty) {
        flushProse();
        flushQuote();
        flushBullets();
        flushNumbered();
      } else if (trimmed.trimLeft().startsWith('>')) {
        flushProse();
        flushBullets();
        flushNumbered();
        quote.add(trimmed.trimLeft().replaceFirst(RegExp(r'^>\s?'), ''));
      } else if (RegExp(r'^[-*]\s+').hasMatch(trimmed.trimLeft())) {
        flushProse();
        flushQuote();
        flushNumbered();
        bullets.add(trimmed.trimLeft().replaceFirst(RegExp(r'^[-*]\s+'), ''));
      } else if (numberedMatch != null) {
        flushProse();
        flushQuote();
        flushBullets();
        numberedStart ??= int.tryParse(numberedMatch.group(1)!) ?? 1;
        numberedItems.add(numberedMatch.group(2)!);
      } else {
        flushQuote();
        flushBullets();
        flushNumbered();
        prose.add(trimmed);
      }
    }
    flushProse();
    flushQuote();
    flushBullets();
    flushNumbered();
  }
}

class _TelegramBlockquote extends StatelessWidget {
  const _TelegramBlockquote({required this.segment, this.textColor});

  final _TelegramTextSegment segment;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = textColor ?? theme.colorScheme.onSurface;
    final accent = theme.colorScheme.primary;
    return Container(
      key: const ValueKey('transcript-blockquote'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.06),
        border: Border(left: BorderSide(color: accent, width: 3)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: _TelegramInlineText(
        text: segment.text,
        textColor: foreground.withValues(alpha: 0.82),
      ),
    );
  }
}

class _TelegramBulletList extends StatelessWidget {
  const _TelegramBulletList({required this.segment, this.textColor});

  final _TelegramTextSegment segment;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = textColor ?? theme.colorScheme.onSurface;
    final markerColor = theme.colorScheme.primary;
    final items = segment.bulletItems ?? const <String>[];
    return Column(
      key: const ValueKey('transcript-bullet-list'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7, right: 8),
                  child: Container(
                    key: const ValueKey('transcript-bullet-marker'),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: markerColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: _TelegramInlineText(text: item, textColor: foreground),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TelegramNumberedList extends StatelessWidget {
  const _TelegramNumberedList({required this.segment, this.textColor});

  final _TelegramTextSegment segment;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = textColor ?? theme.colorScheme.onSurface;
    final markerColor = theme.colorScheme.primary;
    final items = segment.numberedItems ?? const <String>[];
    return Column(
      key: const ValueKey('transcript-numbered-list'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < items.length; index += 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    '${segment.startNumber + index}.',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: markerColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TelegramInlineText(
                    text: items[index],
                    textColor: foreground,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
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

class _TelegramInlineText extends StatelessWidget {
  const _TelegramInlineText({
    required this.text,
    this.textColor,
    this.maxLines,
    this.overflow,
  });

  static final _inlinePattern = RegExp(
    r'(\[(@[^:]+):([^\]]+)\]|`[^`]+`|https?:\/\/[^\s<>()]+|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}|\+?[0-9][0-9 .()-]{6,}[0-9]|\*[^*]+\*|_[^_]+_|~[^~]+~|(?<!\w)[@#][A-Za-z0-9_]+)',
  );

  final String text;
  final Color? textColor;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final spans = _inlineSpans(context);
    if (spans == null) {
      return Text(
        text,
        key: const ValueKey('transcript-expandable-text'),
        maxLines: maxLines,
        overflow: overflow,
        style: TextStyle(color: textColor, fontSize: 15),
      );
    }
    return Text.rich(
      TextSpan(children: spans),
      key: const ValueKey('transcript-formatted-inline-text'),
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(color: textColor, fontSize: 15),
    );
  }

  List<InlineSpan>? _inlineSpans(BuildContext context) {
    final matches = _inlinePattern.allMatches(text).toList();
    if (matches.isEmpty) return null;
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in matches) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      final raw = _trimTrailingPunctuation(match.group(0)!);
      spans.add(_formattedSpan(raw, Theme.of(context).colorScheme.primary));
      cursor = match.start + raw.length;
    }
    if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
    return spans;
  }

  String _trimTrailingPunctuation(String raw) {
    if (raw.startsWith('http') || raw.contains('@')) {
      return raw.replaceFirst(RegExp(r'[,.;:!?]+$'), '');
    }
    return raw;
  }

  TextSpan _accentSpan(String text, Color accent) => TextSpan(
    text: text,
    style: TextStyle(color: accent, fontSize: 15, fontWeight: FontWeight.w700),
  );

  bool _isDetectionPattern(String raw) =>
      raw.startsWith('http://') ||
      raw.startsWith('https://') ||
      raw.contains('@') ||
      RegExp(r'^\+?[0-9][0-9 .()-]{6,}[0-9]$').hasMatch(raw);

  TextSpan _formattedSpan(String raw, Color accent) {
    final mentionWithId = RegExp(r'^\[(@[^:]+):([^\]]+)\]$').firstMatch(raw);
    if (mentionWithId != null) {
      return _accentSpan(mentionWithId.group(1)!, accent);
    }
    if (_isDetectionPattern(raw)) return _accentSpan(raw, accent);
    final marker = raw.characters.first;
    final inner = marker == '@' || marker == '#'
        ? raw
        : raw.substring(1, raw.length - 1);
    final baseStyle = TextStyle(color: textColor, fontSize: 15);
    return switch (marker) {
      '*' => TextSpan(
        text: inner,
        style: baseStyle.copyWith(fontWeight: FontWeight.w700),
      ),
      '_' => TextSpan(
        text: inner,
        style: baseStyle.copyWith(fontStyle: FontStyle.italic),
      ),
      '`' => TextSpan(
        text: inner,
        style: baseStyle.copyWith(
          fontFamily: 'monospace',
          backgroundColor: (textColor ?? Colors.black).withValues(alpha: 0.10),
        ),
      ),
      '~' => TextSpan(
        text: inner,
        style: baseStyle.copyWith(
          decoration: TextDecoration.lineThrough,
          decorationColor: textColor,
        ),
      ),
      '@' || '#' => TextSpan(
        text: inner,
        style: baseStyle.copyWith(color: accent, fontWeight: FontWeight.w700),
      ),
      _ => TextSpan(text: raw, style: baseStyle),
    };
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
        _TelegramInlineText(
          text: widget.text,
          textColor: widget.textColor,
          maxLines: shouldClamp
              ? _TelegramExpandableText.collapsedMaxLines
              : null,
          overflow: shouldClamp ? TextOverflow.fade : null,
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
        if (presentation.showApproval) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  presentation.approvalLabel!,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                if (presentation.approvalPrompt?.isNotEmpty == true)
                  Text(
                    presentation.approvalPrompt!,
                    style: TextStyle(
                      color: textColor?.withValues(alpha: 0.75),
                      fontSize: 12,
                    ),
                  ),
                if (presentation.approvalRisk?.isNotEmpty == true)
                  Text(
                    presentation.approvalRisk!,
                    style: TextStyle(
                      color: textColor?.withValues(alpha: 0.65),
                      fontSize: 11,
                    ),
                  ),
              ],
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
                    if (artifact.showRef)
                      Text(
                        artifact.ref!,
                        style: TextStyle(
                          color: textColor?.withValues(alpha: 0.55),
                          fontSize: 11,
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
            const SizedBox(height: 4),
            _TelegramVoiceWaveform(
              duration: voice.duration,
              confidence: voice.confidence,
              color: textColor,
            ),
            const SizedBox(height: 3),
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

class _TelegramVoiceWaveform extends StatelessWidget {
  const _TelegramVoiceWaveform({
    required this.duration,
    required this.confidence,
    this.color,
  });

  final Duration duration;
  final double confidence;
  final Color? color;

  List<double> get _bars {
    final seed =
        duration.inMilliseconds + (confidence.clamp(0.0, 1.0) * 100).round();
    return List<double>.generate(22, (index) {
      final wave = ((seed + index * 37) % 11) / 10;
      final pulse = index.isEven ? 0.18 : 0.0;
      return (0.22 + wave * 0.62 + pulse).clamp(0.18, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      key: const ValueKey('transcript-voice-waveform'),
      width: 116,
      height: 24,
      child: CustomPaint(
        painter: _VoiceWaveformPainter(
          bars: _bars,
          color: foreground.withValues(alpha: 0.48),
          accent: Theme.of(context).colorScheme.primary.withValues(alpha: 0.72),
        ),
      ),
    );
  }
}

class _VoiceWaveformPainter extends CustomPainter {
  const _VoiceWaveformPainter({
    required this.bars,
    required this.color,
    required this.accent,
  });

  final List<double> bars;
  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    final unit = size.width / bars.length;
    final barWidth = unit * 0.56;
    final activeBars = (bars.length * 0.28).round();
    for (var index = 0; index < bars.length; index += 1) {
      final barHeight = size.height * bars[index].clamp(0.18, 1.0);
      final left = index * unit + (unit - barWidth) / 2;
      final top = (size.height - barHeight) / 2;
      final rect = Rect.fromLTWH(left, top, barWidth, barHeight);
      final paint = Paint()
        ..color = index < activeBars ? accent : color
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_VoiceWaveformPainter oldDelegate) =>
      bars != oldDelegate.bars ||
      color != oldDelegate.color ||
      accent != oldDelegate.accent;
}
