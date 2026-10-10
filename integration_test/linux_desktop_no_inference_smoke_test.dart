import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/shared/widgets/app_shell.dart';

import 'support/desktop_no_inference_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('credential-free production shell exact native restart', (
    tester,
  ) async {
    final root = Platform.environment['WING_SMOKE_ROOT'];
    final phase = Platform.environment['WING_SMOKE_PHASE'];
    if (root == null ||
        !{
          'write',
          'verify',
          'verify401',
          'verify403',
          'bootstrap401',
          'bootstrap403',
        }.contains(phase) ||
        Platform.environment['HOME'] != '$root/home' ||
        Platform.environment['XDG_CONFIG_HOME'] != '$root/config' ||
        Platform.environment['WING_LIVE_AUTH'] != null ||
        Platform.environment['DBUS_SESSION_BUS_ADDRESS'] != null) {
      throw StateError('Use the isolated no-inference launcher');
    }
    final fixture = DesktopNoInferenceFixture();
    final denialStatus = switch (phase) {
      'verify401' => 401,
      'verify403' => 403,
      _ => null,
    };
    final bootstrapStatus = switch (phase) {
      'bootstrap401' => 401,
      'bootstrap403' => 403,
      _ => null,
    };
    final deniedBootstrapRequests = <List<Map<String, Object?>>>[];
    final channel = HermesApiChannel(clientBuilder: fixture.client);
    const store = DesktopNoInferenceStore();
    final cache = GatewayContactCache();
    final directory = HermesGatewayDirectory(
      store: store,
      cache: cache,
      loader: HermesApiGatewaySummaryLoader(clientBuilder: fixture.client),
      activeChannel: channel,
    );

    addTearDown(channel.dispose);
    final before = await cache.loadSelection();
    if (phase == 'write') {
      expect(before, isNull);
    } else {
      expect(before?.contactId.gatewayId, 'synthetic-endpoint');
      expect(before?.contactId.profileId, DesktopNoInferenceFixture.profile);
      expect(before?.sessionId, DesktopNoInferenceFixture.session);
    }
    fixture.deniedHistoryStatus = denialStatus;
    fixture.deniedBootstrapStatus = bootstrapStatus;
    await directory.start();
    if (phase == 'write') {
      await directory.activate(
        directory.contacts.single.id,
        preferredSessionId: DesktopNoInferenceFixture.session,
      );
    }
    if (denialStatus != null || bootstrapStatus != null) {
      expect(
        directory.restorationFailure,
        GatewaySessionRestorationFailure.authentication,
      );
      expect(directory.activeContactId, before?.contactId);
      expect(directory.restoringSessionId, before?.sessionId);
      expect(channel.state.activeSessionId, isNull);
      expect(channel.state.activeMessages, isEmpty);
      expect((await cache.loadSelection())?.contactId, before?.contactId);
      expect((await cache.loadSelection())?.sessionId, before?.sessionId);
      if (bootstrapStatus != null) {
        expect(fixture.deniedReads, hasLength(2));
        expect(channel.state.sessions, isEmpty);
        expect(channel.state.profiles, isEmpty);
        expect(channel.state.capabilities, isNull);
        deniedBootstrapRequests.add(List.of(fixture.requests));
        expect(fixture.requests.map((r) => r['path']), [
          '/health',
          '/v1/capabilities',
          '/health',
          '/v1/capabilities',
        ]);
      } else {
        expect(fixture.deniedReads, hasLength(1));
        expect(fixture.deniedReads.single['status'], denialStatus);
        expect(
          fixture.deniedReads.single['profile'],
          DesktopNoInferenceFixture.profile,
        );
      }
    } else {
      expect(directory.restorationFailure, isNull);
      expect(channel.state.activeSessionId, DesktopNoInferenceFixture.session);
      expect(
        channel.state.activeMessages.single.id,
        'synthetic-message-synthetic-history',
      );
    }
    if (bootstrapStatus == null) {
      expect(
        channel.state.selectedProfileId,
        DesktopNoInferenceFixture.profile,
      );
      expect(channel.state.canCreateSessions, false);
    } else {
      // Before discovery, capability getters are not action availability.
      expect(channel.state.isConnected, false);
    }

    final router = GoRouter(
      initialLocation: denialStatus == null && bootstrapStatus == null
          ? '/tools'
          : '/hermes',
      routes: [
        ShellRoute(
          builder: (_, state, child) =>
              AppShell(location: state.uri.path, child: child),
          routes: [
            GoRoute(
              path: '/tools',
              builder: (_, _) =>
                  const Scaffold(body: Text('Synthetic QA tools')),
            ),
            GoRoute(
              path: '/hermes',
              builder: (_, _) => const HermesChatScreen(),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    final mountStart = fixture.requests.length;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(store),
          hermesGatewayDirectoryProvider.overrideWith((_) => directory),
          hermesVoiceCaptureServiceProvider.overrideWithValue(null),
          hermesTextToSpeechServiceProvider.overrideWithValue(null),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (bootstrapStatus != null) {
      // Shell inventory refresh is distinct from session activation/retry.
      final mountedReads = fixture.requests.sublist(mountStart);
      expect(mountedReads.map((r) => r['path']), [
        '/health',
        '/v1/capabilities',
      ]);
      deniedBootstrapRequests.add(List.of(mountedReads));
      expect(directory.activeContactId, before?.contactId);
      expect(directory.restoringSessionId, before?.sessionId);
      expect(channel.state.activeSessionId, isNull);
    }
    final semantics = tester.ensureSemantics();
    var semanticsDisposed = false;
    addTearDown(() {
      if (!semanticsDisposed) semantics.dispose();
    });
    Future<void> key(LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }

    Future<void> reach(Finder target) async {
      bool focused() =>
          tester
              .getSemantics(target)
              .getSemanticsData()
              .flagsCollection
              .isFocused
              .toBoolOrNull() ==
          true;
      for (var i = 0; i < 80 && !focused(); i++) {
        await key(LogicalKeyboardKey.tab);
      }
      expect(focused(), true);
    }

    Future<void> open() async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
    }

    if (denialStatus != null || bootstrapStatus != null) {
      expect(find.text('Conversation not restored'), findsOneWidget);
      expect(find.byKey(const ValueKey('hermes-composer-field')), findsNothing);
      expect(find.text('Synthetic history synthetic-history'), findsNothing);
      final retry = find.byKey(
        const ValueKey('hermes-session-restoration-retry'),
      );
      final readsBeforeFocus = fixture.requests.length;
      await reach(retry);
      // Merely reaching Retry must not perform an implicit reconciliation.
      expect(fixture.requests, hasLength(readsBeforeFocus));
      expect(directory.restoringSessionId, before?.sessionId);
      if (bootstrapStatus != null) {
        final repeatStart = fixture.requests.length;
        await key(LogicalKeyboardKey.space);
        expect(
          directory.restorationFailure,
          GatewaySessionRestorationFailure.authentication,
        );
        expect(directory.activeContactId, before?.contactId);
        expect(directory.restoringSessionId, before?.sessionId);
        expect(channel.state.activeSessionId, isNull);
        expect(channel.state.activeMessages, isEmpty);
        expect((await cache.loadSelection())?.sessionId, before?.sessionId);
        final repeat = fixture.requests.sublist(repeatStart);
        expect(repeat.map((r) => r['path']), ['/health', '/v1/capabilities']);
        deniedBootstrapRequests.add(List.of(repeat));
        expect(
          find.byKey(const ValueKey('hermes-composer-field')),
          findsNothing,
        );
        await reach(retry);
      }
      fixture.deniedHistoryStatus = null;
      fixture.deniedBootstrapStatus = null;
      await key(LogicalKeyboardKey.space);
      expect(directory.restorationFailure, isNull);
      expect(directory.restoringSessionId, isNull);
      expect(channel.state.activeSessionId, before?.sessionId);
      expect(channel.state.canCreateSessions, false);
      expect(find.text('Synthetic history synthetic-history'), findsOneWidget);
      router.go('/tools');
      await tester.pumpAndSettle();
    }

    final row = find.byKey(
      const ValueKey('hermes-session-row-synthetic-history'),
    );
    await open();
    await reach(row);
    final gate = fixture.held = Completer<String>();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Opening session…'), findsOneWidget);
    // Loading stays keyboard-dismissible; abandoning the modal cannot accept late history.
    await key(LogicalKeyboardKey.escape);
    gate.complete(fixture.history('other-session'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/tools');
    expect(channel.state.activeSessionId, DesktopNoInferenceFixture.session);
    expect(
      channel.state.activeMessages.single.id,
      'synthetic-message-synthetic-history',
    );
    expect(
      (await cache.loadSelection())?.sessionId,
      DesktopNoInferenceFixture.session,
    );
    // Cancellation must fence even a valid current-owner result, not only a
    // malformed foreign history that identity validation independently rejects.
    await open();
    await reach(row);
    final validLateRead = fixture.held = Completer<String>();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Opening session…'), findsOneWidget);
    await key(LogicalKeyboardKey.escape);
    validLateRead.complete(
      fixture
          .history(DesktopNoInferenceFixture.session)
          .replaceAll(
            'synthetic-message-synthetic-history',
            'cancelled-message',
          ),
    );
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/tools');
    expect(
      channel.state.activeMessages.single.id,
      'synthetic-message-synthetic-history',
    );
    await open();
    if (denialStatus == null) {
      fixture.failHistory = true;
    } else {
      fixture.deniedHistoryStatus = denialStatus;
    }
    await reach(row);
    await key(LogicalKeyboardKey.enter);
    final retry = find.byKey(const ValueKey('global-sessions-retry'));
    expect(retry, findsOneWidget);
    fixture.failHistory = false;
    fixture.deniedHistoryStatus = null;
    fixture.wrongOwner = true;
    await reach(retry);
    await key(LogicalKeyboardKey.enter);
    expect(retry, findsOneWidget);
    fixture.wrongOwner = false;
    await reach(retry);
    await key(LogicalKeyboardKey.space);
    expect(router.routeInformationProvider.value.uri.path, '/hermes');
    expect(find.text('Synthetic history synthetic-history'), findsOneWidget);
    expect(channel.state.activeSessionId, DesktopNoInferenceFixture.session);
    expect(
      channel.state.activeMessages.single.id,
      'synthetic-message-synthetic-history',
    );
    expect(fixture.mutationAttempts, 0);
    expect(tester.takeException(), isNull);
    final selection = await cache.loadSelection();
    expect(selection?.contactId.gatewayId, 'synthetic-endpoint');
    expect(selection?.contactId.profileId, DesktopNoInferenceFixture.profile);
    expect(selection?.sessionId, DesktopNoInferenceFixture.session);
    expect(channel.state.selectedProfileId, selection?.contactId.profileId);
    expect(directory.activeContactId, selection?.contactId);
    String identity(Object value) =>
        sha256.convert(utf8.encode(jsonEncode(value))).toString();
    final receipt = {
      'phase': phase,
      'native_pid': pid,
      'owner_identity': identity([
        DesktopNoInferenceFixture.origin,
        DesktopNoInferenceFixture.profile,
        selection?.sessionId,
      ]),
      'history_identity': identity(
        channel.state.activeMessages
            .map((m) => [m.id, m.author.name, m.text])
            .toList(),
      ),
      'counts': {
        'sends': 0,
        'session_creates': 0,
        'model_writes': 0,
        'approvals': 0,
        'stops': 0,
        'provider_requests': 0,
        'management_requests': 0,
        'mutation_attempts': fixture.mutationAttempts,
      },
      'requests': fixture.requests,
      'keyboard_loading_cancel': true,
      'keyboard_error_retry': true,
      'wrong_owner_rejected': true,
      'restoration_denial_status': denialStatus,
      'saved_owner_retained': true,
      'keyboard_restoration_retry': denialStatus != null,
      'cancelled_wrong_owner_rejected': true,
      'cancelled_valid_owner_rejected': true,
      'denied_reads': fixture.deniedReads,
      'bootstrap_denial_status': bootstrapStatus,
      'bootstrap_denied_requests': deniedBootstrapRequests,
      'keyboard_bootstrap_retry': bootstrapStatus != null,
    };
    final target = File('$root/cache/smoke-$phase.json');
    final temporary = File('${target.path}.tmp');
    temporary.writeAsStringSync(jsonEncode(receipt));
    temporary.renameSync(target.path);
    // Keep the GTK pid alive until the parent has observed its owned process group.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    semantics.dispose();
    semanticsDisposed = true;
  });
}
