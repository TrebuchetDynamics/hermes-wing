import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../models/termux_bootstrap_command.dart';

class TermuxHermesSetupScreen extends StatefulWidget {
  const TermuxHermesSetupScreen({super.key});

  @override
  State<TermuxHermesSetupScreen> createState() =>
      _TermuxHermesSetupScreenState();
}

class _TermuxHermesSetupScreenState extends State<TermuxHermesSetupScreen> {
  static final _termuxInstallUri = Uri.parse(
    'https://github.com/termux/termux-app#installation',
  );

  Future<TermuxBootstrapCommand?>? _command;
  bool _copying = false;
  bool _openingGuide = false;

  bool get _actionPending => _copying || _openingGuide;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _command ??= _loadCommand();
  }

  Future<TermuxBootstrapCommand?> _loadCommand() async {
    try {
      final source = await DefaultAssetBundle.of(
        context,
      ).loadString('assets/config/termux_bootstrap.json');
      final json = jsonDecode(source);
      if (json is! Map<String, Object?>) return null;
      return TermuxBootstrapCommand.fromJson(json);
    } on Object {
      return null;
    }
  }

  Future<void> _copy(TermuxBootstrapCommand command) async {
    if (_actionPending) return;
    setState(() => _copying = true);
    try {
      await Clipboard.setData(ClipboardData(text: command.command));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).termuxCopiedMessage),
        ),
      );
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).termuxCopyFailedMessage),
        ),
      );
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  Future<void> _openTermuxInstallGuide() async {
    if (_actionPending) return;
    setState(() => _openingGuide = true);
    var opened = false;
    try {
      opened = await launchUrl(
        _termuxInstallUri,
        mode: LaunchMode.externalApplication,
      );
    } on Object {
      opened = false;
    } finally {
      if (mounted) setState(() => _openingGuide = false);
    }
    if (opened || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).termuxInstallGuideFailedMessage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.termuxSetupTitle)),
      body: SafeArea(
        child: FutureBuilder<TermuxBootstrapCommand?>(
          future: _command,
          builder: (context, snapshot) {
            final loading = snapshot.connectionState != ConnectionState.done;
            final command = snapshot.data;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                Text(strings.termuxSetupBody),
                const SizedBox(height: 24),
                _SetupStep(
                  number: 1,
                  child: FilledButton.icon(
                    key: const ValueKey('termux-install'),
                    style: const ButtonStyle(
                      minimumSize: WidgetStatePropertyAll(Size.fromHeight(48)),
                    ),
                    onPressed: _actionPending ? null : _openTermuxInstallGuide,
                    icon: _openingGuide
                        ? SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              semanticsLabel: strings.termuxOpeningInstallGuide,
                            ),
                          )
                        : const Icon(Icons.open_in_new),
                    label: Text(strings.termuxInstallAction),
                  ),
                ),
                const SizedBox(height: 16),
                _SetupStep(
                  number: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.tonalIcon(
                        key: const ValueKey('termux-copy-command'),
                        style: const ButtonStyle(
                          minimumSize: WidgetStatePropertyAll(
                            Size.fromHeight(48),
                          ),
                        ),
                        onPressed: loading || command == null || _actionPending
                            ? null
                            : () => _copy(command),
                        icon: _copying
                            ? SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  semanticsLabel: strings.termuxCopyingCommand,
                                ),
                              )
                            : const Icon(Icons.copy_outlined),
                        label: Text(strings.termuxCopyAction),
                      ),
                      if (loading) ...[
                        const SizedBox(height: 12),
                        Semantics(
                          key: const ValueKey('termux-command-loading'),
                          liveRegion: true,
                          label: strings.termuxPreparingCommand,
                          excludeSemantics: true,
                          child: Row(
                            children: [
                              const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(strings.termuxPreparingCommand),
                              ),
                            ],
                          ),
                        ),
                      ] else if (command != null) ...[
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SelectableText(
                                command.command,
                                maxLines: 1,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontFamily: 'monospace'),
                              ),
                            ),
                          ),
                        ),
                      ] else if (!loading) ...[
                        const SizedBox(height: 8),
                        Semantics(
                          liveRegion: true,
                          child: Text(strings.termuxMetadataUnavailable),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SetupStep(number: 3, child: Text(strings.termuxRunStep)),
                const SizedBox(height: 16),
                _SetupStep(number: 4, child: Text(strings.termuxReturnStep)),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline),
                        const SizedBox(width: 12),
                        Expanded(child: Text(strings.termuxTierTwoNotice)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({required this.number, required this.child});

  final int number;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CircleAvatar(radius: 16, child: Text('$number')),
      const SizedBox(width: 12),
      Expanded(child: child),
    ],
  );
}
