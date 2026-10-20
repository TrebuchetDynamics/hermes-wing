import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/shared/widgets/app_shell.dart';

import '../support/fake_hermes_channel.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [390.0, 768.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('selected chat composition $width at $scale', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final channel = FakeHermesChannel();
        addTearDown(channel.dispose);
        channel.beginStreamingTurn('A synthetic question');
        channel.completeStreamingTurn(text: 'A readable synthetic answer.');
        await tester.pumpWidget(
          ProviderScope(
            overrides: [hermesChannelProvider.overrideWithValue(channel)],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: const AppShellSessionNavigation(child: HermesChatScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('hermes-chat-session-heading')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('hermes-chat-owner')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('hermes-active-session-bar')),
          findsNothing,
        );
        final field = find.byKey(const ValueKey('hermes-composer-field'));
        final editor = tester.getRect(field);
        final actions = tester.getRect(
          find.byKey(const ValueKey('hermes-composer-actions')),
        );
        expect(editor.width, greaterThan(width - 100));
        expect(editor.bottom, lessThan(actions.top));
        for (final id in [
          'hermes-attachment-button',
          'hermes-draft-mic-button',
          'hermes-composer-voice-options',
          width < 720 ? 'hermes-live-voice-start' : 'hermes-mic-button',
          'hermes-send-button',
        ]) {
          final finder = find.byKey(ValueKey(id));
          final rect = tester.getRect(finder);
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, greaterThanOrEqualTo(48));
          expect(finder.hitTestable(), findsOneWidget);
          final node = tester.getSemantics(finder);
          expect('${node.label} ${node.tooltip}'.trim(), isNotEmpty);
        }
        expect(
          find.byKey(const ValueKey('hermes-continuous-voice-switch')),
          findsNothing,
        );
        await tester.tap(
          find.byKey(const ValueKey('hermes-composer-voice-options')),
        );
        await tester.pumpAndSettle();
        expect(
          find
              .byKey(const ValueKey('hermes-continuous-voice-switch'))
              .hitTestable(),
          findsOneWidget,
        );
        await tester.enterText(field, 'Draft remains with owner');
        final owner = (
          channel.state.activeSessionId,
          channel.state.selectedProfileId,
          channel.state.connectedBaseUrl,
        );
        channel.beginStreamingTurn('Streaming synthetic question');
        await tester.pump();
        final stop = find.byKey(const ValueKey('hermes-composer-stop-chip'));
        expect(stop.hitTestable(), findsOneWidget);
        final focus = tester.widget<TextField>(field).focusNode!;
        focus.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(channel.stopActiveTurnCalls, 1);
        expect(
          tester.widget<TextField>(field).controller!.text,
          'Draft remains with owner',
        );
        expect((
          channel.state.activeSessionId,
          channel.state.selectedProfileId,
          channel.state.connectedBaseUrl,
        ), owner);
        expect(tester.takeException(), isNull);
        debugDefaultTargetPlatformOverride = null;
      });
    }
  }
}
