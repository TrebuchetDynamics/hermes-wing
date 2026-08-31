import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/l10n/app_localizations.dart';
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
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(),
        ),
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

  testWidgets('reconnect keeps the saved key for an equivalent endpoint URL', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      errorMessage: 'stream disconnected',
      connectedBaseUrl: 'https://hermes.example.com',
    );
    final store = FakeHermesEndpointStore(
      initial: const HermesEndpointConfig(
        baseUrl: 'https://hermes.example.com/',
        apiKey: 'saved-agent-key',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(store),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hermes-chat-error-reconnect')));
    await tester.pumpAndSettle();

    expect(channel.connectCalls.last.baseUrl, 'https://hermes.example.com');
    expect(channel.connectCalls.last.apiKey, 'saved-agent-key');
  });

  testWidgets('reconnect ignores duplicate taps while an attempt is pending', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      errorMessage: 'stream disconnected',
      connectedBaseUrl: 'https://hermes.example.com',
    );
    final store = FakeHermesEndpointStore(
      initial: const HermesEndpointConfig(
        baseUrl: 'https://hermes.example.com',
        apiKey: 'saved-agent-key',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(store),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final reconnect = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('hermes-chat-error-reconnect')),
    );
    reconnect.onPressed!();
    reconnect.onPressed!();
    await tester.pumpAndSettle();

    expect(channel.connectCalls, hasLength(1));
  });

  testWidgets('deleting an endpoint clears an equivalent normalized form URL', (
    tester,
  ) async {
    final channel = FakeHermesChannel.disconnected();
    final store = FakeHermesEndpointStore(
      profiles: const [
        HermesEndpointConfig(
          id: 'saved',
          baseUrl: 'https://hermes.example.com/',
          apiKey: 'saved-agent-key',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(store),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(initiallyEditingConnection: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final profileChip = tester.widget<InputChip>(
      find.byKey(const ValueKey('hermes-endpoint-profile-saved')),
    );
    profileChip.onDeleted!();
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('hermes-endpoint-profile-delete-confirm')),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('hermes-base-url-field')),
          )
          .controller
          ?.text,
      isEmpty,
    );
  });

  testWidgets('Add Hermes shows safe local, remote, VPN, and SSH choices', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(FakeHermesChannel()),
          hermesEndpointStoreProvider.overrideWithValue(
            FakeHermesEndpointStore(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(initiallyEditingConnection: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add Hermes'), findsAtLeastNWidgets(1));
    expect(
      find.byKey(const ValueKey('hermes-connection-mode-local')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hermes-connection-mode-remote')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hermes-connection-mode-vpn')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hermes-connection-mode-ssh')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hermes-credential-boundary')),
      findsOneWidget,
    );
    expect(find.text('Remote HTTPS'), findsOneWidget);
    expect(
      find.textContaining('authenticated WebSocket support waits'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('hermes-connection-mode-local')),
    );
    await tester.pump();
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('hermes-base-url-field')),
          )
          .controller
          ?.text,
      'http://127.0.0.1:8642',
    );

    await tester.tap(find.byKey(const ValueKey('hermes-connection-mode-ssh')));
    await tester.pump();
    expect(
      find.textContaining('never runs arbitrary SSH commands'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Start the fixed tunnel outside Wing'),
      findsOneWidget,
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
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(),
        ),
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
