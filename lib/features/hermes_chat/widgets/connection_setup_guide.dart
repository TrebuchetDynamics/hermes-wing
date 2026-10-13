import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';

/// Preparation guidance has no credential, channel or host-management authority.
class ConnectionSetupGuide extends StatefulWidget {
  const ConnectionSetupGuide({super.key, this.browserOrigin});

  final String? browserOrigin;

  @override
  State<ConnectionSetupGuide> createState() => _ConnectionSetupGuideState();
}

class _ConnectionSetupGuideState extends State<ConnectionSetupGuide> {
  int _step = 0;
  bool _docsFailed = false;

  Future<void> _openDocs() async {
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
    if (mounted) setState(() => _docsFailed = !opened);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final steps = [
      (s.connectionGuidePrepare, s.connectionGuidePrepareBody),
      (s.connectionGuideAddress, s.connectionGuideAddressBody),
      (s.connectionGuideToken, s.connectionGuideTokenBody),
      if (widget.browserOrigin != null)
        (s.connectionGuideBrowser, s.connectionGuideBrowserBody),
      (s.connectionGuideVerify, s.connectionGuideVerifyBody),
    ];
    final index = _step.clamp(0, steps.length - 1);
    return ExpansionTile(
      key: const ValueKey('connection-setup-guide'),
      initiallyExpanded: true,
      tilePadding: EdgeInsets.zero,
      title: Text(s.connectionGuideTitle),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  steps[index].$1,
                  key: const ValueKey('connection-guide-step'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(steps[index].$2),
              if (index == 2) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: null,
                  child: Text(s.connectionGuideGenerateToken),
                ),
                Text(s.connectionGuideGenerateTokenBody),
              ],
              if (widget.browserOrigin != null && index == 3) ...[
                const SizedBox(height: 8),
                SelectableText(
                  s.connectionBrowserOrigin(widget.browserOrigin!),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    key: const ValueKey('connection-guide-back'),
                    onPressed: index == 0
                        ? null
                        : () => setState(() => _step = index - 1),
                    child: Text(s.connectionGuideBack),
                  ),
                  FilledButton.tonal(
                    key: const ValueKey('connection-guide-next'),
                    onPressed: index == steps.length - 1
                        ? null
                        : () => setState(() => _step = index + 1),
                    child: Text(
                      index == steps.length - 2
                          ? s.connectionGuideReady
                          : s.connectionGuideNext,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => unawaited(_openDocs()),
                    icon: const Icon(Icons.open_in_new),
                    label: Text(s.connectionGuideDocs),
                  ),
                ],
              ),
              if (_docsFailed)
                Semantics(
                  liveRegion: true,
                  child: Text(s.connectionGuideDocsFailed),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
