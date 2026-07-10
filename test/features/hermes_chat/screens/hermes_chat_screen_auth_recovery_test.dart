import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navivox/core/hermes/channel/hermes_channel.dart';
import 'package:navivox/core/hermes/models/hermes_session.dart';
import 'package:navivox/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:navivox/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:navivox/features/hermes_chat/screens/hermes_chat_screen.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';

void main() {
  testWidgets('auth failures ask for a new key without deleting VPN profile', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      errorMessage: 'HTTP 401 unauthorized invalid API key',
      sessions: const [
        HermesSession(id: 'vpn-session', source: 'fake', title: 'VPN session'),
      ],
      activeSessionId: 'vpn-session',
      connectedBaseUrl: 'http://100.108.109.96:8642',
    );
    final store = FakeHermesEndpointStore(
      initial: const HermesEndpointConfig(
        id: 'vpn',
        baseUrl: 'http://100.108.109.96:8642',
        apiKey: 'old-key',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(store),
        ],
        child: const MaterialApp(home: HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Update key'), findsOneWidget);
    expect(find.text('Reconnect'), findsNothing);

    await tester.tap(find.text('Update key'));
    await tester.pumpAndSettle();

    expect(store.clearCalls, 0);
    expect(find.byKey(const ValueKey('hermes-connect-button')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('hermes-base-url-field')),
          )
          .controller
          ?.text,
      'http://100.108.109.96:8642',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('hermes-api-key-field')))
          .controller
          ?.text,
      isEmpty,
    );
  });

  testWidgets('approval failures remain visible to the operator', (
    tester,
  ) async {
    final channel = FakeHermesChannel(approvalResponsesFail: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(
            FakeHermesEndpointStore(),
          ),
        ],
        child: const MaterialApp(home: HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    channel.emitApprovalRequest(
      const HermesApprovalRequest(
        id: 'approval-1',
        toolCallId: 'tool-1',
        prompt: 'Run a command?',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hermes-approval-deny')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Could not answer Hermes approval'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('hermes-approval-deny')), findsOneWidget);
  });
}
