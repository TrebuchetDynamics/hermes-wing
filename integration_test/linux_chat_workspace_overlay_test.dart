import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/core/hermes/models/hermes_profile.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/app_router.dart';

import '../test/features/hermes_chat/support/fake_hermes_channel.dart';
import '../test/features/hermes_chat/support/fake_hermes_endpoint_store.dart';

// Native engine/router qualification with an in-memory channel, not HTTP/SSE,
// physical keyboard, OS Back or live Agent qualification.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Linux overlays retain Chat at 200% text', (tester) async {
    final root = Platform.environment['WING_LOCAL_ROOT'];
    if (!Platform.isLinux ||
        root == null ||
        Platform.environment['HOME'] != '$root/home' ||
        Platform.environment['XDG_CONFIG_HOME'] != '$root/config' ||
        Platform.environment['XDG_DATA_HOME'] != '$root/data' ||
        Platform.environment['XDG_CACHE_HOME'] != '$root/cache' ||
        Platform.environment['DBUS_SESSION_BUS_ADDRESS'] != null) {
      throw StateError('Use the isolated Linux overlay runner.');
    }
    final journeys = <Map<String, Object?>>[];
    Future<void> settle() async {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    for (final width in [390.0, 1280.0]) {
      await binding.setSurfaceSize(Size(width, 900));
      for (final (entry, destination) in [
        ('shell', 'settings'),
        ('shell', 'profiles'),
        ('slash', 'settings'),
        ('slash', 'profiles'),
        ('completion', 'settings'),
        ('manage', 'profiles'),
      ]) {
        for (final dismissal in ['close', 'escape', 'back']) {
          SharedPreferences.setMockInitialValues({});
          final channel = entry == 'manage'
              ? FakeHermesChannel(
                  profiles: const [
                    HermesProfile(
                      id: 'active',
                      displayName: 'Current',
                      revision: '1',
                    ),
                  ],
                  selectedProfileId: 'active',
                  connectedBaseUrl: 'https://example.invalid',
                )
              : FakeHermesChannel();
          final store = FakeHermesEndpointStore();
          final turn = HermesChatTurn(
            id: 'synthetic-overlay-turn',
            sessionId: 'sess_1',
            author: HermesTurnAuthor.assistant,
            createdAt: DateTime.utc(2026),
            text: 'Synthetic native overlay transcript.',
            status: HermesTurnStatus.completed,
          );
          channel.replaceTranscript([turn]);
          final container = ProviderContainer(
            overrides: [
              hermesChannelProvider.overrideWithValue(channel),
              hermesEndpointStoreProvider.overrideWithValue(store),
            ],
          );
          final router = container.read(routerProvider);
          const location = '/hermes?session=sess_1&filter=all#tail';
          router.go(location);
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
          await settle();
          final chat = tester.state(find.byType(HermesChatScreen));
          final field = find.byKey(const ValueKey('hermes-composer-field'));
          await tester.enterText(field, 'Synthetic unsent native draft');
          final controller = tester.widget<TextField>(field).controller;
          final session = channel.state.activeSessionId;
          final expectedDraft = entry == 'shell' || entry == 'manage'
              ? 'Synthetic unsent native draft'
              : '';
          if (entry == 'manage') {
            await tester.tap(
              find.byKey(const ValueKey('hermes-profile-switcher')),
            );
            await settle();
            await tester.tap(find.byKey(const ValueKey('chat-profile-manage')));
          } else if (entry != 'shell') {
            await tester.enterText(
              field,
              entry == 'completion' ? '/sett' : '/$destination',
            );
            await tester.pump();
            if (entry == 'completion') {
              await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            } else {
              final action = find.byKey(
                ValueKey('hermes-local-command-$destination'),
              );
              await tester.ensureVisible(action);
              await tester.tap(action);
            }
          } else if (width < 600) {
            final label = destination == 'settings' ? 'More' : 'Profiles';
            await tester.tap(
              find.descendant(
                of: find.byType(NavigationBar),
                matching: find.text(label),
              ),
            );
            if (destination == 'settings') {
              await settle();
              await tester.ensureVisible(find.text('Settings').last);
              await tester.tap(find.text('Settings').last);
            }
          } else if (destination == 'profiles') {
            await tester.tap(
              find.byKey(const ValueKey('desktop-manage-profiles')),
            );
          } else {
            final entry = find
                .descendant(
                  of: find.byKey(const ValueKey('desktop-sidebar')),
                  matching: find.text('Settings'),
                )
                .first;
            await tester.ensureVisible(entry);
            await settle();
            await tester.tap(entry);
          }
          await settle();
          final close = find.byKey(
            const ValueKey('chat-workspace-overlay-close'),
          );
          expect(close, findsOneWidget);
          expect(chat.mounted, isTrue);
          expect(tester.widget<TextField>(field).focusNode!.hasFocus, isFalse);
          final semantics = tester.ensureSemantics();
          expect(
            tester
                .getSemantics(close)
                .getSemanticsData()
                .flagsCollection
                .isFocused
                .toBoolOrNull(),
            isTrue,
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          await settle();
          expect(
            tester
                .getSemantics(close)
                .getSemanticsData()
                .flagsCollection
                .isFocused
                .toBoolOrNull(),
            isTrue,
          );
          if (dismissal == 'close') {
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          } else if (dismissal == 'escape') {
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          } else {
            await tester.binding.handlePopRoute();
          }
          await settle();
          expect(close, findsNothing);
          expect(
            router.routeInformationProvider.value.uri.toString(),
            location,
          );
          expect(tester.state(find.byType(HermesChatScreen)), same(chat));
          expect(tester.widget<TextField>(field).controller, same(controller));
          expect(controller!.text, expectedDraft);
          if (entry != 'shell') {
            expect(
              tester.widget<TextField>(field).focusNode!.hasFocus,
              isTrue,
              reason:
                  '$entry $destination $dismissal must restore composer focus',
            );
          }
          expect(channel.state.activeSessionId, session);
          expect(channel.state.activeMessages, [turn]);
          expect(
            find.text('Synthetic native overlay transcript.'),
            findsOneWidget,
          );
          expect(channel.connectCalls, isEmpty);
          expect(channel.disconnectCalls, 0);
          expect(channel.sentVoiceTranscripts, isEmpty);
          expect(channel.stopActiveTurnCalls, 0);
          expect(channel.createSessionCalls, isEmpty);
          expect(channel.selectSessionCalls, isEmpty);
          expect(channel.selectProfileCalls, isEmpty);
          expect(store.saveCalls, isEmpty);
          expect(tester.takeException(), isNull);
          journeys.add({
            'width': width,
            'entry': entry,
            'destination': destination,
            'dismissal': dismissal,
            'text_scale': 2,
            'chat_retained': true,
            'draft_retained': true,
            'transcript_retained': true,
            'exact_location_retained': true,
            'close_keyboard_focus': true,
            'composer_focus_restored': entry != 'shell',
            'mutations': 0,
          });
          semantics.dispose();
          await tester.pumpWidget(const SizedBox.shrink());
          await settle();
          router.dispose();
          container.dispose();
          channel.dispose();
        }
      }
    }
    await binding.setSurfaceSize(null);
    final receipt = File('$root/cache/chat-workspace-overlay.json.pending');
    receipt.writeAsStringSync(
      jsonEncode({'native_pid': pid, 'journeys': journeys}),
    );
    receipt.renameSync('$root/cache/chat-workspace-overlay.json');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
  });
}
