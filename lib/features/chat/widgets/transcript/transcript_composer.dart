import 'package:flutter/material.dart';

import '../../presentation/transcript/transcript_composer_presentation.dart';

class TranscriptComposer extends StatefulWidget {
  const TranscriptComposer({
    required this.controller,
    required this.onSend,
    this.voiceCaptureAvailable = false,
    this.voiceUnavailableReason,
    this.voiceRecoveryAction,
    this.onOpenVoiceSettings,
    this.onUploadFile,
    this.onPickPhotoOrVideo,
    this.onOpenWorkspace,
    this.capturing = false,
    this.onToggleVoice,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final bool voiceCaptureAvailable;
  final String? voiceUnavailableReason;
  final String? voiceRecoveryAction;
  final VoidCallback? onOpenVoiceSettings;
  final VoidCallback? onUploadFile;
  final VoidCallback? onPickPhotoOrVideo;
  final VoidCallback? onOpenWorkspace;
  final bool capturing;
  final VoidCallback? onToggleVoice;

  @override
  State<TranscriptComposer> createState() => _TranscriptComposerState();
}

class _TranscriptComposerState extends State<TranscriptComposer> {
  bool _showEmoji = false;

  TranscriptComposerPresentation _presentation() {
    return TranscriptComposerPresentation.fromState(
      voiceCaptureAvailable: widget.voiceCaptureAvailable,
      voiceUnavailableReason: widget.voiceUnavailableReason,
      voiceRecoveryAction: widget.voiceRecoveryAction,
      canOpenVoiceSettings: widget.onOpenVoiceSettings != null,
      capturing: widget.capturing,
      emojiOpen: _showEmoji,
    );
  }

  void _showVoiceUnavailable(BuildContext context) {
    final presentation = _presentation();
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
                presentation.voiceSheetTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final row in presentation.voiceSheetRows)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_voiceSheetIcon(row.kind)),
                  title: Text(row.title),
                  subtitle: Text(row.subtitle),
                  onTap: _voiceSheetTap(context, row.actionKind),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareSheet(BuildContext context) {
    final parentContext = context;
    final presentation = _presentation();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              presentation.shareTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final option in presentation.shareOptions)
              ListTile(
                leading: Icon(_shareIcon(option.kind)),
                title: Text(option.title),
                subtitle: Text(option.subtitle),
                onTap: () => _handleShareOption(
                  sheetContext: context,
                  parentContext: parentContext,
                  kind: option.kind,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleShareOption({
    required BuildContext sheetContext,
    required BuildContext parentContext,
    required TranscriptComposerShareOptionKind kind,
  }) {
    Navigator.of(sheetContext).pop();
    switch (kind) {
      case TranscriptComposerShareOptionKind.uploadFile:
        final callback = widget.onUploadFile;
        if (callback != null) {
          callback();
          return;
        }
        _showDeferredShareUnavailable(
          parentContext,
          title: 'File upload unavailable',
          message:
              'Gormes has not advertised a Navivox upload endpoint yet. Use text or workspace references for now.',
        );
      case TranscriptComposerShareOptionKind.photoOrVideo:
        final callback = widget.onPickPhotoOrVideo;
        if (callback != null) {
          callback();
          return;
        }
        _showDeferredShareUnavailable(
          parentContext,
          title: 'Photo upload unavailable',
          message:
              'Photo and video picking is ready to plug into the upload endpoint once Gormes enables uploads.',
        );
      case TranscriptComposerShareOptionKind.workspaceFile:
        final callback = widget.onOpenWorkspace;
        if (callback != null) {
          callback();
          return;
        }
        _showDeferredShareUnavailable(
          parentContext,
          title: 'Workspace browser unavailable',
          message:
              'Select a profile contact with workspace roots before browsing workspace files.',
        );
    }
  }

  void _showDeferredShareUnavailable(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline),
                  title: Text(title),
                  subtitle: Text(message),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  IconData _shareIcon(TranscriptComposerShareOptionKind kind) {
    return switch (kind) {
      TranscriptComposerShareOptionKind.uploadFile => Icons.upload_file,
      TranscriptComposerShareOptionKind.photoOrVideo =>
        Icons.photo_library_outlined,
      TranscriptComposerShareOptionKind.workspaceFile => Icons.folder_open,
    };
  }

  IconData _voiceSheetIcon(TranscriptComposerVoiceSheetRowKind kind) {
    return switch (kind) {
      TranscriptComposerVoiceSheetRowKind.status => Icons.mic_off,
      TranscriptComposerVoiceSheetRowKind.recoveryAction =>
        Icons.tips_and_updates_outlined,
      TranscriptComposerVoiceSheetRowKind.openVoiceSettings =>
        Icons.settings_voice_outlined,
    };
  }

  VoidCallback? _voiceSheetTap(
    BuildContext context,
    TranscriptComposerVoiceSheetActionKind? actionKind,
  ) {
    return switch (actionKind) {
      TranscriptComposerVoiceSheetActionKind.openVoiceSettings => () {
        Navigator.of(context).pop();
        widget.onOpenVoiceSettings?.call();
      },
      null => null,
    };
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
    final presentation = _presentation();
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
          if (presentation.showEmoji)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: presentation.quickEmoji.length,
                separatorBuilder: (context, index) => const SizedBox(width: 4),
                itemBuilder: (context, index) {
                  final emoji = presentation.quickEmoji[index];
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
                tooltip: presentation.emojiTooltip,
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
                    hintText: presentation.messageHint,
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
                tooltip: presentation.attachTooltip,
                onPressed: () => _showShareSheet(context),
                icon: const Icon(Icons.attach_file),
              ),
              if (presentation.voiceAvailable)
                IconButton.filledTonal(
                  onPressed: widget.onToggleVoice,
                  icon: Icon(
                    presentation.voiceButtonState ==
                            TranscriptComposerVoiceButtonState.stop
                        ? Icons.stop
                        : Icons.mic,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        presentation.voiceButtonState ==
                            TranscriptComposerVoiceButtonState.stop
                        ? theme.colorScheme.errorContainer
                        : null,
                  ),
                )
              else
                IconButton.outlined(
                  tooltip: presentation.voiceTooltip,
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
