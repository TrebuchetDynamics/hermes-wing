import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/local_setup/screens/termux_hermes_setup_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';
import '../hermes_chat/support/fake_hermes_endpoint_store.dart';

Finder key(String value) => find.byKey(ValueKey(value));

void main() {
  for (final width in [320.0, 1024.0]) {
    testWidgets(
      'phone setup never offers Link bootstrap or pairing at ${width}dp',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final channel = FakeHermesChannel.disconnected();
        final store = FakeHermesEndpointStore(profiles: const []);
        addTearDown(channel.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              hermesChannelProvider.overrideWithValue(channel),
              hermesEndpointStoreProvider.overrideWithValue(store),
              hermesVoiceCaptureServiceProvider.overrideWithValue(null),
              hermesTextToSpeechServiceProvider.overrideWithValue(null),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: const TermuxHermesSetupScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final semantics = tester.ensureSemantics();
        expect(key('platform-local-package-warning'), findsOneWidget);
        final warning = tester
            .widget<Text>(key('platform-local-package-warning'))
            .data!;
        expect(
          warning,
          contains('Automatic installation is unavailable in Wing'),
        );
        expect(warning, contains('current installation steps and limitations'));
        expect(warning, isNot(contains('currently warns')));
        expect(find.textContaining('Wing Link'), findsNothing);
        expect(key('termux-copy-command'), findsNothing);
        expect(key('hermes-api-key-field'), findsNothing);
        for (final action in [
          'platform-local-existing-agent',
          'platform-local-started-agent',
        ]) {
          await tester.ensureVisible(key(action));
          for (
            var tab = 0;
            tab < 30 &&
                tester.getSemantics(key(action)).flagsCollection.isFocused !=
                    Tristate.isTrue;
            tab++
          ) {
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pump();
          }
          expect(
            tester.getSemantics(key(action)).flagsCollection.isFocused,
            Tristate.isTrue,
          );
          // Invoke the public control via keyboard, not its callback.
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pumpAndSettle();
        }
        await tester.ensureVisible(key('hermes-api-key-field'));
        expect(
          tester.widget<TextField>(key('hermes-api-key-field')).obscureText,
          isTrue,
        );
        expect(find.text('http://127.0.0.1:8642'), findsOneWidget);
        expect(key('hermes-open-qr-scanner'), findsNothing);
        expect(key('hermes-enrollment-paste-link'), findsNothing);
        expect(find.textContaining('Wing Link'), findsNothing);
        expect(store.saveCalls, isEmpty);
        expect(channel.connectCalls, isEmpty);
        await tester.ensureVisible(key('platform-local-guide-back'));
        await tester.tap(key('platform-local-guide-back'));
        await tester.pumpAndSettle();
        expect(key('hermes-api-key-field'), findsNothing);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  }
}
