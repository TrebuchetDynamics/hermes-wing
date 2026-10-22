import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../router/routes/app_routes.dart';
import '../../hermes_chat/screens/hermes_chat_screen.dart';
import '../../local_setup/providers/local_hermes_setup_provider.dart';

import '../widgets/hermes_welcome.dart';
import '../widgets/gateway_login_panel.dart';
import '../widgets/gateway_qr_builder.dart';

/// Direct Agent entry; deprecated handoffs are discarded, never exchanged.
class HermesEnrollmentScreen extends ConsumerStatefulWidget {
  const HermesEnrollmentScreen({super.key, this.legacyHandoff = false});

  final bool legacyHandoff;

  @override
  ConsumerState<HermesEnrollmentScreen> createState() =>
      _HermesEnrollmentScreenState();
}

class _HermesEnrollmentScreenState
    extends ConsumerState<HermesEnrollmentScreen> {
  late bool _legacyHandoff = widget.legacyHandoff;

  @override
  void didUpdateWidget(HermesEnrollmentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.legacyHandoff != oldWidget.legacyHandoff) {
      _legacyHandoff = widget.legacyHandoff;
    }
  }

  void _showChooser() {
    setState(() => _legacyHandoff = false);
    // Clear navigation state as well, so another warm handoff is observable.
    context.replace(AppRoutes.enroll);
  }

  void _cancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      _showChooser();
    }
  }

  void _openManualConnection(HermesConnectionMode mode) {
    context.push('${AppRoutes.addHermes}?mode=${mode.name}&welcome=1');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    if (_legacyHandoff) {
      return PopScope<Object?>(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _cancel();
        },
        child: Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: _cancel),
            title: Text(s.enrollTitle),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          s.enrollLegacyHandoffTitle,
                          key: const ValueKey(
                            'hermes-enrollment-legacy-rejected',
                          ),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(s.enrollLegacyHandoffBody),
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const ValueKey('hermes-enrollment-manual-connect'),
                        onPressed: _showChooser,
                        child: Text(s.enrollBackToOptions),
                      ),
                      TextButton(
                        key: const ValueKey('hermes-enrollment-cancel'),
                        onPressed: _cancel,
                        child: Text(s.cancelAction),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: HermesWelcome(
          onConnect: _openManualConnection,
          optionalSetup:
              !kIsWeb && defaultTargetPlatform == TargetPlatform.android
              ? _chooserActions()
              : ref.watch(localLinuxSetupAvailableProvider)
              ? ExpansionTile(
                  key: const ValueKey('hermes-welcome-optional'),
                  title: Text(s.enrollOptionalSetupAction),
                  children: [_chooserActions()],
                )
              : _chooserActions(),
        ),
      ),
    );
  }

  Widget _chooserActions() {
    final s = AppLocalizations.of(context);
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final linux = ref.watch(localLinuxSetupAvailableProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!android)
          TextButton.icon(
            key: const ValueKey('gateway-qr-create'),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const GatewayQrBuilder(),
            ),
            icon: const Icon(Icons.qr_code),
            label: Text(s.gatewayQrCreate),
          ),
        if (android) ...[
          ExpansionTile(
            key: const ValueKey('gateway-login-entry'),
            title: Text(s.gatewayLoginTitle),
            leading: const Icon(Icons.qr_code_scanner),
            children: const [GatewayLoginPanel()],
          ),
          OutlinedButton.icon(
            key: const ValueKey('hermes-enrollment-local-setup'),
            onPressed: () => context.push<void>(AppRoutes.localSetup),
            icon: const Icon(Icons.phone_android_outlined),
            label: Text(
              s.enrollInstallOnPhoneAction,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.enrollPhoneHelp,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ] else if (linux)
          Card.filled(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              key: const ValueKey('hermes-enrollment-local-setup'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              leading: const Icon(Icons.computer_outlined),
              title: Text(s.localSetupAction),
              subtitle: Text(s.enrollLinuxHelp),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push<void>(AppRoutes.localSetup),
            ),
          ),
      ],
    );
  }
}
