import '../../../core/channel/navivox_channel.dart';
import '../../../core/protocol/navivox_memory.dart';
import '../../../shared/presentation/profile_contact_labels.dart';

class MemoryDashboardPresentation {
  const MemoryDashboardPresentation();

  String get title => 'Memory';

  String get searchTitle => 'Search & Browse';

  String get searchFieldLabel => 'Search memories';

  String get searchUnavailableMessage =>
      'Gormes memory search API is unavailable.';

  String get emptySearchMessage => 'No memories found.';

  String get detailUnavailableMessage =>
      'Gormes memory detail API is unavailable.';

  String get correctionDialogTitle => 'Add correction';

  String get correctionFieldLabel => 'Correction note';

  String get correctionFieldHelperText =>
      'Adds a superseding note; raw source is preserved.';

  String get cancelLabel => 'Cancel';

  String get saveCorrectionLabel => 'Save correction';

  MemoryOverviewPresentation overviewFor(
    NavivoxMemoryOverview overview, {
    required NavivoxProfileContact? activeProfile,
  }) {
    final server = profileContactServerLabel(
      activeProfile,
      fallback: 'default',
    );
    final profile = profileContactDisplayLabel(
      activeProfile,
      fallback: overview.profileId,
    );
    final workspace = overview.workspaceId.trim();
    final lastUpdated = overview.lastUpdatedAt;
    return MemoryOverviewPresentation(
      healthLabel: overview.healthLabel,
      serverLabel: server,
      profileLabel: profile,
      workspaceLabel: workspace.isEmpty ? null : workspace,
      databaseLabel: overview.databaseLabel,
      lastUpdatedLabel: lastUpdated?.toUtc().toIso8601String(),
      degradedReason: overview.degradedReason,
      counts: [
        MemoryCountPresentation(label: 'Turns', count: overview.totalTurns),
        MemoryCountPresentation(
          label: 'Active memory items',
          count: overview.activeMemoryItems,
        ),
        MemoryCountPresentation(
          label: 'Observations',
          count: overview.observations,
        ),
        MemoryCountPresentation(
          label: 'Conclusions',
          count: overview.conclusions,
        ),
        MemoryCountPresentation(
          label: 'Session summaries',
          count: overview.sessionSummaries,
        ),
        MemoryCountPresentation(label: 'Entities', count: overview.entities),
        MemoryCountPresentation(
          label: 'Relationships',
          count: overview.relationships,
        ),
      ],
    );
  }

  MemoryItemPresentation itemFor(NavivoxMemoryItem item) {
    final metadata =
        [item.type.wireValue, item.status, item.sessionId, item.peerId]
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .join(' · ');
    return MemoryItemPresentation(
      keyValue: 'memory-item-${item.type.wireValue}-${item.id}',
      title: item.snippet,
      metadataLine: metadata.isEmpty ? null : metadata,
      tags: item.tags,
    );
  }

  MemoryDetailPresentation detailFor(NavivoxMemoryDetail item) {
    return MemoryDetailPresentation(
      title: 'Memory detail',
      content: item.content,
      rows: [
        MemoryDetailLinePresentation(label: 'Type', value: item.type.wireValue),
        MemoryDetailLinePresentation(label: 'Source', value: item.source),
        MemoryDetailLinePresentation(label: 'Session', value: item.sessionId),
        MemoryDetailLinePresentation(label: 'Peer', value: item.peerId),
        MemoryDetailLinePresentation(label: 'Status', value: item.status),
        MemoryDetailLinePresentation(label: 'Created', value: item.createdAt),
      ].where((row) => row.value.trim().isNotEmpty).toList(growable: false),
      provenance: item.provenance,
      linkedEntities: item.linkedEntities,
      linkedRelationships: item.linkedRelationships,
      actions: const [
        MemoryDetailActionPresentation(
          type: NavivoxMemoryActionType.pin,
          label: 'Pin',
        ),
        MemoryDetailActionPresentation(
          type: NavivoxMemoryActionType.archive,
          label: 'Archive',
        ),
        MemoryDetailActionPresentation(
          type: NavivoxMemoryActionType.markStale,
          label: 'Mark stale',
        ),
        MemoryDetailActionPresentation(
          type: NavivoxMemoryActionType.addCorrection,
          label: 'Add correction',
        ),
      ],
    );
  }

  MemoryErrorPresentation errorFor(
    NavivoxProfileContact? activeProfile, {
    required String message,
  }) {
    return MemoryErrorPresentation(
      title: 'Goncho degraded',
      profileLabel: profileContactDisplayLabel(
        activeProfile,
        fallback: 'default',
      ),
      message: message,
    );
  }

  String actionMessageFor(
    NavivoxMemoryActionResult result, {
    required NavivoxMemoryActionType requestedAction,
  }) {
    if (result.isDegraded) return result.degradedReason;
    if (result.message.trim().isEmpty) {
      return '${requestedAction.label} requested.';
    }
    return result.message;
  }
}

class MemoryOverviewPresentation {
  const MemoryOverviewPresentation({
    required this.healthLabel,
    required this.serverLabel,
    required this.profileLabel,
    required this.databaseLabel,
    required this.counts,
    this.workspaceLabel,
    this.lastUpdatedLabel,
    this.degradedReason = '',
  });

  final String healthLabel;
  final String serverLabel;
  final String profileLabel;
  final String? workspaceLabel;
  final String databaseLabel;
  final String? lastUpdatedLabel;
  final String degradedReason;
  final List<MemoryCountPresentation> counts;

  String get serverLine => 'Server: $serverLabel';

  String get profileLine => 'Profile: $profileLabel';

  String? get workspaceLine =>
      workspaceLabel == null ? null : 'Workspace: $workspaceLabel';

  String get databaseTitle => 'Database';

  String? get lastUpdatedLine =>
      lastUpdatedLabel == null ? null : 'Last updated: $lastUpdatedLabel';
}

class MemoryCountPresentation {
  const MemoryCountPresentation({required this.label, required this.count});

  final String label;
  final int count;
}

class MemoryItemPresentation {
  const MemoryItemPresentation({
    required this.keyValue,
    required this.title,
    required this.tags,
    this.metadataLine,
  });

  final String keyValue;
  final String title;
  final String? metadataLine;
  final List<String> tags;
}

class MemoryDetailPresentation {
  const MemoryDetailPresentation({
    required this.title,
    required this.content,
    required this.rows,
    required this.provenance,
    required this.linkedEntities,
    required this.linkedRelationships,
    required this.actions,
  });

  final String title;
  final String content;
  final List<MemoryDetailLinePresentation> rows;
  final String provenance;
  final List<String> linkedEntities;
  final List<String> linkedRelationships;
  final List<MemoryDetailActionPresentation> actions;

  String get provenanceTitle => 'Provenance';

  String get linkedEntitiesTitle => 'Linked entities';

  String get linkedRelationshipsTitle => 'Linked relationships';

  String get rawSourcePreservedLabel => 'Raw source preserved';
}

class MemoryDetailLinePresentation {
  const MemoryDetailLinePresentation({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  String get line => '$label: $value';
}

class MemoryDetailActionPresentation {
  const MemoryDetailActionPresentation({
    required this.type,
    required this.label,
  });

  final NavivoxMemoryActionType type;
  final String label;

  bool get requiresCorrection => type == NavivoxMemoryActionType.addCorrection;
}

class MemoryErrorPresentation {
  const MemoryErrorPresentation({
    required this.title,
    required this.profileLabel,
    required this.message,
  });

  final String title;
  final String profileLabel;
  final String message;

  String get profileLine => 'Profile: $profileLabel';
}
