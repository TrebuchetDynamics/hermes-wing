import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/channel/hermes_detached_run_store.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/core/hermes/client/hermes_api_config.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/core/hermes/shared/hermes_api_http.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_endpoint_store.dart';

const _origin = 'https://recovery.example';
const _profile = 'oracle-coder';
const _session = 'remembered-A';
const _run = 'oracle-run';
const _prompt = 'Synthetic completion probe';
const _answer = 'Synthetic canonical result';
const _contact = GatewayContactId(gatewayId: 'oracle', profileId: _profile);

class _OwnerReadDenied implements HermesApiStatusException {
  const _OwnerReadDenied(this.statusCode);
  @override
  final int statusCode;
}

// Serialized fixture storage outlives both client/provider generations. This
// proves restoration wiring, not OS storage or platform keystore durability.
class _DurableSlot {
  String rows = '[]';
}

class _LeaseStore implements HermesDetachedRunStore {
  _LeaseStore(this.slot);
  final _DurableSlot slot;
  @override
  Object get coordinationKey => slot;
  @override
  Future<List<HermesDetachedRunLease>> load() async => [
    for (final row in jsonDecode(slot.rows) as List)
      HermesDetachedRunLease.fromJson((row as Map).cast<String, Object?>()),
  ];
  @override
  Future<void> save(List<HermesDetachedRunLease> leases) async {
    slot.rows = jsonEncode([for (final lease in leases) lease.toJson()]);
  }
}

// Deterministic backend at the existing HTTP transport seam. It never calls a
// channel/UI setter, and completion remains possible with no client alive.
class _Backend {
  _Backend({this.denialStatus, this.bootstrapDenial = false});
  final int? denialStatus;
  final bool bootstrapDenial;
  final requests = <({String method, Uri uri})>[];
  final events = StreamController<String>();
  bool submitted = false;
  bool completed = false;
  bool clientAbsent = false;
  bool denyOwnerReads = false;
  final deniedReads = <Uri>[];
  Completer<void>? historyGate;
  final terminalHistoryRequested = Completer<void>();
  String get status =>
      completed ? 'completed' : (submitted ? 'running' : 'idle');

  Map<String, int> get mutations => {
    'runStarts': requests
        .where((r) => r.method == 'POST' && r.uri.path == '/v1/runs')
        .length,
    'sessionCreates': requests
        .where((r) => r.method != 'GET' && r.uri.path == '/api/sessions')
        .length,
    'otherMutations': requests
        .where(
          (r) =>
              r.method != 'GET' &&
              r.uri.path != '/v1/runs' &&
              r.uri.path != '/api/sessions',
        )
        .length,
  };

  void completeWhileAbsent() {
    expect(clientAbsent, isTrue);
    expect(submitted, isTrue);
    expect(completed, isFalse);
    completed = true;
  }

  HermesApiClient client(HermesApiConfig config) => HermesApiClient(
    config: config,
    get: (uri, headers) async {
      _record('GET', uri);
      _authorize(uri, headers);
      switch (uri.path) {
        case '/health':
          return '{"status":"ok"}';
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
              'granted_scopes': [
                'profiles:read',
                'sessions:read',
                'chat:write',
              ],
            },
            'features': {
              'run_submission': true,
              'run_status': true,
              'run_events_sse': true,
              'session_chat_streaming': true,
            },
            'endpoints': {
              'profiles': {
                'method': 'GET',
                'path': '/api/profiles',
                'required_scopes': ['profiles:read'],
              },
              'session': {
                'method': 'GET',
                'path': '/api/sessions/{session_id}',
                'required_scopes': ['sessions:read'],
              },
              'session_messages': {
                'method': 'GET',
                'path': '/api/sessions/{session_id}/messages',
                'required_scopes': ['sessions:read'],
              },
              'runs': {'method': 'POST', 'path': '/v1/runs'},
              'run_status': {'method': 'GET', 'path': '/v1/runs/{run_id}'},
              'run_events': {
                'method': 'GET',
                'path': '/v1/runs/{run_id}/events',
              },
              'session_chat_stream': {
                'method': 'POST',
                'path': '/api/sessions/{session_id}/chat/stream',
              },
            },
          });
        case '/api/profiles':
          return jsonEncode({
            'data': [
              {'id': _profile, 'name': 'Oracle coder', 'revision': 'r1'},
            ],
          });
        case '/api/sessions':
          if (uri.queryParameters['profile'] == 'default') {
            return '{"data":[{"id":"default-foreign","source":"api_server"}]}';
          }
          // A newer session tempts accidental startup substitution.
          return jsonEncode({
            'data': [
              {'id': 'newer-B', 'source': 'api_server'},
              {
                'id': _session,
                'source': 'api_server',
                'title': 'Oracle conversation',
              },
            ],
          });
        case '/api/sessions/remembered-A':
          return jsonEncode({
            'session': {'id': _session, 'source': 'api_server'},
          });
        case '/api/sessions/remembered-A/messages':
          if (completed) {
            expect(
              requests.any((r) => r.uri.path == '/v1/runs/$_run'),
              isTrue,
              reason:
                  'Park canonical hydration after authoritative terminal status',
            );
            if (!terminalHistoryRequested.isCompleted) {
              terminalHistoryRequested.complete();
            }
            await historyGate?.future;
          }
          return jsonEncode({
            'object': 'list',
            'session_id': _session,
            'data': [
              if (submitted)
                {
                  'id': 'canonical-user',
                  'session_id': _session,
                  'role': 'user',
                  'content': _prompt,
                },
              if (completed)
                {
                  'id': 'canonical-assistant',
                  'session_id': _session,
                  'role': 'assistant',
                  'content': _answer,
                },
            ],
          });
        case '/v1/runs/oracle-run':
          return jsonEncode({
            'run_id': _run,
            'session_id': _session,
            'status': status,
          });
        default:
          throw StateError('Unexpected fixture read');
      }
    },
    post: (uri, headers, body) async {
      _record('POST', uri);
      _authorize(uri, headers);
      expect(
        uri.path,
        '/v1/runs',
        reason:
            'No session creation, send fallback, Stop or approval is allowed',
      );
      expect(submitted, isFalse, reason: 'Recovery must not resubmit');
      final payload = jsonDecode(body) as Map;
      expect(payload['session_id'], _session);
      submitted = true;
      return jsonEncode({
        'object': 'hermes.run',
        'run': {'id': _run, 'session_id': _session},
      });
    },
    getStream: (uri, headers) {
      _record('GET', uri);
      _authorize(uri, headers);
      expect(uri.path, '/v1/runs/$_run/events');
      return events.stream;
    },
    postStream: (uri, headers, body) {
      _record('POST', uri);
      _authorize(uri, headers);
      throw StateError('Chat fallback/replay is forbidden');
    },
    patch: (uri, headers, body) async => _rejectMutation('PATCH', uri),
    put: (uri, headers, body) async => _rejectMutation('PUT', uri),
    delete: (uri, headers) async => _rejectMutation('DELETE', uri),
  );

  String _rejectMutation(String method, Uri uri) {
    _record(method, uri);
    throw StateError('Unexpected fixture mutation');
  }

  void _record(String method, Uri uri) {
    // Count attempts before authorization or route/owner assertions can reject.
    requests.add((method: method, uri: uri));
    expect(clientAbsent, isFalse, reason: 'No client transport during absence');
    expect(uri.origin, _origin);
    if (uri.path != '/health' &&
        uri.path != '/v1/capabilities' &&
        uri.path != '/api/profiles' &&
        uri.path != '/api/sessions') {
      expect(uri.queryParameters['profile'], _profile);
    }
  }

  void _authorize(Uri uri, Map<String, String> headers) {
    expect(
      headers[hermesApiAuthorizationHeader] ==
          hermesApiBearerAuthorization('synthetic-oracle-authority'),
      isTrue,
      reason: 'Transport uses the saved synthetic authority without logging it',
    );
    // Required production bootstrap read, before owner-resource reconciliation.
    if (denyOwnerReads && bootstrapDenial && uri.path == '/v1/capabilities') {
      deniedReads.add(uri);
      expect(denialStatus, anyOf(401, 403));
      throw _OwnerReadDenied(denialStatus!);
    }
    // Resource-only controls leave discovery and inventory readable, rejecting
    // saved synthetic authority through the real HTTP error classification.
    if (denyOwnerReads &&
        !bootstrapDenial &&
        (uri.path.startsWith('/v1/runs/') ||
            uri.path.startsWith('/api/sessions/'))) {
      deniedReads.add(uri);
      expect(denialStatus, anyOf(401, 403));
      throw _OwnerReadDenied(denialStatus!);
    }
  }
}

Future<void> _until(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 100 && !ready(); i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(ready(), isTrue, reason: 'Bounded deterministic fixture wait');
}

void main() {
  for (final control in [
    (denialStatus: null, bootstrapDenial: false),
    (denialStatus: 401, bootstrapDenial: false),
    (denialStatus: 403, bootstrapDenial: false),
    (denialStatus: 401, bootstrapDenial: true),
    (denialStatus: 403, bootstrapDenial: true),
  ]) {
    final denialStatus = control.denialStatus;
    testWidgets(
      control.bootstrapDenial
          ? 'bootstrap capabilities HTTP $denialStatus denied recreated client retains exact owner without replay'
          : denialStatus != null
          ? 'HTTP $denialStatus denied recreated client retries exact owner without replay'
          : 'absent client completion restores canonical history without replay',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final backend = _Backend(
          denialStatus: denialStatus,
          bootstrapDenial: control.bootstrapDenial,
        );
        final slot = _DurableSlot();
        final endpoints = FakeHermesEndpointStore(
          profiles: const [
            HermesEndpointConfig(
              id: 'oracle',
              baseUrl: _origin,
              apiKey: 'synthetic-oracle-authority',
            ),
          ],
        );
        await GatewayContactCache().saveSelection(
          const GatewayContactSelection(
            contactId: _contact,
            sessionId: _session,
          ),
        );

        ProviderContainer newClient() => ProviderContainer(
          overrides: [
            hermesChannelProvider.overrideWith((ref) {
              final channel = HermesApiChannel(
                clientBuilder: backend.client,
                detachedRunStore: _LeaseStore(slot),
              );
              ref.onDispose(channel.dispose);
              return channel;
            }),
            hermesEndpointStoreProvider.overrideWithValue(endpoints),
            hermesGatewaySummaryLoaderProvider.overrideWithValue(
              HermesApiGatewaySummaryLoader(clientBuilder: backend.client),
            ),
            hermesVoiceCaptureServiceProvider.overrideWithValue(null),
            hermesTextToSpeechServiceProvider.overrideWithValue(null),
          ],
        );
        Future<void> mount(ProviderContainer container) => tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const HermesChatScreen(),
            ),
          ),
        );

        final first = newClient();
        await mount(first);
        final firstChannel = first.read(hermesChannelProvider);
        await _until(
          tester,
          () =>
              !first.read(hermesGatewayDirectoryProvider).isActivating &&
              firstChannel.state.activeSessionId == _session,
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('hermes-composer-field')),
          _prompt,
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
        await _until(
          tester,
          () =>
              jsonDecode(slot.rows).isNotEmpty &&
              backend.requests.any((r) => r.uri.path.endsWith('/events')),
        );
        expect(firstChannel.state.isSessionStreaming(_session), isTrue);
        final lease = (await _LeaseStore(slot).load()).single;
        expect(
          (lease.baseUrl, lease.profileId, lease.sessionId, lease.runId),
          (_origin, _profile, _session, _run),
        );
        expect(backend.completed, isFalse);
        expect(backend.status, 'running');
        expect(backend.mutations, {
          'runStarts': 1,
          'sessionCreates': 0,
          'otherMutations': 0,
        });

        await tester.pumpWidget(const SizedBox.shrink());
        first.dispose();
        await backend.events.close();
        await tester.pump();
        final persistedLease = slot.rows;
        final preferences = await SharedPreferences.getInstance();
        const selectionKey = 'wing.hermes.gateway_contact_selection.v1';
        final persistedSelection = preferences.getString(selectionKey);
        expect(persistedSelection, isNotNull);
        backend.clientAbsent = true;
        final absentRequestCount = backend.requests.length;
        backend.completeWhileAbsent();
        expect(backend.status, 'completed');
        await tester.pump();
        expect(backend.requests.length, absentRequestCount);
        expect((await _LeaseStore(slot).load()).single.runId, _run);
        final before = backend.mutations;
        final readStart = backend.requests.length;
        backend.historyGate = Completer<void>();
        backend.clientAbsent = false;
        backend.denyOwnerReads = denialStatus != null;

        final restored = newClient();
        addTearDown(restored.dispose);
        await mount(restored);
        if (denialStatus != null) {
          final directory = restored.read(hermesGatewayDirectoryProvider);
          final channel = restored.read(hermesChannelProvider);
          Future<void> expectDeniedOwner() async {
            await _until(
              tester,
              () =>
                  !directory.isActivating &&
                  directory.restorationFailure != null,
            );
            await tester.pumpAndSettle();
            expect(
              directory.restorationFailure,
              GatewaySessionRestorationFailure.authentication,
            );
            expect(directory.activeContactId, _contact);
            expect(directory.restoringSessionId, _session);
            expect(channel.state.activeSessionId, isNull);
            expect(channel.state.messages, isEmpty);
            expect(slot.rows, persistedLease);
            final retainedLease = (await _LeaseStore(slot).load()).single;
            expect(
              (
                retainedLease.baseUrl,
                retainedLease.profileId,
                retainedLease.sessionId,
                retainedLease.runId,
              ),
              (_origin, _profile, _session, _run),
            );
            final remembered = await GatewayContactCache().loadSelection();
            expect(remembered!.contactId, _contact);
            expect(remembered.sessionId, _session);
            expect(preferences.getString(selectionKey), persistedSelection);
            expect(backend.mutations, before);
            expect(backend.terminalHistoryRequested.isCompleted, isFalse);
            expect(find.text(_answer), findsNothing);
            expect(
              find.byKey(const ValueKey('hermes-composer-field')),
              findsNothing,
            );
            expect(
              find.byKey(const ValueKey('hermes-send-button')),
              findsNothing,
            );
            expect(
              find.byKey(const ValueKey('hermes-session-restoration')),
              findsOneWidget,
            );
            expect(endpoints.clearCalls, 0);
            expect(endpoints.deleteProfileCalls, isEmpty);
            expect(endpoints.saveCalls, isEmpty);
            expect(endpoints.saveAllCalls, isEmpty);
          }

          await expectDeniedOwner();
          final firstDeniedCount = backend.deniedReads.length;
          void expectBootstrapOnly() {
            if (!control.bootstrapDenial) return;
            expect(
              channel.state.connectionFailureKind,
              HermesConnectionFailureKind.authentication,
            );
            expect(
              backend.requests
                  .skip(readStart)
                  .every(
                    (r) =>
                        r.method == 'GET' &&
                        const {
                          '/health',
                          '/v1/capabilities',
                        }.contains(r.uri.path),
                  ),
              isTrue,
              reason: 'Bootstrap rejection precedes inventory and owner reads',
            );
          }

          expectBootstrapOnly();
          expect(firstDeniedCount, greaterThan(0));
          final retry = find.byKey(
            const ValueKey('hermes-session-restoration-retry'),
          );
          await tester.tap(retry);
          await tester.pump();
          await expectDeniedOwner();
          expect(backend.deniedReads.length, greaterThan(firstDeniedCount));
          expectBootstrapOnly();
          debugPrint(
            'M2 ${control.bootstrapDenial ? 'bootstrap' : 'resource'} HTTP $denialStatus denial oracle: initial denied reads=$firstDeniedCount; '
            'after public Retry=${backend.deniedReads.length}; '
            'lease/remembered owner unchanged=true; mutation delta=0',
          );
          expect(
            backend.deniedReads.every(
              (uri) =>
                  uri.origin == _origin &&
                  (control.bootstrapDenial
                      ? uri.path == '/v1/capabilities'
                      : uri.queryParameters['profile'] == _profile &&
                            const {
                              '/v1/runs/oracle-run',
                              '/api/sessions/remembered-A',
                              '/api/sessions/remembered-A/messages',
                            }.contains(uri.path)),
            ),
            isTrue,
          );

          // Explicit synthetic server authority restoration does not submit work.
          // Use the same public production Retry, not channel state injection.
          backend.denyOwnerReads = false;
          await tester.tap(retry);
          await tester.pump();
        }
        await _until(
          tester,
          () => backend.terminalHistoryRequested.isCompleted,
        );
        expect(restored.read(hermesChannelProvider).state.messages, isEmpty);
        expect(slot.rows, persistedLease);
        expect(
          (await GatewayContactCache().loadSelection())!.sessionId,
          _session,
        );
        expect(
          (await _LeaseStore(slot).load()).single.runId,
          _run,
          reason: 'Lease cannot clear before canonical hydration',
        );
        backend.historyGate!.complete();
        final restoredChannel = restored.read(hermesChannelProvider);
        await _until(
          tester,
          () =>
              jsonDecode(slot.rows).isEmpty &&
              !restored.read(hermesGatewayDirectoryProvider).isActivating,
        );
        await tester.pumpAndSettle();
        final state = restoredChannel.state;
        expect(state.connectedBaseUrl, _origin);
        expect(state.selectedProfileId, _profile);
        expect(state.activeSessionId, _session);
        expect(state.hasUnreconciledRun, isFalse);
        expect(state.isSessionStreaming(_session), isFalse);
        expect(state.errorMessage, isNull);
        expect(
          state.activeMessages.every((m) => m.sessionId == _session),
          isTrue,
        );
        expect(
          state.activeMessages
              .map((m) => (m.id, m.author, m.text, m.status))
              .toList(),
          [
            (
              'canonical-user',
              HermesTurnAuthor.user,
              _prompt,
              HermesTurnStatus.completed,
            ),
            (
              'canonical-assistant',
              HermesTurnAuthor.assistant,
              _answer,
              HermesTurnStatus.completed,
            ),
          ],
        );
        expect(find.text(_answer), findsOneWidget);
        expect(find.text(_prompt), findsOneWidget);
        expect(
          find.byKey(const ValueKey('hermes-session-restoration')),
          findsNothing,
        );
        expect(
          tester
              .widget<TextField>(
                find.byKey(const ValueKey('hermes-composer-field')),
              )
              .enabled,
          isTrue,
        );
        final selection = await GatewayContactCache().loadSelection();
        expect(selection!.contactId, _contact);
        expect(selection.sessionId, _session);
        final recoveryReads = backend.requests.skip(readStart).toList();
        expect(recoveryReads.every((r) => r.method == 'GET'), isTrue);
        expect(
          recoveryReads.every(
            (r) => const {
              '/health',
              '/v1/capabilities',
              '/api/profiles',
              '/api/sessions',
              '/api/sessions/remembered-A',
              '/api/sessions/remembered-A/messages',
              '/v1/runs/oracle-run',
            }.contains(r.uri.path),
          ),
          isTrue,
          reason:
              'No foreign history/session, event reattach or mutation route',
        );
        expect(
          recoveryReads.any((r) => r.uri.path == '/v1/runs/$_run'),
          isTrue,
        );
        expect(
          recoveryReads.any(
            (r) => r.uri.path == '/api/sessions/$_session/messages',
          ),
          isTrue,
        );
        expect(backend.mutations, before);
        debugPrint(
          'M2 oracle counters: ${jsonEncode(backend.mutations)}; recovery mutation delta=0; exact owner/history=true',
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
      variant: TargetPlatformVariant.only(TargetPlatform.linux),
    );
  }
}
