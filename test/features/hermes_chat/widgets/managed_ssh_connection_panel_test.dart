import 'dart:async';
import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import '../ssh_keys/synthetic_ssh_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/widgets/managed_ssh_connection_panel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/hermes_api.dart';
import 'package:wing/core/hermes/setup/secure_hermes_serve_recovery_store.dart';
import 'package:wing/core/hermes/ssh/managed_ssh.dart';
import 'package:wing/features/hermes_chat/providers/managed_ssh_connection_controller.dart';
import 'package:wing/core/hermes/ssh/ssh_connection_request.dart';

const input = SshConnectionRequest(
  host: 'example.invalid',
  sshPort: 22,
  username: 'tester',
  password: 'synthetic-password',
  agentPort: 8642,
  agentBearerToken: 'synthetic-agent-token',
);

class FakeChannel extends ChangeNotifier implements HermesChannel {
  @override
  Stream<HermesApprovalRequest> get approvalRequests => const Stream.empty();
  @override
  HermesChannelState state = const HermesChannelState();
  String? token;
  int disconnects = 0;
  Completer<void>? pending;
  bool fail = false;
  void set(HermesChannelState value) {
    state = value;
    notifyListeners();
  }

  @override
  Future<void> connect({
    required String baseUrl,
    String? apiKey,
    bool deferSessionSelection = false,
  }) async {
    token = apiKey;
    set(const HermesChannelState(status: HermesConnectionStatus.connecting));
    if (pending != null) await pending!.future;
    if (fail) throw StateError('sensitive exception');
    set(
      HermesChannelState(
        status: HermesConnectionStatus.connected,
        connectedBaseUrl: baseUrl,
      ),
    );
  }

  @override
  Future<void> disconnect() async {
    disconnects++;
    set(const HermesChannelState());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _HeldClearStore implements HermesServeRecoveryStore {
  final entered = Completer<void>();
  final release = Completer<void>();
  @override
  Future<void> clear() async {
    if (!entered.isCompleted) {
      entered.complete();
      await release.future;
    }
  }

  @override
  Future<HermesServeRecoverySelection?> load() async => null;
  @override
  Future<void> save(HermesServeRecoverySelection selection) async {}
}

class FakeForward extends ManagedSshForward {
  var waiting = Completer<ManagedSshTunnel>();
  ManagedSshHostKeyVerifier? verify;
  ManagedSshConfig? config;
  ManagedSshCredentials? credentials;
  int stops = 0;
  int closes = 0;
  final ended = Completer<void>();
  @override
  Future<ManagedSshTunnel> connect({
    required ManagedSshConfig configuration,
    required ManagedSshCredentials authentication,
    ManagedSshHostKeyVerifier? verifyHostKey,
    Duration timeout = const Duration(seconds: 20),
  }) {
    credentials = authentication;
    config = configuration;
    verify = verifyHostKey;
    return waiting.future;
  }

  void ready() => waiting.complete(
    ManagedSshTunnel(
      agentUri: Uri.parse('http://127.0.0.1:45678'),
      done: ended.future,
      close: () async {
        closes++;
      },
    ),
  );
  @override
  Future<void> disconnect() async {
    stops++;
  }
}

class _ServeReadChannel extends HermesApiChannel {
  _ServeReadChannel({required this.forwarded});
  final bool forwarded;
  @override
  bool get canEnableLocalServeChat => !forwarded;
  @override
  HermesChannelState get state => const HermesChannelState(
    status: HermesConnectionStatus.connected,
    isServeReadOnly: true,
    connectedBaseUrl: 'http://127.0.0.1:45678',
    selectedProfileId: 'default',
    activeSessionId: 'synthetic-session',
  );
}

void main() {
  for (final cleanupFails in [false, true]) {
    test(
      'Connect waits for cancelled lease teardown; cleanupFails=$cleanupFails',
      () async {
        final channel = FakeChannel();
        final forward = FakeForward();
        final controller = ManagedSshConnectionController(forward, channel);
        final closing = Completer<void>();
        final release = Completer<void>();
        final first = controller.connectSsh(
          input,
          verifyHostKey: (_, _) async => true,
        );
        forward.waiting.complete(
          ManagedSshTunnel(
            agentUri: Uri.parse('http://127.0.0.1:45678'),
            done: forward.ended.future,
            close: () async {
              closing.complete();
              await release.future;
              if (cleanupFails) throw StateError('Synthetic cleanup failure');
            },
          ),
        );
        expect(await first, isTrue);
        final cancellation = controller.cancel();
        await closing.future;
        final retiredCredentials = forward.credentials;
        forward.waiting = Completer<ManagedSshTunnel>();
        final duringCleanup = controller.connectSsh(
          input,
          verifyHostKey: (_, _) async => true,
        );
        expect(forward.credentials, same(retiredCredentials));
        expect(await duringCleanup, isFalse);
        final settled = cleanupFails
            ? expectLater(cancellation, throwsStateError)
            : cancellation;
        release.complete();
        await settled;
        final retry = controller.connectSsh(
          input,
          verifyHostKey: (_, _) async => true,
        );
        forward.ready();
        expect(await retry, isTrue);
        expect(channel.disconnects, 1);
        await controller.cancel();
        controller.dispose();
        channel.dispose();
      },
    );
  }

  test(
    'disposed controller rejects late Connect before acquiring credentials',
    () async {
      final channel = FakeChannel();
      final forward = FakeForward()..ready();
      final controller = ManagedSshConnectionController(forward, channel);
      addTearDown(channel.dispose);
      addTearDown(controller.cancel);
      controller.dispose();
      controller.dispose();

      expect(
        await controller.connectSsh(input, verifyHostKey: (_, _) async => true),
        isFalse,
      );
      expect(forward.config, isNull);
      expect(forward.credentials, isNull);
      expect(channel.token, isNull);
      expect(channel.state.isConnected, isFalse);
      expect(channel.disconnects, 0);
    },
  );

  for (final forwarded in [true, false]) {
    testWidgets(
      'serve chat entry respects forwarded read-only mode $forwarded',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final channel = _ServeReadChannel(forwarded: forwarded);
        final store = FakeHermesEndpointStore();
        final directory = HermesGatewayDirectory(
          store: store,
          cache: FakeGatewayContactCache(),
          loader: FakeGatewaySummaryLoader({}),
          activeChannel: channel,
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              hermesChannelProvider.overrideWithValue(channel),
              hermesEndpointStoreProvider.overrideWithValue(
                FakeHermesEndpointStore(),
              ),
              hermesGatewayDirectoryProvider.overrideWith((_) => directory),
              hermesVoiceCaptureServiceProvider.overrideWithValue(null),
              hermesTextToSpeechServiceProvider.overrideWithValue(null),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const HermesChatScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('hermes-local-serve-chat')),
          forwarded ? findsNothing : findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        channel.dispose();
      },
    );
  }

  Future<void> mount(
    WidgetTester tester,
    ManagedSshConnectionController controller, {
    VoidCallback? onConnected,
    Future<XFile?> Function()? pickKey,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          managedSshConnectionControllerProvider.overrideWithValue(controller),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ManagedSshConnectionPanel(
                onCancel: () {},
                onConnected: onConnected,
                pickKey: pickKey ?? () async => null,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('serve selection changes only its explicit credential label', (
    tester,
  ) async {
    final channel = FakeChannel();
    final controller = ManagedSshConnectionController(FakeForward(), channel);
    await mount(tester, controller);
    expect(find.text('Hermes serve session token'), findsNothing);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.text('Hermes serve session token'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    channel.dispose();
  });

  Future<void> submit(WidgetTester tester) async {
    for (final field in {
      'host': input.host,
      'username': input.username,
      'password': input.password,
      'agent-token': input.agentBearerToken!,
    }.entries) {
      final finder = find.byKey(ValueKey('managed-ssh-${field.key}'));
      await tester.ensureVisible(finder);
      await tester.enterText(finder, field.value);
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final button = find.widgetWithText(FilledButton, 'Connect via SSH');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump();
  }

  for (final abandon in [false, true]) {
    testWidgets(
      abandon
          ? 'production mode switch cancels pending SSH adoption'
          : 'production screen adopts SSH without saving ephemeral endpoint',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final channel = FakeChannel();
        final forward = FakeForward();
        final controller = ManagedSshConnectionController(forward, channel);
        final store = FakeHermesEndpointStore();
        final directory = HermesGatewayDirectory(
          store: store,
          cache: FakeGatewayContactCache(),
          loader: FakeGatewaySummaryLoader({}),
          activeChannel: channel,
        );
        var saved = false;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              managedSshConnectionControllerProvider.overrideWithValue(
                controller,
              ),
              hermesChannelProvider.overrideWithValue(channel),
              hermesEndpointStoreProvider.overrideWithValue(store),
              hermesGatewayDirectoryProvider.overrideWith((_) => directory),
              hermesVoiceCaptureServiceProvider.overrideWithValue(null),
              hermesTextToSpeechServiceProvider.overrideWithValue(null),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: HermesChatScreen(
                initiallyEditingConnection: true,
                initialConnectionMode: HermesConnectionMode.ssh,
                onConnectionSaved: () => saved = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await submit(tester);
        if (abandon) {
          final remote = find.byKey(
            const ValueKey('hermes-connection-mode-remote'),
          );
          await tester.ensureVisible(remote);
          await tester.pumpAndSettle();
          await tester.tap(remote);
          await tester.pumpAndSettle();
          expect(forward.stops, 1);
        }
        forward.ready();
        await tester.pumpAndSettle();
        expect(saved, !abandon);
        expect(channel.token, abandon ? null : input.agentBearerToken);
        expect(await store.loadProfiles(), isEmpty);
        expect(find.byKey(const ValueKey('managed-ssh-host')), findsNothing);
        expect(forward.closes, abandon ? 1 : 0);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        controller.dispose();
        channel.dispose();
      },
    );
  }
  testWidgets(
    'panel reviews fingerprint then keeps adopted tunnel after route disposal',
    (tester) async {
      final channel = FakeChannel();
      final forward = FakeForward();
      final controller = ManagedSshConnectionController(forward, channel);
      var connected = false;
      await mount(tester, controller, onConnected: () => connected = true);
      await submit(tester);
      expect(forward.config!.host, input.host);
      expect(forward.config!.username, input.username);
      expect(forward.config!.sshPort, input.sshPort);
      expect(forward.config!.agentPort, input.agentPort);
      expect(await forward.credentials!.password!(), input.password);
      expect(forward.credentials!.privateKey, isNull);
      expect(channel.token, isNull);
      final trust = Future<bool>.sync(
        () => forward.verify!(
          forward.config!,
          ManagedSshHostKey('ssh-ed25519', List.filled(32, 0)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('SHA256:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'),
        findsOneWidget,
      );
      expect(channel.token, isNull);
      await tester.tap(find.text('Trust this connection'));
      await tester.pumpAndSettle();
      expect(await trust, isTrue);
      forward.ready();
      await tester.pumpAndSettle();
      expect(connected, isTrue);
      expect(channel.token, input.agentBearerToken);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(forward.closes, 0);
      controller.dispose();
      channel.dispose();
    },
  );
  testWidgets('route disposal fences a pending host trust response', (
    tester,
  ) async {
    final channel = FakeChannel();
    final forward = FakeForward();
    final controller = ManagedSshConnectionController(forward, channel);
    await mount(tester, controller);
    await submit(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    final trust = Future<bool>.sync(
      () => forward.verify!(
        forward.config!,
        ManagedSshHostKey('ssh-ed25519', List.filled(32, 0)),
      ),
    );
    expect(await trust, isFalse);
    forward.ready();
    await tester.pump();
    expect(channel.token, isNull);
    expect(forward.stops, 1);
    controller.dispose();
    channel.dispose();
  });
  testWidgets('production SSH panel offers explicit key and password choice', (
    tester,
  ) async {
    final channel = FakeChannel();
    final forward = FakeForward();
    final controller = ManagedSshConnectionController(forward, channel);
    await mount(tester, controller);
    expect(
      find.byKey(const ValueKey('managed-ssh-auth-private-key')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('managed-ssh-auth-password')),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    channel.dispose();
  });
  testWidgets(
    'selected private key reaches production controller with separate Agent token',
    (tester) async {
      final channel = FakeChannel();
      final forward = FakeForward();
      final controller = ManagedSshConnectionController(forward, channel);
      final pem = syntheticSshKey();
      var picks = 0;
      await mount(
        tester,
        controller,
        pickKey: () async {
          picks++;
          return XFile.fromData(
            utf8.encode(pem),
            path: '/redacted/fixture-key',
          );
        },
      );
      expect(picks, 0);
      await tester.tap(
        find.byKey(const ValueKey('managed-ssh-auth-private-key')),
      );
      await tester.pumpAndSettle();
      final select = find.byKey(const ValueKey('managed-ssh-select-key'));
      await tester.ensureVisible(select);
      await tester.tap(select);
      await tester.pumpAndSettle();
      expect(picks, 1);
      expect(find.text('fixture-key'), findsOneWidget);
      expect(find.textContaining('/redacted/'), findsNothing);
      expect(find.textContaining('PRIVATE KEY'), findsNothing);
      expect(find.textContaining('SHA256:'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('managed-ssh-passphrase')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('managed-ssh-password')), findsNothing);
      for (final entry in {
        'host': input.host,
        'username': input.username,
        'agent-token': input.agentBearerToken!,
      }.entries) {
        final field = find.byKey(ValueKey('managed-ssh-${entry.key}'));
        await tester.ensureVisible(field);
        await tester.enterText(field, entry.value);
      }
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final connect = find.widgetWithText(FilledButton, 'Connect via SSH');
      await tester.ensureVisible(connect);
      await tester.pumpAndSettle();
      await tester.tap(connect);
      await tester.pump();
      expect(await forward.credentials!.privateKey!(), pem);
      expect(forward.credentials!.password, isNull);
      expect(channel.token, isNull);
      final trust = Future<bool>.sync(
        () => forward.verify!(
          forward.config!,
          ManagedSshHostKey('ssh-ed25519', List.filled(32, 0)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('SHA256:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'),
        findsOneWidget,
      );
      expect(channel.token, isNull);
      await tester.tap(find.text('Trust this connection'));
      await tester.pumpAndSettle();
      expect(await trust, isTrue);
      forward.ready();
      await tester.pumpAndSettle();
      expect(channel.token, input.agentBearerToken);
      expect(await forward.credentials!.privateKey!(), isNull);
      expect(find.text('fixture-key'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      channel.dispose();
    },
  );
  testWidgets(
    'encrypted key requires obscured passphrase and rejects wrong passphrase before dialing',
    (tester) async {
      final channel = FakeChannel();
      final forward = FakeForward();
      final controller = ManagedSshConnectionController(forward, channel);
      final pem = syntheticSshKey(passphrase: 'synthetic-passphrase');
      await mount(
        tester,
        controller,
        pickKey: () async =>
            XFile.fromData(utf8.encode(pem), path: 'encrypted-fixture'),
      );
      await tester.tap(
        find.byKey(const ValueKey('managed-ssh-auth-private-key')),
      );
      await tester.pumpAndSettle();
      final select = find.byKey(const ValueKey('managed-ssh-select-key'));
      await tester.ensureVisible(select);
      await tester.tap(select);
      await tester.pumpAndSettle();
      final passphrase = find.byKey(const ValueKey('managed-ssh-passphrase'));
      expect(passphrase, findsOneWidget);
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: passphrase,
                matching: find.byType(EditableText),
              ),
            )
            .obscureText,
        isTrue,
      );
      final passphraseController = tester
          .widget<TextFormField>(passphrase)
          .controller!;
      for (final entry in {
        'host': input.host,
        'username': input.username,
      }.entries) {
        final field = find.byKey(ValueKey('managed-ssh-${entry.key}'));
        await tester.ensureVisible(field);
        await tester.enterText(field, entry.value);
      }
      Future<void> send() async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        final button = find.widgetWithText(FilledButton, 'Connect via SSH');
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
      }

      await send();
      expect(forward.config, isNull);
      await tester.ensureVisible(passphrase);
      await tester.enterText(passphrase, 'wrong-synthetic-passphrase');
      await send();
      expect(forward.config, isNull);
      expect(
        find.text(
          'Could not unlock this private key. Check its passphrase or select another key.',
        ),
        findsOneWidget,
      );
      expect(passphraseController.text, isEmpty);
      expect(find.text('encrypted-fixture'), findsNothing);
      expect(passphrase, findsNothing);
      await tester.ensureVisible(select);
      await tester.tap(select);
      await tester.pumpAndSettle();
      await tester.ensureVisible(passphrase);
      await tester.enterText(passphrase, 'synthetic-passphrase');
      await send();
      expect(await forward.credentials!.privateKey!(), pem);
      expect(await forward.credentials!.passphrase!(), 'synthetic-passphrase');
      expect(forward.credentials!.password, isNull);
      forward.ready();
      await tester.pumpAndSettle();
      expect(passphrase, findsNothing);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      channel.dispose();
    },
  );
  for (final abandon in ['cancel', 'password', 'dispose']) {
    testWidgets('late picker completion is fenced after $abandon', (
      tester,
    ) async {
      final channel = FakeChannel();
      final forward = FakeForward();
      final controller = ManagedSshConnectionController(forward, channel);
      final picker = Completer<XFile?>();
      await mount(tester, controller, pickKey: () => picker.future);
      await tester.tap(
        find.byKey(const ValueKey('managed-ssh-auth-private-key')),
      );
      await tester.pumpAndSettle();
      final select = find.byKey(const ValueKey('managed-ssh-select-key'));
      await tester.ensureVisible(select);
      await tester.tap(select);
      await tester.pump();
      if (abandon == 'dispose') {
        await tester.pumpWidget(const SizedBox());
      } else {
        final action = abandon == 'cancel'
            ? find.widgetWithText(TextButton, 'Cancel')
            : find.byKey(const ValueKey('managed-ssh-auth-password'));
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pump();
      }
      picker.complete(
        XFile.fromData(utf8.encode(syntheticSshKey()), path: 'stale-fixture'),
      );
      await tester.pumpAndSettle();
      expect(find.text('stale-fixture'), findsNothing);
      expect(forward.config, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      channel.dispose();
    });
  }
  for (final selection in [
    'oversized',
    'unsupported',
    'malformed',
    'unreadable',
    'cancelled',
  ]) {
    testWidgets(
      'production key picker rejects $selection without forwarding and allows password fallback',
      (tester) async {
        final channel = FakeChannel();
        final forward = FakeForward();
        final controller = ManagedSshConnectionController(forward, channel);
        await mount(
          tester,
          controller,
          pickKey: () async {
            if (selection == 'unreadable') {
              throw StateError('redacted/private/path secret');
            }
            if (selection == 'cancelled') return null;
            final text = switch (selection) {
              'oversized' => '${syntheticSshKey()}${' ' * 65537}',
              'unsupported' =>
                '-----BEGIN PRIVATE KEY-----\nAA==\n-----END PRIVATE KEY-----',
              _ => 'malformed synthetic key',
            };
            return XFile.fromData(utf8.encode(text), path: 'fixture-key');
          },
        );
        await tester.tap(
          find.byKey(const ValueKey('managed-ssh-auth-private-key')),
        );
        await tester.pumpAndSettle();
        final select = find.byKey(const ValueKey('managed-ssh-select-key'));
        await tester.ensureVisible(select);
        await tester.tap(select);
        await tester.pumpAndSettle();
        if (selection != 'cancelled') {
          final expected = switch (selection) {
            'oversized' => 'The selected private key exceeds 64 KiB.',
            'unsupported' =>
              'This private-key format is not supported. Select an OpenSSH, RSA or EC private key.',
            'unreadable' =>
              'Could not read the selected private key. Select it again.',
            _ => 'The selected file is not a valid supported SSH private key.',
          };
          expect(find.text(expected), findsOneWidget);
        }
        expect(forward.config, isNull);
        expect(find.textContaining('redacted/private/path'), findsNothing);
        expect(find.text('fixture-key'), findsNothing);
        await tester.ensureVisible(
          find.byKey(const ValueKey('managed-ssh-auth-password')),
        );
        await tester.tap(
          find.byKey(const ValueKey('managed-ssh-auth-password')),
        );
        await tester.pumpAndSettle();
        await submit(tester);
        expect(await forward.credentials!.password!(), input.password);
        expect(forward.credentials!.privateKey, isNull);
        forward.ready();
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
        channel.dispose();
      },
    );
  }
  testWidgets(
    'key authentication refusal clears selected key and uses sanitized authentication error',
    (tester) async {
      final channel = FakeChannel();
      final forward = FakeForward();
      final controller = ManagedSshConnectionController(forward, channel);
      await mount(
        tester,
        controller,
        pickKey: () async => XFile.fromData(
          utf8.encode(syntheticSshKey()),
          path: 'fixture-refused',
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('managed-ssh-auth-private-key')),
      );
      await tester.pumpAndSettle();
      final select = find.byKey(const ValueKey('managed-ssh-select-key'));
      await tester.ensureVisible(select);
      await tester.tap(select);
      await tester.pumpAndSettle();
      for (final entry in {
        'host': input.host,
        'username': input.username,
      }.entries) {
        final field = find.byKey(ValueKey('managed-ssh-${entry.key}'));
        await tester.ensureVisible(field);
        await tester.enterText(field, entry.value);
      }
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final button = find.widgetWithText(FilledButton, 'Connect via SSH');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      forward.waiting.completeError(
        const ManagedSshException(ManagedSshFailure.authentication),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          'SSH authentication was rejected. Check your username and authentication choice, then retry.',
        ),
        findsOneWidget,
      );
      expect(find.text('fixture-refused'), findsNothing);
      expect(await forward.credentials!.privateKey!(), isNull);
      expect(channel.token, isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      channel.dispose();
    },
  );
  test(
    'controller cancels credential callbacks without waiting for obsolete forwarding',
    () async {
      final channel = FakeChannel();
      final forward = FakeForward();
      final controller = ManagedSshConnectionController(forward, channel);
      final result = controller.connectSsh(
        SshConnectionRequest(
          host: input.host,
          sshPort: input.sshPort,
          username: input.username,
          privateKey: syntheticSshKey(),
          passphrase: 'synthetic-passphrase',
          agentPort: input.agentPort,
          agentBearerToken: input.agentBearerToken,
        ),
        verifyHostKey: (_, _) async => true,
      );
      expect(await forward.credentials!.privateKey!(), isNotNull);
      await controller.cancel();
      expect(await forward.credentials!.privateKey!(), isNull);
      expect(await forward.credentials!.passphrase!(), isNull);
      forward.ready();
      expect(await result, isFalse);
      controller.dispose();
      channel.dispose();
    },
  );
  testWidgets('panel sanitizes transport failure', (tester) async {
    final channel = FakeChannel();
    final forward = FakeForward();
    final controller = ManagedSshConnectionController(forward, channel);
    await mount(tester, controller);
    await submit(tester);
    forward.waiting.completeError(
      StateError('synthetic-password sensitive endpoint'),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('synthetic-password sensitive endpoint'),
      findsNothing,
    );
    expect(
      find.textContaining('Could not establish the SSH connection.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    channel.dispose();
  });
  test('cancel fences stale trust and old tunnel completion', () async {
    final channel = FakeChannel();
    final forward = FakeForward();
    final controller = ManagedSshConnectionController(forward, channel);
    final approval = Completer<bool>();
    final result = controller.connectSsh(
      input,
      verifyHostKey: (_, _) => approval.future,
    );
    final trust = Future<bool>.sync(
      () => forward.verify!(
        forward.config!,
        ManagedSshHostKey('ssh-ed25519', List.filled(32, 0)),
      ),
    );
    await controller.cancel();
    approval.complete(true);
    expect(await trust, isFalse);
    forward.ready();
    expect(await result, isFalse);
    expect(forward.closes, 1);
    expect(channel.token, isNull);
    controller.dispose();
    channel.dispose();
  });
  test('replacement during adoption is never disconnected by cancel', () async {
    final channel = FakeChannel()..pending = Completer<void>();
    final forward = FakeForward();
    final controller = ManagedSshConnectionController(forward, channel);
    final result = controller.connectSsh(
      input,
      verifyHostKey: (_, _) async => true,
    );
    forward.ready();
    await Future<void>.delayed(Duration.zero);
    channel.set(
      const HermesChannelState(status: HermesConnectionStatus.connecting),
    );
    await controller.cancel();
    expect(channel.disconnects, 0);
    channel.pending!.complete();
    await result;
    controller.dispose();
    channel.dispose();
  });
  test('failed Agent adoption closes forwarding lease', () async {
    final channel = FakeChannel()..fail = true;
    final forward = FakeForward();
    final controller = ManagedSshConnectionController(forward, channel);
    final result = controller.connectSsh(
      input,
      verifyHostKey: (_, _) async => true,
    );
    forward.ready();
    await expectLater(result, throwsA(isA<ManagedSshException>()));
    expect(forward.closes, 1);
    expect(channel.disconnects, 1);
    controller.dispose();
    channel.dispose();
  });
  test(
    'obsolete completion and cancel ticket cannot revoke a newer attempt',
    () async {
      final channel = FakeChannel();
      final forward = FakeForward();
      final controller = ManagedSshConnectionController(forward, channel);
      final old = controller.connectSsh(
        input,
        verifyHostKey: (_, _) async => true,
      );
      final ticket = controller.attemptId;
      final oldWaiting = forward.waiting;
      await controller.cancel(attemptId: ticket);
      forward.waiting = Completer<ManagedSshTunnel>();
      final current = controller.connectSsh(
        input,
        verifyHostKey: (_, _) async => true,
      );
      await controller.cancel(attemptId: ticket);
      var oldClosed = false;
      oldWaiting.complete(
        ManagedSshTunnel(
          agentUri: Uri.parse('http://127.0.0.1:45679'),
          done: Completer<void>().future,
          close: () async => oldClosed = true,
        ),
      );
      expect(await old, isFalse);
      expect(oldClosed, isTrue);
      forward.ready();
      expect(await current, isTrue);
      expect(forward.closes, 0);
      expect(channel.disconnects, 0);
      controller.dispose();
      channel.dispose();
    },
  );
  testWidgets(
    'Cancel abandons pending SSH without disconnecting existing Agent',
    (tester) async {
      final channel = FakeChannel()
        ..state = const HermesChannelState(
          status: HermesConnectionStatus.connected,
          connectedBaseUrl: 'https://example.invalid',
        );
      final forward = FakeForward();
      final controller = ManagedSshConnectionController(forward, channel);
      await mount(tester, controller);
      await submit(tester);
      final cancel = find.widgetWithText(TextButton, 'Cancel');
      await tester.ensureVisible(cancel);
      await tester.pumpAndSettle();
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(forward.stops, 1);
      expect(channel.disconnects, 0);
      forward.ready();
      await tester.pumpAndSettle();
      expect(channel.state.connectedBaseUrl, 'https://example.invalid');
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      channel.dispose();
    },
  );
  for (final dispose in [false, true]) {
    test(
      'SSH cancellation during secure recovery cleanup prevents late API reads; dispose=$dispose',
      () async {
        final store = _HeldClearStore();
        var reads = 0;
        final channel = HermesApiChannel(
          serveRecoveryStore: store,
          clientBuilder: (config) => HermesApiClient(
            config: config,
            get: (uri, headers) async {
              reads++;
              throw StateError('Cancelled adoption must not read');
            },
          ),
        );
        final forward = FakeForward();
        final controller = ManagedSshConnectionController(forward, channel);
        final connecting = controller.connectSsh(
          input,
          verifyHostKey: (_, _) async => true,
        );
        forward.ready();
        await store.entered.future;
        if (dispose) {
          controller.dispose();
        } else {
          unawaited(controller.cancel());
        }
        await Future<void>.delayed(Duration.zero);
        store.release.complete();
        expect(await connecting, false);
        await Future<void>.delayed(Duration.zero);
        expect(reads, 0);
        expect(channel.state.status, HermesConnectionStatus.disconnected);
        expect(forward.closes, 1);
        if (!dispose) controller.dispose();
        channel.dispose();
      },
    );
  }
  test(
    'replacement during secure cleanup never reads the old SSH origin',
    () async {
      final store = _HeldClearStore();
      final origins = <String>[];
      final channel = HermesApiChannel(
        serveRecoveryStore: store,
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            origins.add(uri.origin);
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' =>
                '''{
              "object":"hermes.api_server.capabilities",
              "platform":"test","model":"test",
              "auth":{"type":"bearer","required":true,"granted_scopes":[]},
              "features":{},"endpoints":{}
            }''',
              '/api/sessions' => '{"sessions":[],"total":0}',
              _ => throw StateError('Unexpected read'),
            };
          },
        ),
      );
      final forward = FakeForward();
      final controller = ManagedSshConnectionController(forward, channel);
      final old = controller.connectSsh(
        input,
        verifyHostKey: (_, _) async => true,
      );
      forward.ready();
      await store.entered.future;
      final replacement = channel.connect(baseUrl: 'https://example.invalid');
      store.release.complete();
      await replacement;
      expect(await old, false);
      expect(channel.state.isConnected, true);
      expect(channel.state.connectedBaseUrl, 'https://example.invalid');
      expect(origins, isNotEmpty);
      expect(origins, everyElement('https://example.invalid'));
      expect(forward.closes, 1);
      controller.dispose();
      channel.dispose();
    },
  );
  for (final duringHealth in [false, true]) {
    test(
      'production channel rejects lost tunnel; duringHealth=$duringHealth',
      () async {
        final health = Completer<String>();
        final entered = Completer<void>();
        final reads = <String>[];
        var mutations = 0;
        final channel = HermesApiChannel(
          clientBuilder: (config) => HermesApiClient(
            config: config,
            get: (uri, headers) async {
              reads.add(uri.path);
              if (uri.path == '/health') {
                entered.complete();
                return health.future;
              }
              throw StateError('Unexpected read after lost tunnel');
            },
            post: (uri, headers, body) async {
              mutations++;
              throw StateError('Unexpected mutation');
            },
          ),
        );
        final forward = FakeForward();
        final controller = ManagedSshConnectionController(forward, channel);
        final result = controller.connectSsh(
          input,
          verifyHostKey: (_, _) async => true,
        );
        forward.ready();
        if (duringHealth) await entered.future;
        forward.ended.complete();
        await Future<void>.delayed(Duration.zero);
        expect(channel.state.status, HermesConnectionStatus.disconnected);
        health.complete('{"status":"ok"}');
        expect(await result, isFalse);
        expect(channel.state.status, HermesConnectionStatus.disconnected);
        expect(reads, everyElement('/health'));
        expect(mutations, 0);
        expect(forward.closes, 1);
        controller.dispose();
        channel.dispose();
      },
    );
  }
  for (final replacement in [false, true]) {
    test(
      'tunnel loss during adoption fences credentials; replacement=$replacement',
      () async {
        final channel = FakeChannel()..pending = Completer<void>();
        final forward = FakeForward();
        final controller = ManagedSshConnectionController(forward, channel);
        final result = controller.connectSsh(
          input,
          verifyHostKey: (_, _) async => true,
        );
        forward.ready();
        await Future<void>.delayed(Duration.zero);
        expect(channel.state.status, HermesConnectionStatus.connecting);
        if (replacement) {
          channel.set(
            const HermesChannelState(
              status: HermesConnectionStatus.connected,
              connectedBaseUrl: 'https://replacement.invalid',
            ),
          );
        }
        forward.ended.complete();
        await Future<void>.delayed(Duration.zero);
        expect(await forward.credentials!.password!(), isNull);
        expect(channel.disconnects, replacement ? 0 : 1);
        expect(forward.closes, 1);
        channel.pending!.complete();
        expect(await result, isFalse);
        controller.dispose();
        channel.dispose();
      },
    );
  }
  for (final dispose in [false, true]) {
    test(
      'retiring adopted SSH disconnects its Agent; dispose=$dispose',
      () async {
        final channel = FakeChannel();
        final forward = FakeForward();
        final controller = ManagedSshConnectionController(forward, channel);
        final result = controller.connectSsh(
          input,
          verifyHostKey: (_, _) async => true,
        );
        forward.ready();
        expect(await result, isTrue);
        if (dispose) {
          controller.dispose();
          await Future<void>.delayed(Duration.zero);
        } else {
          await controller.cancel(attemptId: controller.attemptId);
        }
        expect(forward.closes, 1);
        expect(channel.disconnects, 1);
        expect(channel.state.status, HermesConnectionStatus.disconnected);
        if (!dispose) controller.dispose();
        channel.dispose();
      },
    );
  }
  test(
    'adopted cancellation preserves replacement during lease teardown',
    () async {
      final channel = FakeChannel();
      final forward = FakeForward();
      final controller = ManagedSshConnectionController(forward, channel);
      final result = controller.connectSsh(
        input,
        verifyHostKey: (_, _) async => true,
      );
      final closing = Completer<void>();
      final closed = Completer<void>();
      forward.waiting.complete(
        ManagedSshTunnel(
          agentUri: Uri.parse('http://127.0.0.1:45678'),
          done: forward.ended.future,
          close: () async {
            closing.complete();
            await closed.future;
          },
        ),
      );
      expect(await result, isTrue);
      final cancellation = controller.cancel();
      await closing.future;
      expect(channel.disconnects, 1);
      expect(channel.state.status, HermesConnectionStatus.disconnected);
      const replacement = HermesChannelState(
        status: HermesConnectionStatus.connected,
        connectedBaseUrl: 'https://replacement.invalid',
        selectedProfileId: 'replacement-profile',
        activeSessionId: 'replacement-session',
      );
      channel.set(replacement);
      closed.complete();
      await cancellation;
      expect(channel.disconnects, 1);
      expect(channel.state, same(replacement));
      controller.dispose();
      channel.dispose();
    },
  );
  test('tunnel loss disconnects only the owning Agent', () async {
    final channel = FakeChannel();
    final forward = FakeForward();
    final controller = ManagedSshConnectionController(forward, channel);
    final result = controller.connectSsh(
      input,
      verifyHostKey: (_, _) async => true,
    );
    forward.ready();
    expect(await result, isTrue);
    forward.ended.complete();
    await Future<void>.delayed(Duration.zero);
    expect(channel.disconnects, 1);
    controller.dispose();
    channel.dispose();
  });
  test(
    'Agent replacement revokes lease without disconnecting replacement',
    () async {
      final channel = FakeChannel();
      final forward = FakeForward();
      final controller = ManagedSshConnectionController(forward, channel);
      final result = controller.connectSsh(
        input,
        verifyHostKey: (_, _) async => true,
      );
      forward.ready();
      expect(await result, isTrue);
      channel.set(
        const HermesChannelState(
          status: HermesConnectionStatus.connected,
          connectedBaseUrl: 'https://replacement.invalid',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      forward.ended.complete();
      await Future<void>.delayed(Duration.zero);
      expect(forward.closes, 1);
      expect(channel.disconnects, 0);
      controller.dispose();
      channel.dispose();
    },
  );
  test('external connection while dialing fences Agent adoption', () async {
    final channel = FakeChannel();
    final forward = FakeForward();
    final controller = ManagedSshConnectionController(forward, channel);
    final result = controller.connectSsh(
      input,
      verifyHostKey: (_, _) async => true,
    );
    channel.set(
      const HermesChannelState(status: HermesConnectionStatus.connecting),
    );
    forward.ready();
    expect(await result, isFalse);
    expect(channel.token, isNull);
    expect(channel.disconnects, 0);
    controller.dispose();
    channel.dispose();
  });
  test(
    'direct Agent adoption uses separate token and keeps lease until owner disconnects',
    () async {
      final channel = FakeChannel();
      final forward = FakeForward();
      final controller = ManagedSshConnectionController(forward, channel);
      final result = controller.connectSsh(
        input,
        verifyHostKey: (_, _) async => true,
      );
      forward.ready();
      expect(await result, isTrue);
      expect(channel.token, input.agentBearerToken);
      expect(channel.state.connectedBaseUrl, 'http://127.0.0.1:45678');
      expect(forward.closes, 0);
      await channel.disconnect();
      await Future<void>.delayed(Duration.zero);
      expect(forward.closes, 1);
      controller.dispose();
      channel.dispose();
    },
  );
}
