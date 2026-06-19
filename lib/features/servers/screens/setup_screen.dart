import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/channel/navivox_channel_provider.dart';
import '../../../core/session/credentials/credential_store_provider.dart';
import '../../../core/session/session_persistence_service.dart';
import '../../../router/navigation_intent.dart';
import '../models/connection_import.dart';
import '../pairing/pairing_handoff_flow.dart';
import '../pairing/pairing_intent.dart';
import '../pairing/pairing_intent_coordinator.dart';
import '../shared/gateway_connection_presentation.dart';
import '../setup/navivox_connect_intent_source.dart';
import '../setup/navivox_connect_intent_source_provider.dart';
import '../setup/setup_guide_presentation.dart';
import '../setup/setup_qr_import_presentation.dart';
import '../setup/setup_screen_presentation.dart';

export '../models/connection_import.dart'
    show PairingHandoffSource, SetupQrImageImport;

export '../setup/setup_qr_import_presentation.dart' show parseNavivoxQrPayload;

const _setupGuidePresentation = SetupGuidePresentation();
const _setupScreenPresentation = SetupScreenPresentation();

typedef SetupQrImageImporter = Future<SetupQrImageImport?> Function();

class SetupQrImageImportException implements Exception {
  const SetupQrImageImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({
    this.qrImageImporter,
    this.connectIntentSource,
    super.key,
  });

  final SetupQrImageImporter? qrImageImporter;
  final NavivoxConnectIntentSource? connectIntentSource;

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupHero extends StatelessWidget {
  const _SetupHero({required this.title, required this.instructions});

  final String title;
  final String instructions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withAlpha(40),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Image.asset('navivox-app-icon.png', fit: BoxFit.cover),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Text(
            instructions,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _SetupHelpCard extends StatelessWidget {
  const _SetupHelpCard({
    required this.networkHint,
    required this.introCopy,
    required this.entries,
    required this.onCopyEntry,
  });

  final String networkHint;
  final String introCopy;
  final List<SetupGuideEntry> entries;
  final ValueChanged<SetupGuideEntry> onCopyEntry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      child: ExpansionTile(
        leading: const Icon(Icons.help_outline),
        title: const Text('Need setup help?'),
        subtitle: const Text('Termux bootstrap, host URL tips, and fixes'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            networkHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            introCopy,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          for (final entry in entries) ...[
            OutlinedButton.icon(
              onPressed: () => onCopyEntry(entry),
              icon: Icon(_setupGuideIcon(entry.id)),
              label: Text(entry.label),
            ),
            if (entry != entries.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _PairingReadinessCard extends StatelessWidget {
  const _PairingReadinessCard({required this.readiness});

  final SetupPairingReadinessPresentation readiness;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = _readinessColors(colorScheme, readiness.status);

    return Semantics(
      key: const ValueKey('setup-pairing-readiness-card'),
      liveRegion:
          readiness.status == SetupPairingReadinessStatus.connecting ||
          readiness.status == SetupPairingReadinessStatus.failedRetry,
      child: Card(
        elevation: 0,
        color: colors.background,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _readinessIcon(readiness.status),
                  color: colors.foreground,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      readiness.title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      readiness.statusLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      readiness.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.foreground,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

({Color background, Color iconBackground, Color foreground}) _readinessColors(
  ColorScheme colorScheme,
  SetupPairingReadinessStatus status,
) {
  return switch (status) {
    SetupPairingReadinessStatus.failedRetry => (
      background: colorScheme.errorContainer,
      iconBackground: colorScheme.errorContainer,
      foreground: colorScheme.onErrorContainer,
    ),
    SetupPairingReadinessStatus.connectedSessionOnly => (
      background: colorScheme.tertiaryContainer,
      iconBackground: colorScheme.tertiaryContainer,
      foreground: colorScheme.onTertiaryContainer,
    ),
    SetupPairingReadinessStatus.importedNeedsReview => (
      background: colorScheme.secondaryContainer,
      iconBackground: colorScheme.secondaryContainer,
      foreground: colorScheme.onSecondaryContainer,
    ),
    SetupPairingReadinessStatus.connecting => (
      background: colorScheme.primaryContainer,
      iconBackground: colorScheme.primaryContainer,
      foreground: colorScheme.onPrimaryContainer,
    ),
    SetupPairingReadinessStatus.manual => (
      background: colorScheme.surfaceContainerHighest,
      iconBackground: colorScheme.secondaryContainer,
      foreground: colorScheme.onSurfaceVariant,
    ),
  };
}

IconData _readinessIcon(SetupPairingReadinessStatus status) {
  return switch (status) {
    SetupPairingReadinessStatus.failedRetry => Icons.error_outline,
    SetupPairingReadinessStatus.connectedSessionOnly =>
      Icons.check_circle_outline,
    SetupPairingReadinessStatus.importedNeedsReview =>
      Icons.fact_check_outlined,
    SetupPairingReadinessStatus.connecting => Icons.sync,
    SetupPairingReadinessStatus.manual => Icons.link_outlined,
  };
}

class _SetupNoticeBanner extends StatelessWidget {
  const _SetupNoticeBanner({required this.notice});

  final SetupScreenNotice notice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = notice.isError
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;
    final foreground = notice.isError
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              notice.isError ? Icons.error_outline : Icons.check_circle_outline,
              color: foreground,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notice.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  if (notice.recoveryMessage != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      notice.recoveryMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: foreground,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _urlController = TextEditingController(text: 'http://127.0.0.1:8765');
  final _tokenController = TextEditingController();
  final _expansionController = ExpansibleController();
  bool _connecting = false;
  bool _showToken = false;
  bool _importingQr = false;
  String? _webSocketUrl;
  PairingHandoffFlow _handoffFlow = const PairingHandoffFlow();
  SetupScreenNotice? _notice;
  late final NavivoxConnectIntentSource _connectIntentSource;
  StreamSubscription<SetupQrImageImport>? _connectIntentSubscription;

  @override
  void initState() {
    super.initState();
    _connectIntentSource =
        widget.connectIntentSource ??
        ref.read(navivoxConnectIntentSourceProvider);
    unawaited(_startConnectIntentHandling());
    unawaited(_tryAutoReconnect());
  }

  @override
  void dispose() {
    _connectIntentSubscription?.cancel();
    _urlController.dispose();
    _tokenController.dispose();
    _expansionController.dispose();
    super.dispose();
  }

  Future<void> _tryAutoReconnect() async {
    final session = SessionPersistenceService();
    final saved = await session.loadSession();
    if (saved == null || saved.isStale) return;

    final gatewayId = saved.gatewayId;
    final credentialStore = ref.read(durableCredentialStoreProvider);

    // Check whether a device credential was saved for this gateway.
    final hasCredential =
        gatewayId != null &&
        await credentialStore.containsCredential(gatewayId: gatewayId);

    if (!hasCredential) {
      if (!mounted) return;
      setState(() {
        _notice = const SetupScreenNotice.info(
          'Known gateway saved. Pair again to reconnect.',
        );
      });
      return;
    }

    // Load the stored credential to form a device-bearer token.
    final metadata = await credentialStore.metadata(gatewayId: gatewayId);
    final secret = await credentialStore.loadSecret(gatewayId: gatewayId);
    if (metadata == null || secret == null || secret.isEmpty) {
      if (!mounted) return;
      setState(() {
        _notice = const SetupScreenNotice.info(
          'Known gateway saved. Pair again to reconnect.',
        );
      });
      return;
    }

    if (metadata.isExpired) {
      await credentialStore.deleteCredential(gatewayId: gatewayId);
      if (!mounted) return;
      setState(() {
        _notice = const SetupScreenNotice.info(
          'Saved credential expired. Pair again to reconnect.',
        );
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _connecting = true;
      _notice = const SetupScreenNotice.info('Reconnecting to saved gateway…');
    });
    try {
      // Reconnect using the stored device-bearer credential so no QR scan is
      // needed. The token is formatted as "{credentialId}:{secret}" and sent
      // as a standard Bearer header; gormes validates the SHA-256 of the secret.
      final deviceBearerToken = '${metadata.credentialLabel}:$secret';
      await ref.read(gatewayNavivoxChannelProvider).connect(
        baseUrl: saved.baseUrl,
        webSocketUrl: saved.webSocketUrl,
        token: deviceBearerToken,
      );
      // Reconnect success: router redirect will handle navigation to chat.
    } catch (_) {
      if (mounted) {
        setState(() {
          _notice = SetupScreenNotice.error(
            'Could not reconnect to saved gateway. Pair again.',
            recoveryMessage:
                'Run `gormes navivox pair` on your host and try again.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final channel = ref.watch(navivoxChannelProvider);
    final readiness = _setupScreenPresentation.pairingReadiness(
      connecting: _connecting,
      connectedSession: channel.state.hasServers,
      source: _handoffFlow.source,
      hasError: _notice?.isError ?? false,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Navivox')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;
            final showReadiness =
                readiness.status != SetupPairingReadinessStatus.manual;

            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primaryContainer.withAlpha(
                      colorScheme.brightness == Brightness.dark ? 44 : 96,
                    ),
                    colorScheme.surface,
                    colorScheme.surface,
                  ],
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 16 : 24,
                    vertical: compact ? 20 : 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SetupHero(
                          title: _setupScreenPresentation.title,
                          instructions:
                              _setupScreenPresentation.pairingInstructions,
                        ),
                        SizedBox(height: compact ? 16 : 20),
                        if (showReadiness) ...[
                          _PairingReadinessCard(readiness: readiness),
                          const SizedBox(height: 12),
                        ],
                        Card(
                          elevation: 0,
                          child: Padding(
                            padding: EdgeInsets.all(compact ? 16 : 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                FilledButton.icon(
                                  key: const ValueKey(
                                    'setup-import-qr-button',
                                  ),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(52),
                                  ),
                                  onPressed: _connecting || _importingQr
                                      ? null
                                      : _importQrImage,
                                  icon: _importingQr
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.qr_code_scanner),
                                  label: Text(
                                    _setupScreenPresentation
                                        .importQrButtonLabel,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ExpansionTile(
                                  controller: _expansionController,
                                  tilePadding: EdgeInsets.zero,
                                  title: Text(
                                    _setupScreenPresentation.enterManuallyLabel,
                                  ),
                                  children: [
                                    const SizedBox(height: 4),
                                    _urlField(),
                                    const SizedBox(height: 12),
                                    _tokenField(),
                                    const SizedBox(height: 16),
                                    Semantics(
                                      container: true,
                                      label: _setupScreenPresentation
                                          .connectButtonLabel,
                                      hint: _setupScreenPresentation
                                          .connectButtonSemanticHint,
                                      button: true,
                                      enabled: !_connecting,
                                      onTap: _connecting
                                          ? null
                                          : _submitManualPairingHandoff,
                                      child: ExcludeSemantics(
                                        child: FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            minimumSize:
                                                const Size.fromHeight(52),
                                            textStyle: theme
                                                .textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          onPressed: _connecting
                                              ? null
                                              : _submitManualPairingHandoff,
                                          icon: _connecting
                                              ? const SizedBox.square(
                                                  dimension: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : const Icon(Icons.hub),
                                          label: Text(
                                            _setupScreenPresentation
                                                .connectButtonLabel,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                                if (_notice != null) ...[
                                  const SizedBox(height: 8),
                                  _SetupNoticeBanner(notice: _notice!),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SetupHelpCard(
                          networkHint: _setupScreenPresentation.networkHint,
                          introCopy: _setupGuidePresentation.introCopy,
                          entries: _setupGuidePresentation.visibleEntries,
                          onCopyEntry: _copySetupGuideEntry,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _urlField() {
    return Semantics(
      label: _setupScreenPresentation.urlFieldSemanticLabel,
      hint: _setupScreenPresentation.urlFieldSemanticHint,
      textField: true,
      child: TextField(
        controller: _urlController,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.dns_outlined),
          labelText: _setupScreenPresentation.urlFieldLabel,
        ),
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.next,
        onChanged: _handleUrlChanged,
        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
      ),
    );
  }

  Widget _tokenField() {
    return Semantics(
      label: _setupScreenPresentation.tokenFieldSemanticLabel,
      hint: _setupScreenPresentation.tokenFieldSemanticHint,
      textField: true,
      obscured: !_showToken,
      child: TextField(
        controller: _tokenController,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.key_outlined),
          labelText: _setupScreenPresentation.tokenFieldLabel,
          suffixIcon: Semantics(
            label: _setupScreenPresentation.tokenVisibilityLabel(
              showToken: _showToken,
            ),
            button: true,
            child: IconButton(
              key: const ValueKey('setup-token-visibility-button'),
              icon: Icon(
                _showToken ? Icons.visibility_off : Icons.visibility,
              ),
              tooltip: _setupScreenPresentation.tokenVisibilityLabel(
                showToken: _showToken,
              ),
              onPressed: () => setState(() => _showToken = !_showToken),
            ),
          ),
        ),
        obscureText: !_showToken,
        textInputAction: TextInputAction.done,
        onSubmitted: _connecting ? null : (_) => _submitManualPairingHandoff(),
      ),
    );
  }

  Future<void> _importQrImage() async {
    setState(() {
      _importingQr = true;
      _notice = null;
    });
    try {
      final importer = widget.qrImageImporter ?? importNavivoxQrImage;
      final result = (await importer())?.withSource(
        PairingHandoffSource.qrImage,
      );
      if (!mounted) return;
      final notice = _setupScreenPresentation.qrImportNotice(result);
      if (result == null || !result.hasValues) {
        setState(() => _notice = notice);
        return;
      }
      _handlePairingIntent(
        PairingIntent.importHandoff(result),
        importNotice: notice,
      );
    } on SetupQrImageImportException catch (error) {
      if (mounted) {
        setState(
          () => _notice = _setupScreenPresentation.qrImportFailureNotice(
            error.message,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _notice = _setupScreenPresentation.qrImportFailureNotice(),
        );
      }
    } finally {
      if (mounted) setState(() => _importingQr = false);
    }
  }

  Future<void> _startConnectIntentHandling() async {
    final available = await _connectIntentSource.isAvailable();
    if (!mounted || !available) return;
    final result = await _connectIntentSource.initialImport();
    if (!mounted) return;
    if (result != null && result.hasValues) {
      _applyConnectIntentImport(result);
    }
    _connectIntentSubscription = _connectIntentSource.imports.listen(
      _applyConnectIntentImport,
    );
  }

  void _applyConnectIntentImport(SetupQrImageImport result) {
    if (!mounted || !result.hasValues) return;
    _handlePairingIntent(
      PairingIntent.importHandoff(result),
      importNotice: _setupScreenPresentation.connectIntentImportNotice,
      allowImmediateImportedConnect: true,
    );
  }

  void _applyConnectionImport(
    SetupQrImageImport result,
    SetupScreenNotice notice,
  ) {
    setState(() {
      if (result.baseUrl != null) {
        _urlController.text = result.baseUrl!;
      }
      if (result.token != null) {
        _tokenController.text = result.token!;
      }
      _webSocketUrl = result.webSocketUrl;
      _handoffFlow = PairingHandoffFlow.fromImport(result);
      _notice = notice;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _expansionController.expand();
    });
  }

  void _handleUrlChanged(String _) {
    _webSocketUrl = null;
    _handoffFlow = _handoffFlow.applyManualConnectionEdit(
      PairingHandoffManualEdit.address,
    );
  }

  Future<void> _confirmActiveGatewayHandoff(SetupQrImageImport import) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _setupScreenPresentation.activeGatewayConfirmationTitle(
            _handoffFlow.safeSourceLabel(),
          ),
        ),
        content: Text(
          _setupScreenPresentation.activeGatewayConfirmationMessage(
            _safeHandoffHostSummary(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              _setupScreenPresentation.activeGatewayCancelButtonLabel,
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              _setupScreenPresentation.activeGatewayConfirmButtonLabel,
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _handlePairingIntent(PairingIntent.confirmHandoff(import));
    }
  }

  String _safeHandoffHostSummary() {
    const presentation = GatewayConnectionPresentation();
    final parsed = presentation.splitBaseUrl(_urlController.text);
    if (parsed.hasError || parsed.baseUrl == null) return 'the new gateway';
    return parsed.baseUrl!;
  }

  Future<void> _submitManualPairingHandoff() {
    return _handlePairingIntent(
      PairingIntent.submitManualHandoff(
        baseUrl: _safeHandoffHostSummary(),
        token: _tokenController.text,
        webSocketUrl: _webSocketUrl,
      ),
    );
  }

  Future<void> _handlePairingIntent(
    PairingIntent intent, {
    SetupScreenNotice? importNotice,
    bool allowImmediateImportedConnect = false,
  }) async {
    final hasActiveGateway = ref
        .read(gatewayNavivoxChannelProvider)
        .state
        .hasServers;
    final plan = const PairingIntentCoordinator().plan(
      intent,
      hasActiveGateway: hasActiveGateway,
      allowImmediateImportedConnect: allowImmediateImportedConnect,
    );
    for (final effect in plan.effects) {
      await _applyPairingIntentEffect(effect, importNotice: importNotice);
    }
  }

  Future<void> _applyPairingIntentEffect(
    PairingIntentEffect effect, {
    SetupScreenNotice? importNotice,
  }) async {
    switch (effect) {
      case ApplyPairingImportEffect(import: final handoffImport):
        _applyConnectionImport(
          handoffImport.import,
          importNotice ?? _setupScreenPresentation.connectIntentImportNotice,
        );
      case RequestPairingConfirmationEffect(import: final handoffImport):
        unawaited(_confirmActiveGatewayHandoff(handoffImport.import));
      case ConnectPairingEffect(:final intent):
        await _connectGateway(intent);
      case IgnorePairingIntentEffect():
        return;
    }
  }

  Future<void> _connectGateway(PairingIntent intent) async {
    const presentation = GatewayConnectionPresentation();
    final urlText = _urlController.text.trim();
    final validationError = presentation.validateBaseUrl(urlText);
    if (validationError != null) {
      setState(() {
        _notice = _setupScreenPresentation.validationFailureNotice(
          validationError,
        );
      });
      return;
    }
    final request = presentation.connectRequest(
      baseUrl: urlText,
      token: _tokenController.text,
      webSocketUrl: _webSocketUrl,
    );

    final autoConnect =
        intent.action == PairingIntentAction.confirmHandoff &&
        intent.source != PairingHandoffSource.manual;
    setState(() {
      _connecting = true;
      _notice = autoConnect ? _setupScreenPresentation.autoConnectNotice : null;
    });
    try {
      final channel = ref.read(gatewayNavivoxChannelProvider);
      await channel.connect(
        baseUrl: request.baseUrl,
        token: request.token,
        webSocketUrl: request.webSocketUrl,
      );
      final outcome = _handoffFlow.afterConnect(channel.state);
      final contact = outcome.profileContactToSelect;
      if (contact != null) {
        channel.selectProfileContact(
          serverId: contact.serverId,
          profileId: contact.profileId,
        );
      }
      if (mounted) {
        NavigationIntent.go(context, outcome.navigationIntent);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _notice = intent.source == PairingHandoffSource.directAppOpen
              ? _setupScreenPresentation.directPairingConnectFailureNotice
              : _setupScreenPresentation.connectFailureNotice,
        );
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _copySetupGuideEntry(SetupGuideEntry entry) async {
    setState(() => _notice = null);
    try {
      await Clipboard.setData(ClipboardData(text: entry.clipboardText));
      if (mounted) {
        setState(() => _notice = SetupScreenNotice.info(entry.successMessage));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _notice = SetupScreenNotice.error(entry.failureMessage));
      }
    }
  }
}

IconData _setupGuideIcon(SetupGuideEntryId id) => switch (id) {
  SetupGuideEntryId.bootstrap => Icons.content_copy,
  SetupGuideEntryId.navivoxPairHandoff => Icons.qr_code_2,
};

Future<SetupQrImageImport?> importNavivoxQrImage() async {
  final image = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (image == null) return null;

  final scanner = MobileScannerController(autoStart: false);
  try {
    final capture = await scanner.analyzeImage(
      image.path,
      formats: const [BarcodeFormat.qrCode],
    );
    for (final barcode in capture?.barcodes ?? const <Barcode>[]) {
      final payload = barcode.rawValue ?? barcode.displayValue;
      if (payload == null) continue;
      final result = parseNavivoxQrPayload(payload);
      if (result != null && result.hasValues) return result;
    }
    throw const SetupQrImageImportException(
      'No Navivox connection details were found in the QR image.',
    );
  } on SetupQrImageImportException {
    rethrow;
  } on UnsupportedError {
    throw const SetupQrImageImportException(
      'QR image import is not supported on this platform.',
    );
  } catch (_) {
    throw const SetupQrImageImportException(
      'Could not read a Navivox QR image.',
    );
  } finally {
    scanner.dispose();
  }
}
