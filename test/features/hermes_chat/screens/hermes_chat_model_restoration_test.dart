import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../gateways/hermes_gateway_session_restoration_test.dart'
    show RestorationHarness;
import '../support/fake_hermes_endpoint_store.dart';

void main() {
  for (final width in [390.0, 1280.0]) {
    testWidgets(
      'recovered session model survives Chat remount at ${width.toInt()}px without a lock write',
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
          if (uri.path != '/api/sessions/older-A') return null;
          expect(uri.queryParameters['profile'], 'coder');
          return '{"object":"hermes.session","session":'
              '{"id":"older-A","source":"api_server","model":"synthetic/model-restored"}}';
        };
        await h.directory.start();
        expect(h.channel.state.activeSessionId, 'older-A');
        expect(h.channel.state.selectedProfileId, 'coder');
        expect(
          h.channel.state.activeSession?.model,
          'synthetic/model-restored',
        );
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
        expect(h.channel.state.activeSessionId, 'older-A');
        expect(h.cache.selection?.sessionId, 'older-A');
        final chip = find.byKey(const ValueKey('hermes-composer-model-chip'));
        expect(chip, findsOneWidget);
        expect(
          find.descendant(
            of: chip,
            matching: find.text('synthetic/model-restored'),
          ),
          findsOneWidget,
        );
        expect(h.channel.state.sessionModelLocks, isEmpty);
        expect(h.mutations, isEmpty);

        // A label-only recovery must not leak into the next session or create
        // a provider/model lock from metadata that contains no provider identity.
        await h.channel.selectSession('newer-B');
        await tester.pumpAndSettle();
        expect(h.channel.state.activeSessionId, 'newer-B');
        expect(
          find.descendant(
            of: chip,
            matching: find.text('synthetic/model-restored'),
          ),
          findsNothing,
        );
        expect(h.channel.state.sessionModelLocks, isEmpty);
        expect(h.mutations, isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
      variant: TargetPlatformVariant.only(TargetPlatform.linux),
    );
  }
}
