import 'dart:convert';
import 'dart:io';

import 'package:wing/core/hermes/client/hermes_web_read_client.dart';

/// Invoked only by qualify_hermes_web_reads.py with owned ephemeral auth on stdin.
Future<void> main() async {
  final input =
      jsonDecode(await stdin.transform(utf8.decoder).join())
          as Map<String, dynamic>;
  final origin = Uri.parse(input['origin'] as String);
  final credential = input['credential'] as String;
  final assertions = <String, bool>{};
  HermesWebReadClient client(String? auth, {String profile = 'default'}) =>
      HermesWebReadClient.forQualification(
        origin: origin,
        credential: auth,
        profile: profile,
      );
  Future<void> rejects(
    String name,
    Future<Object?> Function() action,
    HermesWebFailureKind kind, {
    int? code,
  }) async {
    try {
      await action();
      throw StateError('rejection missing');
    } on HermesWebReadException catch (e) {
      if (e.kind != kind ||
          (code != null && e.rpcCode != code) ||
          e.toString().contains(credential)) {
        throw StateError('unexpected rejection');
      }
      assertions[name] = true;
    }
  }

  final owned = client(credential);
  final anonymous = client(null);
  final wrong = client('invalid-qualification');
  final missing = client(credential, profile: 'missing-qualification-profile');
  try {
    final page = await owned.sessions(limit: 10);
    if (page.total != 1 ||
        page.sessions.single.id != 'wing-qualification-session' ||
        page.sessions.single.model != null ||
        page.sessions.single.endedAt == null) {
      throw StateError('inventory mismatch');
    }
    assertions['dart_rest_explicit_default_list'] = true;
    final history = await owned.history(
      'wing-qualification-session',
      limit: 10,
      order: 'oldest',
    );
    if (history.returned != 2 ||
        history.messages.map((m) => m.id).join(',') != '1,2' ||
        history.messages.first.content != 'Synthetic read-only fixture' ||
        history.messages.last.content !=
            'Synthetic fixture reply, not generation' ||
        history.messages.first.timestamp == null) {
      throw StateError('history mismatch');
    }
    assertions['dart_rest_identity_numeric_ids_unix_time_nullable_history'] =
        true;
    for (final entry in {'anonymous': anonymous, 'wrong': wrong}.entries) {
      await rejects(
        'dart_${entry.key}_rest_rejected',
        () => entry.value.sessions(limit: 10),
        HermesWebFailureKind.authentication,
      );
      await rejects(
        'dart_${entry.key}_history_rejected',
        () => entry.value.history('wing-qualification-session'),
        HermesWebFailureKind.authentication,
      );
      await rejects(
        'dart_${entry.key}_ticket_rejected',
        entry.value.connectReads,
        HermesWebFailureKind.authentication,
      );
    }
    await rejects(
      'dart_missing_profile_list',
      () => missing.sessions(limit: 10),
      HermesWebFailureKind.notFound,
    );
    await rejects(
      'dart_missing_profile_history',
      () => missing.history('wing-qualification-session'),
      HermesWebFailureKind.notFound,
    );
    final connection = await owned.connectReads();
    if (connection.replayEpoch.isEmpty ||
        !await connection.ping() ||
        !(await connection.sessionIds(
          limit: 10,
        )).contains('wing-qualification-session')) {
      throw StateError('RPC mismatch');
    }
    assertions['dart_ticket_subprotocol_gateway_ready_ping_list'] = true;
    final missingConnection = await missing.connectReads();
    await rejects(
      'dart_missing_profile_rpc_4064',
      () => missingConnection.sessionIds(limit: 10),
      HermesWebFailureKind.rpc,
      code: 4064,
    );
    if (owned.productAuthorization !=
        HermesWebProductAuthorization.unsupportedAuthorization) {
      throw StateError('authorization upgraded');
    }
    assertions['production_authorization_unsupported_despite_positive_reads'] =
        true;

    // Ticket lifetime/reuse are separate protocol probes; all adapter reads above
    // use the actual implementation, not these harness helpers.
    Future<Map<String, dynamic>> mint() async {
      final http = HttpClient()..findProxy = (_) => 'DIRECT';
      try {
        final request = await http.postUrl(
          origin.replace(path: '/api/auth/ws-ticket'),
        );
        request.followRedirects = false;
        request.headers.set('Authorization', 'Bearer $credential');
        request.headers.contentType = ContentType.json;
        request.write('{}');
        final response = await request.close();
        if (response.statusCode != 200) throw StateError('ticket mint failed');
        return jsonDecode(await response.transform(utf8.decoder).join())
            as Map<String, dynamic>;
      } finally {
        http.close(force: true);
      }
    }

    Future<WebSocket> upgrade(String? ticket) => WebSocket.connect(
      origin.replace(scheme: 'ws', path: '/api/ws').toString(),
      protocols: ticket == null
          ? null
          : ['hermes-gateway-v1', 'hermes-gateway-ticket.$ticket'],
    ).timeout(const Duration(seconds: 10));
    Future<void> rejectedUpgrade(String name, String? ticket) async {
      WebSocket? socket;
      try {
        socket = await upgrade(ticket);
        throw StateError('upgrade accepted');
      } on WebSocketException catch (e) {
        if (e.httpStatusCode != 403) {
          throw StateError('unexpected upgrade failure');
        }
        assertions[name] = true;
      } finally {
        await socket?.close();
      }
    }

    await rejectedUpgrade('dart_anonymous_upgrade_rejected', null);
    await rejectedUpgrade(
      'dart_wrong_upgrade_ticket_rejected',
      'invalid-qualification',
    );
    final ticket = await mint();
    final socket = await upgrade(ticket['ticket'] as String);
    final ready =
        jsonDecode(
              await socket.first.timeout(const Duration(seconds: 10)) as String,
            )
            as Map;
    if (socket.protocol != 'hermes-gateway-v1' ||
        (ready['params'] as Map)['type'] != 'gateway.ready') {
      throw StateError('ready mismatch');
    }
    await socket.close();
    await rejectedUpgrade(
      'dart_ticket_single_use_rejected',
      ticket['ticket'] as String,
    );
    final expiryTicket = await mint();
    final ttl = expiryTicket['ttl_seconds'];
    if (ttl is! int || ttl < 1 || ttl > 60) {
      throw StateError('ticket TTL unexpected');
    }
    await Future<void>.delayed(Duration(seconds: ttl + 2));
    await rejectedUpgrade(
      'dart_real_duration_ticket_expiry_rejected',
      expiryTicket['ticket'] as String,
    );
    await Future<void>.delayed(const Duration(seconds: 34));
    await rejects(
      'dart_real_duration_access_expiry_rejected',
      () => owned.sessions(limit: 10),
      HermesWebFailureKind.authentication,
    );
    stdout.writeln(
      jsonEncode({
        'assertions': assertions,
        'platform': 'Linux Dart VM loopback only',
        'production_activation': false,
        'ticket_ttl_seconds': ttl,
      }),
    );
  } catch (_) {
    // Raw network/auth/parse exceptions must never leave the private probe.
    stdout.writeln(
      jsonEncode({
        'assertions': assertions,
        'failure': 'live Dart qualification failed',
      }),
    );
    exitCode = 1;
  } finally {
    for (final value in [owned, anonymous, wrong, missing]) {
      value.disconnect();
    }
  }
}
