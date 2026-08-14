class HermesDetachedRunLease {
  const HermesDetachedRunLease({
    required this.runId,
    required this.sessionId,
    required this.baseUrl,
    required this.createdAt,
    this.profileId,
  });

  factory HermesDetachedRunLease.fromJson(Map<String, Object?> json) {
    String requiredString(
      String name, {
      int maximumLength = 512,
      bool allowLegacyBlank = false,
    }) {
      final value = json[name];
      if (value is! String || (!allowLegacyBlank && value.trim().isEmpty)) {
        throw FormatException('Detached run $name is missing.');
      }
      final trimmed = value.trim();
      if (trimmed.length > maximumLength) {
        throw FormatException('Detached run $name is too long.');
      }
      return trimmed;
    }

    final createdAt = DateTime.tryParse(requiredString('created_at'))?.toUtc();
    if (createdAt == null) {
      throw const FormatException('Detached run created_at is invalid.');
    }
    String? profileId;
    if (json.containsKey('profile_id')) {
      final profileValue = json['profile_id'];
      if (profileValue is! String || profileValue.trim().isEmpty) {
        throw const FormatException('Detached run profile_id is invalid.');
      }
      profileId = profileValue.trim();
      if (profileId.length > 256) {
        throw const FormatException('Detached run profile_id is too long.');
      }
    }
    return HermesDetachedRunLease(
      runId: requiredString('run_id', maximumLength: 256),
      // Hermes Agent's historical run-start response omitted session_id. Wing
      // persisted a blank value before validating ownership. Keep that row
      // quarantined: without its session, Wing cannot safely reattach or delete
      // it, but it must not make the entire secure store unreadable.
      sessionId: requiredString(
        'session_id',
        maximumLength: 256,
        allowLegacyBlank: true,
      ),
      baseUrl: requiredString('base_url', maximumLength: 2048),
      profileId: profileId,
      createdAt: createdAt,
    );
  }

  final String runId;
  final String sessionId;
  final String baseUrl;
  final String? profileId;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'run_id': runId,
    'session_id': sessionId,
    'base_url': baseUrl,
    if (profileId != null) 'profile_id': profileId,
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}

abstract interface class HermesDetachedRunStore {
  /// Stable process-local identity for the underlying persistence slot.
  ///
  /// Separate store objects that read and write the same backing key must
  /// return equal values so predecessor and successor channels serialize.
  Object get coordinationKey;

  Future<List<HermesDetachedRunLease>> load();

  Future<void> save(List<HermesDetachedRunLease> leases);
}
