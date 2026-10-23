import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import 'bot_chat_fixture.dart';
import 'local_serve_read_fixture.dart';
import 'integrated_daily_restart_fixture.dart';

/// Synthetic authenticated native RPC/REST, never an Agent or provider.
class LinuxChatFeatureFixture extends BotChatFixture {
  LinuxChatFeatureFixture() : super(portOffset: 35);

  final exportOffsets = <int>[];
  Completer<void>? exportStarted, exportGate, exportResponded;
  bool wrongRegistry = false;

  @override
  Future<bool> handleExtra(HttpRequest request) async {
    if (wrongRegistry && request.uri.path == '/api/sessions/bot-root') {
      request.response.write(jsonEncode({'id': 'foreign', 'hidden': 1}));
      await request.response.close();
      return true;
    }
    if (request.uri.path.endsWith('/messages') &&
        request.uri.queryParameters['order'] == 'oldest' &&
        request.headers.value('Authorization') ==
            'Bearer ${LocalServeReadFixture.token}') {
      final query = request.uri.queryParameters;
      if (request.uri.path != '/api/sessions/default-session/messages' ||
          request.method != 'GET' ||
          query['profile'] != 'default' ||
          query['limit'] != '500' ||
          query['include_compacted'] != 'true') {
        throw StateError('Unexpected paged export request');
      }
      final offset = int.parse(query['offset']!);
      exportOffsets.add(offset);
      if (!(exportStarted?.isCompleted ?? true)) exportStarted!.complete();
      await exportGate?.future;
      request.response.write(
        jsonEncode({
          'profile': 'default',
          'session_id': 'default-session',
          'messages': [
            for (var i = offset; i < 501 && i < offset + 500; i++)
              {
                'id': i + 1,
                'session_id': i == 0 ? 'ancestor' : 'default-session',
                'role': i == 500 ? 'tool' : 'assistant',
                'content': {'text': 'Synthetic raw $i — 日本語 😀'},
                'hidden': i == 0,
              },
          ],
          'pagination': {
            'limit': 500,
            'offset': offset,
            'order': 'oldest',
            'returned': offset == 0
                ? 500
                : offset == 500
                ? 1
                : 0,
          },
        }),
      );
      await request.response.close();
      if (!(exportResponded?.isCompleted ?? true)) exportResponded!.complete();
      return true;
    }
    return super.handleExtra(request);
  }

  Map<String, int> get operations => {
    'registry': count('session.list'),
    'create': count('session.create'),
    'resume': count('session.resume'),
    'history': count('session.history'),
    'send': count('prompt.submit'),
    'approval': count('approval.respond'),
    'stop': count('session.interrupt'),
    'export_pages': exportOffsets.length,
  };

  @override
  Future<void> close() async {
    if (!(exportGate?.isCompleted ?? true)) exportGate!.complete();
    if (!(holdHistory?.isCompleted ?? true)) holdHistory!.complete();
    await super.close();
  }
}

/// Existing deterministic HTTP/SSE server with child-owned readiness, not live IO.
class LinuxChatApiFixture {
  Process? _server;
  HttpServer? _proxy;
  final _forward = HttpClient();
  late String origin;
  final sessionSubmissions = <String>[];
  final sessionTerminals = <Completer<void>>[];

  Future<void> start({bool fallbackStreams = false}) async {
    final base = int.parse(Platform.environment['AUTOWORK_PORT_BASE']!);
    if (base < 1024 || base > 65435) throw StateError('Owned ports required');
    origin = 'http://127.0.0.1:${base + 11}';
    final child = _server = await Process.start(
      'node',
      ['serve_web.mjs'],
      environment: {'PORT': '${base + 10}', 'HERMES_E2E_PORT': '${base + 11}'},
    );
    final ready = Completer<void>();
    final announcements = {
      'Server running at http://127.0.0.1:${base + 10}/',
      'Hermes API running at $origin/',
    };
    child.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(
      (line) {
        announcements.remove(line);
        if (announcements.isEmpty && !ready.isCompleted) ready.complete();
      },
    );
    unawaited(child.stderr.drain<void>());
    await Future.any([
      ready.future,
      child.exitCode.then<void>(
        (_) => throw StateError('Owned fixture exited'),
      ),
    ]).timeout(const Duration(seconds: 10));
    if (fallbackStreams) {
      final upstream = origin;
      _proxy = await HttpServer.bind(InternetAddress.loopbackIPv4, base + 12);
      origin = 'http://127.0.0.1:${base + 12}';
      _proxy!.listen((incoming) async {
        final path = incoming.uri.path;
        if (incoming.method == 'POST' &&
            path == '/api/sessions/synthetic-restoration-000/chat/stream') {
          final body =
              jsonDecode(await utf8.decoder.bind(incoming).join()) as Map;
          final message = body['message'];
          if (message is! String || body.length != 1) {
            throw StateError('Unexpected fallback body');
          }
          sessionSubmissions.add(message);
          final gate = Completer<void>();
          sessionTerminals.add(gate);
          incoming.response.headers.contentType = ContentType(
            'text',
            'event-stream',
          );
          incoming.response.write(
            'event: assistant.delta\ndata: {"delta":"Synthetic queued reply"}\n\n',
          );
          await incoming.response.flush();
          await gate.future;
          incoming.response.write('data: [DONE]\n\n');
          await incoming.response.close();
          return;
        }
        final outgoing = await _forward.openUrl(
          incoming.method,
          Uri.parse('$upstream${incoming.uri}'),
        );
        incoming.headers.forEach((name, values) {
          if (!{'host', 'content-length', 'connection'}.contains(name)) {
            outgoing.headers.set(name, values);
          }
        });
        await outgoing.addStream(incoming);
        final response = await outgoing.close();
        if (incoming.method == 'GET' &&
            (path == '/v1/capabilities' ||
                path == '/api/sessions/synthetic-restoration-000/messages')) {
          final body =
              jsonDecode(await utf8.decoder.bind(response).join())
                  as Map<String, dynamic>;
          if (path == '/v1/capabilities') {
            (body['features'] as Map)['run_submission'] = false;
          } else {
            final rows = body['data'] as List;
            for (var i = 0; i < sessionSubmissions.length; i++) {
              rows.add({
                'id': 'queue-user-$i',
                'session_id': 'synthetic-restoration-000',
                'role': 'user',
                'content': sessionSubmissions[i],
              });
              if (sessionTerminals[i].isCompleted) {
                rows.add({
                  'id': 'queue-reply-$i',
                  'session_id': 'synthetic-restoration-000',
                  'role': 'assistant',
                  'content': 'Synthetic queued reply',
                });
              }
            }
          }
          incoming.response.headers.contentType = ContentType.json;
          incoming.response.write(jsonEncode(body));
          await incoming.response.close();
          return;
        }
        incoming.response.statusCode = response.statusCode;
        response.headers.forEach((name, values) {
          if (!{
            'content-length',
            'transfer-encoding',
            'connection',
          }.contains(name)) {
            incoming.response.headers.set(name, values);
          }
        });
        await incoming.response.addStream(response);
        await incoming.response.close();
      });
    }
    await request('POST', '/e2e/hermes/reset');
  }

  Future<Map<String, dynamic>> request(
    String method,
    String path, [
    Map<String, Object?>? body,
  ]) async {
    final client = HttpClient();
    try {
      final request = await client.openUrl(method, Uri.parse('$origin$path'));
      request.headers.contentType = ContentType.json;
      if (body != null) request.write(jsonEncode(body));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw StateError('Fixture control failed');
      }
      return jsonDecode(await utf8.decoder.bind(response).join())
          as Map<String, dynamic>;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> close() async {
    for (final gate in sessionTerminals) {
      if (!gate.isCompleted) gate.complete();
    }
    await _proxy?.close(force: true);
    _forward.close(force: true);
    final child = _server;
    if (child != null) {
      child.kill();
      await child.exitCode.timeout(const Duration(seconds: 5));
    }
  }
}

/// Same containment as the shared launcher guard, accepting Python tempfile's
/// underscore suffix as well as Dart's alphanumeric suffix for owned children.
String requireLinuxChatRoot() {
  final root = Platform.environment['WING_LINUX_TEST_ROOT'];
  if (root == null) throw StateError('Missing owned Chat root');
  final directory = Directory(root);
  final marker = File('$root/.wing-linux-test-owner');
  if (Platform.environment['XDG_CONFIG_HOME'] != '$root/config' ||
      !directory.existsSync() ||
      directory.resolveSymbolicLinksSync() != root ||
      directory.parent.resolveSymbolicLinksSync() !=
          Directory.systemTemp.resolveSymbolicLinksSync() ||
      !RegExp(
        r'^wing-linux-qualification-[A-Za-z0-9_]+$',
      ).hasMatch(directory.uri.pathSegments.where((s) => s.isNotEmpty).last) ||
      FileSystemEntity.isLinkSync(marker.path) ||
      !marker.existsSync() ||
      !RegExp(r'^[a-f0-9]{64}$').hasMatch(marker.readAsStringSync())) {
    throw StateError('Use the owned Linux Chat campaign root');
  }
  return root;
}

/// Reuses the restart fixture's wire handlers and saved synthetic Agent state;
/// only allocation is adapted to the worker's reserved port range.
class _OwnedChatRestartFixture extends IntegratedDailyRestartFixture {
  _OwnedChatRestartFixture(super.root, super.phase);
  @override
  Future<void> start() async {
    final port = int.parse(Platform.environment['AUTOWORK_PORT_BASE']!) + 80;
    if (phase == 'verify') {
      final saved =
          jsonDecode(File('$root/cache/backend.json').readAsStringSync())
              as Map;
      if (saved['port'] != port) {
        throw StateError('Restart fixture port changed');
      }
      history.addAll(
        (saved['history'] as List).map(
          (r) => (r as Map).cast<String, Object?>(),
        ),
      );
      submits = saved['submits'] as int;
      statuses.addAll((saved['statuses'] as Map).cast<String, String>());
    }
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    origin = 'http://127.0.0.1:$port';
    server.listen((request) async {
      try {
        await handle(request);
      } catch (_) {
        request.response.statusCode = 500;
        await request.response.close();
      }
    });
  }
}

Map<String, String> _restartSources() => {
  for (final path in [
    'integration_test/linux_chat_feature_qualification_test.dart',
    'integration_test/support/linux_chat_feature_fixture.dart',
    'integration_test/support/integrated_daily_restart_fixture.dart',
    'lib/core/hermes/channel/hermes_api_channel.dart',
    'lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart',
    'lib/features/hermes_chat/gateways/hermes_gateway_directory.dart',
    'lib/features/hermes_chat/gateways/gateway_contact_cache.dart',
  ])
    path: sha256.convert(File(path).readAsBytesSync()).toString(),
};

/// Registered only by a fixed child phase of this same committed native target.
/// Each invocation has a fresh GTK process and real, isolated preferences.
void registerLinuxChatRestartPhase(String root, String phase) {
  if (!{'write', 'verify'}.contains(phase)) {
    throw StateError('Unknown restart phase');
  }
  testWidgets('Linux Chat source-bound restart phase', (tester) async {
    final binding = tester.binding as IntegrationTestWidgetsFlutterBinding;
    await binding.setSurfaceSize(const Size(1280, 1000));
    binding.testTextInput.register();
    addTearDown(binding.testTextInput.unregister);
    await tester.pumpWidget(const SizedBox.shrink());
    await waitLinuxChat(
      tester,
      () => binding.lifecycleState == AppLifecycleState.resumed,
    );
    final prefs = await SharedPreferences.getInstance();
    if (phase == 'write') {
      expect(prefs.getKeys(), isEmpty);
      await prefs.setStringList('wing.tips.dismissed.v1', [
        'moreDestinations',
        'voice',
        'approvals',
      ]);
    }
    final sources = _restartSources();
    final fixture = _OwnedChatRestartFixture(root, phase);
    final cache = GatewayContactCache();
    final remembered = await cache.loadSelection();
    expect(
      remembered?.sessionId,
      phase == 'write' ? null : IntegratedDailyRestartFixture.session,
    );
    await tester.runAsync(fixture.start);
    final channel = HermesApiChannel();
    final store = IntegratedDailyEndpointStore(fixture.origin);
    final directory = HermesGatewayDirectory(
      store: store,
      cache: cache,
      loader: const HermesApiGatewaySummaryLoader(),
      activeChannel: channel,
    );
    final container = ProviderContainer(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesEndpointStoreProvider.overrideWithValue(store),
        hermesGatewayDirectoryProvider.overrideWith((ref) {
          final lifetime = ref.watch(hermesDirectoryLifetimeProvider);
          lifetime.attach(directory);
          ref.onDispose(() => lifetime.detach(directory));
          return directory;
        }),
        hermesVoiceCaptureServiceProvider.overrideWithValue(null),
        hermesTextToSpeechServiceProvider.overrideWithValue(null),
      ],
    );
    try {
      await tester.runAsync(directory.start);
      await waitLinuxChat(tester, () => !directory.refreshing);
      expect(
        fixture.mutations,
        isEmpty,
        reason: 'Startup must not replay mutations',
      );
      if (phase == 'write') {
        expect(
          directory.contacts.map((c) => c.id.profileId),
          contains(IntegratedDailyRestartFixture.profile),
          reason: 'Synthetic bootstrap reads: ${jsonEncode(fixture.requests)}',
        );
        final contact = directory.contacts.singleWhere(
          (c) => c.id.profileId == IntegratedDailyRestartFixture.profile,
        );
        await tester.runAsync(
          () => directory.activate(
            contact.id,
            preferredSessionId: IntegratedDailyRestartFixture.session,
          ),
        );
        expect(fixture.mutations, isEmpty);
        await tester.runAsync(
          () => channel.lockSessionModel(
            sessionId: IntegratedDailyRestartFixture.session,
            provider: 'synthetic',
            model: 'synthetic/model',
          ),
        );
      } else {
        expect(
          channel.state.sessionModelLocks,
          isEmpty,
          reason: 'A restart must not manufacture a model lock',
        );
      }
      expect(
        channel.state.selectedProfileId,
        IntegratedDailyRestartFixture.profile,
      );
      expect(
        channel.state.activeSessionId,
        IntegratedDailyRestartFixture.session,
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HermesChatScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (phase == 'write') {
        final field = find.byKey(const ValueKey('hermes-composer-field'));
        await tester.enterText(field, 'Synthetic restart deliberate prompt');
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
        await tester.pump();
        await waitLinuxChat(
          tester,
          () => find
              .byKey(const ValueKey('hermes-approval-once'))
              .evaluate()
              .isNotEmpty,
        );
        await tester.tap(find.byKey(const ValueKey('hermes-approval-once')));
        await tester.pump();
        await waitLinuxChat(
          tester,
          () => channel.state.activeMessages.any(
            (m) => m.id == 'canonical_run_1',
          ),
        );
        expect(fixture.mutations.map((m) => m['path']), [
          '/api/sessions/${IntegratedDailyRestartFixture.session}/model',
          '/v1/runs',
          '/v1/runs/run_1/approval',
        ]);
        expect(fixture.mutations[1]['body'], {
          'session_id': IntegratedDailyRestartFixture.session,
          'input': 'Synthetic restart deliberate prompt',
          'message': 'Synthetic restart deliberate prompt',
        });
        expect(fixture.mutations[2]['body'], {
          'request_id': 'approval_run_1',
          'choice': 'once',
        });
        fixture.save();
      } else {
        expect(find.text('Synthetic canonical reply run_1'), findsWidgets);
        expect(fixture.mutations, isEmpty);
        expect(
          fixture.requests.any(
            (r) =>
                r['path'] ==
                '/api/sessions/${IntegratedDailyRestartFixture.session}',
          ),
          true,
        );
      }
      expect(fixture.submits, 1);
      expect(
        fixture.mutations.every(
          (m) => m['profile'] == IntegratedDailyRestartFixture.profile,
        ),
        true,
      );
      expect(
        channel.state.activeMessages
            .where((m) => m.id.startsWith('canonical_'))
            .map((m) => m.id),
        ['canonical_run_1'],
      );
      final selected = await tester.runAsync(cache.loadSelection);
      expect(
        selected?.contactId.profileId,
        IntegratedDailyRestartFixture.profile,
      );
      expect(selected?.sessionId, IntegratedDailyRestartFixture.session);
      expect(_restartSources(), sources);
      final pending = File('$root/cache/chat-restart-$phase.pending');
      pending.writeAsStringSync(
        jsonEncode({
          'schema': 1,
          'phase': phase,
          'native_pid': pid,
          'source_inputs': sources,
          'profile': selected!.contactId.profileId,
          'session': selected.sessionId,
          'canonical_ids': ['canonical_run_1'],
          'submissions': fixture.submits,
          'operation_counts': {
            'model': phase == 'write' ? 1 : 0,
            'send': phase == 'write' ? 1 : 0,
            'approval': phase == 'write' ? 1 : 0,
            'restore_mutations': 0,
          },
        }),
      );
      pending.renameSync('$root/cache/chat-restart-$phase.json');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 1)),
      );
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(channel.disconnect);
      container.dispose();
      channel.dispose();
      await tester.runAsync(fixture.dispose);
    }
  });
}

Future<(Map<String, int>, List<Map<String, Object?>>)> runLinuxChatRestartPair(
  String root,
) async {
  final sources = _restartSources();
  final childRoot = await Directory.systemTemp.createTemp(
    'wing-linux-qualification-',
  );
  final evidence = <Map<String, Object?>>[];
  var removable = true;
  final environment = <String, String>{
    for (final name in [
      'PATH',
      'TMPDIR',
      'PUB_CACHE',
      'AUTOWORK_PORT_BASE',
      'LANG',
      'LC_ALL',
      'PKG_CONFIG_PATH',
      'CMAKE_PREFIX_PATH',
      'LIBRARY_PATH',
      'LD_LIBRARY_PATH',
      'CPATH',
      'GDK_BACKEND',
      'LIBGL_ALWAYS_SOFTWARE',
      'CMAKE_BUILD_PARALLEL_LEVEL',
      'FLUTTER_SUPPRESS_ANALYTICS',
      'DART_SUPPRESS_ANALYTICS',
      'CI',
    ])
      if (Platform.environment[name] case final String value) name: value,
    'HOME': '${childRoot.path}/home',
    'XDG_CONFIG_HOME': '${childRoot.path}/config',
    'XDG_DATA_HOME': '${childRoot.path}/data',
    'XDG_CACHE_HOME': '${childRoot.path}/cache',
    'XDG_RUNTIME_DIR': '${childRoot.path}/runtime',
    'WING_LINUX_TEST_ROOT': childRoot.path,
  };
  for (final name in ['home', 'config', 'data', 'cache', 'runtime']) {
    await Directory('${childRoot.path}/$name').create();
  }
  await File(
    '$root/.wing-linux-test-owner',
  ).copy('${childRoot.path}/.wing-linux-test-owner');
  try {
    for (final phase in ['write', 'verify']) {
      final command = [
        'xvfb-run',
        '-a',
        '-s',
        '-screen 0 1440x1000x24 -nolisten tcp',
        'flutter',
        'test',
        '--no-pub',
        '-d',
        'linux',
        '--plain-name',
        'Linux Chat source-bound restart phase',
        'integration_test/linux_chat_feature_qualification_test.dart',
      ];
      final receipt = File('${childRoot.path}/cache/chat-restart-$phase.json');
      final log = File('$root/cache/chat-restart-$phase.log');
      final sink = log.openWrite();
      final process = await Process.start(
        '/bin/bash',
        ['-c', r'exec "$@" 2>&1', 'restart', ...command],
        environment: {...environment, 'WING_LINUX_CHAT_RESTART_PHASE': phase},
        includeParentEnvironment: false,
      );
      final output = process.stdout.listen((bytes) {
        sink.add(bytes);
        stdout.add(bytes);
      });
      final errors = process.stderr.listen((bytes) {
        sink.add(bytes);
        stderr.add(bytes);
      });
      Map<String, Object?>? observed;
      Object? observationFailure;
      final group = File(
        '/proc/self/stat',
      ).readAsStringSync().split(')').last.trim().split(' ')[2];
      final observer = Timer.periodic(const Duration(milliseconds: 50), (_) {
        if (!receipt.existsSync() ||
            observed != null ||
            observationFailure != null) {
          return;
        }
        try {
          final value = jsonDecode(receipt.readAsStringSync()) as Map;
          final native = value['native_pid'] as int;
          final fields = File(
            '/proc/$native/stat',
          ).readAsStringSync().split(')').last.trim().split(' ');
          if (native == pid || fields[2] != group || fields[0] == 'Z') {
            throw StateError('Unowned restart GTK process');
          }
          observed = {
            'native_pid': native,
            'start_ticks': fields[19],
            'process_group': group,
            'receipt_sha256': sha256
                .convert(receipt.readAsBytesSync())
                .toString(),
          };
        } catch (error) {
          observationFailure = error;
        }
      });
      int? code;
      try {
        code = await process.exitCode.timeout(const Duration(seconds: 240));
      } finally {
        observer.cancel();
        if (code == null) {
          removable = false;
          process.kill();
          await process.exitCode.timeout(const Duration(seconds: 5));
        }
        await output.cancel();
        await errors.cancel();
        await sink.close();
      }
      expect(
        code,
        0,
        reason: 'Restart phase $phase failed; see retained native log',
      );
      expect(observationFailure, isNull);
      expect(observed, isNotNull);
      final value =
          jsonDecode(receipt.readAsStringSync()) as Map<String, dynamic>;
      expect(value['schema'], 1);
      expect(value['phase'], phase);
      expect(value['source_inputs'], sources);
      expect(value['session'], IntegratedDailyRestartFixture.session);
      expect(value['profile'], IntegratedDailyRestartFixture.profile);
      expect(value['canonical_ids'], ['canonical_run_1']);
      expect(value['submissions'], 1);
      expect(value['operation_counts'], {
        'model': phase == 'write' ? 1 : 0,
        'send': phase == 'write' ? 1 : 0,
        'approval': phase == 'write' ? 1 : 0,
        'restore_mutations': 0,
      });
      final native = observed!['native_pid'];
      bool stillLive() {
        try {
          final fields = File(
            '/proc/$native/stat',
          ).readAsStringSync().split(')').last.trim().split(' ');
          return fields[19] == observed!['start_ticks'] && fields[0] != 'Z';
        } on FileSystemException {
          return false;
        }
      }

      for (var i = 0; i < 100 && stillLive(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      if (stillLive()) removable = false;
      expect(stillLive(), false, reason: 'Restart native child must terminate');
      expect(
        sha256.convert(receipt.readAsBytesSync()).toString(),
        observed!['receipt_sha256'],
      );
      evidence.add({
        ...value,
        ...observed!,
        'exit_code': code,
        'native_gone': true,
        'log_sha256': sha256.convert(log.readAsBytesSync()).toString(),
        'log_utf8': log.readAsStringSync(),
        'command': command,
      });
    }
    expect(evidence[0]['native_pid'], isNot(evidence[1]['native_pid']));
    expect(_restartSources(), sources);
    return (
      {
        'model': 1,
        'send': 1,
        'approval': 1,
        'restart_processes': evidence.length,
        'restore_mutations': 0,
      },
      evidence,
    );
  } finally {
    if (removable) await childRoot.delete(recursive: true);
  }
}

/// Write once, after all cases terminate, while GTK remains observable by driver.
class LinuxChatCases {
  LinuxChatCases(this.root);
  final String root;
  final rows = <Map<String, Object?>>[];
  static const expectedIds = [
    'chat.queue-fifo',
    'chat.streaming-overlay',
    'chat.two-process-recovery',
    'chat.json-frozen-boundary',
    'chat.native-stream-stop-recovery',
    'chat.bot-canonical-draft',
    'chat.bot-reject-registry',
    'chat.bot-reject-hidden',
    'chat.bot-reject-history',
    'chat.bot-reject-replacement',
    'chat.queue-owner-draft',
    'chat.native-contract-gaps',
    'chat.local-timestamps',
    'chat.json-save',
    'chat.json-refuse',
    'chat.json-cancel',
    'chat.json-owner',
    'chat.loaded-text',
    'chat.loaded-markdown',
    'chat.api-tabs-search-pages',
    'chat.api-session-actions',
    'chat.api-model-retry',
    'chat.attachment-owner',
    'chat.stale-stop',
    'chat.json-cancel-read',
  ];

  Future<void> run(
    String id,
    List<String> features,
    Future<Map<String, int>> Function() body, {
    String? backend,
    String input = 'framework',
    String storage = 'mock-preferences;real-owned-files',
    String? unsupported,
    int? ownerCount,
  }) async {
    if (!expectedIds.contains(id) || rows.any((row) => row['id'] == id)) {
      throw StateError('Unknown or duplicate qualification case');
    }
    final row = <String, Object?>{
      'id': id,
      'feature_ids': features,
      'route_ids': ['/hermes'],
      'backend': backend ?? _backend(id),
      'input': input,
      'storage': storage,
      'native_pid': pid,
      'owner_count': ownerCount ?? (_twoOwners.contains(id) ? 2 : 1),
      'operation_counts': {'completed': 0},
      'status': 'fail',
    };
    rows.add(row);
    row['operation_counts'] = await body();
    row['status'] = unsupported == null ? 'pass' : 'unsupported';
    if (unsupported != null) {
      row['negative_assertion'] = true;
      row['skip_reason'] = unsupported;
    }
  }

  static const _twoOwners = {
    'chat.bot-canonical-draft',
    'chat.bot-reject-replacement',
    'chat.queue-owner-draft',
    'chat.json-owner',
    'chat.api-tabs-search-pages',
    'chat.api-session-actions',
    'chat.attachment-owner',
    'chat.stale-stop',
  };

  static String _backend(String id) =>
      id.startsWith('chat.api-') ||
          {
            'chat.queue-owner-draft',
            'chat.queue-fifo',
            'chat.attachment-owner',
            'chat.stale-stop',
            'chat.streaming-overlay',
          }.contains(id)
      ? 'synthetic-loopback-http-sse'
      : 'authenticated-loopback-rest-native-rpc';

  static List<String> _features(String id) => switch (id) {
    'chat.native-stream-stop-recovery' => [
      'HD-CHAT',
      'HD-APPROVAL',
      'HD-STOP',
      'HD-RESUME',
    ],
    'chat.bot-canonical-draft' ||
    'chat.bot-reject-registry' ||
    'chat.bot-reject-hidden' ||
    'chat.bot-reject-history' ||
    'chat.bot-reject-replacement' => ['HD-BOTS', 'HD-DRAFT'],
    'chat.queue-owner-draft' => ['HD-QUEUE', 'HD-DRAFT'],
    'chat.queue-fifo' => ['HD-QUEUE', 'HD-CHAT'],
    'chat.native-contract-gaps' => ['HD-TABS', 'HD-ATTACH', 'HD-CLARIFY'],
    'chat.local-timestamps' => ['HD-COMMAND', 'HD-CHAT'],
    'chat.json-save' ||
    'chat.json-refuse' ||
    'chat.json-cancel' ||
    'chat.json-owner' => ['HD-EXPORT', 'HD-DRAFT'],
    'chat.loaded-text' ||
    'chat.loaded-markdown' ||
    'chat.json-cancel-read' ||
    'chat.json-frozen-boundary' => ['HD-EXPORT'],
    'chat.api-tabs-search-pages' => ['HD-TABS', 'HD-SEARCH', 'HD-DRAFT'],
    'chat.api-session-actions' => ['HD-SEARCH'],
    'chat.api-model-retry' => ['HD-MODEL'],
    'chat.attachment-owner' => ['HD-ATTACH', 'HD-DRAFT'],
    'chat.stale-stop' => ['HD-STOP'],
    'chat.streaming-overlay' => ['HD-CHAT'],
    'chat.two-process-recovery' => ['HD-RESUME'],
    _ => throw StateError('Unknown qualification case'),
  };

  Future<void> publish() async {
    for (final id in expectedIds) {
      if (rows.any((row) => row['id'] == id)) continue;
      rows.add({
        'id': id,
        'feature_ids': _features(id),
        'route_ids': ['/hermes'],
        'backend': 'unexercised',
        'input': 'none',
        'storage': 'none',
        'native_pid': pid,
        'owner_count': 1,
        'operation_counts': {'completed': 0},
        'status': 'not_run',
        'skip_reason': 'Registered case did not reach its body.',
      });
    }
    final file = File('$root/feature-cases.json.pending');
    await file.writeAsString(
      jsonEncode({'schema': 1, 'cases': rows}),
      flush: true,
    );
    await file.rename('$root/feature-cases.json');
    // The campaign observes /proc while the native process is still alive.
    await Future<void>.delayed(const Duration(seconds: 1));
  }
}

Future<void> waitLinuxChat(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 300 && !done(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(
    done(),
    isTrue,
    reason: 'Public Chat action did not reach its terminal state',
  );
}

/// Real X11 input into the owned GTK chooser. No file-selector substitution.
/// Only the fixed synthetic filename under the validated campaign root is used.
Future<void> driveLinuxChatChooser(
  String root,
  String filename, {
  bool cancel = false,
  bool pick = false,
}) async {
  if (!{
    'hermes-session.json',
    'hermes-transcript.txt',
    'hermes-transcript.md',
    'sample.txt',
  }.contains(filename)) {
    throw StateError('Fixed export filename required');
  }
  final result = await Process.run('/usr/bin/python3', [
    '-c',
    _chooserInput,
    root,
    filename,
    cancel
        ? 'cancel'
        : pick
        ? 'pick'
        : 'save',
  ]);
  if (result.exitCode != 0) {
    throw StateError('Owned GTK chooser input failed: ${result.stderr}');
  }
}

const _chooserInput = r'''
import ctypes as c, sys, time
from pathlib import Path
root, name, mode = sys.argv[1:]
p = Path(root)
if p.resolve() != p or not (p / '.wing-linux-test-owner').is_file():
    raise SystemExit('Unowned chooser')
x, t = c.CDLL('libX11.so.6'), c.CDLL('libXtst.so.6')
x.XOpenDisplay.argtypes=[c.c_char_p]; x.XOpenDisplay.restype=c.c_void_p
x.XDefaultRootWindow.argtypes=[c.c_void_p]; x.XDefaultRootWindow.restype=c.c_ulong
x.XQueryTree.argtypes=[c.c_void_p,c.c_ulong,c.POINTER(c.c_ulong),c.POINTER(c.c_ulong),c.POINTER(c.POINTER(c.c_ulong)),c.POINTER(c.c_uint)]
x.XFetchName.argtypes=[c.c_void_p,c.c_ulong,c.POINTER(c.c_char_p)]
x.XFree.argtypes=[c.c_void_p]
x.XKeysymToKeycode.argtypes=[c.c_void_p,c.c_ulong]; x.XKeysymToKeycode.restype=c.c_ubyte
x.XSetInputFocus.argtypes=[c.c_void_p,c.c_ulong,c.c_int,c.c_ulong]
x.XFlush.argtypes=[c.c_void_p]; x.XCloseDisplay.argtypes=[c.c_void_p]
t.XTestFakeKeyEvent.argtypes=[c.c_void_p,c.c_uint,c.c_int,c.c_ulong]
d=x.XOpenDisplay(None)
if not d: raise SystemExit('Owned X11 display unavailable')
def windows(parent, depth=0):
    a,b,n=c.c_ulong(),c.c_ulong(),c.c_uint(); children=c.POINTER(c.c_ulong)()
    if not x.XQueryTree(d,parent,c.byref(a),c.byref(b),c.byref(children),c.byref(n)): return []
    result=[children[i] for i in range(n.value)]
    if children: x.XFree(children)
    if depth<2:
        for w in list(result): result.extend(windows(w,depth+1))
    return result
def title(w):
    n=c.c_char_p(); x.XFetchName(d,w,c.byref(n)); s=n.value.decode(errors='replace') if n.value else ''
    if n: x.XFree(n)
    return s
def key(sym,down):
    code=x.XKeysymToKeycode(d,sym)
    if not code: raise RuntimeError('Missing X11 key')
    t.XTestFakeKeyEvent(d,code,int(down),0); x.XFlush(d); time.sleep(.03)
def stroke(sym): key(sym,True); key(sym,False)
def ctrl(sym): key(0xffe3,True); stroke(sym); key(0xffe3,False)
try:
    deadline=time.monotonic()+10
    while True:
        targets=[w for w in windows(x.XDefaultRootWindow(d)) if title(w) in (('Open File', 'Open file', 'Open') if mode=='pick' else ('Save File',))]
        if targets: break
        if time.monotonic()>deadline: raise RuntimeError('GTK chooser not found')
        time.sleep(.05)
    x.XSetInputFocus(d,targets[-1],2,0); x.XFlush(d); time.sleep(.1)
    if mode=='cancel': stroke(0xff1b)
    else:
        ctrl(ord('l')); time.sleep(.15); ctrl(ord('a'))
        for char in str(p/name):
            shift=char.isupper() or char=='_'
            if shift: key(0xffe1,True)
            stroke(ord('-' if char=='_' else char.lower()))
            if shift: key(0xffe1,False)
        stroke(0xff0d); time.sleep(.6); stroke(0xff0d)
finally: x.XCloseDisplay(d)
''';
