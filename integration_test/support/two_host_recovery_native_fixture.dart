import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/core/hermes/shared/hermes_api_http.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../../test/features/hermes_chat/support/fake_hermes_endpoint_store.dart';
import 'direct_first_run_native_fixture.dart';
import 'remote_connection_retry_native_fixture.dart';

/// Only the HTTP seam is synthetic. Directory, channel and widgets are production.
class TwoHostRecoveryNativeFixture extends RemoteConnectionRetryNativeFixture {
  static const a = DirectFirstRunNativeFixture.origin;
  static const b = 'https://other.example.invalid';
  final ownedRequests = <Map<String, Object?>>[];
  Completer<String>? pendingA;
  bool denyB = false;
  bool dropEarlierB = false;

  String ownerHistory(String owner) {
    final value =
        jsonDecode(history(DirectFirstRunNativeFixture.session))
            as Map<String, dynamic>;
    (value['data'] as List).single['content'] = 'Canonical $owner history';
    (value['pagination'] as Map)['limit'] = 1;
    return jsonEncode(value);
  }

  @override
  Future<String> get(Uri uri, Map<String, String> headers) async {
    final owner = uri.origin == a
        ? 'A'
        : uri.origin == b
        ? 'B'
        : null;
    if (owner == null || headers.containsKey('Authorization')) {
      forbiddenReadAttempts++;
      throw StateError('Only synthetic owner reads permitted');
    }
    ownedRequests.add({
      'owner': owner,
      'method': 'GET',
      'path': uri.path,
      'query': uri.queryParameters,
    });
    if (uri.path == '/v1/capabilities' && owner == 'B' && denyB) {
      throw const DirectFirstRunReadDenial(403);
    }
    if (uri.path.endsWith('/messages')) {
      if (!{
        'default',
        DirectFirstRunNativeFixture.profile,
      }.contains(uri.queryParameters['profile'])) {
        forbiddenReadAttempts++;
        throw StateError('Explicit shared profile required');
      }
      if (owner == 'A' && pendingA != null) {
        final gate = pendingA!;
        pendingA = null;
        return gate.future;
      }
      if (owner == 'B' &&
          dropEarlierB &&
          uri.queryParameters['offset'] == '1') {
        throw const HermesApiTransportException(
          HermesApiTransportFailureKind.network,
        );
      }
      return ownerHistory(owner);
    }
    final response = await super.get(uri, headers);
    if (uri.path != '/v1/capabilities') return response;
    final value = jsonDecode(response) as Map<String, dynamic>;

    // Drafts can be edited; any accidental send is counted and rejected.
    (value['features'] as Map)['session_chat_streaming'] = true;
    (value['endpoints'] as Map)['session_chat_stream'] = {
      'method': 'POST',
      'path': '/api/sessions/{session_id}/chat/stream',
      'profile_scoped': true,
      'required_scopes': ['sessions:read'],
    };
    return jsonEncode(value);
  }
}

Future<Map<String, Object?>> exerciseTwoHostRecovery(
  WidgetTester tester, {
  required double scale,
  required Future<void> Function(String state) capture,
}) async {
  final fixture = TwoHostRecoveryNativeFixture();
  final store = FakeHermesEndpointStore(
    profiles: const [
      HermesEndpointConfig(
        id: 'host-a',
        label: 'Synthetic A',
        baseUrl: TwoHostRecoveryNativeFixture.a,
      ),
      HermesEndpointConfig(
        id: 'host-b',
        label: 'Synthetic B',
        baseUrl: TwoHostRecoveryNativeFixture.b,
      ),
    ],
  );
  final cache = GatewayContactCache();
  final channel = RetryNativeChannel(fixture);
  final directory = HermesGatewayDirectory(
    store: store,
    cache: cache,
    loader: HermesApiGatewaySummaryLoader(clientBuilder: fixture.client),
    activeChannel: channel,
  );
  final container = ProviderContainer(
    overrides: [
      hermesChannelProvider.overrideWith((_) => channel),
      hermesEndpointStoreProvider.overrideWithValue(store),
      hermesGatewayDirectoryProvider.overrideWith((_) => directory),
      hermesVoiceCaptureServiceProvider.overrideWithValue(null),
      hermesTextToSpeechServiceProvider.overrideWithValue(null),
    ],
  );
  addTearDown(container.dispose);
  // The production provider starts this notifier; its override must do so too.
  await directory.start();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const HermesChatScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  Finder control(String name) => find.byKey(ValueKey(name));
  Future<void> keyboard(String name, {bool pending = false}) async {
    await tester.ensureVisible(control(name));
    for (var i = 0; i < 120; i++) {
      var focused = false;
      final context = FocusManager.instance.primaryFocus?.context;
      if (context?.widget.key == ValueKey(name)) focused = true;
      context?.visitAncestorElements((element) {
        if (element.widget.key == ValueKey(name)) focused = true;
        return !focused;
      });
      if (focused) {
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        if (pending) {
          await tester.pump(const Duration(milliseconds: 300));
        } else {
          await tester.pumpAndSettle();
        }
        return;
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump(const Duration(milliseconds: 50));
    }
    fail('Keyboard did not reach $name');
  }

  Future<void> select(String owner, {bool pending = false}) => keyboard(
    'gateway-contact-host-${owner.toLowerCase()}-${DirectFirstRunNativeFixture.profile}',
    pending: pending,
  );
  Future<void> back({bool pending = false}) =>
      keyboard('hermes-back-to-contacts', pending: pending);
  String draft() => tester
      .widget<TextField>(control('hermes-composer-field'))
      .controller!
      .text;
  Future<void> owner(String expected) async {
    expect(
      directory.activeContactId?.gatewayId,
      'host-${expected.toLowerCase()}',
    );
    expect(
      channel.state.connectedBaseUrl,
      expected == 'A'
          ? TwoHostRecoveryNativeFixture.a
          : TwoHostRecoveryNativeFixture.b,
    );
    expect(
      channel.state.selectedProfileId,
      DirectFirstRunNativeFixture.profile,
    );
    expect(channel.state.activeSessionId, DirectFirstRunNativeFixture.session);
    expect(channel.state.isConnected, true);
    expect(find.text('Canonical $expected history'), findsOneWidget);
    expect(
      find.text('Canonical ${expected == 'A' ? 'B' : 'A'} history'),
      findsNothing,
    );
    expect((await cache.loadSelection())?.contactId, directory.activeContactId);
    expect(
      (await cache.loadSelection())?.sessionId,
      DirectFirstRunNativeFixture.session,
    );
  }

  expect(directory.contacts, hasLength(2));
  final saved = await store.loadProfiles();
  expect(channel.state.isConnected, false);
  await select('A');
  await owner('A');
  await back();
  await select('B');
  await owner('B');
  await tester.enterText(
    control('hermes-composer-field'),
    'B replacement draft',
  );
  await capture('selected-b');
  await back();
  await select('A');
  await owner('A');
  expect(draft(), isEmpty);
  await back();
  await select('B');
  await owner('B');
  expect(draft(), 'B replacement draft');

  final lateCases = <Map<String, Object>>[];
  for (final reject in [false, true]) {
    await back();
    final gate = Completer<String>();
    fixture.pendingA = gate;
    final start = fixture.ownedRequests.length;
    await select('A', pending: true);
    expect(directory.isActivating, true);
    expect(fixture.pendingA, isNull);
    // Public All chats cancels the outstanding activation, then selects B.
    await back();
    await select('B');
    await owner('B');
    expect(draft(), 'B replacement draft');
    final before = List.of(fixture.ownedRequests);
    if (reject) {
      gate.completeError(const DirectFirstRunReadDenial(401));
    } else {
      gate.complete(fixture.ownerHistory('A'));
    }
    await tester.pumpAndSettle();
    await owner('B');
    expect(draft(), 'B replacement draft');
    expect(fixture.ownedRequests, before);
    expect(
      fixture.ownedRequests
          .skip(start)
          .where((r) => r['owner'] == 'A')
          .last['path'],
      '/api/sessions/synthetic-history/messages',
    );
    lateCases.add({
      'reject': reject,
      'cancelled': true,
      'replacement_preserved': true,
    });
  }

  // A late success cannot win even when intent returns to the same A strings.
  await back();
  final returning = Completer<String>();
  fixture.pendingA = returning;
  await select('A', pending: true);
  await back();
  await select('B');
  await back();
  await select('A');
  await owner('A');
  await tester.enterText(control('hermes-composer-field'), 'New A intent');
  final returningReads = List.of(fixture.ownedRequests);
  returning.complete(
    fixture
        .ownerHistory('A')
        .replaceAll('Canonical A history', 'Stale A history'),
  );
  await tester.pumpAndSettle();
  await owner('A');
  expect(find.text('Stale A history'), findsNothing);
  expect(draft(), 'New A intent');
  expect(fixture.ownedRequests, returningReads);
  await back();
  await select('B');

  fixture.dropEarlierB = true;
  await keyboard('hermes-transcript-load-earlier-action');
  expect(control('hermes-chat-error-reconnect'), findsOneWidget);
  final idleReads = List.of(fixture.ownedRequests);
  await tester.pump(const Duration(seconds: 2));
  expect(fixture.ownedRequests, idleReads);
  fixture.denyB = true;
  final denialStart = fixture.ownedRequests.length;
  await keyboard('hermes-chat-error-reconnect');
  expect(directory.activeContactId?.gatewayId, 'host-b');
  expect(directory.restoringSessionId, DirectFirstRunNativeFixture.session);
  expect(
    directory.restorationFailure,
    GatewaySessionRestorationFailure.authentication,
  );
  expect(channel.state.isConnected, false);
  expect(await store.loadProfiles(), saved);
  expect(find.textContaining('private-response'), findsNothing);
  expect(fixture.ownedRequests.skip(denialStart).toList(), [
    {
      'owner': 'B',
      'method': 'GET',
      'path': '/health',
      'query': <String, String>{},
    },
    {
      'owner': 'B',
      'method': 'GET',
      'path': '/v1/capabilities',
      'query': <String, String>{},
    },
  ]);
  final deniedReads = List.of(fixture.ownedRequests);
  final deniedConnects = channel.connects;
  await tester.pump(const Duration(seconds: 2));
  expect(fixture.ownedRequests, deniedReads);
  expect(channel.connects, deniedConnects);
  await capture('denied-b');
  fixture.denyB = false;
  fixture.dropEarlierB = false;
  final retryStart = fixture.ownedRequests.length;
  await keyboard('hermes-session-restoration-retry');
  await owner('B');
  expect(draft(), 'B replacement draft');
  expect(directory.restoringSessionId, isNull);
  final retried = fixture.ownedRequests.skip(retryStart).toList();
  expect(channel.connects, deniedConnects + 1);
  // Canonical reply admission also refreshes the directory's read-only summary.
  expect(retried.where((r) => r['path'] == '/health'), hasLength(2));
  expect(retried.every((r) => r['owner'] == 'B'), true);
  expect(
    retried.where((r) => r['path'].toString().endsWith('/messages')),
    hasLength(1),
  );
  await capture('recovered-b');
  expect(store.saveCalls, isEmpty);
  expect(store.deleteProfileCalls, isEmpty);
  expect(store.saveAllCalls, isEmpty);
  expect(fixture.mutationAttempts, 0);
  expect(fixture.forbiddenReadAttempts, 0);
  expect(tester.takeException(), isNull);
  final result = <String, Object?>{
    'public_saved_selection': true,
    'keyboard_retry': true,
    'same_id_return_fenced': true,
    'idle_no_reconnect': true,
    'saved_connected_distinct': true,
    'late_cases': lateCases,
    'profile': DirectFirstRunNativeFixture.profile,
    'session': DirectFirstRunNativeFixture.session,
    'requests': fixture.ownedRequests,
    'retry_requests': retried,
    'retry_connects': channel.connects - deniedConnects,
    'mutation_attempts': fixture.mutationAttempts,
    'management_attempts': 0,
    'forbidden_read_attempts': fixture.forbiddenReadAttempts,
    'physical_keychain': 'NOT_CHECKED',
  };
  await tester.pumpWidget(const SizedBox.shrink());
  return result;
}
