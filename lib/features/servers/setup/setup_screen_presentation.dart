import 'setup_qr_import_presentation.dart';

class SetupScreenPresentation {
  const SetupScreenPresentation();

  String get title => 'Connect to Gormes';

  String get pairingInstructions =>
      'Run `gormes navivox pair`. On Android, Gormes can open Navivox '
      'directly; QR/import and `gormes navivox connect-info` are fallbacks. '
      'Pairing signs in for this app session. Durable reconnect is not saved '
      'yet; pair again if Navivox cannot reconnect after restart.';

  String get networkHint =>
      'Android emulator: use http://10.0.2.2:<port> for a host gateway. '
      'On a physical Android device, use the host LAN, VPN, or Tailscale '
      'URL from connect-info.';

  String get addressFieldLabel => 'Gateway address';

  String get addressFieldSemanticLabel => 'Gateway address field';

  String get addressFieldSemanticHint =>
      'Enter the Gormes gateway host or address.';

  String get portFieldLabel => 'Port';

  String get portFieldSemanticLabel => 'Gateway port field';

  String get portFieldSemanticHint => 'Enter the Gormes gateway port.';

  String get tokenFieldLabel => 'Pairing token';

  String get tokenFieldSemanticLabel => 'Pairing token field';

  String get tokenFieldSemanticHint =>
      'Enter the pairing token printed by Gormes.';

  String get importQrButtonLabel => 'Import QR image';

  String get fixInstructionsButtonLabel => 'Copy fix instructions';

  String tokenVisibilityLabel({required bool showToken}) {
    return showToken ? 'Hide pairing token' : 'Show pairing token';
  }

  String get connectButtonLabel => 'Connect and talk';

  String get connectButtonSemanticHint => 'Connect to Gormes and open chat.';

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

class SetupScreenNotice {
  const SetupScreenNotice._({
    required this.kind,
    required this.message,
    this.recoveryMessage,
  });

  const SetupScreenNotice.info(String message)
    : this._(kind: SetupScreenNoticeKind.info, message: message);

  const SetupScreenNotice.error(String message, {String? recoveryMessage})
    : this._(
        kind: SetupScreenNoticeKind.error,
        message: message,
        recoveryMessage: recoveryMessage,
      );

  final SetupScreenNoticeKind kind;
  final String message;
  final String? recoveryMessage;

  bool get isError => kind == SetupScreenNoticeKind.error;
}

enum SetupScreenNoticeKind { info, error }

String _safeDetailOrFallback(String? detail, String fallback) {
  final text = detail?.trim();
  if (text == null || text.isEmpty) return fallback;
  if (text.toLowerCase().contains('nvbx_')) return fallback;
  return text;
}
