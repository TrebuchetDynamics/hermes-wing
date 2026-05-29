import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/features/servers/pairing/pairing_handoff_flow.dart';
import 'package:navivox/features/servers/setup/setup_qr_import_presentation.dart';
import 'package:navivox/router/navigation_intent.dart';

void main() {
  const mineru = NavivoxProfileContact(
    serverId: 'local',
    profileId: 'mineru',
    displayName: 'Mineru',
    serverLabel: 'Local',
    health: NavivoxProfileHealth.online,
    latestPreview: 'Ready',
  );

  test('carries imported Profile contact target through connect success', () {
    final flow = PairingHandoffFlow.fromImport(
      const SetupQrImageImport(
        baseUrl: 'http://127.0.0.1:8765',
        token: 'nvbx_secret',
        serverId: 'local',
        profileId: 'mineru',
      ),
    );

    final outcome = flow.afterConnect(
      const NavivoxChannelState(profileContacts: [mineru]),
    );

    expect(outcome.profileContactToSelect, mineru);
    expect(
      outcome.navigationIntent,
      isA<OpenChatThread>()
          .having((intent) => intent.serverId, 'serverId', 'local')
          .having((intent) => intent.profileId, 'profileId', 'mineru'),
    );
  });

  test(
    'auto-connects only direct app-open handoffs without an active gateway',
    () {
      final direct = PairingHandoffFlow.fromImport(
        const SetupQrImageImport(
          baseUrl: 'http://127.0.0.1:8765',
          token: 'nvbx_secret',
          source: PairingHandoffSource.directAppOpen,
        ),
      );
      final shared = PairingHandoffFlow.fromImport(
        const SetupQrImageImport(
          baseUrl: 'http://127.0.0.1:8765',
          token: 'nvbx_secret',
          source: PairingHandoffSource.sharedText,
        ),
      );

      expect(direct.shouldAutoConnect(hasActiveGateway: false), isTrue);
      expect(direct.shouldAutoConnect(hasActiveGateway: true), isFalse);
      expect(shared.shouldAutoConnect(hasActiveGateway: false), isFalse);
    },
  );

  test('requires confirmation for every handoff when gateway is active', () {
    final direct = PairingHandoffFlow.fromImport(
      const SetupQrImageImport(source: PairingHandoffSource.directAppOpen),
    );
    final qr = PairingHandoffFlow.fromImport(
      const SetupQrImageImport(source: PairingHandoffSource.qrImage),
    );

    expect(
      direct.requiresActiveGatewayConfirmation(hasActiveGateway: true),
      isTrue,
    );
    expect(
      qr.requiresActiveGatewayConfirmation(hasActiveGateway: true),
      isTrue,
    );
    expect(
      direct.requiresActiveGatewayConfirmation(hasActiveGateway: false),
      isFalse,
    );
    expect(direct.safeSourceLabel(), 'pairing link');
  });

  test('resets imported landing target after manual connection edit', () {
    final flow = PairingHandoffFlow.fromImport(
      const SetupQrImageImport(
        baseUrl: 'http://127.0.0.1:8765',
        token: 'nvbx_secret',
        serverId: 'local',
        profileId: 'mineru',
      ),
    ).resetManualConnectionEdit();

    final outcome = flow.afterConnect(
      const NavivoxChannelState(profileContacts: [mineru]),
    );

    expect(outcome.profileContactToSelect, isNull);
    expect(outcome.navigationIntent, isA<OpenChatsList>());
  });
}
