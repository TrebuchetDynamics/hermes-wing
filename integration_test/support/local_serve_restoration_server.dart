import 'dart:convert';
import 'dart:io';

import 'local_serve_chat_fixture.dart';
import 'local_serve_read_fixture.dart';

class RestorationFixture extends LocalServeChatFixture {
  @override
  Future<bool> handleExtra(HttpRequest request) async {
    if (!request.uri.path.startsWith('/fixture/')) {
      return super.handleExtra(request);
    }
    if (request.headers.value('Authorization') !=
        'Bearer ${LocalServeReadFixture.token}') {
      request.response.statusCode = 401;
    } else {
      switch (request.uri.path) {
        case '/fixture/approval':
          approval(session: 'demo-session');
        case '/fixture/deny':
          denyHistory = true;
          running = false;
        case '/fixture/allow':
          denyHistory = false;
        case '/fixture/receipt':
          request.response.write(
            jsonEncode({
              'sends': count('prompt.submit'),
              'answers': count('approval.respond'),
              'stops': count('session.interrupt'),
              'tickets': minted,
              'rpc_requests': rpc.length,
              'resumes': rpc
                  .where((r) => r['method'] == 'session.resume')
                  .map((r) => r['params'])
                  .toList(),
            }),
          );
        default:
          request.response.statusCode = 404;
      }
    }
    await request.response.close();
    return true;
  }
}

Future<void> main() async {
  final fixture = RestorationFixture()..dropStop = true;
  await fixture.start();
  final cache = Directory(Platform.environment['XDG_CACHE_HOME']!);
  final ready = File('${cache.path}/serve-restoration-ready.pending');
  await ready.writeAsString(
    jsonEncode({'origin': fixture.origin}),
    flush: true,
  );
  await ready.rename('${cache.path}/serve-restoration-ready.json');
}
