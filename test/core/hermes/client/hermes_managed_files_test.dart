import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/client/hermes_managed_files.dart';
import 'package:wing/core/hermes/client/hermes_web_read_client.dart';

const root = '/managed';
Map<String, Object?> policy({String? locked = root}) => {
  'root': locked,
  'locked_root': locked,
  'can_change_path': locked == null,
};
Map<String, Object?> entry(
  String name, {
  bool directory = false,
  int size = 12,
}) => {
  'name': name,
  'path': '$root/$name',
  'is_directory': directory,
  'size': directory ? null : size,
};
Map<String, Object?> listing({List<Object?> entries = const []}) => {
  ...policy(),
  'path': root,
  'parent': null,
  'entries': entries,
};

void main() {
  late HttpServer server;
  late HermesWebReadClient client;
  late HermesManagedFilesSession files;
  late List<Uri> requests;
  late Future<void> Function(HttpRequest) respond;
  setUp(() async {
    final base = int.tryParse(Platform.environment['AUTOWORK_PORT_BASE'] ?? '');
    server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      base == null ? 0 : base + 91,
    );
    requests = [];
    respond = (r) async {
      r.response.write(jsonEncode(listing()));
    };
    server.listen((r) async {
      requests.add(r.uri);
      expect(r.method, 'GET');
      expect(r.headers.value('Authorization'), 'Bearer synthetic-owned-auth');
      expect(r.uri.queryParameters.keys, everyElement('path'));
      r.response.headers.contentType = ContentType.json;
      await respond(r);
      await r.response.close();
    });
    client = HermesWebReadClient.forQualification(
      origin: Uri.parse('http://127.0.0.1:${server.port}'),
      credential: 'synthetic-owned-auth',
      profile: 'default',
    );
    files = client.beginManagedFiles(isCurrent: () => true);
  });
  tearDown(() async {
    client.disconnect();
    await server.close(force: true);
  });

  test(
    'locked managed listing and literal text preview use authenticated GET only',
    () async {
      respond = (r) async {
        r.response.write(
          jsonEncode(
            r.uri.path == '/api/files'
                ? listing(entries: [entry('note.html')])
                : {
                    ...policy(),
                    'name': 'note.html',
                    'path': '$root/note.html',
                    'size': 13,
                    'mime_type': 'text/html',
                    'data_url':
                        'data:text/html;base64,${base64Encode(utf8.encode('<b>plain</b>\n'))}',
                  },
          ),
        );
      };
      final directory = await files.list();
      expect(directory.root, root);
      expect(directory.parent, isNull);
      expect(await files.read(directory.entries.single), '<b>plain</b>\n');
      expect(requests.map((r) => r.path), ['/api/files', '/api/files/read']);
    },
  );

  test(
    'confined symlink aliases preserve display names and read their canonical target',
    () async {
      respond = (r) async {
        r.response.write(
          jsonEncode(
            r.uri.path == '/api/files'
                ? listing(
                    entries: [
                      entry('note.txt'),
                      {...entry('alias.txt'), 'path': '$root/note.txt'},
                    ],
                  )
                : {
                    ...policy(),
                    'name': 'note.txt',
                    'path': '$root/note.txt',
                    'size': 5,
                    'mime_type': 'text/plain',
                    'data_url': 'data:text/plain;base64,aGVsbG8=',
                  },
          ),
        );
      };
      final directory = await files.list();
      expect(directory.entries.map((e) => e.name), ['note.txt', 'alias.txt']);
      expect(await files.read(directory.entries.last), 'hello');
      expect(requests.last.queryParameters['path'], '$root/note.txt');
    },
  );

  test(
    'unlocked, host-root or changed policy never admits a listing',
    () async {
      for (final advertised in [
        policy(locked: null),
        policy(locked: ''),
        {...policy(), 'can_change_path': true},
        policy(locked: '/'),
      ]) {
        files = client.beginManagedFiles(isCurrent: () => true);
        respond = (r) async {
          r.response.write(jsonEncode({...listing(), ...advertised}));
        };
        await expectLater(
          files.list(),
          throwsA(
            isA<HermesManagedFilesException>().having(
              (e) => e.kind,
              'policy refusal',
              advertised['locked_root'] == '/'
                  ? HermesManagedFilesFailure.malformed
                  : HermesManagedFilesFailure.unsupported,
            ),
          ),
        );
        expect(files.isCurrent, isFalse);
      }
      files = client.beginManagedFiles(isCurrent: () => true);
      respond = (r) async {
        r.response.write(jsonEncode(listing()));
      };
      await files.list();
      respond = (r) async {
        r.response.write(
          jsonEncode({...listing(), ...policy(locked: '/replacement')}),
        );
      };
      await expectLater(
        files.list(root),
        throwsA(isA<HermesManagedFilesException>()),
      );
      expect(files.isCurrent, isFalse);
    },
  );

  test(
    'traversal and outside paths never request; server symlink and sensitive denials are sanitized',
    () async {
      respond = (r) async {
        r.response.write(
          jsonEncode(
            listing(
              entries: [
                entry('link'),
                entry('.env'),
                entry('folder', directory: true),
                entry('sibling', directory: true),
              ],
            ),
          ),
        );
      };
      final directory = await files.list();
      for (final path in ['$root/..', '/outside', '$root/../outside']) {
        await expectLater(
          files.list(path),
          throwsA(isA<HermesManagedFilesException>()),
        );
      }
      expect(requests.length, 1);
      respond = (r) async {
        r.response.statusCode = 403;
        r.response.write('sensitive upstream detail');
      };
      for (final file in directory.entries.where(
        (entry) => !entry.isDirectory,
      )) {
        await expectLater(
          files.read(file),
          throwsA(
            isA<HermesManagedFilesException>().having(
              (e) => e.toString(),
              'safe failure',
              isNot(contains('sensitive upstream detail')),
            ),
          ),
        );
      }
      respond = (r) async {
        r.response.write(
          jsonEncode({...listing(), 'path': '$root/folder', 'parent': root}),
        );
      };
      await files.list('$root/folder');
      final before = requests.length;
      await expectLater(
        files.list('$root/sibling'),
        throwsA(
          isA<HermesManagedFilesException>().having(
            (e) => e.kind,
            'expired page handle',
            HermesManagedFilesFailure.denied,
          ),
        ),
      );
      expect(requests.length, before);
    },
  );

  test(
    'preview refuses oversized sources, binary bytes and oversized wire bodies',
    () async {
      respond = (r) async {
        r.response.write(
          jsonEncode(
            listing(
              entries: [entry('large', size: 65537), entry('binary', size: 1)],
            ),
          ),
        );
      };
      final directory = await files.list();
      await expectLater(
        files.read(directory.entries.first),
        throwsA(
          isA<HermesManagedFilesException>().having(
            (e) => e.kind,
            'kind',
            HermesManagedFilesFailure.oversized,
          ),
        ),
      );
      expect(requests.length, 1);
      respond = (r) async {
        r.response.write(
          jsonEncode({
            ...policy(),
            'path': '$root/binary',
            'name': 'binary',
            'size': 1,
            'mime_type': 'application/octet-stream',
            'data_url': 'data:application/octet-stream;base64,AA==',
          }),
        );
      };
      await expectLater(
        files.read(directory.entries.last),
        throwsA(
          isA<HermesManagedFilesException>().having(
            (e) => e.kind,
            'kind',
            HermesManagedFilesFailure.binary,
          ),
        ),
      );
      respond = (r) async {
        r.response.write('x' * (256 * 1024));
      };
      await expectLater(
        files.read(directory.entries.last),
        throwsA(
          isA<HermesManagedFilesException>().having(
            (e) => e.kind,
            'kind',
            HermesManagedFilesFailure.oversized,
          ),
        ),
      );
    },
  );

  test(
    'owner loss rejects in-flight data and cached actions without new requests',
    () async {
      var current = true;
      files = client.beginManagedFiles(isCurrent: () => current);
      final arrived = Completer<void>(), release = Completer<void>();
      respond = (r) async {
        arrived.complete();
        await release.future;
        r.response.write(jsonEncode(listing()));
      };
      final pending = files.list();
      await arrived.future;
      current = false;
      release.complete();
      await expectLater(
        pending,
        throwsA(
          isA<HermesManagedFilesException>().having(
            (e) => e.kind,
            'kind',
            HermesManagedFilesFailure.stale,
          ),
        ),
      );
      await expectLater(
        files.list(),
        throwsA(isA<HermesManagedFilesException>()),
      );
      expect(requests.length, 1);
    },
  );
}
