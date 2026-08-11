import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../router/routes/app_routes.dart';
import '../providers/local_hermes_setup_provider.dart';

class LocalHermesSetupScreen extends ConsumerStatefulWidget {
  const LocalHermesSetupScreen({super.key});

  @override
  ConsumerState<LocalHermesSetupScreen> createState() =>
      _LocalHermesSetupScreenState();
}

class _LocalHermesSetupScreenState
    extends ConsumerState<LocalHermesSetupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(ref.read(localHermesSetupControllerProvider).inspect());
      }
    });
  }

  Future<void> _confirmSetup() async {
    final strings = AppLocalizations.of(context);
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            key: const ValueKey('local-hermes-setup-consent'),
            title: Text(strings.localSetupConsentTitle),
            content: Text(strings.localSetupConsentBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(strings.cancelAction),
              ),
              FilledButton(
                key: const ValueKey('local-hermes-setup-confirm'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(strings.localSetupConsentAction),
              ),
            ],
          ),
        ) ??
        false;
    if (!mounted || !confirmed) return;
    unawaited(ref.read(localHermesSetupControllerProvider).setup());
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final controller = ref.watch(localHermesSetupControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(strings.localSetupTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.localSetupTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(strings.localSetupBody),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _statusBody(strings, controller),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBody(
    AppLocalizations strings,
    LocalHermesSetupController controller,
  ) {
    switch (controller.status) {
      case LocalHermesSetupStatus.idle:
      case LocalHermesSetupStatus.detecting:
        return _progress(strings.localSetupDetecting);
      case LocalHermesSetupStatus.installing:
        return _progress(strings.localSetupInstalling);
      case LocalHermesSetupStatus.missing:
        return _actionState(
          icon: Icons.download_outlined,
          title: strings.localSetupMissingTitle,
          body: strings.localSetupMissingBody,
          action: strings.localSetupInstallAction,
        );
      case LocalHermesSetupStatus.ready:
        return _actionState(
          icon: Icons.check_circle_outline,
          title: strings.localSetupReadyTitle,
          body: strings.localSetupReadyBody,
          detail: controller.inspection?.hermesVersion,
          action: strings.localSetupAdoptAction,
        );
      case LocalHermesSetupStatus.unhealthy:
        return _actionState(
          icon: Icons.build_circle_outlined,
          title: strings.localSetupUnhealthyTitle,
          body: strings.localSetupUnhealthyBody,
          action: strings.localSetupRepairAction,
        );
      case LocalHermesSetupStatus.complete:
        return _messageState(
          icon: Icons.task_alt,
          title: strings.localSetupCompleteTitle,
          body: strings.localSetupCompleteBody,
          action: FilledButton.icon(
            key: const ValueKey('local-hermes-setup-continue'),
            onPressed: () => context.go(AppRoutes.enroll),
            icon: const Icon(Icons.link),
            label: Text(strings.localSetupContinueAction),
          ),
        );
      case LocalHermesSetupStatus.failed:
        return _messageState(
          icon: Icons.error_outline,
          title: controller.errorMessage ?? strings.localSetupUnhealthyTitle,
          body: '',
          action: OutlinedButton.icon(
            key: const ValueKey('local-hermes-setup-retry'),
            onPressed: () => unawaited(controller.inspect()),
            icon: const Icon(Icons.refresh),
            label: Text(strings.localSetupRetryAction),
          ),
        );
    }
  }

  Widget _progress(String label) => Semantics(
    liveRegion: true,
    child: Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(label, textAlign: TextAlign.center),
      ],
    ),
  );

  Widget _actionState({
    required IconData icon,
    required String title,
    required String body,
    required String action,
    String? detail,
  }) => _messageState(
    icon: icon,
    title: title,
    body: body,
    detail: detail,
    action: FilledButton.icon(
      key: const ValueKey('local-hermes-setup-action'),
      onPressed: _confirmSetup,
      icon: const Icon(Icons.play_arrow),
      label: Text(action),
    ),
  );

  Widget _messageState({
    required IconData icon,
    required String title,
    required String body,
    required Widget action,
    String? detail,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 40),
      const SizedBox(height: 12),
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      if (detail != null && detail.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(detail, key: const ValueKey('local-hermes-version')),
      ],
      if (body.isNotEmpty) ...[const SizedBox(height: 8), Text(body)],
      const SizedBox(height: 20),
      action,
    ],
  );
}
