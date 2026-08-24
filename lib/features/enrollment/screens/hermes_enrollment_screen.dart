import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../router/routes/app_routes.dart';
import '../../hermes_chat/screens/hermes_chat_screen.dart';
import '../models/hermes_enrollment_payload.dart';
import '../providers/hermes_enrollment_provider.dart';

enum _EnrollmentInputError { invalid, clipboardEmpty }

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
  _EnrollmentInputError? _payloadError;
  bool _bootstrapped = false;
  bool _scanning = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    final source = ref.read(hermesConnectIntentSourceProvider);
    _subscription = source.payloadEvents().listen(_handleExplicitHandoff);
    unawaited(
      source.initialPayload().then((payload) {
        if (!mounted || payload == null) return;
        _handleExplicitHandoff(payload);
      }),
    );
  }

  void _handleExplicitHandoff(
    String raw, {
    bool cleartextOriginConfirmed = false,
  }) {
    if (!mounted) return;
    try {
      final payload = HermesEnrollmentPayload.parseExplicitHandoff(
        raw,
        cleartextOriginConfirmed: cleartextOriginConfirmed,
      );
      setState(() => _payloadError = null);
      unawaited(ref.read(hermesEnrollmentControllerProvider).inspect(payload));
    } on HermesEnrollmentCleartextOriginRequired catch (error) {
      // Parse the exact candidate synchronously into the smallest structured
      // enrollment value before showing UI. The raw shared prose/link must not
      // remain captured across the dialog await.
      try {
        final payload = HermesEnrollmentPayload.parseExplicitHandoff(
          raw,
          cleartextOriginConfirmed: true,
        );
        unawaited(_confirmCleartextOrigin(payload, error.origin));
      } on FormatException {
        setState(() => _payloadError = _EnrollmentInputError.invalid);
      }
    } on FormatException {
      setState(() => _payloadError = _EnrollmentInputError.invalid);
    }
  }

  Future<void> _pastePairingLink() async {
    setState(() => _payloadError = null);
    final ClipboardData? data;
    try {
      data = await Clipboard.getData(Clipboard.kTextPlain);
    } on PlatformException {
      if (mounted) {
        setState(() => _payloadError = _EnrollmentInputError.invalid);
      }
      return;
    }
    if (!mounted) return;
    final raw = data?.text;
    if (raw == null || raw.trim().isEmpty) {
      setState(() => _payloadError = _EnrollmentInputError.clipboardEmpty);
      return;
    }
    _handleExplicitHandoff(raw);
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
    if (payload != null) _handleExplicitHandoff(payload);
  }

  Future<void> _confirmCleartextOrigin(
    HermesEnrollmentPayload payload,
    Uri origin,
  ) async {
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
    setState(() => _payloadError = null);
    unawaited(ref.read(hermesEnrollmentControllerProvider).inspect(payload));
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
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) =>
              const HermesChatScreen(initiallyEditingConnection: true),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(hermesEnrollmentControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).enrollTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
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
              Text(
                _payloadError == _EnrollmentInputError.clipboardEmpty
                    ? strings.enrollClipboardEmpty
                    : strings.enrollInvalidLinkBody,
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
        final count = controller.connectedProfileCount;
        if (count == null) return const SizedBox.shrink();
        return Center(
          child: Column(
            key: const ValueKey('hermes-enrollment-confirmed'),
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, size: 48),
              const SizedBox(height: 12),
              Text(
                strings.enrollConnectedProfiles(count),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(strings.enrollConnectedBody, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton(
                    key: const ValueKey('hermes-enrollment-view-profiles'),
                    onPressed: () =>
                        _leaveConfirmed(controller, AppRoutes.profiles),
                    child: Text(strings.enrollViewProfilesAction),
                  ),
                  FilledButton.tonal(
                    key: const ValueKey('hermes-enrollment-open-chat'),
                    onPressed: () =>
                        _leaveConfirmed(controller, AppRoutes.hermes),
                    child: Text(strings.enrollOpenChatAction),
                  ),
                ],
              ),
            ],
          ),
        );
      case HermesEnrollmentStatus.expired:
        return _buildExpired();
      case HermesEnrollmentStatus.inspectionFailed:
        return _buildFailure(exchangeFailed: false);
      case HermesEnrollmentStatus.exchangeFailed:
        return _buildFailure(exchangeFailed: true);
    }
  }

  Widget _buildFailure({required bool exchangeFailed}) {
    final strings = AppLocalizations.of(context);
    final buttonStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
    );
    return Center(
      child: Semantics(
        liveRegion: true,
        child: Column(
          key: const ValueKey('hermes-enrollment-error'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.link_off, size: 48),
            const SizedBox(height: 12),
            Text(
              exchangeFailed
                  ? strings.enrollExchangeFailedTitle
                  : strings.enrollInspectionFailedTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              exchangeFailed
                  ? strings.enrollExchangeFailedBody
                  : strings.enrollInspectionFailedBody,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const ValueKey('hermes-enrollment-paste-another'),
              style: buttonStyle,
              onPressed: _scanning
                  ? null
                  : () => unawaited(_pastePairingLink()),
              icon: const Icon(Icons.content_paste_outlined),
              label: Text(strings.enrollPasteAnotherLink),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              key: const ValueKey('hermes-enrollment-scan-another'),
              style: buttonStyle,
              onPressed: _scanning ? null : () => unawaited(_scanQrCode()),
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(strings.enrollScanAnotherQr),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpired() {
    final strings = AppLocalizations.of(context);
    final buttonStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
    );
    return Center(
      child: Semantics(
        liveRegion: true,
        child: Column(
          key: const ValueKey('hermes-enrollment-expired'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.timer_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              strings.enrollExpiredTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(strings.enrollExpiredBody, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const ValueKey('hermes-enrollment-paste-another'),
              style: buttonStyle,
              onPressed: _scanning
                  ? null
                  : () => unawaited(_pastePairingLink()),
              icon: const Icon(Icons.content_paste_outlined),
              label: Text(strings.enrollPasteAnotherLink),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              key: const ValueKey('hermes-enrollment-scan-another'),
              style: buttonStyle,
              onPressed: _scanning ? null : () => unawaited(_scanQrCode()),
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(strings.enrollScanAnotherQr),
            ),
          ],
        ),
      ),
    );
  }

  void _leaveConfirmed(HermesEnrollmentController controller, String route) {
    controller.clearConfirmed();
    context.go(route);
  }

  Widget _entryActions() {
    final strings = AppLocalizations.of(context);
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (isAndroid) {
      final buttonStyle = ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            key: const ValueKey('hermes-enrollment-paste-link'),
            style: buttonStyle,
            onPressed: _scanning ? null : () => unawaited(_pastePairingLink()),
            icon: const Icon(Icons.content_paste_outlined),
            label: Text(strings.enrollPasteLink),
          ),
          const SizedBox(height: 12),
          _scanButton(style: buttonStyle),
          const SizedBox(height: 12),
          Text(strings.enrollSameDeviceHelper, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('hermes-enrollment-manual-connect'),
            style: buttonStyle,
            onPressed: _scanning ? null : _openManualConnection,
            icon: const Icon(Icons.link_outlined),
            label: Text(strings.enrollManualConnectAction),
          ),
          const SizedBox(height: 8),
          Text(
            strings.enrollManualConnectWarning,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux)
          FilledButton.tonalIcon(
            key: const ValueKey('hermes-enrollment-local-setup'),
            onPressed: () => context.push(AppRoutes.localSetup),
            icon: const Icon(Icons.computer_outlined),
            label: Text(strings.localSetupAction),
          ),
        OutlinedButton.icon(
          key: const ValueKey('hermes-enrollment-manual-connect'),
          onPressed: _scanning ? null : _openManualConnection,
          icon: const Icon(Icons.link_outlined),
          label: Text(strings.enrollManualConnectAction),
        ),
      ],
    );
  }

  Widget _scanButton({ButtonStyle? style}) {
    final strings = AppLocalizations.of(context);
    return FilledButton.tonalIcon(
      key: const ValueKey('hermes-enrollment-scan-qr'),
      style: style,
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
    final wingLinkHost = _displayAuthority(controller.wingLinkOrigin);
    final reviewedLabel = preview.label.isEmpty
        ? strings.enrollUnlabeled
        : preview.label;
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
          strings.enrollGrantQuestion(preview.connectionCount, reviewedLabel),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        _PreviewRow(
          label: strings.enrollHermesAgentLabel,
          value: host,
          valueKey: 'hermes-enrollment-host',
        ),
        if (wingLinkHost != null)
          _PreviewRow(
            label: strings.enrollWingLinkLabel,
            value: wingLinkHost,
            valueKey: 'hermes-enrollment-wing-link-host',
          ),
        _PreviewRow(
          label: strings.enrollRequestedAccess,
          value: preview.scopes.isEmpty
              ? strings.enrollScopesNone
              : preview.scopes.join(', '),
          valueKey: 'hermes-enrollment-scopes',
        ),
        _PreviewRow(
          label: strings.enrollProfilesLabel,
          value: preview.connectionCount.toString(),
          valueKey: 'hermes-enrollment-profile-count',
        ),
        _PreviewRow(
          label: strings.enrollExpiresLabel,
          value: _formatRemainingTime(strings, controller.remainingTime),
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
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton(
              key: const ValueKey('hermes-enrollment-cancel'),
              onPressed: confirming ? null : _cancel,
              child: Text(strings.cancelAction),
            ),
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
                  : Text(
                      strings.enrollConnectProfilesAction(
                        preview.connectionCount,
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  String? _displayAuthority(Uri? uri) {
    if (uri == null || uri.host.isEmpty) return null;
    return uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
  }

  /// Scheme+host+port only, lowercased — the identity that matters for
  /// deciding whether the paired server's claimed origin matches the link.
  String _normalizedOrigin(Uri uri) {
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme.toLowerCase()}://${uri.host.toLowerCase()}$port';
  }

  String _formatRemainingTime(AppLocalizations strings, Duration? remaining) {
    if (remaining == null) return strings.enrollExpiryUnknown;
    final seconds = remaining.inSeconds;
    final minutes = seconds ~/ Duration.secondsPerMinute;
    final remainder = seconds % Duration.secondsPerMinute;
    return '$minutes:${remainder.toString().padLeft(2, '0')}';
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
