import 'dart:async';
import 'dart:convert';

import 'package:wing/core/hermes/channel/hermes_api_channel.dart';

import '../../test/features/hermes_chat/support/fake_hermes_endpoint_store.dart';
import 'direct_first_run_native_fixture.dart';

/// Reuses the read-only synthetic authority; never opens a network socket.
class RemoteConnectionRetryNativeFixture extends DirectFirstRunNativeFixture {
  @override
  Future<String> get(Uri uri, Map<String, String> headers) async {
    final response = await super.get(uri, headers);
    if (uri.queryParameters['profile'] != 'default' ||
        !uri.path.startsWith('/api/sessions')) {
      return response;
    }
    final value = jsonDecode(response) as Map<String, dynamic>;
    // Direct connect uses the supported advertised default query context.
    // Keep its session rows distinct from the directory's synthetic-qa owner.
    if (uri.path == '/api/sessions') {
      for (final row in value['data'] as List<dynamic>) {
        (row as Map<String, dynamic>)['profile_id'] = 'default';
      }
    } else if (!uri.path.endsWith('/messages')) {
      value['profile_id'] = 'default';
    }
    return jsonEncode(value);
  }
}

class RetryNativeChannel extends HermesApiChannel {
  RetryNativeChannel(RemoteConnectionRetryNativeFixture fixture)
    : super(clientBuilder: fixture.client);

  int connects = 0;
  int disconnects = 0;

  @override
  Future<void> connect({
    required String baseUrl,
    String? apiKey,
    bool deferSessionSelection = false,
  }) {
    connects++;
    return super.connect(
      baseUrl: baseUrl,
      apiKey: apiKey,
      deferSessionSelection: deferSessionSelection,
    );
  }

  @override
  Future<void> disconnect() {
    disconnects++;
    return super.disconnect();
  }
}

/// Fault injection at the endpoint-store seam, NOT physical secure storage.
class RetryNativeStore extends FakeHermesEndpointStore {
  int attempts = 0;
  bool reject = false;
  Completer<void>? gate;

  @override
  Future<void> save({
    required String baseUrl,
    String? apiKey,
    String? label,
    String? profileId,
    String? wingLinkOrigin,
    String? wingLinkToken,
    String? wingLinkPendingCredentialId,
    String? wingLinkHostFingerprint,
    String? wingLinkDeviceId,
  }) async {
    attempts++;
    final pending = gate;
    gate = null;
    final fail = reject;
    await pending?.future;
    if (fail) throw StateError('private-storage-detail-must-not-render');
    await super.save(
      baseUrl: baseUrl,
      apiKey: apiKey,
      label: label,
      profileId: profileId,
      wingLinkOrigin: wingLinkOrigin,
      wingLinkToken: wingLinkToken,
      wingLinkPendingCredentialId: wingLinkPendingCredentialId,
      wingLinkHostFingerprint: wingLinkHostFingerprint,
      wingLinkDeviceId: wingLinkDeviceId,
    );
  }
}
