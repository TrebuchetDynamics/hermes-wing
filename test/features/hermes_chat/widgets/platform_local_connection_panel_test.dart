import 'package:wing/core/hermes/channel/hermes_channel.dart';
import '../support/fake_hermes_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_add_screen.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/core/hermes/local_discovery/local_hermes_home_discovery.dart';
import 'package:wing/features/hermes_chat/widgets/platform_local_connection_panel.dart';
import 'package:wing/l10n/app_localizations.dart';
import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_hermes_gateway_directory.dart';

Finder key(String value) => find.byKey(ValueKey(value));

class SyntheticHome implements LocalHermesHomePlatform {
  SyntheticHome({this.inspect});
  final Future<LocalHermesHomeInspection> Function(String)? inspect;
  @override
  bool get isSupported => true;
  @override
  String get userHome => '/synthetic';
  final calls = <String>[];
  @override
  Future<LocalHermesHomeInspection> inspectDirectory(String path) async {
    calls.add(path);
    return inspect == null
        ? LocalHermesHomeInspection.directory(path)
        : await inspect!(path);
  }
}

Future<(HermesChannel, FakeHermesEndpointStore, SyntheticHome)> pumpEntry(
  WidgetTester tester,
  TargetPlatform platform, {
  SyntheticHome? home,
  Future<String?> Function()? picker,
  Future<bool> Function(Uri)? launcher,
  HermesChannel? channelOverride,
  double textScale = 1,
  FakeHermesEndpointStore? storeOverride,
  HermesConnectionMode initialMode = HermesConnectionMode.remote,
}) async {
  SharedPreferences.setMockInitialValues({});
  debugDefaultTargetPlatformOverride = platform;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
  final store = storeOverride ?? FakeHermesEndpointStore();
  final channel =
      channelOverride ??
      FakeHermesChannel(status: HermesConnectionStatus.disconnected);
  home ??= SyntheticHome();
  final directory = HermesGatewayDirectory(
    store: store,
    cache: FakeGatewayContactCache(),
    loader: FakeGatewaySummaryLoader({}),
    activeChannel: channel,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        platformLocalHomeDiscoveryProvider.overrideWithValue(
          LocalHermesHomeDiscovery(platform: home),
        ),
        platformLocalDirectoryPickerProvider.overrideWithValue(
          picker ?? () async => null,
        ),
        platformLocalDocumentationLauncherProvider.overrideWithValue(
          launcher ?? (_) async => true,
        ),
        hermesChannelProvider.overrideWith((_) => channel),
        hermesEndpointStoreProvider.overrideWithValue(store),
        hermesGatewayDirectoryProvider.overrideWith((_) => directory),
        hermesVoiceCaptureServiceProvider.overrideWithValue(null),
        hermesTextToSpeechServiceProvider.overrideWithValue(null),
      ],
      child: RepaintBoundary(
        key: const ValueKey("platform-local-render"),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: HermesAddScreen(mode: initialMode),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (initialMode != HermesConnectionMode.local) {
    await tester.ensureVisible(key('hermes-connection-mode-local'));
    await tester.tap(key('hermes-connection-mode-local'));
  }
  await tester.pumpAndSettle();
  return (channel, store, home);
}

void main() {
  testWidgets('production Android Local enters This phone guide, not QR', (
    tester,
  ) async {
    await pumpEntry(tester, TargetPlatform.android);
    expect(find.text('This phone'), findsOneWidget);
    expect(key('platform-local-termux-docs'), findsOneWidget);
    expect(key('hermes-open-qr-scanner'), findsNothing);
    expect(key('hermes-api-key-field'), findsNothing);
    expect(key('hermes-optional-setup'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
  testWidgets(
    'production Linux Local discovers default home and offers native folder choice',
    (tester) async {
      await pumpEntry(tester, TargetPlatform.linux);
      expect(find.text('Hermes home'), findsOneWidget);
      expect(key('platform-local-home-status'), findsOneWidget);
      expect(key('platform-local-choose-home'), findsOneWidget);
      expect(key('hermes-open-local-setup'), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
