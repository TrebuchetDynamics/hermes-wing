import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/hermes_api.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

const session = 'synthetic-reconnect';
const prompt = 'Synthetic reconnect request';
const commentary = 'Synthetic reconnect commentary';
const answer = 'Synthetic canonical answer';
const hidden = 'Synthetic hidden model context /tmp/synthetic-only';

class ReconnectFixture {
  bool canonical = false;
  final mutations = <String>[];
  final streams = <StreamController<String>>[];
  final reads = <String>[];
  late final channel = HermesApiChannel(
    clientBuilder: (config) => HermesApiClient(
      config: config,
      get: (uri, headers) async {
        reads.add(uri.path);
        return switch (uri.path) {
          '/health' => '{"status":"ok"}',
          '/v1/capabilities' => jsonEncode({
            'object': 'hermes.api_server.capabilities',
            'schema_version': 1,
            'features': {
              'run_submission': true,
              'run_events_sse': true,
              'run_approval_response': true,
              'run_stop': true,
              'run_status': true,
            },
            'endpoints': {
              'sessions': {'method': 'GET', 'path': '/api/sessions'},
              'session_messages': {
                'method': 'GET',
                'path': '/api/sessions/{session_id}/messages',
              },
              'runs': {'method': 'POST', 'path': '/v1/runs'},
              'run_events': {
                'method': 'GET',
                'path': '/v1/runs/{run_id}/events',
              },
              'run_status': {'method': 'GET', 'path': '/v1/runs/{run_id}'},
              'run_approval': {
                'method': 'POST',
                'path': '/v1/runs/{run_id}/approval',
              },
              'run_stop': {'method': 'POST', 'path': '/v1/runs/{run_id}/stop'},
            },
          }),
          '/api/sessions' => jsonEncode({
            'object': 'list',
            'data': [
              {
                'id': session,
                'source': 'synthetic',
                'title': 'Synthetic reconnect',
              },
            ],
          }),
          '/api/sessions/$session/messages' => jsonEncode({
            'object': 'list',
            'session_id': session,
            'data': canonical ? history : [],
          }),
          '/v1/runs/run_1' => jsonEncode({
            'run_id': 'run_1',
            'session_id': session,
            'status': canonical ? 'completed' : 'running',
          }),
          _ => throw StateError('Unexpected fixture read ${uri.path}'),
        };
      },
      post: (uri, headers, body) async {
        mutations.add(uri.path);
        if (uri.path == '/v1/runs') {
          return jsonEncode({
            'run_id': 'run_${streams.length + 1}',
            'session_id': session,
          });
        }
        if (uri.path.endsWith('/approval')) return '{}';
        throw StateError('Unexpected fixture mutation ${uri.path}');
      },
      getStream: (uri, headers) {
        final stream = StreamController<String>();
        streams.add(stream);
        return stream.stream;
      },
    ),
  );

  List<Map<String, Object?>> get history => [
    row('canonical-user', 'user', prompt),
    row('canonical-commentary', 'assistant', commentary),
    row('canonical-read', 'tool', hidden, tool: 'read_file'),
    row('canonical-web', 'tool', hidden, tool: 'web_search'),
    row('canonical-answer', 'assistant', answer),
  ];

  Map<String, Object?> row(
    String id,
    String role,
    String text, {
    String? tool,
  }) => {
    'id': id,
    'session_id': session,
    'role': role,
    'content': text,
    'tool_name': ?tool,
  };

  void event(String name, Map<String, Object?> payload) =>
      streams.last.add('event: $name\ndata: ${jsonEncode(payload)}\n\n');

  Future<void> prelude() async {
    await pumpEventQueue();
    event('message.delta', {'delta': commentary});
    for (final tool in ['read_file', 'web_search']) {
      event('tool.started', {'tool': tool, 'tool_call_id': tool});
      event('tool.completed', {
        'tool': tool,
        'tool_call_id': tool,
        'result_text': hidden,
      });
    }
    event('approval.request', {
      'run_id': 'run_${streams.length}',
      'command': 'synthetic',
      'description': 'Synthetic pending approval',
      'choices': ['once', 'deny'],
    });
    await pumpEventQueue();
  }

  Future<void> dispose() async {
    channel.dispose();
    for (final stream in streams) {
      await stream.close();
    }
  }
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> reach(WidgetTester tester, String label) async {
  final target = find.text(label);
  expect(target, findsOneWidget);
  for (var i = 0; i < 70; i++) {
    final context = FocusManager.instance.primaryFocus?.context;
    final control =
        context?.findAncestorWidgetOfExactType<ListTile>() ??
        context?.findAncestorWidgetOfExactType<TextButton>() ??
        context?.findAncestorWidgetOfExactType<FilledButton>() ??
        context?.findAncestorWidgetOfExactType<OutlinedButton>();
    if (control != null &&
        find
            .descendant(of: find.byWidget(control), matching: target)
            .evaluate()
            .isNotEmpty) {
      return;
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  fail('Keyboard could not reach $label');
}

Future<void> mount(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(platform: TargetPlatform.linux),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const HermesChatScreen(),
      ),
    ),
  );
  await settle(tester);
}

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
    }),
  );
  testWidgets(
    'canonical reconnect replaces transient activity and retired approval; remount never replays',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 1100);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = ReconnectFixture();
      addTearDown(fixture.dispose);
      await fixture.channel.connect(baseUrl: 'http://127.0.0.1:8642');
      final container = ProviderContainer(
        overrides: [
          hermesChannelProvider.overrideWithValue(fixture.channel),
          hermesVoiceCaptureServiceProvider.overrideWithValue(null),
          hermesTextToSpeechServiceProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);
      await mount(tester, container);
      final send = fixture.channel.sendText(prompt);
      await tester.runAsync(fixture.prelude);
      await settle(tester);
      expect(find.text('Hermes host activity · 2 steps'), findsOneWidget);
      await reach(tester, 'Approve once');
      final retiredFocus = FocusManager.instance.primaryFocus;
      fixture.canonical = true;
      await fixture.channel.connect(baseUrl: 'http://127.0.0.1:8642');
      await send;
      await settle(tester);
      expect(find.text('Approve once'), findsNothing);
      expect(FocusManager.instance.primaryFocus, isNot(same(retiredFocus)));
      expect(fixture.channel.state.activeMessages.map((t) => t.id), [
        'canonical-user',
        'canonical-commentary',
        'canonical-read',
        'canonical-web',
        'canonical-answer',
      ]);
      for (final remount in [false, true]) {
        if (remount) {
          await tester.pumpWidget(const SizedBox());
          await settle(tester);
          await mount(tester, container);
        }
        for (final width in [390.0, 1280.0]) {
          tester.view.physicalSize = Size(width, 1100);
          await settle(tester);
          double? previous;
          for (final label in [
            prompt,
            commentary,
            'Hermes host activity · 2 steps',
            answer,
          ]) {
            expect(find.text(label), findsOneWidget);
            final y = tester.getTopLeft(find.text(label)).dy;
            if (previous != null) expect(y, greaterThan(previous));
            previous = y;
          }
          expect(find.text(hidden), findsNothing);
          expect(find.text('Approve once'), findsNothing);
          expect(fixture.mutations, ['/v1/runs']);
        }
      }
      await reach(tester, 'Hermes host activity · 2 steps');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester);
      expect(find.text('File activity'), findsOneWidget);
      expect(find.text('Web activity'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('File activity')).dy,
        lessThan(tester.getTopLeft(find.text('Web activity')).dy),
      );
      // Retired activation and read-only refresh cannot decide or stop.
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await fixture.channel.reconcileActiveSession();
      await settle(tester);
      expect(fixture.mutations, ['/v1/runs']);
      expect(
        fixture.reads.where((p) => p.endsWith('/messages')).length,
        greaterThanOrEqualTo(3),
      );
      expect(
        fixture.channel.state.activeMessages
            .where((t) => t.kind == HermesTurnKind.toolCall)
            .length,
        2,
      );
      final recoveryMutationDelta = fixture.mutations.length - 1;
      // A new connection's approval remains keyboard operable across layout
      // replacement. Only this explicit setup send and decision may mutate.
      fixture.canonical = false;
      await fixture.channel.connect(baseUrl: 'http://127.0.0.1:8642');
      final currentSend = fixture.channel.sendText('Synthetic current request');
      await tester.runAsync(fixture.prelude);
      await settle(tester);
      for (final width in [390.0, 1280.0]) {
        tester.view.physicalSize = Size(width, 1100);
        await settle(tester);
        await reach(tester, 'Approve once');
        expect(fixture.mutations, ['/v1/runs', '/v1/runs']);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester);
      expect(fixture.mutations, [
        '/v1/runs',
        '/v1/runs',
        '/v1/runs/run_2/approval',
      ]);
      await tester.runAsync(() async {
        fixture.event('message.delta', {'delta': 'Synthetic current answer'});
        fixture.event('run.completed', {
          'run_id': 'run_2',
          'session_id': session,
          'status': 'completed',
        });
        await pumpEventQueue();
      });
      await settle(tester);
      await currentSend;
      expect(find.text('Approve once'), findsNothing);
      debugPrint(
        jsonEncode({
          'synthetic_reconnect_receipt': true,
          'canonical_ids': fixture.history.map((row) => row['id']).toList(),
          'reconnect_remount_mutation_delta': recoveryMutationDelta,
          'explicit_prompts': fixture.mutations
              .where((p) => p == '/v1/runs')
              .length,
          'explicit_decisions': fixture.mutations
              .where((p) => p.endsWith('/approval'))
              .length,
          'stops': fixture.mutations.where((p) => p.endsWith('/stop')).length,
          'mutations': fixture.mutations,
        }),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
