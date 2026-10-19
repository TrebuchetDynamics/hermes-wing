import 'package:flutter/material.dart';
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
  for (final width in [390.0, 960.0, 1149.0, 1150.0, 1440.0]) {
    testWidgets('chat preserves reading space at $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [hermesChannelProvider.overrideWithValue(channel)],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AppShellSessionNavigation(child: HermesChatScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final composer = find.byKey(const ValueKey('hermes-composer-field'));
      expect(
        find.byKey(const ValueKey('hermes-active-session-bar')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('hermes-session-rail-search-field')),
        findsNothing,
      );
      if (width == 960) {
        expect(tester.getSize(composer).width, greaterThan(650));
      }
      await tester.enterText(composer, 'Retained draft');
      channel.beginStreamingTurn('Synthetic question');
      await tester.pump();
      expect(
        tester.widget<TextField>(composer).controller!.text,
        'Retained draft',
      );
      expect(tester.takeException(), isNull);
      channel.completeStreamingTurn(text: 'Synthetic response.');
      await tester.pumpAndSettle();
    });
  }

  testWidgets(
    'wide chat shows the session rail and suppresses the active session bar',
    (tester) async {
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [hermesChannelProvider.overrideWithValue(channel)],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HermesChatScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('hermes-session-rail-search-field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('hermes-active-session-bar')),
        findsNothing,
      );
    },
  );
}
