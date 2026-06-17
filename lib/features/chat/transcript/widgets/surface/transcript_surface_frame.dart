import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/channel/navivox_channel.dart';
import '../../../../../core/protocol/navivox_event.dart';
import '../../../../../shared/voice/text_to_speech_service.dart';
import '../../../../../shared/voice/voice_capture_service.dart';
import '../transcript_input_panel.dart';
import '../transcript_thread.dart';

class TranscriptSurfaceFrame extends StatefulWidget {
  const TranscriptSurfaceFrame({
    required this.messages,
    required this.onSend,
    this.voiceCaptureService,
    this.onVoice,
    this.onVoiceCaptureStarted,
    this.onVoiceCaptureFailed,
    this.reArmCapture,
    this.voiceCaptureTimeout = const Duration(seconds: 30),
    this.voiceUnavailableReason,
    this.voiceRecoveryAction,
    this.onOpenVoiceSettings,
    this.onUploadFile,
    this.onPickPhotoOrVideo,
    this.onOpenWorkspace,
    this.textToSpeechService,
    this.assistantTypingLabel,
    this.onCancelActiveTurn,
    this.forwardTargets = const [],
    this.onForward,
    this.onInspectRunRecord,
    super.key,
  });

  final List<NavivoxChatMessage> messages;
  final ValueChanged<String> onSend;
  final VoiceCaptureService? voiceCaptureService;
  final ValueChanged<VoiceCapture>? onVoice;
  final VoidCallback? onVoiceCaptureStarted;
  final ValueChanged<Object>? onVoiceCaptureFailed;
  final Listenable? reArmCapture;
  final Duration voiceCaptureTimeout;
  final String? voiceUnavailableReason;
  final String? voiceRecoveryAction;
  final VoidCallback? onOpenVoiceSettings;
  final VoidCallback? onUploadFile;
  final VoidCallback? onPickPhotoOrVideo;
  final VoidCallback? onOpenWorkspace;
  final TextToSpeechService? textToSpeechService;
  final String? assistantTypingLabel;
  final VoidCallback? onCancelActiveTurn;
  final List<NavivoxProfileContact> forwardTargets;
  final void Function(NavivoxChatMessage message, NavivoxProfileContact target)?
  onForward;
  final FutureOr<void> Function(NavivoxChatMessage message)? onInspectRunRecord;

  @override
  State<TranscriptSurfaceFrame> createState() => _TranscriptSurfaceFrameState();
}

class _TranscriptSurfaceFrameState extends State<TranscriptSurfaceFrame> {
  static const _jumpToBottomThreshold = 80.0;

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _showJumpToBottom = false;
  int _newMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  @override
  void didUpdateWidget(TranscriptSurfaceFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    final appendedCount = widget.messages.length - oldWidget.messages.length;
    if (appendedCount > 0) {
      if (_isNearBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
      } else {
        _newMessageCount += appendedCount;
        _showJumpToBottom = true;
      }
    } else if (appendedCount < 0) {
      _newMessageCount = 0;
      _showJumpToBottom = false;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return true;
    return _distanceFromBottom <= _jumpToBottomThreshold;
  }

  double get _distanceFromBottom =>
      _scrollController.position.maxScrollExtent -
      _scrollController.position.pixels;

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final shouldShow = !_isNearBottom;
    final shouldResetNewMessages = _isNearBottom && _newMessageCount > 0;
    if (shouldShow == _showJumpToBottom && !shouldResetNewMessages) return;
    setState(() {
      _showJumpToBottom = shouldShow;
      if (_isNearBottom) _newMessageCount = 0;
    });
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      if (_showJumpToBottom || _newMessageCount > 0) {
        setState(() {
          _showJumpToBottom = false;
          _newMessageCount = 0;
        });
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: TranscriptThread(
                  messages: widget.messages,
                  scrollController: _scrollController,
                  assistantTypingLabel: widget.assistantTypingLabel,
                  forwardTargets: widget.forwardTargets,
                  onForward: widget.onForward,
                  onInspectRunRecord: widget.onInspectRunRecord,
                  textToSpeechService: widget.textToSpeechService,
                  onCancelActiveTurn: widget.onCancelActiveTurn,
                ),
              ),
              if (_showJumpToBottom)
                Positioned(
                  right: 16,
                  bottom: 12,
                  child: FloatingActionButton.small(
                    key: const ValueKey('transcript-jump-to-bottom'),
                    tooltip: 'Jump to latest message',
                    onPressed: _scrollToEnd,
                    child: _JumpToBottomIcon(newMessageCount: _newMessageCount),
                  ),
                ),
            ],
          ),
        ),
        TranscriptInputPanel(
          controller: _controller,
          onSend: widget.onSend,
          voiceCaptureService: widget.voiceCaptureService,
          onVoice: widget.onVoice,
          onVoiceCaptureStarted: widget.onVoiceCaptureStarted,
          onVoiceCaptureFailed: widget.onVoiceCaptureFailed,
          reArmCapture: widget.reArmCapture,
          voiceCaptureTimeout: widget.voiceCaptureTimeout,
          voiceUnavailableReason: widget.voiceUnavailableReason,
          voiceRecoveryAction: widget.voiceRecoveryAction,
          onOpenVoiceSettings: widget.onOpenVoiceSettings,
          onUploadFile: widget.onUploadFile,
          onPickPhotoOrVideo: widget.onPickPhotoOrVideo,
          onOpenWorkspace: widget.onOpenWorkspace,
        ),
      ],
    );
  }
}

class _JumpToBottomIcon extends StatelessWidget {
  const _JumpToBottomIcon({required this.newMessageCount});

  final int newMessageCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeLabel = newMessageCount > 99 ? '99+' : '$newMessageCount';
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        const Icon(Icons.keyboard_arrow_down),
        if (newMessageCount > 0)
          Positioned(
            key: const ValueKey('transcript-jump-to-bottom-badge'),
            right: -12,
            top: -12,
            child: Semantics(
              label: '$newMessageCount new messages',
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onError,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
