part of '../transcript_surface.dart';

class _InputBar extends StatefulWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
    this.voiceService,
    this.voiceUnavailableReason,
    this.capturing = false,
    this.onToggleVoice,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final VoiceCaptureService? voiceService;
  final String? voiceUnavailableReason;
  final bool capturing;
  final VoidCallback? onToggleVoice;

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _showEmoji = false;

  static const _quickEmoji = ['😀', '👍', '🙏', '🔥', '✅', '👀'];

  void _showVoiceUnavailable(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  widget.voiceUnavailableReason ?? 'device STT unavailable',
                ),
                subtitle: const Text(
                  'Check microphone permissions and Settings.',
                ),
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
    final unavailableReason = widget.voiceUnavailableReason?.trim();
    final unavailableTooltip = unavailableReason?.isNotEmpty == true
        ? 'Voice unavailable: $unavailableReason'
        : 'Voice unavailable';
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
              if (widget.voiceService != null)
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
