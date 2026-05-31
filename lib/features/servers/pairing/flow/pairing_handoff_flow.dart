import '../../../../core/channel/navivox_channel.dart';
import '../../../../router/navigation_intent.dart';
import '../../models/connection_import.dart';
import '../contracts/pairing_handoff_manual_edit.dart';
import '../landing/pairing_handoff_landing.dart';

class PairingHandoffFlow {
  const PairingHandoffFlow({
    this.landing = const PairingHandoffLanding(),
    this.source = PairingHandoffSource.manual,
  });

  factory PairingHandoffFlow.fromImport(SetupQrImageImport import) {
    return PairingHandoffFlow(
      landing: PairingHandoffLanding(
        serverId: import.serverId,
        profileId: import.profileId,
      ),
      source: import.source,
    );
  }

  final PairingHandoffLanding landing;
  final PairingHandoffSource source;

  bool get isDirectAppOpen => source == PairingHandoffSource.directAppOpen;

  bool shouldAutoConnect({required bool hasActiveGateway}) {
    return isDirectAppOpen && !hasActiveGateway;
  }

  bool requiresActiveGatewayConfirmation({required bool hasActiveGateway}) {
    return hasActiveGateway;
  }

  String safeSourceLabel() {
    return switch (source) {
      PairingHandoffSource.directAppOpen => 'pairing link',
      PairingHandoffSource.qrImage => 'QR image',
      PairingHandoffSource.sharedText => 'shared text',
      PairingHandoffSource.manual => 'manual entry',
    };
  }

  PairingHandoffFlow applyManualConnectionEdit(PairingHandoffManualEdit edit) {
    if (pairingHandoffManualEditClearsImportedTarget(edit)) {
      return const PairingHandoffFlow();
    }
    return this;
  }

  PairingHandoffFlow resetManualConnectionEdit() {
    return applyManualConnectionEdit(PairingHandoffManualEdit.address);
  }

  PairingHandoffConnectOutcome afterConnect(NavivoxChannelState state) {
    final contact = landing.reportedProfileContact(state);
    return PairingHandoffConnectOutcome(
      profileContactToSelect: contact,
      navigationIntent: landing.navigationIntentAfterConnect(state),
    );
  }
}

class PairingHandoffConnectOutcome {
  const PairingHandoffConnectOutcome({
    required this.profileContactToSelect,
    required this.navigationIntent,
  });

  final NavivoxProfileContact? profileContactToSelect;
  final NavigationIntent navigationIntent;
}
