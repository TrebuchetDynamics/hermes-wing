import '../../protocol/voice/models/wing_voice_run.dart';
import '../models/hermes_capabilities.dart';
import '../models/hermes_chat_turn.dart';
import '../models/hermes_health.dart';
import '../models/hermes_job.dart';
import '../models/hermes_model_assignment.dart';
import '../models/hermes_profile.dart';
import '../models/hermes_provider.dart';
import '../models/hermes_session.dart';
import '../models/hermes_skill.dart';

enum HermesConnectionStatus { disconnected, connecting, connected, error }

enum HermesOptionalResource { detailedHealth, models, skills, toolsets, jobs }

class HermesChannelState {
  const HermesChannelState({
    this.status = HermesConnectionStatus.disconnected,
    this.errorMessage,
    this.capabilities,
    this.detailedHealth,
    this.models = const [],
    this.skills = const [],
    this.skillDetails = const [],
    this.enabledToolsets = const [],
    this.jobs = const [],
    this.optionalResourceErrors = const {},
    this.sessions = const [],
    this.activeSessionId,
    this.profiles = const [],
    this.selectedProfileId,
    this.providers = const [],
    this.modelInventory,
    this.connectedBaseUrl,
    this.connectedWithApiKey = false,
    this.messages = const {},
    this.voiceRuns = const {},
    this.activeVoiceRunId,
  });

  final HermesConnectionStatus status;
  final String? errorMessage;
  final HermesCapabilityDocument? capabilities;
  final HermesHealthStatus? detailedHealth;
  final List<String> models;
  final List<String> skills;
  final List<HermesSkill> skillDetails;
  final List<String> enabledToolsets;
  final List<HermesJob> jobs;

  /// Advertised optional resources that failed to load. An absent resource is
  /// unsupported; an empty loaded list is available but empty.
  final Map<HermesOptionalResource, String> optionalResourceErrors;
  final List<HermesSession> sessions;
  final String? activeSessionId;

  /// Profiles ("agents") advertised by the connected endpoint. Refreshed by
  /// profile selection and after every profile mutation or 412 conflict.
  final List<HermesProfile> profiles;

  /// The client-selected profile. This is Hermes Wing-local state only: selecting
  /// a profile never mutates the Hermes CLI's active profile.
  final String? selectedProfileId;

  /// Providers and their write-only credential presence for the selected
  /// profile. Loaded on demand (never carries a raw key). Empty until the
  /// provider surface loads them.
  final List<HermesProvider> providers;

  /// The model catalog + active/auxiliary assignment for the selected profile,
  /// loaded on demand. Null until the model surface loads it.
  final HermesModelInventory? modelInventory;

  final String? connectedBaseUrl;
  final bool connectedWithApiKey;

  /// Scope-gating visibility hooks. These mirror the milestone-1 pattern
  /// (`supportsSchema` + advertised endpoint + granted scope) so surfaces can
  /// hide read/write affordances the connected token cannot use.
  bool get canReadDetailedHealth => _allowsEndpoint(
    'health_detailed',
    'GET',
    '/health/detailed',
    'gateway:read',
  );

  bool get canReadSkills => _advertisesEndpoint('skills', 'GET', '/v1/skills');

  bool get canReadToolsets =>
      _advertisesEndpoint('toolsets', 'GET', '/v1/toolsets');

  bool get canReadRuntimeModels =>
      _advertisesEndpoint('models', 'GET', '/v1/models');

  bool get canReadJobs =>
      _allowsEndpoint('jobs', 'GET', '/api/jobs', 'tasks:read');

  bool get canReadProfileSoul => _allowsEndpoint(
    'profile_soul',
    'GET',
    '/api/profiles/{name}/soul',
    'profiles:read',
  );

  bool get canReadProviders =>
      _allowsEndpoint('providers', 'GET', '/api/providers', 'providers:read');

  bool get canWriteProviders => _allowsEndpoint(
    'provider_credential_set',
    'PUT',
    '/api/providers/{slug}/credential',
    'providers:write',
  );

  bool get canReadModels =>
      _allowsEndpoint('models', 'GET', '/api/models', 'models:read');

  bool get canWriteModels => _allowsEndpoint(
    'models_assignment',
    'PUT',
    '/api/models/assignment',
    'models:write',
  );

  bool _advertisesEndpoint(String name, String method, String path) {
    final document = capabilities;
    return document != null &&
        document.supportsSchema &&
        document.advertisesEndpoint(name, method, path);
  }

  bool _allowsEndpoint(String name, String method, String path, String scope) {
    final document = capabilities;
    return document != null &&
        document.supportsSchema &&
        document.auth.allows(scope) &&
        document.advertisesScopedEndpoint(name, method, path, scope);
  }

  HermesProfile? get selectedProfile {
    final id = selectedProfileId;
    if (id == null) return null;
    for (final profile in profiles) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  /// Turns per session id, in arrival order.
  final Map<String, List<HermesChatTurn>> messages;
  final Map<String, WingVoiceRun> voiceRuns;
  final String? activeVoiceRunId;

  bool get isConnected => status == HermesConnectionStatus.connected;

  HermesSession? get activeSession {
    final id = activeSessionId;
    if (id == null) return null;
    for (final session in sessions) {
      if (session.id == id) return session;
    }
    return null;
  }

  List<HermesChatTurn> get activeMessages =>
      messages[activeSessionId] ?? const [];

  WingVoiceRun? get activeVoiceRun {
    final id = activeVoiceRunId;
    if (id == null) return null;
    final run = voiceRuns[id];
    if (run == null || run.isTerminal) return null;
    return run;
  }

  /// The most recent voice run regardless of status, for history/recovery
  /// copy. Prefers the tracked [activeVoiceRunId], else the last-inserted run.
  WingVoiceRun? get latestVoiceRun {
    final id = activeVoiceRunId;
    if (id != null) {
      final run = voiceRuns[id];
      if (run != null) return run;
    }
    if (voiceRuns.isEmpty) return null;
    return voiceRuns.values.last;
  }

  HermesChannelState copyWith({
    HermesConnectionStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
    HermesCapabilityDocument? capabilities,
    HermesHealthStatus? detailedHealth,
    bool clearDetailedHealth = false,
    List<String>? models,
    List<String>? skills,
    List<HermesSkill>? skillDetails,
    List<String>? enabledToolsets,
    List<HermesJob>? jobs,
    Map<HermesOptionalResource, String>? optionalResourceErrors,
    List<HermesSession>? sessions,
    String? activeSessionId,
    bool clearActiveSessionId = false,
    List<HermesProfile>? profiles,
    String? selectedProfileId,
    bool clearSelectedProfileId = false,
    List<HermesProvider>? providers,
    HermesModelInventory? modelInventory,
    String? connectedBaseUrl,
    bool clearConnectedBaseUrl = false,
    bool? connectedWithApiKey,
    Map<String, List<HermesChatTurn>>? messages,
    Map<String, WingVoiceRun>? voiceRuns,
    String? activeVoiceRunId,
    bool clearActiveVoiceRunId = false,
  }) {
    assert(
      !clearDetailedHealth || detailedHealth == null,
      'copyWith cannot set and clear detailedHealth at the same time.',
    );
    assert(
      !clearActiveSessionId || activeSessionId == null,
      'copyWith cannot set and clear activeSessionId at the same time.',
    );
    assert(
      !clearActiveVoiceRunId || activeVoiceRunId == null,
      'copyWith cannot set and clear activeVoiceRunId at the same time.',
    );
    assert(
      !clearSelectedProfileId || selectedProfileId == null,
      'copyWith cannot set and clear selectedProfileId at the same time.',
    );
    return HermesChannelState(
      status: status ?? this.status,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      capabilities: capabilities ?? this.capabilities,
      detailedHealth: clearDetailedHealth
          ? null
          : detailedHealth ?? this.detailedHealth,
      models: models ?? this.models,
      skills: skills ?? this.skills,
      skillDetails: skillDetails ?? this.skillDetails,
      enabledToolsets: enabledToolsets ?? this.enabledToolsets,
      jobs: jobs ?? this.jobs,
      optionalResourceErrors:
          optionalResourceErrors ?? this.optionalResourceErrors,
      sessions: sessions ?? this.sessions,
      activeSessionId: clearActiveSessionId
          ? null
          : activeSessionId ?? this.activeSessionId,
      profiles: profiles ?? this.profiles,
      selectedProfileId: clearSelectedProfileId
          ? null
          : selectedProfileId ?? this.selectedProfileId,
      providers: providers ?? this.providers,
      modelInventory: modelInventory ?? this.modelInventory,
      connectedBaseUrl: clearConnectedBaseUrl
          ? null
          : connectedBaseUrl ?? this.connectedBaseUrl,
      connectedWithApiKey: connectedWithApiKey ?? this.connectedWithApiKey,
      messages: messages ?? this.messages,
      voiceRuns: voiceRuns ?? this.voiceRuns,
      activeVoiceRunId: clearActiveVoiceRunId
          ? null
          : activeVoiceRunId ?? this.activeVoiceRunId,
    );
  }
}
