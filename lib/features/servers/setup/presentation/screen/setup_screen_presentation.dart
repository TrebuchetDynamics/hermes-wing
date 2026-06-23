import '../../../../../core/protocol/navivox_json.dart';
import '../../../models/connection_import.dart';
import '../../../shared/setup_screen_notice.dart';

export '../../../shared/setup_screen_notice.dart';

class SetupScreenPresentation {
  const SetupScreenPresentation();

  String get title => 'Connect to Gormes';

  String get pairingInstructions =>
      'Run `gormes navivox pair`, then scan the QR or open the pairing link.';

  String get networkHint =>
      'Android emulator: use http://10.0.2.2:<port> for a host gateway. '
      'On a physical Android device, use the host LAN, VPN, or Tailscale '
      'URL from connect-info.';

  String get urlFieldLabel => 'Gateway URL';

  String get urlFieldSemanticLabel => 'Gateway URL field';

  String get urlFieldSemanticHint =>
      'Enter the Gormes gateway URL, for example http://127.0.0.1:8765.';

  String get enterManuallyLabel => 'Enter manually';

  String get tokenFieldLabel => 'Pairing token';

  String get tokenFieldSemanticLabel => 'Pairing token field';

  String get tokenFieldSemanticHint =>
      'Enter the pairing token printed by Gormes.';

  String get importQrButtonLabel => 'Scan or import QR';

  String tokenVisibilityLabel({required bool showToken}) {
    return showToken ? 'Hide pairing token' : 'Show pairing token';
  }

  String get connectButtonLabel => 'Connect and talk';

  String get connectButtonSemanticHint => 'Connect to Gormes and open chat.';

  SetupPairingReadinessPresentation pairingReadiness({
    required bool connecting,
    required bool connectedSession,
    required PairingHandoffSource source,
    required bool hasError,
  }) {
    if (connecting) {
      return const SetupPairingReadinessPresentation(
        status: SetupPairingReadinessStatus.connecting,
        statusLabel: 'Connecting to Gormes',
        message:
            'Navivox is checking the gateway with the current pairing details.',
      );
    }
    if (hasError) {
      return const SetupPairingReadinessPresentation(
        status: SetupPairingReadinessStatus.failedRetry,
        statusLabel: 'Pairing needs attention',
        message:
            'Pairing did not complete. Review the message below, keep Gormes pairing open, then retry.',
      );
    }
    if (source != PairingHandoffSource.manual) {
      final sourceLabel = _safePairingHandoffSourceLabel(source);
      return SetupPairingReadinessPresentation(
        status: SetupPairingReadinessStatus.importedNeedsReview,
        statusLabel: 'Review imported handoff',
        message:
            'Connection details were imported from $sourceLabel. Review the gateway address below before connecting.',
      );
    }
    if (connectedSession) {
      return const SetupPairingReadinessPresentation(
        status: SetupPairingReadinessStatus.connectedSessionOnly,
        statusLabel: 'Connected for this app session',
        message:
            'Pairing succeeded for this app session. Durable reconnect is separate and not saved by this step.',
      );
    }
    return const SetupPairingReadinessPresentation(
      status: SetupPairingReadinessStatus.manual,
      statusLabel: 'Ready for pairing details',
      message:
          'Use a Gormes pairing link, or tap Enter manually below to type the gateway URL and token.',
    );
  }

  SetupScreenNotice qrImportNotice(SetupQrImageImport? result) {
    if (result == null || !result.hasValues) {
      return const SetupScreenNotice.info('No QR image selected.');
    }
    return const SetupScreenNotice.info('Imported QR connection details.');
  }

  SetupScreenNotice get connectIntentImportNotice =>
      const SetupScreenNotice.info('Imported Navivox connection link.');

  SetupScreenNotice qrImportFailureNotice([String? detail]) {
    return SetupScreenNotice.error(
      _safeDetailOrFallback(detail, 'Could not read a Navivox QR image.'),
    );
  }

  SetupScreenNotice validationFailureNotice(String message) {
    return SetupScreenNotice.error(message);
  }

  SetupScreenNotice get connectFailureNotice => const SetupScreenNotice.error(
    'Could not connect to Gormes gateway.',
    recoveryMessage:
        'Run `gormes navivox status`; if it is not listening, run `gormes navivox pair`, keep it open, then retry. Use `connect-info` for LAN/VPN/Tailscale URLs.',
  );

  SetupScreenNotice
  get directPairingConnectFailureNotice => const SetupScreenNotice.error(
    'Could not connect from the pairing link.',
    recoveryMessage:
        'Keep `gormes navivox pair` running, then retry. If this device cannot reach that URL, import the QR image or use `connect-info`.',
  );

  SetupScreenNotice get autoConnectNotice =>
      const SetupScreenNotice.info('Connecting from pairing link…');

  String activeGatewayConfirmationTitle(String sourceLabel) {
    return 'Review new $sourceLabel';
  }

  String activeGatewayConfirmationMessage(String hostSummary) {
    return 'Navivox is already connected. Connect to $hostSummary instead?';
  }

  String handoffHostSummary({
    required String scheme,
    required String address,
    required String port,
  }) {
    final normalizedScheme = scheme.trim().isEmpty ? 'http' : scheme.trim();
    final host = _hostForAuthority(address.trim());
    final normalizedPort = port.trim();
    if (host.isEmpty) return 'the new gateway';
    if (normalizedPort.isEmpty) return '$normalizedScheme://$host';
    return '$normalizedScheme://$host:$normalizedPort';
  }

  String get activeGatewayConfirmButtonLabel => 'Connect to new gateway';

  String get activeGatewayCancelButtonLabel => 'Keep current gateway';

  SetupScreenNotice get connectSuccessNotice =>
      const SetupScreenNotice.info('Connected for this app session.');

  String get connectCommandExplanation =>
      'This command starts the Gormes gateway and prints a connection URL '
      'or QR code. Scan the QR with Navivox to pair, or copy the connection '
      'URL shown in your terminal. Pairing starts this app session; durable '
      'reconnect will require a future secure credential.';
}

enum SetupPairingReadinessStatus {
  manual,
  importedNeedsReview,
  connecting,
  connectedSessionOnly,
  failedRetry,
}

class SetupPairingReadinessPresentation {
  const SetupPairingReadinessPresentation({
    required this.status,
    required this.statusLabel,
    required this.message,
  });

  final SetupPairingReadinessStatus status;
  final String statusLabel;
  final String message;

  String get title => 'Pairing readiness';
}

String _safePairingHandoffSourceLabel(PairingHandoffSource source) {
  return switch (source) {
    PairingHandoffSource.directAppOpen => 'a pairing link',
    PairingHandoffSource.qrImage => 'a QR image',
    PairingHandoffSource.sharedText => 'shared text',
    PairingHandoffSource.manual => 'manual entry',
  };
}

String _hostForAuthority(String host) {
  if (_looksLikeBareIpv6Address(host)) return '[$host]';
  return host;
}

bool _looksLikeBareIpv6Address(String value) {
  if (value.startsWith('[') || value.endsWith(']')) return false;
  return ':'.allMatches(value).length > 1;
}

String _safeDetailOrFallback(String? detail, String fallback) {
  final text = navivoxOptionalStringFromJson(detail);
  if (text == null) return fallback;
  if (text.toLowerCase().contains('nvbx_')) return fallback;
  return text;
}
