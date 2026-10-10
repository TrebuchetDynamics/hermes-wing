import 'package:flutter/material.dart';
import 'dart:async';
import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/core/hermes/client/hermes_api_config.dart';
import 'package:wing/core/hermes/shared/hermes_api_http.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';

const first = HermesEndpointConfig(
  id: 'first',
  baseUrl: 'https://first.example.invalid/p/shared',
  label: 'Shared name',
);
const second = HermesEndpointConfig(
  id: 'second',
  baseUrl: 'https://second.example.invalid/p/shared',
  label: 'Shared name',
);

class Loader implements GatewaySummaryLoader {
  @override
  Future<GatewaySummary> load(HermesEndpointConfig config) async =>
      const GatewaySummary(profiles: [], sessionsByProfile: {});
}

class Store extends FakeHermesEndpointStore {
  Store() : super(profiles: [first, second]);
  Completer<void>? pending;
  bool fail = false;
  int attempts = 0;
  @override
  Future<void> save({
    required String baseUrl,
    String? apiKey,
    String? label,
    String? profileId,
    String? wingLinkOrigin,
    String? wingLinkToken,
    String? wingLinkPendingCredentialId,
    String? wingLinkHostFingerprint,
    String? wingLinkDeviceId,
  }) async {
    attempts++;
    await pending?.future;
    if (fail) throw StateError('private storage detail');
    await super.save(
      baseUrl: baseUrl,
      apiKey: apiKey,
      label: label,
      profileId: profileId,
    );
  }
}

class StatusFailure implements HermesApiStatusException {
  const StatusFailure(this.statusCode);
  @override
  final int statusCode;
}

class Probe {
  final calls = <HermesApiConfig>[];
  Completer<String>? pending;
  int status = 200;
  String body =
      '{"object":"hermes.api_server.capabilities","platform":"hermes-agent","schema_version":1}';
  HermesApiClient build(HermesApiConfig config) {
    calls.add(config);
    return HermesApiClient(
      config: config,
      get: (uri, headers) async {
        expect(uri, config.capabilitiesUri);
        if (status != 200) throw StatusFailure(status);
        return pending?.future ?? body;
      },
      post: (uri, headers, body) async =>
          throw StateError('Unexpected mutation'),
    );
  }
}

Future<FakeHermesChannel> mount(
  WidgetTester tester,
  FakeHermesEndpointStore store, {
  Probe? probe,
  double width = 1280,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final channel = FakeHermesChannel.disconnected();
  addTearDown(channel.dispose);
  final directory = HermesGatewayDirectory(
    store: store,
    cache: GatewayContactCache(),
    loader: Loader(),
    activeChannel: channel,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesEndpointStoreProvider.overrideWithValue(store),
        hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
        if (probe != null)
          hermesEndpointTestClientProvider.overrideWithValue(probe.build),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: const HermesChatScreen(initiallyEditingConnection: true),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return channel;
}

Future<void> edit(WidgetTester tester) async {
  final button = find.byKey(
    const ValueKey('hermes-endpoint-profile-edit-first'),
  );
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  for (final abandon in ['owner', 'dispose']) {
    testWidgets('pending save settlement after $abandon cannot replace owner', (
      tester,
    ) async {
      final store = Store()..pending = Completer<void>();
      final channel = await mount(tester, store);
      await edit(tester);
      await tester.tap(find.byKey(const ValueKey('hermes-saved-edit-save')));
      await tester.pump();
      if (abandon == 'owner') {
        await channel.connect(baseUrl: second.baseUrl);
        await channel.connect(baseUrl: first.baseUrl);
      } else {
        await tester.pumpWidget(const SizedBox());
      }
      store.pending!.complete();
      await tester.pumpAndSettle();
      expect(store.saveCalls, hasLength(1));
      expect(store.saveCalls.single.id, 'first');
      expect(channel.connectCalls, hasLength(abandon == 'owner' ? 2 : 0));
      expect(
        find.text('Saved connection updated. Chat has not been reconnected.'),
        findsNothing,
      );
      if (abandon == 'owner') {
        expect(
          find.byKey(const ValueKey('hermes-saved-edit-dialog')),
          findsOneWidget,
        );
        expect(
          find.textContaining('The connection owner or draft changed'),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
  for (final raw in [
    'https://user:synthetic@example.invalid',
    'https://example.invalid?credential=synthetic',
    'https://example.invalid/#synthetic',
    'https://example.invalid/unsupported',
  ]) {
    testWidgets('invalid endpoint draft never saves or tests: $raw', (
      tester,
    ) async {
      final store = Store();
      final probe = Probe();
      await mount(tester, store, probe: probe);
      await edit(tester);
      await tester.enterText(
        find.byKey(const ValueKey('hermes-saved-edit-url')),
        raw,
      );
      await tester.tap(find.byKey(const ValueKey('hermes-saved-edit-test')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('hermes-saved-edit-save')));
      await tester.pumpAndSettle();
      expect(probe.calls, isEmpty);
      expect(store.attempts, 0);
      expect(
        find.byKey(const ValueKey('hermes-saved-edit-dialog')),
        findsOneWidget,
      );
    });
  }
  for (final width in [390.0, 1280.0]) {
    testWidgets(
      'explicit save updates original ID only at $width and 200% text',
      (tester) async {
        final store = Store();
        final channel = await mount(tester, store, width: width, scale: 2);
        await edit(tester);
        await tester.enterText(
          find.byKey(const ValueKey('hermes-saved-edit-url')),
          'https://draft.example.invalid/p/shared',
        );
        await tester.enterText(
          find.byKey(const ValueKey('hermes-saved-edit-key')),
          'synthetic-replacement',
        );
        expect(
          tester
              .widget<TextField>(
                find.byKey(const ValueKey('hermes-saved-edit-key')),
              )
              .obscureText,
          isTrue,
        );
        await tester.tap(find.byKey(const ValueKey('hermes-saved-edit-save')));
        await tester.pumpAndSettle();
        expect(store.attempts, 1);
        expect(store.saveCalls.single.id, 'first');
        expect(store.saveCalls.single.apiKey, 'synthetic-replacement');
        expect(
          (await store.loadProfiles())
              .singleWhere((row) => row.id == 'second')
              .baseUrl,
          second.baseUrl,
        );
        expect(channel.connectCalls, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('delayed storage failure keeps draft for explicit retry', (
    tester,
  ) async {
    final store = Store()
      ..fail = true
      ..pending = Completer<void>();
    final channel = await mount(tester, store);
    await edit(tester);
    await tester.enterText(
      find.byKey(const ValueKey('hermes-saved-edit-url')),
      'https://draft.example.invalid',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-saved-edit-save')));
    await tester.pump();
    store.pending!.complete();
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Could not save this connection'),
      findsOneWidget,
    );
    expect(find.textContaining('private storage detail'), findsNothing);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('hermes-saved-edit-url')),
          )
          .controller!
          .text,
      'https://draft.example.invalid',
    );
    store.fail = false;
    await tester.tap(find.byKey(const ValueKey('hermes-saved-edit-save')));
    await tester.pumpAndSettle();
    expect(store.attempts, 2);
    expect(store.saveCalls, hasLength(1));
    expect(channel.connectCalls, isEmpty);
  });
  for (final action in ['save', 'test']) {
    testWidgets(
      'changed owner rejects stale $action including return to origin',
      (tester) async {
        final store = Store();
        final probe = Probe();
        final channel = await mount(tester, store, probe: probe);
        await edit(tester);
        await channel.connect(baseUrl: second.baseUrl);
        await channel.connect(baseUrl: first.baseUrl);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('hermes-saved-edit-$action')));
        await tester.pumpAndSettle();
        expect(store.attempts, 0);
        expect(probe.calls, isEmpty);
        expect(
          find.textContaining('The connection owner or draft changed'),
          findsOneWidget,
        );
      },
    );
  }
  for (final status in [200, 401, 403, 500]) {
    testWidgets(
      'read-only draft test status $status leaves owner and storage unchanged',
      (tester) async {
        final store = Store();
        final probe = Probe()..status = status;
        final channel = await mount(tester, store, probe: probe);
        await edit(tester);
        await tester.enterText(
          find.byKey(const ValueKey('hermes-saved-edit-url')),
          'https://draft.example.invalid/p/shared',
        );
        await tester.enterText(
          find.byKey(const ValueKey('hermes-saved-edit-key')),
          'synthetic-replacement',
        );
        await tester.tap(find.byKey(const ValueKey('hermes-saved-edit-test')));
        await tester.pumpAndSettle();
        expect(
          probe.calls.single.baseUri.toString(),
          'https://draft.example.invalid/p/shared',
        );
        expect(probe.calls.single.apiKey, 'synthetic-replacement');
        expect(
          find.textContaining(
            status == 200
                ? 'Supported Agent discovery responded'
                : status == 500
                ? 'could not be verified'
                : 'denied this credential',
          ),
          findsOneWidget,
        );
        expect(store.attempts, 0);
        expect(channel.connectCalls, isEmpty);
      },
    );
  }
  for (final abandon in ['draft', 'cancel', 'owner', 'dispose']) {
    testWidgets('late read after $abandon cannot announce success', (
      tester,
    ) async {
      final store = Store();
      final probe = Probe()..pending = Completer<String>();
      final channel = await mount(tester, store, probe: probe);
      await edit(tester);
      await tester.tap(find.byKey(const ValueKey('hermes-saved-edit-test')));
      await tester.pump();
      if (abandon == 'draft') {
        await tester.enterText(
          find.byKey(const ValueKey('hermes-saved-edit-url')),
          second.baseUrl,
        );
      } else if (abandon == 'cancel') {
        await tester.tap(
          find.byKey(const ValueKey('hermes-saved-edit-cancel-test')),
        );
      } else if (abandon == 'owner') {
        await channel.connect(baseUrl: second.baseUrl);
      } else {
        await tester.pumpWidget(const SizedBox());
      }
      probe.pending!.complete(probe.body);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Supported Agent discovery responded'),
        findsNothing,
      );
      expect(store.attempts, 0);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'read timeout and incompatible response remain explicit failures',
    (tester) async {
      final store = Store();
      final probe = Probe()..pending = Completer<String>();
      await mount(tester, store, probe: probe);
      await edit(tester);
      await tester.tap(find.byKey(const ValueKey('hermes-saved-edit-test')));
      await tester.pump(const Duration(seconds: 21));
      await tester.pumpAndSettle();
      expect(find.textContaining('could not be verified'), findsOneWidget);
      probe.pending!.complete('{}');
      probe.pending = null;
      probe.body = '{}';
      await tester.tap(find.byKey(const ValueKey('hermes-saved-edit-test')));
      await tester.pumpAndSettle();
      expect(find.textContaining('could not be verified'), findsOneWidget);
      expect(store.attempts, 0);
    },
  );
  testWidgets('public saved edit cancels without saving or connecting', (
    tester,
  ) async {
    final store = FakeHermesEndpointStore(profiles: [first, second]);
    final channel = await mount(tester, store);
    await edit(tester);
    await tester.enterText(
      find.byKey(const ValueKey('hermes-saved-edit-url')),
      'https://draft.example.invalid/p/shared',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-saved-edit-cancel')));
    await tester.pumpAndSettle();
    expect(store.saveCalls, isEmpty);
    expect(channel.connectCalls, isEmpty);
    expect((await store.loadProfiles()).first.baseUrl, first.baseUrl);
  });
}
