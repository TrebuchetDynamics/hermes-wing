import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../router/routes/app_routes.dart';
import '../models/hermes_enrollment_payload.dart';
import '../providers/hermes_enrollment_provider.dart';

/// Reviews a one-time Hermes Wing connect pairing request before exchanging it.
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
  bool _scanning = false;

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
      setState(() => _payloadError = error.message);
    }
  }

  Future<void> _scanQrCode() async {
    if (_scanning) return;
    setState(() {
      _scanning = true;
      _payloadError = null;
    });
    final payload = await ref
        .read(hermesConnectIntentSourceProvider)
        .scanQrCode();
    if (!mounted) return;
    setState(() => _scanning = false);
    if (payload != null) _handlePayload(payload);
  }

  Future<void> _confirmCleartextOrigin(String raw, Uri origin) async {
    final strings = AppLocalizations.of(context);
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            key: const ValueKey('hermes-enrollment-cleartext-warning'),
            title: Text(strings.enrollCleartextDialogTitle),
            content: Text(strings.enrollCleartextDialogBody(origin.host)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(strings.cancelAction),
              ),
              FilledButton(
                key: const ValueKey('hermes-enrollment-cleartext-confirm'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(strings.enrollContinueAction),
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

  void _openManualConnection() {
    ref.read(hermesEnrollmentControllerProvider).cancel();
    context.go('${AppRoutes.hermes}?connect=1');
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
      appBar: AppBar(title: Text(AppLocalizations.of(context).enrollTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildBody(controller),
        ),
      ),
    );
  }

  Widget _buildBody(HermesEnrollmentController controller) {
    final strings = AppLocalizations.of(context);
    if (_payloadError != null) {
      final colors = Theme.of(context).colorScheme;
      return Center(
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.link_off, size: 48, color: colors.error),
              const SizedBox(height: 12),
              Text(
                strings.enrollInvalidLinkTitle,
                key: const ValueKey('hermes-enrollment-payload-error'),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(strings.enrollInvalidLinkBody, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                strings.enrollInvalidLinkDetail(_payloadError!),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _entryActions(),
            ],
          ),
        ),
      );
    }
    switch (controller.status) {
      case HermesEnrollmentStatus.idle:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                strings.enrollScanPrompt,
                key: const ValueKey('hermes-enrollment-idle'),
              ),
              const SizedBox(height: 16),
              _entryActions(),
            ],
          ),
        );
      case HermesEnrollmentStatus.inspecting:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(strings.enrollVerifying),
            ],
          ),
        );
      case HermesEnrollmentStatus.ready:
      case HermesEnrollmentStatus.confirming:
        return _buildPreview(controller);
      case HermesEnrollmentStatus.confirmed:
        return Center(
          child: Text(
            strings.enrollConnected,
            key: const ValueKey('hermes-enrollment-confirmed'),
          ),
        );
      case HermesEnrollmentStatus.failed:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                controller.errorMessage ?? strings.enrollFailed,
                key: const ValueKey('hermes-enrollment-error'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const ValueKey('hermes-enrollment-dismiss'),
                onPressed: _cancel,
                child: Text(strings.enrollCloseAction),
              ),
            ],
          ),
        );
    }
  }

  Widget _entryActions() {
    final strings = AppLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        _scanButton(),
        OutlinedButton.icon(
          key: const ValueKey('hermes-enrollment-manual-connect'),
          onPressed: _scanning ? null : _openManualConnection,
          icon: const Icon(Icons.link_outlined),
          label: Text(strings.enrollManualConnectAction),
        ),
      ],
    );
  }

  Widget _scanButton() {
    final strings = AppLocalizations.of(context);
    return FilledButton.icon(
      key: const ValueKey('hermes-enrollment-scan-qr'),
      onPressed: _scanning ? null : () => unawaited(_scanQrCode()),
      icon: _scanning
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.qr_code_scanner),
      label: Text(
        _scanning ? strings.enrollOpeningScanner : strings.enrollScanQr,
      ),
    );
  }

  Widget _buildPreview(HermesEnrollmentController controller) {
    final strings = AppLocalizations.of(context);
    final preview = controller.preview;
    if (preview == null) return const SizedBox.shrink();
    final confirming = controller.status == HermesEnrollmentStatus.confirming;
    // Display the origin from the pairing PAYLOAD — the host the token will
    // actually be saved and connected against — never the server-echoed
    // `preview.origin`, which the paired server fully controls. Showing the
    // server's claimed host would let a hostile link display a trusted name
    // while the grant lands elsewhere.
    final originUri = controller.origin;
    final host = originUri != null && originUri.host.isNotEmpty
        ? (originUri.hasPort
              ? '${originUri.host}:${originUri.port}'
              : originUri.host)
        : (originUri?.toString() ?? preview.origin);
    final cleartext = originUri?.scheme == 'http';
    final previewUri = Uri.tryParse(preview.origin);
    final originMismatch =
        originUri != null &&
        previewUri != null &&
        _normalizedOrigin(previewUri) != _normalizedOrigin(originUri);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          strings.enrollGrantQuestion,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        _PreviewRow(
          label: strings.enrollEndpointLabel,
          value: host,
          valueKey: 'hermes-enrollment-host',
        ),
        _PreviewRow(
          label: strings.enrollDeviceLabel,
          value: preview.label.isEmpty
              ? strings.enrollUnlabeled
              : preview.label,
          valueKey: 'hermes-enrollment-label',
        ),
        _PreviewRow(
          label: strings.enrollRequestedAccess,
          value: preview.scopes.isEmpty
              ? strings.enrollScopesNone
              : preview.scopes.join(', '),
          valueKey: 'hermes-enrollment-scopes',
        ),
        _PreviewRow(
          label: strings.enrollExpiresLabel,
          value: _formatExpiry(strings, preview.expiresAt),
          valueKey: 'hermes-enrollment-expiry',
        ),
        if (cleartext) ...[
          const SizedBox(height: 8),
          Text(
            strings.enrollCleartextNotice,
            key: const ValueKey('hermes-enrollment-cleartext-notice'),
          ),
        ],
        if (originMismatch) ...[
          const SizedBox(height: 8),
          Text(
            strings.enrollOriginMismatch(preview.origin),
            key: const ValueKey('hermes-enrollment-origin-mismatch'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            OutlinedButton(
              key: const ValueKey('hermes-enrollment-cancel'),
              onPressed: confirming ? null : _cancel,
              child: Text(strings.cancelAction),
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
                  : Text(strings.enrollConnectAction),
            ),
          ],
        ),
      ],
    );
  }

  /// Scheme+host+port only, lowercased — the identity that matters for
  /// deciding whether the paired server's claimed origin matches the link.
  String _normalizedOrigin(Uri uri) {
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme.toLowerCase()}://${uri.host.toLowerCase()}$port';
  }

  String _formatExpiry(AppLocalizations strings, DateTime? expiresAt) {
    if (expiresAt == null) return strings.enrollExpiryUnknown;
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
