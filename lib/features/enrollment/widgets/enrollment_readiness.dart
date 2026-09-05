import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hermes/setup/hermes_endpoint_store.dart';
import '../../../l10n/app_localizations.dart';
import '../../hermes_chat/providers/hermes_channel_provider.dart';
import '../providers/hermes_enrollment_provider.dart';

/// Projects only the newly enrolled endpoint's live state; model inventory alone
/// never proves configuration, authentication, or inference readiness.
class EnrollmentReadiness extends ConsumerWidget {
  const EnrollmentReadiness({super.key, required this.controller});
  final HermesEnrollmentController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final state = ref.watch(hermesChannelStateProvider);
    final connectedUrl = state.connectedBaseUrl;
    final current =
        connectedUrl != null &&
        hermesEndpointIdForBaseUrl(connectedUrl) ==
            controller.connectedGatewayId &&
        state.isConnected;
    final model = current && state.canReadDetailedHealth
        ? state.detailedHealth?.readiness?.checks
              .where((check) => check.id == 'model')
              .firstOrNull
        : null;
    final busy = controller.connection == HermesEnrollmentConnection.connecting;
    final modelLabel = switch (model?.status) {
      'ok' => s.enrollModelConfigured,
      'degraded' => s.enrollModelMissing,
      _ => s.enrollModelUnknown,
    };
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row(context, Icons.check_circle_outline, s.enrollCredentialsSaved),
          _row(
            context,
            current ? Icons.check_circle_outline : Icons.info_outline,
            current
                ? s.enrollAgentConnected
                : busy
                ? s.enrollConnectingSaved
                : s.enrollSavedNotConnected,
          ),
          _row(
            context,
            model?.status == 'ok'
                ? Icons.check_circle_outline
                : Icons.info_outline,
            modelLabel,
          ),
          Text(
            s.enrollReadinessHelp,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('hermes-enrollment-check-readiness'),
            onPressed: busy ? null : () => unawaited(controller.connectSaved()),
            icon: busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: Text(s.enrollCheckReadiness),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
      ],
    ),
  );
}
