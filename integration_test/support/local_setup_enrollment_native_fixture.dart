import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/app/wing_app.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/local_discovery/local_hermes_home_discovery.dart';
import 'package:wing/features/hermes_chat/widgets/platform_local_connection_panel.dart';

import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/local_setup/providers/local_hermes_setup_provider.dart';
import 'package:wing/router/providers/app_router.dart';

import '../../test/features/hermes_chat/support/fake_hermes_endpoint_store.dart';
import '../../test/features/hermes_chat/support/fake_hermes_gateway_directory.dart';
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
  var linkConstructions = 0;
  final home = _FixtureHomeDiscovery();
  final data = DirectFirstRunNativeFixture();
  final store = FakeHermesEndpointStore();
  final channel = HermesApiChannel(clientBuilder: data.client);

  final container = ProviderContainer(
    overrides: [
      localWingLinkHostProvider.overrideWith((_) {
        linkConstructions++;
        throw StateError('Link construction forbidden');
      }),
      platformLocalHomeDiscoveryProvider.overrideWithValue(home),
      hermesChannelProvider.overrideWith((_) => channel),
      hermesEndpointStoreProvider.overrideWithValue(store),
      gatewayContactCacheProvider.overrideWithValue(FakeGatewayContactCache()),
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
  Future<void> open() async {
    expect(localControl('hermes-welcome'), findsOneWidget);
    if (localControl('hermes-enrollment-local-setup').evaluate().isEmpty) {
      await activate('hermes-welcome-optional');
    }
    await activate('hermes-enrollment-local-setup');
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

  // AppBar Back and platform cancellation preserve the chooser and saved data.
  await open();
  await capture('direct-local');
  await localActivate(tester, find.byType(BackButton));
  expect(localControl('hermes-welcome'), findsOneWidget);
  expect(store.saveCalls, isEmpty);
  await open();
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
  expect(localControl('hermes-welcome'), findsOneWidget);
  expect(store.saveCalls, isEmpty);

  // Authentication/capability denial stays direct; a later explicit retry is
  // another read attempt, never installation, pairing or mutation replay.
  await open();
  await activate('platform-local-advanced-endpoint');
  await tester.enterText(
    localControl('hermes-base-url-field'),
    DirectFirstRunNativeFixture.origin,
  );
  data.deniedBootstrapStatus = 401;
  await activate('hermes-connect-button');
  expect(store.saveCalls, isEmpty);
  expect(data.deniedReads, isNotEmpty);
  expect(find.textContaining('private-response'), findsNothing);
  expect(localControl('hermes-enrollment-paste-link'), findsNothing);
  final deniedRequests = data.requests.length;
  await tester.pump(const Duration(seconds: 2));
  expect(data.requests.length, deniedRequests);
  expect(linkConstructions, 0);
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
    reason:
        'status=${channel.state.status} saves=${store.saveCalls.length} reads=${data.requests}',
  );
  expect(store.saveCalls.single.wingLinkToken, isNull);
  expect(store.saveCalls.single.wingLinkOrigin, isNull);
  expect(router.routeInformationProvider.value.uri.path, '/hermes');
  expect(linkConstructions, 0);
  expect(home.inspections, 3);
  expect(data.mutationAttempts, 0);
  expect(data.forbiddenReadAttempts, 0);
  await capture('direct');
  expect(tester.takeException(), isNull);
  final result = <String, Object?>{
    'inspect': home.inspections,
    'link_constructions': linkConstructions,
    'management': linkConstructions,
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

class _FixtureHomeDiscovery extends LocalHermesHomeDiscovery {
  int inspections = 0;
  @override
  Future<LocalHermesHomeInspection> inspectDefault() async {
    inspections++;
    return const LocalHermesHomeInspection.directory('/synthetic/.hermes');
  }
}
