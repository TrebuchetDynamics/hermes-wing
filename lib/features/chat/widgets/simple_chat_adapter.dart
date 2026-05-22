import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/channel/navivox_channel.dart';
import '../../../core/protocol/navivox_event.dart';
import '../../voice/services/text_to_speech_service.dart';
import '../../voice/services/voice_capture_service.dart';
import '../../voice/widgets/voice_morph_surface.dart';

class SimpleChatAdapter extends StatefulWidget {
  const SimpleChatAdapter({
    required this.messages,
    required this.onSend,
    this.voiceCaptureService,
    this.onVoice,
    this.voiceCaptureTimeout = const Duration(seconds: 30),
    this.voiceUnavailableReason,
    this.voiceRecoveryAction,
    this.onOpenVoiceSettings,
    this.textToSpeechService,
    this.assistantTypingLabel,
    this.forwardTargets = const [],
    this.onForward,
    super.key,
  });

  final List<NavivoxChatMessage> messages;
  final ValueChanged<String> onSend;
  final VoiceCaptureService? voiceCaptureService;
  final ValueChanged<VoiceCapture>? onVoice;
  final Duration voiceCaptureTimeout;
  final String? voiceUnavailableReason;
  final String? voiceRecoveryAction;
  final VoidCallback? onOpenVoiceSettings;
  final TextToSpeechService? textToSpeechService;
  final String? assistantTypingLabel;
  final List<NavivoxProfileContact> forwardTargets;
  final void Function(NavivoxChatMessage message, NavivoxProfileContact target)?
  onForward;

  @override
  State<SimpleChatAdapter> createState() => _SimpleChatAdapterState();
}

class _SimpleChatAdapterState extends State<SimpleChatAdapter> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _capturing = false;
  String? _captureError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  @override
  void didUpdateWidget(SimpleChatAdapter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length > oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: widget.messages.isEmpty && widget.assistantTypingLabel == null
              ? Center(
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
                        'Start a conversation',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount:
                      widget.messages.length +
                      (widget.assistantTypingLabel == null ? 0 : 1),
                  itemBuilder: (context, index) {
                    if (index == widget.messages.length) {
                      return _TypingIndicator(
                        label: widget.assistantTypingLabel!,
                      );
                    }
                    final msg = widget.messages[index];
                    final isUser = msg.author == NavivoxMessageAuthor.user;
                    final prev = index > 0 ? widget.messages[index - 1] : null;
                    final showTail = prev == null || prev.author != msg.author;
                    return _TelegramBubble(
                      message: msg,
                      isUser: isUser,
                      showTail: showTail,
                      forwardTargets: widget.forwardTargets,
                      onForward: widget.onForward,
                      textToSpeechService: widget.textToSpeechService,
                    );
                  },
                ),
        ),
        if (_captureError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              _captureError!,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
            ),
          ),
        SafeArea(
          top: false,
          child: _InputBar(
            controller: _controller,
            onSend: _send,
            voiceService: widget.voiceCaptureService,
            voiceUnavailableReason: widget.voiceUnavailableReason,
            voiceRecoveryAction: widget.voiceRecoveryAction,
            onOpenVoiceSettings: widget.onOpenVoiceSettings,
            capturing: _capturing,
            onToggleVoice: _toggleVoiceCapture,
          ),
        ),
      ],
    );
  }

  void _send(String text) {
    widget.onSend(text);
    _controller.clear();
  }

  Future<void> _toggleVoiceCapture() async {
    final service = widget.voiceCaptureService;
    if (service == null) return;

    if (_capturing) {
      setState(() => _capturing = false);
      return;
    }

    setState(() {
      _capturing = true;
      _captureError = null;
    });
    try {
      final capture = await service.capture(
        timeout: widget.voiceCaptureTimeout,
      );
      if (!mounted) return;
      widget.onVoice?.call(capture);
    } on VoiceCaptureTimeout {
      if (mounted) {
        setState(() => _captureError = 'Voice capture timed out.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _captureError = 'Voice capture failed: $e');
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
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

  Future<void> _showMessageActions(BuildContext context) {
    final text = _messageActionText(message);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              'Message actions',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (text.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    sheetContext,
                  ).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SelectableText(text),
              ),
            if (text.isNotEmpty) ...[
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy text'),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (!sheetContext.mounted) return;
                  Navigator.of(sheetContext).pop();
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    const SnackBar(content: Text('Message copied')),
                  );
                },
              ),
              if (textToSpeechService != null)
                ListTile(
                  leading: const Icon(Icons.volume_up),
                  title: const Text('Read aloud'),
                  onTap: () async {
                    await textToSpeechService!.speak(text);
                    if (!sheetContext.mounted) return;
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      const SnackBar(content: Text('Reading aloud')),
                    );
                  },
                ),
            ],
            if (forwardTargets.isNotEmpty && onForward != null) ...[
              const Divider(),
              const ListTile(
                leading: Icon(Icons.forward),
                title: Text('Forward to'),
              ),
              for (final target in forwardTargets)
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(target.displayName),
                  subtitle: Text(target.serverLabel),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onForward?.call(message, target);
                  },
                ),
            ],
            if (text.isNotEmpty && textToSpeechService == null)
              const ListTile(
                enabled: false,
                leading: Icon(Icons.volume_off),
                title: Text('Read aloud unavailable'),
                subtitle: Text('Device TTS is not connected.'),
              ),
          ],
        ),
      ),
    );
  }
}

String _messageActionText(NavivoxChatMessage message) {
  return switch (message.kind) {
    NavivoxMessageKind.text => message.text ?? '',
    NavivoxMessageKind.voice => message.voice?.transcript ?? '',
    NavivoxMessageKind.toolCall => [
      message.toolCall?.name,
      message.toolCall?.status,
      message.toolCall?.summary,
    ].whereType<String>().where((part) => part.isNotEmpty).join('\n'),
    NavivoxMessageKind.safetyWarning || NavivoxMessageKind.approvalRequest => [
      message.safetyNotice?.message,
      message.safetyNotice?.risk,
    ].whereType<String>().where((part) => part.isNotEmpty).join('\n'),
  };
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

class _InputBar extends StatefulWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
    this.voiceService,
    this.voiceUnavailableReason,
    this.voiceRecoveryAction,
    this.onOpenVoiceSettings,
    this.capturing = false,
    this.onToggleVoice,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final VoiceCaptureService? voiceService;
  final String? voiceUnavailableReason;
  final String? voiceRecoveryAction;
  final VoidCallback? onOpenVoiceSettings;
  final bool capturing;
  final VoidCallback? onToggleVoice;

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _showEmoji = false;

  static const _quickEmoji = ['😀', '👍', '🙏', '🔥', '✅', '👀'];

  String? _canonicalVoiceUnavailableReason(String? reason) {
    final trimmed = reason?.trim();
    if (trimmed == null || trimmed.isEmpty) return trimmed;
    if (trimmed.toLowerCase() == 'device stt unavailable') {
      return 'device STT unavailable';
    }
    return trimmed;
  }

  String _voiceSettingsSubtitle(String? reason) {
    return reason == 'device STT unavailable'
        ? 'Review continuous voice after enabling device speech recognition.'
        : reason == 'select a profile contact'
        ? 'Select a profile contact before reviewing continuous voice settings.'
        : 'Review continuous voice and trust settings';
  }

  void _showVoiceUnavailable(BuildContext context) {
    final reason = _canonicalVoiceUnavailableReason(
      widget.voiceUnavailableReason,
    );
    final helpText = reason == 'device STT unavailable'
        ? 'Install or enable device speech recognition, then reopen Navivox.'
        : 'Check microphone permissions and Settings.';
    final recoveryAction = widget.voiceRecoveryAction?.trim();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                'Voice unavailable',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.mic_off),
                title: Text(
                  reason?.isNotEmpty == true
                      ? reason!
                      : 'device STT unavailable',
                ),
                subtitle: Text(helpText),
              ),
              if (recoveryAction?.isNotEmpty == true)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.tips_and_updates_outlined),
                  title: const Text('Recovery action'),
                  subtitle: Text(recoveryAction!),
                ),
              if (widget.onOpenVoiceSettings != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.settings_voice_outlined),
                  title: const Text('Open voice settings'),
                  subtitle: Text(_voiceSettingsSubtitle(reason)),
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onOpenVoiceSettings?.call();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: const [
            Text('Share'),
            SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.upload_file),
              title: Text('Upload file'),
              subtitle: Text('Attach a local file when upload wiring lands.'),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined),
              title: Text('Photo or video'),
              subtitle: Text('Media picker placeholder.'),
            ),
            ListTile(
              leading: Icon(Icons.folder_open),
              title: Text('Workspace file'),
              subtitle: Text('Share a file from the active Gormes workspace.'),
            ),
          ],
        ),
      ),
    );
  }

  void _insertEmoji(String emoji) {
    final value = widget.controller.value;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;
    final text = value.text.replaceRange(start, end, emoji);
    final offset = start + emoji.length;
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unavailableReason = _canonicalVoiceUnavailableReason(
      widget.voiceUnavailableReason,
    );
    final unavailableTooltip = unavailableReason?.isNotEmpty == true
        ? 'Voice unavailable: $unavailableReason'
        : 'Voice unavailable';
    final voiceAvailable =
        widget.voiceService != null && unavailableReason?.isNotEmpty != true;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showEmoji)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickEmoji.length,
                separatorBuilder: (context, index) => const SizedBox(width: 4),
                itemBuilder: (context, index) {
                  final emoji = _quickEmoji[index];
                  return TextButton(
                    onPressed: () => _insertEmoji(emoji),
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  );
                },
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Emoji',
                onPressed: () => setState(() => _showEmoji = !_showEmoji),
                icon: Icon(
                  _showEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: 'Message Gormes',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: widget.onSend,
                ),
              ),
              IconButton(
                tooltip: 'Attach',
                onPressed: () => _showShareSheet(context),
                icon: const Icon(Icons.attach_file),
              ),
              if (voiceAvailable)
                IconButton.filledTonal(
                  onPressed: widget.onToggleVoice,
                  icon: Icon(widget.capturing ? Icons.stop : Icons.mic),
                  style: IconButton.styleFrom(
                    backgroundColor: widget.capturing
                        ? theme.colorScheme.errorContainer
                        : null,
                  ),
                )
              else
                IconButton.outlined(
                  tooltip: unavailableTooltip,
                  onPressed: () => _showVoiceUnavailable(context),
                  icon: const Icon(Icons.mic_off),
                ),
              const SizedBox(width: 4),
              IconButton.filled(
                onPressed: () => widget.onSend(widget.controller.text),
                icon: const Icon(Icons.send, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
