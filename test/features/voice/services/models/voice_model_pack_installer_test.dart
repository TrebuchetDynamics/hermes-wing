@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice/services/models/voice_model_pack.dart';
import 'package:wing/features/voice/services/models/voice_model_pack_installer.dart';

void main() {
  test('manifest accepts multiple named pinned HTTPS artifacts', () {
    final first = utf8.encode('model');
    final second = utf8.encode('tokens');

    final manifest = VoiceModelPackManifest(
      packId: 'whisper-tiny',
      version: '1.0.0',
      provenance: 'official Hermes voice registry',
      artifacts: <VoiceModelPackArtifact>[
        VoiceModelPackArtifact(
          name: 'model',
          path: 'weights/model.bin',
          uri: Uri.parse('https://models.example/model.bin'),
          expectedBytes: first.length,
          sha256: sha256.convert(first).toString(),
        ),
        VoiceModelPackArtifact(
          name: 'tokens',
          path: 'config/tokens.json',
          uri: Uri.parse('https://models.example/tokens.json'),
          expectedBytes: second.length,
          sha256: sha256.convert(second).toString(),
        ),
      ],
    );

    expect(manifest.artifactsByName.keys, <String>['model', 'tokens']);
    expect(manifest.totalBytes, first.length + second.length);
  });

  test('installed pack snapshots artifact paths immutably', () {
    final paths = <String, String>{'model': 'model.bin'};
    final installed = InstalledVoiceModelPack(
      packId: 'pack',
      version: '1',
      provenance: 'registry',
      directory: Directory('/models/pack/1'),
      artifactPaths: paths,
    );

    paths['model'] = '../changed.bin';

    expect(installed.artifactFile('model').path, '/models/pack/1/model.bin');
  });

  test('manifest rejects unsafe identities, artifacts, and pins', () {
    VoiceModelPackManifest build({
      String packId = 'whisper',
      String version = '1',
      String provenance = 'registry',
      String name = 'model',
      String path = 'model.bin',
      String uri = 'https://models.example/model.bin',
      int bytes = 1,
      String hash =
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    }) => VoiceModelPackManifest(
      packId: packId,
      version: version,
      provenance: provenance,
      artifacts: <VoiceModelPackArtifact>[
        VoiceModelPackArtifact(
          name: name,
          path: path,
          uri: Uri.parse(uri),
          expectedBytes: bytes,
          sha256: hash,
        ),
      ],
    );

    expect(() => build(packId: '../escape'), throwsFormatException);
    expect(() => build(version: '/absolute'), throwsFormatException);
    expect(() => build(provenance: ''), throwsFormatException);
    expect(() => build(name: '../model'), throwsFormatException);
    expect(() => build(path: '../model.bin'), throwsFormatException);
    expect(() => build(path: '/tmp/model.bin'), throwsFormatException);
    expect(() => build(path: r'config\\..\\model.bin'), throwsFormatException);
    expect(() => build(path: 'C:/model.bin'), throwsFormatException);
    expect(() => build(path: 'config/model\n.bin'), throwsFormatException);
    expect(() => build(path: '.pack.json'), throwsFormatException);
    expect(
      () => build(uri: 'http://models.example/model.bin'),
      throwsFormatException,
    );
    expect(() => build(bytes: 0), throwsFormatException);
    expect(() => build(hash: 'not-a-sha'), throwsFormatException);
    expect(
      () => VoiceModelPackManifest(
        packId: 'whisper',
        version: '1',
        provenance: 'registry',
        artifacts: <VoiceModelPackArtifact>[],
      ),
      throwsFormatException,
    );
    expect(
      () => VoiceModelPackManifest(
        packId: 'whisper',
        version: '1',
        provenance: 'registry',
        artifacts: <VoiceModelPackArtifact>[
          build().artifacts.single,
          build().artifacts.single,
        ],
      ),
      throwsFormatException,
    );
    expect(
      () => VoiceModelPackManifest(
        packId: 'whisper',
        version: '1',
        provenance: 'registry',
        artifacts: <VoiceModelPackArtifact>[
          VoiceModelPackArtifact(
            name: 'parent',
            path: 'weights',
            uri: Uri.parse('https://models.example/weights'),
            expectedBytes: 1,
            sha256:
                'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          ),
          VoiceModelPackArtifact(
            name: 'child',
            path: 'weights/model.bin',
            uri: Uri.parse('https://models.example/model.bin'),
            expectedBytes: 1,
            sha256:
                'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
          ),
        ],
      ),
      throwsFormatException,
    );
  });

  group('installer', () {
    late Directory root;
    late Map<String, _Reply> replies;
    late List<Uri> requested;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('voice-model-pack-test');
      replies = <String, _Reply>{};
      requested = <Uri>[];
    });

    tearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    Future<T> withHttp<T>(Future<T> Function() body) => HttpOverrides.runZoned(
      body,
      createHttpClient: (_) => _FakeHttpClient((uri) async {
        requested.add(uri);
        final reply = replies[uri.toString()];
        if (reply == null) throw const SocketException('fixture missing');
        return _FakeRequest(reply);
      }),
    );

    VoiceModelPackManifest healthyManifest({String version = '1.0.0'}) {
      final model = utf8.encode('model payload');
      final config = utf8.encode('{"language":"en"}');
      replies['https://models.example/model.bin'] = _Reply(200, model);
      replies['https://models.example/config.json'] = _Reply(200, config);
      return VoiceModelPackManifest(
        packId: 'whisper-tiny',
        version: version,
        provenance: 'Hermes registry release 42',
        artifacts: <VoiceModelPackArtifact>[
          VoiceModelPackArtifact(
            name: 'model',
            path: 'weights/model.bin',
            uri: Uri.parse('https://models.example/model.bin'),
            expectedBytes: model.length,
            sha256: sha256.convert(model).toString(),
          ),
          VoiceModelPackArtifact(
            name: 'config',
            path: 'config/config.json',
            uri: Uri.parse('https://models.example/config.json'),
            expectedBytes: config.length,
            sha256: sha256.convert(config).toString(),
          ),
        ],
      );
    }

    test(
      'installs multiple artifacts and immutable provenance metadata',
      () async {
        final manifest = healthyManifest();
        final installer = VoiceModelPackInstaller(rootDirectory: root);

        final installed = await withHttp(() => installer.install(manifest));

        expect(
          await installed.artifactFile('model').readAsString(),
          'model payload',
        );
        expect(
          jsonDecode(await installed.artifactFile('config').readAsString()),
          <String, Object?>{'language': 'en'},
        );
        expect(installed.packId, manifest.packId);
        expect(installed.version, manifest.version);
        expect(installed.provenance, manifest.provenance);
        final metadata = await File(
          '${installed.directory.path}/.pack.json',
        ).readAsString();
        expect(metadata, contains('Hermes registry release 42'));
        expect(metadata, isNot(contains('https://')));
        expect(
          root
              .listSync(recursive: true)
              .where((entry) => entry.path.contains('.download')),
          isEmpty,
        );
        expect(requested, hasLength(2));
      },
    );

    test('reports exact cumulative byte progress across artifacts', () async {
      final manifest = healthyManifest();
      final installer = VoiceModelPackInstaller(rootDirectory: root);
      final progress = <VoiceModelPackProgress>[];

      await withHttp(
        () => installer.install(manifest, onProgress: progress.add),
      );

      expect(progress, isNotEmpty);
      expect(progress.first.receivedBytes, 0);
      expect(progress.first.totalBytes, manifest.totalBytes);
      expect(progress.last.receivedBytes, manifest.totalBytes);
      expect(progress.last.totalBytes, manifest.totalBytes);
      final received = progress.map((entry) => entry.receivedBytes).toList();
      expect(received, orderedEquals(<int>[...received]..sort()));
    });

    test('validates installed metadata and every pinned artifact', () async {
      final manifest = healthyManifest();
      final installer = VoiceModelPackInstaller(rootDirectory: root);
      final installed = await withHttp(() => installer.install(manifest));

      expect(await installer.installedPack(manifest), isNotNull);
      await installed.artifactFile('model').writeAsString('tampered!!!!!');
      expect(await installer.installedPack(manifest), isNull);
    });

    test('delete removes destination, backup, and abandoned staging', () async {
      final manifest = healthyManifest();
      final installer = VoiceModelPackInstaller(rootDirectory: root);
      await withHttp(() => installer.install(manifest));
      final parent = Directory('${root.path}/${manifest.packId}');
      await Directory('${parent.path}/${manifest.version}.backup').create();
      await Directory(
        '${parent.path}/.${manifest.version}.download-abandoned',
      ).create();

      await installer.delete(manifest.packId, manifest.version);

      expect(await parent.exists(), isFalse);
    });

    test('serializes transactions across installer instances', () async {
      final manifest = healthyManifest();
      final adoptionStarted = Completer<void>();
      final adoptionGate = Completer<void>();
      final installing = VoiceModelPackInstaller(
        rootDirectory: root,
        adoptStaging: (staging, destination) async {
          adoptionStarted.complete();
          await adoptionGate.future;
          await staging.rename(destination.path);
        },
      );
      final deleting = VoiceModelPackInstaller(rootDirectory: root);

      final installation = withHttp(() => installing.install(manifest));
      await adoptionStarted.future;
      var deletionCompleted = false;
      final deletion = deleting
          .delete(manifest.packId, manifest.version)
          .then((_) => deletionCompleted = true);
      final deletedBeforeAdoption = await Future.any<bool>([
        deletion.then((_) => true),
        Future<bool>.delayed(const Duration(milliseconds: 100), () => false),
      ]);

      expect(deletedBeforeAdoption, isFalse);
      adoptionGate.complete();
      await installation;
      await deletion;
      expect(deletionCompleted, isTrue);
    });

    test('adoption failure rolls the healthy predecessor back', () async {
      final manifest = healthyManifest();
      final installer = VoiceModelPackInstaller(rootDirectory: root);
      final predecessor = await withHttp(() => installer.install(manifest));
      final oldBytes = await predecessor.artifactFile('model').readAsBytes();
      final failing = VoiceModelPackInstaller(
        rootDirectory: root,
        adoptStaging: (_, _) async =>
            throw const FileSystemException('simulated rename failure'),
      );

      await expectLater(
        withHttp(() => failing.install(manifest)),
        throwsA(
          isA<VoiceModelPackException>().having(
            (error) => error.code,
            'code',
            VoiceModelPackError.adoption,
          ),
        ),
      );

      final restored = await installer.installedPack(manifest);
      expect(restored, isNotNull);
      expect(await restored!.artifactFile('model').readAsBytes(), oldBytes);
    });

    test(
      'startup recovery restores backup and removes abandoned staging',
      () async {
        final manifest = healthyManifest();
        final installer = VoiceModelPackInstaller(rootDirectory: root);
        final installed = await withHttp(() => installer.install(manifest));
        final destination = installed.directory;
        final backup = Directory('${destination.path}.backup');
        await destination.rename(backup.path);
        final abandoned = Directory(
          '${destination.parent.path}/.${manifest.version}.download-crashed',
        );
        await abandoned.create();

        final recovered = await installer.installedPack(manifest);

        expect(recovered, isNotNull);
        expect(await destination.exists(), isTrue);
        expect(await backup.exists(), isFalse);
        expect(await abandoned.exists(), isFalse);
      },
    );

    test(
      'fetch failure preserves predecessor and exposes no source URL',
      () async {
        final manifest = healthyManifest();
        final installer = VoiceModelPackInstaller(rootDirectory: root);
        await withHttp(() => installer.install(manifest));
        replies['https://models.example/config.json'] = const _Reply(503);

        Object? failure;
        try {
          await withHttp(() => installer.install(manifest));
        } catch (error) {
          failure = error;
        }

        expect(failure, isA<VoiceModelPackException>());
        expect('$failure', isNot(contains('models.example')));
        expect(await installer.installedPack(manifest), isNotNull);
      },
    );

    test('checksum failure preserves the healthy predecessor', () async {
      final manifest = healthyManifest();
      final installer = VoiceModelPackInstaller(rootDirectory: root);
      final original = await withHttp(() => installer.install(manifest));
      final originalBytes = await original.artifactFile('model').readAsBytes();
      replies['https://models.example/model.bin'] = _Reply(
        200,
        utf8.encode('tampered payl'),
      );

      await expectLater(
        withHttp(() => installer.install(manifest)),
        throwsA(
          isA<VoiceModelPackException>().having(
            (error) => error.code,
            'code',
            VoiceModelPackError.integrity,
          ),
        ),
      );

      final restored = await installer.installedPack(manifest);
      expect(restored, isNotNull);
      expect(
        await restored!.artifactFile('model').readAsBytes(),
        originalBytes,
      );
    });

    test('refuses HTTPS redirects to cleartext without issuing them', () async {
      final manifest = healthyManifest();
      replies['https://models.example/model.bin'] = const _Reply(
        HttpStatus.found,
        <int>[],
        'http://attacker.example/model.bin',
      );

      await expectLater(
        withHttp(
          () => VoiceModelPackInstaller(rootDirectory: root).install(manifest),
        ),
        throwsA(
          isA<VoiceModelPackException>().having(
            (error) => error.code,
            'code',
            VoiceModelPackError.transport,
          ),
        ),
      );
      expect(requested.map((uri) => uri.scheme), everyElement('https'));
    });
  });
}

final class _Reply {
  const _Reply(this.statusCode, [this.body = const <int>[], this.location]);

  final int statusCode;
  final List<int> body;
  final String? location;
}

final class _FakeHttpClient implements HttpClient {
  _FakeHttpClient(this.onGetUrl);

  final Future<HttpClientRequest> Function(Uri) onGetUrl;

  @override
  Duration? connectionTimeout;

  @override
  Future<HttpClientRequest> getUrl(Uri url) => onGetUrl(url);

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

final class _FakeRequest implements HttpClientRequest {
  _FakeRequest(this.reply);

  final _Reply reply;

  @override
  bool followRedirects = true;

  @override
  Future<HttpClientResponse> close() async => _FakeResponse(reply);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

final class _FakeResponse extends Stream<List<int>>
    implements HttpClientResponse {
  const _FakeResponse(this.reply);

  final _Reply reply;

  @override
  int get statusCode => reply.statusCode;

  @override
  int get contentLength => reply.body.length;

  @override
  HttpHeaders get headers => _FakeHeaders(reply.location);

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(reply.body).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  Future<E> drain<E>([E? futureValue]) async => futureValue as E;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

final class _FakeHeaders implements HttpHeaders {
  const _FakeHeaders(this.location);

  final String? location;

  @override
  String? value(String name) =>
      name.toLowerCase() == HttpHeaders.locationHeader ? location : null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}
