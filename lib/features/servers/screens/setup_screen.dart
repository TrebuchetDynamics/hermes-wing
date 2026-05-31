import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/channel/navivox_channel_provider.dart';
import '../../../core/protocol/navivox_endpoint_uri.dart';
import '../../../core/session/session_persistence_service.dart';
import '../../../router/navigation_intent.dart';
import '../models/connection_import.dart';
import '../pairing/pairing_handoff_flow.dart';
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

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _addressController = TextEditingController(text: '127.0.0.1');
  final _portController = TextEditingController(text: '8765');
  final _tokenController = TextEditingController();
  bool _connecting = false;
  bool _showToken = false;
  bool _importingQr = false;
  String _scheme = 'http';
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
    _addressController.dispose();
    _portController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _tryAutoReconnect() async {
    final session = SessionPersistenceService();
    final saved = await session.loadSession();
    if (saved == null || saved.isStale || !saved.canAttemptReconnect) return;
    if (!mounted) return;
    setState(() {
      _connecting = true;
      _notice = const SetupScreenNotice.info('Reconnecting to saved gateway…');
    });
    try {
      await ref
          .read(gatewayNavivoxChannelProvider)
          .connect(baseUrl: saved.baseUrl, webSocketUrl: saved.webSocketUrl);
      // Reconnect success: router redirect will handle navigation to chat.
    } catch (_) {
      if (mounted) {
        final stale = saved.isStale;
        setState(() {
          _notice = SetupScreenNotice.error(
            stale
                ? 'Saved session expired. Please pair again with your gateway.'
                : 'Could not reconnect to saved gateway. Pair again.',
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
    return Scaffold(
      appBar: AppBar(title: const Text('Navivox')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _setupScreenPresentation.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(_setupScreenPresentation.pairingInstructions),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _setupScreenPresentation.networkHint,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Semantics(
                          label: _setupScreenPresentation
                              .addressFieldSemanticLabel,
                          hint:
                              _setupScreenPresentation.addressFieldSemanticHint,
                          textField: true,
                          child: TextField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText:
                                  _setupScreenPresentation.addressFieldLabel,
                            ),
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.next,
                            onChanged: _handleAddressChanged,
                            onSubmitted: (_) =>
                                FocusScope.of(context).nextFocus(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 112,
                        child: Semantics(
                          label:
                              _setupScreenPresentation.portFieldSemanticLabel,
                          hint: _setupScreenPresentation.portFieldSemanticHint,
                          textField: true,
                          child: TextField(
                            controller: _portController,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText:
                                  _setupScreenPresentation.portFieldLabel,
                            ),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) => _webSocketUrl = null,
                            onSubmitted: (_) =>
                                FocusScope.of(context).nextFocus(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    label: _setupScreenPresentation.tokenFieldSemanticLabel,
                    hint: _setupScreenPresentation.tokenFieldSemanticHint,
                    textField: true,
                    obscured: !_showToken,
                    child: TextField(
                      controller: _tokenController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: _setupScreenPresentation.tokenFieldLabel,
                      ),
                      obscureText: !_showToken,
                      textInputAction: TextInputAction.done,
                      onSubmitted: _connecting
                          ? null
                          : (_) => _connectGateway(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        key: const ValueKey('setup-import-qr-button'),
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
                            : const Icon(Icons.image_search),
                        label: Text(
                          _setupScreenPresentation.importQrButtonLabel,
                        ),
                      ),
                      TextButton.icon(
                        key: const ValueKey(
                          'setup-copy-fix-instructions-button',
                        ),
                        onPressed: () => _copySetupGuideEntry(
                          _setupGuidePresentation.entry(
                            SetupGuideEntryId.navivoxPairHandoff,
                          ),
                        ),
                        icon: const Icon(Icons.content_copy),
                        label: Text(
                          _setupScreenPresentation.fixInstructionsButtonLabel,
                        ),
                      ),
                      TextButton.icon(
                        key: const ValueKey('setup-token-visibility-button'),
                        onPressed: () {
                          setState(() => _showToken = !_showToken);
                        },
                        icon: Icon(
                          _showToken ? Icons.visibility_off : Icons.visibility,
                        ),
                        label: Text(
                          _setupScreenPresentation.tokenVisibilityLabel(
                            showToken: _showToken,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_notice != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _notice!.message,
                      style: TextStyle(
                        color: _notice!.isError
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    if (_notice!.recoveryMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(_notice!.recoveryMessage!),
                    ],
                  ],
                  const SizedBox(height: 12),
                  Semantics(
                    label: _setupScreenPresentation.connectButtonLabel,
                    hint: _setupScreenPresentation.connectButtonSemanticHint,
                    button: true,
                    enabled: !_connecting,
                    onTap: _connecting ? null : _connectGateway,
                    child: ExcludeSemantics(
                      child: FilledButton.icon(
                        onPressed: _connecting ? null : _connectGateway,
                        icon: _connecting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.hub),
                        label: Text(
                          _setupScreenPresentation.connectButtonLabel,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _setupGuidePresentation.introCopy,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          for (final entry
                              in _setupGuidePresentation.visibleEntries) ...[
                            if (entry.id != SetupGuideEntryId.bootstrap)
                              const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () => _copySetupGuideEntry(entry),
                              icon: Icon(_setupGuideIcon(entry.id)),
                              label: Text(entry.label),
                            ),
                          ],
                        ],
                      ),
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
      _applyConnectionImport(result, notice);
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
    if (result != null && result.hasValues) {
      _applyConnectIntentImport(result);
    }
    if (!mounted) return;
    _connectIntentSubscription = _connectIntentSource.imports.listen(
      _applyConnectIntentImport,
    );
  }

  void _applyConnectIntentImport(SetupQrImageImport result) {
    if (!mounted || !result.hasValues) return;
    _applyConnectionImport(
      result,
      _setupScreenPresentation.connectIntentImportNotice,
    );
    final hasActiveGateway = ref
        .read(gatewayNavivoxChannelProvider)
        .state
        .hasServers;
    if (_handoffFlow.requiresActiveGatewayConfirmation(
      hasActiveGateway: hasActiveGateway,
    )) {
      unawaited(_confirmActiveGatewayHandoff());
      return;
    }
    if (_handoffFlow.shouldAutoConnect(hasActiveGateway: hasActiveGateway)) {
      unawaited(_connectGateway(autoConnect: true));
    }
  }

  void _applyConnectionImport(
    SetupQrImageImport result,
    SetupScreenNotice notice,
  ) {
    setState(() {
      if (result.baseUrl != null) {
        const presentation = GatewayConnectionPresentation();
        final parsed = presentation.splitBaseUrl(result.baseUrl!);
        if (!parsed.hasError) {
          _scheme = Uri.tryParse(parsed.baseUrl!)?.scheme ?? 'http';
          _addressController.text = parsed.address!;
          _portController.text = parsed.port!;
        }
      }
      if (result.token != null) {
        _tokenController.text = result.token!;
      }
      _webSocketUrl = result.webSocketUrl;
      _handoffFlow = PairingHandoffFlow.fromImport(result);
      _notice = notice;
    });
  }

  void _handleAddressChanged(String value) {
    _webSocketUrl = null;
    _handoffFlow = _handoffFlow.resetManualConnectionEdit();
    final uri = Uri.tryParse(value.trim());
    if (uri != null && navivoxIsEndpointScheme(uri.scheme)) {
      _scheme = navivoxHttpSchemeFromEndpointScheme(uri.scheme);
    } else {
      _scheme = 'http';
    }
  }

  Future<void> _confirmActiveGatewayHandoff() async {
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
      await _connectGateway(autoConnect: true);
    }
  }

  String _safeHandoffHostSummary() {
    final scheme = _scheme.trim().isEmpty ? 'http' : _scheme.trim();
    final host = _addressController.text.trim();
    final port = _portController.text.trim();
    if (host.isEmpty) return 'the new gateway';
    if (port.isEmpty) return '$scheme://$host';
    return '$scheme://$host:$port';
  }

  Future<void> _connectGateway({bool autoConnect = false}) async {
    const presentation = GatewayConnectionPresentation();
    final validationError = presentation.validateAddressAndPort(
      address: _addressController.text,
      port: _portController.text,
      scheme: _scheme,
    );
    if (validationError != null) {
      setState(() {
        _notice = _setupScreenPresentation.validationFailureNotice(
          validationError,
        );
      });
      return;
    }
    final request = presentation.connectRequestFromParts(
      address: _addressController.text,
      port: _portController.text,
      token: _tokenController.text,
      scheme: _scheme,
      webSocketUrl: _webSocketUrl,
    );

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
          () => _notice = autoConnect && _handoffFlow.isDirectAppOpen
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
