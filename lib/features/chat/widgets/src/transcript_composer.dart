part of '../transcript_surface.dart';

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
