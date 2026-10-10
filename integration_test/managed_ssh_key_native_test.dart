import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/app/wing_app.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/features/hermes_chat/widgets/managed_ssh_connection_form.dart';

import '../test/features/hermes_chat/support/fake_hermes_endpoint_store.dart';
import 'support/managed_ssh_key_native_fixture.dart';

Finder control(String id) => find.byKey(ValueKey(id));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('full app disposable managed SSH key read-only workflow', (
    tester,
  ) async {
    const isolated = bool.fromEnvironment('WING_SSH_KEY_ISOLATED');
    if (!isolated || (!Platform.isLinux && !Platform.isAndroid)) {
      throw StateError('Use the isolated native SSH key launcher');
    }
    // Local storage acquisition only is substituted. No channel, API client,
    // managed controller or SSH forward provider is overridden.
    SharedPreferences.setMockInitialValues({});
    final fixture = await ManagedSshKeyNativeFixture.load();
    addTearDown(fixture.dispose);
    final selector = ManagedSshKeyDocumentSelector();
    final original = installManagedSshDocumentSelector(selector);
    addTearDown(() => restoreManagedSshDocumentSelector(original));
    final container = ProviderContainer(
      overrides: [
        hermesEndpointStoreProvider.overrideWithValue(
          FakeHermesEndpointStore(),
        ),
        hermesVoiceCaptureServiceProvider.overrideWithValue(null),
        hermesTextToSpeechServiceProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);
    final channel = container.read(hermesChannelProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WingApp()),
    );

    Future<void> until(bool Function() ready, String reason) async {
      for (var attempt = 0; attempt < 150; attempt++) {
        await tester.pump(const Duration(milliseconds: 100));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        if (ready()) return;
      }
      fail(reason); // Never interpolate runtime values or key parser errors.
    }

    Future<void> tap(Finder finder) async {
      await until(() => finder.evaluate().isNotEmpty, 'Expected UI missing');
      await tester.ensureVisible(finder.first);
      await tester.tap(finder.first);
      await tester.pump(const Duration(milliseconds: 150));
    }

    Future<void> edit(String id, String value) async {
      final finder = control(id);
      await until(() => finder.evaluate().isNotEmpty, 'Expected field missing');
      await tester.ensureVisible(finder);
      await tester.enterText(finder, value);
      await tester.pump();
    }

    final form = find.byType(ManagedSshConnectionForm);
    Finder formButton(Type type) =>
        find.descendant(of: form, matching: find.byType(type));
    Future<Map<String, dynamic>> stats() async =>
        (await tester.runAsync(() => fixture.control('stats')))!;
    Map<String, dynamic> reads(Map<String, dynamic> value) =>
        value['requests'] as Map<String, dynamic>;
    Future<void> open() async {
      if (form.evaluate().isEmpty) {
        if (control('hermes-welcome-ssh').evaluate().isNotEmpty) {
          await tap(control('hermes-welcome-ssh'));
        } else {
          if (control('hermes-connection-mode-ssh').evaluate().isEmpty) {
            await tap(control('hermes-connect-another-gateway'));
          }
          await tap(control('hermes-connection-mode-ssh'));
        }
      }
      await until(() => form.evaluate().isNotEmpty, 'Managed form not mounted');
      await edit('managed-ssh-host', fixture.host);
      await edit('managed-ssh-ssh-port', '${fixture.sshPort}');
      await edit('managed-ssh-username', fixture.username);
      await edit('managed-ssh-agent-port', '${fixture.agentPort}');
      await tap(control('managed-ssh-auth-private-key'));
    }

    Future<void> pick(String mode) async {
      selector.next = fixture.document(mode);
      await tap(control('managed-ssh-select-key'));
    }

    Future<void> submit() async {
      await edit('managed-ssh-agent-token', fixture.agentToken);
      await tap(formButton(FilledButton));
    }

    Future<void> trust() async {
      await until(
        () => find.byType(AlertDialog).evaluate().isNotEmpty,
        'Host trust review missing',
      );
      // Compare the exact generated out-of-band fingerprint before accepting.
      // Avoid expect(actual, expected): failure output could expose metadata.
      if (find.text(fixture.fingerprint).evaluate().length != 1) {
        fail('Host fingerprint mismatch; refusing connection');
      }
      await tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        ),
      );
    }

    await until(
      () =>
          control('hermes-welcome-ssh').evaluate().isNotEmpty ||
          control('hermes-connection-mode-ssh').evaluate().isNotEmpty,
      'Public managed SSH entry missing',
    );
    final initial = await stats();
    expect(reads(initial), isEmpty);
    await open();
    await pick('invalid');
    await submit();
    await tester.pump(const Duration(seconds: 1));
    expect(channel.state.isConnected, false);
    expect(reads(await stats()), reads(initial));
    expect(find.byType(AlertDialog), findsNothing);

    await pick('wrong');
    await submit();
    await trust();
    await until(
      () =>
          tester.widget<FilledButton>(formButton(FilledButton)).onPressed !=
          null,
      'Authentication failure did not settle',
    );
    expect(channel.state.isConnected, false);
    final wrong = await stats();
    expect(wrong['ssh_auths'], 0);
    expect(wrong['ssh_denials'], greaterThan(0));
    expect(reads(wrong), reads(initial));

    // A late selected document must not resurrect a cancelled form.
    // Use a typed helper in the fixture to hold the document platform result.
    final selection = selector.hold();
    await tap(control('managed-ssh-select-key'));
    await tester.pump(const Duration(milliseconds: 300));
    await tap(formButton(TextButton));
    selection.complete(fixture.document('valid'));
    await tester.pump(const Duration(seconds: 1));
    expect(channel.state.isConnected, false);
    expect(reads(await stats()), reads(initial));

    // Hold the real Agent bootstrap after SSH authentication, then cancel the
    // production form before releasing its late response.
    await open();
    await pick('valid');
    await tester.runAsync(() => fixture.control('hold'));
    await submit();
    await trust();
    await until(
      () => (channel.state.status == HermesConnectionStatus.connecting),
      'Bootstrap did not start',
    );
    await tap(formButton(TextButton));
    await tester.runAsync(() => fixture.control('release'));
    await until(
      () => !(channel.state.status == HermesConnectionStatus.connecting),
      'Cancelled bootstrap remained active',
    );
    expect(channel.state.isConnected, false);
    final stale = await stats();
    expect(reads(stale)['GET /api/sessions'] ?? 0, 0);

    final cycles = <Map<String, dynamic>>[];
    for (var cycle = 0; cycle < 2; cycle++) {
      await open();
      await pick('valid');
      final before = await stats();
      await submit();
      await trust();
      await until(
        () => channel.state.isConnected,
        'SSH/Agent connection failed',
      );
      await tap(control('hermes-profile-switcher'));
      await tap(control('chat-profile-row-qa-key'));
      await until(
        () =>
            channel.state.selectedProfileId == 'qa-key' &&
            channel.state.activeSessionId == 'qa-history',
        'Exact profile/session not restored',
      );
      await until(
        () => find.text('Disposable SSH key history').evaluate().isNotEmpty,
        'Canonical history not visible',
      );
      // Read-only model qualification: no session model-lock endpoint exists.
      await tester.runAsync(() => channel.loadModelOptions());
      expect(channel.state.modelOptions, isNotNull);
      expect(channel.state.modelOptions!.currentProvider, 'synthetic');
      expect(channel.state.modelOptions!.currentModel, 'synthetic/model');
      expect(channel.state.modelOptions!.providers.single.models, [
        'synthetic/model',
      ]);
      final connected = await stats();
      expect(connected['ssh_auths'], (before['ssh_auths'] as int) + 1);
      expect(connected['mutation_attempts'], 0);
      expect(connected['forbidden_reads'], 0);
      expect(connected['forbidden_ssh'], 0);
      final exactReads = reads(connected);
      await tester.pump(const Duration(seconds: 1));
      expect(reads(await stats()), exactReads); // No automatic replay/retry.
      final delta = <String, int>{
        for (final entry in exactReads.entries)
          entry.key:
              (entry.value as int) - ((reads(before)[entry.key] ?? 0) as int),
      }..removeWhere((_, count) => count == 0);
      expect(delta['GET /api/model/options'], greaterThan(0));
      expect(delta['GET /api/sessions/qa-history/messages'], greaterThan(0));
      cycles.add({'request_delta': delta});
      await tap(control('hermes-disconnect-button'));
      await tap(control('hermes-disconnect-confirm'));
      await until(() => !channel.state.isConnected, 'Disconnect failed');
      await until(
        () => form.evaluate().isEmpty,
        'Connected form remained mounted',
      );
      Map<String, dynamic> disconnected = await stats();
      for (
        var attempt = 0;
        attempt < 40 && disconnected['live_ssh'] != 0;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        disconnected = await stats();
      }
      expect(disconnected['live_ssh'], 0);
      expect(reads(disconnected), exactReads);
    }
    // Exact per-route equality across the two deliberately identical journeys.
    expect(cycles[1]['request_delta'], cycles[0]['request_delta']);
    final result = await stats();
    expect(result['mutation_attempts'], 0);
    expect(result['forbidden_ssh'], 0);
    expect(result['forbidden_reads'], 0);
    expect(tester.takeException(), isNull);
    // Launcher accepts only this bounded sanitized summary, never Flutter logs.
    // ignore: avoid_print
    print(
      'WING_SSH_KEY_RESULT ${jsonEncode({'platform': Platform.operatingSystem, 'workflow': 'PASS', 'native_picker': 'NOT_CHECKED', 'physical_secure_storage': 'NOT_CHECKED', 'encrypted_key': 'NOT_CHECKED', 'model': 'READ_ONLY_INVENTORY', 'wing_link': 'NO_LISTENER', 'cycles': cycles, 'counters': result})}',
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
