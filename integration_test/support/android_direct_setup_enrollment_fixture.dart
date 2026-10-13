import 'dart:convert';

import 'direct_first_run_native_fixture.dart';

/// Synthetic authenticated loopback authority, never a real Agent or socket.
class AndroidDirectSetupEnrollmentFixture extends DirectFirstRunNativeFixture {
  static const loopback = 'http://127.0.0.1:8642';
  static const token = 'synthetic-android-qa-token';

  @override
  Future<String> get(Uri uri, Map<String, String> headers) async {
    if (uri.origin != loopback) {
      forbiddenReadAttempts++;
      throw StateError('Only synthetic loopback reads permitted');
    }
    final authorization = headers['Authorization'];
    if (authorization != 'Bearer $token') {
      deniedReads.add({'status': 401, 'path': uri.path});
      throw const DirectFirstRunReadDenial(401);
    }
    final result = await super.get(
      uri.replace(scheme: 'https', host: 'example.invalid', port: 443),
      {...headers}..remove('Authorization'),
    );
    if (uri.path != '/v1/capabilities') return result;
    final capabilities = jsonDecode(result) as Map<String, dynamic>;
    (capabilities['auth'] as Map<String, dynamic>)['required'] = true;
    return jsonEncode(capabilities);
  }
}
