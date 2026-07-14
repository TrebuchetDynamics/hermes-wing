import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../router/routes/app_routes.dart';
import '../models/hermes_enrollment_payload.dart';
import '../providers/hermes_enrollment_provider.dart';

/// Reviews a one-time Navivox connect pairing request before exchanging it.
/// Reached only via an Android connect intent, so it lives outside the
/// authenticated app shell: there is no configured Hermes endpoint yet.
/// Displays only what the server returns from inspection (host, label,
/// scopes, expiry) — never a bearer token, which this screen never even
/// receives.
class HermesEnrollmentScreen extends ConsumerStatefulWidget {
  const HermesEnrollmentScreen({super.key});

  @override
  ConsumerState<HermesEnrollmentScreen> createState() =>
      _HermesEnrollmentScreenState();
}

class _HermesEnrollmentScreenState
    extends ConsumerState<HermesEnrollmentScreen> {
  StreamSubscription<String>? _subscription;
  String? _payloadError;
  bool _redirected = false;
  bool _bootstrapped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    final source = ref.read(hermesConnectIntentSourceProvider);
    _subscription = source.payloadEvents().listen(_handlePayload);
    unawaited(
      source.initialPayload().then((payload) {
        if (!mounted || payload == null) return;
        _handlePayload(payload);
      }),
    );
  }

  void _handlePayload(String raw, {bool cleartextOriginConfirmed = false}) {
    if (!mounted) return;
    try {
      final payload = HermesEnrollmentPayload.parse(
        raw,
        cleartextOriginConfirmed: cleartextOriginConfirmed,
      );
      setState(() => _payloadError = null);
      unawaited(ref.read(hermesEnrollmentControllerProvider).inspect(payload));
    } on HermesEnrollmentCleartextOriginRequired catch (error) {
      unawaited(_confirmCleartextOrigin(raw, error.origin));
    } on FormatException catch (error) {
      setState(
        () => _payloadError =
            'This pairing link is not valid: '
            '${error.message}',
      );
    }
  }

  Future<void> _confirmCleartextOrigin(String raw, Uri origin) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            key: const ValueKey('hermes-enrollment-cleartext-warning'),
            title: const Text('Pair over plain HTTP?'),
            content: Text(
              'The endpoint ${origin.host} uses plain HTTP. Continue only '
              'on a trusted VPN, Tailscale network, or isolated LAN. Prefer '
              'HTTPS for remote Hermes endpoints.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                key: const ValueKey('hermes-enrollment-cleartext-confirm'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
    if (!mounted || !confirmed) return;
    _handlePayload(raw, cleartextOriginConfirmed: true);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  void _cancel() {
    ref.read(hermesEnrollmentControllerProvider).cancel();
    setState(() => _payloadError = null);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.hermes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(hermesEnrollmentControllerProvider);
    if (controller.status == HermesEnrollmentStatus.confirmed && !_redirected) {
      _redirected = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.hermes);
      });
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Connect to Hermes')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildBody(controller),
        ),
      ),
    );
  }

  Widget _buildBody(HermesEnrollmentController controller) {
    if (_payloadError != null) {
      return Center(
        child: Text(
          _payloadError!,
          key: const ValueKey('hermes-enrollment-payload-error'),
        ),
      );
    }
    switch (controller.status) {
      case HermesEnrollmentStatus.idle:
        return const Center(
          child: Text(
            'Waiting for a pairing link from Hermes Desktop…',
            key: ValueKey('hermes-enrollment-idle'),
          ),
        );
      case HermesEnrollmentStatus.inspecting:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Verifying pairing code…'),
            ],
          ),
        );
      case HermesEnrollmentStatus.ready:
      case HermesEnrollmentStatus.confirming:
        return _buildPreview(controller);
      case HermesEnrollmentStatus.confirmed:
        return const Center(
          child: Text(
            'Connected. Returning to Hermes…',
            key: ValueKey('hermes-enrollment-confirmed'),
          ),
        );
      case HermesEnrollmentStatus.failed:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                controller.errorMessage ?? 'Pairing failed.',
                key: const ValueKey('hermes-enrollment-error'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const ValueKey('hermes-enrollment-dismiss'),
                onPressed: _cancel,
                child: const Text('Close'),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildPreview(HermesEnrollmentController controller) {
    final preview = controller.preview;
    if (preview == null) return const SizedBox.shrink();
    final confirming = controller.status == HermesEnrollmentStatus.confirming;
    final originUri = Uri.tryParse(preview.origin);
    final host = originUri?.host.isNotEmpty == true
        ? (originUri!.hasPort
              ? '${originUri.host}:${originUri.port}'
              : originUri.host)
        : preview.origin;
    final cleartext = originUri?.scheme == 'http';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Grant Navivox access to this Hermes endpoint?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        _PreviewRow(
          label: 'Endpoint',
          value: host,
          valueKey: 'hermes-enrollment-host',
        ),
        _PreviewRow(
          label: 'Device label',
          value: preview.label.isEmpty ? '(unlabeled)' : preview.label,
          valueKey: 'hermes-enrollment-label',
        ),
        _PreviewRow(
          label: 'Requested access',
          value: preview.scopes.isEmpty ? 'none' : preview.scopes.join(', '),
          valueKey: 'hermes-enrollment-scopes',
        ),
        _PreviewRow(
          label: 'Expires',
          value: _formatExpiry(preview.expiresAt),
          valueKey: 'hermes-enrollment-expiry',
        ),
        if (cleartext) ...[
          const SizedBox(height: 8),
          const Text(
            'This endpoint uses plain HTTP. Only continue on a trusted '
            'network.',
            key: ValueKey('hermes-enrollment-cleartext-notice'),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            OutlinedButton(
              key: const ValueKey('hermes-enrollment-cancel'),
              onPressed: confirming ? null : _cancel,
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            FilledButton(
              key: const ValueKey('hermes-enrollment-confirm'),
              onPressed: confirming
                  ? null
                  : () => unawaited(controller.confirm()),
              child: confirming
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Connect'),
            ),
          ],
        ),
      ],
    );
  }

  String _formatExpiry(DateTime? expiresAt) {
    if (expiresAt == null) return 'unknown';
    final local = expiresAt.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.label,
    required this.value,
    required this.valueKey,
  });

  final String label;
  final String value;
  final String valueKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: Text(value, key: ValueKey(valueKey))),
        ],
      ),
    );
  }
}
