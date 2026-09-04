import 'dart:convert';
import 'dart:io';

import '../../shared/hermes_api_http.dart';

const _maximumResponseBytes = 64 << 20;

Future<String> defaultGet(Uri uri, Map<String, String> headers) {
  return _request(uri: uri, method: 'GET', headers: headers);
}

Future<String> defaultPost(Uri uri, Map<String, String> headers, String body) {
  return _request(uri: uri, method: 'POST', headers: headers, body: body);
}

Future<String> defaultPatch(Uri uri, Map<String, String> headers, String body) {
  return _request(uri: uri, method: 'PATCH', headers: headers, body: body);
}

Future<String> defaultPut(Uri uri, Map<String, String> headers, String body) {
  return _request(uri: uri, method: 'PUT', headers: headers, body: body);
}

Future<String> defaultDelete(Uri uri, Map<String, String> headers) {
  return _request(uri: uri, method: 'DELETE', headers: headers);
}

Stream<String> defaultPostStream(
  Uri uri,
  Map<String, String> headers,
  String body,
) {
  return _requestStream(uri: uri, method: 'POST', headers: headers, body: body);
}

Stream<String> defaultGetStream(Uri uri, Map<String, String> headers) {
  return _requestStream(uri: uri, method: 'GET', headers: headers);
}

Stream<String> _requestStream({
  required Uri uri,
  required String method,
  required Map<String, String> headers,
  String? body,
}) async* {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
  try {
    final request = await client.openUrl(method, uri);
    request.followRedirects = false;
    headers.forEach(request.headers.set);
    final payload = body;
    if (payload != null) request.add(utf8.encode(payload));
    final response = await request.close();
    _checkResponseLength(response, uri);
    if (!hermesApiIsSuccessStatus(response.statusCode)) {
      throw HttpException(
        hermesApiHttpStatusMessage(response.statusCode),
        uri: uri,
      );
    }
    yield* utf8.decoder.bind(_boundedResponse(response, uri));
  } finally {
    client.close(force: true);
  }
}

Future<String> _request({
  required Uri uri,
  required String method,
  required Map<String, String> headers,
  String? body,
}) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
  try {
    final request = await client.openUrl(method, uri);
    request.followRedirects = false;
    headers.forEach(request.headers.set);
    final payload = body;
    if (payload != null) request.add(utf8.encode(payload));
    final response = await request.close();
    _checkResponseLength(response, uri);
    final responseBody = await utf8.decoder
        .bind(_boundedResponse(response, uri))
        .join();
    if (!hermesApiIsSuccessStatus(response.statusCode)) {
      throw HttpException(
        hermesApiHttpStatusMessage(response.statusCode),
        uri: uri,
      );
    }
    return responseBody;
  } finally {
    client.close(force: true);
  }
}

void _checkResponseLength(HttpClientResponse response, Uri uri) {
  if (response.contentLength > _maximumResponseBytes) {
    throw HttpException('Hermes API response exceeded its bound', uri: uri);
  }
}

Stream<List<int>> _boundedResponse(
  HttpClientResponse response,
  Uri uri,
) async* {
  var total = 0;
  await for (final chunk in response) {
    total += chunk.length;
    if (total > _maximumResponseBytes) {
      throw HttpException('Hermes API response exceeded its bound', uri: uri);
    }
    yield chunk;
  }
}
