import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Synthetic session token and sanitized rows; never starts or contacts Agent.
class LocalServeReadFixture {
  static const token = 'synthetic-serve-owner';
  late HttpServer server;
  final requests = <String>[];
  final profiles = ['default', 'demo'];
  bool unsupported = false;
  Completer<void>? holdProfiles;
  Completer<void>? profilesRequested;
  String get origin => 'http://127.0.0.1:${server.port}';

  Future<void> start() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests.add('${request.method} ${request.uri.path}');
      if (await handleExtra(request)) return;
      request.response.headers.contentType = ContentType.json;
      if (request.method != 'GET' ||
          request.headers.value('Authorization') != 'Bearer $token') {
        request.response.statusCode = HttpStatus.unauthorized;
      } else if (unsupported) {
        request.response.statusCode = HttpStatus.notFound;
      } else if (request.uri.path == '/api/profiles') {
        if (!(profilesRequested?.isCompleted ?? true)) {
          profilesRequested!.complete();
        }
        await holdProfiles?.future;
        request.response.write(
          jsonEncode({
            'profiles': [
              for (final p in profiles)
                {'name': p, 'display_name': p, 'path': '/redacted/ignored'},
            ],
          }),
        );
      } else if (request.uri.path == '/api/sessions') {
        final profile = request.uri.queryParameters['profile'];
        final limit = int.parse(request.uri.queryParameters['limit']!);
        final offset = int.parse(request.uri.queryParameters['offset']!);
        request.response.write(
          jsonEncode({
            'sessions': offset == 0
                ? [session('$profile-session', profile!)]
                : [],
            'total': 1,
            'limit': limit,
            'offset': offset,
            'storage': {},
          }),
        );
      } else if (request.uri.path.endsWith('/messages')) {
        final id = request.uri.pathSegments[2];
        final profile = request.uri.queryParameters['profile'];
        final limit = int.parse(request.uri.queryParameters['limit']!);
        final offset = int.parse(request.uri.queryParameters['offset']!);
        request.response.write(
          jsonEncode({
            'profile': profile,
            'session_id': id,
            'messages': offset == 0
                ? [
                    {
                      'id': 1,
                      'session_id': id,
                      'role': 'user',
                      'content': '$profile fixture question',
                      'timestamp': 1,
                    },
                    {
                      'id': 2,
                      'session_id': id,
                      'role': 'assistant',
                      'content': '$profile fixture answer',
                      'timestamp': 2,
                    },
                  ]
                : [],
            'pagination': {
              'limit': limit,
              'offset': offset,
              'order': request.uri.queryParameters['order'],
              'returned': offset == 0 ? 2 : 0,
            },
          }),
        );
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
      await request.response.close();
    });
  }

  Map<String, Object?> session(String id, String profile) => {
    'id': id,
    'profile': profile,
    'title': '$profile read session',
    'model': null,
    'source': 'desktop',
    'preview': null,
    'started_at': 1,
    'ended_at': null,
    'message_count': 2,
    'is_active': false,
  };
  Future<bool> handleExtra(HttpRequest request) async => false;
  Future<void> close() async {
    if (!(holdProfiles?.isCompleted ?? true)) holdProfiles!.complete();
    await server.close(force: true);
  }
}
