import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/hermes_chat/widgets/session_model_picker_sheet.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../gateways/hermes_gateway_session_restoration_test.dart'
    show RestorationHarness;
import '../support/fake_hermes_endpoint_store.dart';

void main() {
  for (final width in [390.0, 1280.0]) {
    testWidgets(
      'metadata-only recovery never confirms a provider or replays a lock at ${width.toInt()}px',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final h = RestorationHarness();
        addTearDown(h.dispose);
        h.configureCapabilities = (document) {
          final endpoints = document['endpoints']! as Map<String, Object?>;
          endpoints['model_options'] = {
            'method': 'GET',
            'path': '/api/model/options',
          };
          endpoints['session_model_lock'] = {
            'method': 'POST',
            'path': '/api/sessions/{session_id}/model',
          };
        };
        h.onRead = (uri) async {
          if (uri.path == '/api/model/options') {
            return jsonEncode({
              'provider': 'beta',
              'model': 'shared-model',
              'providers': [
                for (final slug in ['alpha', 'beta'])
                  {
                    'slug': slug,
                    'label': slug == 'alpha' ? 'Alpha' : 'Beta',
                    'authenticated': true,
                    'models': ['shared-model'],
                  },
              ],
            });
          }
          if (uri.path != '/api/sessions/older-A') return null;
          expect(uri.queryParameters['profile'], 'coder');
          return jsonEncode({
            'object': 'hermes.session',
            'session': {
              'id': 'older-A',
              'source': 'api_server',
              'model': 'shared-model',
            },
          });
        };
        await h.directory.start();
        expect(h.channel.state.activeSessionId, 'older-A');
        expect(h.channel.state.selectedProfileId, 'coder');
        expect(h.channel.state.activeSession?.model, 'shared-model');
        expect(h.channel.state.sessionModelLocks, isEmpty);
        final showChat = ValueNotifier(true);
        addTearDown(showChat.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              hermesChannelProvider.overrideWithValue(h.channel),
              hermesGatewayDirectoryProvider.overrideWith((_) {
                h.disposed = true;
                return h.directory;
              }),
              hermesEndpointStoreProvider.overrideWithValue(
                FakeHermesEndpointStore(
                  initial: const HermesEndpointConfig(
                    id: 'alpha',
                    baseUrl: 'https://alpha.example',
                    apiKey: 'synthetic-agent',
                  ),
                ),
              ),
              hermesVoiceCaptureServiceProvider.overrideWithValue(null),
              hermesTextToSpeechServiceProvider.overrideWithValue(null),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: ValueListenableBuilder<bool>(
                valueListenable: showChat,
                builder: (context, visible, _) => visible
                    ? const HermesChatScreen()
                    : const Scaffold(body: Text('Away from Chat')),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        showChat.value = false;
        await tester.pumpAndSettle();
        expect(find.text('Away from Chat'), findsOneWidget);
        showChat.value = true;
        await tester.pumpAndSettle();
        final chip = find.byKey(const ValueKey('hermes-composer-model-chip'));
        expect(
          find.descendant(of: chip, matching: find.text('shared-model')),
          findsOneWidget,
        );
        expect(h.channel.state.canLockSessionModel, isTrue);
        expect(h.channel.state.activeMessages.single.id, 'canonical-A');
        for (var opening = 0; opening < 2; opening++) {
          await tester.tap(chip);
          await tester.pumpAndSettle();
          final picker = tester.widget<SessionModelPickerSheet>(
            find.byType(SessionModelPickerSheet),
          );
          // Shared model text and catalog defaults cannot prove either provider.
          // An unknown session pair requires a fresh explicit selection.
          expect(picker.currentSessionModel, isNull);
          expect(picker.options.currentProvider, 'beta');
          expect(picker.options.currentModel, 'shared-model');
          expect(picker.options.selectableProviders.map((p) => p.slug), [
            'alpha',
            'beta',
          ]);
          expect(
            find.text('Selected: Beta (beta) — shared-model'),
            findsNothing,
          );
          expect(
            find.text(
              'Hermes Agent does not report this session’s confirmed provider and model. Choose a model explicitly to change this session; cancelling leaves it unchanged.',
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
          expect(
            tester
                .widgetList<ListTile>(
                  find.descendant(
                    of: find.byType(SessionModelPickerSheet),
                    matching: find.byType(ListTile),
                  ),
                )
                .every((tile) => tile.trailing == null),
            isTrue,
          );
          await tester.tap(
            find.byKey(const ValueKey('session-model-alpha/shared-model')),
          );
          await tester.pumpAndSettle();
          expect(
            find.text('Selected: Alpha (alpha) — shared-model'),
            findsOneWidget,
          );
          expect(h.channel.state.sessionModelLocks, isEmpty);
          expect(h.mutations, isEmpty);
          await tester.ensureVisible(find.text('Cancel'));
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
          expect(find.byType(SessionModelPickerSheet), findsNothing);
          expect(h.channel.state.activeSessionId, 'older-A');
          expect(h.channel.state.selectedProfileId, 'coder');
          expect(h.cache.selection?.sessionId, 'older-A');
          expect(h.channel.state.activeSession?.model, 'shared-model');
          expect(h.channel.state.sessionModelLocks, isEmpty);
          expect(h.mutations, isEmpty);
        }
        expect(h.reads.any((u) => u.path == '/api/model/options'), isTrue);
        expect(
          h.reads
              .where((u) => u.path == '/api/sessions/older-A')
              .every((u) => u.queryParameters['profile'] == 'coder'),
          isTrue,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
      variant: TargetPlatformVariant.only(TargetPlatform.linux),
    );
  }
}
