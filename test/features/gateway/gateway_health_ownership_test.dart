import 'dart:async';
import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_health.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/gateway/screens/gateway_screen.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';
import '../hermes_chat/support/fake_hermes_gateway_directory.dart';

HermesCapabilityDocument _caps({
  int schema = 1,
  bool operation = true,
  String method = 'GET',
  String path = '/health/detailed',
  List<String> required = const ['gateway:read'],
  List<String> granted = const ['gateway:read'],
}) => HermesCapabilityDocument.fromJson({
  'schema_version': schema,
  'auth': {'type': 'bearer', 'required': true, 'granted_scopes': granted},
  'endpoints': {
    if (operation)
      'health_detailed': {
        'method': method,
        'path': path,
        'required_scopes': required,
      },
  },
});

const _health = HermesHealthStatus(
  status: 'ok',
  platform: 'hermes-agent',
  version: 'fixture-health',
  gatewayState: 'running',
  activeAgents: 1,
);

class _Channel extends FakeHermesChannel {
  _Channel() : super(basicHealth: _health, detailedHealth: _health);
  HermesCapabilityDocument caps = _caps();
  String profile = 'default';
  String origin = 'http://localhost:8642';
  HermesConnectionStatus status = HermesConnectionStatus.connected;
  bool selecting = false;
  bool failed = false;
  HermesHealthStatus health = _health;

  final pending = <Completer<void>>[];
  @override
  HermesChannelState get state => super.state.copyWith(
    capabilities: caps,
    detailedHealth: failed ? null : health,
    clearDetailedHealth: failed,
    connectedBaseUrl: origin,
    selectedProfileId: profile,
    status: status,
    isSelectingProfile: selecting,

    optionalResourceErrors: failed
        ? const {
            HermesOptionalResource.detailedHealth: 'synthetic private metadata',
          }
        : const {},
  );
  void emit() => notifyListeners();
  @override
  Future<void> loadDetailedHealth() {
    loadDetailedHealthCalls++;
    final gate = Completer<void>();
    pending.add(gate);
    return gate.future;
  }
}

final _refresh = find.byKey(const ValueKey('gateway-refresh-button'));
final _retry = find.byKey(const ValueKey('gateway-status-inline-retry'));
bool _enabled(WidgetTester tester) =>
    tester.widget<IconButton>(_refresh).onPressed != null;
ProviderContainer _container(
  _Channel channel, {
  HermesGatewayDirectory? directory,
}) => ProviderContainer(
  overrides: [
    hermesChannelProvider.overrideWithValue(channel),
    hermesGatewayDirectoryProvider.overrideWith(
      (ref) =>
          directory ??
          directoryFor(
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
        home: const GatewayScreen(),
      ),
    );
Future<void> _start(WidgetTester tester) async {
  await tester.tap(_refresh);
  await tester.pump();
  expect(_enabled(tester), isFalse);
}

void _finish(_Channel channel, int index, bool fails) {
  // Like the production loader, publish the optional-resource result before
  // resolving the request. UI must not treat this unowned state as a new retry.
  channel.failed = fails;
  channel.emit();
  if (fails) {
    channel.pending[index].completeError(
      StateError('synthetic private metadata'),
    );
  } else {
    channel.pending[index].complete();
  }
}

void _noWrites(_Channel channel) {
  expect(channel.connectCalls, isEmpty);
  expect(channel.disconnectCalls, 0);
  expect(channel.selectProfileCalls, isEmpty);
  expect(channel.selectSessionCalls, isEmpty);
  expect(channel.createSessionCalls, isEmpty);
  expect(channel.sentVoiceTranscripts, isEmpty);
  expect(find.textContaining('synthetic private'), findsNothing);
}

void main() {
  testWidgets(
    'directory-only replacement invalidates pending read and rebinds listeners',
    (tester) async {
      final channel = _Channel();
      final first = directoryFor(
        configs: [],
        loader: FakeGatewaySummaryLoader({}),
        activeChannel: channel,
      );
      final second = directoryFor(
        configs: [],
        loader: FakeGatewaySummaryLoader({}),
        activeChannel: channel,
      );
      var current = first;
      final container = ProviderContainer(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesGatewayDirectoryProvider.overrideWith((ref) => current),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(channel.dispose);
      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();
      await _start(tester);
      current = second;
      container.invalidate(hermesGatewayDirectoryProvider);
      expect(container.read(hermesGatewayDirectoryProvider), same(second));
      await tester.pump();
      await tester.pump();
      expect(_enabled(tester), isTrue);
      await _start(tester);
      _finish(channel, 0, true);
      await tester.pump();
      expect(_enabled(tester), isFalse);
      expect(_retry, findsNothing);
      channel.profile = 'other';
      channel.emit();
      await tester.pump();
      expect(_enabled(tester), isTrue);
      _finish(channel, 1, true);
      await tester.pumpAndSettle();
      expect(_retry, findsNothing);
      await _start(tester);
      _finish(channel, 2, false);
      await tester.pumpAndSettle();
      expect(_enabled(tester), isTrue);
      _noWrites(channel);
    },
  );
  testWidgets('published failure does not return on same-ID channel A-B-A', (
    tester,
  ) async {
    final channel = _Channel();
    final other = _Channel();
    final directory = directoryFor(
      configs: [],
      loader: FakeGatewaySummaryLoader({}),
      activeChannel: channel,
    );
    final container = _container(channel, directory: directory);
    addTearDown(container.dispose);
    addTearDown(channel.dispose);
    addTearDown(other.dispose);
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();
    await _start(tester);
    _finish(channel, 0, true);
    await tester.pumpAndSettle();
    expect(_retry, findsOneWidget);
    for (final next in [other, channel]) {
      container.updateOverrides([
        hermesChannelProvider.overrideWithValue(next),
        hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
      ]);
      expect(container.read(hermesChannelProvider), same(next));
    }
    await tester.pumpAndSettle();
    expect(_enabled(tester), isTrue);
    expect(_retry, findsNothing);
    expect(
      find.text(
        'Connected. Basic health is available, but detailed status could not be loaded.',
      ),
      findsNothing,
    );
    expect(find.text('fixture-health'), findsOneWidget);
    expect(channel.loadDetailedHealthCalls, 1);
    expect(other.loadDetailedHealthCalls, 0);
    _noWrites(channel);
    _noWrites(other);
  });
  for (final fails in [false, true]) {
    for (final oldFirst in [false, true]) {
      testWidgets(
        'same-ID channel replacement rejects old ${fails ? 'failure' : 'success'}, oldFirst=$oldFirst',
        (tester) async {
          final old = _Channel();
          final next = _Channel();
          final container = _container(old);
          addTearDown(container.dispose);
          addTearDown(old.dispose);
          addTearDown(next.dispose);
          await tester.pumpWidget(_app(container));
          await tester.pumpAndSettle();
          await _start(tester);
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
          expect(_enabled(tester), isTrue);
          expect(next.loadDetailedHealthCalls, 0);
          await _start(tester);
          if (oldFirst) {
            _finish(old, 0, fails);
            await tester.pump();
            expect(_enabled(tester), isFalse);
            expect(_retry, findsNothing);
          }
          _finish(next, 0, true);
          await tester.pumpAndSettle();
          expect(_retry, findsOneWidget);
          if (!oldFirst) {
            _finish(old, 0, fails);
            await tester.pumpAndSettle();
            expect(_retry, findsOneWidget);
          }
          expect(_enabled(tester), isTrue);
          _noWrites(next);
        },
      );
    }
  }
  testWidgets(
    'same-ID replacement channel A-B-A before a frame invalidates the old read',
    (tester) async {
      final old = _Channel();
      final other = _Channel();
      final directory = directoryFor(
        configs: [],
        loader: FakeGatewaySummaryLoader({}),
        activeChannel: old,
      );
      final container = _container(old, directory: directory);
      addTearDown(container.dispose);
      addTearDown(old.dispose);
      addTearDown(other.dispose);
      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();
      await _start(tester);
      for (final channel in [other, old]) {
        container.updateOverrides([
          hermesChannelProvider.overrideWithValue(channel),
          hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
        ]);
        expect(container.read(hermesChannelProvider), same(channel));
      }
      await tester.pump();
      expect(_enabled(tester), isTrue);
      await _start(tester);
      _finish(old, 0, true);
      await tester.pump();
      expect(_enabled(tester), isFalse);
      expect(_retry, findsNothing);
      _finish(old, 1, false);
      await tester.pumpAndSettle();
      expect(_enabled(tester), isTrue);
      expect(other.loadDetailedHealthCalls, 0);
      _noWrites(old);
      _noWrites(other);
    },
  );
  for (final transition in [
    'profile',
    'origin',
    'disconnect',
    'error',
    'selecting',
    'operation',
    'method',
    'path',
    'schema',
    'grant',
    'additional grant',
  ]) {
    for (final roundtrip in [false, true]) {
      testWidgets(
        '$transition owner loss${roundtrip ? ' and same-frame restoration' : ''} invalidates pending and shown failure',
        (tester) async {
          final channel = _Channel();
          final container = _container(channel);
          addTearDown(container.dispose);
          addTearDown(channel.dispose);
          await tester.pumpWidget(_app(container));
          await tester.pumpAndSettle();
          // Exercise both an outstanding read and a failure already rendered.
          for (final shown in [false, true]) {
            await _start(tester);
            final old = channel.pending.length - 1;
            if (shown) {
              _finish(channel, old, true);
              await tester.pumpAndSettle();
              expect(_retry, findsOneWidget);
            }
            switch (transition) {
              case 'profile':
                channel.profile = 'other';
              case 'origin':
                channel.origin = 'http://localhost:8643';
              case 'disconnect':
                channel.status = HermesConnectionStatus.disconnected;
              case 'error':
                channel.status = HermesConnectionStatus.error;
              case 'selecting':
                channel.selecting = true;
              case 'operation':
                channel.caps = _caps(operation: false);
              case 'method':
                channel.caps = _caps(method: 'POST');
              case 'path':
                channel.caps = _caps(path: '/other');
              case 'schema':
                channel.caps = _caps(schema: 999);
              case 'grant':
                channel.caps = _caps(granted: []);
              case 'additional grant':
                channel.caps = _caps(required: ['gateway:read', 'extra:read']);
            }
            channel.emit();
            if (!roundtrip) {
              await tester.pump();
              if (!['profile', 'origin'].contains(transition)) {
                expect(_refresh, findsNothing);
              }
            }
            channel.profile = 'default';
            channel.origin = 'http://localhost:8642';
            channel.status = HermesConnectionStatus.connected;
            channel.selecting = false;
            channel.caps = _caps();
            channel.emit();
            await tester.pump();
            expect(_enabled(tester), isTrue);
            expect(_retry, findsNothing);
            await _start(tester);
            final current = channel.pending.length - 1;
            if (!shown) {
              _finish(channel, old, true);
              await tester.pump();
              expect(_enabled(tester), isFalse);
              expect(_retry, findsNothing);
            }
            _finish(channel, current, false);
            await tester.pumpAndSettle();
            expect(_enabled(tester), isTrue);
            expect(_retry, findsNothing);
          }
          _noWrites(channel);
        },
      );
    }
  }
  testWidgets('management host roundtrip is observed without connecting Chat', (
    tester,
  ) async {
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
    final before = channel.connectCalls.length;
    final container = _container(channel, directory: directory);
    addTearDown(container.dispose);
    addTearDown(channel.dispose);
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();
    await _start(tester);
    directory.selectManagementGateway('B');
    await tester.pump();
    expect(_refresh, findsNothing);
    expect(channel.loadDetailedHealthCalls, 1);
    directory.selectManagementGateway('A');
    await tester.pump();
    expect(_enabled(tester), isTrue);
    await _start(tester);
    directory.selectManagementGateway('B');
    directory.selectManagementGateway('A');
    await tester.pump();
    expect(_enabled(tester), isTrue);
    await _start(tester);
    _finish(channel, 0, true);
    _finish(channel, 1, false);
    await tester.pump();
    expect(_enabled(tester), isFalse);
    expect(_retry, findsNothing);
    _finish(channel, 2, false);
    await tester.pumpAndSettle();
    expect(channel.connectCalls.length, before);
    expect(directory.activeContactId?.gatewayId, 'A');
    expect(channel.loadDetailedHealthCalls, 3);
  });
  testWidgets(
    'ordinary same-authorized-owner health and scope updates retain pending read',
    (tester) async {
      final channel = _Channel();
      final container = _container(channel);
      addTearDown(container.dispose);
      addTearDown(channel.dispose);
      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();
      await _start(tester);
      channel.caps = _caps(
        required: ['gateway:read', 'extra:read'],
        granted: ['gateway:read', 'extra:read'],
      );
      channel.health = const HermesHealthStatus(
        status: 'ok',
        platform: 'hermes-agent',
        version: 'same-owner-update',
        gatewayState: 'running',
        activeAgents: 2,
      );
      channel.emit();
      await tester.pump();
      expect(_enabled(tester), isFalse);
      expect(find.text('same-owner-update'), findsOneWidget);
      await tester.tap(_refresh);
      expect(channel.loadDetailedHealthCalls, 1);
      _finish(channel, 0, false);
      await tester.pumpAndSettle();
      expect(_enabled(tester), isTrue);
      _noWrites(channel);
    },
  );
  testWidgets(
    'same-host management profile stays eligible but transfers health owner',
    (tester) async {
      final channel = _Channel();
      final directory = directoryFor(
        configs: const [
          HermesEndpointConfig(
            id: 'A',
            label: 'A',
            baseUrl: 'http://localhost:8642/p/default',
            wingLinkOrigin: 'https://host.example',
            wingLinkDeviceId: 'fixture-device',
          ),
          HermesEndpointConfig(
            id: 'B',
            label: 'B',
            baseUrl: 'http://localhost:8642/p/other',
            wingLinkOrigin: 'https://host.example',
            wingLinkDeviceId: 'fixture-device',
          ),
        ],
        loader: FakeGatewaySummaryLoader({
          'A': gatewaySummary(['default']),
          'B': gatewaySummary(['other']),
        }),
        activeChannel: channel,
      );
      await directory.refresh();
      await directory.activateGateway('A');
      final connections = channel.connectCalls.length;
      final container = _container(channel, directory: directory);
      addTearDown(container.dispose);
      addTearDown(channel.dispose);
      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();
      await _start(tester);
      directory.selectManagementGateway('B');
      await tester.pump();
      expect(_enabled(tester), isTrue);
      await _start(tester);
      _finish(channel, 0, true);
      await tester.pump();
      expect(_enabled(tester), isFalse);
      expect(_retry, findsNothing);
      _finish(channel, 1, true);
      await tester.pumpAndSettle();
      expect(_retry, findsOneWidget);
      channel.profile = 'other';
      channel.emit();
      await tester.pumpAndSettle();
      expect(_retry, findsNothing);
      expect(_enabled(tester), isTrue);
      expect(channel.connectCalls.length, connections);
      expect(directory.activeContactId?.gatewayId, 'A');
    },
  );
  for (final grants in [
    <String>[],
    ['gateway:read', 'extra:read'],
  ]) {
    testWidgets(
      'exact authorized health with required grants $grants is available',
      (tester) async {
        final channel = _Channel()
          ..caps = _caps(required: grants, granted: grants);
        final container = _container(channel);
        addTearDown(container.dispose);
        addTearDown(channel.dispose);
        await tester.pumpWidget(_app(container));
        await tester.pumpAndSettle();
        expect(_enabled(tester), isTrue);
        expect(channel.loadDetailedHealthCalls, 0);
        final button = tester.widget<IconButton>(_refresh);
        button.onPressed!();
        button.onPressed!();
        await tester.pump();
        expect(channel.loadDetailedHealthCalls, 1);
        _finish(channel, 0, false);
        await tester.pumpAndSettle();
        _noWrites(channel);
      },
    );
  }
  for (final width in [390.0, 1280.0]) {
    testWidgets(
      'refresh and retry are independently operable at $width with 200% text and reduced motion',
      (tester) async {
        tester.view.physicalSize = Size(width, 2200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        final channel = _Channel()..failed = true;
        final container = _container(channel);
        addTearDown(container.dispose);
        addTearDown(channel.dispose);
        await tester.pumpWidget(_app(container, scale: 2));
        await tester.pumpAndSettle();
        expect(find.byTooltip('Refresh gateway status'), findsOneWidget);
        expect(
          tester
              .getSemantics(_refresh)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
        );
        await tester.ensureVisible(_retry);
        expect(tester.getSemantics(_retry).label, contains('Retry'));
        expect(
          tester.getSemantics(_retry).id,
          isNot(tester.getSemantics(_refresh).id),
        );
        final retryButton = tester.widget<TextButton>(_retry);
        // Two direct activations also cover input before the next frame rebuilds.
        retryButton.onPressed!();
        retryButton.onPressed!();
        await tester.pump();
        expect(channel.loadDetailedHealthCalls, 1);
        expect(tester.widget<TextButton>(_retry).onPressed, isNull);
        expect(_enabled(tester), isFalse);
        final pendingRefresh = tester.getSemantics(_refresh);
        expect(pendingRefresh.label, 'Refresh gateway status');
        expect(pendingRefresh.flagsCollection.isButton, isTrue);
        expect(pendingRefresh.flagsCollection.isEnabled, Tristate.isFalse);
        expect(
          pendingRefresh.getSemanticsData().hasAction(SemanticsAction.tap),
          isFalse,
        );
        _finish(channel, 0, true);
        await tester.pumpAndSettle();
        final labelContext = tester.element(
          find.descendant(of: _retry, matching: find.text('Retry')),
        );
        final focus = Focus.of(labelContext);
        for (var index = 0; index < 10 && !focus.hasFocus; index++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
        }
        expect(focus.hasFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(channel.loadDetailedHealthCalls, 2);
        channel.failed = false;
        channel.emit();
        _finish(channel, 1, false);
        await tester.pumpAndSettle();
        expect(_enabled(tester), isTrue);
        expect(_retry, findsNothing);
        final refreshFocus = Focus.of(
          tester.element(
            find.descendant(of: _refresh, matching: find.byIcon(Icons.refresh)),
          ),
        );
        for (var index = 0; index < 10 && !refreshFocus.hasFocus; index++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
        }
        expect(refreshFocus.hasFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(channel.loadDetailedHealthCalls, 3);
        _finish(channel, 2, false);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        _noWrites(channel);
        semantics.dispose();
      },
    );
  }
}
