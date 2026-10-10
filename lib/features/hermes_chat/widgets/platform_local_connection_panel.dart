import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/hermes/local_discovery/local_hermes_home_discovery.dart';
import '../../../l10n/app_localizations.dart';

final platformLocalHomeDiscoveryProvider = Provider<LocalHermesHomeDiscovery>(
  (_) => LocalHermesHomeDiscovery(),
);
final platformLocalDirectoryPickerProvider =
    Provider<Future<String?> Function()>(
      (_) =>
          () => getDirectoryPath(),
    );
final platformLocalDocumentationLauncherProvider =
    Provider<Future<bool> Function(Uri)>(
      (_) =>
          (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
    );

/// Local preparation never owns a channel, credential, process or saved path.
/// The supplied form retains the existing direct connection/save/error owner.
class PlatformLocalConnectionPanel extends ConsumerStatefulWidget {
  const PlatformLocalConnectionPanel({
    super.key,
    required this.enabled,
    required this.child,
    this.busy = false,
  });

  final bool enabled;
  final bool busy;
  final Widget child;

  @override
  ConsumerState<PlatformLocalConnectionPanel> createState() =>
      _PlatformLocalConnectionPanelState();
}

class _PlatformLocalConnectionPanelState
    extends ConsumerState<PlatformLocalConnectionPanel> {
  LocalHermesHomeInspection? _inspection;
  int _generation = 0;
  int _step = 0;
  bool _picking = false;
  bool _opening = false;
  bool _linkFailed = false;

  bool get _linux => !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;
  bool get _phone => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    if (widget.enabled && _linux) unawaited(_inspectDefault());
  }

  @override
  void didUpdateWidget(PlatformLocalConnectionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled == widget.enabled) return;
    _generation++;
    _inspection = null;
    _step = 0;
    _picking = false;
    _opening = false;
    _linkFailed = false;
    if (widget.enabled && _linux) unawaited(_inspectDefault());
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  bool _current(int generation) =>
      mounted && widget.enabled && generation == _generation;

  Future<void> _inspectDefault() async {
    final generation = ++_generation;
    final result = await ref
        .read(platformLocalHomeDiscoveryProvider)
        .inspectDefault();
    if (_current(generation)) setState(() => _inspection = result);
  }

  Future<void> _chooseHome() async {
    if (_picking || widget.busy) return;
    final generation = ++_generation;
    setState(() => _picking = true);
    try {
      final directory = await ref.read(platformLocalDirectoryPickerProvider)();
      if (!_current(generation)) return;
      if (directory == null) {
        setState(() => _picking = false);
        if (_inspection == null) unawaited(_inspectDefault());
        return;
      }
      final result = await ref
          .read(platformLocalHomeDiscoveryProvider)
          .inspectSelected(directory);
      if (_current(generation)) setState(() => _inspection = result);
    } on Object {
      if (_current(generation)) {
        setState(
          () => _inspection = const LocalHermesHomeInspection.unavailable(
            LocalHermesHomeStatus.unreadable,
          ),
        );
      }
    } finally {
      if (_current(generation)) {
        setState(() => _picking = false);
      }
    }
  }

  Future<void> _openDocumentation(String url) async {
    if (_opening || widget.busy) return;
    final generation = _generation;
    setState(() {
      _opening = true;
      _linkFailed = false;
    });
    var opened = false;
    try {
      opened = await ref.read(platformLocalDocumentationLauncherProvider)(
        Uri.parse(url),
      );
    } on Object {
      opened = false;
    }
    if (!_current(generation)) return;
    setState(() {
      _opening = false;
      _linkFailed = !opened;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget heading(String value) =>
        Text(value, style: theme.textTheme.titleLarge);
    Widget docs(String key, String label, String url) => OutlinedButton.icon(
      key: ValueKey(key),
      onPressed: _opening || widget.busy ? null : () => _openDocumentation(url),
      icon: const Icon(Icons.open_in_new),
      label: Text(label),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_linux) ...[
          heading(s.platformLocalHomeTitle),
          const SizedBox(height: 8),
          Text(s.platformLocalHomeExplanation),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(switch (_inspection?.status) {
              null => s.platformLocalHomeInspecting,
              LocalHermesHomeStatus.supported => s.platformLocalHomeFound,
              LocalHermesHomeStatus.absent => s.platformLocalHomeMissing,
              LocalHermesHomeStatus.notDirectory =>
                s.platformLocalHomeNotDirectory,
              LocalHermesHomeStatus.unreadable => s.platformLocalHomeUnreadable,
              LocalHermesHomeStatus.unsupported =>
                s.platformLocalHomeUnsupported,
            }, key: const ValueKey('platform-local-home-status')),
          ),
          if (_inspection?.canonicalPath case final String path)
            Text(path, key: const ValueKey('platform-local-home-path')),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('platform-local-choose-home'),
            onPressed: _picking || widget.busy ? null : _chooseHome,
            icon: const Icon(Icons.folder_open),
            label: Text(s.platformLocalChooseHome),
          ),
          const SizedBox(height: 16),
          widget.child,
        ] else if (_phone) ...[
          heading(s.platformLocalPhoneTitle),
          const SizedBox(height: 8),
          Text(s.platformLocalPhoneBoundary),
          const SizedBox(height: 12),
          Text(
            s.platformLocalPackageWarning,
            key: const ValueKey('platform-local-package-warning'),
          ),
          const SizedBox(height: 16),
          if (_step == 0) ...[
            heading(s.platformLocalPrepareTitle),
            Text(s.platformLocalPrepareBody),
            docs(
              'platform-local-termux-docs',
              s.platformLocalTermuxDocs,
              'https://github.com/termux/termux-app#installation',
            ),
            docs(
              'platform-local-agent-docs',
              s.platformLocalAgentDocs,
              'https://hermes-agent.nousresearch.com/docs/getting-started/termux',
            ),
            FilledButton(
              key: const ValueKey('platform-local-existing-agent'),
              onPressed: widget.busy ? null : () => setState(() => _step = 1),
              child: Text(s.platformLocalExistingAgent),
            ),
            TextButton(
              key: const ValueKey('platform-local-skip-guide'),
              onPressed: widget.busy ? null : () => setState(() => _step = 2),
              child: Text(s.platformLocalSkipGuide),
            ),
          ] else if (_step == 1) ...[
            heading(s.platformLocalConfigureTitle),
            Text(s.platformLocalConfigureBody),
            docs(
              'platform-local-api-docs',
              s.platformLocalApiDocs,
              'https://hermes-agent.nousresearch.com/docs/user-guide/features/api-server',
            ),
            FilledButton(
              key: const ValueKey('platform-local-started-agent'),
              onPressed: widget.busy ? null : () => setState(() => _step = 2),
              child: Text(s.platformLocalStartedAgent),
            ),
          ] else ...[
            heading(s.platformLocalAuthenticateTitle),
            Text(s.platformLocalAuthenticateBody),
            const SizedBox(height: 12),
            widget.child,
          ],
          if (_step > 0)
            TextButton(
              key: const ValueKey('platform-local-guide-back'),
              onPressed: widget.busy ? null : () => setState(() => _step--),
              child: Text(s.platformLocalGuideBack),
            ),
          if (_linkFailed)
            Text(
              s.platformLocalDocumentationFailed,
              key: const ValueKey('platform-local-docs-error'),
            ),
        ] else ...[
          Text(s.platformLocalBrowserExplanation),
          const SizedBox(height: 16),
          widget.child,
        ],
      ],
    );
  }
}
