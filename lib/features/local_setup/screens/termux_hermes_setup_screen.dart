import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../router/routes/app_routes.dart';

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
  int _step = 0;
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
    final titles = [
      strings.termuxPrepareStep,
      strings.termuxInstallStep,
      strings.termuxPairStep,
    ];
    return PopScope<Object?>(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) setState(() => _step--);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(strings.termuxSetupTitle),
          leading: _step > 0
              ? BackButton(onPressed: () => setState(() => _step--))
              : null,
        ),
        body: SafeArea(
          child: FutureBuilder<TermuxBootstrapCommand?>(
            future: _command,
            builder: (context, snapshot) {
              final loading = snapshot.connectionState != ConnectionState.done;
              final command = snapshot.data;
              return SingleChildScrollView(
                key: ValueKey(_step),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          liveRegion: true,
                          child: Text(strings.enrollStepProgress(_step + 1, 3)),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (_step + 1) / 3,
                          semanticsLabel: strings.enrollStepProgress(
                            _step + 1,
                            3,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          titles[_step],
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        if (_step == 0) ...[
                          Text(strings.termuxSetupBody),
                          const SizedBox(height: 16),
                          Text(strings.termuxPrerequisites),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            key: const ValueKey('termux-install'),
                            onPressed: _actionPending
                                ? null
                                : _openTermuxInstallGuide,
                            icon: _openingGuide
                                ? _spinner(strings.termuxOpeningInstallGuide)
                                : const Icon(Icons.open_in_new),
                            label: Text(strings.termuxInstallAction),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            key: const ValueKey('termux-ready'),
                            onPressed: _actionPending
                                ? null
                                : () => setState(() => _step = 1),
                            child: Text(strings.termuxReadyAction),
                          ),
                        ] else if (_step == 1) ...[
                          Text(strings.termuxRunStep),
                          const SizedBox(height: 16),
                          if (loading)
                            Semantics(
                              key: const ValueKey('termux-command-loading'),
                              liveRegion: true,
                              child: Row(
                                children: [
                                  _spinner(strings.termuxPreparingCommand),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(strings.termuxPreparingCommand),
                                  ),
                                ],
                              ),
                            )
                          else if (command == null)
                            Semantics(
                              liveRegion: true,
                              child: Text(strings.termuxMetadataUnavailable),
                            )
                          else
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
                          const SizedBox(height: 16),
                          FilledButton.tonalIcon(
                            key: const ValueKey('termux-copy-command'),
                            style: const ButtonStyle(
                              minimumSize: WidgetStatePropertyAll(
                                Size.fromHeight(48),
                              ),
                            ),
                            onPressed:
                                loading || command == null || _actionPending
                                ? null
                                : () => _copy(command),
                            icon: _copying
                                ? _spinner(strings.termuxCopyingCommand)
                                : const Icon(Icons.copy_outlined),
                            label: Text(strings.termuxCopyAction),
                          ),
                          const SizedBox(height: 16),
                          Text(strings.termuxAdoptionHelp),
                          const SizedBox(height: 12),
                          FilledButton(
                            key: const ValueKey('termux-setup-finished'),
                            onPressed: () => setState(() => _step = 2),
                            child: Text(strings.termuxSetupFinished),
                          ),
                        ] else ...[
                          Text(strings.termuxReturnStep),
                          const SizedBox(height: 16),
                          Text(strings.termuxPairRecovery),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            key: const ValueKey('termux-open-pairing'),
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop(true);
                              } else {
                                context.go('${AppRoutes.enroll}?step=pair');
                              }
                            },
                            icon: const Icon(Icons.link),
                            label: Text(strings.enrollComputerReady),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _step = 1),
                            child: Text(strings.termuxReturnToSetup),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Text(
                          strings.termuxTierTwoNotice,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _spinner(String label) => SizedBox.square(
    dimension: 18,
    child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: label),
  );
}
