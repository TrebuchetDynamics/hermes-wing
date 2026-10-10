import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/core/hermes/models/hermes_profile.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/app_router.dart';
import 'package:wing/router/app_routes.dart';
import '../features/hermes_chat/support/fake_hermes_channel.dart';
import '../features/hermes_chat/support/fake_hermes_endpoint_store.dart';

const close = ValueKey('chat-workspace-overlay-close');
const composer = ValueKey('hermes-composer-field');

Future<void> capture(WidgetTester tester, String name) async {
  if (Platform.environment['WING_OVERLAY_CAPTURE'] != '1') return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
      '.task-evidence/official-desktop-revamp/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

// Streaming intentionally schedules frames forever; settle route transitions,
// not the Agent turn.
Future<void> settleRoutes(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  for (final width in [390.0, 1200.0]) {
    for (final trigger in ['settings', 'settings-tab', 'profiles', 'manage']) {
      testWidgets('chat $trigger retains workspace at $width', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final channel = trigger == 'manage'
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
        channel.replaceTranscript([
          for (var index = 0; index < 25; index++)
            HermesChatTurn(
              id: 'synthetic-$index',
              sessionId: 'sess_1',
              author: HermesTurnAuthor.assistant,
              createdAt: DateTime.utc(2026),
              text: 'Synthetic layout row $index.',
              status: HermesTurnStatus.completed,
            ),
        ]);
        final store = FakeHermesEndpointStore();
        final container = ProviderContainer(
          overrides: [
            hermesChannelProvider.overrideWithValue(channel),
            hermesEndpointStoreProvider.overrideWithValue(store),
          ],
        );
        addTearDown(container.dispose);
        addTearDown(channel.dispose);
        final router = container.read(routerProvider);
        addTearDown(router.dispose);
        const location = '/hermes?session=sess_1&filter=all#tail';
        router.go(location);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            ),
          ),
        );
        await settleRoutes(tester);
        final chat = tester.state(find.byType(HermesChatScreen));
        final field = find.byKey(composer);
        final controller = tester.widget<TextField>(field).controller!;
        final positions = tester
            .stateList<ScrollableState>(
              find.descendant(
                of: find.byType(HermesChatScreen),
                matching: find.byType(Scrollable),
              ),
            )
            .map((state) => state.position)
            .toList();
        final transcript = positions.firstWhere((p) => p.maxScrollExtent > 100);
        transcript.jumpTo(transcript.maxScrollExtent / 2);
        await tester.pump();
        final offsets = positions.map((p) => p.pixels).toList();
        final session = channel.state.activeSessionId;
        if (trigger == 'manage') {
          await tester.enterText(field, 'unsent synthetic draft');
          await tester.tap(
            find.byKey(const ValueKey('hermes-profile-switcher')),
          );
          await settleRoutes(tester);
          await tester.tap(find.byKey(const ValueKey('chat-profile-manage')));
        } else {
          await tester.enterText(
            field,
            trigger == 'settings-tab'
                ? '/sett'
                : '/${trigger.split('-').first}',
          );
          await tester.pump();
          if (trigger == 'settings-tab') {
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          } else {
            final action = find.byKey(
              ValueKey('hermes-local-command-$trigger'),
            );
            await tester.ensureVisible(action);
            await tester.tap(action);
          }
        }
        await settleRoutes(tester);
        expect(
          chat.mounted,
          isTrue,
          reason: 'chat caller must retain workspace',
        );
        expect(find.byKey(close), findsOneWidget);
        expect(find.byKey(const ValueKey('chat-profile-search')), findsNothing);
        await tester.tap(find.byKey(close));
        await settleRoutes(tester);
        expect(router.routeInformationProvider.value.uri.toString(), location);
        expect(tester.state(find.byType(HermesChatScreen)), same(chat));
        expect(tester.widget<TextField>(field).controller, same(controller));
        expect(
          controller.text,
          trigger == 'manage' ? 'unsent synthetic draft' : '',
        );
        expect(channel.state.activeSessionId, session);
        for (var i = 0; i < positions.length; i++) {
          expect(positions[i].hasPixels, isTrue);
          expect(positions[i].pixels, offsets[i]);
        }
        expect(channel.connectCalls, isEmpty);
        expect(channel.sentVoiceTranscripts, isEmpty);
        expect(channel.disconnectCalls, 0);
        expect(channel.stopActiveTurnCalls, 0);
        expect(channel.createSessionCalls, isEmpty);
        expect(channel.selectSessionCalls, isEmpty);
        expect(channel.selectProfileCalls, isEmpty);
        expect(store.saveCalls, isEmpty);
        if (trigger == 'manage') {
          await tester.tap(
            find.byKey(const ValueKey('hermes-profile-switcher')),
          );
          await settleRoutes(tester);
          expect(
            find.byKey(const ValueKey('chat-profile-search')),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        debugDefaultTargetPlatformOverride = null;
      });
    }
    for (final destination in [AppRoutes.profiles, AppRoutes.settings]) {
      for (final dismissal in ['close', 'back', 'escape']) {
        testWidgets(
          'shell $destination retains mounted chat/full location via $dismissal at $width',
          (tester) async {
            SharedPreferences.setMockInitialValues({});
            tester.view.physicalSize = Size(width, 900);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            if (Platform.environment['WING_OVERLAY_CAPTURE'] == '1') {
              await tester.runAsync(() async {
                final root = Platform.environment['FLUTTER_ROOT']!;
                for (final entry in {
                  'Roboto':
                      '$root/engine/src/flutter/txt/third_party/fonts/Roboto-Regular.ttf',
                  'MaterialIcons':
                      '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
                }.entries) {
                  final loader = FontLoader(entry.key)
                    ..addFont(
                      File(
                        entry.value,
                      ).readAsBytes().then(ByteData.sublistView),
                    );
                  await loader.load();
                }
              });
            }
            final channel = FakeHermesChannel();
            channel.replaceTranscript([
              for (var index = 0; index < 25; index++)
                HermesChatTurn(
                  id: 'synthetic-$index',
                  sessionId: 'sess_1',
                  author: HermesTurnAuthor.assistant,
                  createdAt: DateTime.utc(2026),
                  text: 'Synthetic layout row $index. No provider was called.',
                  status: index == 24
                      ? HermesTurnStatus.streaming
                      : HermesTurnStatus.completed,
                ),
            ]);
            final store = FakeHermesEndpointStore();
            final container = ProviderContainer(
              overrides: [
                hermesChannelProvider.overrideWithValue(channel),
                hermesEndpointStoreProvider.overrideWithValue(store),
              ],
            );
            addTearDown(container.dispose);
            addTearDown(channel.dispose);
            final router = container.read(routerProvider);
            addTearDown(router.dispose);
            const location = '/hermes?session=synthetic&filter=all#tail';
            router.go(location);
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: RepaintBoundary(
                  key: const ValueKey('capture'),
                  child: MaterialApp.router(
                    debugShowCheckedModeBanner: false,
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    routerConfig: router,
                  ),
                ),
              ),
            );
            await settleRoutes(tester);
            final chat = tester.state(find.byType(HermesChatScreen));
            final field = find.byKey(composer);
            await tester.enterText(field, 'unsent synthetic draft');
            final editor = tester.widget<TextField>(field);
            final controller = editor.controller;
            final session = channel.state.activeSessionId;
            final positions = tester
                .stateList<ScrollableState>(
                  find.descendant(
                    of: find.byType(HermesChatScreen),
                    matching: find.byType(Scrollable),
                  ),
                )
                .map((state) => state.position)
                .toList();
            final transcript = positions.firstWhere(
              (position) => position.maxScrollExtent > 100,
            );
            transcript.jumpTo(transcript.maxScrollExtent / 2);
            await tester.pump();
            final offsets = positions
                .map((position) => position.pixels)
                .toList();
            if (width < 600) {
              if (destination == AppRoutes.settings) {
                await tester.tap(
                  find.descendant(
                    of: find.byType(NavigationBar),
                    matching: find.text('More'),
                  ),
                );
                await settleRoutes(tester);
                await tester.ensureVisible(find.text('Settings').last);
                await tester.tap(find.text('Settings').last);
              } else {
                await tester.tap(
                  find.descendant(
                    of: find.byType(NavigationBar),
                    matching: find.text('Profiles'),
                  ),
                );
              }
            } else if (destination == AppRoutes.profiles) {
              await tester.tap(
                find.byKey(const ValueKey('desktop-manage-profiles')),
              );
            } else {
              await tester.ensureVisible(
                find
                    .descendant(
                      of: find.byKey(const ValueKey('desktop-sidebar')),
                      matching: find.text('Settings'),
                    )
                    .first,
              );
              await settleRoutes(tester);
              await tester.tap(
                find
                    .descendant(
                      of: find.byKey(const ValueKey('desktop-sidebar')),
                      matching: find.text('Settings'),
                    )
                    .first,
              );
            }
            await settleRoutes(tester);
            expect(
              chat.mounted,
              isTrue,
              reason: 'overlay must not dispose chat',
            );
            expect(find.byKey(close), findsOneWidget);

            expect(editor.focusNode!.hasFocus, isFalse);
            final semantics = tester.ensureSemantics();
            expect(tester.getSemantics(find.byKey(close)).tooltip, 'Close');
            expect(
              tester
                  .getSemantics(find.byKey(close))
                  .getSemanticsData()
                  .flagsCollection
                  .isFocused
                  .toBoolOrNull(),
              isTrue,
            );
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pump();
            expect(editor.focusNode!.hasFocus, isFalse);
            await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
            await settleRoutes(tester);
            if (destination == AppRoutes.settings && dismissal == 'back') {
              await tester.tap(find.text('Voice & speech'));
              await settleRoutes(tester);
              expect(chat.mounted, isTrue);
              await tester.binding.handlePopRoute();
              await settleRoutes(tester);
              expect(find.text('Settings'), findsWidgets);
              expect(chat.mounted, isTrue);
              expect(channel.stopActiveTurnCalls, 0);
            }
            expect(find.byType(ModalBarrier), findsWidgets);
            await tester.tapAt(const Offset(2, 2));
            await settleRoutes(tester);
            expect(editor.focusNode!.hasFocus, isFalse);
            if (dismissal == 'close') {
              await capture(
                tester,
                'chat-overlay-${destination.substring(1)}-${width.toInt()}',
              );
              await tester.tap(find.byKey(close));
            } else if (dismissal == 'back') {
              await tester.binding.handlePopRoute();
            } else {
              await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            }
            await settleRoutes(tester);
            expect(
              router.routeInformationProvider.value.uri.toString(),
              location,
            );
            expect(tester.state(find.byType(HermesChatScreen)), same(chat));
            expect(
              tester.widget<TextField>(field).controller,
              same(controller),
            );
            expect(controller!.text, 'unsent synthetic draft');
            expect(channel.state.activeSessionId, session);
            for (var i = 0; i < positions.length; i++) {
              expect(positions[i].hasPixels, isTrue);
              expect(positions[i].pixels, offsets[i]);
            }
            expect(channel.connectCalls, isEmpty);
            expect(channel.sentVoiceTranscripts, isEmpty);
            expect(channel.disconnectCalls, 0);
            expect(channel.stopActiveTurnCalls, 0);
            expect(
              channel.state.activeMessages.last.status,
              HermesTurnStatus.streaming,
            );
            expect(channel.createSessionCalls, isEmpty);
            expect(channel.selectSessionCalls, isEmpty);
            expect(store.saveCalls, isEmpty);
            expect(tester.takeException(), isNull);
            semantics.dispose();
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
      }
    }
    for (final destination in [AppRoutes.profiles, AppRoutes.settings]) {
      testWidgets(
        'direct $destination at $width stays disconnected and returns through chat entry',
        (tester) async {
          SharedPreferences.setMockInitialValues({});
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final channel = FakeHermesChannel.disconnected();
          final store = FakeHermesEndpointStore();
          final container = ProviderContainer(
            overrides: [
              hermesChannelProvider.overrideWithValue(channel),
              hermesEndpointStoreProvider.overrideWithValue(store),
            ],
          );
          addTearDown(container.dispose);
          addTearDown(channel.dispose);
          final router = container.read(routerProvider);
          addTearDown(router.dispose);
          router.go(destination);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp.router(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                routerConfig: router,
              ),
            ),
          );
          await settleRoutes(tester);
          expect(find.byKey(close), findsOneWidget);
          expect(find.byType(HermesChatScreen), findsNothing);
          await tester.binding.handlePopRoute();
          await settleRoutes(tester);
          expect(
            router.routeInformationProvider.value.uri.path,
            AppRoutes.hermes,
          );
          expect(find.byKey(const ValueKey('hermes-welcome')), findsOneWidget);
          expect(channel.state.isConnected, isFalse);
          expect(channel.connectCalls, isEmpty);
          expect(store.saveCalls, isEmpty);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
}
