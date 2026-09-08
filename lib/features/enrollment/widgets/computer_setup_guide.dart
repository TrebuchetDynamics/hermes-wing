import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';

/// Local instructions only: advancing a step never asserts remote installation.
class ComputerSetupGuide extends StatefulWidget {
  const ComputerSetupGuide({super.key, required this.onPair});
  final VoidCallback onPair;

  @override
  State<ComputerSetupGuide> createState() => _ComputerSetupGuideState();
}

class _ComputerSetupGuideState extends State<ComputerSetupGuide> {
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
    final command = _existing
        ? '~/.local/bin/wing-link setup &&\n~/.local/bin/wing-link pair'
        : 'git clone --depth 1 https://github.com/TrebuchetDynamics/hermes-wing.git\n'
              'cd hermes-wing\n'
              './install-wing-link.sh &&\n'
              '~/.local/bin/wing-link pair';
    return Column(
      key: const ValueKey('hermes-enrollment-computer-guide'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.enrollComputerAction,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          s.enrollComputerInstallTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(s.enrollComputerRequirements),
        const SizedBox(height: 12),
        CheckboxListTile(
          key: const ValueKey('computer-wing-link-installed'),
          contentPadding: EdgeInsets.zero,
          title: Text(s.enrollComputerExisting),
          value: _existing,
          onChanged: (value) => setState(() => _existing = value ?? false),
        ),
        Text(
          _existing
              ? s.enrollComputerExistingHelp
              : s.enrollComputerInstallBody,
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              command,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
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
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('hermes-enrollment-computer-ready'),
          onPressed: widget.onPair,
          child: Text(s.enrollComputerReady),
        ),
      ],
    );
  }
}
