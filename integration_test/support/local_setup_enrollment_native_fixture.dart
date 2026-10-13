import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/app/wing_app.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/local_discovery/local_hermes_home_discovery.dart';
import 'package:wing/core/hermes/local_discovery/local_hermes_home_platform_io.dart';
import 'package:wing/core/hermes/setup/secure_hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';
import 'package:wing/features/hermes_chat/widgets/platform_local_connection_panel.dart';

import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';

import 'package:wing/router/providers/app_router.dart';

import 'direct_first_run_native_fixture.dart';

Finder localControl(String name) => find.byKey(ValueKey(name));

Future<void> localActivate(
  WidgetTester tester,
  Finder target, {
  bool settle = true,
}) async {
  for (var i = 0; i < 50 && target.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(
    target,
    findsOneWidget,
    reason:
        'Visible text: ${tester.widgetList<Text>(find.byType(Text)).map((text) => text.data).join(" | ")}',
  );
  await tester.ensureVisible(target);
  for (var i = 0; i < 120; i++) {
    bool focused = false;
    FocusManager.instance.primaryFocus?.context?.visitAncestorElements((
      element,
    ) {
      if (target.evaluate().any((candidate) => identical(candidate, element))) {
        focused = true;
      }
      return !focused;
    });
    if (focused) {
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      if (settle) {
        await tester.pumpAndSettle();
      } else {
        await tester.pump(const Duration(milliseconds: 200));
      }
      return;
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('Keyboard could not reach $target');
}

/// Production WingApp/router/enrollment; only external authorities are fixtures.
Future<Map<String, Object?>> runLocalEnrollmentJourney(
  WidgetTester tester, {
  required Future<void> Function(String) capture,
}) async {
  var sockets = 0;
  final receipt = await HttpOverrides.runZoned(
    () => _runLocalEnrollmentJourney(tester, capture: capture),
    createHttpClient: (_) {
      sockets++;
      throw StateError('Only injected Agent reads are permitted');
    },
  );
  expect(sockets, 0);
  return {...receipt, 'link_operations': sockets};
}

Future<Map<String, Object?>> _runLocalEnrollmentJourney(
  WidgetTester tester, {
  required Future<void> Function(String) capture,
}) async {
  final folders = (await tester.runAsync(
    () => Directory.systemTemp.createTemp('wing-local-metadata-'),
  ))!;
  addTearDown(() => folders.delete(recursive: true));
  final home = _ObservedHomeDiscovery(tester, folders.path);
  final data = DirectFirstRunNativeFixture()..deniedBootstrapStatus = 401;
  const gateway = 'saved-local-owner';
  const bundle = 'wing.hermes.endpoint_bundle.v1';
  const legacySlot = 'wing.hermes.profile_wing_link_token.$gateway';
  final rawRow = <String, Object?>{
    'id': gateway,
    'baseUrl': DirectFirstRunNativeFixture.origin,
    'wingLinkOrigin': 'https://control.example.invalid',
    'wingLinkToken': 'synthetic-inert-control',
    'wingLinkPendingCredentialId': 'synthetic-pending',
    'wingLinkHostFingerprint': 'synthetic-pin',
    'wingLinkDeviceId': 'synthetic-device',
  };
  final raw = jsonEncode([rawRow]);
  final metadataRow = {...rawRow}
    ..remove('wingLinkToken')
    ..remove('wingLinkHostFingerprint');
  final rawMetadata = jsonEncode([metadataRow]);
  final preferences = await SharedPreferences.getInstance();
  await preferences.setString('wing.hermes.profiles', rawMetadata);
  FlutterSecureStorage.setMockInitialValues({
    bundle: raw,
    legacySlot: 'synthetic-inert-slot',
  });
  final storage = _ObservedStorage();
  final store = SecureHermesEndpointStore(secureStorage: storage);
  final cache = GatewayContactCache();
  const selection = GatewayContactSelection(
    contactId: GatewayContactId(
      gatewayId: gateway,
      profileId: DirectFirstRunNativeFixture.profile,
    ),
    sessionId: DirectFirstRunNativeFixture.session,
  );
  await cache.saveSelection(selection);
  var pickerCalls = 0;
  final channel = HermesApiChannel(clientBuilder: data.client);

  final container = ProviderContainer(
    overrides: [
      platformLocalHomeDiscoveryProvider.overrideWithValue(home),
      platformLocalDirectoryPickerProvider.overrideWithValue(() async {
        pickerCalls++;
        return pickerCalls == 1 ? null : '${folders.path}/selected';
      }),
      hermesChannelProvider.overrideWith((_) => channel),
      hermesEndpointStoreProvider.overrideWithValue(store),
      gatewayContactCacheProvider.overrideWithValue(cache),
      hermesGatewaySummaryLoaderProvider.overrideWithValue(
        HermesApiGatewaySummaryLoader(clientBuilder: data.client),
      ),

      hermesVoiceCaptureServiceProvider.overrideWithValue(null),
      hermesTextToSpeechServiceProvider.overrideWithValue(null),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const WingApp()),
  );
  await tester.pumpAndSettle();
  final appContext = tester.element(find.byType(MaterialApp));
  final appContainer = ProviderScope.containerOf(appContext);
  final router = appContainer.read(routerProvider);
  Future<void> activate(String name, {bool settle = true}) =>
      localActivate(tester, localControl(name), settle: settle);
  Future<void> preserved({bool unchanged = true}) async {
    final saved = (await store.loadProfiles()).single;
    expect(saved.id, gateway);
    expect(saved.baseUrl, DirectFirstRunNativeFixture.origin);
    expect(saved.apiKey, isNull);
    final remembered = (await cache.loadSelection())!;
    expect(remembered.contactId, selection.contactId);
    expect(remembered.sessionId, selection.sessionId);
    expect(storage.legacyReads, 0);
    expect(storage.legacyDeletes, 0);
    expect(
      await const FlutterSecureStorage().read(key: legacySlot),
      'synthetic-inert-slot',
    );
    final current = await const FlutterSecureStorage().read(key: bundle);
    if (unchanged) {
      expect(current, raw);
      expect(preferences.getString('wing.hermes.profiles'), rawMetadata);
      expect(storage.writes, 0);
    } else {
      final row = (jsonDecode(current!) as List).single as Map;
      for (final key in rawRow.keys) {
        expect(row[key], rawRow[key], reason: key);
      }
      final metadata =
          (jsonDecode(preferences.getString('wing.hermes.profiles')!) as List)
                  .single
              as Map;
      for (final key in metadataRow.keys) {
        expect(metadata[key], metadataRow[key], reason: key);
      }
    }
  }

  Future<void> open() async {
    expect(localControl('hermes-welcome'), findsOneWidget);
    if (localControl('hermes-enrollment-local-setup').evaluate().isEmpty) {
      await activate('hermes-welcome-optional');
    }
    await activate('hermes-enrollment-local-setup');
    await home.pending;
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/setup/local');
    expect(localControl('platform-local-home-status'), findsOneWidget);
    expect(localControl('hermes-enrollment-paste-link'), findsNothing);
    expect(localControl('local-hermes-setup-action'), findsNothing);
    expect(
      tester
          .widget<TextField>(localControl('hermes-api-key-field'))
          .obscureText,
      isTrue,
    );
  }

  // Missing Agent access never consumes the inert management slot.
  await activate('hermes-connect-another-gateway');
  await activate('hermes-optional-setup');
  await preserved();
  await open();
  expect(home.lastStatus, LocalHermesHomeStatus.absent);
  expect(localControl('platform-local-home-path'), findsNothing);
  expect(channel.state.isConnected, isFalse);
  await activate('platform-local-choose-home');
  expect(home.selectedInspections, 0);
  expect(home.lastStatus, LocalHermesHomeStatus.absent);
  await preserved();
  await capture('direct-local');
  await localActivate(tester, find.byType(BackButton));
  expect(localControl('hermes-welcome'), findsOneWidget);
  await preserved();
  await tester.runAsync(() async {
    await Directory('${folders.path}/.hermes').create();
    await Directory('${folders.path}/selected').create();
  });
  await open();
  expect(home.lastStatus, LocalHermesHomeStatus.supported);
  expect(
    tester.widget<Text>(localControl('platform-local-home-path')).data,
    '${folders.path}/.hermes',
  );
  expect(channel.state.isConnected, isFalse);
  await capture('default-home');
  await activate('platform-local-choose-home');
  await home.pending;
  await tester.pumpAndSettle();
  expect(
    tester.widget<Text>(localControl('platform-local-home-path')).data,
    '${folders.path}/selected',
  );
  expect(channel.state.isConnected, isFalse);
  await preserved();
  await capture('selected-home');
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
  expect(localControl('hermes-welcome'), findsOneWidget);
  await preserved();

  // Authentication/capability denial stays direct; a later explicit retry is
  // another read attempt, never installation, pairing or mutation replay.
  await open();
  await activate('platform-local-advanced-endpoint');
  await tester.enterText(
    localControl('hermes-base-url-field'),
    DirectFirstRunNativeFixture.origin,
  );
  data.deniedBootstrapStatus = 401;
  final previousDenials = data.deniedReads.length;
  await activate('hermes-connect-button');
  await preserved();
  expect(data.deniedReads.length, greaterThan(previousDenials));
  expect(localControl('hermes-connect-error'), findsOneWidget);
  expect(
    tester
        .widget<Semantics>(localControl('hermes-connect-error'))
        .properties
        .liveRegion,
    true,
  );
  expect(find.textContaining('private-response'), findsNothing);
  expect(localControl('hermes-enrollment-paste-link'), findsNothing);
  final deniedRequests = data.requests.length;
  await tester.pump(const Duration(seconds: 2));
  expect(data.requests.length, deniedRequests);
  await capture('direct-denied');
  data.deniedBootstrapStatus = null;
  await activate('hermes-connect-button');
  await tester.pumpAndSettle();
  final contact = appContainer
      .read(hermesGatewayDirectoryProvider)
      .contacts
      .single;
  await activate(
    'gateway-contact-${contact.id.gatewayId}-${contact.id.profileId}',
  );
  for (var i = 0; i < 50 && !channel.state.isConnected; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
  expect(
    channel.state.isConnected,
    true,
    reason: 'status=${channel.state.status} reads=${data.requests}',
  );

  expect(router.routeInformationProvider.value.uri.path, '/hermes');
  expect(home.defaultInspections, 3);
  expect(home.selectedInspections, 1);
  expect(pickerCalls, 2);
  expect(channel.state.activeSessionId, selection.sessionId);
  expect(
    appContainer.read(hermesGatewayDirectoryProvider).activeContactId,
    selection.contactId,
  );
  await preserved(unchanged: false);
  expect(data.mutationAttempts, 0);
  expect(data.forbiddenReadAttempts, 0);
  await capture('direct');
  expect(tester.takeException(), isNull);
  final result = <String, Object?>{
    'inspect': home.defaultInspections + home.selectedInspections,
    'picker_calls': pickerCalls,
    'chooser_cancel_preserved': true,
    'metadata_missing_default_selected': true,
    'saved_owner_preserved': true,
    'inert_legacy_preserved': true,
    'legacy_reads': storage.legacyReads,
    'legacy_deletes': storage.legacyDeletes,

    'mutations': data.mutationAttempts,
    'forbidden_reads': data.forbiddenReadAttempts,
    'route': router.routeInformationProvider.value.uri.path,
    'direct_retry': true,
    'no_automatic_replay': true,
    'direct_without_management': true,
  };
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  return result;
}

class _ObservedHomeDiscovery extends LocalHermesHomeDiscovery {
  _ObservedHomeDiscovery(this.tester, String root)
    : delegate = LocalHermesHomeDiscovery(
        platform: IoLocalHermesHomePlatform(userHome: root),
      );

  final WidgetTester tester;
  final LocalHermesHomeDiscovery delegate;
  int defaultInspections = 0;
  int selectedInspections = 0;
  LocalHermesHomeStatus? lastStatus;
  Future<LocalHermesHomeInspection>? pending;

  @override
  Future<LocalHermesHomeInspection> inspectDefault() {
    defaultInspections++;
    return pending = _inspect(delegate.inspectDefault);
  }

  @override
  Future<LocalHermesHomeInspection> inspectSelected(String directory) {
    selectedInspections++;
    return pending = _inspect(() => delegate.inspectSelected(directory));
  }

  Future<LocalHermesHomeInspection> _inspect(
    Future<LocalHermesHomeInspection> Function() inspect,
  ) async {
    final result = (await tester.runAsync(inspect))!;
    lastStatus = result.status;
    return result;
  }
}

class _ObservedStorage extends FlutterSecureStorage {
  int legacyReads = 0;
  int legacyDeletes = 0;
  int writes = 0;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    if (key.contains('wing_link_token')) {
      legacyReads++;
      throw StateError('Inert management slot must not be read');
    }
    return super.read(key: key);
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    if (key.contains('wing_link_token')) {
      legacyDeletes++;
      throw StateError('Retained management slot must not be deleted');
    }
    return super.delete(key: key);
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    writes++;
    return super.write(key: key, value: value);
  }
}
