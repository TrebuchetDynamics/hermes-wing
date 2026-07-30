import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_hermes_gateway_directory.dart';

void main() {
  testWidgets('Android uses the configured network Hermes endpoint', (
    tester,
  ) async {
    const configuredBaseUrl = String.fromEnvironment('WING_HERMES_BASE_URL');
    await tester.binding.setSurfaceSize(const Size(390, 844));
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      debugDefaultTargetPlatformOverride = null;
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(
            FakeHermesChannel.disconnected(),
          ),
          hermesEndpointStoreProvider.overrideWithValue(
            FakeHermesEndpointStore(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('hermes-base-url-field')),
          )
          .controller
          ?.text,
      configuredBaseUrl,
    );
    expect(find.text('Connect to your Hermes VPS'), findsOneWidget);
    expect(find.text('Android emulator'), findsNothing);

    final developerShortcuts = find.byKey(
      const ValueKey('hermes-developer-shortcuts'),
    );
    await tester.ensureVisible(developerShortcuts);
    await tester.tap(developerShortcuts);
    await tester.pumpAndSettle();

    expect(find.text('This device'), findsNothing);
    expect(find.text('Android emulator'), findsOneWidget);
    expect(find.text('Clear server details'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('deleting a first-connect endpoint reloads the directory', (
    tester,
  ) async {
    final channel = FakeHermesChannel.disconnected();
    final store = FakeHermesEndpointStore(
      initial: const HermesEndpointConfig(
        id: 'saved',
        label: 'Saved gateway',
        baseUrl: 'https://saved.example',
      ),
    );
    final directory = _ReloadRecordingDirectory(store, channel);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(store),
          hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chip = find.byKey(const ValueKey('hermes-endpoint-profile-saved'));
    expect(chip, findsOneWidget);
    await tester.tap(
      find.descendant(of: chip, matching: find.byIcon(Icons.close)),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('hermes-endpoint-profile-delete-confirm')),
    );
    await tester.pumpAndSettle();

    expect(store.deleteProfileCalls, ['saved']);
    expect(directory.reloadCalls, 1);
    expect(chip, findsNothing);
  });
}

class _ReloadRecordingDirectory extends HermesGatewayDirectory {
  _ReloadRecordingDirectory(
    FakeHermesEndpointStore store,
    FakeHermesChannel channel,
  ) : super(
        store: store,
        cache: FakeGatewayContactCache(),
        loader: FakeGatewaySummaryLoader(const {}),
        activeChannel: channel,
      );

  int reloadCalls = 0;

  @override
  Future<void> reload({GatewayContactId? activate}) async {
    reloadCalls++;
    await super.reload(activate: activate);
  }
}
