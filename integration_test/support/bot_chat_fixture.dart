import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'local_serve_chat_fixture.dart';
import 'local_serve_read_fixture.dart';

/// Deterministic canonical registry; no Agent/provider or inference is used.
class BotChatFixture extends LocalServeChatFixture {
  BotChatFixture({this.portOffset = 45});
  @override
  final int portOffset;
  String? registryId = 'bot-root';
  String tip = 'bot-tip';
  bool hidden = true, tipHidden = true, lookupError = false, denied = false;
  bool conflict = false, replayMissing = false, approvalInReplay = false;
  Completer<void>? lookupStarted,
      lookupGate,
      pageStarted,
      pageGate,
      historyStarted;
  final profilesRead = <String>[];
  int? reportedCount;

  @override
  Future<bool> handleExtra(HttpRequest request) async {
    final path = request.uri.pathSegments;
    if (request.method == 'GET' &&
        request.uri.path == '/api/sessions' &&
        request.headers.value('Authorization') ==
            'Bearer ${LocalServeReadFixture.token}') {
      final offset = int.parse(request.uri.queryParameters['offset']!);
      final profile = request.uri.queryParameters['profile']!;
      if (offset > 0) {
        if (!(pageStarted?.isCompleted ?? true)) pageStarted!.complete();
        await pageGate?.future;
      }
      request.response.write(
        jsonEncode({
          'sessions': [
            if (offset < 2)
              session(
                offset == 0 ? '$profile-session' : '$profile-extra',
                profile,
              ),
          ],
          'total': 2,
          'limit': int.parse(request.uri.queryParameters['limit']!),
          'offset': offset,
          'storage': <String, Object>{},
        }),
      );
      await request.response.close();
      return true;
    }
    if (request.method != 'GET' || path.length != 3 || path[1] != 'sessions') {
      return super.handleExtra(request);
    }
    if (request.headers.value('Authorization') !=
            'Bearer ${LocalServeReadFixture.token}' ||
        registryId == null ||
        !{registryId, tip}.contains(path.last)) {
      request.response.statusCode = 404;
    } else {
      request.response.write(
        jsonEncode({
          'id': path.last,
          'profile': request.uri.queryParameters['profile'],
          'title': path.last == registryId ? 'Bot Chat' : 'Bot Chat #2',
          'hidden': hidden && (path.last == registryId || tipHidden) ? 1 : 0,
        }),
      );
    }
    await request.response.close();
    return true;
  }

  @override
  Future<bool> handleRpc(WebSocket socket, Map<String, dynamic> frame) async {
    final params = frame['params'] as Map;
    void respond(Map<String, Object?> body, {bool error = false}) => socket.add(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': frame['id'],
        error ? 'error' : 'result': body,
      }),
    );
    switch (frame['method']) {
      case 'session.list':
        if (params['title'] != 'Bot Chat' ||
            params['include_hidden'] != true ||
            params['limit'] != 200) {
          throw StateError('Noncanonical fixture lookup');
        }
        profilesRead.add(params['profile'] as String);
        if (!(lookupStarted?.isCompleted ?? true)) lookupStarted!.complete();
        await lookupGate?.future;
        if (lookupError || denied) {
          respond({
            'code': denied ? -32601 : 5006,
            'message': 'Unavailable',
          }, error: true);
        } else {
          respond({
            'sessions': [
              if (registryId != null)
                {
                  'id': registryId,
                  'resolved_id': tip,
                  'title': 'Bot Chat',
                  'message_count': reportedCount ?? canonical.length,
                  'live_message_count': reportedCount ?? canonical.length,
                  'source': 'desktop',
                  'started_at': 1,
                  'preview': '',
                },
            ],
          });
        }
      case 'session.create':
        if (params['title'] != 'Bot Chat' ||
            params['hidden'] != true ||
            params['follow_profile_config'] != true ||
            params['idempotency_key'] is! String ||
            params.containsKey('messages')) {
          throw StateError('Unsafe fixture create');
        }
        respond({
          'session_id': 'runtime-new-bot',
          'stored_session_id': 'new-bot',
          'info': {'profile_name': params['profile']},
          'messages': <Object>[],
          'message_count': 0,
        });
      case 'session.title':
        if (params['session_id'] != 'runtime-new-bot' ||
            params['title'] != 'Bot Chat') {
          throw StateError('Retargeted fixture title');
        }
        registryId = tip = conflict ? 'peer-bot' : 'new-bot';
        respond(
          conflict
              ? {'code': 4022, 'message': 'Title conflict'}
              : {'title': 'Bot Chat', 'pending': false},
          error: conflict,
        );
      case 'session.history':
        if (!(historyStarted?.isCompleted ?? true)) historyStarted!.complete();
        return false;
      case 'session.events.since':
        if (replayMissing) {
          respond({'code': -32601, 'message': 'Unavailable'}, error: true);
        } else if (approvalInReplay) {
          respond({
            'epoch': 'fixture-epoch',
            'latest_seq': sequence,
            'events': <Object>[],
            'count': 0,
            'truncated': false,
            'open_requests': [
              {
                'id': 'srq-fixture',
                'method': 'approval',
                'params': {
                  'session_id': params['session_id'],
                  'request_id': 'queue-fixture',
                  'choices': ['once', 'deny'],
                },
              },
            ],
          });
        } else {
          return false;
        }
      default:
        return false;
    }
    return true;
  }

  @override
  Future<void> close() async {
    if (!(lookupGate?.isCompleted ?? true)) lookupGate!.complete();
    if (!(pageGate?.isCompleted ?? true)) pageGate!.complete();
    await super.close();
  }
}
