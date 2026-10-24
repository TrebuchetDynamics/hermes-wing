part of 'hermes_web_read_client.dart';

extension _ManagedDownloadReader on HermesWebReadClient {
  Future<Uint8List> _downloadManagedFile(
    String path,
    HermesManagedFileTransfer transfer, {
    required bool Function() isCurrent,
  }) async {
    void check() {
      transfer.check();
      if (!isCurrent()) {
        throw const HermesManagedFilesException(
          HermesManagedFilesFailure.stale,
        );
      }
    }

    check();
    if (_credential == null || _http.length >= 8) {
      throw const HermesManagedFilesException(HermesManagedFilesFailure.denied);
    }
    final client = HttpClient()
      ..connectionTimeout = timeout
      ..autoUncompress = false
      ..findProxy = (_) => 'DIRECT';
    _http.add(client);
    var finished = false;
    unawaited(
      transfer.whenCancelled.then((_) {
        if (!finished) client.close(force: true);
      }),
    );
    try {
      return await (() async {
        final request = await client.getUrl(
          _origin.replace(
            path: '/api/files/download',
            queryParameters: {'path': path},
          ),
        );
        check();
        request.followRedirects = false;
        request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
        request.headers.set(
          hermesApiAuthorizationHeader,
          hermesApiBearerAuthorization(_credential),
        );
        final response = await request.close();
        check();
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw const HermesManagedFilesException(
            HermesManagedFilesFailure.denied,
          );
        }
        if (response.statusCode == 413) {
          throw const HermesManagedFilesException(
            HermesManagedFilesFailure.oversized,
          );
        }
        if (response.statusCode != 200 ||
            (response.headers.value(HttpHeaders.contentEncodingHeader) ??
                    'identity') !=
                'identity') {
          throw const HermesManagedFilesException(
            HermesManagedFilesFailure.failed,
          );
        }
        final length = response.contentLength;
        const maximum = HermesManagedFilesSession.maximumDownloadBytes;
        if (length > maximum) {
          throw const HermesManagedFilesException(
            HermesManagedFilesFailure.oversized,
          );
        }
        final bytes = BytesBuilder(copy: false);
        transfer.onProgress?.call(0, length < 0 ? null : length);
        await for (final chunk in response) {
          check();
          if (bytes.length + chunk.length > maximum) {
            throw const HermesManagedFilesException(
              HermesManagedFilesFailure.oversized,
            );
          }
          bytes.add(chunk);
          transfer.onProgress?.call(bytes.length, length < 0 ? null : length);
        }
        check();
        if (length >= 0 && bytes.length != length) {
          throw const HermesManagedFilesException(
            HermesManagedFilesFailure.failed,
          );
        }
        return bytes.takeBytes();
      })().timeout(const Duration(seconds: 30));
    } on HermesManagedFilesException {
      rethrow;
    } catch (_) {
      check();
      throw const HermesManagedFilesException(HermesManagedFilesFailure.failed);
    } finally {
      finished = true;
      _http.remove(client);
      client.close(force: true);
    }
  }
}
