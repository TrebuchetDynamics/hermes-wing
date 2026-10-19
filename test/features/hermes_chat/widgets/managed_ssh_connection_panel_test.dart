import 'dart:async';
import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../ssh_keys/synthetic_ssh_keys.dart';
import 'package:flutter/foundation.dart';
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
import 'package:wing/core/hermes/setup/secure_managed_ssh_recovery_store.dart';
import 'package:wing/core/hermes/ssh/managed_ssh.dart';
import 'package:wing/core/hermes/ssh/secure_managed_ssh_host_trust_store.dart';
import 'package:wing/core/hermes/ssh/secure_managed_ssh_target_store.dart';
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

class _Denied implements HermesApiStatusException {
  const _Denied([this.statusCode = 401]);
  @override
  final int statusCode;
}

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

class _HeldDisconnectChannel extends FakeChannel {
  final disconnectEntered = Completer<void>();
  final disconnectRelease = Completer<void>();

  @override
  Future<void> disconnect() async {
    if (!disconnectEntered.isCompleted) {
      disconnectEntered.complete();
      await disconnectRelease.future;
    }
    await super.disconnect();
  }
}

class _HeldClearStore implements HermesServeRecoveryStore {
  final entered = Completer<void>();
  final release = Completer<void>();
  bool hold = true;
  @override
  Future<void> clear() async {
    if (hold && !entered.isCompleted) {
      entered.complete();
      await release.future;
    }
  }

  @override
  Future<HermesServeRecoverySelection?> load() async => null;
  @override
  Future<void> save(HermesServeRecoverySelection selection) async {}
}

class _DeniedClearStore implements HermesServeRecoveryStore {
  @override
  Future<void> clear() async =>
      throw StateError('synthetic private storage failure');
  @override
  Future<HermesServeRecoverySelection?> load() async => null;
  @override
  Future<void> save(HermesServeRecoverySelection selection) async {}
}

class _DeniedSshStore implements ManagedSshRecoveryStore {
  _DeniedSshStore({required this.denyLoad});
  final bool denyLoad;
  @override
  Future<ManagedSshRecovery?> load(
    ManagedSshConfig config,
    SshAgentTransport transport,
  ) async {
    if (denyLoad) throw StateError('synthetic sensitive storage failure');
    return null;
  }

  @override
  Future<void> save(ManagedSshRecovery selection) async {
    throw StateError('synthetic sensitive storage failure');
  }
}

class FakeForward extends ManagedSshForward {
  var waiting = Completer<ManagedSshTunnel>();
  ManagedSshHostKeyVerifier? verify;
  ManagedSshConfig? config;
  ManagedSshCredentials? credentials;
  int stops = 0;
  int closes = 0;
  Completer<void>? closeGate;
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
    if (!autoVerify) return waiting.future;
    // Like the real adapter, the tunnel resolves only after host-key review.
    return Future(() async {
      final accepted = await verifyHostKey!(
        configuration,
        ManagedSshHostKey('ssh-ed25519', List.filled(32, 3)),
      );
      if (!accepted) {
        throw const ManagedSshException(ManagedSshFailure.hostKeyRejected);
      }
      return waiting.future;
    });
  }

  /// Production [HermesApiChannel] adoption requires a reviewed host key.
  bool autoVerify = false;

  void ready() => waiting.complete(
    ManagedSshTunnel(
      agentUri: Uri.parse('http://127.0.0.1:45678'),
      done: ended.future,
      close: () async {
        closes++;
        await closeGate?.future;
      },
    ),
  );

  @override
  Future<void> disconnect() async {
    stops++;
  }
}

class _ServeReadChannel extends HermesApiChannel {
  _ServeReadChannel({required this.canNegotiate});
  final bool canNegotiate;
  @override
  bool get canEnableLocalServeChat => canNegotiate;
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
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'controller passes explicit profile into reviewed forward and Agent client',
    () async {
      final reads = <String>[];
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            reads.add(uri.path);
            expect(headers['Authorization'], 'Bearer synthetic-profile-token');
            return switch (uri.path) {
              '/p/demo/health' => '{"status":"ok"}',
              '/p/demo/v1/capabilities' =>
                '{"object":"hermes.api_server.capabilities","platform":"test","model":"test","auth":{"type":"bearer","required":true,"granted_scopes":[]},"features":{},"endpoints":{}}',
              '/p/demo/api/sessions' => '{"sessions":[],"total":0}',
              _ => throw StateError('Unexpected read'),
            };
          },
          post: (_, _, _) async => throw StateError('No mutations authorized'),
        ),
      );
      final forward = FakeForward()..autoVerify = true;
      final controller = ManagedSshConnectionController(forward, channel);
      addTearDown(() async {
        await controller.cancel();
        controller.dispose();
        channel.dispose();
      });
      final connecting = controller.connectSsh(
        const SshConnectionRequest(
          host: 'example.invalid',
          sshPort: 22,
          username: 'tester',
          password: 'synthetic-password',
          agentPort: 8642,
          agentProfile: 'demo',
          agentBearerToken: 'synthetic-profile-token',
        ),
        verifyHostKey: (config, _) => config.agentProfile == 'demo',
      );
      await Future<void>.delayed(Duration.zero);
      expect(forward.config!.agentProfile, 'demo');
      forward.waiting.complete(
        ManagedSshTunnel(
          agentUri: forward.config!.forwardedAgentUri(45678),
          done: forward.ended.future,
          close: () async {},
        ),
      );
      expect(await connecting, isTrue);
      expect(channel.state.connectedBaseUrl, 'http://127.0.0.1:45678/p/demo');
      expect(reads, [
        '/p/demo/health',
        '/p/demo/v1/capabilities',
        '/p/demo/api/sessions',
      ]);
      expect(channel.state.selectedProfileId, 'demo');
      expect(controller.recoveryTarget!.configuration.agentProfile, 'demo');
      expect(await forward.credentials!.password!(), isNull);
    },
  );

  test(
    'profile Agent denial never falls back to root or reuses SSH authentication',
    () async {
      final paths = <String>[];
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            paths.add(uri.path);
            expect(
              headers['Authorization'],
              'Bearer synthetic-wrong-profile-token',
            );
            throw const _Denied();
          },
        ),
      );
      final forward = FakeForward()..autoVerify = true;
      final controller = ManagedSshConnectionController(forward, channel);
      addTearDown(() async {
        await controller.cancel();
        controller.dispose();
        channel.dispose();
      });
      final connecting = controller.connectSsh(
        const SshConnectionRequest(
          host: 'example.invalid',
          sshPort: 22,
          username: 'tester',
          password: 'synthetic-password',
          agentPort: 8642,
          agentProfile: 'demo',
          agentBearerToken: 'synthetic-wrong-profile-token',
        ),
        verifyHostKey: (_, _) => true,
      );
      await Future<void>.delayed(Duration.zero);
      forward.waiting.complete(
        ManagedSshTunnel(
          agentUri: forward.config!.forwardedAgentUri(45678),
          done: forward.ended.future,
          close: () async {
            forward.closes++;
          },
        ),
      );
      await expectLater(
        connecting,
        throwsA(
          isA<ManagedSshAgentException>().having(
            (e) => e.kind,
            'kind',
            HermesConnectionFailureKind.authentication,
          ),
        ),
      );
      expect(paths, ['/p/demo/health']);
      expect(forward.closes, 1);
      expect(await forward.credentials!.password!(), isNull);
      expect(controller.recoveryTarget, isNull);
    },
  );

  for (final scenario in [
    (failCleanup: false, reentrant: false),
    (failCleanup: true, reentrant: false),
    (failCleanup: false, reentrant: true),
    (failCleanup: true, reentrant: true),
  ]) {
    final failCleanup = scenario.failCleanup;
    test('repeated cancel awaits owned teardown; $scenario', () async {
      final forward = FakeForward();
      final closing = Completer<void>();
      final release = Completer<void>();
      forward.waiting.complete(
        ManagedSshTunnel(
          agentUri: Uri.parse('http://127.0.0.1:45678'),
          done: forward.ended.future,
          close: () async {
            forward.closes++;
            closing.complete();
            await release.future;
            if (failCleanup) throw StateError('synthetic cleanup failure');
          },
        ),
      );
      final channel = FakeChannel();
      final controller = ManagedSshConnectionController(forward, channel);
      addTearDown(() {
        controller.dispose();
        channel.dispose();
      });
      expect(
        await controller.connectSsh(input, verifyHostKey: (_, _) async => true),
        isTrue,
      );
      final attempt = controller.attemptId;
      var settled = false;
      Object? secondError;
      Future<void> joinCancellation() => controller.cancel().then<void>(
        (_) {
          settled = true;
        },
        onError: (Object e) {
          secondError = e;
          settled = true;
        },
      );
      late Future<void> second;
      if (scenario.reentrant) {
        channel.addListener(() => second = joinCancellation());
      }
      Object? firstError;
      final first = controller.cancel(attemptId: attempt).catchError((
        Object e,
      ) {
        firstError = e;
      });
      await closing.future;
      if (!scenario.reentrant) second = joinCancellation();
      // A stale panel still cannot join or cancel the current generation.
      await controller.cancel(attemptId: attempt);
      await Future<void>.delayed(Duration.zero);
      expect(settled, isFalse);
      expect(channel.disconnects, 1);
      expect(forward.closes, 1);
      expect(
        await controller.connectSsh(input, verifyHostKey: (_, _) async => true),
        isFalse,
      );
      release.complete();
      await Future.wait([first, second]);
      expect(settled, isTrue);
      expect(firstError, failCleanup ? isStateError : isNull);
      expect(secondError, same(firstError));
      expect(forward.closes, 1);
    });
  }

  for (final replaced in [false, true]) {
    test(
      'channel owner loss serializes SSH teardown; replaced=$replaced',
      () async {
        final forward = FakeForward();
        final closing = Completer<void>();
        final release = Completer<void>();
        forward.waiting.complete(
          ManagedSshTunnel(
            agentUri: Uri.parse('http://127.0.0.1:45678'),
            done: forward.ended.future,
            close: () async {
              forward.closes++;
              closing.complete();
              await release.future;
            },
          ),
        );
        final channel = FakeChannel();
        final controller = ManagedSshConnectionController(forward, channel);
        addTearDown(() async {
          if (!release.isCompleted) release.complete();
          await Future<void>.delayed(Duration.zero);
          await controller.cancel();
          controller.dispose();
          channel.dispose();
        });
        expect(
          await controller.connectSsh(
            input,
            verifyHostKey: (_, _) async => true,
          ),
          isTrue,
        );
        final retiredCredentials = forward.credentials;
        final replacement = replaced
            ? const HermesChannelState(
                status: HermesConnectionStatus.connected,
                connectedBaseUrl: 'https://replacement.invalid',
                selectedProfileId: 'replacement-profile',
                activeSessionId: 'replacement-session',
              )
            : const HermesChannelState();
        channel.set(replacement);
        await closing.future;
        expect(
          await controller.connectSsh(
            input,
            verifyHostKey: (_, _) async => true,
          ),
          isFalse,
        );
        expect(forward.credentials, same(retiredCredentials));
        expect(channel.state, same(replacement));
        expect(channel.disconnects, 0);
        expect(forward.closes, 1);
        release.complete();
        await Future<void>.delayed(Duration.zero);
        forward.ended.complete();
        await Future<void>.delayed(Duration.zero);
        expect(channel.state, same(replacement));
        expect(channel.disconnects, 0);
        forward.waiting = Completer<ManagedSshTunnel>();
        final nextEnded = Completer<void>();
        forward.waiting.complete(
          ManagedSshTunnel(
            agentUri: Uri.parse('http://127.0.0.1:45679'),
            done: nextEnded.future,
            close: () async => forward.closes++,
          ),
        );
        expect(
          await controller.connectSsh(
            input,
            verifyHostKey: (_, _) async => true,
          ),
          isTrue,
        );
        expect(channel.state.connectedBaseUrl, 'http://127.0.0.1:45679');
        expect(forward.closes, 1);
      },
    );
  }

  test('tunnel loss blocks SSH retry during production lease cleanup', () async {
    final store = _HeldClearStore()..hold = false;
    final reads = <String>[];
    var mutations = 0;
    final channel = HermesApiChannel(
      serveRecoveryStore: store,
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          reads.add(uri.origin);
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
        post: (uri, headers, body) async {
          mutations++;
          throw StateError('Unexpected mutation');
        },
      ),
    );
    final forward = FakeForward()
      ..autoVerify = true
      ..ready();
    final controller = ManagedSshConnectionController(forward, channel);
    addTearDown(() async {
      if (!(forward.closeGate?.isCompleted ?? true)) {
        forward.closeGate!.complete();
      }
      await Future<void>.delayed(Duration.zero);
      await controller.cancel();
      controller.dispose();
      channel.dispose();
    });
    expect(
      await controller.connectSsh(input, verifyHostKey: (_, _) async => true),
      isTrue,
    );
    final retiredCredentials = forward.credentials;
    final originalReads = reads.length;
    forward.closeGate = Completer<void>();
    forward.ended.complete();
    for (var i = 0; i < 100 && forward.closes == 0; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(forward.closes, 1);
    expect(
      await controller.connectSsh(input, verifyHostKey: (_, _) async => true),
      isFalse,
    );
    expect(forward.credentials, same(retiredCredentials));
    expect(reads.length, originalReads);
    // Loss retains the interrupted selection as an error for explicit reconnect.
    expect(channel.state.status, HermesConnectionStatus.error);
    expect(controller.needsSshReconnect, isTrue);
    forward.closeGate!.complete();
    await Future<void>.delayed(Duration.zero);
    expect(forward.closes, 1);
    expect(mutations, 0);
  });

  test('tunnel loss blocks SSH retry until Agent retirement settles', () async {
    final channel = _HeldDisconnectChannel();
    final forward = FakeForward()..ready();
    final controller = ManagedSshConnectionController(forward, channel);
    addTearDown(() async {
      if (!channel.disconnectRelease.isCompleted) {
        channel.disconnectRelease.complete();
      }
      await Future<void>.delayed(Duration.zero);
      await controller.cancel();
      controller.dispose();
      channel.dispose();
    });
    expect(
      await controller.connectSsh(input, verifyHostKey: (_, _) async => true),
      isTrue,
    );
    final retiredCredentials = forward.credentials;
    forward.ended.complete();
    await channel.disconnectEntered.future;
    forward.waiting = Completer<ManagedSshTunnel>()
      ..complete(
        ManagedSshTunnel(
          agentUri: Uri.parse('http://127.0.0.1:45679'),
          done: Completer<void>().future,
          close: () async {},
        ),
      );
    expect(
      await controller.connectSsh(input, verifyHostKey: (_, _) async => true),
      isFalse,
    );
    expect(forward.credentials, same(retiredCredentials));
    channel.disconnectRelease.complete();
    await Future<void>.delayed(Duration.zero);
    expect(channel.state.isConnected, isFalse);
    expect(channel.disconnects, 1);
    expect(forward.closes, 1);
    expect(
      await controller.connectSsh(input, verifyHostKey: (_, _) async => true),
      isTrue,
    );
    expect(channel.state.connectedBaseUrl, 'http://127.0.0.1:45679');
    expect(channel.disconnects, 1);
  });

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

  for (final canNegotiate in [true, false]) {
    testWidgets(
      'serve chat entry respects channel negotiation availability $canNegotiate',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final channel = _ServeReadChannel(canNegotiate: canNegotiate);
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
          canNegotiate ? findsOneWidget : findsNothing,
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
    bool chatEntry = false,
  }) async {
    final channel = controller.channel;
    final store = FakeHermesEndpointStore();
    final directory = HermesGatewayDirectory(
      store: store,
      cache: FakeGatewayContactCache(),
      loader: FakeGatewaySummaryLoader({}),
      activeChannel: channel,
    );
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          managedSshConnectionControllerProvider.overrideWithValue(controller),
          if (chatEntry) ...[
            hermesChannelProvider.overrideWithValue(channel),
            hermesEndpointStoreProvider.overrideWithValue(store),
            hermesGatewayDirectoryProvider.overrideWith((_) => directory),
            hermesVoiceCaptureServiceProvider.overrideWithValue(null),
            hermesTextToSpeechServiceProvider.overrideWithValue(null),
          ],
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: chatEntry
              ? (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(2),
                    viewInsets: const EdgeInsets.only(bottom: 80),
                  ),
                  child: child!,
                )
              : null,
          home: chatEntry
              ? HermesChatScreen(
                  initiallyEditingConnection: true,
                  initialConnectionMode: HermesConnectionMode.ssh,
                  onConnectionSaved: onConnected,
                )
              : Scaffold(
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

  for (final status in [401, 403, 0]) {
    testWidgets(
      'production Agent failure survives cleanup and is visible in narrow SSH Chat entry: $status',
      (tester) async {
        tester.view.physicalSize = const Size(320, 480);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        var rejecting = true;
        var reads = 0;
        final channel = HermesApiChannel(
          clientBuilder: (config) => HermesApiClient(
            config: config,
            get: (uri, _) async {
              reads++;
              if (rejecting) {
                if (status == 0) throw const FormatException('redacted');
                throw _Denied(status);
              }
              return switch (uri.path) {
                '/health' => '{"status":"ok"}',
                '/v1/capabilities' =>
                  '{"schema_version":1,"profile_context":{"type":"query","name":"profile","required":true,"default_profile_id":"default"},"auth":{"type":"bearer","required":true,"granted_scopes":[]},"features":{},"endpoints":{"session_messages":{"method":"GET","path":"/api/sessions/{session_id}/messages","profile_scoped":true}}}',
                '/api/sessions' =>
                  '{"data":[{"id":"synthetic-session","source":"api_server"}],"has_more":false}',
                '/api/sessions/synthetic-session/messages' =>
                  '{"object":"list","session_id":"synthetic-session","data":[]}',
                _ => throw StateError('Unexpected fixture read'),
              };
            },
            post: (_, _, _) async =>
                throw StateError('No mutations authorized'),
          ),
        );
        final forward = FakeForward()
          ..autoVerify = true
          ..closeGate = Completer<void>();
        final controller = ManagedSshConnectionController(forward, channel);
        var successes = 0;
        await const SecureManagedSshHostTrustStore().verify(
          ManagedSshConfig(
            host: input.host,
            username: input.username,
            agentPort: 8642,
          ),
          ManagedSshHostKey('ssh-ed25519', List.filled(32, 3)),
          isCurrent: () => true,
          review: () async => true,
        );
        await mount(
          tester,
          controller,
          onConnected: () => successes++,
          chatEntry: true,
        );
        for (final entry in {
          'host': input.host,
          'username': input.username,
          'password': input.password,
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
        // The user scrolls away while Connect is pending.
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, 4000),
        );
        await tester.pumpAndSettle();
        forward.ready();
        await tester.pumpAndSettle();
        expect(forward.closes, 1);
        expect(channel.state.status, HermesConnectionStatus.disconnected);
        expect(find.text('Connecting via SSH…'), findsOneWidget);
        expect(successes, 0);
        forward.closeGate!.complete();
        await tester.pumpAndSettle();
        final summary = find.text(
          status == 0
              ? 'Incompatible Agent. Check port.'
              : 'Agent access denied. Check token.',
        );
        expect(summary, findsOneWidget);
        final retry = find.widgetWithText(FilledButton, 'Connect via SSH');
        final viewport = tester.getRect(find.byType(Scaffold).last);

        for (final control in [summary, retry]) {
          final bounds = tester.getRect(control);
          final scrollViewport = tester.getRect(
            find.byType(SingleChildScrollView).first,
          );
          expect(bounds.top, greaterThanOrEqualTo(scrollViewport.top));
          expect(bounds.bottom, lessThanOrEqualTo(viewport.bottom - 80));
        }
        expect(retry.hitTestable(), findsOneWidget);
        expect(
          tester
              .getSemantics(summary)
              .getSemanticsData()
              .flagsCollection
              .isLiveRegion,
          isTrue,
        );
        expect(tester.widget<FilledButton>(retry).onPressed, isNotNull);
        expect(channel.state.isConnected, isFalse);
        expect(successes, 0);
        expect(reads, 1); // No automatic retry or alternate-surface probe.
        for (final id in ['password', 'agent-token']) {
          expect(
            tester
                .widget<TextFormField>(find.byKey(ValueKey('managed-ssh-$id')))
                .controller!
                .text,
            isEmpty,
          );
        }
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const ValueKey('managed-ssh-host')),
              )
              .controller!
              .text,
          input.host,
        );
        rejecting = false;
        forward.waiting = Completer<ManagedSshTunnel>();
        forward.closeGate = null;
        forward.ready();
        for (final entry in {
          'password': input.password,
          'agent-token': input.agentBearerToken!,
        }.entries) {
          final field = find.byKey(ValueKey('managed-ssh-${entry.key}'));
          await tester.ensureVisible(field);
          await tester.enterText(field, entry.value);
        }
        // A deliberate keyboard retry must reacquire credentials and run once.
        await tester.testTextInput.receiveAction(TextInputAction.done);
        // Retry input above is still at 320x480/200%. Render the resulting
        // full Chat separately; its short-height layout is outside this repair.
        tester.view.physicalSize = const Size(800, 1200);
        await tester.pumpAndSettle();
        expect(
          successes,
          1,
          reason:
              'reads=$reads status=${channel.state.status} kind=${channel.state.connectionFailureKind} error=${channel.state.errorMessage}',
        );
        expect(reads, 5);
        expect(channel.state.isConnected, isTrue);
        expect(channel.state.selectedProfileId, 'default');
        expect(channel.state.activeSessionId, 'synthetic-session');
        expect(channel.state.messages, contains('synthetic-session'));
        expect(find.byKey(const ValueKey('managed-ssh-host')), findsNothing);
        semantics.dispose();
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
        channel.dispose();
      },
    );
  }

  testWidgets(
    'saved target restores production transport choice without opening SSH',
    (tester) async {
      await const SecureManagedSshTargetStore().save(
        ManagedSshTarget(
          config: ManagedSshConfig(
            host: 'saved.invalid',
            sshPort: 2222,
            username: 'tester',
            agentPort: 8643,
          ),
          serveReads: true,
        ),
      );
      final channel = FakeChannel();
      final forward = FakeForward();
      final controller = ManagedSshConnectionController(forward, channel);
      await mount(tester, controller);
      expect(find.text('Hermes serve session token'), findsNothing);
      final load = find.byKey(const ValueKey('managed-ssh-load-target'));
      await tester.ensureVisible(load);
      await tester.tap(load);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('managed-ssh-serve-reads')),
            )
            .value,
        isTrue,
      );
      expect(find.text('Hermes serve session token'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('managed-ssh-host')),
            )
            .controller!
            .text,
        'saved.invalid',
      );
      expect(forward.config, isNull);
      expect(channel.state.isConnected, isFalse);
      expect(channel.token, isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      channel.dispose();
    },
  );

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

  for (final serve in [false, true]) {
    testWidgets(
      'preflight storage rejection is visible without Agent acquisition serve=$serve',
      (tester) async {
        final channel = HermesApiChannel(
          serveRecoveryStore: _DeniedClearStore(),
        );
        final forward = FakeForward()..autoVerify = true;
        final controller = ManagedSshConnectionController(forward, channel);
        await const SecureManagedSshHostTrustStore().verify(
          ManagedSshConfig(
            host: input.host,
            username: input.username,
            agentPort: 8642,
          ),
          ManagedSshHostKey('ssh-ed25519', List.filled(32, 3)),
          isCurrent: () => true,
          review: () async => true,
        );
        await mount(tester, controller);
        if (serve) {
          final choice = find.byKey(const ValueKey('managed-ssh-serve-reads'));
          await tester.ensureVisible(choice);
          await tester.tap(choice);
          await tester.pumpAndSettle();
        }
        await submit(tester);
        forward.ready();
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Secure connection storage is unavailable.'),
          findsOneWidget,
        );
        expect(
          find.textContaining('synthetic private storage failure'),
          findsNothing,
        );
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNotNull,
        );
        expect(forward.closes, 1);
        expect(channel.state.isConnected, isFalse);
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
        channel.dispose();
      },
    );
  }

  for (final loss in [false, true]) {
    for (final preflight in [false, true]) {
      test(
        'retired failure cannot cross a newer channel intent loss=$loss preflight=$preflight',
        () async {
          final store = _HeldClearStore()..hold = false;
          final health = Completer<String>();
          final entered = Completer<void>();
          var first = true;
          final channel = HermesApiChannel(
            serveRecoveryStore: store,
            clientBuilder: (config) => HermesApiClient(
              config: config,
              get: (_, _) async {
                if (first && loss) {
                  first = false;
                  entered.complete();
                  return health.future;
                }
                throw const _Denied();
              },
            ),
          );
          final forward = FakeForward()
            ..autoVerify = true
            ..closeGate = Completer<void>();
          final controller = ManagedSshConnectionController(forward, channel);
          final result = controller
              .connectSsh(input, verifyHostKey: (_, _) => true)
              .then<Object>((v) => v, onError: (Object e) => e);
          forward.ready();
          if (loss) {
            await entered.future;
            forward.ended.complete();
          }
          for (var i = 0; i < 100 && forward.closes == 0; i++) {
            await Future<void>.delayed(Duration.zero);
          }
          expect(forward.closes, 1);
          if (loss) health.complete('{"status":"ok"}');
          Future<void>? replacement;
          if (preflight) {
            store.hold = true;
            replacement = channel.connect(
              baseUrl: 'https://replacement.invalid',
            );
            await store.entered.future;
          } else {
            await channel.connect(baseUrl: 'https://replacement.invalid');
            await channel.disconnect();
          }
          forward.closeGate!.complete();
          expect(await result, isFalse);
          if (preflight) {
            store.release.complete();
            await replacement;
          }
          controller.dispose();
          channel.dispose();
        },
      );
    }
  }

  testWidgets('Android SSH offers deliberate serve selection, Linux does not', (
    tester,
  ) async {
    final channel = FakeChannel();
    final forward = FakeForward();
    final controller = ManagedSshConnectionController(forward, channel);
    await mount(tester, controller);
    final choice = find.byKey(const ValueKey('managed-ssh-serve-reads'));
    expect(choice, findsOneWidget);
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.pumpAndSettle();
    expect(find.text('Hermes serve session token'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    await mount(tester, controller);
    expect(choice, findsNothing);
    await tester.pumpWidget(const SizedBox());
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await mount(tester, controller);
    expect(find.byKey(const ValueKey('managed-ssh-host')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    debugDefaultTargetPlatformOverride = null;
    controller.dispose();
    channel.dispose();
  });

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
  testWidgets('reviewed host key survives panel and controller recreation', (
    tester,
  ) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final channel = FakeChannel();
      final forward = FakeForward();
      final controller = ManagedSshConnectionController(forward, channel);
      await mount(tester, controller);
      await submit(tester);
      final trust = Future<bool>.sync(
        () => forward.verify!(
          forward.config!,
          ManagedSshHostKey('ssh-ed25519', List.filled(32, 0)),
        ),
      );
      await tester.pumpAndSettle();
      if (attempt == 0) {
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(
          find.widgetWithText(FilledButton, 'Trust and remember host'),
        );
        await tester.pumpAndSettle();
      } else {
        expect(find.byType(AlertDialog), findsNothing);
      }
      expect(await trust, isTrue);
      forward.ready();
      await tester.pumpAndSettle();
      expect(channel.state.isConnected, isTrue);
      await tester.pumpWidget(const SizedBox());
      await controller.cancel();
      controller.dispose();
      channel.dispose();
    }
  });

  for (final corrupt in [false, true]) {
    testWidgets(
      'remembered host trust blocks changed/corrupt key: corrupt=$corrupt',
      (tester) async {
        final target = ManagedSshConfig(
          host: input.host,
          username: input.username,
          sshPort: input.sshPort,
          agentPort: input.agentPort,
        );
        await const SecureManagedSshHostTrustStore().verify(
          target,
          ManagedSshHostKey('ssh-ed25519', List.filled(32, 0)),
          review: () async => true,
          isCurrent: () => true,
        );
        final storage = const FlutterSecureStorage();
        if (corrupt) {
          final slots = await storage.readAll();
          await storage.write(key: slots.keys.single, value: 'malformed-pin');
        }
        final before = await storage.readAll();
        final channel = FakeChannel();
        final forward = FakeForward();
        final controller = ManagedSshConnectionController(forward, channel);
        await mount(tester, controller);
        await submit(tester);
        final trust = Future<bool>.sync(
          () => forward.verify!(
            forward.config!,
            ManagedSshHostKey('ssh-ed25519', List.filled(32, 1)),
          ),
        );
        await tester.pumpAndSettle();
        expect(await trust, isFalse);
        expect(find.byType(AlertDialog), findsNothing);
        forward.waiting.completeError(
          const ManagedSshException(ManagedSshFailure.hostKeyRejected),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining(
            corrupt
                ? 'could not be read or saved securely'
                : 'differs from the remembered key',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('malformed-pin'), findsNothing);
        expect(channel.token, isNull);
        expect(channel.state.isConnected, isFalse);
        expect(await storage.readAll(), before);
        await tester.pumpWidget(const SizedBox());
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
      await tester.tap(find.text('Trust and remember host'));
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
      await tester.tap(find.text('Trust and remember host'));
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
  testWidgets(
    'controller replacement fences a late old failure and permits the new owner',
    (tester) async {
      final oldChannel = FakeChannel();
      final oldForward = FakeForward();
      final oldController = ManagedSshConnectionController(
        oldForward,
        oldChannel,
      );
      final newChannel = FakeChannel();
      final newForward = FakeForward();
      final newController = ManagedSshConnectionController(
        newForward,
        newChannel,
      );
      var successes = 0;
      await mount(tester, oldController);
      await submit(tester);
      await mount(tester, newController, onConnected: () => successes++);
      oldForward.waiting.completeError(
        const ManagedSshException(ManagedSshFailure.authentication),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('SSH authentication was rejected.'),
        findsNothing,
      );
      await submit(tester);
      newForward.ready();
      await tester.pumpAndSettle();
      expect(successes, 1);
      expect(newChannel.state.isConnected, isTrue);
      expect(newChannel.disconnects, 0);
      await tester.pumpWidget(const SizedBox());
      oldController.dispose();
      newController.dispose();
      oldChannel.dispose();
      newChannel.dispose();
    },
  );

  for (final scenario in [
    'unknown',
    'timeout',
    'storage-load',
    'storage-save',
    'tunnel-loss',
  ]) {
    testWidgets('panel sanitizes and explains $scenario failure', (
      tester,
    ) async {
      final channel = FakeChannel();
      if (scenario == 'tunnel-loss') {
        channel.pending = Completer<void>();
        channel.fail = true;
      }
      final forward = FakeForward()..autoVerify = scenario == 'storage-save';
      final controller = ManagedSshConnectionController(
        forward,
        channel,
        recoveryStore: scenario.startsWith('storage')
            ? _DeniedSshStore(denyLoad: scenario == 'storage-load')
            : null,
      );
      if (scenario == 'storage-save') {
        await const SecureManagedSshHostTrustStore().verify(
          ManagedSshConfig(
            host: input.host,
            username: input.username,
            agentPort: 8642,
          ),
          ManagedSshHostKey('ssh-ed25519', List.filled(32, 3)),
          isCurrent: () => true,
          review: () async => true,
        );
      }
      await mount(tester, controller);
      await submit(tester);
      if (scenario == 'storage-save' || scenario == 'tunnel-loss') {
        forward.ready();
        if (scenario == 'tunnel-loss') {
          await tester.pumpAndSettle();
          forward.ended.complete();
          await tester.pumpAndSettle();
          channel.pending!.complete();
        }
      } else if (scenario != 'storage-load') {
        forward.waiting.completeError(
          scenario == 'timeout'
              ? const ManagedSshException(ManagedSshFailure.timeout)
              : StateError('synthetic-password sensitive endpoint'),
        );
      }
      await tester.pumpAndSettle();
      expect(
        find.textContaining('synthetic-password sensitive endpoint'),
        findsNothing,
      );
      expect(
        find.textContaining('synthetic sensitive storage failure'),
        findsNothing,
      );
      expect(
        find.textContaining(
          scenario.startsWith('storage')
              ? 'Secure connection storage is unavailable.'
              : scenario == 'timeout'
              ? 'SSH connection timed out.'
              : 'Could not establish the SSH connection.',
        ),
        findsOneWidget,
      );
      expect(channel.state.isConnected, isFalse);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      channel.dispose();
    });
  }
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
        final forward = FakeForward()..autoVerify = true;
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
      final forward = FakeForward()..autoVerify = true;
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
        final forward = FakeForward()..autoVerify = true;
        final controller = ManagedSshConnectionController(forward, channel);
        final result = expectLater(
          controller.connectSsh(input, verifyHostKey: (_, _) async => true),
          throwsA(isA<ManagedSshException>()),
        );
        forward.ready();
        if (duringHealth) await entered.future;
        forward.ended.complete();
        await Future<void>.delayed(Duration.zero);
        expect(channel.state.status, HermesConnectionStatus.disconnected);
        health.complete('{"status":"ok"}');
        await result;
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
      forward.closeGate = Completer<void>();
      final cancelling = controller.cancel();
      channel.set(
        channel.state.copyWith(errorMessage: 'synthetic status update'),
      );
      forward.closeGate!.complete();
      await cancelling;
      expect(channel.disconnects, 1);
      expect(channel.state.isConnected, false);
      expect(forward.closes, 1);
      controller.dispose();
      channel.dispose();
    },
  );
}
