import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/app/wing_app.dart';
import 'package:wing/features/enrollment/providers/hermes_enrollment_provider.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/router/providers/app_router.dart';

import 'remote_connection_retry_native_fixture.dart';

/// In-memory placeholder only; never a host credential or socket.
class RemoteAuthExplanationFixture extends RemoteConnectionRetryNativeFixture {
  static const placeholder = 'synthetic-not-a-credential';
  int tokenReads = 0;

  @override
  Future<String> get(Uri uri, Map<String, String> headers) async {
    expect(headers['Authorization'], 'Bearer $placeholder');
    tokenReads++;
    final result = await super.get(uri, {
      for (final entry in headers.entries)
        if (entry.key != 'Authorization') entry.key: entry.value,
    });
    if (uri.path != '/v1/capabilities') return result;
    final catalog = jsonDecode(result) as Map<String, dynamic>;
    (catalog['auth'] as Map<String, dynamic>)['required'] = true;
    return jsonEncode(catalog);
  }
}

Future<Map<String, Object?>> runRemoteAuthExplanationJourney(
  WidgetTester tester, {
  required Future<void> Function(String) capture,
}) async {
  Finder control(String name) => find.byKey(ValueKey(name));
  final fixture = RemoteAuthExplanationFixture();
  final store = RetryNativeStore();
  final channel = RetryNativeChannel(fixture);
  final directory = HermesGatewayDirectory(
    store: store,
    cache: GatewayContactCache(),
    loader: HermesApiGatewaySummaryLoader(clientBuilder: fixture.client),
    activeChannel: channel,
  );
  var managementAttempts = 0;
  final enrollment = HermesEnrollmentController(
    endpointStore: store,
    inspectEnrollment: ({required origin, required code}) async {
      managementAttempts++;
      throw StateError('Management forbidden');
    },
    exchangeEnrollment: ({required origin, required code}) async {
      managementAttempts++;
      throw StateError('Management forbidden');
    },
  );
  final container = ProviderContainer(
    overrides: [
      hermesChannelProvider.overrideWith((_) => channel),
      hermesEndpointStoreProvider.overrideWithValue(store),
      hermesGatewayDirectoryProvider.overrideWith((_) => directory),
      hermesEnrollmentControllerProvider.overrideWith((_) => enrollment),
      hermesVoiceCaptureServiceProvider.overrideWithValue(null),
      hermesTextToSpeechServiceProvider.overrideWithValue(null),
    ],
  );
  addTearDown(container.dispose);
  final router = container.read(routerProvider);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const WingApp()),
  );
  await tester.pumpAndSettle();
  Future<void> reachFinder(Finder target) async {
    await tester.ensureVisible(target);
    for (var i = 0; i < 120; i++) {
      var focused = false;
      final context = FocusManager.instance.primaryFocus?.context;
      if (context != null &&
          context.mounted &&
          identical(context.widget, tester.widget(target))) {
        focused = true;
      }
      context?.visitAncestorElements((element) {
        if (identical(element.widget, tester.widget(target))) focused = true;
        return !focused;
      });
      if (focused) {
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        return;
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }
    fail('Keyboard did not reach $target');
  }

  Future<void> reach(String name) => reachFinder(control(name));
  Future<void> cancel() async {
    await reachFinder(find.byType(BackButton));
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
  }

  Future<void> activate(String name) async {
    await reach(name);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
  }

  Future<void> edit(String name, String value) async {
    await reach(name);
    await tester.enterText(control(name), value);
    await tester.pumpAndSettle();
  }

  String draft(String key) =>
      tester.widget<TextField>(control(key)).controller!.text;
  void explanation() {
    expect(control('hermes-remote-auth-explanation'), findsOneWidget);
    final text = tester
        .widget<SelectableText>(control('hermes-remote-auth-explanation'))
        .data!;
    expect(text, contains('Browser OAuth sign-in is not supported'));
    expect(text, contains('OAuth-only server cannot currently connect'));
    expect(text, contains('retry explicitly or cancel'));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            (widget is Text &&
                widget.data?.contains(
                      RemoteAuthExplanationFixture.placeholder,
                    ) ==
                    true) ||
            (widget is SelectableText &&
                widget.data?.contains(
                      RemoteAuthExplanationFixture.placeholder,
                    ) ==
                    true),
      ),
      findsNothing,
    );
    expect(find.textContaining('private-response'), findsNothing);
  }

  expect(fixture.requests, isEmpty);
  // Fresh production welcome -> Remote Add, not an internal form-only mount.
  await activate('hermes-welcome-remote');
  explanation();
  await reach('hermes-remote-auth-focus');
  await capture('before');
  await activate('hermes-remote-transport-vpn');
  explanation();
  await activate('hermes-remote-transport-remote');
  await edit('hermes-base-url-field', 'https://example.invalid');
  await edit('hermes-api-key-field', RemoteAuthExplanationFixture.placeholder);
  await edit('hermes-profile-label-field', 'Synthetic auth host');
  expect(
    tester.widget<TextField>(control('hermes-api-key-field')).obscureText,
    isTrue,
  );
  fixture.deniedBootstrapStatus = 403;
  await activate('hermes-connect-button');
  expect(control('hermes-connect-error'), findsOneWidget);
  explanation();
  expect(channel.connects, 1);
  expect(store.attempts, 0);
  final beforeIdle = List.of(fixture.requests);
  await tester.pump(const Duration(seconds: 2));
  expect(fixture.requests, beforeIdle);
  expect(draft('hermes-profile-label-field'), 'Synthetic auth host');
  expect(draft('hermes-base-url-field'), 'https://example.invalid');
  expect(
    draft('hermes-api-key-field'),
    RemoteAuthExplanationFixture.placeholder,
  );
  await reach('hermes-remote-auth-focus');
  await capture('denied');
  await cancel();
  expect(store.attempts, 0);
  expect(channel.connects, 1);
  await activate('hermes-welcome-remote');
  explanation();
  await edit('hermes-base-url-field', 'https://example.invalid');
  await edit('hermes-api-key-field', RemoteAuthExplanationFixture.placeholder);
  await edit('hermes-profile-label-field', 'Synthetic auth host');
  fixture.deniedBootstrapStatus = 401;
  await activate('hermes-connect-button');
  explanation();
  expect(channel.connects, 2);
  expect(store.attempts, 0);
  fixture.deniedBootstrapStatus = null;
  await activate('hermes-connect-button');
  expect(channel.connects, 3);
  expect(store.saveCalls, hasLength(1));
  expect(
    store.saveCalls.single.apiKey,
    RemoteAuthExplanationFixture.placeholder,
  );
  expect(store.saveCalls.single.wingLinkOrigin, isNull);
  expect(store.saveCalls.single.wingLinkToken, isNull);
  expect(fixture.mutationAttempts, 0);
  expect(fixture.forbiddenReadAttempts, 0);
  expect(managementAttempts, 0);
  final contact = directory.contacts.single;
  await activate(
    'gateway-contact-${contact.id.gatewayId}-${contact.id.profileId}',
  );
  expect(channel.state.isConnected, isTrue);
  expect(channel.connects, 4);
  await capture('connected');
  // Existing Chat's public Add flow shares the explanation and explicit Back.
  await activate('hermes-back-to-contacts');
  await activate('hermes-connect-another-gateway');
  await activate('hermes-connection-mode-remote');
  explanation();
  await reach('hermes-remote-auth-focus');
  await capture('editing');
  await cancel();
  expect(channel.connects, 4);
  expect(store.attempts, 1);
  expect(tester.takeException(), isNull);
  return {
    'public_entry': true,
    'denial_sanitized': true,
    'keyboard_explanation': true,
    'explicit_retry_cancel': true,
    'form_draft_retained': true,
    'connects': channel.connects,
    'saves': store.attempts,
    'token_reads': fixture.tokenReads,
    'management_attempts': managementAttempts,
    'mutation_attempts': fixture.mutationAttempts,
    'forbidden_read_attempts': fixture.forbiddenReadAttempts,
    'denied_reads': fixture.deniedReads,
    'requests': fixture.requests,
    'physical_keychain': 'NOT_CHECKED',
  };
}
