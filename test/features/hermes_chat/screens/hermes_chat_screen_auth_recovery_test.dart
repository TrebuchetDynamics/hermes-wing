import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:wing/core/hermes/local_discovery/local_hermes_home_discovery.dart';
import 'package:wing/features/hermes_chat/widgets/platform_local_connection_panel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';

import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';

void main() {
  testWidgets('superseded endpoint save cannot disconnect a newer attempt', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final channel = FakeHermesChannel.disconnected();
    final store = _DeferredSaveEndpointStore();
    addTearDown(channel.dispose);
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
    await tester.tap(
      find.byKey(const ValueKey('hermes-connection-mode-local')),
    );
    await tester.pump();
    final skip = find.byKey(const ValueKey('platform-local-skip-guide'));
    await tester.ensureVisible(skip);
    await tester.tap(skip);
    await tester.pumpAndSettle();
    final connect = tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('hermes-connect-button')),
        )
        .onPressed!;
    connect();
    await tester.pump();
    expect(store.pending, hasLength(1));
    // A queued second action supersedes the attempt while its credential save
    // is pending, even when the selected endpoint is unchanged.
    connect();
    await tester.pump();
    expect(store.pending, hasLength(2));
    final disconnects = channel.disconnectCalls;
    store.pending.first.complete();
    await tester.pump();
    expect(channel.disconnectCalls, disconnects);
    expect(channel.state.status, HermesConnectionStatus.connected);
    store.pending.last.complete();
    await tester.pumpAndSettle();
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('connection failures are announced as a live region', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final semantics = tester.ensureSemantics();
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.disconnected,
      connectErrorMessage: 'SocketException: private transport detail',
    );
    addTearDown(channel.dispose);
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
          home: HermesChatScreen(initiallyEditingConnection: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('hermes-connection-mode-local')),
    );
    await tester.pump();
    final skip = find.byKey(const ValueKey('platform-local-skip-guide'));
    await tester.ensureVisible(skip);
    await tester.tap(skip);
    await tester.pumpAndSettle();
    final connect = find.byKey(const ValueKey('hermes-connect-button'));
    await tester.ensureVisible(connect);
    await tester.tap(connect);
    await tester.pumpAndSettle();

    final error = find.byKey(const ValueKey('hermes-connect-error'));
    expect(error, findsOneWidget);
    expect(tester.getSemantics(error).flagsCollection.isLiveRegion, isTrue);
    expect(find.textContaining('private transport'), findsNothing);
    semantics.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('typed connection auth failure ignores platform wording', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.error,
      errorMessage: 'opaque transport failure',
      connectionFailureKind: HermesConnectionFailureKind.authentication,
    );
    addTearDown(channel.dispose);

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
          home: HermesChatScreen(initiallyEditingConnection: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hermes API rejected the API key.'), findsOneWidget);
    expect(find.textContaining('opaque transport'), findsNothing);
  });

  testWidgets('typed invalid endpoint overrides auth-like wording', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.error,
      errorMessage: '401 platform wrapper',
      connectionFailureKind: HermesConnectionFailureKind.invalidEndpoint,
    );
    addTearDown(channel.dispose);

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
          home: HermesChatScreen(initiallyEditingConnection: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Check the Hermes address.'), findsOneWidget);
    expect(find.text('Hermes API rejected the API key.'), findsNothing);
    expect(find.textContaining('platform wrapper'), findsNothing);
  });

  testWidgets('typed TLS failure gives trust recovery guidance', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.error,
      errorMessage: 'opaque secure transport failure',
      connectionFailureKind: HermesConnectionFailureKind.tls,
    );
    addTearDown(channel.dispose);

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
          home: HermesChatScreen(initiallyEditingConnection: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Secure connection to Hermes failed.'), findsOneWidget);
    expect(find.textContaining('Re-pair explicitly'), findsOneWidget);
    expect(find.textContaining('opaque secure'), findsNothing);
  });

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
          // Exercise direct-channel recovery without saved-directory routing.
          hermesGatewayDirectoryProvider.overrideWith(
            (ref) => HermesGatewayDirectory(
              store: FakeHermesEndpointStore(),
              cache: GatewayContactCache(),
              loader: const HermesApiGatewaySummaryLoader(),
              activeChannel: channel,
            ),
          ),
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
          // Exercise direct-channel recovery without saved-directory routing.
          hermesGatewayDirectoryProvider.overrideWith(
            (ref) => HermesGatewayDirectory(
              store: FakeHermesEndpointStore(),
              cache: GatewayContactCache(),
              loader: const HermesApiGatewaySummaryLoader(),
              activeChannel: channel,
            ),
          ),
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
          // Exercise direct-channel recovery without saved-directory routing.
          hermesGatewayDirectoryProvider.overrideWith(
            (ref) => HermesGatewayDirectory(
              store: FakeHermesEndpointStore(),
              cache: GatewayContactCache(),
              loader: const HermesApiGatewaySummaryLoader(),
              activeChannel: channel,
            ),
          ),
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

  testWidgets('Add Hermes groups VPN within three primary connection choices', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          platformLocalHomeDiscoveryProvider.overrideWithValue(
            _MetadataDiscovery(),
          ),
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
      find.byKey(const ValueKey('hermes-remote-transport-vpn')),
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
    expect(find.text('Remote'), findsOneWidget);
    expect(find.text('Remote HTTPS'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('hermes-primary-connection-modes')),
        matching: find.byType(ChoiceChip),
      ),
      findsNWidgets(3),
    );
    expect(find.text('VPN / NetBird / Tailscale'), findsOneWidget);
    expect(
      find.textContaining('authenticated WebSocket support waits'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('hermes-connection-mode-local')),
    );
    await tester.pump();
    final advanced = find.byKey(
      const ValueKey('platform-local-advanced-endpoint'),
    );
    await tester.ensureVisible(advanced);
    await tester.tap(advanced);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('hermes-base-url-field')),
          )
          .controller
          ?.text,
      'http://127.0.0.1:8642',
    );

    final ssh = find.byKey(const ValueKey('hermes-connection-mode-ssh'));
    await tester.ensureVisible(ssh);
    await tester.tap(ssh);
    await tester.pumpAndSettle();
    for (final field in [
      'host',
      'ssh-port',
      'username',
      'password',
      'agent-port',
      'agent-token',
    ]) {
      expect(find.byKey(ValueKey('managed-ssh-$field')), findsOneWidget);
    }
    for (final secret in ['password', 'agent-token']) {
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(ValueKey('managed-ssh-$secret')),
                matching: find.byType(TextField),
              ),
            )
            .obscureText,
        isTrue,
      );
    }
    debugDefaultTargetPlatformOverride = null;
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

class _MetadataDiscovery extends LocalHermesHomeDiscovery {
  @override
  Future<LocalHermesHomeInspection> inspectDefault() async =>
      const LocalHermesHomeInspection.directory('/synthetic/.hermes');
}

class _DeferredSaveEndpointStore extends FakeHermesEndpointStore {
  final pending = <Completer<void>>[];

  @override
  Future<void> save({
    required String baseUrl,
    String? apiKey,
    String? label,
    String? profileId,
    String? wingLinkOrigin,
    String? wingLinkToken,
    String? wingLinkPendingCredentialId,
    String? wingLinkHostFingerprint,
    String? wingLinkDeviceId,
  }) async {
    final gate = Completer<void>();
    pending.add(gate);
    await gate.future;
    await super.save(
      baseUrl: baseUrl,
      apiKey: apiKey,
      label: label,
      profileId: profileId,
      wingLinkOrigin: wingLinkOrigin,
      wingLinkToken: wingLinkToken,
      wingLinkPendingCredentialId: wingLinkPendingCredentialId,
      wingLinkHostFingerprint: wingLinkHostFingerprint,
      wingLinkDeviceId: wingLinkDeviceId,
    );
  }
}
