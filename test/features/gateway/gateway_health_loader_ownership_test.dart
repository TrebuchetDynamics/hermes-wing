import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/gateway/screens/gateway_screen.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_endpoint_store.dart';
import '../hermes_chat/support/fake_hermes_gateway_directory.dart';

const _detail =
    '{"status":"ok","version":"detail-fixture","gateway_state":"running"}';
const _privateError = 'synthetic private health metadata';
final _refresh = find.byKey(const ValueKey('gateway-refresh-button'));
final _retry = find.byKey(const ValueKey('gateway-status-inline-retry'));
final _fallback = find.text(
  'Connected. Basic health is available, but detailed status could not be loaded.',
);
bool _enabled(WidgetTester tester) =>
    tester.widget<IconButton>(_refresh).onPressed != null;

class _Fixture {
  _Fixture({this.bootstrapFails = false});
  bool bootstrapFails;
  int bootstrapCalls = 0;
  int bootstrapHealthCalls = 0;
  final reads = <String>[];
  final pending = <Completer<String>>[];
  late final HermesApiChannel channel;
  late final HermesGatewayDirectory directory;
  late final ProviderContainer container;

  Future<void> connect() async {
    channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          reads.add(uri.path);
          switch (uri.path) {
            case '/health':
              bootstrapCalls++;
              return '{"status":"ok","version":"basic-fixture"}';
            case '/v1/capabilities':
              return jsonEncode({
                'schema_version': 1,
                'auth': {
                  'type': 'bearer',
                  'required': true,
                  'granted_scopes': ['gateway:read'],
                },
                'endpoints': {
                  'health_detailed': {
                    'method': 'GET',
                    'path': '/health/detailed',
                    'required_scopes': ['gateway:read'],
                  },
                },
              });
            case '/api/sessions':
              return '{"sessions":[]}';
            case '/health/detailed':
              if (bootstrapHealthCalls < bootstrapCalls) {
                bootstrapHealthCalls++;
                if (bootstrapFails) throw StateError(_privateError);
                return _detail;
              }
              final gate = Completer<String>();
              pending.add(gate);
              return gate.future;
            default:
              throw StateError('Unexpected fixture read');
          }
        },
        post: (_, _, _) async => throw StateError('Mutation forbidden'),
      ),
    );
    directory = HermesGatewayDirectory(
      store: FakeHermesEndpointStore(
        profiles: const [
          HermesEndpointConfig(
            id: 'A',
            label: 'Fixture A',
            baseUrl: 'http://localhost:8642',
          ),
          HermesEndpointConfig(
            id: 'B',
            label: 'Fixture B',
            baseUrl: 'http://localhost:8643',
          ),
        ],
      ),
      cache: FakeGatewayContactCache(),
      loader: FakeGatewaySummaryLoader({
        'A': gatewaySummary([]),
        'B': gatewaySummary([]),
      }),
      activeChannel: channel,
    );
    await directory.refresh();
    await directory.activateGateway('A');
    expect(channel.state.isConnected, isTrue);
    expect(directory.activeContactId?.gatewayId, 'A');
    container = ProviderContainer(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
      ],
    );
  }

  Widget get app => UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const GatewayScreen(),
    ),
  );
  void finish(int index, {required bool fail, String response = _detail}) {
    if (fail) {
      pending[index].completeError(StateError(_privateError));
    } else {
      pending[index].complete(response);
    }
  }

  void dispose() {
    container.dispose();
    channel.dispose();
  }

  void assertReadOnly(int explicitReads) {
    expect(
      reads.where((path) => path == '/health/detailed').length,
      explicitReads + 1,
    );
    expect(reads.where((path) => path != '/health/detailed'), [
      '/health',
      '/v1/capabilities',
      '/api/sessions',
    ]);
    expect(directory.activeContactId?.gatewayId, 'A');
    expect(channel.state.activeSessionId, isNull);
    expect(channel.state.selectedProfileId, isNull);
    expect(find.textContaining(_privateError), findsNothing);
  }
}

Future<void> _start(WidgetTester tester) async {
  await tester.tap(_refresh);
  await tester.pump();
  expect(_enabled(tester), isFalse);
}

Future<void> _transfer(
  WidgetTester tester,
  _Fixture fixture,
  bool sameFrame,
) async {
  fixture.directory.selectManagementGateway('B');
  if (!sameFrame) {
    await tester.pump();
    expect(_refresh, findsNothing);
  }
  fixture.directory.selectManagementGateway('A');
  await tester.pump();
  expect(_enabled(tester), isTrue);
}

void main() {
  testWidgets(
    'actual loader reconnect bootstrap failure is adopted by the new connected owner',
    (tester) async {
      final fixture = _Fixture();
      await fixture.connect();
      addTearDown(fixture.dispose);
      await tester.pumpWidget(fixture.app);
      await tester.pumpAndSettle();
      expect(_retry, findsNothing);
      fixture.bootstrapFails = true;
      await fixture.channel.connect(baseUrl: 'http://localhost:8642');
      await tester.pumpAndSettle();
      expect(_retry, findsOneWidget);
      expect(_fallback, findsOneWidget);
      expect(find.text('basic-fixture'), findsOneWidget);
      expect(fixture.bootstrapHealthCalls, 2);
      expect(fixture.pending, isEmpty);
      expect(find.textContaining(_privateError), findsNothing);
    },
  );
  for (final oldFirst in [false, true]) {
    testWidgets(
      'actual loader stale failure cannot replace newer success, oldFirst=$oldFirst',
      (tester) async {
        final fixture = _Fixture();
        await fixture.connect();
        addTearDown(fixture.dispose);
        await tester.pumpWidget(fixture.app);
        await tester.pumpAndSettle();
        await _start(tester);
        await _transfer(tester, fixture, true);
        await _start(tester);
        if (oldFirst) {
          fixture.finish(0, fail: true);
          await tester.pump();
          expect(_enabled(tester), isFalse);
          expect(_retry, findsNothing);
        }
        fixture.finish(
          1,
          fail: false,
          response: '{"status":"ok","version":"new-owner-success"}',
        );
        await tester.pumpAndSettle();
        if (!oldFirst) {
          fixture.finish(0, fail: true);
          await tester.pumpAndSettle();
        }
        expect(find.text('new-owner-success'), findsOneWidget);
        expect(_retry, findsNothing);
        expect(_fallback, findsNothing);
        expect(_enabled(tester), isTrue);
        fixture.assertReadOnly(2);
      },
    );
  }
  for (final sameFrame in [false, true]) {
    for (final shown in [false, true]) {
      testWidgets(
        'actual loader ${shown ? 'shown' : 'late'} error is owner-bound, sameFrame=$sameFrame',
        (tester) async {
          final fixture = _Fixture();
          await fixture.connect();
          addTearDown(fixture.dispose);
          await tester.pumpWidget(fixture.app);
          await tester.pumpAndSettle();
          await _start(tester);
          if (shown) {
            fixture.finish(0, fail: true);
            await tester.pumpAndSettle();
            expect(_retry, findsOneWidget);
            expect(_fallback, findsOneWidget);
            expect(
              fixture.channel.state.optionalResourceErrors.containsKey(
                HermesOptionalResource.detailedHealth,
              ),
              isTrue,
            );
          }
          await _transfer(tester, fixture, sameFrame);
          if (!shown) {
            fixture.finish(0, fail: true);
            await tester.pumpAndSettle();
          }
          expect(_retry, findsNothing);
          expect(
            _fallback,
            findsNothing,
            reason:
                'A shared-loader error may not replace the new owner presentation',
          );
          expect(find.text('detail-fixture'), findsOneWidget);
          // Shared authoritative error is untouched. No automatic retry/read.
          expect(
            fixture.channel.state.optionalResourceErrors.containsKey(
              HermesOptionalResource.detailedHealth,
            ),
            isTrue,
          );
          fixture.assertReadOnly(1);
          await _start(tester);
          fixture.finish(1, fail: true);
          await tester.pumpAndSettle();
          expect(_retry, findsOneWidget);
          final retry = tester.widget<TextButton>(_retry);
          retry.onPressed!();
          retry.onPressed!();
          await tester.pump();
          expect(fixture.pending.length, 3);
          expect(tester.widget<TextButton>(_retry).onPressed, isNull);
          fixture.finish(2, fail: false);
          await tester.pumpAndSettle();
          expect(_retry, findsNothing);
          expect(_fallback, findsNothing);
          fixture.assertReadOnly(3);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final oldFirst in [false, true]) {
    for (final oldFails in [false, true]) {
      testWidgets(
        'actual loader stale ${oldFails ? 'error' : 'success'} cannot change newer failure, oldFirst=$oldFirst',
        (tester) async {
          final fixture = _Fixture();
          await fixture.connect();
          addTearDown(fixture.dispose);
          await tester.pumpWidget(fixture.app);
          await tester.pumpAndSettle();
          await _start(tester);
          await _transfer(tester, fixture, true);
          await _start(tester);
          if (oldFirst) {
            fixture.finish(0, fail: oldFails);
            await tester.pump();
            expect(_enabled(tester), isFalse);
            expect(_retry, findsNothing);
            expect(_fallback, findsNothing);
          }
          fixture.finish(1, fail: true);
          await tester.pumpAndSettle();
          expect(_retry, findsOneWidget);
          expect(_fallback, findsOneWidget);
          if (!oldFirst) {
            fixture.finish(0, fail: oldFails);
            await tester.pumpAndSettle();
          }
          expect(_retry, findsOneWidget);
          expect(_fallback, findsOneWidget);
          expect(_enabled(tester), isTrue);
          fixture.assertReadOnly(2);
        },
      );
    }
  }
  testWidgets(
    'actual loader current bootstrap failure retains basic fallback and explicit retry',
    (tester) async {
      final fixture = _Fixture(bootstrapFails: true);
      await fixture.connect();
      addTearDown(fixture.dispose);
      await tester.pumpWidget(fixture.app);
      await tester.pumpAndSettle();
      expect(_retry, findsOneWidget);
      expect(_fallback, findsOneWidget);
      expect(find.text('basic-fixture'), findsOneWidget);
      fixture.assertReadOnly(0);
      tester.widget<TextButton>(_retry).onPressed!();
      await tester.pump();
      fixture.finish(0, fail: false);
      await tester.pumpAndSettle();
      expect(_retry, findsNothing);
      expect(_fallback, findsNothing);
      expect(find.text('detail-fixture'), findsOneWidget);
      fixture.assertReadOnly(1);
    },
  );
}
