import '../../protocol/navivox_json.dart';
import '../shared/navivox_gateway_json.dart';

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
      sessionId: navivoxStringFieldFromJson(json, 'session_id'),
      lastRequestId: navivoxStringFieldFromJson(json, 'last_request_id'),
      profileServer: navivoxStringFieldFromJson(json, 'profile_server'),
      profileId: navivoxStringFieldFromJson(json, 'profile_id'),
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
      runId: navivoxStringFieldFromJson(json, 'run_id'),
      sessionId: navivoxStringFieldFromJson(json, 'session_id'),
      status: navivoxStringFieldFromJson(json, 'status'),
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
      action: navivoxStringFieldFromJson(json, 'action'),
      status: navivoxStringFieldFromJson(json, 'status'),
      applied: navivoxGatewayBoolField(json, 'applied'),
      profileId: navivoxStringFieldFromJson(json, 'profile_id'),
      root: navivoxStringFieldFromJson(json, 'root'),
      workspaceCount: navivoxIntFromJson(json['workspace_count']),
      draft: navivoxMapFieldFromJson(json, 'draft'),
      contact: navivoxMapFieldFromJson(json, 'contact'),
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
      profiles: navivoxGatewayObjectListWhereHasText(
        json['profiles'],
        NavivoxProfileRoute.fromJson,
        (profile) => profile.profileId,
      ),
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
    final profileId = navivoxStringFieldFromJson(json, 'profile_id');
    return NavivoxProfileRoute(
      profileId: profileId,
      displayName: navivoxGatewayStringFieldWithFallbackField(
        json,
        'display_name',
        'profile_id',
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
