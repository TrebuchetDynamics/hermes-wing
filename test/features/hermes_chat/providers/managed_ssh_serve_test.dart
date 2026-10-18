import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:wing/core/hermes/client/hermes_api_client.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/setup/secure_managed_ssh_recovery_store.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/l10n/app_localizations.dart';
import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_hermes_gateway_directory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/setup/secure_hermes_serve_recovery_store.dart';
import 'package:wing/core/hermes/ssh/managed_ssh.dart';
import 'package:wing/core/hermes/ssh/ssh_connection_request.dart';
import 'package:wing/features/hermes_chat/providers/managed_ssh_connection_controller.dart';

import '../../../../integration_test/support/local_serve_chat_fixture.dart';
import '../../../../integration_test/support/local_serve_read_fixture.dart';

class _RecoveryStore implements HermesServeRecoveryStore {
  final saved = <HermesServeRecoverySelection>[];
  Completer<void>? heldClear;
  Completer<void>? clearing;
  @override
  Future<HermesServeRecoverySelection?> load() async => null;
  @override
  Future<void> save(HermesServeRecoverySelection selection) async {
    saved.add(selection);
  }

  @override
  Future<void> clear() async {
    if (!(clearing?.isCompleted ?? true)) clearing!.complete();
    await heldClear?.future;
  }
}

class _SshStore extends SecureManagedSshRecoveryStore {
  bool rejectSaves = false;
  @override
  Future<void> save(ManagedSshRecovery selection) {
    if (rejectSaves) throw StateError('synthetic sensitive storage failure');
    return super.save(selection);
  }
}

// Only the SSH network boundary is substituted; Agent HTTP, ticket, RPC,
// channel/controller ownership and recovery policy are production code.
class _Forward extends ManagedSshForward {
  _Forward(this.origin);
  String origin;
  var ended = Completer<void>();
  int fingerprintByte = 0;
  @override
  Future<ManagedSshTunnel> connect({
    required ManagedSshConfig configuration,
    required ManagedSshCredentials authentication,
    ManagedSshHostKeyVerifier? verifyHostKey,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (!await (verifyHostKey?.call(
          configuration,
          ManagedSshHostKey('ssh-ed25519', List.filled(32, fingerprintByte)),
        ) ??
        false)) {
      throw const ManagedSshException(ManagedSshFailure.hostKeyRejected);
    }
    if (ended.isCompleted) ended = Completer<void>();
    return ManagedSshTunnel(
      agentUri: Uri.parse(origin).replace(
        path: configuration.agentProfile == null
            ? ''
            : '/p/${configuration.agentProfile}',
      ),
      done: ended.future,
      close: disconnect,
    );
  }

  @override
  Future<void> disconnect() async {
    if (!ended.isCompleted) ended.complete();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LocalServeChatFixture fixture;
  late _RecoveryStore store;
  late HermesApiChannel channel;
  late _Forward forward;
  late ManagedSshConnectionController controller;
  late _SshStore sshStore;
  setUp(() async {
    HttpOverrides.global = null;
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    fixture = LocalServeChatFixture();
    await fixture.start();
    store = _RecoveryStore();
    channel = HermesApiChannel(serveRecoveryStore: store);
    forward = _Forward(fixture.origin);
    sshStore = _SshStore();
    controller = ManagedSshConnectionController(
      forward,
      channel,
      recoveryStore: sshStore,
    );
  });
  tearDown(() async {
    controller.dispose();
    channel.dispose();
    await fixture.close();
    debugDefaultTargetPlatformOverride = null;
  });
  Future<bool> connect({String token = LocalServeReadFixture.token}) =>
      controller.connectSsh(
        SshConnectionRequest(
          host: 'example.invalid',
          sshPort: 22,
          username: 'synthetic',
          password: 'synthetic-password',
          agentPort: 8642,
          agentBearerToken: token,
          transport: SshAgentTransport.serve,
        ),
        verifyHostKey: (_, _) => true,
      );

  test(
    'Android SSH serve reads and deliberate chat never save a transient origin',
    () async {
      expect(await connect(), true);
      expect(channel.state.isServeReadOnly, true);
      expect(channel.state.activeMessages.last.text, 'default fixture answer');
      expect(fixture.minted, 0);
      await channel.selectProfile('demo');
      expect(channel.state.selectedProfileId, 'demo');
      expect(channel.state.activeSessionId, 'demo-session');
      await channel.enableLocalServeChat();
      expect(channel.state.serveChat?.canSubmit, true);
      expect(fixture.count('prompt.submit'), 0);
      fixture.dropSubmit = true;
      await expectLater(
        channel.sendText('deliberate synthetic turn'),
        throwsA(isA<Exception>()),
      );
      expect(channel.state.hasUnreconciledRun, true);
      fixture.dropSubmit = false;
      await channel.retryLocalServeConversation();
      expect(channel.state.serveChat?.canSubmit, true);
      expect(fixture.count('prompt.submit'), 1);
      final submitted = fixture.rpc.singleWhere(
        (r) => r['method'] == 'prompt.submit',
      );
      expect(submitted['params'], containsPair('profile', 'demo'));
      expect(
        submitted['params'],
        containsPair('session_id', 'runtime-demo-session'),
      );
      expect(store.saved, isEmpty);
    },
  );

  test(
    'Android SSH separates REST authentication from ticket and owner authorization',
    () async {
      expect(await connect(token: 'synthetic-wrong-token'), false);
      expect(channel.state.isConnected, false);
      expect(fixture.minted, 0);
      forward = _Forward(fixture.origin);
      controller.dispose();
      controller = ManagedSshConnectionController(forward, channel);
      expect(await connect(), true);
      fixture.denyTicket = true;
      await channel.enableLocalServeChat();
      expect(channel.state.isConnected, true);
      expect(channel.state.serveChat, isNull);
      await expectLater(channel.sendText('not sent'), throwsStateError);
      fixture.denyTicket = false;
      fixture.resumedProfile = 'different-owner';
      await channel.enableLocalServeChat();
      expect(channel.state.serveChat, isNull);
      expect(fixture.count('prompt.submit'), 0);
      expect(fixture.count('approval.respond'), 0);
      expect(fixture.count('session.interrupt'), 0);
      expect(store.saved, isEmpty);
    },
  );

  test(
    'superseded SSH cleanup cannot adopt or disconnect a same-origin replacement',
    () async {
      fixture.unsupported = true;
      await channel.connectLocalServeReads(
        baseUrl: fixture.origin,
        credential: LocalServeReadFixture.token,
      );
      fixture.unsupported = false;
      store.heldClear = Completer<void>();
      store.clearing = Completer<void>();
      fixture.profilesRequested = Completer<void>();
      fixture.holdProfiles = Completer<void>();
      final obsolete = connect();
      await store.clearing!.future;
      final replacement = channel.retryLocalServeConversation();
      await fixture.profilesRequested!.future;
      store.heldClear!.complete();
      expect(await obsolete, false);
      fixture.holdProfiles!.complete();
      await replacement;
      expect(channel.state.isConnected, true);
      expect(channel.state.connectedBaseUrl, fixture.origin);
      expect(channel.state.activeSessionId, 'default-session');
      expect(forward.ended.isCompleted, true);
    },
  );

  test(
    'stale SSH reads cannot invalidate a replacement waiting for secure storage',
    () async {
      fixture.profilesRequested = Completer<void>();
      fixture.holdProfiles = Completer<void>();
      final obsolete = connect();
      await fixture.profilesRequested!.future;
      store.heldClear = Completer<void>();
      store.clearing = Completer<void>();
      final replacement = channel.connectLocalServeReads(
        baseUrl: fixture.origin,
        credential: LocalServeReadFixture.token,
      );
      await store.clearing!.future;
      fixture.holdProfiles!.complete();
      expect(await obsolete, false);
      store.heldClear!.complete();
      await replacement;
      expect(channel.state.isConnected, true);
      expect(channel.state.activeSessionId, 'default-session');
      expect(forward.ended.isCompleted, true);
    },
  );

  test(
    'SSH loss during serve adoption rejects late reads and cannot retry its origin',
    () async {
      fixture.profilesRequested = Completer<void>();
      fixture.holdProfiles = Completer<void>();
      final pending = connect();
      await fixture.profilesRequested!.future;
      await forward.disconnect();
      fixture.holdProfiles!.complete();
      expect(await pending, false);
      expect(channel.state.isConnected, false);
      final requests = List.of(fixture.requests);
      await channel.retryLocalServeConversation();
      expect(fixture.requests, requests);
      expect(store.saved, isEmpty);
    },
  );

  test(
    'SSH loss after chat qualification revokes only that lease without replay',
    () async {
      expect(await connect(), true);
      await channel.selectProfile('demo');
      await channel.enableLocalServeChat();
      fixture.dropSubmit = true;
      await expectLater(
        channel.sendText('synthetic uncertain turn'),
        throwsException,
      );
      final disconnected = Completer<void>();
      void changed() {
        if (!channel.state.isConnected && !disconnected.isCompleted) {
          disconnected.complete();
        }
      }

      channel.addListener(changed);
      await forward.disconnect();
      await disconnected.future;
      channel.removeListener(changed);
      expect(channel.state.selectedProfileId, 'demo');
      expect(channel.state.activeSessionId, 'demo-session');
      expect(channel.state.hasUnreconciledRun, true);
      final requests = List.of(fixture.requests);
      await channel.retryLocalServeConversation();
      expect(fixture.requests, requests);
      expect(channel.state.serveChat, isNull);
      expect(fixture.count('prompt.submit'), 1);
      expect(fixture.count('approval.respond'), 0);
      expect(fixture.count('session.interrupt'), 0);
      final oldOrigin = fixture.origin;
      await fixture.close();
      fixture = LocalServeChatFixture();
      await fixture.start();
      expect(fixture.origin, isNot(oldOrigin));
      forward.origin = fixture.origin;
      expect(await connect(), true);
      expect(channel.state.selectedProfileId, 'demo');
      expect(channel.state.activeSessionId, 'demo-session');
      expect(channel.state.hasUnreconciledRun, true);
      await channel.retryLocalServeConversation();
      expect(channel.state.serveChat?.canSubmit, true);
      expect(channel.state.hasUnreconciledRun, false);
      expect(fixture.count('prompt.submit'), 0);
      expect(fixture.count('approval.respond'), 0);
      expect(fixture.count('session.interrupt'), 0);
      expect(store.saved, isEmpty);
    },
  );

  for (final prefix in [null, 'demo']) {
    test(
      'advertised SSH restores only the remembered owner without reading default-session history prefix=$prefix',
      () async {
        controller.dispose();
        channel.dispose();
        final admitted = <String>[];
        final histories = <String>[];
        final capabilities = {
          'schema_version': 1,
          'profile_context': {
            'type': 'query',
            'name': 'profile',
            'required': true,
            'default_profile_id': 'default',
          },
          'auth': {
            'type': 'bearer',
            'required': true,
            'granted_scopes': ['profiles:read'],
          },
          'features': <String, bool>{},
          'endpoints': {
            'profiles': {
              'method': 'GET',
              'path': '/api/profiles',
              'required_scopes': ['profiles:read'],
            },
            'session_messages': {
              'method': 'GET',
              'path': '/api/sessions/{session_id}/messages',
              'profile_scoped': true,
            },
          },
        };
        channel = HermesApiChannel(
          clientBuilder: (config) => HermesApiClient(
            config: config,
            get: (uri, _) async {
              if (uri.path.endsWith('/messages')) {
                histories.add(uri.path);
                expect(
                  uri.queryParameters['profile'],
                  prefix == null ? 'demo' : isNull,
                );
                expect(
                  uri.path,
                  '${prefix == null ? '' : '/p/$prefix'}/api/sessions/remembered/messages',
                );
                return '{"object":"list","session_id":"remembered","data":[]}';
              }
              return switch (uri.path.replaceFirst(
                prefix == null ? '' : '/p/$prefix',
                '',
              )) {
                '/health' => '{"status":"ok"}',
                '/v1/capabilities' => jsonEncode(capabilities),
                '/api/profiles' =>
                  '{"data":[{"id":"default","name":"Default"},{"id":"demo","name":"Demo"}]}',
                '/api/sessions' =>
                  '{"data":[{"id":"wrong-default","source":"api_server"},{"id":"remembered","source":"api_server"}],"has_more":false}',
                _ => throw StateError('Unexpected read'),
              };
            },
          ),
        );
        channel.addListener(() {
          if (channel.state.activeSessionId != null) {
            admitted.add(channel.state.activeSessionId!);
          }
        });
        final config = ManagedSshConfig(
          host: 'example.invalid',
          username: 'synthetic',
          agentPort: 8642,
          agentProfile: prefix,
        );
        await sshStore.save(
          ManagedSshRecovery(
            configuration: config,
            transport: SshAgentTransport.advertisedApi,
            hostKey: ManagedSshHostKey('ssh-ed25519', List.filled(32, 0)),
            profile: 'demo',
            session: 'remembered',
            uncertain: false,
          ),
        );
        controller = ManagedSshConnectionController(
          forward,
          channel,
          recoveryStore: sshStore,
        );
        expect(
          await controller.connectSsh(
            SshConnectionRequest(
              host: 'example.invalid',
              sshPort: 22,
              username: 'synthetic',
              password: 'synthetic-password',
              agentPort: 8642,
              agentProfile: prefix,
              agentBearerToken: LocalServeReadFixture.token,
            ),
            verifyHostKey: (_, _) => true,
          ),
          true,
        );
        expect(admitted, isNotEmpty);
        expect(admitted.toSet(), {'remembered'});
        expect(histories, [
          '${prefix == null ? '' : '/p/$prefix'}/api/sessions/remembered/messages',
        ]);
        expect(channel.state.selectedProfileId, 'demo');
      },
    );
  }

  test(
    'failed SSH stream uncertainty survives navigation and reconnect without resubmission',
    () async {
      controller.dispose();
      channel.dispose();
      var sends = 0;
      channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, _) async {
            if (uri.path.endsWith('/messages')) {
              return jsonEncode({
                'object': 'list',
                'session_id': uri.pathSegments[2],
                'data': [],
              });
            }
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => jsonEncode({
                'schema_version': 1,
                'features': {'session_chat_streaming': true},
                'endpoints': {
                  'session_chat_stream': {
                    'method': 'POST',
                    'path': '/api/sessions/{session_id}/chat/stream',
                  },
                  'session_messages': {
                    'method': 'GET',
                    'path': '/api/sessions/{session_id}/messages',
                  },
                },
              }),
              '/api/sessions' =>
                '{"data":[{"id":"remembered","source":"api_server"},{"id":"other","source":"api_server"}]}',
              _ => throw StateError('Unexpected read'),
            };
          },
          postStream: (_, _, _) {
            sends++;
            // A loses its terminal event; B completes through its own stream.
            return sends == 1
                ? const Stream<String>.empty()
                : Stream.value('data: [DONE]\n\n');
          },
        ),
      );
      controller = ManagedSshConnectionController(
        forward,
        channel,
        recoveryStore: sshStore,
      );
      Future<bool> connectApi() => controller.connectSsh(
        const SshConnectionRequest(
          host: 'example.invalid',
          sshPort: 22,
          username: 'synthetic',
          password: 'synthetic-password',
          agentPort: 8642,
          agentBearerToken: null,
        ),
        verifyHostKey: (_, _) => true,
      );
      expect(await connectApi(), true);
      await channel.sendText('synthetic uncertain work');
      expect(controller.recoveryTarget?.uncertain, true);
      expect(channel.state.hasUnreconciledRun, true);
      await channel.selectSession('other');
      await channel.sendText('synthetic separate work');
      expect(controller.recoveryTarget?.uncertain, false);
      channel.clearActiveSession();
      await channel.disconnect();
      // Connect stays closed until the retired lease finishes teardown.
      await controller.cancel();
      expect(await connectApi(), true);
      expect(channel.state.activeSessionId, isNull);
      await channel.selectSession('remembered');
      await expectLater(
        channel.sendText('must not submit again'),
        throwsStateError,
      );
      expect(channel.state.hasUnreconciledRun, true);
      expect(sends, 2);
    },
  );

  test(
    'saved SSH owners survive host switches but reject changed fingerprints before Agent reads',
    () async {
      expect(await connect(), true);
      await channel.selectProfile('demo');
      await channel.disconnect();
      forward.fingerprintByte = 1;
      final reads = List.of(fixture.requests);
      await expectLater(
        connect(),
        throwsA(
          isA<ManagedSshException>().having(
            (e) => e.failure,
            'failure',
            ManagedSshFailure.hostKeyRejected,
          ),
        ),
      );
      expect(fixture.requests, reads);
      forward.fingerprintByte = 0;
      expect(
        await controller.connectSsh(
          const SshConnectionRequest(
            host: 'other.invalid',
            sshPort: 22,
            username: 'synthetic',
            password: 'synthetic-password',
            agentPort: 8642,
            agentBearerToken: LocalServeReadFixture.token,
            transport: SshAgentTransport.serve,
          ),
          verifyHostKey: (_, _) => true,
        ),
        true,
      );
      expect(channel.state.activeSessionId, 'default-session');
      await channel.disconnect();
      expect(await connect(), true);
      expect(channel.state.selectedProfileId, 'demo');
      expect(channel.state.activeSessionId, 'demo-session');
      expect(fixture.count('prompt.submit'), 0);
    },
  );

  test(
    'failed secure uncertainty save prevents a forwarded Send until explicit recovery',
    () async {
      expect(await connect(), true);
      await channel.enableLocalServeChat();
      sshStore.rejectSaves = true;
      await expectLater(
        channel.sendText('synthetic not submitted'),
        throwsStateError,
      );
      expect(fixture.count('prompt.submit'), 0);
      sshStore.rejectSaves = false;
      await channel.retryLocalServeConversation();
      await channel.sendText('synthetic deliberate submission');
      expect(fixture.count('prompt.submit'), 1);
      expect(fixture.count('approval.respond'), 0);
      expect(fixture.count('session.interrupt'), 0);
    },
  );

  testWidgets(
    'interrupted SSH Retry reopens the exact target with blank authentication',
    (tester) async {
      await tester.runAsync(() async {
        expect(await connect(), true);
        channel.clearActiveSession();
        await Future<void>.delayed(Duration.zero);
      });
      expect(controller.recoveryTarget?.session, isNull);
      final endpoints = FakeHermesEndpointStore();
      final directory = HermesGatewayDirectory(
        store: endpoints,
        cache: FakeGatewayContactCache(),
        loader: FakeGatewaySummaryLoader({}),
        activeChannel: channel,
      );
      final container = ProviderContainer(
        overrides: [
          managedSshConnectionControllerProvider.overrideWithValue(controller),
          hermesChannelProvider.overrideWithValue(channel),
          hermesGatewayDirectoryProvider.overrideWith((_) => directory),
          hermesEndpointStoreProvider.overrideWithValue(endpoints),
          hermesVoiceCaptureServiceProvider.overrideWithValue(null),
          hermesTextToSpeechServiceProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);
      // Production creates the controller through its provider when SSH starts.
      container.read(managedSshConnectionControllerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HermesChatScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.runAsync(() async {
        await forward.disconnect();
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(channel.state.isConnected, false);
      expect(controller.needsSshReconnect, true);
      final retry = find.descendant(
        of: find.byKey(const ValueKey('managed-ssh-interrupted')),
        matching: find.byType(FilledButton),
      );
      expect(retry, findsOneWidget);
      final requests = List.of(fixture.requests);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      String text(String name) => tester
          .widget<TextFormField>(find.byKey(ValueKey('managed-ssh-$name')))
          .controller!
          .text;
      expect(text('host'), 'example.invalid');
      expect(text('username'), 'synthetic');
      expect(text('password'), isEmpty);
      expect(text('agent-token'), isEmpty);
      expect(fixture.requests, requests);
      expect(await endpoints.loadProfiles(), isEmpty);
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
