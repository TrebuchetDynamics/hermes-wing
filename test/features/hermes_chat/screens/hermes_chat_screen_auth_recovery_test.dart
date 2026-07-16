import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';

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
      connectedBaseUrl: 'http://hermes.tailnet.example:8642',
    );
    final store = FakeHermesEndpointStore(
      initial: const HermesEndpointConfig(
        id: 'vpn',
        baseUrl: 'http://hermes.tailnet.example:8642',
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
      'http://hermes.tailnet.example:8642',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('hermes-api-key-field')))
          .controller
          ?.text,
      isEmpty,
    );
  });

  testWidgets('profile labels persist and presets clear secret fields', (
    tester,
  ) async {
    final channel = FakeHermesChannel.disconnected();
    final store = FakeHermesEndpointStore();

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

    expect(find.text('Connect to your Hermes VPS'), findsOneWidget);
    expect(find.text('VPS connection'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('hermes-base-url-field')),
          )
          .controller
          ?.text,
      isEmpty,
    );
    expect(
      find.textContaining('stored in secure device storage'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('hermes-connect-button')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('hermes-api-key-field')))
          .obscureText,
      isTrue,
    );
    await tester.tap(find.byKey(const ValueKey('hermes-api-key-visibility')));
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('hermes-api-key-field')))
          .obscureText,
      isFalse,
    );

    await tester.enterText(
      find.byKey(const ValueKey('hermes-api-key-field')),
      'private-key',
    );
    await tester.enterText(
      find.byKey(const ValueKey('hermes-profile-label-field')),
      'Local agent',
    );
    final developerShortcuts = find.byKey(
      const ValueKey('hermes-developer-shortcuts'),
    );
    await tester.ensureVisible(developerShortcuts);
    await tester.tap(developerShortcuts);
    await tester.pumpAndSettle();
    final clearServerDetails = find.byKey(
      const ValueKey('hermes-preset-remote'),
    );
    await tester.ensureVisible(clearServerDetails);
    await tester.tap(clearServerDetails);
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('hermes-api-key-field')))
          .controller
          ?.text,
      isEmpty,
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('hermes-profile-label-field')),
          )
          .controller
          ?.text,
      isEmpty,
    );

    await tester.enterText(
      find.byKey(const ValueKey('hermes-base-url-field')),
      'http://127.0.0.1:8642',
    );
    await tester.enterText(
      find.byKey(const ValueKey('hermes-profile-label-field')),
      'Local agent',
    );
    final connectButton = find.byKey(const ValueKey('hermes-connect-button'));
    expect(tester.widget<FilledButton>(connectButton).onPressed, isNotNull);
    tester.widget<FilledButton>(connectButton).onPressed?.call();
    await tester.pumpAndSettle();

    expect(store.saveCalls.single.label, 'Local agent');
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
