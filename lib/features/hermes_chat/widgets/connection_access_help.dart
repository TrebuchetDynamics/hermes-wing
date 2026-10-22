import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';

/// No controller or endpoint input: only public instructions can leave this UI.
class ConnectionAccessHelp extends StatefulWidget {
  const ConnectionAccessHelp({super.key});

  @override
  State<ConnectionAccessHelp> createState() => _ConnectionAccessHelpState();
}

class _ConnectionAccessHelpState extends State<ConnectionAccessHelp> {
  bool _pending = false;
  String? _notice;

  Future<void> _copy() async {
    if (_pending) return;
    final s = AppLocalizations.of(context);
    setState(() => _pending = true);
    String notice;
    try {
      await Clipboard.setData(ClipboardData(text: s.connectionAccessRequest));
      notice = s.connectionAccessCopied;
    } on Object {
      notice = s.connectionInformationCopyFailed;
    }
    if (!mounted) return;
    setState(() {
      _pending = false;
      _notice = notice;
    });
  }

  Future<void> _docs() async {
    if (_pending) return;
    final s = AppLocalizations.of(context);
    setState(() => _pending = true);
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(
          'https://hermes-agent.nousresearch.com/docs/user-guide/features/api-server',
        ),
        mode: LaunchMode.externalApplication,
      );
    } on Object {
      opened = false;
    }
    if (!mounted) return;
    setState(() {
      _pending = false;
      _notice = opened ? null : s.connectionGuideDocsFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.connectionAccessBody),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          key: const ValueKey('connection-access-copy'),
          onPressed: _pending ? null : _copy,
          icon: const Icon(Icons.copy_outlined),
          label: Text(s.connectionAccessCopy),
        ),
        TextButton.icon(
          onPressed: _pending ? null : _docs,
          icon: const Icon(Icons.open_in_new),
          label: Text(s.connectionGuideDocs),
        ),
        ExpansionTile(
          key: const ValueKey('connection-access-request'),
          tilePadding: EdgeInsets.zero,
          title: Text(s.connectionAccessPreview),
          children: [SelectableText(s.connectionAccessRequest)],
        ),
        if (_notice != null)
          Semantics(
            liveRegion: true,
            child: Text(
              _notice!,
              key: const ValueKey('connection-access-notice'),
            ),
          ),
      ],
    );
  }
}

Future<void> showConnectionAccessHelp(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(AppLocalizations.of(context).connectionAccessTitle),
    content: const SizedBox(
      width: 560,
      child: SingleChildScrollView(child: ConnectionAccessHelp()),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(AppLocalizations.of(context).connectionInformationClose),
      ),
    ],
  ),
);
