import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/providers/hermes_session_pin_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hermes_chat_session_disclosure_test.dart' as support;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [390.0, 1280.0]) {
    testWidgets('queued pin toggle rejects owner away-and-return at $width', (
      tester,
    ) async {
      final channel = await support.pumpChat(tester, width);
      final preferences = await SharedPreferences.getInstance();
      final before = preferences.getStringList(
        'wing.hermes.pinned_sessions.v1',
      );
      expect(before, isNotEmpty);
      final callback = tester
          .widget<PopupMenuButton<String>>(
            find.byKey(const ValueKey('hermes-session-menu-pin')),
          )
          .onSelected!;
      final state = channel.state;
      callback('pin');
      channel.change(
        state.copyWith(connectedBaseUrl: 'https://other.example.invalid'),
      );
      channel.change(state);
      await tester.pumpAndSettle();
      expect(
        preferences.getStringList('wing.hermes.pinned_sessions.v1'),
        before,
      );
      expect(channel.selectSessionCalls, isEmpty);
      expect(channel.selectProfileCalls, isEmpty);
      expect(channel.connectCalls, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'disposed Chat cannot toggle a shared pin store still owned by the app',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final channel = support.DisclosureChannel();
      addTearDown(channel.dispose);
      final visible = ValueNotifier(true);
      addTearDown(visible.dispose);
      final container = ProviderContainer(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ValueListenableBuilder<bool>(
              valueListenable: visible,
              builder: (_, shown, _) =>
                  shown ? const HermesChatScreen() : const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final menu = find.byKey(const ValueKey('hermes-session-menu-pin'));
      await tester.ensureVisible(menu);
      tester.widget<PopupMenuButton<String>>(menu).onSelected!('pin');
      await tester.pumpAndSettle();
      final preferences = await SharedPreferences.getInstance();
      final before = preferences.getStringList(
        'wing.hermes.pinned_sessions.v1',
      );
      expect(before, isNotEmpty);
      final callback = tester.widget<PopupMenuButton<String>>(menu).onSelected!;
      final store = container.read(hermesSessionPinStoreProvider);
      visible.value = false;
      await tester.pumpAndSettle();
      expect(find.byType(HermesChatScreen), findsNothing);
      expect(
        identical(store, container.read(hermesSessionPinStoreProvider)),
        isTrue,
      );
      callback('pin');
      await tester.pumpAndSettle();
      expect(
        preferences.getStringList('wing.hermes.pinned_sessions.v1'),
        before,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
