enum NavivoxMemoryHealth { active, degraded, unavailable }

enum NavivoxMemoryType {
  all('all', 'All'),
  turns('turns', 'Turns'),
  memoryItems('memory_items', 'Memory items'),
  observations('observations', 'Observations'),
  conclusions('conclusions', 'Conclusions'),
  sessionSummaries('session_summaries', 'Session summaries'),
  entities('entities', 'Entities'),
  relationships('relationships', 'Relationships');

  const NavivoxMemoryType(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static NavivoxMemoryType fromWire(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return all;
    for (final type in values) {
      if (type.wireValue == text) return type;
    }
    return all;
  }
}

enum NavivoxMemoryActionType {
  pin('pin', 'Pin'),
  unpin('unpin', 'Unpin'),
  archive('archive', 'Archive'),
  unarchive('unarchive', 'Unarchive'),
  markStale('mark_stale', 'Mark stale'),
  addCorrection('add_correction', 'Add correction');

  const NavivoxMemoryActionType(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static NavivoxMemoryActionType fromWire(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return archive;
    for (final type in values) {
      if (type.wireValue == text) return type;
    }
    return archive;
  }
}

class NavivoxMemorySearchResult {
  const NavivoxMemorySearchResult({
    required this.items,
    this.nextPageToken = '',
    this.degradedReason = '',
  });

  const NavivoxMemorySearchResult.degraded({required String reason})
    : items = const [],
      nextPageToken = '',
      degradedReason = reason;

  factory NavivoxMemorySearchResult.fromJson(Map<String, Object?> json) {
    final rawItems = json['items'];
    return NavivoxMemorySearchResult(
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (item) => NavivoxMemoryItem.fromJson(
                    Map<String, Object?>.from(item),
                  ),
                )
                .toList(growable: false)
          : const [],
      nextPageToken: _string(json['next_page_token'], fallback: ''),
      degradedReason: _string(
        json['degraded_reason'] ?? json['reason'],
        fallback: '',
      ),
    );
  }

  final List<NavivoxMemoryItem> items;
  final String nextPageToken;
  final String degradedReason;

  bool get isDegraded => degradedReason.trim().isNotEmpty;
}

class NavivoxMemoryItem {
  const NavivoxMemoryItem({
    required this.id,
    required this.type,
    required this.snippet,
    this.timestamp = '',
    this.sessionId = '',
    this.peerId = '',
    this.status = '',
    this.tags = const [],
    this.score,
  });

  factory NavivoxMemoryItem.fromJson(Map<String, Object?> json) {
    return NavivoxMemoryItem(
      id: _string(json['id'], fallback: ''),
      type: NavivoxMemoryType.fromWire(json['type']),
      snippet: _string(json['snippet'] ?? json['content'], fallback: ''),
      timestamp: _string(json['timestamp'] ?? json['created_at'], fallback: ''),
      sessionId: _string(
        json['session_id'] ?? json['session_key'],
        fallback: '',
      ),
      peerId: _string(json['peer_id'], fallback: ''),
      status: _string(json['status'], fallback: ''),
      tags: _stringList(json['tags']),
      score: _double(json['score']),
    );
  }

  final String id;
  final NavivoxMemoryType type;
  final String snippet;
  final String timestamp;
  final String sessionId;
  final String peerId;
  final String status;
  final List<String> tags;
  final double? score;
}

class NavivoxMemoryDetail {
  const NavivoxMemoryDetail({
    required this.id,
    required this.type,
    required this.content,
    this.source = '',
    this.sessionId = '',
    this.peerId = '',
    this.createdAt = '',
    this.updatedAt = '',
    this.status = '',
    this.tags = const [],
    this.provenance = '',
    this.linkedEntities = const [],
    this.linkedRelationships = const [],
    this.degradedReason = '',
  });

  const NavivoxMemoryDetail.degraded({required this.id, required String reason})
    : type = NavivoxMemoryType.all,
      content = '',
      source = '',
      sessionId = '',
      peerId = '',
      createdAt = '',
      updatedAt = '',
      status = '',
      tags = const [],
      provenance = '',
      linkedEntities = const [],
      linkedRelationships = const [],
      degradedReason = reason;

  factory NavivoxMemoryDetail.fromJson(Map<String, Object?> json) {
    return NavivoxMemoryDetail(
      id: _string(json['id'], fallback: ''),
      type: NavivoxMemoryType.fromWire(json['type']),
      content: _string(json['content'] ?? json['snippet'], fallback: ''),
      source: _string(json['source'] ?? json['source_table'], fallback: ''),
      sessionId: _string(
        json['session_id'] ?? json['session_key'],
        fallback: '',
      ),
      peerId: _string(json['peer_id'], fallback: ''),
      createdAt: _string(json['created_at'] ?? json['timestamp'], fallback: ''),
      updatedAt: _string(json['updated_at'], fallback: ''),
      status: _string(json['status'], fallback: ''),
      tags: _stringList(json['tags']),
      provenance: _string(json['provenance'], fallback: ''),
      linkedEntities: _stringList(json['linked_entities']),
      linkedRelationships: _stringList(json['linked_relationships']),
      degradedReason: _string(
        json['degraded_reason'] ?? json['reason'],
        fallback: '',
      ),
    );
  }

  final String id;
  final NavivoxMemoryType type;
  final String content;
  final String source;
  final String sessionId;
  final String peerId;
  final String createdAt;
  final String updatedAt;
  final String status;
  final List<String> tags;
  final String provenance;
  final List<String> linkedEntities;
  final List<String> linkedRelationships;
  final String degradedReason;

  bool get isDegraded => degradedReason.trim().isNotEmpty;
}

class NavivoxMemoryActionResult {
  const NavivoxMemoryActionResult({
    required this.accepted,
    required this.action,
    required this.message,
    this.rawSourcePreserved = true,
    this.degradedReason = '',
  });

  const NavivoxMemoryActionResult.degraded({
    required this.action,
    required String reason,
  }) : accepted = false,
       message = '',
       rawSourcePreserved = true,
       degradedReason = reason;

  factory NavivoxMemoryActionResult.fromJson(Map<String, Object?> json) {
    return NavivoxMemoryActionResult(
      accepted: _bool(json['accepted']),
      action: NavivoxMemoryActionType.fromWire(json['action']),
      message: _string(json['message'], fallback: ''),
      rawSourcePreserved: _bool(json['raw_source_preserved'], fallback: true),
      degradedReason: _string(
        json['degraded_reason'] ?? json['reason'],
        fallback: '',
      ),
    );
  }

  final bool accepted;
  final NavivoxMemoryActionType action;
  final String message;
  final bool rawSourcePreserved;
  final String degradedReason;

  bool get isDegraded => degradedReason.trim().isNotEmpty;
}

class NavivoxMemoryOverview {
  const NavivoxMemoryOverview({
    required this.profileId,
    required this.workspaceId,
    required this.databaseLabel,
    required this.health,
    required this.totalTurns,
    required this.activeMemoryItems,
    required this.observations,
    required this.conclusions,
    required this.sessionSummaries,
    required this.entities,
    required this.relationships,
    this.degradedReason = '',
    this.lastUpdatedAt,
  });

  const NavivoxMemoryOverview.degraded({
    required this.profileId,
    required String reason,
  }) : workspaceId = '',
       databaseLabel = 'redacted',
       health = NavivoxMemoryHealth.degraded,
       totalTurns = 0,
       activeMemoryItems = 0,
       observations = 0,
       conclusions = 0,
       sessionSummaries = 0,
       entities = 0,
       relationships = 0,
       degradedReason = reason,
       lastUpdatedAt = null;

  factory NavivoxMemoryOverview.fromJson(Map<String, Object?> json) {
    final counts = json['counts'];
    final countMap = counts is Map ? Map<String, Object?>.from(counts) : json;
    final healthText = json['health']?.toString().trim().toLowerCase();
    final health = switch (healthText) {
      'active' || 'ok' || 'healthy' => NavivoxMemoryHealth.active,
      'unavailable' || 'offline' => NavivoxMemoryHealth.unavailable,
      _ => NavivoxMemoryHealth.degraded,
    };

    return NavivoxMemoryOverview(
      profileId: _string(json['profile_id'], fallback: 'default'),
      workspaceId: _string(json['workspace_id'], fallback: ''),
      databaseLabel: _safeDatabaseLabel(
        json['database_label'] ?? json['database_path'],
      ),
      health: health,
      totalTurns: _int(countMap['turns'] ?? countMap['total_turns']),
      activeMemoryItems: _int(
        countMap['memory_items'] ?? countMap['active_memory_items'],
      ),
      observations: _int(countMap['observations']),
      conclusions: _int(countMap['conclusions']),
      sessionSummaries: _int(countMap['session_summaries']),
      entities: _int(countMap['entities']),
      relationships: _int(countMap['relationships']),
      degradedReason: _string(
        json['degraded_reason'] ?? json['reason'],
        fallback: '',
      ),
      lastUpdatedAt: _dateTime(json['last_updated_at']),
    );
  }

  final String profileId;
  final String workspaceId;
  final String databaseLabel;
  final NavivoxMemoryHealth health;
  final int totalTurns;
  final int activeMemoryItems;
  final int observations;
  final int conclusions;
  final int sessionSummaries;
  final int entities;
  final int relationships;
  final String degradedReason;
  final DateTime? lastUpdatedAt;

  bool get isActive => health == NavivoxMemoryHealth.active;

  String get healthLabel => switch (health) {
    NavivoxMemoryHealth.active => 'Goncho active',
    NavivoxMemoryHealth.degraded => 'Goncho degraded',
    NavivoxMemoryHealth.unavailable => 'Goncho unavailable',
  };
}

String _string(Object? value, {required String fallback}) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return fallback;
  return text;
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _double(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

bool _bool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  final text = value?.toString().trim().toLowerCase();
  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;
  return fallback;
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

DateTime? _dateTime(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text);
}

String _safeDatabaseLabel(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return 'redacted';

  const gormesMarker = '/.gormes/';
  final markerIndex = text.indexOf(gormesMarker);
  if (markerIndex >= 0) {
    return '~/.gormes/${text.substring(markerIndex + gormesMarker.length)}';
  }
  if (text.startsWith('/')) {
    final parts = text.split('/').where((part) => part.isNotEmpty).toList();
    final basename = parts.isEmpty ? 'memory.db' : parts.last;
    return 'redacted/$basename';
  }
  return text;
}
