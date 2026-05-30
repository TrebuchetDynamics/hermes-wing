import 'package:flutter/material.dart';

import '../../../voice/services/capture/voice_capture_service.dart';
import '../../voice/controllers/transcript_voice_capture_flow.dart';
import 'transcript_composer.dart';

class TranscriptInputPanel extends StatefulWidget {
  const TranscriptInputPanel({
    required this.controller,
    required this.onSend,
    this.voiceCaptureService,
    this.onVoice,
    this.onVoiceCaptureStarted,
    this.onVoiceCaptureFailed,
    this.voiceCaptureTimeout = const Duration(seconds: 30),
    this.voiceUnavailableReason,
    this.voiceRecoveryAction,
    this.onOpenVoiceSettings,
    this.onUploadFile,
    this.onPickPhotoOrVideo,
    this.onOpenWorkspace,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final VoiceCaptureService? voiceCaptureService;
  final ValueChanged<VoiceCapture>? onVoice;
  final VoidCallback? onVoiceCaptureStarted;
  final ValueChanged<Object>? onVoiceCaptureFailed;
  final Duration voiceCaptureTimeout;
  final String? voiceUnavailableReason;
  final String? voiceRecoveryAction;
  final VoidCallback? onOpenVoiceSettings;
  final VoidCallback? onUploadFile;
  final VoidCallback? onPickPhotoOrVideo;
  final VoidCallback? onOpenWorkspace;

  @override
  State<TranscriptInputPanel> createState() => _TranscriptInputPanelState();
}

class _TranscriptInputPanelState extends State<TranscriptInputPanel> {
  final _voiceCaptureFlow = const TranscriptVoiceCaptureFlow();
  bool _capturing = false;
  String? _captureError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
          child: TranscriptComposer(
            controller: widget.controller,
            onSend: _send,
            voiceCaptureAvailable: widget.voiceCaptureService != null,
            voiceUnavailableReason: widget.voiceUnavailableReason,
            voiceRecoveryAction: widget.voiceRecoveryAction,
            onOpenVoiceSettings: widget.onOpenVoiceSettings,
            onUploadFile: widget.onUploadFile,
            onPickPhotoOrVideo: widget.onPickPhotoOrVideo,
            onOpenWorkspace: widget.onOpenWorkspace,
            capturing: _capturing,
            onToggleVoice: _toggleVoiceCapture,
          ),
        ),
      ],
    );
  }

  void _send(String text) {
    widget.onSend(text);
    widget.controller.clear();
  }

  Future<void> _toggleVoiceCapture() async {
    if (widget.voiceCaptureService == null) return;

    if (_capturing) {
      setState(() => _capturing = false);
      return;
    }

    setState(() {
      _capturing = true;
      _captureError = null;
    });
    final outcome = await _voiceCaptureFlow.capture(
      service: widget.voiceCaptureService,
      timeout: widget.voiceCaptureTimeout,
      onStarted: widget.onVoiceCaptureStarted,
    );
    try {
      switch (outcome.status) {
        case TranscriptVoiceCaptureStatus.unavailable:
          return;
        case TranscriptVoiceCaptureStatus.captured:
          if (!mounted) return;
          final capture = outcome.capture;
          if (capture != null) widget.onVoice?.call(capture);
          break;
        case TranscriptVoiceCaptureStatus.failed:
          if (mounted) {
            setState(() => _captureError = outcome.errorMessage);
          }
          final error = outcome.error;
          if (error != null) widget.onVoiceCaptureFailed?.call(error);
          break;
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }
}
