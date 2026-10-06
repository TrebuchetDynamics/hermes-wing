import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel_state.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_profile.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/core/wing_link/wing_link_client.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/profiles/screens/profiles_screen.dart';
import 'package:wing/features/profiles/widgets/profile_editor_sheet.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';
import '../hermes_chat/support/fake_hermes_endpoint_store.dart';
import '../hermes_chat/support/fake_hermes_gateway_directory.dart';

final _search = find.byKey(const ValueKey('profiles-search'));
final _clear = find.byTooltip('Clear profile search');
HermesCapabilityDocument _caps({
  bool read = true,
  List<String> requiredScopes = const ['profiles:read'],
  List<String>? grantedScopes,
}) => HermesCapabilityDocument.fromJson({
  'schema_version': 1,
  'auth': {
    'type': 'bearer',
    'granted_scopes': grantedScopes ?? (read ? ['profiles:read'] : []),
  },
  'endpoints': {
    'profiles': {
      'method': 'GET',
      'path': '/api/profiles',
      'required_scopes': requiredScopes,
    },
  },
});
const _native = [
  HermesProfile(id: 'native', displayName: 'Native', revision: 'n1'),
];
HermesEndpointConfig _host(String id, {bool enrolled = true}) =>
    HermesEndpointConfig(
      id: id,
      label: id,
      baseUrl: 'http://localhost:8642/p/default',
      wingLinkOrigin: 'http://localhost:${id == 'A' ? 8654 : 8655}',
      wingLinkToken: enrolled ? 'synthetic-only' : null,
    );
String _inventory(String prefix) => jsonEncode({
  'profiles': [
    {
      'id': 'default',
      'name': '$prefix Home',
      'topology_revision': 't1',
      'source': 'cli',
      'gateway_state': 'running',
      'actions': {},
    },
    {
      'id': 'coder',
      'name': '$prefix Coder',
      'description': 'Review [draft].*',
      'model': 'Example/Small',
      'topology_revision': 't1',
      'source': 'cli',
      'gateway_state': 'stopped',
      'actions': {
        'rename': {'revision': 'r-coder'},
        'delete': {'revision': 'd-coder'},
      },
    },
    {
      'id': 'bare',
      'name': null,
      'description': null,
      'model': null,
      'topology_revision': 't1',
      'source': 'api',
      'gateway_state': 'unknown',
      'actions': {},
    },
  ],
});
Widget _app(ProviderContainer container, {double scale = 1}) =>
    UncontrolledProviderScope(
      container: container,
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
        home: const ProfilesScreen(),
      ),
    );
ProviderContainer _container(
  FakeHermesChannel channel,
  HermesGatewayDirectory directory,
  WingLinkClientBuilder builder,
) => ProviderContainer(
  overrides: [
    hermesChannelProvider.overrideWithValue(channel),
    hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
    wingLinkClientBuilderProvider.overrideWithValue(builder),
  ],
);
Future<void> _query(WidgetTester tester, String value) async {
  await tester.ensureVisible(_search);
  await tester.enterText(_search, value);
  await tester.pumpAndSettle();
}

String _queryValue(WidgetTester tester) =>
    tester.widget<TextField>(_search).controller!.text;

void main() {
  for (final sameFrame in [false, true]) {
    testWidgets(
      'additional native read grant loss ${sameFrame ? 'same-frame' : 'visible'} discards query without resurrection',
      (tester) async {
        final allowed = _caps(
          requiredScopes: ['profiles:read', 'profiles:write'],
          grantedScopes: ['profiles:read', 'profiles:write'],
        );
        final denied = _caps(
          requiredScopes: ['profiles:read', 'profiles:write'],
          grantedScopes: ['profiles:read'],
        );
        final channel = FakeHermesChannel(
          capabilities: allowed,
          profiles: _native,
          selectedProfileId: 'native',
        );
        final directory = directoryFor(
          configs: [],
          loader: FakeGatewaySummaryLoader({}),
          activeChannel: channel,
        );
        final container = _container(
          channel,
          directory,
          ({required origin, required token, required hostFingerprint}) =>
              WingLinkClient(origin: origin, token: token),
        );
        addTearDown(container.dispose);
        addTearDown(channel.dispose);
        await tester.pumpWidget(_app(container));
        await tester.pumpAndSettle();
        await _query(tester, 'native');
        channel.replaceCapabilitiesAndProfiles(denied, _native);
        if (!sameFrame) {
          await tester.pumpAndSettle();
          expect(_search, findsNothing);
          expect(find.text('Native'), findsNothing);
          expect(find.text('Profiles unavailable'), findsOneWidget);
        }
        channel.replaceCapabilitiesAndProfiles(allowed, _native);
        await tester.pumpAndSettle();
        expect(_queryValue(tester), isEmpty);
        expect(find.text('Native'), findsOneWidget);
        expect(channel.state.selectedProfileId, 'native');
        expect(channel.selectProfileCalls, isEmpty);
        expect(channel.connectCalls, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'authorized same-owner native required-scope updates preserve query',
    (tester) async {
      final channel = FakeHermesChannel(
        capabilities: _caps(),
        profiles: _native,
      );
      final directory = directoryFor(
        configs: [],
        loader: FakeGatewaySummaryLoader({}),
        activeChannel: channel,
      );
      final container = _container(
        channel,
        directory,
        ({required origin, required token, required hostFingerprint}) =>
            WingLinkClient(origin: origin, token: token),
      );
      addTearDown(container.dispose);
      addTearDown(channel.dispose);
      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();
      await _query(tester, 'native');
      for (final scopes in [
        ['profiles:read', 'profiles:write'],
        ['*'],
      ]) {
        channel.replaceCapabilitiesAndProfiles(
          _caps(
            requiredScopes: ['profiles:read', 'profiles:write'],
            grantedScopes: scopes,
          ),
          _native,
        );
        await tester.pumpAndSettle();
        expect(_queryValue(tester), 'native');
        expect(find.text('Native'), findsOneWidget);
      }
      expect(channel.selectProfileCalls, isEmpty);
      expect(channel.connectCalls, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  for (final status in [401, 403]) {
    testWidgets(
      'Wing Link read authority $status loss hides rows and discards query on retry',
      (tester) async {
        final channel = FakeHermesChannel(
          status: HermesConnectionStatus.disconnected,
        );
        final directory = directoryFor(
          configs: [_host('A')],
          loader: FakeGatewaySummaryLoader({'A': gatewaySummary([])}),
          activeChannel: channel,
        );
        await directory.refresh();
        var reads = 0;
        final container = _container(
          channel,
          directory,
          ({required origin, required token, required hostFingerprint}) =>
              WingLinkClient(
                origin: origin,
                token: token,
                get: (uri, _) async {
                  if (uri.path != '/v1/profiles') {
                    throw StateError('catalog unavailable');
                  }
                  if (++reads == 2) throw WingLinkHttpException(status);
                  return _inventory('A');
                },
                post: (_, _, _) async => jsonEncode({
                  'profile': {
                    'id': 'newone',
                    'name': 'newone',
                    'topology_revision': 't2',
                    'source': 'cli',
                    'gateway_state': 'stopped',
                    'actions': {},
                  },
                }),
              ),
        );
        addTearDown(container.dispose);
        addTearDown(channel.dispose);
        await tester.pumpWidget(_app(container));
        await tester.pumpAndSettle();
        await _query(tester, 'private query');
        await tester.tap(find.text('New Profile'));
        await tester.pumpAndSettle();
        final editor = tester.widget<ProfileEditorSheet>(
          find.byType(ProfileEditorSheet),
        );
        await editor.onCreate!(name: 'newone');
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
        await tester.pumpAndSettle();
        expect(_search, findsNothing);
        expect(find.byKey(const ValueKey('agent-chat-coder')), findsNothing);
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        expect(_queryValue(tester), isEmpty);
        expect(find.text('A Coder'), findsOneWidget);
      },
    );
  }

  testWidgets(
    'same-owner Wing Link reload preserves search and exact rename revision',
    (tester) async {
      final channel = FakeHermesChannel(
        status: HermesConnectionStatus.disconnected,
      );
      final directory = directoryFor(
        configs: [_host('A')],
        loader: FakeGatewaySummaryLoader({'A': gatewaySummary([])}),
        activeChannel: channel,
      );
      await directory.refresh();
      var reads = 0;
      final renamedRead = Completer<String>();
      final writes = <Map<String, Object?>>[];
      final container = _container(
        channel,
        directory,
        ({required origin, required token, required hostFingerprint}) =>
            WingLinkClient(
              origin: origin,
              token: token,
              get: (_, _) {
                reads++;
                return reads == 1
                    ? Future.value(_inventory('A'))
                    : renamedRead.future;
              },
              patch: (uri, headers, body) async {
                writes.add({'path': uri.path, 'body': jsonDecode(body)});
                return jsonEncode({
                  'profile': {
                    'id': 'renamed',
                    'name': 'renamed',
                    'topology_revision': 't2',
                    'source': 'cli',
                    'gateway_state': 'stopped',
                    'actions': {},
                  },
                });
              },
            ),
      );
      addTearDown(container.dispose);
      addTearDown(channel.dispose);
      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();
      await _query(tester, 'EXAMPLE/small');
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Edit'))
          .onPressed!();
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Profile name'),
        'renamed',
      );
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      expect(writes, [
        {
          'path': '/v1/profiles/coder',
          'body': {'name': 'renamed', 'revision': 'r-coder'},
        },
      ]);
      renamedRead.complete(_inventory('Updated A'));
      await tester.pumpAndSettle();
      expect(_queryValue(tester), 'EXAMPLE/small');
      expect(find.text('Updated A Coder'), findsOneWidget);
      expect(find.text('Updated A Home'), findsNothing);
      expect(reads, 2);
    },
  );

  testWidgets(
    'same-frame host roundtrip while Wing Link read is pending starts a fresh read',
    (tester) async {
      final channel = FakeHermesChannel(
        status: HermesConnectionStatus.disconnected,
      );
      final directory = directoryFor(
        configs: [_host('A'), _host('B')],
        loader: FakeGatewaySummaryLoader({
          'A': gatewaySummary([]),
          'B': gatewaySummary([]),
        }),
        activeChannel: channel,
      );
      await directory.refresh();
      final old = Completer<String>();
      var reads = 0;
      final container = _container(
        channel,
        directory,
        ({required origin, required token, required hostFingerprint}) =>
            WingLinkClient(
              origin: origin,
              token: token,
              get: (_, _) =>
                  ++reads == 1 ? old.future : Future.value(_inventory('New A')),
            ),
      );
      addTearDown(container.dispose);
      addTearDown(channel.dispose);
      await tester.pumpWidget(_app(container));
      await tester.pump();
      directory.selectManagementGateway('B');
      directory.selectManagementGateway('A');
      await tester.pumpAndSettle();
      expect(reads, 2);
      expect(find.text('New A Coder'), findsOneWidget);
      await _query(tester, 'small');
      old.completeError(StateError('synthetic late failure'));
      await tester.pumpAndSettle();
      expect(_queryValue(tester), 'small');
      expect(find.text('Could not load local profiles.'), findsNothing);
    },
  );

  testWidgets(
    'Wing Link replacement client factory with same host resets search',
    (tester) async {
      final channel = FakeHermesChannel(
        status: HermesConnectionStatus.disconnected,
      );
      final directory = directoryFor(
        configs: [_host('A')],
        loader: FakeGatewaySummaryLoader({'A': gatewaySummary([])}),
        activeChannel: channel,
      );
      await directory.refresh();
      WingLinkClientBuilder builder(String prefix) =>
          ({required origin, required token, required hostFingerprint}) =>
              WingLinkClient(
                origin: origin,
                token: token,
                get: (_, _) async => _inventory(prefix),
              );
      final firstBuilder = builder('First');
      final container = _container(channel, directory, firstBuilder);
      addTearDown(container.dispose);
      addTearDown(channel.dispose);
      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();
      await _query(tester, 'private');
      container.updateOverrides([
        hermesChannelProvider.overrideWithValue(channel),
        hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
        wingLinkClientBuilderProvider.overrideWithValue(builder('Second')),
      ]);
      await tester.pumpAndSettle();
      expect(_queryValue(tester), isEmpty);
      expect(find.text('Second Coder'), findsOneWidget);
    },
  );

  for (final width in [390.0, 1280.0]) {
    testWidgets(
      'Wing Link bounded metadata, null/name-only, order, semantics and zero search calls at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final channel = FakeHermesChannel(
          status: HermesConnectionStatus.disconnected,
        );
        final directory = directoryFor(
          configs: [_host('A')],
          loader: FakeGatewaySummaryLoader({'A': gatewaySummary([])}),
          activeChannel: channel,
        );
        await directory.refresh();
        var reads = 0;
        var mutations = 0;
        final container = _container(
          channel,
          directory,
          ({required origin, required token, required hostFingerprint}) =>
              WingLinkClient(
                origin: origin,
                token: token,
                get: (_, _) async {
                  reads++;
                  return _inventory('A');
                },
                post: (_, _, _) async {
                  mutations++;
                  throw StateError('unexpected mutation');
                },
                patch: (_, _, _) async {
                  mutations++;
                  throw StateError('unexpected mutation');
                },
                delete: (_, _) async {
                  mutations++;
                  throw StateError('unexpected mutation');
                },
              ),
        );
        addTearDown(container.dispose);
        // The ChangeNotifier provider owns directory disposal.
        addTearDown(channel.dispose);
        await tester.pumpWidget(_app(container, scale: 2));
        await tester.pumpAndSettle();
        expect(reads, 1);
        for (final query in [
          'CODER',
          'a CODER',
          'review [DRAFT].*',
          'EXAMPLE/small',
        ]) {
          await _query(tester, query);
          expect(find.text('A Coder'), findsOneWidget);
          expect(find.text('A Home'), findsNothing);
        }
        await _query(tester, 'bare');
        expect(
          find
              .text('bare', findRichText: false)
              .evaluate()
              .where((element) => element.widget is Text),
          hasLength(1),
        );
        await _query(tester, '.*missing');
        expect(find.text('No matching profiles'), findsOneWidget);
        expect(find.text('No profiles available'), findsNothing);
        expect(find.bySemanticsLabel('Search profiles'), findsOneWidget);
        expect(
          tester.getSemantics(_clear),
          isSemantics(
            tooltip: 'Clear profile search',
            isButton: true,
            hasTapAction: true,
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(_queryValue(tester), isEmpty);
        expect(
          find
              .byType(FilledButton)
              .evaluate()
              .map((e) => e.widget.key)
              .whereType<ValueKey<String>>()
              .map((k) => k.value),
          ['agent-chat-default', 'agent-chat-coder', 'agent-chat-bare'],
        );
        await directory.refresh();
        await tester.pumpAndSettle();
        await _query(tester, 'coder');
        await directory.refresh();
        await tester.pumpAndSettle();
        expect(_queryValue(tester), 'coder');
        expect(reads, 1);
        expect(mutations, 0);
        expect(channel.connectCalls, isEmpty);
        expect(channel.selectProfileCalls, isEmpty);
        expect(tester.takeException(), isNull);
        // Filtering changes no editor identity, revision, or full clone inventory.
        tester
            .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Edit'))
            .onPressed!();
        await tester.pumpAndSettle();
        final editor = tester.widget<ProfileEditorSheet>(
          find.byType(ProfileEditorSheet),
        );
        expect(editor.profile!.id, 'coder');
        expect(editor.profile!.revision, 't1');
        expect(editor.profiles.map((p) => p.id), ['default', 'coder', 'bare']);
        expect(mutations, 0);
      },
    );
  }

  for (final fails in [false, true]) {
    testWidgets(
      'old Wing Link read ${fails ? 'failure' : 'success'} cannot affect A-B-A search or inventory',
      (tester) async {
        final channel = FakeHermesChannel(
          status: HermesConnectionStatus.disconnected,
        );
        final directory = directoryFor(
          configs: [_host('A'), _host('B')],
          loader: FakeGatewaySummaryLoader({
            'A': gatewaySummary([]),
            'B': gatewaySummary([]),
          }),
          activeChannel: channel,
        );
        await directory.refresh();
        final oldRead = Completer<String>();
        var aReads = 0;
        final container = _container(
          channel,
          directory,
          ({required origin, required token, required hostFingerprint}) =>
              WingLinkClient(
                origin: origin,
                token: token,
                get: (_, _) {
                  if (origin.port == 8654 && ++aReads == 1) {
                    return oldRead.future;
                  }
                  return Future.value(
                    _inventory(origin.port == 8654 ? 'New A' : 'B'),
                  );
                },
              ),
        );
        addTearDown(container.dispose);
        // The ChangeNotifier provider owns directory disposal.
        addTearDown(channel.dispose);
        await tester.pumpWidget(_app(container));
        await tester.pump();
        directory.selectManagementGateway('B');
        await tester.pumpAndSettle();
        await _query(tester, 'B Coder');
        directory.selectManagementGateway('A');
        await tester.pumpAndSettle();
        expect(_queryValue(tester), isEmpty);
        await _query(tester, 'New A Coder');
        if (fails) {
          oldRead.completeError(StateError('synthetic old failure'));
        } else {
          oldRead.complete(_inventory('Old A'));
        }
        await tester.pumpAndSettle();
        expect(_queryValue(tester), 'New A Coder');
        expect(find.byKey(const ValueKey('agent-chat-coder')), findsOneWidget);
        expect(find.text('Old A Coder'), findsNothing);
        expect(find.text('Could not load local profiles.'), findsNothing);
        expect(tester.takeException(), isNull);
        directory.selectManagementGateway('B');
        directory.selectManagementGateway('A');
        await tester.pumpAndSettle();
        expect(_queryValue(tester), isEmpty);
      },
    );
  }

  testWidgets(
    'Wing Link enrollment loss and restoration discard private query',
    (tester) async {
      final channel = FakeHermesChannel(
        status: HermesConnectionStatus.disconnected,
      );
      var enrolled = true;
      final store = FakeHermesEndpointStore(
        onLoadProfiles: () async => [_host('A', enrolled: enrolled)],
      );
      final directory = HermesGatewayDirectory(
        store: store,
        cache: FakeGatewayContactCache(),
        loader: FakeGatewaySummaryLoader({'A': gatewaySummary([])}),
        activeChannel: channel,
      );
      await directory.refresh();
      final container = _container(
        channel,
        directory,
        ({required origin, required token, required hostFingerprint}) =>
            WingLinkClient(
              origin: origin,
              token: token,
              get: (_, _) async => _inventory('A'),
            ),
      );
      addTearDown(container.dispose);
      // The ChangeNotifier provider owns directory disposal.
      addTearDown(channel.dispose);
      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();
      await _query(tester, 'private query');
      enrolled = false;
      await directory.refresh();
      await tester.pumpAndSettle();
      expect(_search, findsNothing);
      enrolled = true;
      await directory.refresh();
      await tester.pumpAndSettle();
      expect(_queryValue(tester), isEmpty);
    },
  );

  testWidgets(
    'native-Wing Link-native source changes discard queries before results render',
    (tester) async {
      final channel = FakeHermesChannel(
        capabilities: _caps(),
        profiles: _native,
      );
      final directory = directoryFor(
        configs: [_host('A')],
        loader: FakeGatewaySummaryLoader({
          'A': gatewaySummary(['default']),
        }),
        activeChannel: channel,
      );
      await directory.refresh();
      await directory.activateGateway('A');
      final container = _container(
        channel,
        directory,
        ({required origin, required token, required hostFingerprint}) =>
            WingLinkClient(
              origin: origin,
              token: token,
              get: (_, _) async => _inventory('A'),
            ),
      );
      addTearDown(container.dispose);
      // The ChangeNotifier provider owns directory disposal.
      addTearDown(channel.dispose);
      channel.replaceCapabilitiesAndProfiles(_caps(), _native);
      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();
      await _query(tester, 'native');
      channel.replaceCapabilitiesAndProfiles(_caps(read: false), _native);
      await tester.pumpAndSettle();
      expect(_queryValue(tester), isEmpty);
      expect(find.text('A Coder'), findsOneWidget);
      await _query(tester, 'coder');
      channel.replaceCapabilitiesAndProfiles(_caps(), _native);
      await tester.pumpAndSettle();
      expect(_queryValue(tester), isEmpty);
      expect(find.text('Native'), findsOneWidget);
    },
  );

  testWidgets(
    'replacement Agent client with same IDs discards search and listens to the new client',
    (tester) async {
      final first = FakeHermesChannel(capabilities: _caps(), profiles: _native);
      final second = FakeHermesChannel(
        capabilities: _caps(),
        profiles: _native,
      );
      final directory = directoryFor(
        configs: [],
        loader: FakeGatewaySummaryLoader({}),
        activeChannel: first,
      );
      final container = _container(
        first,
        directory,
        ({required origin, required token, required hostFingerprint}) =>
            WingLinkClient(origin: origin, token: token),
      );
      addTearDown(container.dispose);
      // The ChangeNotifier provider owns directory disposal.
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();
      await _query(tester, 'old private');
      container.updateOverrides([
        hermesChannelProvider.overrideWithValue(second),
        hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
        wingLinkClientBuilderProvider.overrideWithValue(
          container.read(wingLinkClientBuilderProvider),
        ),
      ]);
      await tester.pumpAndSettle();
      expect(_queryValue(tester), isEmpty);
      await _query(tester, 'native');
      second.replaceCapabilitiesAndProfiles(_caps(read: false), _native);
      second.replaceCapabilitiesAndProfiles(_caps(), _native);
      await tester.pumpAndSettle();
      expect(_queryValue(tester), isEmpty);
    },
  );

  testWidgets(
    'visible search action selects exact native ID without changing hidden active owner first',
    (tester) async {
      final channel = FakeHermesChannel(
        capabilities: _caps(),
        selectedProfileId: 'home',
        profiles: const [
          HermesProfile(id: 'home', displayName: 'Same label', revision: 'r1'),
          HermesProfile(
            id: 'target',
            displayName: 'Same label',
            revision: 'r2',
          ),
        ],
      );
      final directory = directoryFor(
        configs: [],
        loader: FakeGatewaySummaryLoader({}),
        activeChannel: channel,
      );
      final container = _container(
        channel,
        directory,
        ({required origin, required token, required hostFingerprint}) =>
            WingLinkClient(origin: origin, token: token),
      );
      addTearDown(container.dispose);
      // The ChangeNotifier provider owns directory disposal.
      addTearDown(channel.dispose);
      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();
      await _query(tester, 'TARGET');
      expect(channel.state.selectedProfileId, 'home');
      expect(channel.selectProfileCalls, isEmpty);
      expect(find.text('Active chat'), findsNothing);
      final button = find.byKey(const ValueKey('agent-chat-target'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(channel.selectProfileCalls, ['target']);
      expect(channel.state.selectedProfileId, 'target');
    },
  );
}
