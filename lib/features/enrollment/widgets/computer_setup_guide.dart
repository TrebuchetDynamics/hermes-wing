import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';

/// Local instructions only: advancing a step never asserts remote installation.
class ComputerSetupGuide extends StatefulWidget {
  const ComputerSetupGuide({
    super.key,
    required this.onPair,
    required this.step,
    required this.onStepChanged,
  });
  final VoidCallback onPair;
  final int step;
  final ValueChanged<int> onStepChanged;

  @override
  State<ComputerSetupGuide> createState() => _ComputerSetupGuideState();
}

class _ComputerSetupGuideState extends State<ComputerSetupGuide> {
  int get _step => widget.step;
  bool _existing = false;
  bool _copying = false;

  Future<void> _copy(String command) async {
    if (_copying) return;
    setState(() => _copying = true);
    final strings = AppLocalizations.of(context);
    try {
      await Clipboard.setData(ClipboardData(text: command));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.enrollCommandCopied)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.termuxCopyFailedMessage)),
        );
      }
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final titles = [
      s.enrollComputerPrerequisites,
      s.enrollComputerInstallTitle,
      s.enrollComputerModelTitle,
      s.enrollComputerPairTitle,
    ];
    final command = switch (_step) {
      1 =>
        _existing
            ? '~/.local/bin/wing-link inspect\n~/.local/bin/wing-link setup'
            : 'git clone --depth 1 https://github.com/TrebuchetDynamics/hermes-wing.git\ncd hermes-wing\n./install-wing-link.sh',
      2 => 'hermes setup',
      3 => '~/.local/bin/wing-link pair',
      _ => null,
    };
    return Column(
      key: const ValueKey('hermes-enrollment-computer-guide'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.enrollComputerAction,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          child: Text(s.enrollStepProgress(_step + 1, titles.length)),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (_step + 1) / titles.length,
          semanticsLabel: s.enrollStepProgress(_step + 1, titles.length),
        ),
        const SizedBox(height: 24),
        Text(titles[_step], style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Text(switch (_step) {
          0 => s.enrollComputerRequirements,
          1 =>
            _existing
                ? s.enrollComputerExistingHelp
                : s.enrollComputerInstallBody,
          2 => s.enrollComputerModelBody,
          _ => s.enrollComputerPairBody,
        }),
        if (_step == 0) ...[
          const SizedBox(height: 16),
          Text(s.enrollComputerPrerequisitesHelp),
        ],
        if (_step == 1)
          CheckboxListTile(
            key: const ValueKey('computer-wing-link-installed'),
            contentPadding: EdgeInsets.zero,
            title: Text(s.enrollComputerExisting),
            value: _existing,
            onChanged: (value) => setState(() => _existing = value ?? false),
          ),
        if (command != null) ...[
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                command,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('computer-copy-command'),
              onPressed: _copying ? null : () => _copy(command),
              icon: const Icon(Icons.copy_outlined),
              label: Text(s.enrollCopyCommand),
            ),
          ),
          Text(
            s.enrollExternalStepNotice,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          key: ValueKey(
            _step == 3
                ? 'hermes-enrollment-computer-ready'
                : 'computer-next-step',
          ),
          onPressed: _step == 3
              ? widget.onPair
              : () => widget.onStepChanged(_step + 1),
          child: Text(switch (_step) {
            0 => s.enrollComputerPrerequisitesReady,
            1 => s.enrollHostSetupFinished,
            2 => s.enrollModelSetupFinished,
            _ => s.enrollComputerReady,
          }),
        ),
        if (_step > 0)
          TextButton(
            key: const ValueKey('computer-previous-step'),
            onPressed: () => widget.onStepChanged(_step - 1),
            child: Text(s.enrollPreviousStep),
          ),
      ],
    );
  }
}
