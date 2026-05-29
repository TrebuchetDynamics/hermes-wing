import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/servers/setup/setup_qr_import_presentation.dart';
import 'package:navivox/features/servers/setup/setup_screen_presentation.dart';

void main() {
  const presentation = SetupScreenPresentation();

  test('centralizes first-run setup field and action copy', () {
    expect(presentation.title, 'Connect to Gormes');
    expect(presentation.pairingInstructions, contains('gormes navivox pair'));
    expect(
      presentation.pairingInstructions,
      contains('gormes navivox connect-info'),
    );
    expect(presentation.pairingInstructions, contains('this app session'));
    expect(
      presentation.pairingInstructions,
      contains('Durable reconnect is not saved'),
    );
    expect(presentation.networkHint, contains('10.0.2.2'));
    expect(presentation.addressFieldLabel, 'Gateway address');
    expect(presentation.addressFieldSemanticLabel, 'Gateway address field');
    expect(presentation.addressFieldSemanticHint, contains('Gormes gateway'));
    expect(presentation.portFieldLabel, 'Port');
    expect(presentation.portFieldSemanticLabel, 'Gateway port field');
    expect(presentation.portFieldSemanticHint, contains('Gormes gateway port'));
    expect(presentation.tokenFieldLabel, 'Pairing token');
    expect(presentation.tokenFieldSemanticLabel, 'Pairing token field');
    expect(presentation.tokenFieldSemanticHint, contains('printed by Gormes'));
    expect(presentation.importQrButtonLabel, 'Import QR image');
    expect(presentation.fixInstructionsButtonLabel, 'Copy fix instructions');
    expect(presentation.connectButtonLabel, 'Connect and talk');
    expect(presentation.connectButtonSemanticHint, contains('open chat'));
  });

  test('centralizes active-gateway handoff confirmation copy', () {
    expect(
      presentation.activeGatewayConfirmationTitle('pairing link'),
      'Review new pairing link',
    );
    expect(
      presentation.activeGatewayConfirmationMessage(
        'https://gateway.example:8765',
      ),
      'Navivox is already connected. Connect to https://gateway.example:8765 instead?',
    );
    expect(
      presentation.activeGatewayConfirmButtonLabel,
      'Connect to new gateway',
    );
    expect(presentation.activeGatewayCancelButtonLabel, 'Keep current gateway');
  });

  test('centralizes token visibility labels', () {
    expect(
      presentation.tokenVisibilityLabel(showToken: false),
      'Show pairing token',
    );
    expect(
      presentation.tokenVisibilityLabel(showToken: true),
      'Hide pairing token',
    );
  });

  test('turns QR import outcomes into info notices without leaking tokens', () {
    final skipped = presentation.qrImportNotice(null);
    expect(skipped.kind, SetupScreenNoticeKind.info);
    expect(skipped.message, 'No QR image selected.');
    expect(skipped.recoveryMessage, isNull);

    final imported = presentation.qrImportNotice(
      const SetupQrImageImport(
        baseUrl: 'http://127.0.0.1:8765',
        token: 'nvbx_secret_should_not_render',
      ),
    );
    expect(imported.kind, SetupScreenNoticeKind.info);
    expect(imported.message, 'Imported QR connection details.');
    expect(imported.message, isNot(contains('nvbx_secret_should_not_render')));
    expect(imported.recoveryMessage, isNull);
  });

  test('keeps connect recovery guidance attached only to connect failures', () {
    final validation = presentation.validationFailureNotice(
      'Use http, https, ws, or wss.',
    );
    expect(validation.kind, SetupScreenNoticeKind.error);
    expect(validation.message, 'Use http, https, ws, or wss.');
    expect(validation.recoveryMessage, isNull);

    final connect = presentation.connectFailureNotice;
    expect(connect.kind, SetupScreenNoticeKind.error);
    expect(connect.message, 'Could not connect to Gormes gateway.');
    expect(connect.recoveryMessage, contains('gormes navivox status'));
    expect(connect.recoveryMessage, contains('gormes navivox pair'));
    expect(connect.recoveryMessage, contains('connect-info'));
    expect(connect.recoveryMessage, isNot(contains('nvbx_')));

    final direct = presentation.directPairingConnectFailureNotice;
    expect(direct.kind, SetupScreenNoticeKind.error);
    expect(direct.message, 'Could not connect from the pairing link.');
    expect(direct.recoveryMessage, contains('gormes navivox pair'));
    expect(direct.recoveryMessage, contains('connect-info'));
    expect(direct.recoveryMessage, isNot(contains('nvbx_')));
  });

  test('uses specific QR errors but falls back rather than leaking tokens', () {
    final unsupported = presentation.qrImportFailureNotice(
      'QR image import is not supported on this platform.',
    );
    expect(unsupported.kind, SetupScreenNoticeKind.error);
    expect(
      unsupported.message,
      'QR image import is not supported on this platform.',
    );

    final tokenBearing = presentation.qrImportFailureNotice(
      'Could not read token nvbx_secret_should_not_render.',
    );
    expect(tokenBearing.message, 'Could not read a Navivox QR image.');
    expect(
      tokenBearing.message,
      isNot(contains('nvbx_secret_should_not_render')),
    );
  });
}
