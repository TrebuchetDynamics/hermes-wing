import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/app/wing_app.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/local_discovery/local_hermes_home_discovery.dart';
import 'package:wing/features/hermes_chat/widgets/platform_local_connection_panel.dart';
import 'package:wing/core/wing_link/local_wing_link_host.dart';
import 'package:wing/features/enrollment/providers/hermes_enrollment_provider.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/local_setup/providers/local_hermes_setup_provider.dart';
import 'package:wing/router/providers/app_router.dart';

import '../../test/features/hermes_chat/support/fake_hermes_endpoint_store.dart';
import '../../test/features/hermes_chat/support/fake_hermes_gateway_directory.dart';
import 'direct_first_run_native_fixture.dart';

class LocalSetupEnrollmentFixture {
  bool installed = false;
  int inspections = 0;
  int setups = 0;
  int cancellations = 0;
  int management = 0;
  final operations = <_PendingSetup>[];
  final inspectArguments = <List<String>>[];
  late final host = LocalWingLinkHost(
    executablePath: '/synthetic/wing',
    runner: (_, arguments) async {
      inspections++;
      inspectArguments.add(List.of(arguments));
      return LocalWingLinkProcessResult(
        exitCode: 0,
        stdout: jsonEncode({
          'protocol_version': 2,
          'platform': 'linux',
          'hermes_installed': installed,
          'hermes_healthy': installed,
          'setup_available': true,
        }),
      );
    },
    setupStarter: (_, _) async {
      setups++;
      final operation = _PendingSetup(() => cancellations++);
      operations.add(operation);
      return operation;
    },
  );

  void finish(bool success) {
    operations.last.completer.complete(
      LocalWingLinkProcessResult(
        exitCode: success ? 0 : 1,
        stdout: success
            ? '{"protocol_version":2,"result":{"hermes_installed":true,"hermes_adopted":true,"gateway_started":true}}'
            : 'synthetic-private-output-must-not-render',
      ),
    );
  }
}

class _PendingSetup implements LocalWingLinkSetupOperation {
  _PendingSetup(this.onCancel);
  final void Function() onCancel;
  final completer = Completer<LocalWingLinkProcessResult>();
  @override
  Future<LocalWingLinkProcessResult> get result => completer.future;
  @override
  Future<void> cancel() async => onCancel();
}

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
  final fixture = LocalSetupEnrollmentFixture();
  final data = DirectFirstRunNativeFixture();
  final store = FakeHermesEndpointStore();
  final channel = HermesApiChannel(clientBuilder: data.client);

  final container = ProviderContainer(
    overrides: [
      localWingLinkHostProvider.overrideWithValue(fixture.host),
      platformLocalHomeDiscoveryProvider.overrideWithValue(
        _FixtureHomeDiscovery(),
      ),
      hermesChannelProvider.overrideWith((_) => channel),
      hermesEndpointStoreProvider.overrideWithValue(store),
      gatewayContactCacheProvider.overrideWithValue(FakeGatewayContactCache()),
      hermesGatewaySummaryLoaderProvider.overrideWithValue(
        HermesApiGatewaySummaryLoader(clientBuilder: data.client),
      ),
      hermesEnrollmentControllerProvider.overrideWith(
        (_) => HermesEnrollmentController(
          endpointStore: store,
          inspectEnrollment: ({required origin, required code}) async {
            fixture.management++;
            throw StateError('Management forbidden');
          },
          exchangeEnrollment: ({required origin, required code}) async {
            fixture.management++;
            throw StateError('Management forbidden');
          },
        ),
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
    expect(appContainer.read(localWingLinkHostProvider), same(fixture.host));
    expect(
      fixture.inspections,
      greaterThan(0),
      reason: 'Typed inspect fixture was not invoked',
    );
  }

  Future<void> start() async {
    await activate('local-hermes-setup-action');
    expect(localControl('local-hermes-setup-consent'), findsOneWidget);
    await activate('local-hermes-setup-confirm', settle: false);
  }

  // Both missing-install and existing-adopt choices require consent. Escape
  // and explicit Cancel never reach the typed setup starter.
  for (final existing in [false, true]) {
    fixture.installed = existing;
    await open();
    expect(fixture.setups, 0);
    await activate('local-hermes-setup-action');
    await capture(existing ? 'adopt-consent' : 'install-consent');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(fixture.setups, 0);
    await activate('local-hermes-setup-action');
    await localActivate(tester, find.widgetWithText(TextButton, 'Cancel'));
    expect(fixture.setups, 0);
    await localActivate(tester, find.byType(BackButton));
    expect(localControl('hermes-welcome'), findsOneWidget);
  }
  // Completion is verified with a new read, and cannot navigate automatically.
  await open();
  final reads = fixture.inspections;
  await start();
  expect(fixture.setups, 1);
  fixture.finish(true);
  await tester.pumpAndSettle();
  expect(fixture.inspections, reads + 1);
  expect(localControl('local-hermes-setup-continue'), findsOneWidget);
  expect(localControl('hermes-enrollment-paste-link'), findsNothing);
  await capture('complete');
  await activate('local-hermes-setup-continue');
  expect(localControl('hermes-enrollment-paste-link'), findsOneWidget);
  expect(fixture.management, 0);
  await localActivate(tester, find.byType(BackButton));

  // Stop fences either late outcome. Check again performs one read, no setup.
  for (final success in [true, false]) {
    await open();
    await start();
    await localActivate(
      tester,
      find.widgetWithText(OutlinedButton, 'Stop setup'),
      settle: false,
    );
    fixture.finish(success);
    await tester.pumpAndSettle();
    expect(localControl('local-hermes-setup-continue'), findsNothing);
    final before = fixture.inspections;
    final setups = fixture.setups;
    await localActivate(
      tester,
      find.widgetWithText(OutlinedButton, 'Check again'),
    );
    expect(fixture.inspections, before + 1);
    expect(fixture.setups, setups);
    await localActivate(tester, find.byType(BackButton));
  }
  await open();
  await start();
  fixture.finish(false);
  await tester.pumpAndSettle();
  expect(localControl('local-hermes-setup-failure'), findsOneWidget);
  expect(find.textContaining('synthetic-private-output'), findsNothing);
  final failedReads = fixture.inspections;
  await capture('failure');
  await activate('local-hermes-setup-retry');
  expect(fixture.inspections, failedReads + 1);
  expect(fixture.setups, 4);
  await localActivate(tester, find.byType(BackButton));

  // Dispose while running, then select direct connection using public controls.
  // A late operation result cannot open pairing or replace the direct form.
  for (final success in [true, false]) {
    await open();
    await start();
    await localActivate(tester, find.byType(BackButton));
    await activate('hermes-enrollment-direct-connect');
    fixture.finish(success);
    await tester.pumpAndSettle();
    expect(localControl('platform-local-home-status'), findsOneWidget);
    expect(localControl('hermes-base-url-field'), findsNothing);
    await activate('platform-local-advanced-endpoint');
    expect(localControl('hermes-base-url-field'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(localControl('hermes-api-key-field'))
          .obscureText,
      isTrue,
    );
    expect(localControl('hermes-enrollment-paste-link'), findsNothing);
    expect(localControl('local-hermes-setup-continue'), findsNothing);
    if (!success) {
      await activate('hermes-connection-mode-remote');
      await tester.enterText(
        localControl('hermes-base-url-field'),
        DirectFirstRunNativeFixture.origin,
      );
      await activate('hermes-connect-button');
    } else {
      await localActivate(tester, find.byType(BackButton));
    }
  }
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
  expect(fixture.setups, 6);
  expect(
    fixture.inspectArguments.every(
      (args) => args.join(' ') == 'inspect --json',
    ),
    true,
  );
  expect(fixture.cancellations, 4);
  expect(fixture.management, 0);
  expect(data.mutationAttempts, 0);
  expect(data.forbiddenReadAttempts, 0);
  await capture('direct');
  expect(tester.takeException(), isNull);
  final result = <String, Object?>{
    'inspect': fixture.inspections,
    'setup': fixture.setups,
    'cancel': fixture.cancellations,
    'management': fixture.management,
    'mutations': data.mutationAttempts,
    'forbidden_reads': data.forbiddenReadAttempts,
    'route': router.routeInformationProvider.value.uri.path,
    'consent': true,
    'explicit_continue': true,
    'late_results_fenced': true,
    'inspection_only_retry': true,
    'direct_without_management': true,
  };
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  return result;
}

class _FixtureHomeDiscovery extends LocalHermesHomeDiscovery {
  @override
  Future<LocalHermesHomeInspection> inspectDefault() async =>
      const LocalHermesHomeInspection.directory('/synthetic/.hermes');
}
