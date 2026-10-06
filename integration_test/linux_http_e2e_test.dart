import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

// Real native transport and UI against an owned, ephemeral deterministic server.
// This does not qualify a production Agent or provider inference.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.shouldPropagateDevicePointerEvents = true;
  WidgetController.hitTestWarningShouldBeFatal = true;
  late Process server;
  late String origin;

  setUpAll(() async {
    // Reserve distinct ports together, releasing them immediately before launch.
    final sockets = <ServerSocket>[
      await ServerSocket.bind(InternetAddress.loopbackIPv4, 0),
      await ServerSocket.bind(InternetAddress.loopbackIPv4, 0),
    ];
    final ports = sockets.map((socket) => socket.port).toList();
    for (final socket in sockets) {
      await socket.close();
    }
    origin = 'http://127.0.0.1:${ports[1]}';
    final script = File('serve_web.mjs').absolute;
    expect(script.existsSync(), isTrue, reason: 'Run from the Wing repo root.');
    server = await Process.start(
      'node',
      [script.path],
      environment: {'PORT': '${ports[0]}', 'HERMES_E2E_PORT': '${ports[1]}'},
    );
    // Confirm both binds belong to this child before sending any reset request.
    final listening = Completer<void>();
    final expectedAnnouncements = {
      'Server running at http://127.0.0.1:${ports[0]}/',
      'Hermes API running at $origin/',
    };
    server.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          expectedAnnouncements.remove(line);
          if (expectedAnnouncements.isEmpty && !listening.isCompleted) {
            listening.complete();
          }
        });
    unawaited(server.stderr.drain<void>());
    addTearDown(() async {
      server.kill();
      await server.exitCode.timeout(const Duration(seconds: 5));
    });
    await Future.any([
      listening.future,
      server.exitCode.then<void>(
        (_) => throw StateError('Owned HTTP fixture exited before readiness.'),
      ),
    ]).timeout(const Duration(seconds: 10));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    binding.testTextInput.register();
    addTearDown(binding.testTextInput.unregister);
    expect(
      (await _request(origin, 'POST', '/e2e/hermes/reset'))['reset'],
      true,
    );
  });

  Future<HermesApiChannel> mount(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final channel = HermesApiChannel();
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: origin);
    expect(channel.state.isConnected, isTrue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(
            const EmptyHermesEndpointStore(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return channel;
  }

  for (final width in [420.0, 1440.0]) {
    for (final allow in [true, false]) {
      testWidgets('native HTTP $width new chat and approval=$allow', (
        tester,
      ) async {
        final channel = await mount(tester, width);
        final previous = channel.state.activeSessionId;
        final create = find.byKey(const ValueKey('hermes-new-session'));
        if (create.evaluate().isEmpty) {
          await tester.tap(find.byTooltip('More actions'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('New session'));
        } else {
          await tester.tap(create);
        }
        await _wait(
          tester,
          () =>
              channel.state.activeSessionId != null &&
              channel.state.activeSessionId != previous,
        );
        expect(channel.state.activeSessionId, isNotNull);
        await _submit(tester, 'native socket approval');
        await _wait(
          tester,
          () => find.text('Approve once').evaluate().isNotEmpty,
        );
        await tester.tap(find.text(allow ? 'Approve once' : 'Deny'));
        await _wait(
          tester,
          () =>
              !channel.state.isSessionStreaming(channel.state.activeSessionId!),
        );
        await tester.pumpAndSettle();
        final messages = await _request(
          origin,
          'GET',
          '/api/sessions/${channel.state.activeSessionId}/messages',
        );
        final rows = messages['data'] as List;
        expect(rows.where((row) => row['role'] == 'user'), hasLength(1));
        expect(
          rows.where((row) => row['role'] == 'assistant'),
          hasLength(allow ? 1 : 0),
        );
        expect(
          find.text('Hermes echo: native socket approval'),
          allow ? findsOneWidget : findsNothing,
        );
        expect(
          channel.state.errorMessage,
          allow ? isNull : 'Hermes run was cancelled.',
        );
        if (!allow) {
          // Denial is terminal, not a successful reply or an implicit retry.
          // A new explicit prompt must use canonical history exactly once.
          expect(
            channel.state.activeMessages
                .where((turn) => turn.text.isEmpty)
                .single
                .status,
            HermesTurnStatus.failed,
          );
          await _submit(tester, 'native explicit after denial');
          await _wait(
            tester,
            () => find.text('Approve once').evaluate().isNotEmpty,
          );
          await tester.tap(find.text('Approve once'));
          await _wait(
            tester,
            () => !channel.state.isSessionStreaming(
              channel.state.activeSessionId!,
            ),
          );
          await tester.pumpAndSettle();
          expect(channel.state.errorMessage, isNull);
          expect(
            find.text('Hermes echo: native explicit after denial'),
            findsOneWidget,
          );
          final after = await _request(
            origin,
            'GET',
            '/api/sessions/${channel.state.activeSessionId}/messages',
          );
          expect(
            (after['data'] as List)
                .where((row) => row['role'] == 'user')
                .map((row) => row['content']),
            ['native socket approval', 'native explicit after denial'],
          );
          expect(
            (after['data'] as List).where((row) => row['role'] == 'assistant'),
            hasLength(1),
          );
        }
      });
    }

    testWidgets('native HTTP $width stop then retry sends exactly once', (
      tester,
    ) async {
      final channel = await mount(tester, width);
      await _submit(tester, 'native socket stop');
      await _wait(
        tester,
        () => find.text('Approve once').evaluate().isNotEmpty,
      );
      await tester.tap(find.widgetWithText(ActionChip, 'Stop'));
      await _wait(
        tester,
        () => !channel.state.isSessionStreaming(channel.state.activeSessionId!),
      );
      expect(
        (await _request(origin, 'GET', '/e2e/hermes/stop-count'))['stopCount'],
        1,
      );
      await tester.pumpAndSettle();
      expect(find.text('Approve once'), findsNothing);
      await _submit(tester, 'native socket retry');
      await _wait(
        tester,
        () => find.text('Approve once').evaluate().isNotEmpty,
      );
      await tester.tap(find.text('Approve once'));
      await _wait(
        tester,
        () => !channel.state.isSessionStreaming(channel.state.activeSessionId!),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hermes echo: native socket retry'), findsOneWidget);
      final wire = await _request(
        origin,
        'GET',
        '/api/sessions/${channel.state.activeSessionId}/messages',
      );
      final users = (wire['data'] as List).where(
        (row) => row['role'] == 'user',
      );
      expect(users.map((row) => row['content']), [
        'native socket stop',
        'native socket retry',
      ]);
    });
  }

  testWidgets(
    'native HTTP CRUD and repeated reconnect use server state without replay',
    (tester) async {
      final channel = await mount(tester, 1440);
      await channel.createSession();
      final original = channel.state.activeSessionId!;
      await channel.renameSession(sessionId: original, title: 'Native renamed');
      await channel.forkSession(original, title: 'Native fork');
      final fork = channel.state.activeSessionId!;
      expect(fork, isNot(original));
      await channel.selectSession(original);
      await tester.pumpAndSettle();
      await _submit(tester, 'native reconnect once');
      await _wait(
        tester,
        () => find.text('Approve once').evaluate().isNotEmpty,
      );
      await tester.tap(find.text('Approve once'));
      await _wait(tester, () => !channel.state.isSessionStreaming(original));
      for (var cycle = 0; cycle < 3; cycle++) {
        await channel.disconnect();
        await channel.connect(baseUrl: origin);
        await channel.selectSession(original);
        await channel.reconcileActiveSession();
        expect(channel.state.activeSession?.title, 'Native renamed');
        final wire = await _request(
          origin,
          'GET',
          '/api/sessions/$original/messages',
        );
        expect(wire['data'] as List, hasLength(2));
      }
      await channel.deleteSession(fork);
      await channel.deleteSession(original);
      await channel.disconnect();
      await channel.connect(baseUrl: origin);
      expect(
        channel.state.sessions.any((s) => s.id == fork || s.id == original),
        isFalse,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _submit(WidgetTester tester, String text) async {
  await tester.enterText(
    find.byKey(const ValueKey('hermes-composer-field')),
    text,
  );
  await _wait(
    tester,
    () =>
        find
            .byKey(const ValueKey('hermes-send-button'))
            .evaluate()
            .isNotEmpty &&
        tester
                .widget<IconButton>(
                  find.byKey(const ValueKey('hermes-send-button')),
                )
                .onPressed !=
            null,
  );
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
  await tester.pump();
}

Future<void> _wait(WidgetTester tester, bool Function() predicate) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (!predicate() && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(
    predicate(),
    isTrue,
    reason: 'Native HTTP flow did not reach its checkpoint.',
  );
  await tester.pump(const Duration(milliseconds: 100));
}

Future<Map<String, dynamic>> _request(
  String origin,
  String method,
  String path,
) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
  try {
    final request = await client.openUrl(method, Uri.parse('$origin$path'));
    final response = await request.close().timeout(const Duration(seconds: 5));
    expect(response.statusCode, 200);
    return jsonDecode(await utf8.decoder.bind(response).join())
        as Map<String, dynamic>;
  } finally {
    client.close(force: true);
  }
}
