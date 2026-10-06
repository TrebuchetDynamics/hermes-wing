import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/providers/screens/providers_screen.dart';
import 'package:wing/features/providers/widgets/provider_credential_sheet.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/shared/widgets/wing_skeleton.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';
import '../hermes_chat/support/fake_hermes_gateway_directory.dart';

HermesCapabilityDocument _caps({
  String method = 'GET',
  String path = '/api/providers',
  bool operation = true,
  List<String> required = const ['providers:read'],
  List<String> granted = const [
    'providers:read',
    'providers:write',
    'models:read',
  ],
  bool runtime = false,
}) => HermesCapabilityDocument.fromJson({
  'schema_version': 1,
  'profile_context': {'type': 'query', 'name': 'profile', 'required': true},
  'auth': {'type': 'bearer', 'required': true, 'granted_scopes': granted},
  'endpoints': {
    if (operation)
      'providers': {
        'method': method,
        'path': path,
        'required_scopes': required,
      },
    'provider_credential_set': {
      'method': 'PUT',
      'path': '/api/providers/{slug}/credential',
      'required_scopes': ['providers:write'],
    },
    'models': {
      'method': 'GET',
      'path': runtime ? '/v1/models' : '/api/models',
      'required_scopes': ['models:read'],
    },
  },
});

final _rows = [
  const HermesProvider(slug: 'candidate', label: 'Other', authType: 'oauth'),
  const HermesProvider(
    slug: 'alpha',
    label: 'Display [alpha].*',
    authType: 'api_key',
    configured: true,
    envVars: ['NOT_SEARCHABLE_ENV'],
    keyHint: '····ab12',
  ),
  HermesProvider.fromJson({'slug': 'bare', 'label': null, 'auth_type': null}),
  const HermesProvider(
    slug: 'second',
    label: 'Second',
    authType: 'api_key',
    configured: true,
  ),
];

class _Channel extends FakeHermesChannel {
  _Channel()
    : super(
        selectedProfileId: 'default',
        modelInventory: const HermesModelInventory(
          assignment: HermesModelAssignment(
            activeProvider: 'alpha',
            activeModel: 'selected',
            revision: 'r1',
          ),
        ),
      );
  HermesCapabilityDocument caps = _caps();
  List<HermesProvider> rows = _rows;
  String profile = 'default';
  String origin = 'http://localhost:8642';
  HermesConnectionStatus status = HermesConnectionStatus.connected;
  final gates = <Completer<void>>[];
  @override
  HermesChannelState get state => super.state.copyWith(
    capabilities: caps,
    providers: rows,
    selectedProfileId: profile,
    connectedBaseUrl: origin,
    status: status,
    models: ['runtime-model'],
  );
  void emit() => notifyListeners();
  @override
  Future<void> loadProviders() async {
    await super.loadProviders();
    if (gates.isNotEmpty) await gates.removeAt(0).future;
  }
}

final _search = find.byKey(const ValueKey('providers-search'));
final _clear = find.byTooltip('Clear provider search');
String _query(WidgetTester tester) =>
    tester.widget<TextField>(_search).controller!.text;
Future<void> _enter(WidgetTester tester, String value) async {
  await tester.ensureVisible(_search);
  await tester.enterText(_search, value);
  await tester.pumpAndSettle();
}

ProviderContainer _container(_Channel channel) => ProviderContainer(
  overrides: [
    hermesChannelProvider.overrideWithValue(channel),
    hermesGatewayDirectoryProvider.overrideWith(
      (ref) => directoryFor(
        configs: [],
        loader: FakeGatewaySummaryLoader({}),
        activeChannel: channel,
      ),
    ),
  ],
);
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
        home: const ProvidersScreen(),
      ),
    );
void _noWrites(_Channel channel) {
  expect(channel.setProviderCredentialCalls, isEmpty);
  expect(channel.removeProviderCredentialCalls, isEmpty);
  expect(channel.validateProviderCredentialCalls, isEmpty);
  expect(channel.assignModelCalls, isEmpty);
  expect(channel.refreshModelsCalls, 0);
  expect(channel.connectCalls, isEmpty);
  expect(channel.selectProfileCalls, isEmpty);
  expect(channel.sentVoiceTranscripts, isEmpty);
}

void main() {
  testWidgets(
    'active gateway A-B-A before a frame discards search with same channel and profile',
    (tester) async {
      final channel = _Channel();
      final directory = directoryFor(
        configs: const [
          HermesEndpointConfig(
            id: 'A',
            label: 'A',
            baseUrl: 'http://localhost:8642',
          ),
          HermesEndpointConfig(
            id: 'B',
            label: 'B',
            baseUrl: 'http://localhost:8643',
          ),
        ],
        loader: FakeGatewaySummaryLoader({
          'A': gatewaySummary(['default']),
          'B': gatewaySummary(['default']),
        }),
        activeChannel: channel,
      );
      await directory.refresh();
      await directory.activateGateway('A');
      final container = ProviderContainer(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(channel.dispose);
      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();
      await _enter(tester, 'private query');
      await directory.activateGateway('B');
      await directory.activateGateway('A');
      await tester.pumpAndSettle();
      expect(directory.activeContactId?.gatewayId, 'A');
      expect(_query(tester), isEmpty);
      expect(find.text('Display [alpha].*'), findsOneWidget);
      expect(channel.loadProvidersCalls, 2);
      expect(channel.assignModelCalls, isEmpty);
      expect(channel.setProviderCredentialCalls, isEmpty);
    },
  );

  testWidgets('current load failure removes query and retry starts empty', (
    tester,
  ) async {
    final channel = _Channel();
    final gate = Completer<void>();
    channel.gates.add(gate);
    final container = _container(channel);
    addTearDown(container.dispose);
    addTearDown(channel.dispose);
    await tester.pumpWidget(_app(container));
    await tester.pump();
    await _enter(tester, 'private query');
    gate.completeError(StateError('synthetic current failure'));
    await tester.pumpAndSettle();
    expect(_search, findsNothing);
    expect(
      find.text('Providers could not be loaded from Hermes.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(_query(tester), isEmpty);
    expect(channel.loadProvidersCalls, 2);
    _noWrites(channel);
  });

  for (final width in [390.0, 1280.0]) {
    testWidgets(
      'literal slug/display-only search, order, semantics and keyboard clear at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 2200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        final channel = _Channel();
        final container = _container(channel);
        addTearDown(container.dispose);
        addTearDown(channel.dispose);
        await tester.pumpWidget(_app(container, scale: 2));
        await tester.pumpAndSettle();
        expect(channel.loadProvidersCalls, 1);
        expect(channel.loadModelsCalls, 1);
        for (final query in ['ALPHA', 'display [ALPHA].*']) {
          await _enter(tester, query);
          expect(find.text('Display [alpha].*'), findsOneWidget);
          expect(find.text('Second'), findsNothing);
          expect(find.text('Available providers'), findsNothing);
          expect(find.text('alpha / selected'), findsOneWidget);
        }
        // A visible management action still carries the original exact provider.
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Manage credential'),
            )
            .onPressed!();
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<ProviderCredentialSheet>(
                find.byType(ProviderCredentialSheet),
              )
              .provider
              .slug,
          'alpha',
        );
        await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
        await tester.pumpAndSettle();
        for (final query in [
          'NOT_SEARCHABLE_ENV',
          'ab12',
          'oauth',
          '.*missing',
        ]) {
          await _enter(tester, query);
          expect(find.text('No matching providers'), findsOneWidget);
          expect(find.text('No providers available'), findsNothing);
          expect(find.text('alpha / selected'), findsOneWidget);
        }
        expect(find.bySemanticsLabel('Search providers'), findsOneWidget);
        expect(
          tester.getSemantics(_clear),
          isSemantics(
            tooltip: 'Clear provider search',
            isButton: true,
            hasTapAction: true,
          ),
        );
        expect(
          tester
              .getSemantics(find.text('No matching providers'))
              .flagsCollection
              .isLiveRegion,
          isTrue,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(_query(tester), isEmpty);
        expect(_clear, findsNothing);
        await tester.ensureVisible(find.text('Other'));
        expect(
          tester.getTopLeft(find.text('Display [alpha].*')).dy,
          lessThan(tester.getTopLeft(find.text('Second')).dy),
        );
        expect(
          tester.getTopLeft(find.text('Second')).dy,
          lessThan(tester.getTopLeft(find.text('Other')).dy),
        );
        await _enter(tester, 'BARE');
        expect(find.text('bare'), findsOneWidget);
        expect(find.text('Configured providers'), findsNothing);
        expect(find.text('Available providers'), findsOneWidget);
        expect(channel.loadProvidersCalls, 1);
        expect(channel.loadModelsCalls, 1);
        _noWrites(channel);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }

  testWidgets(
    'same authorized owner updates and explicit read preserve query',
    (tester) async {
      final channel = _Channel();
      final container = _container(channel);
      addTearDown(container.dispose);
      addTearDown(channel.dispose);
      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();
      await _enter(tester, 'second');
      channel.caps = _caps(
        required: ['providers:read', 'extra:read'],
        granted: ['*'],
      );
      channel.rows = [
        ..._rows,
        const HermesProvider(slug: 'second-new', label: 'New', authType: ''),
      ];
      channel.emit();
      await channel.loadProviders();
      await tester.pumpAndSettle();
      expect(_query(tester), 'second');
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('New'), findsOneWidget);
      expect(channel.loadProvidersCalls, 2);
      _noWrites(channel);
    },
  );

  for (final transition in [
    'profile',
    'host',
    'disconnect',
    'error',
    'operation',
    'method',
    'path',
    'base grant',
    'additional grant',
  ]) {
    for (final roundtrip in [false, true]) {
      testWidgets(
        '$transition ${roundtrip ? 'same-frame roundtrip' : 'loss'} discards owner query',
        (tester) async {
          final channel = _Channel();
          final container = _container(channel);
          addTearDown(container.dispose);
          addTearDown(channel.dispose);
          await tester.pumpWidget(_app(container));
          await tester.pumpAndSettle();
          await _enter(tester, 'private query');
          switch (transition) {
            case 'profile':
              channel.profile = 'other';
            case 'host':
              channel.origin = 'http://localhost:8643';
            case 'disconnect':
              channel.status = HermesConnectionStatus.disconnected;
            case 'error':
              channel.status = HermesConnectionStatus.error;
            case 'operation':
              channel.caps = _caps(operation: false, runtime: true);
            case 'method':
              channel.caps = _caps(method: 'POST', runtime: true);
            case 'path':
              channel.caps = _caps(path: '/api/other', runtime: true);
            case 'base grant':
              channel.caps = _caps(granted: ['models:read'], runtime: true);
            case 'additional grant':
              channel.caps = _caps(
                required: ['providers:read', 'extra:read'],
                runtime: true,
              );
          }
          channel.emit();
          if (!roundtrip) {
            await tester.pumpAndSettle();
            if (!['profile', 'host'].contains(transition)) {
              expect(_search, findsNothing);
            }
            if ([
              'operation',
              'method',
              'path',
              'base grant',
              'additional grant',
            ].contains(transition)) {
              expect(find.text('Providers unavailable'), findsOneWidget);
              expect(find.text('runtime-model'), findsOneWidget);
            }
          }
          channel.profile = 'default';
          channel.origin = 'http://localhost:8642';
          channel.status = HermesConnectionStatus.connected;
          channel.caps = _caps();
          channel.emit();
          await tester.pumpAndSettle();
          expect(_query(tester), isEmpty);
          expect(find.text('Display [alpha].*'), findsOneWidget);
          _noWrites(channel);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final fails in [false, true]) {
    testWidgets(
      'replacement same-ID channel rejects late ${fails ? 'failure' : 'success'} and loading cleanup',
      (tester) async {
        final old = _Channel();
        final gate = Completer<void>();
        old.gates.add(gate);
        final next = _Channel();
        final currentGate = Completer<void>();
        next.rows = [];
        next.gates.add(currentGate);
        final container = _container(old);
        addTearDown(container.dispose);
        addTearDown(old.dispose);
        addTearDown(next.dispose);
        await tester.pumpWidget(_app(container));
        await tester.pump();
        await _enter(tester, 'old private');
        container.updateOverrides([
          hermesChannelProvider.overrideWithValue(next),
          hermesGatewayDirectoryProvider.overrideWith(
            (ref) => directoryFor(
              configs: [],
              loader: FakeGatewaySummaryLoader({}),
              activeChannel: next,
            ),
          ),
        ]);
        await tester.pump();
        await tester.pump();
        expect(find.byType(WingSkeletonList), findsOneWidget);
        if (fails) {
          gate.completeError(StateError('synthetic old failure'));
        } else {
          gate.complete();
        }
        await tester.pump();
        expect(find.byType(WingSkeletonList), findsOneWidget);
        expect(
          find.text('Providers could not be loaded from Hermes.'),
          findsNothing,
        );
        next.rows = _rows;
        currentGate.complete();
        next.emit();
        await tester.pumpAndSettle();
        expect(_query(tester), isEmpty);
        await _enter(tester, 'second');
        expect(find.text('Second'), findsOneWidget);
        _noWrites(next);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('old read across same-frame A-B-A cannot fail new owner query', (
    tester,
  ) async {
    final channel = _Channel();
    final gate = Completer<void>();
    channel.gates.add(gate);
    final container = _container(channel);
    addTearDown(container.dispose);
    addTearDown(channel.dispose);
    await tester.pumpWidget(_app(container));
    await tester.pump();
    await _enter(tester, 'old private');
    channel.profile = 'other';
    channel.emit();
    channel.profile = 'default';
    channel.emit();
    await tester.pumpAndSettle();
    expect(_query(tester), isEmpty);
    await _enter(tester, 'second');
    gate.completeError(StateError('synthetic old failure'));
    await tester.pumpAndSettle();
    expect(_query(tester), 'second');
    expect(find.text('Second'), findsOneWidget);
    expect(
      find.text('Providers could not be loaded from Hermes.'),
      findsNothing,
    );
    expect(channel.loadProvidersCalls, 2);
  });
}
