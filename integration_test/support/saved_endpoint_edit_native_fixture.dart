import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/core/hermes/client/hermes_api_config.dart';
import 'package:wing/core/hermes/client/hermes_api_transport.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/core/hermes/shared/hermes_api_http.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';

import '../../test/features/hermes_chat/support/fake_hermes_endpoint_store.dart';

/// Disposable credential-free socket authority. Only discovery reads are allowed.
class SavedEndpointEditNativeFixture {
  static const body =
      '{"object":"hermes.api_server.capabilities","platform":"hermes-agent","schema_version":1}';
  late final HttpServer server;
  final requests = <Map<String, Object?>>[];
  int status = 200;
  int forbidden = 0;
  Completer<void>? gate;
  final pending = <Future<void>>[];

  String get origin => 'http://127.0.0.1:${server.port}';

  Future<void> start() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      final work = respond(request);
      pending.add(work);
    });
  }

  Future<void> respond(HttpRequest request) async {
    final capturedStatus = status;
    final capturedGate = gate;
    gate = null;
    requests.add({
      'method': request.method,
      'path': request.uri.path,
      'query': request.uri.queryParameters,
      'status': capturedStatus,
    });
    if (request.method != 'GET' ||
        request.uri.path != '/v1/capabilities' ||
        request.uri.hasQuery ||
        request.headers.value('Authorization') != null) {
      forbidden++;
      request.response.statusCode = 405;
    } else {
      await capturedGate?.future;
      request.response.statusCode = capturedStatus;
      request.response.write(capturedStatus == 200 ? body : 'private-response');
    }
    await request.response.close();
  }

  HermesApiClient client(HermesApiConfig config) => HermesApiClient(
    config: config,
    get: (uri, headers) async {
      if (uri.origin != origin || uri.path != '/v1/capabilities') {
        forbidden++;
        throw StateError('Forbidden destination');
      }
      final http = HttpClient();
      try {
        final request = await http.getUrl(uri);
        request.followRedirects = false;
        headers.forEach(request.headers.set);
        final response = await request.close();
        final text = await utf8.decoder.bind(response).join();
        if (response.statusCode != 200) {
          throw SavedEditReadDenial(response.statusCode);
        }
        return text;
      } finally {
        http.close(force: true);
      }
    },
    post: (uri, headers, body) {
      forbidden++;
      return unsupportedHermesApiPost(uri, headers, body);
    },
    patch: (uri, headers, body) {
      forbidden++;
      return unsupportedHermesApiPatch(uri, headers, body);
    },
    put: (uri, headers, body) {
      forbidden++;
      return unsupportedHermesApiPut(uri, headers, body);
    },
    delete: (uri, headers) {
      forbidden++;
      return unsupportedHermesApiDelete(uri, headers);
    },
    postStream: (uri, headers, body) {
      forbidden++;
      return unsupportedHermesApiPostStream(uri, headers, body);
    },
    getStream: (uri, headers) {
      forbidden++;
      return unsupportedHermesApiGetStream(uri, headers);
    },
  );

  Future<void> close() async {
    await server.close(force: true);
    await Future.wait(pending);
  }
}

final class SavedEditReadDenial implements HermesApiStatusException {
  const SavedEditReadDenial(this.statusCode);
  @override
  final int statusCode;
}

class SavedEditStore extends FakeHermesEndpointStore {
  SavedEditStore()
    : super(
        profiles: [
          const HermesEndpointConfig(
            id: 'original',
            baseUrl: 'https://original.example.invalid',
            label: 'Shared name',
          ),
          const HermesEndpointConfig(
            id: 'peer',
            baseUrl: 'https://peer.example.invalid',
            label: 'Shared name',
          ),
        ],
      );
}

/// Directory reads are deliberately inert; only explicit Test opens the socket.
class SavedEditDirectoryLoader implements GatewaySummaryLoader {
  @override
  Future<GatewaySummary> load(HermesEndpointConfig config) async =>
      const GatewaySummary(profiles: [], sessionsByProfile: {});
}
