import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/channel/navivox_channel.dart';
import '../../../core/protocol/navivox_event.dart';
import '../../voice/services/text_to_speech_service.dart';
import '../../voice/services/voice_capture_service.dart';
import '../../voice/widgets/voice_morph_surface.dart';

part 'src/transcript_message_actions.dart';
part 'src/transcript_composer.dart';
part 'src/transcript_message_bodies.dart';
part 'src/transcript_bubble.dart';

class TranscriptSurface extends StatefulWidget {
  const TranscriptSurface({
    required this.messages,
    required this.onSend,
    this.voiceCaptureService,
    this.onVoice,
    this.onVoiceCaptureStarted,
    this.onVoiceCaptureFailed,
    this.voiceCaptureTimeout = const Duration(seconds: 30),
    this.voiceUnavailableReason,
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
  final VoidCallback? onVoiceCaptureStarted;
  final ValueChanged<Object>? onVoiceCaptureFailed;
  final Duration voiceCaptureTimeout;
  final String? voiceUnavailableReason;
  final TextToSpeechService? textToSpeechService;
  final String? assistantTypingLabel;
  final List<NavivoxProfileContact> forwardTargets;
  final void Function(NavivoxChatMessage message, NavivoxProfileContact target)?
  onForward;

  @override
  State<TranscriptSurface> createState() => _TranscriptSurfaceState();
}

class _TranscriptSurfaceState extends State<TranscriptSurface> {
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
  void didUpdateWidget(TranscriptSurface oldWidget) {
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
    widget.onVoiceCaptureStarted?.call();
    try {
      final capture = await service.capture(
        timeout: widget.voiceCaptureTimeout,
      );
      if (!mounted) return;
      widget.onVoice?.call(capture);
    } on VoiceCaptureTimeout catch (e) {
      if (mounted) {
        setState(() => _captureError = 'Voice capture timed out.');
      }
      widget.onVoiceCaptureFailed?.call(e);
    } catch (e) {
      if (mounted) {
        setState(() => _captureError = 'Voice capture failed: $e');
      }
      widget.onVoiceCaptureFailed?.call(e);
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }
}
