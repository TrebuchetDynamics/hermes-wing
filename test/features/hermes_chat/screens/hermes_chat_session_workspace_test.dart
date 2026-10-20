import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/core/hermes/setup/secure_hermes_detached_run_store.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../gateways/hermes_gateway_session_restoration_test.dart'
    show RestorationHarness;
import '../../../../integration_test/support/local_serve_chat_fixture.dart';
import '../../../../integration_test/support/local_serve_read_fixture.dart';
import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_hermes_gateway_directory.dart';

const _origin = 'http://fake-hermes:8642';
const _composer = ValueKey('hermes-composer-field');
const _sessions = [
  HermesSession(id: 'a', title: 'Conversation A', source: 'fake'),
  HermesSession(id: 'b', title: 'Conversation B', source: 'fake'),
];

ValueKey<(String, ({String gatewayId, String? profileId, String sessionId}))>
tab(
  String id, {
  String profile = 'default',
  String gateway = _origin,
  bool close = false,
}) => ValueKey((
  close ? 'hermes-workspace-close' : 'hermes-workspace-tab',
  (gatewayId: gateway, profileId: profile, sessionId: id),
));

class WorkspaceChannel extends FakeHermesChannel {
  WorkspaceChannel({bool supportsStop = true})
    : super(
        sessions: _sessions,
        sessionId: 'a',
        selectedProfileId: 'default',
        capabilities: HermesCapabilityDocument.fromJson({
          'schema_version': 1,
          'features': {
            'run_stop': supportsStop,
            'run_status': true,
            'run_submission': true,
            'run_events_sse': true,
          },
          'auth': {'granted_scopes': <String>[]},
          'endpoints': {
            'runs': {'method': 'POST', 'path': '/v1/runs'},
            'run_events': {'method': 'GET', 'path': '/v1/runs/{run_id}/events'},
            'run_stop': {'method': 'POST', 'path': '/v1/runs/{run_id}/stop'},
            'run_status': {'method': 'GET', 'path': '/v1/runs/{run_id}'},
          },
        }),
      );

  final listeners = <VoidCallback>{};
  @override
  void addListener(VoidCallback listener) {
    listeners.add(listener);
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listeners.remove(listener);
    super.removeListener(listener);
  }

  Completer<bool>? stopGate;
  bool reconciling = false;
  bool nativeServe = false;
  @override
  HermesChannelState get state => super.state.copyWith(
    hasUnreconciledRun: reconciling,
    isServeReadOnly: nativeServe,
  );
  final stoppedTargets = <HermesTurnInterruptionTarget>[];

  @override
  Future<bool> stopTurn(HermesTurnInterruptionTarget target) async {
    stoppedTargets.add(target);
    reconciling = true;
    notifyListeners();
    try {
      final confirmed = await (stopGate?.future ?? Future.value(true));
      if (!target.matches(activeTurnInterruptionTarget)) return false;
      if (confirmed) stopActiveTurn();
      return confirmed;
    } finally {
      reconciling = false;
      notifyListeners();
    }
  }
}

Future<void> mount(
  WidgetTester tester,
  HermesChannel channel, {
  HermesGatewayDirectory? directory,
  ValueNotifier<Widget>? page,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesEndpointStoreProvider.overrideWithValue(
          FakeHermesEndpointStore(),
        ),
        hermesGatewayDirectoryProvider.overrideWith(
          (_) =>
              directory ??
              directoryFor(
                configs: const [],
                loader: FakeGatewaySummaryLoader({}),
                activeChannel: channel as FakeHermesChannel,
              ),
        ),
        hermesVoiceCaptureServiceProvider.overrideWithValue(null),
        hermesTextToSpeechServiceProvider.overrideWithValue(null),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: page == null
            ? const HermesChatScreen()
            : ValueListenableBuilder<Widget>(
                valueListenable: page,
                builder: (_, child, _) => child,
              ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

TextEditingController composer(WidgetTester tester) =>
    tester.widget<TextField>(find.byKey(_composer)).controller!;

Future<void> cycle(WidgetTester tester, {bool reverse = false}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  if (reverse) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  if (reverse) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

class _TwoSessionNativeFixture extends LocalServeChatFixture {
  @override
  Future<bool> handleExtra(HttpRequest request) async {
    if (request.method == 'GET' &&
        request.uri.path == '/api/sessions' &&
        request.headers.value('Authorization') ==
            'Bearer ${LocalServeReadFixture.token}') {
      final profile = request.uri.queryParameters['profile']!;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'sessions': [
            session('$profile-session', profile),
            session('second-$profile', profile),
          ],
          'total': 2,
          'offset': 0,
          'limit': int.parse(request.uri.queryParameters['limit']!),
          'storage': {},
        }),
      );
      await request.response.close();
      return true;
    }
    return super.handleExtra(request);
  }
}

class WorkspaceRecoveryChannel extends HermesApiChannel {
  WorkspaceRecoveryChannel({required super.clientBuilder})
    : super(
        detachedRunStore: SecureHermesDetachedRunStore(),
        runStatusReconcileInterval: Duration.zero,
      );

  int recoverySettlements = 0;
  @override
  Future<void> reconcileActiveSession() async {
    try {
      await super.reconcileActiveSession();
    } finally {
      recoverySettlements++;
    }
  }
}

class WorkspaceRecoveryFixture {
  final streams = <String, StreamController<String>>{};
  final mutations = <String>[];
  bool lostA = false;
  bool canonicalA = false;
  Completer<String>? statusA;
  bool statusAEntered = false;
  late final channel = WorkspaceRecoveryChannel(
    clientBuilder: (config) => HermesApiClient(
      config: config,
      get: (uri, _) async {
        if (uri.path == '/health') return '{"status":"ok"}';
        if (uri.path == '/v1/capabilities') {
          return jsonEncode({
            'schema_version': 1,
            'profile_context': {
              'type': 'query',
              'name': 'profile',
              'required': true,
              'default_profile_id': 'default',
            },
            'features': {
              'run_submission': true,
              'run_events_sse': true,
              'run_status': true,
              'run_stop': true,
            },
            'endpoints': {
              'runs': {'method': 'POST', 'path': '/v1/runs'},
              'run_events': {
                'method': 'GET',
                'path': '/v1/runs/{run_id}/events',
              },
              'run_status': {'method': 'GET', 'path': '/v1/runs/{run_id}'},
              'run_stop': {'method': 'POST', 'path': '/v1/runs/{run_id}/stop'},
              'session_messages': {
                'method': 'GET',
                'path': '/api/sessions/{session_id}/messages',
              },
            },
          });
        }
        if (uri.path == '/api/sessions') {
          return jsonEncode({
            'data': [
              for (final s in _sessions)
                {'id': s.id, 'title': s.title, 'source': 'synthetic'},
            ],
          });
        }
        final id = uri.path.split('/')[3];
        if (uri.path.startsWith('/v1/runs/')) {
          expect(uri.queryParameters['profile'], 'default');
          if (id == 'a' && statusA != null) {
            statusAEntered = true;
            return statusA!.future;
          }
          if (id == 'a' && lostA && !canonicalA) {
            throw StateError('Synthetic loss');
          }
          return status(id);
        }
        return jsonEncode({
          'object': 'list',
          'session_id': id,
          'data': [
            if (streams.containsKey(id))
              {
                'id': 'user-$id',
                'session_id': id,
                'role': 'user',
                'content': 'Synthetic run ${id.toUpperCase()}',
              },
            if (id == 'a' && canonicalA)
              {
                'id': 'canonical-a',
                'session_id': id,
                'role': 'assistant',
                'content': 'Synthetic canonical A',
              },
          ],
        });
      },
      post: (uri, _, body) async {
        mutations.add(uri.path);
        expect(uri.path, '/v1/runs');
        final id = (jsonDecode(body) as Map)['session_id'];
        return jsonEncode({'run_id': id, 'session_id': id, 'status': 'queued'});
      },
      getStream: (uri, _) {
        final id = uri.path.split('/')[3];
        final stream = StreamController<String>();
        streams[id] = stream;
        return stream.stream;
      },
    ),
  );
  String status(String id) => jsonEncode({
    'run_id': id,
    'session_id': id,
    'status': id == 'a' && canonicalA ? 'completed' : 'running',
  });
  Future<void> dispose() async {
    channel.dispose();
    for (final stream in streams.values) {
      await stream.close();
    }
  }
}

void main() {
  testWidgets(
    'Reconnect reconciles only the lost tab and late recovery cannot leave the focused sibling',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final f = WorkspaceRecoveryFixture();
      addTearDown(f.dispose);
      const origin = 'https://workspace.example';
      await f.channel.connect(baseUrl: origin);
      expect(
        f.channel.state.isConnected,
        isTrue,
        reason: f.channel.state.errorMessage,
      );
      final directory = HermesGatewayDirectory(
        store: FakeHermesEndpointStore(),
        cache: FakeGatewayContactCache(),
        loader: FakeGatewaySummaryLoader({}),
        activeChannel: f.channel,
      );
      await mount(tester, f.channel, directory: directory);
      Future<void> open(String id) async {
        final chip = find.descendant(
          of: find.byKey(tab(id, gateway: origin)),
          matching: find.byType(ChoiceChip),
        );
        await tester.ensureVisible(chip);
        await tester.tap(chip);
        await tester.runAsync(() async {
          await pumpEventQueue();
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(f.channel.state.activeSessionId, id);
      }

      await f.channel.selectSession('b');
      await tester.pumpAndSettle();
      expect(f.channel.state.selectedProfileId, 'default');
      expect(find.byKey(tab('a', gateway: origin)), findsOneWidget);
      expect(find.byKey(tab('b', gateway: origin)), findsOneWidget);
      await tester.enterText(find.byKey(_composer), 'Synthetic run B');
      await tester.pump();
      await tester.tap(find.byTooltip('Send'));
      await tester.pump();
      await tester.runAsync(() async {
        await pumpEventQueue();
      });
      await tester.pump();
      expect(f.channel.state.activeSessionId, 'b');
      expect(
        f.streams.keys,
        contains('b'),
        reason: f.channel.state.errorMessage,
      );
      expect(
        tester.widget<TextField>(find.byKey(_composer)).enabled,
        isTrue,
        reason:
            'unresolved=${f.channel.state.hasUnreconciledRun} error=${f.channel.state.errorMessage}',
      );
      await tester.enterText(
        find.byKey(_composer),
        'Synthetic retained B draft',
      );
      composer(tester).selection = const TextSelection.collapsed(offset: 4);
      final healthyB = f.streams['b'];
      await open('a');
      await tester.enterText(find.byKey(_composer), 'Synthetic run A');
      await tester.pump();
      await tester.tap(find.byTooltip('Send'));
      await tester.pump();
      await tester.runAsync(() async {
        await pumpEventQueue();
      });
      expect(f.streams.keys, contains('a'));
      f.statusA = Completer<String>();
      final originalEofStatus = f.statusA!;
      f.lostA = true;
      await tester.runAsync(() async {
        await f.streams['a']!.close();
        await pumpEventQueue();
      });
      await tester.pump();
      expect(f.channel.state.activeSessionId, 'a');
      expect(f.channel.state.isSessionStreaming('b'), isTrue);
      // Do not reselect A: foreground EOF must preserve the sibling even when
      // no selection-time recovery flag has been populated.
      expect(f.channel.state.isSessionStreaming('a'), isFalse);
      expect(f.channel.state.errorMessage, isNotNull);
      expect(f.statusAEntered, isTrue);
      // Reconnect must supersede even the original stream's pending EOF read.
      f.statusAEntered = false;
      f.canonicalA = true;
      f.statusA = Completer<String>();
      await tester.tap(
        find.byKey(const ValueKey('hermes-chat-error-reconnect')),
      );
      await tester.runAsync(() async {
        await pumpEventQueue();
      });
      await tester.pump();
      expect(
        f.channel.state.isSessionStreaming('b'),
        isTrue,
        reason: 'Recovering A must not retire the healthy B subscription',
      );
      expect(f.statusAEntered, isTrue);
      expect(f.channel.recoverySettlements, 0);
      expect(f.streams['b'], same(healthyB));
      expect(f.channel.state.activeSessionId, 'a');
      await open('b');
      expect(f.channel.state.activeSessionId, 'b');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focus = FocusManager.instance.primaryFocus;
      expect(focus, isNotNull);
      f.statusA!.complete(f.status('a'));
      f.statusA = null;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(f.channel.recoverySettlements, 1);
      expect(f.channel.state.activeSessionId, 'b');
      expect(FocusManager.instance.primaryFocus, same(focus));
      expect(composer(tester).text, 'Synthetic retained B draft');
      expect(
        composer(tester).selection,
        const TextSelection.collapsed(offset: 4),
      );
      // B's original stream still publishes only to B after A's late read.
      f.streams['b']!.add(
        'event: message.delta\ndata: {"run_id":"b","session_id":"b","delta":"Synthetic live B"}\n\n',
      );
      await tester.pump();
      expect(f.channel.state.activeMessages.last.text, 'Synthetic live B');
      await open('a');
      expect(f.channel.state.activeMessages.last.text, 'Synthetic canonical A');
      expect(f.channel.state.hasUnreconciledRun, isFalse);
      originalEofStatus.complete(
        '{"run_id":"a","session_id":"a","status":"running"}',
      );
      await tester.runAsync(() async {
        await pumpEventQueue();
      });
      await tester.pump();
      expect(f.channel.state.activeSessionId, 'a');
      expect(f.channel.state.activeMessages.last.text, 'Synthetic canonical A');
      expect(f.channel.state.hasUnreconciledRun, isFalse);
      expect(f.channel.state.isSessionStreaming('b'), isTrue);
      expect(f.mutations, ['/v1/runs', '/v1/runs']);
      expect(tester.takeException(), isNull);
      await f.channel.disconnect();
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'retired workspace Open and Close callbacks are inert after Chat unmount',
    (tester) async {
      final channel = WorkspaceChannel();
      addTearDown(channel.dispose);
      await mount(tester, channel);
      await channel.selectSession('b');
      await tester.pumpAndSettle();
      final open = tester
          .widget<ChoiceChip>(
            find.descendant(
              of: find.byKey(tab('a')),
              matching: find.byType(ChoiceChip),
            ),
          )
          .onSelected!;
      final close = tester
          .widget<IconButton>(find.byKey(tab('b', close: true)))
          .onPressed!;
      await tester.pumpWidget(const SizedBox());
      open(true);
      close();
      await tester.pump();
      expect(channel.state.activeSessionId, 'b');
      expect(channel.stoppedTargets, isEmpty);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'cached close Reconnect rejects owner roundtrip and native transition',
    (tester) async {
      for (final native in [false, true]) {
        final channel = WorkspaceChannel(supportsStop: false);
        addTearDown(channel.dispose);
        await mount(tester, channel);
        channel.beginStreamingTurn('Synthetic recovery owner');
        await tester.pump();
        await tester.tap(find.byKey(tab('a', close: true)));
        await tester.pump(const Duration(milliseconds: 400));
        final reconnect = tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Reconnect'))
            .onPressed!;
        if (native) {
          channel.nativeServe = true;
          channel.notifyListeners();
        } else {
          await channel.selectSession('b');
          await channel.selectSession('a');
        }
        reconnect();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(channel.connectCalls, isEmpty);
        expect(channel.state.activeSessionId, 'a');
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          tester
              .widget<TextButton>(find.widgetWithText(TextButton, 'Keep open'))
              .onPressed,
          isNotNull,
        );
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      }
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'Chat unmount releases a root close dialog and its held Stop observers',
    (tester) async {
      final channel = WorkspaceChannel();
      final page = ValueNotifier<Widget>(const HermesChatScreen());
      addTearDown(channel.dispose);
      addTearDown(page.dispose);
      await mount(tester, channel, page: page);
      channel.beginStreamingTurn('Synthetic held run');
      await tester.pump();
      channel.stopGate = Completer<bool>();
      await tester.tap(find.byKey(tab('a', close: true)));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(
        find.byKey(const ValueKey('hermes-workspace-stop-close')),
      );
      await tester.pump();
      page.value = const Text('Replacement screen');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        channel.listeners.length,
        1,
        reason: 'Only the reactive state provider remains',
      );
      channel.stopGate!.complete(false);
      await tester.pump();
      expect(channel.listeners.length, 1);
      expect(channel.state.activeSessionId, 'a');
      expect(channel.stoppedTargets.map((target) => target.sessionId), ['a']);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'native A to B to A cannot expose idle Close while Agent work is running',
    (tester) async {
      final oldHttp = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = oldHttp);
      FlutterSecureStorage.setMockInitialValues({});
      final fixture = _TwoSessionNativeFixture();
      await tester.runAsync(fixture.start);
      addTearDown(fixture.close);
      final channel = HermesApiChannel();
      addTearDown(channel.dispose);
      await tester.runAsync(() async {
        await channel.connectLocalServeReads(
          baseUrl: fixture.origin,
          credential: LocalServeReadFixture.token,
        );
        await channel.selectProfile('demo');
        await channel.enableLocalServeChat();
      });
      final directory = HermesGatewayDirectory(
        store: FakeHermesEndpointStore(),
        cache: FakeGatewayContactCache(),
        loader: FakeGatewaySummaryLoader({}),
        activeChannel: channel,
      );
      await mount(tester, channel, directory: directory);
      await tester.runAsync(() async {
        await channel.sendText('Synthetic native A running');
        fixture.running = true;
        await channel.selectSession('second-demo');
        await channel.selectSession('demo-session');
      });
      await tester.pump();
      expect(channel.state.activeSessionId, 'demo-session');
      expect(fixture.running, isTrue);
      expect(
        find.byKey(const ValueKey('hermes-active-session-bar')),
        findsNothing,
      );
      expect(find.byTooltip('Close demo read session'), findsNothing);
      await cycle(tester);
      expect(channel.state.activeSessionId, 'demo-session');
      expect(fixture.count('prompt.submit'), 1);
      expect(fixture.count('session.interrupt'), 0);
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'native serve cannot use workspace controls or revive cached gateway actions',
    (tester) async {
      final channel = WorkspaceChannel();
      addTearDown(channel.dispose);
      await mount(tester, channel);
      await channel.selectSession('b');
      await tester.pumpAndSettle();
      final open = tester
          .widget<ChoiceChip>(
            find.descendant(
              of: find.byKey(tab('a')),
              matching: find.byType(ChoiceChip),
            ),
          )
          .onSelected!;
      final close = tester
          .widget<IconButton>(find.byKey(tab('b', close: true)))
          .onPressed!;
      channel.nativeServe = true;
      channel.notifyListeners();
      open(true);
      close();
      await tester.pumpAndSettle();
      expect(channel.state.activeSessionId, 'b');
      expect(find.byKey(tab('a')), findsNothing);
      expect(find.byKey(tab('b', close: true)), findsNothing);
      await cycle(tester);
      expect(channel.state.activeSessionId, 'b');
      expect(channel.stoppedTargets, isEmpty);
      expect(find.byType(AlertDialog), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'keyboard restores the exact saved host/profile with a colliding session id',
    (tester) async {
      final h = RestorationHarness();
      h.configureCapabilities = (doc) {
        doc['features'] = {'session_chat_streaming': true};
        (doc['endpoints'] as Map)['session_chat_stream'] = {
          'method': 'POST',
          'path': '/api/sessions/{session_id}/chat/stream',
        };
      };
      await h.directory.start();
      await mount(tester, h.channel, directory: h.directory);
      await tester.enterText(
        find.byKey(_composer),
        'Synthetic alpha coder draft',
      );
      composer(tester).selection = const TextSelection.collapsed(offset: 3);
      await h.directory.activate(
        const GatewayContactId(gatewayId: 'beta', profileId: 'default'),
        preferredSessionId: 'older-A',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(_composer),
        'Synthetic beta default draft',
      );
      expect(
        find.byKey(tab('older-A', gateway: 'alpha', profile: 'coder')),
        findsOneWidget,
      );
      expect(find.byKey(tab('older-A', gateway: 'beta')), findsOneWidget);
      await cycle(tester);
      expect(h.channel.state.connectedBaseUrl, 'https://alpha.example');
      expect(h.channel.state.selectedProfileId, 'coder');
      expect(h.channel.state.activeSessionId, 'older-A');
      expect(composer(tester).text, 'Synthetic alpha coder draft');
      expect(
        composer(tester).selection,
        const TextSelection.collapsed(offset: 3),
      );
      await cycle(tester, reverse: true);
      expect(h.channel.state.connectedBaseUrl, 'https://beta.example');
      expect(h.channel.state.selectedProfileId, 'default');
      expect(composer(tester).text, 'Synthetic beta default draft');
      expect(h.mutations, isEmpty);
      expect(
        h.cache.selection?.contactId,
        const GatewayContactId(gatewayId: 'beta', profileId: 'default'),
      );
      await tester.pumpWidget(const SizedBox());
      h.disposed = true;
      h.dispose();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'compact visited tabs restore each draft and text selection by keyboard',
    (tester) async {
      final channel = WorkspaceChannel();
      addTearDown(channel.dispose);
      await mount(tester, channel);
      await tester.enterText(find.byKey(_composer), 'Synthetic A draft');
      composer(tester).selection = const TextSelection(
        baseOffset: 2,
        extentOffset: 7,
      );
      await channel.selectSession('b');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(_composer), 'Synthetic B draft');
      composer(tester).selection = const TextSelection.collapsed(offset: 4);
      expect(find.byKey(tab('a')), findsOneWidget);
      expect(find.byKey(tab('b')), findsOneWidget);
      await cycle(tester);
      expect(channel.state.activeSessionId, 'a');
      expect(composer(tester).text, 'Synthetic A draft');
      expect(
        composer(tester).selection,
        const TextSelection(baseOffset: 2, extentOffset: 7),
      );
      await cycle(tester, reverse: true);
      expect(channel.state.activeSessionId, 'b');
      expect(composer(tester).text, 'Synthetic B draft');
      expect(
        composer(tester).selection,
        const TextSelection.collapsed(offset: 4),
      );
      await tester.ensureVisible(find.byKey(tab('b', close: true)));
      await tester.tap(find.byKey(tab('b', close: true)));
      await tester.pumpAndSettle();
      expect(find.byKey(tab('b')), findsNothing);
      await channel.selectSession('b'); // Also used by global session access.
      await tester.pumpAndSettle();
      expect(find.byKey(tab('b')), findsOneWidget);
      expect(composer(tester).text, 'Synthetic B draft');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'close waits for captured Stop confirmation and releases a failed request for retry',
    (tester) async {
      final channel = WorkspaceChannel();
      addTearDown(channel.dispose);
      await mount(tester, channel);
      await channel.selectSession('b');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(_composer), 'Synthetic B retained');
      await channel.selectSession('a');
      channel.beginStreamingTurn('Synthetic A run');
      await tester.pump();
      channel.stopGate = Completer<bool>();
      await tester.tap(find.byKey(tab('a', close: true)));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(
        find.byKey(const ValueKey('hermes-workspace-stop-close')),
      );
      await tester.pump();
      expect(find.byKey(tab('a')), findsOneWidget);
      expect(channel.stoppedTargets.single.sessionId, 'a');
      channel.stopGate!.complete(false);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(tab('a')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('hermes-workspace-close-uncertain')),
        findsOneWidget,
      );
      await tester.tap(find.text('Keep open'));
      await tester.pump(const Duration(milliseconds: 400));
      channel.stopGate = Completer<bool>();
      await tester.tap(find.byKey(tab('a', close: true)));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(
        find.byKey(const ValueKey('hermes-workspace-stop-close')),
      );
      await tester.pump();
      channel.stopGate!.complete(true);
      await tester.pumpAndSettle();
      expect(find.byKey(tab('a')), findsNothing);
      expect(channel.state.activeSessionId, 'b');
      expect(composer(tester).text, 'Synthetic B retained');
      expect(channel.stoppedTargets.map((t) => t.sessionId), ['a', 'a']);
      expect(channel.deleteSessionCalls, isEmpty);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'retired platform editing input cannot overwrite a switched conversation',
    (tester) async {
      final channel = WorkspaceChannel();
      addTearDown(channel.dispose);
      await mount(tester, channel);
      await tester.enterText(find.byKey(_composer), 'Synthetic A draft');
      await channel.selectSession('b');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(_composer), 'Synthetic B draft');
      final oldClient =
          (tester.testTextInput.log
                      .lastWhere((call) => call.method == 'TextInput.setClient')
                      .arguments
                  as List)
              .first;
      await cycle(tester);
      expect(composer(tester).text, 'Synthetic A draft');
      tester.binding.channelBuffers.push(
        'flutter/textinput',
        const JSONMethodCodec().encodeMethodCall(
          MethodCall('TextInputClient.updateEditingState', [
            oldClient,
            const TextEditingValue(text: 'Synthetic stale B input').toJSON(),
          ]),
        ),
        (_) {},
      );
      await tester.pump();
      expect(composer(tester).text, 'Synthetic A draft');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'cached composer Stop cannot interrupt the replacement conversation',
    (tester) async {
      final channel = WorkspaceChannel();
      addTearDown(channel.dispose);
      await mount(tester, channel);
      channel.beginStreamingTurn('Synthetic A run');
      await tester.pump();
      final stop = tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('hermes-composer-stop-chip')),
          )
          .onPressed!;
      await channel.selectSession('b');
      channel.beginStreamingTurn('Synthetic B run');
      stop(); // An old rendered action must not resolve through current selection.
      await tester.pump();
      expect(channel.state.isSessionStreaming('a'), isTrue);
      expect(channel.state.isSessionStreaming('b'), isTrue);
      expect(channel.stopActiveTurnCalls, 0);
      await channel.selectSession('a');
      stop(); // Returning to the same running target must not revive old input.
      await tester.pump();
      expect(channel.state.isSessionStreaming('a'), isTrue);
      expect(channel.state.isSessionStreaming('b'), isTrue);
      expect(channel.stopActiveTurnCalls, 0);

      final freshStop = tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('hermes-composer-stop-chip')),
          )
          .onPressed!;
      channel.reconciling = true;
      channel.notifyListeners();
      channel.reconciling = false;
      channel.notifyListeners();
      freshStop(); // Readiness alone does not retire the unchanged owner.
      await tester.pump();
      expect(channel.stopActiveTurnCalls, 1);
      expect(channel.state.isSessionStreaming('b'), isTrue);
      await tester.pumpWidget(const SizedBox());
      freshStop(); // A disposed screen cannot read providers or dispatch input.
      expect(channel.stopActiveTurnCalls, 1);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'retained Stop and close rejects loss of exact status authority',
    (tester) async {
      final channel = WorkspaceChannel();
      addTearDown(channel.dispose);
      await mount(tester, channel);
      channel.beginStreamingTurn('Synthetic A run');
      await tester.pump();
      await tester.tap(find.byKey(tab('a', close: true)));
      await tester.pump(const Duration(milliseconds: 400));
      final stop = tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('hermes-workspace-stop-close')),
          )
          .onPressed!;
      final capabilities = channel.state.capabilities!;
      channel.setCapabilities(
        HermesCapabilityDocument(
          object: capabilities.object,
          platform: capabilities.platform,
          model: capabilities.model,
          auth: capabilities.auth,
          features: capabilities.features,
          endpoints: {...capabilities.endpoints}..remove('run_status'),
        ),
      );
      stop(); // Invoke before the dialog rebuilds its disabled controls.
      await tester.pump(const Duration(milliseconds: 400));
      expect(channel.stoppedTargets, isEmpty);
      expect(channel.state.isSessionStreaming('a'), isTrue);
      expect(channel.state.activeSessionId, 'a');
      expect(find.byKey(tab('a', close: true)), findsOneWidget);
      expect(
        find.byKey(const ValueKey('hermes-workspace-stop-unavailable')),
        findsOneWidget,
      );
      await tester.tap(find.text('Keep open'));
      await tester.pump(const Duration(milliseconds: 400));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'unsupported and stale close controls cannot stop another selected run',
    (tester) async {
      final channel = WorkspaceChannel(supportsStop: false);
      addTearDown(channel.dispose);
      await mount(tester, channel);
      channel.beginStreamingTurn('Synthetic A run');
      await tester.pump();
      await tester.tap(find.byKey(tab('a', close: true)));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.byKey(const ValueKey('hermes-workspace-stop-unavailable')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('hermes-workspace-stop-close')),
        findsNothing,
      );
      await channel.selectSession('b');
      channel.beginStreamingTurn('Synthetic B run');
      await tester.pump();
      await tester.tap(find.text('Keep open'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(channel.state.activeSessionId, 'b');
      expect(channel.stoppedTargets, isEmpty);
      expect(channel.state.isSessionStreaming('a'), isTrue);
      expect(channel.state.isSessionStreaming('b'), isTrue);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
}
