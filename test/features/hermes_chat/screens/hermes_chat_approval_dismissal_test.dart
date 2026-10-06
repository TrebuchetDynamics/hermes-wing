import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_hermes_gateway_directory.dart';

void main() {
  for (final flow in ['connection reset', 'channel rebind', 'profile switch']) {
    testWidgets(
      'retained malformed dismissal preserves replacement after $flow',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final gate = Completer<void>();
        final profileGate = Completer<void>();
        final channel = FakeHermesChannel(
          approvalResponseGate: () => gate.future,
          profiles: const [
            HermesProfile(id: 'alpha', displayName: 'Alpha', revision: '1'),
            HermesProfile(id: 'beta', displayName: 'Beta', revision: '1'),
          ],
          selectedProfileId: 'alpha',
          selectProfileGate: (_) => profileGate.future,
        );
        addTearDown(channel.dispose);
        final replacement = FakeHermesChannel(
          approvalResponseGate: () => gate.future,
        );
        addTearDown(replacement.dispose);
        final directory = directoryFor(
          configs: const [],
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
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: HermesChatScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final container = ProviderScope.containerOf(
          tester.element(find.byType(HermesChatScreen)),
        );
        if (flow == 'profile switch') {
          // Reset is synchronous at switch admission. A can arrive during the
          // pending selection and open Review before the selection completes.
          await tester.tap(
            find.byKey(const ValueKey('hermes-profile-switcher')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('chat-profile-row-beta')));
          await tester.pumpAndSettle();
          expect(channel.selectProfileCalls, ['beta']);
          expect(channel.state.selectedProfileId, 'alpha');
        }
        channel.emitApprovalRequest(
          const HermesApprovalRequest(
            id: '',
            toolCallId: 'malformed-A',
            prompt: 'Malformed request A',
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('hermes-approval-review')));
        await tester.pumpAndSettle();
        final dismiss = find.byKey(
          const ValueKey('hermes-approval-sheet-dismiss-malformed'),
        );
        expect(dismiss.hitTestable(), findsOneWidget);

        var activeChannel = channel;
        switch (flow) {
          case 'connection reset':
            await channel.disconnect();
            await tester.pumpAndSettle();
            await channel.connect(baseUrl: 'http://127.0.0.1:8642');
          case 'channel rebind':
            container.updateOverrides([
              hermesChannelProvider.overrideWithValue(replacement),
              hermesEndpointStoreProvider.overrideWithValue(
                FakeHermesEndpointStore(),
              ),
              hermesGatewayDirectoryProvider.overrideWith((_) => directory),
            ]);
            await tester.pumpAndSettle();
            activeChannel = replacement;
          case 'profile switch':
            profileGate.complete();
            await tester.pumpAndSettle();
            expect(channel.state.selectedProfileId, 'beta');
        }
        activeChannel.emitApprovalRequest(
          const HermesApprovalRequest(
            id: 'valid-B',
            toolCallId: 'tool-B',
            prompt: 'Replacement request B',
            choices: {HermesApprovalDecision.once, HermesApprovalDecision.deny},
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Review Hermes approval'), findsOneWidget);
        expect(
          tester
              .widget<SelectableText>(
                find.byKey(const ValueKey('hermes-approval-sheet-prompt')),
              )
              .data,
          'Malformed request A',
        );
        final approve = find.byKey(const ValueKey('hermes-approval-once'));
        expect(approve, findsOneWidget);
        expect(
          tester.widget<FilledButton>(approve).onPressed,
          flow == 'profile switch' ? isNull : isNotNull,
        );
        expect(approve.hitTestable(), findsNothing);
        expect(dismiss.hitTestable(), findsOneWidget);
        expect(activeChannel.respondToApprovalCalls, isEmpty);

        if (flow == 'connection reset') {
          // Connection reset transfers focus to the rebuilt background route.
          // Ordinary Tab/Enter can admit B even though the modal blocks taps.
          final approveElement = tester.element(approve);
          var reached = false;
          for (var i = 0; i < 32 && !reached; i++) {
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pump();
            FocusManager.instance.primaryFocus?.context?.visitAncestorElements((
              element,
            ) {
              if (identical(element, approveElement)) reached = true;
              return !reached;
            });
          }
          expect(reached, isTrue, reason: 'B reached only by real Tab events');
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();
          expect(activeChannel.respondToApprovalCalls, hasLength(1));
          expect(
            activeChannel.respondToApprovalCalls.single['approvalId'],
            'valid-B',
          );
          expect(dismiss.hitTestable(), findsOneWidget);
          final busy = find.byKey(const ValueKey('hermes-approval-responding'));
          expect(busy, findsOneWidget);
          await tester.tap(dismiss);
          // B's preserved progress indicator intentionally keeps scheduling
          // frames until settlement; finish only the sheet's exit animation.
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          await tester.pump();
          expect(dismiss, findsNothing);
          expect(busy, findsOneWidget, reason: 'stale A must not release B');
          expect(tester.widget<FilledButton>(approve).onPressed, isNull);
          expect(activeChannel.respondToApprovalCalls, hasLength(1));
          gate.complete();
          await tester.pumpAndSettle();
          expect(busy, findsNothing);
          expect(activeChannel.respondToApprovalCalls, hasLength(1));
          expect(find.text('Replacement request B'), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          return;
        }
        final sheetRoute = ModalRoute.of(tester.element(dismiss));
        for (var i = 0; i < 8; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          final focusContext = FocusManager.instance.primaryFocus?.context;
          expect(focusContext, isNotNull);
          expect(ModalRoute.of(focusContext!), same(sheetRoute));
        }
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();
        expect(activeChannel.createSessionCalls, isEmpty);
        expect(activeChannel.selectSessionCalls, isEmpty);
        expect(activeChannel.respondToApprovalCalls, isEmpty);
        expect(dismiss.hitTestable(), findsOneWidget);
        expect(approve.hitTestable(), findsNothing);

        // The ordinary user path must close A before B can be answered. Calling
        // the covered B widget's onPressed directly would invent reachability.
        await tester.tap(dismiss);
        await tester.pumpAndSettle();
        expect(dismiss, findsNothing);
        expect(approve.hitTestable(), findsOneWidget);
        expect(activeChannel.respondToApprovalCalls, isEmpty);
        await tester.tap(approve);
        await tester.pump();
        expect(
          activeChannel.respondToApprovalCalls.single['approvalId'],
          'valid-B',
        );
        expect(
          find.byKey(const ValueKey('hermes-approval-responding')),
          findsOneWidget,
        );
        gate.complete();
        await tester.pumpAndSettle();
        expect(activeChannel.respondToApprovalCalls, hasLength(1));
        expect(find.text('Replacement request B'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
      variant: TargetPlatformVariant.only(TargetPlatform.linux),
    );
  }
}
