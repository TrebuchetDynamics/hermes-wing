import '../../protocol/navivox_json.dart';

/// Snapshot of a gateway session.
class NavivoxGatewaySessionSnapshot {
  const NavivoxGatewaySessionSnapshot({
    required this.sessionId,
    required this.lastRequestId,
    required this.profileServer,
    required this.profileId,
    required this.createdAt,
    required this.updatedAt,
    required this.subscribers,
  });

  factory NavivoxGatewaySessionSnapshot.fromJson(Map<String, Object?> json) {
    return NavivoxGatewaySessionSnapshot(
      sessionId: navivoxStringFromJson(json['session_id'], fallback: ''),
      lastRequestId: navivoxStringFromJson(
        json['last_request_id'],
        fallback: '',
      ),
      profileServer: navivoxStringFromJson(
        json['profile_server'],
        fallback: '',
      ),
      profileId: navivoxStringFromJson(json['profile_id'], fallback: ''),
      createdAt: navivoxDateTimeFromJson(json['created_at']),
      updatedAt: navivoxDateTimeFromJson(json['updated_at']),
      subscribers: navivoxIntFromJson(json['subscribers']),
    );
  }

  final String sessionId;
  final String lastRequestId;
  final String profileServer;
  final String profileId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int subscribers;
}

/// Snapshot of a gateway run record.
class NavivoxRunRecordSnapshot {
  const NavivoxRunRecordSnapshot({
    required this.runId,
    required this.sessionId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.completedAt,
    required this.raw,
  });

  factory NavivoxRunRecordSnapshot.fromJson(Map<String, Object?> json) {
    return NavivoxRunRecordSnapshot(
      runId: navivoxStringFromJson(json['run_id'], fallback: ''),
      sessionId: navivoxStringFromJson(json['session_id'], fallback: ''),
      status: navivoxStringFromJson(json['status'], fallback: ''),
      createdAt: navivoxDateTimeFromJson(json['created_at']),
      updatedAt: navivoxDateTimeFromJson(json['updated_at']),
      completedAt: navivoxDateTimeFromJson(json['completed_at']),
      raw: json,
    );
  }

  final String runId;
  final String sessionId;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final Map<String, Object?> raw;
}

/// Result of a profile seed (draft or apply).
class NavivoxProfileSeedResult {
  const NavivoxProfileSeedResult({
    required this.action,
    required this.status,
    required this.applied,
    required this.profileId,
    required this.root,
    required this.workspaceCount,
    required this.draft,
    required this.contact,
  });

  factory NavivoxProfileSeedResult.fromJson(Map<String, Object?> json) {
    return NavivoxProfileSeedResult(
      action: navivoxStringFromJson(json['action'], fallback: ''),
      status: navivoxStringFromJson(json['status'], fallback: ''),
      applied: json['applied'] == true,
      profileId: navivoxStringFromJson(json['profile_id'], fallback: ''),
      root: navivoxStringFromJson(json['root'], fallback: ''),
      workspaceCount: navivoxIntFromJson(json['workspace_count']),
      draft: navivoxMapFromJson(json['draft']),
      contact: navivoxMapFromJson(json['contact']),
    );
  }

  final String action;
  final String status;
  final bool applied;
  final String profileId;
  final String root;
  final int workspaceCount;
  final Map<String, Object?> draft;
  final Map<String, Object?> contact;

  bool get isDraft => status == 'draft' && action == 'profile_seed_draft';
  bool get isApplied => applied && action == 'profile_seed_applied';
}

/// Profile routing report from the gateway.
class NavivoxProfileRoutingReport {
  const NavivoxProfileRoutingReport({this.profiles = const []});

  factory NavivoxProfileRoutingReport.fromJson(Map<String, Object?> json) {
    return NavivoxProfileRoutingReport(
      profiles: navivoxMapListFromJson(json['profiles'])
          .map(NavivoxProfileRoute.fromJson)
          .where((profile) => profile.profileId.isNotEmpty)
          .toList(growable: false),
    );
  }

  final List<NavivoxProfileRoute> profiles;
}

/// A single profile route entry.
class NavivoxProfileRoute {
  const NavivoxProfileRoute({
    required this.profileId,
    required this.displayName,
    this.workspaces = const [],
    this.providers = const [],
    this.channels = const [],
  });

  factory NavivoxProfileRoute.fromJson(Map<String, Object?> json) {
    final profileId = navivoxStringFromJson(json['profile_id'], fallback: '');
    return NavivoxProfileRoute(
      profileId: profileId,
      displayName: navivoxStringFromJson(
        json['display_name'],
        fallback: profileId,
      ),
      workspaces: navivoxStringListFromJson(json['workspaces']),
      providers: navivoxStringListFromJson(json['providers']),
      channels: navivoxStringListFromJson(json['channels']),
    );
  }

  final String profileId;
  final String displayName;
  final List<String> workspaces;
  final List<String> providers;
  final List<String> channels;
}
