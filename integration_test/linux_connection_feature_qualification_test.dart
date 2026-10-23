import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/local_discovery/local_hermes_home_discovery.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/providers/managed_ssh_connection_controller.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';

import 'support/direct_first_run_native_fixture.dart';
import 'support/linux_connection_feature_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late LinuxConnectionCases cases;
  setUpAll(() => cases = LinuxConnectionCases());
  setUp(() async {
    // Synthetic trust faults are separate from the real private-keyring runner.
    FlutterSecureStorage.setMockInitialValues({});
    await (await SharedPreferences.getInstance()).clear();
  });

  testWidgets(
    'GTK Local cancel, denied metadata and retired picker cannot select a new owner',
    (tester) async {
      final h = LinuxConnectionHarness();
      await h.mount(tester);
      expect(h.home.inspections, ['/synthetic/.hermes']);
      await h.activate(tester, 'platform-local-choose-home');
      expect(h.home.inspections, ['/synthetic/.hermes']);
      expect(find.text('/synthetic/.hermes'), findsOneWidget);

      h.home.denied = LocalHermesHomeStatus.unreadable;
      h.picker = () async => '/synthetic/denied';
      await h.activate(tester, 'platform-local-choose-home');
      expect(connectionControl('platform-local-home-path'), findsNothing);
      expect(find.text('Directory found — discovery only'), findsNothing);

      final pending = Completer<String?>();
      h.picker = () => pending.future;
      await h.activate(tester, 'platform-local-choose-home');
      await h.activate(tester, 'hermes-connection-mode-remote');
      await h.activate(tester, 'hermes-connection-mode-local');
      pending.complete('/synthetic/stale');
      await tester.pumpAndSettle();
      expect(h.home.inspections, [
        '/synthetic/.hermes',
        '/synthetic/denied',
        '/synthetic/.hermes',
      ]);
      expect(find.text('/synthetic/stale'), findsNothing);
      expect(h.channel.connects, 0);
      expect(h.store.attempts, 0);
      expect(h.fixture.requests, isEmpty);
      expect(connectionControl('hermes-open-local-setup'), findsNothing);
      expect(connectionControl('hermes-open-qr-scanner'), findsNothing);
      expect(tester.takeException(), isNull);
      cases.record(
        'connections.local-picker-recovery',
        ['HD-LOCAL', 'HD-ENTRY'],
        {
          'metadata_inspections': h.home.inspections.length,
          'connects': h.channel.connects,
          'saves': h.store.attempts,
        },
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'GTK late Remote bootstrap cannot replace a deliberate replacement owner',
    (tester) async {
      final h = LinuxConnectionHarness();
      await h.mount(tester, mode: HermesConnectionMode.remote);
      await h.edit(
        tester,
        'hermes-base-url-field',
        DirectFirstRunNativeFixture.origin,
      );
      final gate = Completer<void>();
      h.fixture.bootstrapGate = gate;
      await tester.ensureVisible(connectionControl('hermes-connect-button'));
      await tester.tap(connectionControl('hermes-connect-button'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(h.fixture.bootstrapGate, isNull);
      expect(h.channel.state.status, HermesConnectionStatus.connecting);
      await h.channel.connect(baseUrl: 'https://other.example.invalid');
      final owner = h.channel.state;
      final disconnects = h.channel.disconnects;
      final reads = h.fixture.requests.length;
      gate.complete();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      expect(h.channel.state, same(owner));
      expect(h.channel.state.connectedBaseUrl, 'https://other.example.invalid');
      expect(h.channel.disconnects, disconnects);
      expect(h.channel.connects, 2);
      expect(h.store.attempts, 0);
      // The retired bootstrap may finish its original read, never a read
      // against the replacement origin or a channel/storage mutation.
      expect(h.fixture.readOrigins.sublist(reads), [
        DirectFirstRunNativeFixture.origin,
      ]);
      expect(h.fixture.mutationAttempts, 0);
      expect(tester.takeException(), isNull);
      cases.record(
        'connections.bootstrap-owner-replacement',
        ['HD-REMOTE', 'HD-HOSTS'],
        {
          'connects': h.channel.connects,
          'saves': h.store.attempts,
          'late_read_delta': h.fixture.requests.length - reads,
          'mutations': h.fixture.mutationAttempts,
        },
        owners: 2,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'GTK saved-origin edit cannot borrow stored authorization or reconnect on cancel',
    (tester) async {
      final h = LinuxConnectionHarness();
      await h.store.saveAll(const [
        HermesEndpointConfig(
          id: 'synthetic-saved',
          baseUrl: DirectFirstRunNativeFixture.origin,
          apiKey: 'synthetic-original',
          label: 'Synthetic saved host',
        ),
      ]);
      await h.mount(tester, mode: HermesConnectionMode.remote);
      await h.activate(tester, 'hermes-endpoint-profile-edit-synthetic-saved');
      await h.edit(
        tester,
        'hermes-saved-edit-url',
        'https://other.example.invalid',
      );
      final builds = h.fixture.configurations.length;
      final probes = h.fixture.readOrigins.length;
      await h.activate(tester, 'hermes-saved-edit-test');
      expect(h.fixture.configurations.length, builds + 1);
      expect(h.fixture.configurations.last.apiKey, isNull);
      expect(h.fixture.authorizationKinds.sublist(probes), ['absent']);
      expect(h.fixture.readOrigins.sublist(probes), [
        'https://other.example.invalid',
      ]);
      expect(
        tester
            .widget<TextField>(connectionControl('hermes-saved-edit-key'))
            .controller!
            .text,
        isEmpty,
      );
      await h.edit(tester, 'hermes-saved-edit-key', 'synthetic-replacement');
      h.fixture.deniedBootstrapStatus = 403;
      await h.activate(tester, 'hermes-saved-edit-test');
      expect(
        h.fixture.configurations.last.baseUri.origin,
        'https://other.example.invalid',
      );
      expect(
        h.fixture.configurations.last.apiKey == 'synthetic-replacement',
        isTrue,
      );
      expect(h.fixture.authorizationKinds.sublist(probes), [
        'absent',
        'replacement',
      ]);
      expect(h.fixture.readOrigins.sublist(probes), [
        'https://other.example.invalid',
        'https://other.example.invalid',
      ]);
      expect(find.textContaining('denied this credential'), findsOneWidget);
      expect(find.textContaining('private-response'), findsNothing);
      await h.activate(tester, 'hermes-saved-edit-cancel');
      expect(
        (await h.store.loadProfiles()).single.baseUrl,
        DirectFirstRunNativeFixture.origin,
      );
      expect(
        (await h.store.loadProfiles()).single.apiKey == 'synthetic-original',
        isTrue,
      );
      expect(h.store.attempts, 0);
      expect(h.channel.connects, 0);
      expect(h.fixture.mutationAttempts, 0);
      cases.record(
        'connections.saved-origin-credential-custody',
        ['HD-REMOTE', 'HD-HOSTS'],
        {
          'draft_probes': h.fixture.configurations.length - builds,
          'connects': h.channel.connects,
          'saves': h.store.attempts,
          'mutations': h.fixture.mutationAttempts,
        },
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'GTK trust cancel and controller replacement cannot authorize retired SSH review',
    (tester) async {
      final h = LinuxConnectionHarness();
      final forward = ConnectionTrustForward();
      final controller = ManagedSshConnectionController(forward, h.channel);
      final replacementForward = ConnectionTrustForward();
      final replacement = ManagedSshConnectionController(
        replacementForward,
        h.channel,
      );
      addTearDown(controller.dispose);
      addTearDown(replacement.dispose);
      await h.mount(tester, ssh: controller, mode: HermesConnectionMode.ssh);
      Future<void> submit() async {
        for (final field in {
          'host': 'example.invalid',
          'username': 'synthetic-user',
          'password': 'synthetic-password',
          'agent-token': 'synthetic-original',
        }.entries) {
          await h.edit(tester, 'managed-ssh-${field.key}', field.value);
        }
        FocusManager.instance.primaryFocus?.unfocus();
        final connect = find.widgetWithText(FilledButton, 'Connect via SSH');
        await tester.ensureVisible(connect);
        await tester.tap(connect);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
      }

      await submit();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(TextButton, 'Cancel'),
        ),
      );
      await tester.pumpAndSettle();
      expect(forward.accepted, isFalse);
      expect(await const FlutterSecureStorage().readAll(), isEmpty);
      await submit();
      h.replaceSsh(replacement);
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Trust and remember host'),
      );
      await tester.pumpAndSettle();
      expect(forward.accepted, isFalse);
      expect(replacementForward.attempts, 0);
      expect(h.channel.connects, 0);
      expect(h.store.attempts, 0);
      expect(await const FlutterSecureStorage().readAll(), isEmpty);
      expect(tester.takeException(), isNull);
      cases.record(
        'connections.ssh-retired-trust-review',
        ['HD-SSH'],
        {
          'ssh_attempts': forward.attempts,
          'trust_reviews': forward.reviews,
          'replacement_attempts': replacementForward.attempts,
          'agent_connects': h.channel.connects,
          'saves': h.store.attempts,
        },
        owners: 2,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await controller.cancel();
      await replacement.cancel();
    },
  );

  testWidgets(
    'GTK denied discovery stays unavailable until explicit retry without mutation replay',
    (tester) async {
      final h = LinuxConnectionHarness();
      await h.mount(tester, mode: HermesConnectionMode.remote);
      await h.edit(
        tester,
        'hermes-base-url-field',
        DirectFirstRunNativeFixture.origin,
      );
      h.fixture.deniedBootstrapStatus = 401;
      await h.activate(tester, 'hermes-connect-button');
      expect(find.text('Hermes API rejected the API key.'), findsOneWidget);
      final reads = h.fixture.requests.length;
      await tester.pump(const Duration(seconds: 3));
      expect(h.fixture.requests.length, reads);
      expect(h.channel.connects, 1);
      expect(h.store.attempts, 0);
      h.fixture.deniedBootstrapStatus = null;
      h.store.reject = true;
      await h.activate(tester, 'hermes-connect-button');
      expect(h.channel.connects, 2);
      expect(h.channel.state.isConnected, isTrue);
      expect(connectionControl('hermes-connection-save-error'), findsOneWidget);
      expect(connectionControl('hermes-local-serve-chat'), findsNothing);
      expect(h.channel.state.canCreateSessions, isFalse);
      expect(h.channel.state.canWriteProviders, isFalse);
      final settledReads = h.fixture.requests.length;
      await tester.pump(const Duration(seconds: 3));
      expect(h.fixture.requests.length, settledReads);
      expect(h.store.attempts, 1);
      expect(h.fixture.mutationAttempts, 0);
      expect(h.fixture.forbiddenReadAttempts, 0);
      expect(tester.takeException(), isNull);
      cases.record(
        'connections.absent-native-contracts-no-replay',
        ['HD-ENTRY', 'HD-REMOTE', 'HD-LOCAL', 'HD-SSH'],
        {
          'connects': h.channel.connects,
          'save_attempts': h.store.attempts,
          'mutations': h.fixture.mutationAttempts,
          'idle_read_delta': h.fixture.requests.length - settledReads,
        },
        unsupported: true,
        reason:
            'Synthetic REST reads do not advertise native chat, lifecycle, pairing or installation. Deliberate native chat negotiation is not exercised.',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await cases.publish(tester);
    },
  );
}
