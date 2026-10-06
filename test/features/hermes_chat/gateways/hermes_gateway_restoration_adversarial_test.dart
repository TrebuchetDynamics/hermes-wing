import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/models/hermes_profile.dart';
import 'package:wing/core/hermes/shared/hermes_api_http.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';

import 'hermes_gateway_session_restoration_test.dart'
    show RestorationHarness, target;

class _StatusFailure implements HermesApiStatusException {
  const _StatusFailure(this.statusCode);
  @override
  final int statusCode;
}

Map<String, Object?> _endpoints(Map<String, Object?> doc) =>
    doc['endpoints']! as Map<String, Object?>;
String _history(String id) => jsonEncode({
  'object': 'list',
  'session_id': 'older-A',
  'data': [
    {'id': id, 'session_id': 'older-A', 'role': 'assistant', 'content': id},
  ],
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final failures =
      <
        String,
        (GatewaySessionRestorationFailure, void Function(RestorationHarness))
      >{
        'schema': (
          GatewaySessionRestorationFailure.unsupported,
          (h) => h.configureCapabilities = (doc) => doc['schema_version'] = 99,
        ),
        'missing metadata operation': (
          GatewaySessionRestorationFailure.unsupported,
          (h) =>
              h.configureCapabilities = (doc) =>
                  _endpoints(doc).remove('session'),
        ),
        'wrong method': (
          GatewaySessionRestorationFailure.unsupported,
          (h) =>
              h.configureCapabilities = (doc) =>
                  (_endpoints(doc)['session'] as Map)['method'] = 'POST',
        ),
        'wrong path': (
          GatewaySessionRestorationFailure.unsupported,
          (h) =>
              h.configureCapabilities = (doc) =>
                  (_endpoints(doc)['session'] as Map)['path'] = '/other',
        ),
        'missing history operation': (
          GatewaySessionRestorationFailure.unsupported,
          (h) =>
              h.configureCapabilities = (doc) =>
                  _endpoints(doc).remove('session_messages'),
        ),
        'ungranted declared scope': (
          GatewaySessionRestorationFailure.unsupported,
          (h) => h.configureCapabilities = (doc) =>
              (_endpoints(doc)['session'] as Map)['required_scopes'] = [
                'sessions:read',
                'extra:read',
              ],
        ),
        'ungranted history scope': (
          GatewaySessionRestorationFailure.unsupported,
          (h) => h.configureCapabilities = (doc) =>
              (_endpoints(doc)['session_messages'] as Map)['required_scopes'] =
                  ['extra:read'],
        ),
        for (final code in [401, 403, 404, 503])
          'HTTP $code': (
            code == 401 || code == 403
                ? GatewaySessionRestorationFailure.authentication
                : code == 404
                ? GatewaySessionRestorationFailure.unavailable
                : GatewaySessionRestorationFailure.transient,
            (h) => h.onRead = (uri) async {
              if (uri.path == '/api/sessions/older-A') {
                throw _StatusFailure(code);
              }
              return null;
            },
          ),
        'timeout': (
          GatewaySessionRestorationFailure.transient,
          (h) => h.onRead = (uri) async {
            if (uri.path == '/api/sessions/older-A') {
              throw TimeoutException('synthetic');
            }
            return null;
          },
        ),
        for (final body in [
          '{}',
          '{"object":"list","session":{"id":"older-A"}}',
          '{"object":"hermes.session","session":{"id":"newer-B"}}',
          '{"object":"hermes.session","session":{"id":42}}',
          '{"object":"hermes.session","session":[]}',
        ])
          'invalid metadata $body': (
            GatewaySessionRestorationFailure.incompatible,
            (h) =>
                h.onRead = (uri) async =>
                    uri.path == '/api/sessions/older-A' ? body : null,
          ),
      };
  for (final entry in failures.entries) {
    test('retains target with no fallback or mutation: ${entry.key}', () async {
      final h = RestorationHarness();
      addTearDown(h.dispose);
      entry.value.$2(h);
      await h.directory.start();
      expect(h.directory.restorationFailure, entry.value.$1);
      expect(h.directory.restoringSessionId, 'older-A');
      expect(h.channel.state.activeSessionId, isNull);
      expect(h.channel.state.messages, isEmpty);
      expect(h.cache.selection?.sessionId, 'older-A');
      expect(h.cache.saved, isEmpty);
      expect(h.channel.state.sessions.any((s) => s.id == 'older-A'), isFalse);
      expect(h.mutations, isEmpty);
      if (entry.value.$1 == GatewaySessionRestorationFailure.unsupported) {
        expect(
          h.reads.where((uri) => uri.path == '/api/sessions/older-A'),
          isEmpty,
        );
      }
    });
  }

  for (final error in <Object>[
    const _StatusFailure(401),
    const _StatusFailure(403),
    const _StatusFailure(404),
    const _StatusFailure(503),
    TimeoutException('synthetic'),
  ]) {
    test(
      'failed canonical history retains target and never falls back: ${error is _StatusFailure ? error.statusCode : 'timeout'}',
      () async {
        final h = RestorationHarness();
        addTearDown(h.dispose);
        h.onRead = (uri) async {
          if (uri.path == '/api/sessions/older-A/messages') {
            throw error;
          }
          return null;
        };
        await h.directory.start();
        expect(h.channel.state.activeSessionId, isNull);
        expect(h.channel.state.messages, isEmpty);
        expect(h.directory.restoringSessionId, 'older-A');
        expect(h.directory.restorationFailure, isNotNull);
        expect(h.cache.selection?.sessionId, 'older-A');
        expect(h.cache.saved, isEmpty);
        expect(h.mutations, isEmpty);
      },
    );
  }

  test(
    'authenticated operations with no declared scopes do not invent a grant',
    () async {
      final h = RestorationHarness();
      addTearDown(h.dispose);
      h.configureCapabilities = (doc) {
        doc['auth'] = {'granted_scopes': <String>[]};
        for (final endpoint in _endpoints(doc).values) {
          (endpoint as Map)['required_scopes'] = <String>[];
        }
      };
      await h.directory.start();
      expect(h.channel.state.activeSessionId, 'older-A');
      expect(h.cache.selection?.sessionId, 'older-A');
      expect(h.mutations, isEmpty);
    },
  );

  test(
    'a valid remembered Telegram identity is restored without creating',
    () async {
      final h = RestorationHarness(loaded: true);
      addTearDown(h.dispose);
      h.onRead = (uri) async => uri.path == '/api/sessions'
          ? '{"data":[{"id":"older-A","source":"telegram"},{"id":"newer-B","source":"api_server"}]}'
          : null;
      await h.directory.start();
      expect(h.channel.state.activeSession?.source, 'telegram');
      expect(h.channel.state.activeMessages.single.id, 'canonical-A');
      expect(
        h.reads.where((uri) => uri.path == '/api/sessions/older-A'),
        isEmpty,
      );
      expect(h.mutations, isEmpty);
    },
  );

  test(
    'foreground preferred activation and Retry share exact startup path',
    () async {
      final h = RestorationHarness();
      addTearDown(h.dispose);
      h.onRead = (uri) async {
        if (uri.path == '/api/sessions/older-A') {
          throw const _StatusFailure(404);
        }
        return null;
      };
      await h.directory.start();
      h.onRead = null;
      await h.directory.retrySessionRestoration();
      expect(h.channel.state.activeSessionId, 'older-A');
      expect(h.directory.restoringSessionId, isNull);
      await h.directory.activate(
        target.contactId,
        preferredSessionId: target.sessionId,
      );
      expect(h.channel.state.activeMessages.single.id, 'canonical-A');
      expect(h.cache.selection?.sessionId, 'older-A');
      expect(h.mutations, isEmpty);
    },
  );

  for (final phase in ['metadata', 'history']) {
    for (final action in [
      'directory',
      'remove',
      'dispose',
      'manual',
      'profile',
      'host',
      'reuse',
    ]) {
      test('parked $phase cannot override $action ownership', () async {
        final h = RestorationHarness();
        addTearDown(h.dispose);
        final approvals = <Object>[];
        final approvalSubscription = h.channel.approvalRequests.listen(
          approvals.add,
        );
        addTearDown(approvalSubscription.cancel);
        final entered = Completer<void>();
        final release = Completer<String>();
        final path = phase == 'metadata'
            ? '/api/sessions/older-A'
            : '/api/sessions/older-A/messages';
        h.onRead = (uri) async {
          if (uri.path == path && !entered.isCompleted) {
            entered.complete();
            return release.future;
          }
          return null;
        };
        final activation = h.directory.start();
        await entered.future;
        expect(h.channel.state.activeSessionId, isNull);
        expect(h.cache.selection?.sessionId, 'older-A');
        switch (action) {
          case 'directory':
            await h.directory.showDirectory();
          case 'remove':
            await h.directory.removeGateway('alpha');
          case 'dispose':
            h.directory.dispose();
            h.disposed = true;
          case 'manual':
            h.directory.supersedeSessionRestoration();
            await h.channel.selectSession('newer-B');
          case 'profile':
            await h.directory.selectProfileOnActiveGateway(
              'other',
              discoveredProfile: const HermesProfile(
                id: 'other',
                displayName: 'Other',
                revision: 'r',
              ),
            );
          case 'host':
            await h.directory.activate(
              const GatewayContactId(gatewayId: 'beta', profileId: 'coder'),
              preferredSessionId: 'older-A',
            );
          case 'reuse':
            await h.directory.activate(
              const GatewayContactId(gatewayId: 'beta', profileId: 'coder'),
              preferredSessionId: 'older-A',
            );
            await h.directory.activate(
              target.contactId,
              preferredSessionId: 'older-A',
            );
        }
        release.complete(
          phase == 'metadata'
              ? '{"object":"hermes.session","session":{"id":"older-A","source":"api_server"}}'
              : _history('stale-A'),
        );
        await activation;
        if (action == 'directory' || action == 'remove') {
          expect(h.directory.activeContactId, isNull);
          expect(h.channel.state.activeSessionId, isNull);
          expect(h.cache.selection, isNull);
        } else if (action == 'dispose') {
          expect(h.channel.state.activeSessionId, isNull);
          expect(h.cache.selection?.sessionId, 'older-A');
          expect(h.cache.saved, isEmpty);
        } else {
          final expected = action == 'manual' || action == 'profile'
              ? 'newer-B'
              : 'older-A';
          expect(h.channel.state.activeSessionId, expected);
          expect(h.cache.selection?.sessionId, expected);
          expect(
            h.channel.state.activeMessages.single.id,
            expected == 'newer-B' ? 'canonical-B' : 'canonical-A',
          );
          if (action == 'profile') {
            expect(h.cache.selection?.contactId.profileId, 'other');
          }
          if (action == 'host') {
            expect(h.cache.selection?.contactId.gatewayId, 'beta');
          }
          if (action == 'reuse') {
            expect(h.cache.selection?.contactId, target.contactId);
          }
        }
        expect(
          h.channel.state.messages.values
              .expand((v) => v)
              .any((v) => v.id == 'stale-A'),
          isFalse,
        );
        expect(approvals, isEmpty);
        expect(h.mutations, isEmpty);
      });
    }
  }
}
