import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/app/wing_app.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/enrollment/providers/hermes_enrollment_provider.dart';
import 'package:wing/features/enrollment/services/hermes_connect_intent_source.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';

import 'package:wing/router/providers/app_router.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';
import '../hermes_chat/support/fake_hermes_endpoint_store.dart';
import '../hermes_chat/support/fake_hermes_gateway_directory.dart';

class _Ingress implements HermesConnectIntentSource {
  _Ingress(this.pending);
  String? pending;
  final events = StreamController<String>.broadcast();
  int scans = 0;
  int imports = 0;
  @override
  Future<String?> initialPayload() async => pending;
  @override
  Future<String?> consumeInitialPayload() async {
    final value = pending;
    pending = null;
    return value;
  }

  @override
  Stream<String> payloadEvents() => events.stream;
  @override
  Future<String?> scanQrCode() async {
    scans++;
    return null;
  }

  @override
  Future<String?> importQrImage() async {
    imports++;
    return null;
  }
}

void main() {
  testWidgets(
    'warm handoff cancellation preserves fresh welcome and direct form',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final source = _Ingress(null);
      addTearDown(source.events.close);
      final store = FakeHermesEndpointStore();
      final channel = FakeHermesChannel.disconnected();
      addTearDown(channel.dispose);
      final originalState = channel.state;

      final directory = directoryFor(
        configs: [],
        loader: FakeGatewaySummaryLoader({}),
        activeChannel: channel,
      );
      final container = ProviderContainer(
        overrides: [
          hermesConnectIntentSourceProvider.overrideWithValue(source),
          hermesEndpointStoreProvider.overrideWithValue(store),
          hermesChannelProvider.overrideWithValue(channel),
          hermesGatewayDirectoryProvider.overrideWith((_) => directory),
          hermesVoiceCaptureServiceProvider.overrideWithValue(null),
          hermesTextToSpeechServiceProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const WingApp()),
      );
      await tester.pumpAndSettle();
      final router = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      ).read(routerProvider);
      final welcome = find.byKey(const ValueKey('hermes-welcome'));
      final rejected = find.byKey(
        const ValueKey('hermes-enrollment-legacy-rejected'),
      );
      expect(router.state.uri.path, '/hermes');
      expect(welcome, findsOneWidget);

      for (final directForm in [false, true]) {
        TextEditingController? draft;
        final url = find.byKey(const ValueKey('hermes-base-url-field'));
        if (directForm) {
          await tester.ensureVisible(
            find.byKey(const ValueKey('hermes-welcome-remote')),
          );
          await tester.tap(find.byKey(const ValueKey('hermes-welcome-remote')));
          await tester.pumpAndSettle();
          await tester.enterText(url, 'https://agent.example');
          draft = tester.widget<TextField>(url).controller;
        }
        for (final platformBack in [false, true]) {
          source.pending = 'malformed fixture-warm-share';
          source.events.add(source.pending!);
          await tester.pumpAndSettle();
          expect(rejected, findsOneWidget);
          if (platformBack) {
            await tester.binding.handlePopRoute();
          } else {
            await tester.tap(
              find.byKey(const ValueKey('hermes-enrollment-cancel')),
            );
          }
          await tester.pumpAndSettle();
          expect(router.state.uri.path, directForm ? '/hermes/add' : '/hermes');
          expect(rejected, findsNothing);
          expect(source.pending, isNull);
          if (directForm) {
            expect(tester.widget<TextField>(url).controller, same(draft));
            expect(draft!.text, 'https://agent.example');
          } else {
            expect(welcome, findsOneWidget);
          }
        }
        if (directForm) {
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(router.state.uri.path, '/hermes');
          expect(welcome, findsOneWidget);
          expect(rejected, findsNothing);
        }
      }
      expect(channel.state, same(originalState));
      expect(await store.loadProfiles(), isEmpty);
      expect(store.saveCalls, isEmpty);
      expect(store.clearCalls, 0);
      expect(store.deleteProfileCalls, isEmpty);
      expect(channel.connectCalls, isEmpty);
      expect(channel.state.messages, isEmpty);

      expect(source.scans, 0);
      expect(source.imports, 0);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.linux,
    }),
  );

  for (final input in [
    null,
    'wing://connect?origin=https%3A%2F%2Flegacy.example&code=fixture-expired',
    'Shared legacy handoff: not a valid URI fixture-private',
  ]) {
    testWidgets(
      'legacy route and cold/warm handoffs reject $input',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = const Size(390, 1000);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final semantics = tester.ensureSemantics();

        final source = _Ingress(input);
        addTearDown(source.events.close);
        final store = FakeHermesEndpointStore(
          profiles: const [
            HermesEndpointConfig(
              id: 'saved',
              baseUrl: 'https://agent.example/p/owner',
              apiKey: 'fixture-agent',
            ),
          ],
        );
        final original = await store.loadProfiles();
        final channel = FakeHermesChannel(
          sessionId: 'session-owner',
          connectedBaseUrl: 'https://agent.example/p/owner',
          selectedProfileId: 'owner',
          activeSessionId: 'session-owner',
        );

        final directory = directoryFor(
          configs: [],
          loader: FakeGatewaySummaryLoader({}),
          activeChannel: channel,
        );

        var clipboard = 0;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.getData') clipboard++;
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        final container = ProviderContainer(
          overrides: [
            hermesConnectIntentSourceProvider.overrideWithValue(source),
            hermesEndpointStoreProvider.overrideWithValue(store),
            hermesChannelProvider.overrideWithValue(channel),
            hermesGatewayDirectoryProvider.overrideWith((_) => directory),
            hermesVoiceCaptureServiceProvider.overrideWithValue(null),
            hermesTextToSpeechServiceProvider.overrideWithValue(null),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const WingApp(),
          ),
        );
        await tester.pumpAndSettle();
        final appContainer = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp)),
        );
        final router = appContainer.read(routerProvider);
        if (input == null) {
          router.go('/enroll?step=pair');
          await tester.pumpAndSettle();
        }
        final rejected = find.byKey(
          const ValueKey('hermes-enrollment-legacy-rejected'),
        );
        expect(rejected, findsOneWidget);
        expect(
          tester.getSemantics(rejected).flagsCollection.isLiveRegion,
          isTrue,
        );
        for (final key in [
          'hermes-enrollment-paste-link',
          'hermes-enrollment-scan-qr',
          'hermes-enrollment-import-qr-image',
          'hermes-enrollment-confirm',
          'hermes-enrollment-link-field',
        ]) {
          expect(find.byKey(ValueKey(key)), findsNothing);
        }
        expect(find.textContaining('fixture-expired'), findsNothing);
        expect(find.textContaining('fixture-private'), findsNothing);
        await tester.ensureVisible(
          find.byKey(const ValueKey('hermes-enrollment-cancel')),
        );
        await tester.tap(
          find.byKey(const ValueKey('hermes-enrollment-cancel')),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('hermes-welcome')), findsOneWidget);
        source.pending = 'wing://connect?code=fixture-warm';
        source.events.add(source.pending!);
        await tester.pumpAndSettle();
        expect(rejected, findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('hermes-welcome')), findsOneWidget);
        router.go('/enroll');
        await tester.pumpAndSettle();
        expect(rejected, findsNothing);
        expect(source.pending, isNull);
        await tester.ensureVisible(
          find.byKey(const ValueKey('hermes-welcome-remote')),
        );
        await tester.tap(find.byKey(const ValueKey('hermes-welcome-remote')));
        await tester.pumpAndSettle();
        expect(router.state.uri.path, '/hermes/add');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        router.go('/hermes');
        await tester.pumpAndSettle();
        final composer = find.byKey(const ValueKey('hermes-composer-field'));
        expect(
          composer,
          findsOneWidget,
          reason: tester
              .widgetList<Text>(find.byType(Text))
              .map((t) => t.data)
              .join(' | '),
        );
        await tester.enterText(composer, 'unsent fixture draft');
        final draft = tester.widget<TextField>(composer).controller!;
        source.pending = 'malformed fixture-warm-share';
        source.events.add(source.pending!);
        await tester.pumpAndSettle();
        expect(rejected, findsOneWidget);
        await tester.ensureVisible(
          find.byKey(const ValueKey('hermes-enrollment-cancel')),
        );
        await tester.tap(
          find.byKey(const ValueKey('hermes-enrollment-cancel')),
        );
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(composer).controller, same(draft));
        expect(draft.text, 'unsent fixture draft');
        expect(source.pending, isNull);
        expect(channel.state.connectedBaseUrl, 'https://agent.example/p/owner');
        expect(channel.state.selectedProfileId, 'owner');
        expect(channel.state.activeSessionId, 'session-owner');
        expect(await store.loadProfiles(), original);
        expect(store.saveCalls, isEmpty);
        expect(store.clearCalls, 0);
        expect(store.deleteProfileCalls, isEmpty);
        expect(channel.connectCalls, isEmpty);
        expect(
          channel.state.messages.values.every((turns) => turns.isEmpty),
          isTrue,
        );

        expect(clipboard, 0);
        expect(source.scans, 0);
        expect(source.imports, 0);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
      variant: TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.linux,
      }),
    );
  }
}
