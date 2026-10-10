import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';

Future<void> showConnectionInformationHelp(BuildContext context) =>
    showDialog<void>(
      context: context,
      builder: (_) => const ConnectionInformationHelpDialog(),
    );

/// Deliberately has no form/controller input. Only fixed public localized
/// instructions can cross the clipboard boundary.
class ConnectionInformationHelpDialog extends StatefulWidget {
  const ConnectionInformationHelpDialog({super.key});

  @override
  State<ConnectionInformationHelpDialog> createState() =>
      _ConnectionInformationHelpDialogState();
}

class _ConnectionInformationHelpDialogState
    extends State<ConnectionInformationHelpDialog> {
  bool _copying = false;
  bool? _copied;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    if (_copying) return;
    final instructions = AppLocalizations.of(
      context,
    ).connectionInformationHelpText;
    setState(() => _copying = true);
    var copied = false;
    try {
      await Clipboard.setData(ClipboardData(text: instructions));
      copied = true;
    } on Object {
      copied = false;
    }
    if (!mounted) return;
    setState(() {
      _copying = false;
      _copied = copied;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(s.connectionInformationHelpTitle),
      content: SizedBox(
        width: 560,
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SelectableText(
                  s.connectionInformationHelpText,
                  key: const ValueKey('connection-information-help-text'),
                ),
                if (_copied != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _copied!
                          ? s.connectionInformationCopied
                          : s.connectionInformationCopyFailed,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('connection-information-close'),
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.connectionInformationClose),
        ),
        OutlinedButton.icon(
          key: const ValueKey('connection-information-copy'),
          onPressed: _copying ? null : _copy,
          icon: const Icon(Icons.copy_outlined),
          label: Text(s.connectionInformationCopy),
        ),
      ],
    );
  }
}
