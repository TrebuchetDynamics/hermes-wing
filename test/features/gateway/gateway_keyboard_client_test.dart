import 'dart:async';
import 'dart:convert';
import 'dart:ui' show SemanticsAction, SemanticsRole, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/app_router.dart';

import '../hermes_chat/support/fake_hermes_endpoint_store.dart';

final _refresh = find.byKey(const ValueKey('gateway-refresh-button'));
final _retry = find.byKey(const ValueKey('gateway-status-inline-retry'));
final _fallback = find.text(
  'Connected. Basic health is available, but detailed status could not be loaded.',
);
const _detail = '{"status":"ok","version":"fixture-detail"}';

Future<void> _reach(WidgetTester tester, Finder control) async {
  for (var step = 0; step < 32; step++) {
    if (tester
            .getSemantics(control)
            .getSemanticsData()
            .flagsCollection
            .isFocused ==
        Tristate.isTrue) {
      return;
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  fail('Named health control never received keyboard semantic focus');
}

void main() {
  for (final width in [390.0, 1280.0]) {
    for (final mode in ['success', 'failure', 'unsupported']) {
      testWidgets(
        'actual client/router Connections keyboard $mode at $width / 200%',
        (tester) async {
          tester.view.physicalSize = Size(width, 1400);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          SharedPreferences.setMockInitialValues({});
          final reads = <Uri>[];
          final pending = <Completer<String>>[];
          var detailCalls = 0;
          final channel = HermesApiChannel(
            clientBuilder: (config) => HermesApiClient(
              config: config,
              get: (uri, _) async {
                reads.add(uri);
                switch (uri.path) {
                  case '/health':
                    return '{"status":"ok","version":"fixture-basic"}';
                  case '/v1/capabilities':
                    return jsonEncode({
                      'schema_version': 1,
                      'profile_context': {
                        'type': 'query',
                        'name': 'profile',
                        'required': true,
                        'default_profile_id': 'default',
                      },
                      'auth': {
                        'granted_scopes': ['gateway:read'],
                      },
                      'endpoints': {
                        if (mode != 'unsupported')
                          'health_detailed': {
                            'method': 'GET',
                            'path': '/health/detailed',
                            'required_scopes': ['gateway:read'],
                          },
                      },
                    });
                  case '/api/sessions':
                    return '{"data":[{"id":"fixture-session"}]}';
                  case '/api/sessions/fixture-session/messages':
                    return '{"object":"list","session_id":"fixture-session","pagination":{"offset":0,"limit":500,"order":"latest"},"data":[]}';
                  case '/health/detailed':
                    detailCalls++;
                    if (detailCalls == 1) {
                      if (mode == 'failure') {
                        throw StateError('synthetic private health metadata');
                      }
                      return _detail;
                    }
                    final gate = Completer<String>();
                    pending.add(gate);
                    return gate.future;
                  default:
                    throw StateError('Unexpected deterministic read');
                }
              },
              post: (_, _, _) => throw StateError('Unexpected mutation'),
            ),
          );
          addTearDown(channel.dispose);
          await channel.connect(baseUrl: 'http://127.0.0.1:8642');
          // Health controls are meaningful only after the production channel
          // admits the exact session's history and completes bootstrap.
          expect(channel.state.isConnected, isTrue);
          expect(channel.state.isSelectingProfile, isFalse);
          expect(channel.state.selectedProfileId, 'default');
          expect(channel.state.activeSessionId, 'fixture-session');
          expect(channel.state.messages['fixture-session'], isEmpty);
          expect(channel.state.errorMessage, isNull);
          final container = ProviderContainer(
            overrides: [
              hermesChannelProvider.overrideWithValue(channel),
              hermesEndpointStoreProvider.overrideWithValue(
                FakeHermesEndpointStore(profiles: const []),
              ),
            ],
          );
          addTearDown(container.dispose);
          final router = container.read(routerProvider)..go('/gateway');
          addTearDown(router.dispose);
          final semantics = tester.ensureSemantics();
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp.router(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                routerConfig: router,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(2),
                    disableAnimations: true,
                  ),
                  child: child!,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final directory = container.read(hermesGatewayDirectoryProvider);
          final beforeOwner = (
            channel.state.selectedProfileId,
            channel.state.activeSessionId,
            channel.state.modelInventory?.assignment.activeProvider,
            channel.state.modelInventory?.assignment.activeModel,
            channel.state.status,
            directory.managementGatewayId,
            directory.activeContactId,
          );
          final initial = reads.length;
          if (mode == 'unsupported') {
            expect(_refresh, findsNothing);
            expect(_retry, findsNothing);
            expect(_fallback, findsNothing);
            expect(
              find.text(
                'Connected. Showing basic health because this gateway does not advertise detailed status.',
              ),
              findsOneWidget,
            );
            expect(detailCalls, 0);
          } else {
            // The outer label/button wrapper must preserve the IconButton's
            // focus semantics, not just its invisible label and tap action.
            expect(
              tester.getSemantics(_refresh).label,
              'Refresh gateway status',
            );
            expect(
              tester
                  .getSemantics(_refresh)
                  .getSemanticsData()
                  .hasAction(SemanticsAction.focus),
              isTrue,
              reason: 'The enabled refresh must expose keyboard focusability',
            );
            await _reach(tester, mode == 'failure' ? _retry : _refresh);
            // Repeated activation before the rebuild exercises the synchronous
            // shared guard without sending keys to a replacement non-health focus.
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            await tester.pump();
            expect(pending, hasLength(1));
            expect(tester.widget<IconButton>(_refresh).onPressed, isNull);
            final pendingRefresh = tester.getSemantics(_refresh);
            expect(pendingRefresh.label, 'Refresh gateway status');
            expect(pendingRefresh.flagsCollection.isButton, isTrue);
            expect(pendingRefresh.flagsCollection.isEnabled, Tristate.isFalse);
            expect(
              pendingRefresh.getSemanticsData().role,
              SemanticsRole.none,
              reason: 'Decorative spinner must not replace the button role',
            );
            expect(
              pendingRefresh.getSemanticsData().hasAction(SemanticsAction.tap),
              isFalse,
            );
            expect(pending, hasLength(1));
            pending[0].completeError(
              StateError('synthetic private health metadata'),
            );
            await tester.pumpAndSettle();
            expect(_fallback, findsOneWidget);
            expect(_retry, findsOneWidget);
            expect(find.textContaining('synthetic private'), findsNothing);
            await _reach(tester, _retry);
            await tester.sendKeyEvent(LogicalKeyboardKey.space);
            await tester.sendKeyEvent(LogicalKeyboardKey.space);
            await tester.pump();
            expect(pending, hasLength(2));
            expect(tester.widget<TextButton>(_retry).onPressed, isNull);
            expect(_fallback, findsOneWidget);
            expect(pending, hasLength(2));
            pending[1].complete(_detail);
            await tester.pumpAndSettle();
            expect(_fallback, findsNothing);
            expect(_retry, findsNothing);
            expect(find.text('fixture-detail'), findsOneWidget);
            await _reach(tester, _refresh);
            expect(
              tester
                  .getSemantics(_refresh)
                  .getSemanticsData()
                  .flagsCollection
                  .isFocused,
              Tristate.isTrue,
            );
            expect(detailCalls, 3);
            expect(reads.skip(initial).map((uri) => uri.path), [
              '/health/detailed',
              '/health/detailed',
            ]);
          }
          expect(
            reads
                .where((uri) => uri.path == '/health/detailed')
                .every((uri) => uri.queryParameters.isEmpty),
            isTrue,
          );
          expect((
            channel.state.selectedProfileId,
            channel.state.activeSessionId,
            channel.state.modelInventory?.assignment.activeProvider,
            channel.state.modelInventory?.assignment.activeModel,
            channel.state.status,
            directory.managementGatewayId,
            directory.activeContactId,
          ), beforeOwner);
          expect(tester.takeException(), isNull);
          semantics.dispose();
        },
      );
    }
  }
}
