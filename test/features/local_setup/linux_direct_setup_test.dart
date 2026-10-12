import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/local_discovery/local_hermes_home_discovery.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/hermes_chat/widgets/platform_local_connection_panel.dart';
import 'package:wing/features/local_setup/providers/local_hermes_setup_provider.dart';
import 'package:wing/features/local_setup/screens/local_hermes_setup_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';
import '../hermes_chat/support/fake_hermes_endpoint_store.dart';
import '../hermes_chat/widgets/platform_local_connection_panel_test.dart'
    show SyntheticHome;

void main() {
  for (final width in [390.0, 1280.0]) {
    testWidgets(
      'Linux setup is direct and metadata-only at $width',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final channel = FakeHermesChannel.disconnected();
        const saved = HermesEndpointConfig(
          id: 'keep',
          baseUrl: 'https://saved.example.invalid',
          apiKey: 'synthetic-saved-only',
          wingLinkOrigin: 'https://legacy.example.invalid',
          wingLinkToken: 'synthetic-management-only',
        );
        final store = FakeHermesEndpointStore(initial: saved);
        final home = SyntheticHome();
        addTearDown(channel.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              localWingLinkHostProvider.overrideWith(
                (_) => throw StateError('Link construction forbidden'),
              ),
              platformLocalHomeDiscoveryProvider.overrideWithValue(
                LocalHermesHomeDiscovery(platform: home),
              ),
              platformLocalDirectoryPickerProvider.overrideWithValue(
                () async => '/synthetic/alternate',
              ),
              hermesChannelProvider.overrideWithValue(channel),
              hermesEndpointStoreProvider.overrideWithValue(store),
              hermesVoiceCaptureServiceProvider.overrideWithValue(null),
              hermesTextToSpeechServiceProvider.overrideWithValue(null),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: const LocalHermesSetupScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final semantics = tester.ensureSemantics();
        expect(home.calls, ['/synthetic/.hermes']);
        expect(find.textContaining('Wing Link'), findsNothing);
        expect(
          find.byKey(const ValueKey('local-hermes-setup-action')),
          findsNothing,
        );
        final chooser = find.byKey(
          const ValueKey('platform-local-choose-home'),
        );
        await tester.ensureVisible(chooser);
        for (
          var tab = 0;
          tab < 40 &&
              tester.getSemantics(chooser).flagsCollection.isFocused !=
                  Tristate.isTrue;
          tab++
        ) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
        }
        expect(
          tester.getSemantics(chooser).flagsCollection.isFocused,
          Tristate.isTrue,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(home.calls, ['/synthetic/.hermes', '/synthetic/alternate']);
        expect(find.text('/synthetic/alternate'), findsOneWidget);
        expect(
          tester
              .widget<TextField>(
                find.byKey(const ValueKey('hermes-api-key-field')),
              )
              .obscureText,
          isTrue,
        );
        expect(channel.connectCalls, isEmpty);
        expect(store.saveCalls, isEmpty);
        expect(store.saveAllCalls, isEmpty);
        expect(store.deleteProfileCalls, isEmpty);
        expect(store.clearCalls, 0);
        expect(await store.loadProfiles(), [same(saved)]);
        // Hydration must keep the Agent key with its exact saved endpoint,
        // never copy a management credential or retarget it to loopback.
        expect(
          tester
              .widget<TextField>(
                find.byKey(const ValueKey('hermes-api-key-field')),
              )
              .controller!
              .text,
          saved.apiKey,
        );
        final endpoint = find.byKey(
          const ValueKey('platform-local-advanced-endpoint'),
        );
        await tester.ensureVisible(endpoint);
        await tester.tap(endpoint);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(
                find.byKey(const ValueKey('hermes-base-url-field')),
              )
              .controller!
              .text,
          saved.baseUrl,
        );
        expect(
          find.byKey(const ValueKey('hermes-enrollment-paste-link')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
      variant: TargetPlatformVariant.only(TargetPlatform.linux),
    );
  }
}
