import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/app_router.dart';

import '../test/features/hermes_chat/support/fake_hermes_endpoint_store.dart';
import '../test/shared/widgets/app_shell_navigation_groups_test.dart'
    as navigation;

// Real loopback HTTP/SSE and production client; no Agent, provider or credentials.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Linux overlays retain progressive HTTP/SSE Chat', (
    tester,
  ) async {
    final root = Platform.environment['WING_LOCAL_ROOT'];
    if (!Platform.isLinux ||
        root == null ||
        Platform.environment['HOME'] != '$root/home' ||
        Platform.environment['XDG_CONFIG_HOME'] != '$root/config' ||
        Platform.environment['XDG_DATA_HOME'] != '$root/data' ||
        Platform.environment['XDG_CACHE_HOME'] != '$root/cache' ||
        Platform.environment['DBUS_SESSION_BUS_ADDRESS'] != null) {
      throw StateError('Use the isolated Linux streaming runner.');
    }
    Future<void> settle() async {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> until(bool Function() ready) async {
      for (var i = 0; i < 100 && !ready(); i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(ready(), isTrue, reason: 'HTTP/SSE client barrier');
    }

    final semantics = tester.ensureSemantics();
    final journeys = <Map<String, Object?>>[];
    for (final width in [390.0, 1280.0]) {
      await binding.setSurfaceSize(Size(width, 900));
      for (final destination in ['settings', 'profiles']) {
        for (final dismissal in ['close', 'escape', 'back']) {
          SharedPreferences.setMockInitialValues({});
          final fixture = (await tester.runAsync(_StreamFixture.start))!;
          final channel = HermesApiChannel();
          final store = FakeHermesEndpointStore();
          final container = ProviderContainer(
            overrides: [
              hermesChannelProvider.overrideWithValue(channel),
              hermesEndpointStoreProvider.overrideWithValue(store),
            ],
          );
          final router = container.read(routerProvider);
          try {
            await tester.runAsync(
              () => channel.connect(baseUrl: fixture.origin),
            );
            expect(channel.state.isConnected, isTrue);
            expect(channel.state.activeSessionId, 'sess_1');
            const location = '/hermes?session=sess_1&filter=all#tail';
            router.go(location);
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: MaterialApp.router(
                  routerConfig: router,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(2),
                      disableAnimations: true,
                    ),
                    child: child!,
                  ),
                ),
              ),
            );
            await settle();
            final chat = tester.state(find.byType(HermesChatScreen));
            final field = find.byKey(const ValueKey('hermes-composer-field'));
            await tester.enterText(field, _StreamFixture.prompt);
            await tester.pump();
            await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
            await until(() => fixture.stream != null);
            await tester.runAsync(() => fixture.delta('Synthetic progressive'));
            await until(
              () =>
                  channel.state.activeMessages.last.text ==
                  'Synthetic progressive',
            );
            expect(
              channel.state.activeMessages.last.status,
              HermesTurnStatus.streaming,
            );
            expect(find.text('Synthetic progressive'), findsOneWidget);
            await tester.tap(field);
            await tester.pump();
            await tester.enterText(field, 'Synthetic unsent next draft');
            final controller = tester.widget<TextField>(field).controller!;
            await settle();
            expect(controller.text, 'Synthetic unsent next draft');
            if (width < 600) {
              await tester.tap(
                find.descendant(
                  of: find.byType(NavigationBar),
                  matching: find.text(
                    destination == 'settings' ? 'More' : 'Profiles',
                  ),
                ),
              );
              await settle();
              if (destination == 'settings') {
                await tester.tap(find.text('Settings').last);
              }
            } else {
              await tester.tap(
                destination == 'settings'
                    ? find.bySemanticsLabel('Settings')
                    : find.byKey(const ValueKey('desktop-manage-profiles')),
              );
            }
            await settle();
            final close = find.byKey(
              const ValueKey('chat-workspace-overlay-close'),
            );
            expect(close, findsOneWidget);
            expect(chat.mounted, isTrue);
            expect(
              navigation.flag(tester, close, focused: true),
              isTrue,
              reason:
                  'overlay initial focus $width $dismissal: ${FocusManager.instance.primaryFocus}',
            );
            expect(
              channel.state.activeMessages.last.status,
              HermesTurnStatus.streaming,
            );
            // A second client-consumed chunk precedes terminal release, not one burst.
            await tester.runAsync(() => fixture.delta(' reply.'));
            await until(
              () =>
                  channel.state.activeMessages.last.text ==
                  _StreamFixture.reply,
            );
            expect(
              channel.state.activeMessages.last.status,
              HermesTurnStatus.streaming,
            );
            expect(close, findsOneWidget);
            await tester.runAsync(fixture.complete);
            await until(
              () => channel.state.activeMessages.last.id == 'canonical-reply',
            );
            await settle();
            expect(
              tester.widget<TextField>(field).focusNode!.hasFocus,
              isFalse,
            );
            expect(
              channel.state.activeMessages.last.status,
              HermesTurnStatus.completed,
            );
            expect(
              channel.state.activeMessages.last.text,
              _StreamFixture.reply,
            );
            expect(close, findsOneWidget);
            expect(chat.mounted, isTrue);
            expect(
              navigation.flag(tester, close, focused: true),
              isTrue,
              reason:
                  'overlay completed focus $width $dismissal: ${FocusManager.instance.primaryFocus}',
            );
            if (dismissal == 'close') {
              await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            } else if (dismissal == 'escape') {
              await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            } else {
              await tester.binding.handlePopRoute();
            }
            await settle();
            expect(close, findsNothing, reason: '$width $dismissal dismissal');
            expect(tester.state(find.byType(HermesChatScreen)), same(chat));
            expect(
              tester.widget<TextField>(field).controller,
              same(controller),
            );
            expect(controller.text, 'Synthetic unsent next draft');
            expect(
              router.routeInformationProvider.value.uri.toString(),
              location,
            );
            expect(channel.state.connectedBaseUrl, fixture.origin);
            expect(channel.state.activeSessionId, 'sess_1');
            expect(find.text(_StreamFixture.reply), findsOneWidget);
            expect(channel.state.errorMessage, isNull);
            expect(fixture.writes, ['POST /api/sessions/sess_1/chat/stream']);
            expect(fixture.unexpected, isEmpty);
            expect(fixture.historyReads, 2);
            expect(store.saveCalls, isEmpty);
            expect(tester.takeException(), isNull);
            journeys.add({
              'width': width,
              'destination': destination,
              'dismissal': dismissal,
              'text_scale': 2,
              'progressive_chunks': 2,
              'completed_under_overlay': true,
              'canonical_reply': true,
              'chat_retained': true,
              'draft_retained': true,
              'exact_owner_retained': true,
              'exact_location_retained': true,
              'sends': fixture.writes.length,
              'history_reads': fixture.historyReads,
              'unexpected_requests': fixture.unexpected.length,
              'endpoint_saves': store.saveCalls.length,
            });
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await settle();
            router.dispose();
            container.dispose();
            channel.dispose();
            await tester.runAsync(() => fixture.server.close(force: true));
          }
        }
      }
    }
    semantics.dispose();
    await binding.setSurfaceSize(null);
    File('$root/cache/chat-workspace-stream.json.pending')
      ..writeAsStringSync(jsonEncode({'native_pid': pid, 'journeys': journeys}))
      ..renameSync('$root/cache/chat-workspace-stream.json');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
  });
}

class _StreamFixture {
  _StreamFixture(this.server);
  final HttpServer server;
  HttpResponse? stream;
  final writes = <String>[];
  final unexpected = <String>[];
  var historyReads = 0;
  var completed = false;
  static const prompt = 'Synthetic native streaming request';
  static const reply = 'Synthetic progressive reply.';
  String get origin => 'http://127.0.0.1:${server.port}';

  static Future<_StreamFixture> start() async {
    final fixture = _StreamFixture(
      await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
    );
    fixture.server.listen(fixture.handle);
    return fixture;
  }

  Future<void> delta(String text) async {
    stream!.write(
      'event: assistant.delta\ndata: ${jsonEncode({'delta': text})}\n\n',
    );
    await stream!.flush();
  }

  Future<void> complete() async {
    completed = true;
    stream!.write('data: [DONE]\n\n');
    await stream!.close();
  }

  Future<void> handle(HttpRequest request) async {
    final route = '${request.method} ${request.uri.path}';
    final response = request.response;
    if (request.method != 'GET') writes.add(route);
    Object? body;
    switch (route) {
      case 'GET /health':
        body = {'status': 'ok'};
      case 'GET /v1/capabilities':
        body = {
          'object': 'hermes.api_server.capabilities',
          'platform': 'hermes-agent',
          'model': 'hermes-agent',
          'auth': {'type': 'bearer', 'required': false},
          'features': {'session_chat_streaming': true},
          'endpoints': {
            'session_chat_stream': {
              'method': 'POST',
              'path': '/api/sessions/{session_id}/chat/stream',
            },
          },
        };
      case 'GET /api/sessions':
        body = {
          'object': 'list',
          'data': [
            {
              'id': 'sess_1',
              'source': 'api_server',
              'title': 'Synthetic native stream',
              'message_count': completed ? 2 : 0,
            },
          ],
        };
      case 'GET /api/sessions/sess_1/messages':
        historyReads++;
        body = {
          'object': 'list',
          'session_id': 'sess_1',
          'data': [
            if (completed) ...[
              {
                'id': 'canonical-prompt',
                'session_id': 'sess_1',
                'role': 'user',
                'content': prompt,
              },
              {
                'id': 'canonical-reply',
                'session_id': 'sess_1',
                'role': 'assistant',
                'content': reply,
              },
            ],
          ],
        };
      case 'POST /api/sessions/sess_1/chat/stream':
        final payload = jsonDecode(await utf8.decoder.bind(request).join());
        if (payload is! Map ||
            payload['message'] != prompt ||
            payload.length != 1 ||
            stream != null) {
          unexpected.add('Invalid or duplicate Send');
          response.statusCode = HttpStatus.badRequest;
          await response.close();
          return;
        }
        response.headers.contentType = ContentType(
          'text',
          'event-stream',
          charset: 'utf-8',
        );
        response.bufferOutput = false;
        stream = response;
        response.write(': synthetic stream ready\n\n');
        await response.flush();
        return;
      default:
        unexpected.add(route);
        response.statusCode = HttpStatus.notFound;
        body = {'error': 'Unexpected synthetic request'};
    }
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(body));
    await response.close();
  }
}
