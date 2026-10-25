import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/settings/providers/chat_preferences_provider.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';

void main() {
  testWidgets(
    'local chat backdrop changes decoration without changing chat ownership',
    (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final width in [390.0, 1280.0]) {
        for (final brightness in Brightness.values) {
          SharedPreferences.setMockInitialValues({
            'wing.tips.dismissed.v1': [
              'moreDestinations',
              'voice',
              'approvals',
            ],
          });
          tester.view.physicalSize = Size(width, 1400);
          final channel = FakeHermesChannel();
          final turns = List.generate(
            30,
            (i) => HermesChatTurn(
              id: 'backdrop-$i',
              sessionId: 'sess_1',
              author: HermesTurnAuthor.assistant,
              createdAt: DateTime.utc(2026),
              text: 'Synthetic loaded message $i.\n\nSecond paragraph.',
            ),
          );
          channel.replaceTranscript(turns);
          final container = ProviderContainer(
            overrides: [hermesChannelProvider.overrideWithValue(channel)],
          );
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                theme: ThemeData(brightness: brightness),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(2)),
                  child: child!,
                ),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const HermesChatScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final field = find.byKey(const ValueKey('hermes-composer-field'));
          final foreground = tester.element(field);
          final original = tester.widget<TextField>(field);
          final controller = original.controller!;
          final focus = original.focusNode!;
          final route = ModalRoute.of(tester.element(field));
          final transcript = find.byKey(const ValueKey('hermes-transcript'));
          final transcriptElement = tester.element(transcript);
          final scroll = tester.state<ScrollableState>(
            find
                .descendant(of: transcript, matching: find.byType(Scrollable))
                .first,
          );
          scroll.position.jumpTo(scroll.position.maxScrollExtent / 2);
          focus.requestFocus();
          const draft = TextEditingValue(
            text: 'Synthetic selected draft',
            selection: TextSelection(baseOffset: 1, extentOffset: 5),
            composing: TextRange(start: 0, end: 5),
          );
          controller.value = draft;
          await tester.pumpAndSettle();
          final position = scroll.position.pixels;
          final settings = container.read(wingChatPreferencesProvider.notifier);
          final backdrop = find.byKey(const ValueKey('chat-backdrop-art'));
          expect(backdrop, findsNothing);
          final owner = channel.state;
          final session = owner.activeSessionId;
          final profile = owner.selectedProfileId;
          for (final enabled in [true, false, true, false]) {
            final before = channel.state;
            settings.setBackdropEnabled(enabled);
            await tester.pumpAndSettle();
            expect(backdrop, enabled ? findsOneWidget : findsNothing);
            if (enabled) {
              final imageFinder = find.descendant(
                of: backdrop,
                matching: find.byType(Image),
              );
              final image = tester.widget<Image>(imageFinder);
              expect(image.excludeFromSemantics, isTrue);
              final resized = image.image as ResizeImage;
              expect(
                (resized.imageProvider as AssetImage).assetName,
                'assets/desktop/filler-bg0.jpg',
              );
              expect(resized.width, greaterThanOrEqualTo(width.round()));
              expect(resized.width, lessThan(4000));
              await tester.runAsync(
                () => precacheImage(image.image, tester.element(imageFinder)),
              );
              await tester.pumpAndSettle();
              final rendered = tester.renderObject<RenderImage>(
                find.descendant(
                  of: imageFinder,
                  matching: find.byType(RawImage),
                ),
              );
              expect(
                rendered.image,
                isNotNull,
                reason: 'Bundled art must really decode',
              );
              final artSize = tester.getSize(imageFinder);
              final pane = tester.getSize(
                find.byKey(const ValueKey('chat-backdrop-pane')),
              );
              expect(artSize.width, greaterThanOrEqualTo(pane.width));
              expect(artSize.height, pane.height * 1.6);
              expect(image.alignment, Alignment.topLeft);
              expect(
                tester
                    .widget<Opacity>(
                      find.descendant(
                        of: backdrop,
                        matching: find.byType(Opacity),
                      ),
                    )
                    .opacity,
                .025,
              );
              final filters = tester
                  .widgetList<ColorFiltered>(
                    find.descendant(
                      of: backdrop,
                      matching: find.byType(ColorFiltered),
                    ),
                  )
                  .toList();
              final surface = Theme.of(
                tester.element(field),
              ).colorScheme.surface;
              expect(
                filters.first.colorFilter,
                ColorFilter.mode(surface, BlendMode.difference),
              );
              expect(filters.length, brightness == Brightness.light ? 2 : 1);
              if (brightness == Brightness.light) {
                expect(
                  filters.last.colorFilter,
                  const ColorFilter.matrix(<double>[
                    -1,
                    0,
                    0,
                    0,
                    255,
                    0,
                    -1,
                    0,
                    0,
                    255,
                    0,
                    0,
                    -1,
                    0,
                    255,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ]),
                );
              }
              expect(
                find.ancestor(
                  of: imageFinder,
                  matching: find.byType(IgnorePointer),
                ),
                findsWidgets,
              );
              expect(
                find.ancestor(
                  of: imageFinder,
                  matching: find.byType(ExcludeSemantics),
                ),
                findsWidgets,
              );
              expect(
                find.ancestor(
                  of: imageFinder,
                  matching: find.byType(ExcludeFocus),
                ),
                findsWidgets,
              );
              expect(
                find.ancestor(of: field, matching: find.byType(ColorFiltered)),
                findsNothing,
              );
              expect(
                find.ancestor(of: imageFinder, matching: find.byType(ClipRect)),
                findsWidgets,
              );
            }
            expect(tester.element(field), same(foreground));
            expect(tester.element(transcript), same(transcriptElement));
            expect(
              tester.widget<TextField>(field).controller,
              same(controller),
            );
            expect(tester.widget<TextField>(field).focusNode, same(focus));
            expect(focus.hasFocus, isTrue);
            expect(controller.value, draft);
            expect(scroll.position.pixels, position);
            expect(ModalRoute.of(tester.element(field)), same(route));
            expect(container.read(hermesChannelProvider), same(channel));
            expect(channel.state, same(before));
            if (enabled) {
              channel.replaceTranscript([
                ...channel.state.activeMessages,
                HermesChatTurn(
                  id: 'extra-${channel.state.activeMessages.length}',
                  sessionId: session!,
                  author: HermesTurnAuthor.assistant,
                  createdAt: DateTime.utc(2026),
                  text: 'Synthetic loaded update',
                ),
              ]);
              await tester.pumpAndSettle();
            }
          }
          channel.beginStreamingTurn('Synthetic streaming update');
          await tester.pump(const Duration(seconds: 1));
          settings.setBackdropEnabled(true);
          channel.appendStreamingTurnText('Synthetic streamed text');
          await tester.pump(const Duration(seconds: 1));
          settings.setBackdropEnabled(false);
          channel.completeStreamingTurn(text: 'Synthetic completed text');
          await tester.pumpAndSettle();
          expect(tester.element(field), same(foreground));
          expect(controller.value, draft);
          expect(focus.hasFocus, isTrue);
          expect(channel.state.activeSessionId, session);
          expect(channel.state.selectedProfileId, profile);
          expect(channel.connectCalls, isEmpty);
          expect(channel.selectSessionCalls, isEmpty);
          expect(channel.selectProfileCalls, isEmpty);
          expect(channel.createSessionCalls, isEmpty);
          expect(channel.loadEarlierMessagesCalls, 0);
          expect(channel.loadMoreSessionsCalls, 0);
          expect(channel.reconcileActiveSessionCalls, 0);
          expect(channel.loadProvidersCalls, 0);
          expect(channel.loadModelsCalls, 0);
          expect(channel.assignModelCalls, isEmpty);
          expect(channel.lockSessionModelCalls, isEmpty);
          expect(channel.stopActiveTurnCalls, 0);
          expect(channel.respondToApprovalCalls, isEmpty);
          expect(channel.sentImageDataUrls, isEmpty);
          // The decorative layer must let one real foreground click through.
          settings.setBackdropEnabled(true);
          controller.value = const TextEditingValue(
            text: 'Synthetic send once',
            selection: TextSelection.collapsed(offset: 19),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
          await tester.pumpAndSettle();
          expect(channel.sentImageDataUrls, hasLength(1));
          expect(channel.state.activeSessionId, session);
          channel.replaceTranscript([]);
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'Empty-chat ListTile ink needs a local Material surface',
          );
          await tester.pumpWidget(const SizedBox());
          container.dispose();
          channel.dispose();
        }
      }
      semantics.dispose();
    },
  );
}
