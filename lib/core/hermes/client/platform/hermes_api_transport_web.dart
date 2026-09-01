import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../../shared/hermes_api_http.dart';

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
}) {
  final request = web.XMLHttpRequest();
  late final StreamController<String> controller;
  controller = StreamController<String>(
    onCancel: () {
      request.abort();
    },
  );
  var delivered = 0;
  var settled = false;

  request.open(method, uri.toString(), true);
  headers.forEach((name, value) => request.setRequestHeader(name, value));
  request.onProgress.listen((_) {
    if (settled) return;
    if (request.responseURL.isNotEmpty &&
        !_matchesRequestUrl(request.responseURL, uri)) {
      settled = true;
      request.abort();
      controller.addError(StateError('Hermes API redirects are not supported'));
      controller.close();
      return;
    }
    final text = request.responseText;
    if (text.length > delivered) {
      controller.add(text.substring(delivered));
      delivered = text.length;
    }
  });
  request.onLoad.listen((_) {
    if (settled) return;
    settled = true;
    if (!_matchesRequestUrl(request.responseURL, uri)) {
      controller.addError(StateError('Hermes API redirects are not supported'));
    } else if (!hermesApiIsSuccessStatus(request.status)) {
      controller.addError(
        StateError(hermesApiHttpStatusMessage(request.status)),
      );
    } else {
      final text = request.responseText;
      if (text.length > delivered) controller.add(text.substring(delivered));
    }
    controller.close();
  });
  request.onError.listen((_) {
    if (settled) return;
    settled = true;
    controller.addError(StateError(hermesApiHttpStatusMessage(request.status)));
    controller.close();
  });

  final payload = body;
  if (payload == null) {
    request.send();
  } else {
    request.send(payload.toJS);
  }
  return controller.stream;
}

Future<String> _request({
  required Uri uri,
  required String method,
  required Map<String, String> headers,
  String? body,
}) async {
  final request = web.XMLHttpRequest();
  final completer = Completer<String>();

  request.open(method, uri.toString(), true);
  headers.forEach((name, value) => request.setRequestHeader(name, value));
  request.onLoad.listen((_) {
    if (!_matchesRequestUrl(request.responseURL, uri)) {
      completer.completeError(
        StateError('Hermes API redirects are not supported'),
      );
      return;
    }
    final status = request.status;
    if (hermesApiIsSuccessStatus(status)) {
      completer.complete(request.responseText);
    } else {
      completer.completeError(StateError(hermesApiHttpStatusMessage(status)));
    }
  });
  request.onError.listen(
    (_) => completer.completeError(
      StateError(hermesApiHttpStatusMessage(request.status)),
    ),
  );

  final payload = body;
  if (payload == null) {
    request.send();
  } else {
    request.send(payload.toJS);
  }
  return completer.future;
}

bool _matchesRequestUrl(String responseUrl, Uri requestUri) {
  final responseUri = Uri.tryParse(responseUrl);
  if (responseUri == null) return false;
  final expected = requestUri.replace(fragment: null);
  return responseUri.scheme == expected.scheme &&
      responseUri.userInfo == expected.userInfo &&
      responseUri.host == expected.host &&
      responseUri.port == expected.port &&
      responseUri.path == expected.path &&
      responseUri.query == expected.query;
}
