import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/hermes_chat/widgets/session_model_picker_sheet.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/providers/app_router.dart';

import 'support/integrated_daily_restart_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('full GTK shell approval Stop and exact off-page process restart', (
    tester,
  ) async {
    final root = Platform.environment['WING_INTEGRATED_ROOT'];
    final phase = Platform.environment['WING_INTEGRATED_PHASE'];
    final width = double.parse(
      Platform.environment['WING_INTEGRATED_WIDTH'] ?? '0',
    );
    if (root == null ||
        !{'write', 'verify'}.contains(phase) ||
        ![390.0, 1280.0].contains(width) ||
        Platform.environment['HOME'] != '$root/home' ||
        Platform.environment['DBUS_SESSION_BUS_ADDRESS'] != null ||
        Platform.environment['WING_LIVE_AUTH'] != null) {
      throw StateError('Use the isolated integrated restart launcher');
    }
    // Real platform preferences, shared by two processes; no mock initialization.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('wing.tips.dismissed.v1', [
      'moreDestinations',
      'voice',
      'approvals',
    ]);
    final cache = GatewayContactCache();
    final remembered = await cache.loadSelection();
    expect(
      remembered?.sessionId,
      phase == 'write' ? null : IntegratedDailyRestartFixture.session,
    );
    final fixture = IntegratedDailyRestartFixture(root, phase!);
    await tester.runAsync(fixture.start);
    final channel = HermesApiChannel(); // Actual native HTTP and SSE.
    final store = IntegratedDailyEndpointStore(fixture.origin);
    final directory = HermesGatewayDirectory(
      store: store,
      cache: cache,
      loader: const HermesApiGatewaySummaryLoader(),
      activeChannel: channel,
    );
    final container = ProviderContainer(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesEndpointStoreProvider.overrideWithValue(store),
        hermesGatewayDirectoryProvider.overrideWith((ref) {
          final lifetime = ref.watch(hermesDirectoryLifetimeProvider);
          lifetime.attach(directory);
          ref.onDispose(() => lifetime.detach(directory));
          return directory;
        }),
        hermesVoiceCaptureServiceProvider.overrideWithValue(null),
        hermesTextToSpeechServiceProvider.overrideWithValue(null),
      ],
    );
    final router = container.read(routerProvider);
    final highlight = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() => FocusManager.instance.highlightStrategy = highlight);
    binding.testTextInput.register();
    addTearDown(binding.testTextInput.unregister);
    await binding.setSurfaceSize(Size(width, 1000));
    addTearDown(() => binding.setSurfaceSize(null));
    await tester.runAsync(directory.start);
    final restoreMutations = fixture.mutations.length;
    expect(restoreMutations, 0);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          ),
        ),
      ),
    );

    Future<void> settle() async {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    Future<void> wait(bool Function() ready) async {
      for (var i = 0; i < 100 && !ready(); i++) {
        await settle();
      }
      if (!ready()) {
        debugPrint(
          'SYNTHETIC_DIAGNOSTIC ${jsonEncode({'requests': fixture.requests, 'mutations': fixture.mutations, 'error': channel.state.errorMessage, 'labels': tester.widgetList<Text>(find.byType(Text)).map((w) => w.data).toList()})}',
        );
      }
      expect(ready(), true);
    }

    Finder keyed(String key) => find.byKey(ValueKey(key));
    bool focused(Finder target) {
      if (target.evaluate().isEmpty) return false;
      final elements = target.evaluate().toSet();
      final context = FocusManager.instance.primaryFocus?.context;
      var inside = elements.contains(context);
      context?.visitAncestorElements((e) {
        if (elements.contains(e)) inside = true;
        return !inside;
      });
      if (inside) return true;
      final control =
          context?.findAncestorWidgetOfExactType<ListTile>() ??
          context?.findAncestorWidgetOfExactType<ActionChip>() ??
          context?.findAncestorWidgetOfExactType<FilledButton>() ??
          context?.findAncestorWidgetOfExactType<OutlinedButton>() ??
          context?.findAncestorWidgetOfExactType<IconButton>();
      return control != null &&
          find
              .descendant(
                of: find.byWidget(control),
                matching: target,
                matchRoot: true,
              )
              .evaluate()
              .isNotEmpty;
    }

    final focus = <Map<String, Object?>>[];
    Future<void> reach(Finder target) async {
      await wait(() => target.evaluate().isNotEmpty);
      await tester.ensureVisible(target.first);
      for (var i = 0; i < 120 && !focused(target); i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(focused(target), true, reason: target.toString());
      final rect = tester.getRect(target.first);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(width));
      focus.add({
        'target': target.toString(),
        'rect': [rect.left, rect.top, rect.right, rect.bottom],
      });
    }

    Future<void> activate(Finder target) async {
      await reach(target);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle();
    }

    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        final result = await Process.run('/usr/bin/import', [
          '-window',
          'root',
          '$root/cache/integrated-$width-$phase-$name.png',
        ]);
        expect(result.exitCode, 0);
      });
    }

    Future<void> model() async {
      await activate(keyed('hermes-composer-model-chip'));
      await wait(
        () => find.byType(SessionModelPickerSheet).evaluate().isNotEmpty,
      );
      if (phase == 'verify') {
        final picker = tester.widget<SessionModelPickerSheet>(
          find.byType(SessionModelPickerSheet),
        );
        expect(picker.currentSessionModel, isNull);
        expect(picker.requireExplicitSelection, true);
        expect(
          find.text(
            AppLocalizations.of(
              tester.element(find.byType(SessionModelPickerSheet)),
            ).sessionModelIdentityNotReported,
          ),
          findsOneWidget,
        );
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Use for session'),
              )
              .onPressed,
          isNull,
        );
        await capture('unknown-model');
      }
      await activate(keyed('session-model-synthetic/synthetic/model'));
      await activate(find.widgetWithText(FilledButton, 'Use for session'));
      await wait(() => find.byType(SessionModelPickerSheet).evaluate().isEmpty);
      expect(
        channel
            .state
            .sessionModelLocks[IntegratedDailyRestartFixture.session]
            ?.accepted,
        true,
      );
    }

    Future<void> send(String text) async {
      await reach(keyed('hermes-composer-field'));
      await tester.enterText(keyed('hermes-composer-field'), text);
      await activate(keyed('hermes-send-button'));
    }

    await settle();
    final phases = <String>[];
    bool lateOwnerFenced = false;
    if (phase == 'write') {
      final contact = directory.contacts.singleWhere(
        (c) => c.id.profileId == IntegratedDailyRestartFixture.profile,
      );
      await activate(
        keyed(
          'gateway-contact-${contact.id.gatewayId}-${contact.id.profileId}',
        ),
      );
      await wait(() => channel.state.isConnected);
      expect(
        channel.state.selectedProfileId,
        IntegratedDailyRestartFixture.profile,
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await settle();
      await activate(keyed('hermes-sessions-load-more'));
      await activate(
        keyed('hermes-session-row-${IntegratedDailyRestartFixture.session}'),
      );
      await wait(
        () =>
            channel.state.activeSessionId ==
            IntegratedDailyRestartFixture.session,
      );
      phases.add('explicit-off-page-selection');
      await model();
      await send('Synthetic deliberate approval prompt');
      await wait(() => find.text('Approve once').evaluate().isNotEmpty);
      await activate(find.text('Approve once'));
      await wait(
        () =>
            channel.state.activeMessages.any((m) => m.id == 'canonical_run_1'),
      );
      phases.add('correlated-approval');
      await send('Synthetic deliberate Stop prompt');
      await wait(() => channel.activeTurnInterruptionTarget?.runId == 'run_2');
      final retired = channel.activeTurnInterruptionTarget!;
      await capture('unfocused');
      await reach(find.text('Stop'));
      await capture('focus');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await wait(
        () => channel.state.hasUnreconciledRun && fixture.stopGate != null,
      );
      final before = fixture.mutations.length;
      await expectLater(
        channel.sendText('Synthetic forbidden replay'),
        throwsStateError,
      );
      expect(fixture.mutations.length, before);
      phases.add('uncertain-stop-blocks-send');
      await reach(find.text('Reconnect'));
      await capture('failure');
      fixture.cancel();
      // Explicit Reconnect performs exact terminal/history reconciliation while
      // the old Stop response is still delayed; no retry/second Stop is issued.
      await activate(find.text('Reconnect'));
      await wait(
        () =>
            !directory.isActivating &&
            !channel.state.hasUnreconciledRun &&
            channel.state.activeSessionId ==
                IntegratedDailyRestartFixture.session &&
            channel.state.activeMessages.any((m) => m.id == 'canonical_run_2'),
      );
      expect(
        channel.state.activeMessages.any((m) => m.id == 'canonical_run_2'),
        true,
      );
      final canonicalBeforeLateStop = channel.state.activeMessages
          .map((m) => m.id)
          .toList();
      fixture.stopGate!.complete();
      fixture.stopGate = null;
      await settle();
      expect(
        channel.state.activeMessages.map((m) => m.id).toList(),
        canonicalBeforeLateStop,
      );
      expect(await channel.stopTurn(retired), false);
      expect(
        channel.state.activeSessionId,
        IntegratedDailyRestartFixture.session,
      );
      lateOwnerFenced = true;
      phases.add('terminal-canonical-recovered');
      await capture('recovered');
      fixture.save();
    } else {
      expect(
        channel.state.activeSessionId,
        IntegratedDailyRestartFixture.session,
      );
      expect(
        channel.state.selectedProfileId,
        IntegratedDailyRestartFixture.profile,
      );
      expect(
        channel.state.activeMessages.any((m) => m.id == 'canonical_run_2'),
        true,
      );
      expect(channel.state.sessionModelLocks, isEmpty);
      expect(fixture.mutations, isEmpty);
      phases.add('exact-restored-no-replay');
      await capture('restored');
      await model();
      await send('Synthetic deliberate resumed prompt');
      await wait(
        () =>
            channel.state.activeMessages.any((m) => m.id == 'canonical_run_3'),
      );
      phases.add('explicit-reselection-resumed-send');
      await capture('resumed');
    }
    final beforeLeave = fixture.mutations.length;
    router.go('/settings');
    await settle();
    router.go('/hermes');
    await settle();
    expect(fixture.mutations.length, beforeLeave);
    final selection = await tester.runAsync(cache.loadSelection);
    expect(selection?.sessionId, IntegratedDailyRestartFixture.session);
    expect(
      selection?.contactId.profileId,
      IntegratedDailyRestartFixture.profile,
    );
    expect(tester.takeException(), isNull);
    final receipt = File('$root/cache/integrated-$width-$phase.pending');
    receipt.writeAsStringSync(
      jsonEncode({
        'native_pid': pid,
        'phase': phase,
        'width': width,
        'text_scale': 2.0,
        'profile': IntegratedDailyRestartFixture.profile,
        'session': selection!.sessionId,
        'phases': phases,
        'mutations': fixture.mutations,
        'requests': fixture.requests,
        'restore_mutations': restoreMutations,
        'leave_mutations': fixture.mutations.length - beforeLeave,
        'late_owner_fenced': lateOwnerFenced,
        'focus': focus,
        'canonical_ids': channel.state.activeMessages
            .where((m) => m.id.startsWith('canonical_'))
            .map((m) => m.id)
            .toList(),
      }),
    );
    receipt.renameSync('$root/cache/integrated-$width-$phase.json');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(channel.disconnect);
    container.dispose();
    router.dispose();
    channel.dispose();
    await tester.runAsync(fixture.dispose);
  });
}
