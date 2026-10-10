import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/hermes_api.dart';

import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';

import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';

import 'app_shell_global_session_access_test.dart' as support;
import 'app_shell_global_session_modal_test.dart' as modal;

class PageChannel extends support.DelayedChannel {
  bool fail = true;
  @override
  Future<void> loadMoreSessions() async {
    loadMoreSessionsCalls++;
    if (fail) throw StateError('synthetic page failure');
    change(state.copyWith(hasMoreSessions: false, clearErrorMessage: true));
  }
}

void main() {
  for (final acknowledged in [true, false]) {
    testWidgets(
      'real channel New failure ${acknowledged ? 'retries acknowledged history without another write' : 'has no uncertain creation replay'}',
      (tester) async {
        final writes = <String>[];
        final history = <String>[];
        var failHistory = true;
        var nextId = 0;
        final channel = HermesApiChannel(
          sessionIdFactory: () => 'synthetic-created-${++nextId}',
          clientBuilder: (config) => HermesApiClient(
            config: config,
            get: (uri, headers) async {
              if (uri.path.endsWith('/messages')) {
                history.add(uri.path);
                if (failHistory && uri.path.contains('synthetic-created-')) {
                  throw StateError('synthetic history failure');
                }
                return jsonEncode({
                  'object': 'list',
                  'session_id': uri.pathSegments[2],
                  'data': [],
                });
              }
              return switch (uri.path) {
                '/health' => '{"status":"ok"}',
                '/v1/capabilities' => jsonEncode({
                  'schema_version': 1,
                  'endpoints': {
                    'sessions': {'method': 'GET', 'path': '/api/sessions'},
                    'session_create': {
                      'method': 'POST',
                      'path': '/api/sessions',
                    },
                    'session_messages': {
                      'method': 'GET',
                      'path': '/api/sessions/{session_id}/messages',
                    },
                  },
                }),
                '/api/sessions' =>
                  '{"data":[{"id":"synthetic-active","source":"test"}]}',
                _ => throw StateError('unexpected synthetic GET'),
              };
            },
            post: (uri, headers, body) async {
              expect(uri.path, '/api/sessions');
              final id =
                  (jsonDecode(body) as Map<String, dynamic>)['id'] as String;
              writes.add(id);
              if (!acknowledged) throw StateError('synthetic uncertain write');
              return jsonEncode({
                'session': {'id': id, 'source': 'test'},
              });
            },
          ),
        );
        addTearDown(channel.dispose);
        await tester.runAsync(
          () => channel.connect(baseUrl: 'http://127.0.0.1:8642'),
        );
        expect(
          channel.state.isConnected,
          isTrue,
          reason: channel.state.errorMessage,
        );
        final h = support.Harness(support.DelayedChannel());
        h.container.updateOverrides([
          hermesChannelProvider.overrideWithValue(channel),
          hermesDirectoryLifetimeProvider.overrideWithValue(h.lifetime),
          hermesGatewayDirectoryProvider.overrideWith((_) => h.directory),
        ]);
        await modal.pump(tester, h);
        await modal.open(tester);
        await modal.reach(
          tester,
          find.byKey(const ValueKey('hermes-sessions-new')),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(writes, ['synthetic-created-1']);
        expect(h.path, '/tools');
        final retry = find.byKey(const ValueKey('global-sessions-retry'));
        if (acknowledged) {
          expect(channel.state.activeSessionId, writes.single);
          expect(channel.state.errorMessage, isNotNull);
          failHistory = false;
          await modal.reach(tester, retry);
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.runAsync(() => Future<void>.delayed(Duration.zero));
          await tester.pumpAndSettle();
          expect(channel.state.activeSessionId, writes.single);
          expect(channel.state.errorMessage, isNull);
          expect(history.where((path) => path.contains('synthetic-created-')), [
            '/api/sessions/synthetic-created-1/messages',
            '/api/sessions/synthetic-created-1/messages',
          ]);
          expect(h.path, '/hermes');
        } else {
          expect(retry, findsNothing);
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          await modal.shortcut(tester);
          expect(retry, findsNothing);
        }
        expect(writes, ['synthetic-created-1']);
      },
    );
  }

  testWidgets(
    'explicit page failure retries once, no open/reopen reads, exact list denial hides Load more',
    (tester) async {
      final channel = PageChannel();
      channel.change(channel.state.copyWith(hasMoreSessions: true));
      final h = support.Harness(channel);
      await modal.pump(tester, h);
      await modal.open(tester);
      expect(channel.loadMoreSessionsCalls, 0);
      await modal.reach(
        tester,
        find.byKey(const ValueKey('hermes-sessions-load-more')),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(channel.loadMoreSessionsCalls, 1);
      channel.fail = false;
      await modal.reach(
        tester,
        find.byKey(const ValueKey('global-sessions-retry')),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(channel.loadMoreSessionsCalls, 2);
      expect(h.path, '/tools');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      channel.change(
        channel.state.copyWith(
          hasMoreSessions: true,
          capabilities: HermesCapabilityDocument.fromJson({
            'schema_version': 1,
            'endpoints': {
              'session_messages': {
                'method': 'GET',
                'path': '/api/sessions/{session_id}/messages',
              },
            },
          }),
        ),
      );
      await modal.shortcut(tester);
      expect(
        find.byKey(const ValueKey('hermes-sessions-load-more')),
        findsNothing,
      );
      expect(channel.loadMoreSessionsCalls, 2);
      expect(channel.selectSessionCalls, isEmpty);
      expect(channel.createSessionCalls, isEmpty);
    },
  );

  testWidgets(
    'empty loaded inventory retains search and differs from read error',
    (tester) async {
      final channel = support.DelayedChannel();
      channel.change(channel.state.copyWith(sessions: []));
      final h = support.Harness(channel);
      await modal.pump(tester, h);
      await modal.open(tester);
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: modal.search,
                matching: find.byType(EditableText),
              ),
            )
            .focusNode
            .hasFocus,
        isTrue,
      );
      final empty = tester
          .widget<Text>(
            find.descendant(of: modal.panel, matching: find.byType(Text)).last,
          )
          .data;
      channel.change(
        channel.state.copyWith(errorMessage: 'synthetic read failure'),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: modal.panel, matching: find.text(empty!)),
        findsNothing,
      );
      h.noIncidentalWork();
    },
  );

  testWidgets(
    'cancelled New and reopened modal cannot admit old creation or replay prompts/approvals',
    (tester) async {
      final channel = support.DelayedChannel()..gate = Completer<void>();
      final h = support.Harness(channel);
      await modal.pump(tester, h);
      await modal.open(tester);
      await modal.reach(
        tester,
        find.byKey(const ValueKey('hermes-sessions-new')),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(channel.createSessionCalls.length, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await modal.shortcut(tester);
      channel.gate!.complete();
      await tester.pumpAndSettle();
      expect(h.path, '/tools');
      expect(channel.state.activeSessionId, 'synthetic-active');
      expect(channel.createSessionCalls.length, 1);
      expect(channel.sentImageDataUrls, isEmpty);
      expect(channel.respondToApprovalCalls, isEmpty);
      h.noIncidentalWork();
    },
  );

  testWidgets(
    'channel replacement and return invalidates pending modal acknowledgement',
    (tester) async {
      final channel = support.DelayedChannel()..gate = Completer<void>();
      final replacement = support.DelayedChannel();
      addTearDown(replacement.dispose);
      final h = support.Harness(channel);
      await modal.pump(tester, h);
      await modal.open(tester);
      await modal.reach(tester, modal.row);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      h.container.updateOverrides([
        hermesChannelProvider.overrideWithValue(replacement),
        hermesDirectoryLifetimeProvider.overrideWithValue(h.lifetime),
        hermesGatewayDirectoryProvider.overrideWith((_) => h.directory),
      ]);
      await tester.pump();
      h.container.updateOverrides([
        hermesChannelProvider.overrideWithValue(channel),
        hermesDirectoryLifetimeProvider.overrideWithValue(h.lifetime),
        hermesGatewayDirectoryProvider.overrideWith((_) => h.directory),
      ]);
      await tester.pump();
      channel.gate!.complete();
      await tester.pumpAndSettle();
      expect(channel.state.activeSessionId, 'synthetic-active');
      expect(h.path, '/tools');
    },
  );

  testWidgets(
    'captured panel row and confirmation cannot revive after removal/owner return',
    (tester) async {
      final channel = support.DelayedChannel();
      final h = support.Harness(channel);
      await modal.pump(tester, h);
      await modal.open(tester);
      final presentation = tester.widget<HermesSessionsPanel>(
        find.byType(HermesSessionsPanel),
      );
      final before = channel.state;
      channel.change(before.copyWith(sessions: [support.sessions.first]));
      channel.change(before);
      presentation.onSelect(support.sessions.last);
      presentation.onCreate();
      presentation.onRename(support.sessions.last);
      await tester.pumpAndSettle();
      expect(channel.selectSessionCalls, isEmpty);
      expect(channel.createSessionCalls, isEmpty);
      expect(
        find.byKey(const ValueKey('hermes-session-title-field')),
        findsNothing,
      );
      final current = tester.widget<HermesSessionsPanel>(
        find.byType(HermesSessionsPanel),
      );
      current.onRename(support.sessions.last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('hermes-session-title-field')),
        'Synthetic new title',
      );
      await tester.pumpAndSettle();
      channel.change(before.copyWith(selectedProfileId: 'replacement'));
      channel.change(before);
      await tester.tap(find.byKey(const ValueKey('hermes-session-title-save')));
      await tester.pumpAndSettle();
      expect(channel.renameSessionCalls, isEmpty);
      expect(channel.createSessionCalls, isEmpty);
      expect(h.path, '/tools');
      h.noIncidentalWork();
    },
  );
}
