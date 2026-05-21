part of '../transcript_surface.dart';

Future<void> _showTranscriptMessageActions({
  required BuildContext context,
  required NavivoxChatMessage message,
  required List<NavivoxProfileContact> forwardTargets,
  required void Function(
    NavivoxChatMessage message,
    NavivoxProfileContact target,
  )?
  onForward,
  required TextToSpeechService? textToSpeechService,
  required VoidCallback? onCancelActiveTurn,
}) {
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
                color: Theme.of(sheetContext).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SelectableText(text),
            ),
          if (onCancelActiveTurn != null)
            ListTile(
              leading: const Icon(Icons.pause_circle_outline),
              title: const Text('Pause stream'),
              subtitle: const Text('Stop the current assistant response.'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onCancelActiveTurn();
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                  const SnackBar(content: Text('Stream pause requested')),
                );
              },
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
                  await textToSpeechService.speak(text);
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
                  onForward(message, target);
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
