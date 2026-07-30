@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:wing/features/voice/services/tts/pocket_speech_asset_download_service.dart';
import 'package:wing/features/voice/services/tts/pocket_speech_asset_download_service_io.dart';
import 'package:wing/shared/voice/voice_settings.dart';

/// One canned reply for a single URL.
class _Reply {
  _Reply({
    required this.statusCode,
    this.body = const <int>[],
    this.location,
    this.contentLength,
  });

  final int statusCode;
  final List<int> body;
  final String? location;
  final int? contentLength;
}

void main() {
  late Directory root;
  late List<Uri> requested;
  late Map<String, _Reply> replies;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    root = await Directory.systemTemp.createTemp('pocket-speech-test');
    // Answer path_provider over its platform channel so the test needs no
    // transitive platform-interface dependency.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => root.path,
        );
    requested = [];
    replies = {};
  });

  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  /// Runs [body] with HttpClient serving [replies] and recording [requested].
  Future<T> withHttp<T>(Future<T> Function() body) => HttpOverrides.runZoned(
    body,
    createHttpClient: (_) => _FakeHttpClient((uri) async {
      requested.add(uri);
      final reply = replies[uri.toString()];
      if (reply == null) throw HttpException('unexpected $uri');
      return _FakeRequest(reply);
    }),
  );

  String sha(List<int> bytes) => sha256.convert(bytes).toString();

  /// A spec whose model and voices payloads are served correctly.
  ({PocketSpeechDownloadSpec spec, List<int> model, List<int> voices})
  healthySpec() {
    final model = utf8.encode('onnx-model-bytes');
    final voices = utf8.encode('{"af":"voice"}');
    replies['https://cdn.example/model.onnx'] = _Reply(
      statusCode: 200,
      body: model,
    );
    replies['https://cdn.example/voices.json'] = _Reply(
      statusCode: 200,
      body: voices,
    );
    return (
      spec: PocketSpeechDownloadSpec(
        modelUrl: 'https://cdn.example/model.onnx',
        voicesJsonUrl: 'https://cdn.example/voices.json',
        modelSha256: sha(model),
        voicesJsonSha256: sha(voices),
        modelBytes: model.length,
        voicesJsonBytes: voices.length,
      ),
      model: model,
      voices: voices,
    );
  }

  IoPocketSpeechAssetDownloadService serviceFor(
    PocketSpeechDownloadSpec spec,
  ) => IoPocketSpeechAssetDownloadService(
    config: PocketSpeechAssetDownloadConfig(
      kitten: spec,
      kokoro: const PocketSpeechDownloadSpec(
        modelUrl: '',
        voicesJsonUrl: '',
        modelSha256: '',
        voicesJsonSha256: '',
        modelBytes: 0,
        voicesJsonBytes: 0,
      ),
    ),
  );

  test('a healthy download installs both files', () async {
    final fixture = healthySpec();

    final pack = await withHttp(
      () => serviceFor(fixture.spec).download(PocketSpeechModel.kitten),
    );

    expect(File(pack.modelPath).readAsBytesSync(), fixture.model);
    expect(File(pack.voicesPath).readAsBytesSync(), fixture.voices);
  });

  test('an unconfigured model refuses to download', () async {
    final service = serviceFor(healthySpec().spec);

    await expectLater(
      withHttp(() => service.download(PocketSpeechModel.kokoro)),
      throwsStateError,
    );
    expect(requested, isEmpty, reason: 'nothing should be fetched');
  });

  group('integrity', () {
    test('a tampered payload fails its pinned checksum', () async {
      final fixture = healthySpec();
      final tampered = utf8.encode('onnx-model-EVIL!');
      expect(tampered.length, fixture.model.length, reason: 'same size');
      replies['https://cdn.example/model.onnx'] = _Reply(
        statusCode: 200,
        body: tampered,
      );

      await expectLater(
        withHttp(
          () => serviceFor(fixture.spec).download(PocketSpeechModel.kitten),
        ),
        throwsA(
          isStateError.having(
            (e) => e.message,
            'message',
            contains('checksum'),
          ),
        ),
      );
    });

    test('a short payload is rejected on size', () async {
      final fixture = healthySpec();
      replies['https://cdn.example/model.onnx'] = _Reply(
        statusCode: 200,
        body: utf8.encode('short'),
        contentLength: -1,
      );

      await expectLater(
        withHttp(
          () => serviceFor(fixture.spec).download(PocketSpeechModel.kitten),
        ),
        throwsA(
          isStateError.having((e) => e.message, 'message', contains('size')),
        ),
      );
    });

    test('an oversized payload is cut off mid-stream', () async {
      final fixture = healthySpec();
      replies['https://cdn.example/model.onnx'] = _Reply(
        statusCode: 200,
        body: utf8.encode('onnx-model-bytes-and-a-lot-more-padding'),
        contentLength: -1,
      );

      await expectLater(
        withHttp(
          () => serviceFor(fixture.spec).download(PocketSpeechModel.kitten),
        ),
        throwsA(
          isStateError.having(
            (e) => e.message,
            'message',
            contains('exceeded'),
          ),
        ),
      );
    });

    test(
      'a declared length that disagrees with the spec is rejected',
      () async {
        final fixture = healthySpec();
        replies['https://cdn.example/model.onnx'] = _Reply(
          statusCode: 200,
          body: fixture.model,
          contentLength: fixture.model.length + 10,
        );

        await expectLater(
          withHttp(
            () => serviceFor(fixture.spec).download(PocketSpeechModel.kitten),
          ),
          throwsA(
            isStateError.having((e) => e.message, 'message', contains('size')),
          ),
        );
      },
    );

    test('voices content that is not a JSON object is rejected', () async {
      final fixture = healthySpec();
      final notAnObject = utf8.encode('["a","list"]');
      replies['https://cdn.example/voices.json'] = _Reply(
        statusCode: 200,
        body: notAnObject,
      );
      final spec = PocketSpeechDownloadSpec(
        modelUrl: fixture.spec.modelUrl,
        voicesJsonUrl: fixture.spec.voicesJsonUrl,
        modelSha256: fixture.spec.modelSha256,
        voicesJsonSha256: sha(notAnObject),
        modelBytes: fixture.spec.modelBytes,
        voicesJsonBytes: notAnObject.length,
      );

      await expectLater(
        withHttp(() => serviceFor(spec).download(PocketSpeechModel.kitten)),
        throwsFormatException,
      );
    });
  });

  group('transport', () {
    test('an HTTPS redirect is followed', () async {
      final fixture = healthySpec();
      replies['https://cdn.example/model.onnx'] = _Reply(
        statusCode: HttpStatus.found,
        location: 'https://cdn.example/model-v2.onnx',
      );
      replies['https://cdn.example/model-v2.onnx'] = _Reply(
        statusCode: 200,
        body: fixture.model,
      );

      final pack = await withHttp(
        () => serviceFor(fixture.spec).download(PocketSpeechModel.kitten),
      );

      expect(File(pack.modelPath).readAsBytesSync(), fixture.model);
      expect(
        requested.map((u) => u.toString()),
        contains('https://cdn.example/model-v2.onnx'),
      );
    });

    test('a redirect that downgrades to cleartext is refused', () async {
      final fixture = healthySpec();
      replies['https://cdn.example/model.onnx'] = _Reply(
        statusCode: HttpStatus.movedPermanently,
        location: 'http://cdn.example/model.onnx',
      );

      await expectLater(
        withHttp(
          () => serviceFor(fixture.spec).download(PocketSpeechModel.kitten),
        ),
        throwsA(
          isStateError.having((e) => e.message, 'message', contains('HTTPS')),
        ),
      );
      expect(
        requested.map((u) => u.scheme),
        everyElement('https'),
        reason: 'the client must never issue the cleartext request',
      );
    });

    test('an endless redirect chain is capped', () async {
      final fixture = healthySpec();
      replies['https://cdn.example/model.onnx'] = _Reply(
        statusCode: HttpStatus.found,
        location: 'https://cdn.example/model.onnx',
      );

      await expectLater(
        withHttp(
          () => serviceFor(fixture.spec).download(PocketSpeechModel.kitten),
        ),
        throwsA(isA<Object>()),
      );
      expect(requested.length, lessThanOrEqualTo(7));
    });

    test('a server error is surfaced, not written to disk', () async {
      final fixture = healthySpec();
      replies['https://cdn.example/model.onnx'] = _Reply(statusCode: 503);

      await expectLater(
        withHttp(
          () => serviceFor(fixture.spec).download(PocketSpeechModel.kitten),
        ),
        throwsA(isA<HttpException>()),
      );
    });
  });

  test('a failed download leaves no partial files behind', () async {
    final fixture = healthySpec();
    replies['https://cdn.example/voices.json'] = _Reply(statusCode: 500);

    await expectLater(
      withHttp(
        () => serviceFor(fixture.spec).download(PocketSpeechModel.kitten),
      ),
      throwsA(isA<HttpException>()),
    );

    final dir = Directory('${root.path}/pocket_speech/kitten');
    final leftovers = dir.existsSync()
        ? dir.listSync().map((e) => e.path.split('/').last).toList()
        : <String>[];
    expect(
      leftovers.where((n) => n.endsWith('.download')),
      isEmpty,
      reason: 'temp files must be cleaned up',
    );
  });

  test('delete removes an installed voice pack', () async {
    final fixture = healthySpec();
    await withHttp(
      () => serviceFor(fixture.spec).download(PocketSpeechModel.kitten),
    );
    final dir = Directory('${root.path}/pocket_speech/kitten');
    expect(dir.existsSync(), isTrue);

    await serviceFor(fixture.spec).delete(PocketSpeechModel.kitten);

    expect(dir.existsSync(), isFalse);
  });
}

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient(this.onGetUrl);

  final Future<HttpClientRequest> Function(Uri url) onGetUrl;

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

class _FakeRequest implements HttpClientRequest {
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

class _FakeResponse extends Stream<List<int>> implements HttpClientResponse {
  _FakeResponse(this.reply);

  final _Reply reply;

  @override
  int get statusCode => reply.statusCode;

  @override
  int get contentLength => reply.contentLength ?? reply.body.length;

  @override
  HttpHeaders get headers => _FakeHeaders(reply.location);

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
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

class _FakeHeaders implements HttpHeaders {
  _FakeHeaders(this.location);

  final String? location;

  @override
  String? value(String name) =>
      name.toLowerCase() == HttpHeaders.locationHeader ? location : null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}
