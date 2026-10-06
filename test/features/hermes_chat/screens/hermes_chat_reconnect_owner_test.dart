import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../gateways/hermes_gateway_session_restoration_test.dart'
    show RestorationHarness, target;
import '../support/fake_hermes_endpoint_store.dart';

void main() {
  testWidgets(
    'real Reconnect preserves the explicit off-page session owner',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = RestorationHarness();
      addTearDown(h.dispose);
      // This harness's legacy nested pagination is not a paging advertisement.
      // Supply the actual top-level session-page contract for this regression.
      h.onRead = (uri) async => uri.path == '/api/sessions'
          ? '{"data":[{"id":"newer-B","source":"api_server"}],'
                '"offset":0,"limit":50,"has_more":true,"next_offset":50}'
          : null;
      await h.directory.start();
      expect(h.channel.state.hasMoreSessions, isTrue);
      expect(h.channel.state.selectedProfileId, 'coder');
      expect(h.channel.state.activeSessionId, 'older-A');
      expect(h.cache.selection?.contactId, target.contactId);
      expect(h.cache.selection?.sessionId, target.sessionId);

      // A bounded read failure exposes Reconnect without any chat submission
      // or mutation, isolating owner recovery from Stop settlement.
      h.onRead = (uri) async {
        if (uri.path == '/api/sessions') {
          throw StateError('Synthetic stream disconnected');
        }
        return null;
      };
      await h.channel.loadMoreSessions();
      h.onRead = null;
      expect(h.channel.state.errorMessage, isNotNull);
      expect(h.mutations, isEmpty);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hermesChannelProvider.overrideWithValue(h.channel),
            hermesGatewayDirectoryProvider.overrideWith((_) {
              // Riverpod owns directory disposal after this provider is built.
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
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HermesChatScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final reconnect = find.byKey(
        const ValueKey('hermes-chat-error-reconnect'),
      );
      expect(reconnect, findsOneWidget);
      final readsBefore = h.reads.length;
      await tester.ensureVisible(reconnect);
      await tester.tap(reconnect);
      await tester.pumpAndSettle();

      final recoveryReads = h.reads.skip(readsBefore).toList();
      // Capture both active and persisted ownership before the first assertion
      // so a failed run discriminates actual owner loss from missing semantics.
      debugPrint(
        'RECONNECT_OWNER active=${h.channel.state.activeSessionId} '
        'profile=${h.channel.state.selectedProfileId} '
        'saved=${h.cache.selection?.sessionId} '
        'savedProfile=${h.cache.selection?.contactId.profileId} '
        'reads=${recoveryReads.map((u) => '${u.path}?profile=${u.queryParameters['profile']}').toList()} '
        'mutations=${h.mutations.length}',
      );
      expect(h.channel.state.activeSessionId, 'older-A');
      expect(h.channel.state.selectedProfileId, 'coder');
      expect(h.cache.selection?.contactId, target.contactId);
      expect(h.cache.selection?.sessionId, target.sessionId);
      expect(h.cache.saved.map((s) => s.sessionId), isNot(contains('newer-B')));
      expect(h.channel.state.activeMessages.single.id, 'canonical-A');
      expect(
        recoveryReads.where((u) => u.path == '/api/sessions/older-A'),
        hasLength(1),
      );
      expect(
        recoveryReads
            .where((u) => u.path.startsWith('/api/sessions/older-A'))
            .every((u) => u.queryParameters['profile'] == 'coder'),
        isTrue,
      );
      expect(h.mutations, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
}
