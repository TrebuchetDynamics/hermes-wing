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
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
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
      for (final destination in [
        'settings',
        'profiles',
        'profile-switch',
        'connection-switch',
      ]) {
        if (width < 600 && destination == 'connection-switch') continue;
        for (final dismissal in ['close', 'escape', 'back']) {
          SharedPreferences.setMockInitialValues({});
          final fixture = (await tester.runAsync(_StreamFixture.start))!;
          final replacement = destination == 'connection-switch'
              ? (await tester.runAsync(
                  () => _StreamFixture.start(replacement: true),
                ))!
              : null;
          final channel = HermesApiChannel();
          final store = FakeHermesEndpointStore(
            profiles: [
              if (replacement != null) ...[
                HermesEndpointConfig(
                  id: 'original',
                  label: 'Synthetic original host',
                  baseUrl: fixture.origin,
                ),
                HermesEndpointConfig(
                  id: 'replacement',
                  label: 'Synthetic replacement host',
                  baseUrl: replacement.origin,
                ),
              ],
            ],
          );
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
            await tester.runAsync(() => channel.selectProfile('default'));
            expect(channel.state.selectedProfileId, 'default');
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
                      size: Size(width, 900),
                      textScaler: TextScaler.linear(2),
                      disableAnimations: true,
                    ),
                    child: child!,
                  ),
                ),
              ),
            );
            await settle();
            if (replacement != null) {
              final original = find.byKey(
                const ValueKey('gateway-contact-original-default'),
              );
              await until(() => original.evaluate().isNotEmpty);
              await tester.ensureVisible(original);
              await settle();
              await tester.tap(original);
              await until(
                () =>
                    container
                        .read(hermesGatewayDirectoryProvider)
                        .activeContactId
                        ?.gatewayId ==
                    'original',
              );
              await settle();
            }
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
                    (destination == 'settings' || replacement != null)
                        ? 'More'
                        : 'Profiles',
                  ),
                ),
              );
              await settle();
              if ((destination == 'settings' || replacement != null)) {
                await tester.tap(find.text('Settings').last);
              }
            } else {
              await tester.tap(
                (destination == 'settings' || replacement != null)
                    ? find.bySemanticsLabel('Settings')
                    : find.byKey(const ValueKey('desktop-manage-profiles')),
              );
            }
            await settle();
            final close = find.byKey(
              const ValueKey('chat-workspace-overlay-close'),
            );
            expect(close, findsOneWidget);
            if (destination != 'settings' && replacement == null) {
              expect(
                find.byKey(const ValueKey('agent-chat-coder')),
                findsOneWidget,
              );
              expect(find.text('Coding profile'), findsOneWidget);
            }
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
            if (replacement != null) {
              final connections = find.descendant(
                of: find.byType(ListTile),
                matching: find.text('Connections'),
              );
              await tester.ensureVisible(connections);
              await settle();
              await tester.tap(connections);
              await settle();
              final row = find.byKey(
                const ValueKey('connection-host-replacement'),
              );
              await until(() => row.evaluate().isNotEmpty);
              await tester.ensureVisible(row);
              await settle();
              expect(row.hitTestable(), findsOneWidget);
              await tester.tap(row);
              await settle();
              final connect = find.byKey(
                const ValueKey('gateway-connect-chat-button'),
              );
              await tester.ensureVisible(connect);
              await settle();
              expect(connect.hitTestable(), findsOneWidget);
              await tester.tap(connect);
              await until(
                () =>
                    channel.state.connectedBaseUrl == replacement.origin &&
                    channel.state.activeSessionId == 'replacement_session' &&
                    channel.state.activeMessages.length == 1 &&
                    channel.state.activeMessages.single.id ==
                        'replacement-reply',
              );
              // Keep the original server pending until the exact new owner settles.
              expect(fixture.completed, isFalse);
              expect(replacement.replacementHistoryReads, greaterThan(0));
              final chatAction = find.descendant(
                of: find.byKey(const ValueKey('desktop-sidebar')),
                matching: find.bySemanticsLabel('Chat'),
              );
              await tester.tap(chatAction);
              await settle();
              final replacementChat = tester.state(
                find.byType(HermesChatScreen),
              );
              expect(
                find.text(_StreamFixture.replacementReply),
                findsOneWidget,
              );
              expect(find.text(_StreamFixture.reply), findsNothing);
              await tester.runAsync(fixture.complete);
              final canonical = await tester.runAsync(() async {
                final client = HttpClient();
                try {
                  final request = await client.getUrl(
                    Uri.parse('${fixture.origin}/api/sessions/sess_1/messages'),
                  );
                  final response = await request.close();
                  return jsonDecode(await utf8.decoder.bind(response).join())
                      as Map<String, dynamic>;
                } finally {
                  client.close(force: true);
                }
              });
              expect(canonical!['session_id'], 'sess_1');
              expect((canonical['data'] as List).last, {
                'id': 'canonical-reply',
                'session_id': 'sess_1',
                'role': 'assistant',
                'content': _StreamFixture.reply,
              });
              await settle();
              await tester.tap(find.bySemanticsLabel('Settings'));
              await settle();
              expect(close, findsOneWidget);
              if (dismissal == 'close') {
                await tester.tap(close);
              } else if (dismissal == 'escape') {
                await tester.sendKeyEvent(LogicalKeyboardKey.escape);
              } else {
                await tester.binding.handlePopRoute();
              }
              await settle();
              expect(close, findsNothing);
              expect(channel.state.connectedBaseUrl, replacement.origin);
              expect(channel.state.activeSessionId, 'replacement_session');
              expect(
                channel.state.activeMessages.single.id,
                'replacement-reply',
              );
              expect(
                channel.state.activeMessages.single.status,
                HermesTurnStatus.completed,
              );
              expect(channel.state.errorMessage, isNull);
              expect(
                find.text(_StreamFixture.replacementReply),
                findsOneWidget,
              );
              expect(find.text(_StreamFixture.reply), findsNothing);
              expect(find.text('Synthetic progressive'), findsNothing);
              expect(
                tester.state(find.byType(HermesChatScreen)),
                same(replacementChat),
              );
              expect(fixture.writes, ['POST /api/sessions/sess_1/chat/stream']);
              expect(replacement.writes, isEmpty);
              expect(fixture.unexpected, isEmpty);
              expect(replacement.unexpected, isEmpty);
              expect(store.saveCalls, isEmpty);
              expect(tester.takeException(), isNull);
              journeys.add({
                'width': width,
                'destination': destination,
                'dismissal': dismissal,
                'text_scale': 2,
                'progressive_chunks': 2,
                'canonical_reply': true,
                'chat_retained': true,
                'sends': fixture.writes.length,
                'unexpected_requests':
                    fixture.unexpected.length + replacement.unexpected.length,
                'endpoint_saves': store.saveCalls.length,
                'selected_session': 'replacement_session',
                'distinct_origin': replacement.origin != fixture.origin,
                'replacement_history_read':
                    replacement.replacementHistoryReads > 0,
                'replacement_writes': replacement.writes.length,
                'old_completed_after_replacement': fixture.completed,
                'stale_reply_absent': true,
              });
              continue;
            }
            if (destination == 'profile-switch') {
              final action = find.byKey(const ValueKey('agent-chat-coder'));
              await tester.ensureVisible(action);
              await settle();
              expect(action.hitTestable(), findsOneWidget);
              await tester.tap(action);
              await until(
                () =>
                    channel.state.selectedProfileId == 'coder' &&
                    channel.state.activeSessionId == 'coder_session' &&
                    channel.state.activeMessages.isNotEmpty,
              );
              await settle();
              expect(close, findsNothing);
              expect(find.text(_StreamFixture.coderReply), findsOneWidget);
              expect(tester.state(find.byType(HermesChatScreen)), same(chat));
              await tester.runAsync(fixture.complete);
              await settle();
              if (width < 600) {
                await tester.tap(
                  find.descendant(
                    of: find.byType(NavigationBar),
                    matching: find.text('Profiles'),
                  ),
                );
              } else {
                await tester.tap(
                  find.byKey(const ValueKey('desktop-manage-profiles')),
                );
              }
              await settle();
              expect(close, findsOneWidget);
              if (dismissal == 'close') {
                await tester.sendKeyEvent(LogicalKeyboardKey.enter);
              } else if (dismissal == 'escape') {
                await tester.sendKeyEvent(LogicalKeyboardKey.escape);
              } else {
                await tester.binding.handlePopRoute();
              }
              await settle();
              expect(close, findsNothing);
              expect(channel.state.selectedProfileId, 'coder');
              expect(channel.state.activeSessionId, 'coder_session');
              expect(channel.state.connectedBaseUrl, fixture.origin);
              expect(channel.state.activeMessages.single.id, 'coder-reply');
              expect(find.text(_StreamFixture.coderReply), findsOneWidget);
              expect(find.text(_StreamFixture.reply), findsNothing);
              expect(
                channel.state.activeMessages.single.status,
                HermesTurnStatus.completed,
              );
              expect(channel.state.errorMessage, isNull);
              expect(tester.state(find.byType(HermesChatScreen)), same(chat));
              expect(
                router.routeInformationProvider.value.uri.toString(),
                location,
              );
              expect(fixture.writes, ['POST /api/sessions/sess_1/chat/stream']);
              expect(fixture.unexpected, isEmpty);
              expect(fixture.coderHistoryReads, 1);
              expect(store.saveCalls, isEmpty);
              expect(tester.takeException(), isNull);
              journeys.add({
                'width': width,
                'destination': destination,
                'dismissal': dismissal,
                'text_scale': 2,
                'progressive_chunks': 2,
                'selected_profile': 'coder',
                'selected_session': 'coder_session',
                'canonical_reply': true,
                'chat_retained': true,
                'exact_location_retained': true,
                'sends': fixture.writes.length,
                'replacement_history_reads': fixture.coderHistoryReads,
                'unexpected_requests': fixture.unexpected.length,
                'endpoint_saves': store.saveCalls.length,
              });
              continue;
            }
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
            expect(fixture.historyReads, 3);
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
            if (replacement != null) {
              await tester.runAsync(
                () => replacement.server.close(force: true),
              );
            }
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
  _StreamFixture(this.server, {this.replacement = false});
  final bool replacement;
  final HttpServer server;
  HttpResponse? stream;
  final writes = <String>[];
  final unexpected = <String>[];
  var historyReads = 0;
  var coderHistoryReads = 0;
  var replacementHistoryReads = 0;
  var completed = false;
  static const prompt = 'Synthetic native streaming request';
  static const reply = 'Synthetic progressive reply.';
  static const coderReply = 'Synthetic coding profile history.';
  static const replacementReply = 'Synthetic replacement host history.';
  String get origin => 'http://127.0.0.1:${server.port}';

  static Future<_StreamFixture> start({bool replacement = false}) async {
    final fixture = _StreamFixture(
      await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
      replacement: replacement,
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
          'auth': {
            'type': 'bearer',
            'required': false,
            'granted_scopes': ['profiles:read'],
          },
          'profile_context': {
            'type': 'query',
            'name': 'profile',
            'required': true,
            'default_profile_id': 'default',
          },
          'features': {'session_chat_streaming': true},
          'endpoints': {
            'profiles': {
              'method': 'GET',
              'path': '/api/profiles',
              'profile_scoped': false,
              'required_scopes': ['profiles:read'],
            },
            'session_chat_stream': {
              'method': 'POST',
              'path': '/api/sessions/{session_id}/chat/stream',
            },
          },
        };
      case 'GET /api/profiles':
        body = {
          'data': [
            {'id': 'default', 'name': 'Home profile', 'revision': 'r1'},
            {'id': 'coder', 'name': 'Coding profile', 'revision': 'r2'},
          ],
        };
      case 'GET /api/sessions':
        body = {
          'object': 'list',
          'data': [
            if (replacement)
              {
                'id': 'replacement_session',
                'source': 'api_server',
                'title': 'Synthetic replacement host',
                'message_count': 1,
              }
            else if (request.uri.queryParameters['profile'] == 'coder')
              {
                'id': 'coder_session',
                'source': 'api_server',
                'title': 'Synthetic coding session',
                'message_count': 1,
              }
            else
              {
                'id': 'sess_1',
                'source': 'api_server',
                'title': 'Synthetic native stream',
                'message_count': completed ? 2 : 0,
              },
          ],
        };
      case 'GET /api/sessions/replacement_session/messages':
        replacementHistoryReads++;
        if (!replacement) unexpected.add(route);
        body = {
          'object': 'list',
          'session_id': 'replacement_session',
          'data': [
            {
              'id': 'replacement-reply',
              'session_id': 'replacement_session',
              'role': 'assistant',
              'content': replacementReply,
            },
          ],
        };
      case 'GET /api/sessions/coder_session/messages':
        coderHistoryReads++;
        if (request.uri.queryParameters['profile'] != 'coder') {
          unexpected.add('Missing coder context');
        }
        body = {
          'object': 'list',
          'session_id': 'coder_session',
          'data': [
            {
              'id': 'coder-reply',
              'session_id': 'coder_session',
              'role': 'assistant',
              'content': coderReply,
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
