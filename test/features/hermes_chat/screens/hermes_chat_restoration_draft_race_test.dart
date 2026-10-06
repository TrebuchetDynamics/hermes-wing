import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../gateways/hermes_gateway_session_restoration_test.dart'
    show RestorationHarness, target;
import '../support/fake_hermes_endpoint_store.dart';

const _composer = ValueKey('hermes-composer-field');

void main() {
  for (final phase in ['metadata', 'history']) {
    testWidgets(
      'real parked $phase cannot retarget the chosen B draft',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final h = RestorationHarness();
        h.configureCapabilities = (doc) {
          doc['features'] = {'session_chat_streaming': true};
          (doc['endpoints'] as Map)['session_chat_stream'] = {
            'method': 'POST',
            'path': '/api/sessions/{session_id}/chat/stream',
          };
        };
        await h.directory.start();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              hermesChannelProvider.overrideWithValue(h.channel),
              hermesGatewayDirectoryProvider.overrideWith((_) => h.directory),
              hermesEndpointStoreProvider.overrideWithValue(
                FakeHermesEndpointStore(),
              ),
              hermesVoiceCaptureServiceProvider.overrideWithValue(null),
              hermesTextToSpeechServiceProvider.overrideWithValue(null),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
              home: const HermesChatScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(_composer),
          'Synthetic owned A draft',
        );
        await h.channel.selectSession('newer-B');
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(_composer),
          'Synthetic owned B draft',
        );
        final entered = Completer<void>();
        final release = Completer<String>();
        final path = phase == 'metadata'
            ? '/api/sessions/older-A'
            : '/api/sessions/older-A/messages';
        h.onRead = (uri) async {
          if (uri.path == path && !entered.isCompleted) {
            entered.complete();
            return release.future;
          }
          return null;
        };
        final restoration = h.directory.activate(
          target.contactId,
          preferredSessionId: 'older-A',
        );
        await entered.future;
        await tester.pumpAndSettle();
        expect(find.byKey(_composer), findsNothing);
        await tester.tap(
          find.byKey(const ValueKey('hermes-session-restoration-choose')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('hermes-session-title-newer-B')),
        );
        await tester.pumpAndSettle();
        expect(h.channel.state.activeSessionId, 'newer-B');
        expect(
          tester.widget<TextField>(find.byKey(_composer)).controller!.text,
          'Synthetic owned B draft',
        );
        await tester.enterText(
          find.byKey(_composer),
          'Synthetic latest B draft',
        );
        release.complete(
          phase == 'metadata'
              ? '{"object":"hermes.session","session":{"id":"older-A","source":"api_server"}}'
              : '{"data":[{"id":"stale-A","role":"assistant","content":"Stale A"}]}',
        );
        await restoration;
        await tester.pumpAndSettle();
        expect(h.channel.state.activeSessionId, 'newer-B');
        expect(h.channel.state.activeMessages.single.id, 'canonical-B');
        expect(
          tester.widget<TextField>(find.byKey(_composer)).controller!.text,
          'Synthetic latest B draft',
        );
        expect(h.cache.selection?.sessionId, 'newer-B');
        expect(h.mutations, isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        h.disposed =
            true; // ChangeNotifierProvider owns its directory override.
        h.dispose();
      },
      variant: TargetPlatformVariant.only(TargetPlatform.linux),
    );
  }
}
