part of 'hermes_web_read_client.dart';

const _botTitle = 'Bot Chat';
typedef _BotRegistryRow = ({String id, String tip, bool hasHistory});

extension _BotChatRequests on HermesWebReadClient {
  Future<_BotRegistryRow?> _lookupBotChat(
    HermesWebReadConnection rpc, {
    required bool knownCanonical,
  }) async {
    final response = await rpc._read('session.list', {
      'profile': _profile,
      'title': _botTitle,
      'include_hidden': true,
      'limit': 200,
    });
    // Exact-title lookup is a registry. Neither a malformed/windowed response
    // nor an empty result contradicting positive evidence establishes absence.
    final rows = webRows(response['sessions'], 1);
    if (rows.isEmpty) {
      if (knownCanonical) webMalformed();
      return null;
    }
    final row = webObject(rows.single);
    if (row.containsKey('profile')) webIdentity(row['profile'], _profile);
    webIdentity(row['root_title'] ?? row['title'], _botTitle);
    final id = webString(row['id'], maximum: 128);
    final tip = webString(row['resolved_id'] ?? id, maximum: 128);
    HermesWebReadClient._validateIdentity(id);
    HermesWebReadClient._validateIdentity(tip);
    // Pending hiding is separate/best-effort in Agent's lazy materialization.
    // Retain only these facts from the native detail response, never its blobs.
    for (final session in {id, tip}) {
      final detail = await _request(
        '/api/sessions/$session',
        query: {'profile': _profile},
      );
      webIdentity(detail['id'], session);
      webIdentity(detail['profile'], _profile);
      if (session == id) webIdentity(detail['title'], _botTitle);
      final hidden = detail['hidden'];
      if (hidden != true && !(hidden is int && hidden == 1)) webMalformed();
    }
    final count = row['live_message_count'] ?? row['message_count'];
    return (
      id: id,
      tip: tip,
      hasHistory: count == null || webInteger(count) > 0,
    );
  }

  Future<HermesServeLifecycle?> _prepareBotChat({
    required bool knownCanonical,
    required bool allowCreate,
    required String idempotencyKey,
    required bool Function() canAccept,
  }) async {
    if (!canAccept()) return null;
    final lifecycle = await connectLifecycleForProduct() as HermesWebLifecycle;
    lifecycle._stagingBotChat = true;
    if (!canAccept()) return null;
    final rpc = lifecycle._connection;
    var row = await _lookupBotChat(rpc, knownCanonical: knownCanonical);
    if (!canAccept()) return null;
    if (row == null) {
      if (!allowCreate) return null;
      // Adopt-before-mint also covers another client racing this gesture.
      row = await _lookupBotChat(rpc, knownCanonical: false);
      if (!canAccept()) return null;
      if (row == null) {
        final created = await rpc._read('session.create', {
          'profile': _profile,
          'title': _botTitle,
          'hidden': true,
          'follow_profile_config': true,
          'idempotency_key': idempotencyKey,
        });
        if (!canAccept()) return null;
        final runtime = webString(created['session_id'], maximum: 128);
        HermesWebReadClient._validateIdentity(runtime);
        HermesWebReadClient._validateIdentity(
          webString(created['stored_session_id'], maximum: 128),
        );
        final info = webObject(created['info']);
        if (info.containsKey('profile_name')) {
          webIdentity(info['profile_name'], _profile);
        }
        try {
          final titled = await rpc._read('session.title', {
            'profile': _profile,
            'session_id': runtime,
            'title': _botTitle,
          });
          if (!canAccept()) return null;
          webIdentity(titled['title'], _botTitle);
          webIdentity(titled['pending'], false);
        } on HermesWebReadException catch (error) {
          // This exact title conflict alone permits adopting a registry winner.
          // No timeout retry, kickoff, compatibility prompt or hidden rollback.
          if (error.kind != HermesWebFailureKind.rpc || error.rpcCode != 4022) {
            rethrow;
          }
        }
        if (!canAccept()) return null;
        row = await _lookupBotChat(rpc, knownCanonical: true);
        if (!canAccept()) return null;
      }
    }
    if (row == null || !canAccept()) return null;
    await lifecycle.resumeSession(row.tip);
    if (!canAccept()) return null;
    if (!lifecycle.eventReplaySupported ||
        lifecycle.needsReconciliation ||
        lifecycle.disconnected) {
      throw UnsupportedError(
        'Canonical Bot Chat needs settled history and replay.',
      );
    }
    if (row.hasHistory && lifecycle.turns.isEmpty) webMalformed();
    return lifecycle;
  }
}
