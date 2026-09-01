// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/client/hermes_api_client.dart';
import '../../../core/hermes/client/hermes_api_config.dart';
import '../../../core/hermes/models/hermes_session.dart';
import '../../../core/hermes/setup/hermes_endpoint_store.dart';
import '../../../core/wing_link/wing_link_client.dart';
import 'gateway_contact.dart';
import 'gateway_contact_cache.dart';

class GatewaySummary {
  const GatewaySummary({
    required this.profiles,
    required this.sessionsByProfile,
    this.unscopedSessions = const [],
    this.profileContextAvailable = false,
  });

  final List<HermesProfile> profiles;
  final Map<String, List<HermesSession>> sessionsByProfile;
  final List<HermesSession> unscopedSessions;
  final bool profileContextAvailable;
}

typedef GatewayPeriodicTimerFactory =
    Timer Function(Duration duration, void Function(Timer) callback);

abstract interface class GatewaySummaryLoader {
  Future<GatewaySummary> load(HermesEndpointConfig config);
}

typedef PendingWingLinkCredentialRecovery =
    Future<bool> Function(HermesEndpointConfig config);

class HermesApiGatewaySummaryLoader implements GatewaySummaryLoader {
  const HermesApiGatewaySummaryLoader({this.clientBuilder});

  final HermesApiClient Function(HermesApiConfig config)? clientBuilder;

  @override
  Future<GatewaySummary> load(HermesEndpointConfig config) async {
    final apiConfig = HermesApiConfig.fromBaseUrl(
      config.baseUrl,
      apiKey: config.apiKey,
    );
    final client =
        clientBuilder?.call(apiConfig) ?? HermesApiClient(config: apiConfig);
    await client.health();
    final capabilities = await client.capabilities();
    final supportsProfileContext =
        capabilities.supportsSchema &&
        capabilities.profileContext.isSupportedQueryContext;
    final profileEndpoint = capabilities.endpoints['profiles'];
    final supportsProfiles =
        supportsProfileContext &&
        profileEndpoint != null &&
        capabilities.auth.allows('profiles:read') &&
        profileEndpoint.requiredScopes.every(capabilities.auth.allows) &&
        capabilities.advertisesScopedEndpoint(
          'profiles',
          'GET',
          '/api/profiles',
          'profiles:read',
        );
    if (!supportsProfiles) {
      return GatewaySummary(
        profiles: const [],
        sessionsByProfile: const {},
        unscopedSessions: await client.listSessions(
          profile: supportsProfileContext
              ? capabilities.profileContext.defaultProfileId
              : null,
        ),
        profileContextAvailable: supportsProfileContext,
      );
    }
    final profiles = await client.listProfiles();
    return GatewaySummary(
      profiles: profiles,
      profileContextAvailable: true,
      sessionsByProfile: {
        for (final profile in profiles)
          profile.id: await client.listSessions(profile: profile.id),
      },
    );
  }
}

class HermesGatewayDirectory extends ChangeNotifier
    with WidgetsBindingObserver {
  HermesGatewayDirectory({
    required HermesEndpointStore store,
    required GatewayContactCache cache,
    required GatewaySummaryLoader loader,
    required HermesChannel activeChannel,
    DateTime Function()? now,
    GatewayPeriodicTimerFactory? periodicTimer,
    PendingWingLinkCredentialRecovery? pendingCredentialRecovery,
    this.maxConcurrent = 3,
  }) : assert(maxConcurrent > 0),
       _store = store,
       _cache = cache,
       _loader = loader,
       _activeChannel = activeChannel,
       _now = now ?? DateTime.now,
       _periodicTimer = periodicTimer ?? Timer.periodic,
       _pendingCredentialRecovery =
           pendingCredentialRecovery ?? _verifyAndAcknowledgePendingCredential;

  final HermesEndpointStore _store;
  final GatewayContactCache _cache;
  final GatewaySummaryLoader _loader;
  final HermesChannel _activeChannel;
  final DateTime Function() _now;
  final GatewayPeriodicTimerFactory _periodicTimer;
  final PendingWingLinkCredentialRecovery _pendingCredentialRecovery;
  final int maxConcurrent;
  final Map<String, HermesEndpointConfig> _configsById = {};
  final Map<String, int> _gatewayRefreshGenerations = {};
  List<GatewayContact> _contacts = const [];
  List<GatewayOverview> _gateways = const [];
  GatewayContactId? _activeContactId;
  bool _refreshing = false;
  bool _started = false;
  int _refreshGeneration = 0;
  int _activationGeneration = 0;
  Future<void> _profileSelectionTail = Future.value();
  Future<void> _selectionPersistenceTail = Future.value();
  bool _observingActiveChannel = false;
  Timer? _foregroundTimer;

  List<GatewayContact> get contacts => List.unmodifiable(_contacts);
  List<GatewayOverview> get gateways => List.unmodifiable(_gateways);
  GatewayContactId? get activeContactId => _activeContactId;
  GatewayContact? get activeContact {
    final id = _activeContactId;
    if (id == null) return null;
    for (final contact in _contacts) {
      if (contact.id == id) return contact;
    }
    return null;
  }

  bool get refreshing => _refreshing;
  bool get hasSavedGateways => _configsById.isNotEmpty;

  HermesEndpointConfig? get activeGatewayConfig {
    final gatewayId = _activeContactId?.gatewayId;
    return gatewayId == null ? null : _configsById[gatewayId];
  }

  HermesEndpointConfig? configForGateway(String gatewayId) =>
      _configsById[gatewayId];

  /// Resolves an independently enrolled endpoint for a profile managed by the
  /// selected gateway's Wing Link inventory. Inventory membership alone is not
  /// enrollment: the endpoint must have its own saved bearer credential and
  /// exact `/p/<profile>` routing on the same reviewed authorities.
  String? enrolledGatewayIdForManagedProfile({
    required String sourceGatewayId,
    required String profileId,
  }) {
    final source = _configsById[sourceGatewayId];
    final sourceHermes = Uri.tryParse(source?.baseUrl ?? '');
    final sourceWingLink = Uri.tryParse(source?.wingLinkOrigin ?? '');
    if (source == null ||
        sourceHermes == null ||
        sourceWingLink == null ||
        profileId.trim() != profileId ||
        profileId.isEmpty) {
      return null;
    }
    final sourceFingerprint = source.wingLinkHostFingerprint?.trim() ?? '';
    final requiresPinnedWingLink = sourceWingLink.scheme == 'https';
    if (requiresPinnedWingLink && sourceFingerprint.isEmpty) return null;
    for (final entry in _configsById.entries) {
      final candidate = entry.value;
      final credential = candidate.apiKey?.trim() ?? '';
      final candidateHermes = Uri.tryParse(candidate.baseUrl);
      final candidateWingLink = Uri.tryParse(candidate.wingLinkOrigin ?? '');
      if (credential.isEmpty ||
          candidateHermes == null ||
          candidateWingLink == null ||
          candidateHermes.scheme != sourceHermes.scheme ||
          candidateHermes.host.toLowerCase() !=
              sourceHermes.host.toLowerCase() ||
          candidateHermes.port != sourceHermes.port ||
          candidateWingLink.scheme != sourceWingLink.scheme ||
          candidateWingLink.host.toLowerCase() !=
              sourceWingLink.host.toLowerCase() ||
          candidateWingLink.port != sourceWingLink.port ||
          (requiresPinnedWingLink &&
              (candidate.wingLinkHostFingerprint?.trim() ?? '') !=
                  sourceFingerprint)) {
        continue;
      }
      final segments = candidateHermes.pathSegments
          .where((segment) => segment.isNotEmpty)
          .toList(growable: false);
      if (segments.length == 2 &&
          segments.first == 'p' &&
          segments.last == profileId) {
        return entry.key;
      }
      if (profileId == 'default' &&
          entry.key == sourceGatewayId &&
          segments.isEmpty) {
        return entry.key;
      }
    }
    return null;
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _activeChannel.addListener(_onActiveChannelChanged);
    _observingActiveChannel = true;
    final rememberedSelection = await _cache.loadSelection();
    _contacts = await _cache.load();
    notifyListeners();
    await refresh();
    if (rememberedSelection != null &&
        _contacts.any(
          (contact) =>
              contact.id == rememberedSelection.contactId &&
              contact.chatAvailable,
        )) {
      try {
        await activate(
          rememberedSelection.contactId,
          preferredSessionId: rememberedSelection.sessionId,
        );
      } catch (_) {
        // Keep the directory usable when a remembered endpoint is offline.
      }
    }
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      _startForegroundRefresh();
    }
  }

  Future<void> refresh() async {
    final generation = ++_refreshGeneration;
    _refreshing = true;
    notifyListeners();
    List<HermesEndpointConfig> configs;
    try {
      configs = await _store.loadProfiles();
    } catch (_) {
      // Saved gateways are unreadable, so report every known gateway as
      // unreachable instead of stranding the directory mid-refresh.
      if (generation != _refreshGeneration) return;
      _refreshing = false;
      _markEverythingOffline();
      notifyListeners();
      return;
    }
    if (generation != _refreshGeneration) return;
    configs = await _recoverPendingWingLinkCredentials(configs);
    if (generation != _refreshGeneration) return;

    _configsById
      ..clear()
      ..addEntries(
        configs.map((config) => MapEntry(config.id ?? config.baseUrl, config)),
      );
    final now = _now().toUtc();
    _gateways = [
      for (final config in configs)
        GatewayOverview(
          id: config.id ?? config.baseUrl,
          label: config.displayLabel,
          baseUrl: config.baseUrl,
          availability: GatewayAvailability.refreshing,
          lastRefreshedAt: now,
        ),
    ];
    final savedIds = _configsById.keys.toSet();
    _contacts = sortGatewayContacts(
      _contacts
          .where((contact) => savedIds.contains(contact.id.gatewayId))
          .map(
            (contact) =>
                contact.copyWith(availability: GatewayAvailability.refreshing),
          ),
    );
    notifyListeners();

    var nextIndex = 0;
    Future<void> worker() async {
      while (nextIndex < configs.length) {
        final index = nextIndex++;
        await _refreshGateway(configs[index], generation);
      }
    }

    await Future.wait(
      List.generate(min(maxConcurrent, configs.length), (_) => worker()),
    );
    if (generation != _refreshGeneration) return;
    _refreshing = false;
    await _saveContacts();
    notifyListeners();
  }

  Future<List<HermesEndpointConfig>> _recoverPendingWingLinkCredentials(
    List<HermesEndpointConfig> configs,
  ) async {
    final recovered = [...configs];
    final groups = <(String, String, String), List<int>>{};
    for (var index = 0; index < configs.length; index++) {
      final config = configs[index];
      final origin = Uri.tryParse(config.wingLinkOrigin ?? '');
      final controlToken = config.wingLinkToken ?? '';
      final credentialId = config.wingLinkPendingCredentialId ?? '';
      if (origin == null ||
          origin.host.isEmpty ||
          controlToken.isEmpty ||
          credentialId.isEmpty) {
        continue;
      }
      groups
          .putIfAbsent((
            origin.toString(),
            controlToken,
            credentialId,
          ), () => <int>[])
          .add(index);
    }

    for (final entry in groups.entries) {
      try {
        if (!await _pendingCredentialRecovery(configs[entry.value.first])) {
          continue;
        }
        for (final index in entry.value) {
          final config = configs[index];
          recovered[index] = HermesEndpointConfig(
            id: config.id,
            baseUrl: config.baseUrl,
            apiKey: config.apiKey,
            label: config.label,
            wingLinkOrigin: config.wingLinkOrigin,
            wingLinkToken: config.wingLinkToken,
            wingLinkPendingCredentialId: '',
            wingLinkHostFingerprint: config.wingLinkHostFingerprint,
            wingLinkDeviceId: config.wingLinkDeviceId,
          );
        }
        await _store.saveAll(recovered);
      } catch (_) {
        // Leave every securely stored bundle member pending for a later refresh.
      }
    }
    return recovered;
  }

  static Future<bool> _verifyAndAcknowledgePendingCredential(
    HermesEndpointConfig config,
  ) async {
    final origin = Uri.parse(config.wingLinkOrigin!);
    await HermesApiClient(
      config: HermesApiConfig.fromBaseUrl(
        config.baseUrl,
        apiKey: config.apiKey,
      ),
    ).health();
    final client = WingLinkClient(
      origin: origin,
      token: config.wingLinkToken!,
      hostFingerprint: config.wingLinkHostFingerprint,
    );
    await client.verifyPendingCredential();
    await client.acknowledgeCredential(config.wingLinkPendingCredentialId!);
    return true;
  }

  /// The contact cache is a best-effort local convenience that every refresh
  /// rebuilds, so a failed write must never break the operation that triggered
  /// it or strand callers that discard this future.
  Future<void> _saveContacts() async {
    try {
      await _cache.save(_contacts);
    } catch (_) {
      // Intentionally ignored; authoritative state lives on the gateway.
    }
  }

  void _markEverythingOffline() {
    _contacts = sortGatewayContacts(
      _contacts.map(
        (contact) =>
            contact.copyWith(availability: GatewayAvailability.offline),
      ),
    );
    _gateways = [
      for (final gateway in _gateways)
        GatewayOverview(
          id: gateway.id,
          label: gateway.label,
          baseUrl: gateway.baseUrl,
          availability: GatewayAvailability.offline,
          lastRefreshedAt: gateway.lastRefreshedAt,
        ),
    ];
  }

  Future<void> _refreshGateway(
    HermesEndpointConfig config,
    int generation,
  ) async {
    final gatewayId = config.id ?? config.baseUrl;
    final gatewayGeneration = (_gatewayRefreshGenerations[gatewayId] ?? 0) + 1;
    _gatewayRefreshGenerations[gatewayId] = gatewayGeneration;
    bool isCurrent() =>
        generation == _refreshGeneration &&
        identical(_configsById[gatewayId], config) &&
        _gatewayRefreshGenerations[gatewayId] == gatewayGeneration;
    try {
      final summary = await _loader.load(config);
      if (!isCurrent()) return;
      final refreshedAt = _now().toUtc();
      final apiProfiles = {
        for (final profile in summary.profiles) profile.id: profile,
      };
      final endpointProfileId = _profileIdFromEndpoint(config.baseUrl);
      final profileIds = endpointProfileId == null
          ? apiProfiles.keys
          : apiProfiles.containsKey(endpointProfileId)
          ? [endpointProfileId]
          : const <String>[];
      final projected = profileIds.isEmpty
          ? [
              GatewayContact(
                id: GatewayContactId(
                  gatewayId: gatewayId,
                  profileId: endpointProfileId ?? 'default',
                ),
                gatewayLabel: _gatewayLabelForProfile(
                  config.displayLabel,
                  endpointProfileId,
                ),
                profileName: endpointProfileId ?? 'Endpoint contact',
                latestSession: _latestSession(summary.unscopedSessions),
                sessionCount: summary.unscopedSessions.length,
                availability: GatewayAvailability.online,
                lastRefreshedAt: refreshedAt,
                isFallbackProfile: true,
              ),
            ]
          : [
              for (final profileId in profileIds)
                GatewayContact(
                  id: GatewayContactId(
                    gatewayId: gatewayId,
                    profileId: profileId,
                  ),
                  gatewayLabel: _gatewayLabelForProfile(
                    config.displayLabel,
                    endpointProfileId,
                  ),
                  profileName:
                      apiProfiles[profileId]?.displayName ??
                      (profileId == 'default' ? 'Default profile' : profileId),
                  latestSession: _latestSession(
                    summary.sessionsByProfile[profileId] ??
                        (profileId == 'default'
                            ? summary.unscopedSessions
                            : const []),
                  ),
                  sessionCount:
                      summary.sessionsByProfile[profileId]?.length ??
                      (profileId == 'default'
                          ? summary.unscopedSessions.length
                          : 0),
                  availability: GatewayAvailability.online,
                  lastRefreshedAt: refreshedAt,
                  isFallbackProfile:
                      endpointProfileId != null ||
                      (profileId == 'default' &&
                          !summary.profileContextAvailable),
                  chatAvailable:
                      endpointProfileId != null ||
                      profileId == 'default' ||
                      summary.profileContextAvailable,
                ),
            ];
      _replaceGatewayContacts(gatewayId, projected);
      _replaceGatewayOverview(config, GatewayAvailability.online, refreshedAt);
    } catch (error) {
      if (!isCurrent()) return;
      final message = error.toString();
      final availability =
          message.contains('HTTP 401') || message.contains('HTTP 403')
          ? GatewayAvailability.authenticationFailed
          : GatewayAvailability.offline;
      _contacts = sortGatewayContacts([
        for (final contact in _contacts)
          contact.id.gatewayId == gatewayId
              ? contact.copyWith(availability: availability)
              : contact,
      ]);
      _replaceGatewayOverview(config, availability, _now().toUtc());
    }
    notifyListeners();
  }

  void _replaceGatewayContacts(
    String gatewayId,
    List<GatewayContact> replacement,
  ) {
    _contacts = sortGatewayContacts([
      for (final contact in _contacts)
        if (contact.id.gatewayId != gatewayId) contact,
      ...replacement,
    ]);
  }

  void _replaceGatewayOverview(
    HermesEndpointConfig config,
    GatewayAvailability availability,
    DateTime refreshedAt,
  ) {
    final gatewayId = config.id ?? config.baseUrl;
    _gateways = [
      for (final gateway in _gateways)
        if (gateway.id != gatewayId) gateway,
      GatewayOverview(
        id: gatewayId,
        label: config.displayLabel,
        baseUrl: config.baseUrl,
        availability: availability,
        lastRefreshedAt: refreshedAt,
      ),
    ];
  }

  HermesSession? _latestSession(List<HermesSession> sessions) {
    HermesSession? latest;
    DateTime? latestAt;
    for (final session in sessions) {
      final activity = DateTime.tryParse(session.lastActive ?? '')?.toUtc();
      if (latest == null ||
          (activity != null &&
              (latestAt == null || activity.isAfter(latestAt)))) {
        latest = session;
        latestAt = activity;
      }
    }
    return latest;
  }

  Future<void> reload({GatewayContactId? activate}) async {
    await refresh();
    if (activate != null &&
        _contacts.any((contact) => contact.id == activate)) {
      await this.activate(activate);
    }
  }

  Future<void> renameGateway(String gatewayId, String? label) async {
    final config = _configsById[gatewayId];
    if (config == null) throw StateError('Gateway is no longer saved.');
    final trimmed = label?.trim();
    final normalizedLabel = trimmed == null || trimmed.isEmpty ? null : trimmed;
    await _store.save(
      baseUrl: config.baseUrl,
      apiKey: config.apiKey,
      label: normalizedLabel,
      profileId: gatewayId,
      wingLinkOrigin: config.wingLinkOrigin,
      wingLinkToken: config.wingLinkToken,
      wingLinkPendingCredentialId: config.wingLinkPendingCredentialId,
      wingLinkHostFingerprint: config.wingLinkHostFingerprint,
      wingLinkDeviceId: config.wingLinkDeviceId,
    );
    final displayLabel = normalizedLabel ?? config.baseUrl;
    _configsById[gatewayId] = HermesEndpointConfig(
      id: gatewayId,
      label: normalizedLabel,
      baseUrl: config.baseUrl,
      apiKey: config.apiKey,
      wingLinkOrigin: config.wingLinkOrigin,
      wingLinkToken: config.wingLinkToken,
      wingLinkPendingCredentialId: config.wingLinkPendingCredentialId,
      wingLinkHostFingerprint: config.wingLinkHostFingerprint,
      wingLinkDeviceId: config.wingLinkDeviceId,
    );
    _contacts = sortGatewayContacts([
      for (final contact in _contacts)
        contact.id.gatewayId == gatewayId
            ? contact.copyWith(gatewayLabel: displayLabel)
            : contact,
    ]);
    _gateways = [
      for (final gateway in _gateways)
        gateway.id == gatewayId
            ? GatewayOverview(
                id: gateway.id,
                label: displayLabel,
                baseUrl: gateway.baseUrl,
                availability: gateway.availability,
                lastRefreshedAt: gateway.lastRefreshedAt,
              )
            : gateway,
    ];
    await _saveContacts();
    notifyListeners();
  }

  Future<void> updateGatewayConnection(
    String gatewayId, {
    required String baseUrl,
    String? apiKey,
    bool clearApiKey = false,
  }) async {
    final config = _configsById[gatewayId];
    if (config == null) throw StateError('Gateway is no longer saved.');
    if (_activeContactId?.gatewayId == gatewayId) {
      throw StateError(
        'Disconnect this gateway before updating its connection.',
      );
    }
    final normalizedBaseUrl = hermesPublicEndpointBaseUrl(baseUrl);
    HermesApiConfig.fromBaseUrl(normalizedBaseUrl);
    if (_configsById.entries.any(
      (entry) =>
          entry.key != gatewayId && entry.value.baseUrl == normalizedBaseUrl,
    )) {
      throw StateError('Another saved gateway already uses this URL.');
    }
    final replacementApiKey = clearApiKey
        ? null
        : apiKey?.trim().isNotEmpty == true
        ? apiKey!.trim()
        : config.apiKey;
    final replacement = HermesEndpointConfig(
      id: gatewayId,
      label: config.label,
      baseUrl: normalizedBaseUrl,
      apiKey: replacementApiKey,
    );
    await _store.save(
      baseUrl: replacement.baseUrl,
      apiKey: replacement.apiKey,
      label: replacement.label,
      profileId: gatewayId,
    );
    _configsById[gatewayId] = replacement;
    final refreshedAt = _now().toUtc();
    _contacts = sortGatewayContacts([
      for (final contact in _contacts)
        contact.id.gatewayId == gatewayId
            ? contact.copyWith(
                availability: GatewayAvailability.refreshing,
                lastRefreshedAt: refreshedAt,
              )
            : contact,
    ]);
    _replaceGatewayOverview(
      replacement,
      GatewayAvailability.refreshing,
      refreshedAt,
    );
    notifyListeners();
    await _refreshGateway(replacement, _refreshGeneration);
    await _saveContacts();
  }

  Future<void> reconnectGateway(String gatewayId) async {
    final config = _configsById[gatewayId];
    if (config == null) throw StateError('Gateway is no longer saved.');
    await _refreshGateway(config, _refreshGeneration);
    await _saveContacts();
  }

  Future<void> activateGateway(String gatewayId) async {
    GatewayContact? target;
    for (final contact in _contacts) {
      if (contact.id.gatewayId != gatewayId) continue;
      target ??= contact;
      if (contact.id.profileId == 'default') {
        target = contact;
        break;
      }
    }
    if (target == null) {
      await reconnectGateway(gatewayId);
      target = _contacts
          .where((contact) => contact.id.gatewayId == gatewayId)
          .firstOrNull;
    }
    if (target == null) throw StateError('Gateway has no available profiles.');
    await activate(target.id);
  }

  Future<void> selectProfileOnActiveGateway(
    String profileId, {
    HermesProfile? discoveredProfile,
  }) async {
    final predecessor = _profileSelectionTail;
    final release = Completer<void>();
    _profileSelectionTail = release.future;
    await predecessor;
    try {
      final currentId = _activeContactId;
      if (currentId == null) {
        throw StateError('Select a gateway before selecting a profile.');
      }
      if (_activeChannel.state.hasStreamingSessions) {
        throw StateError('Stop active replies before switching profiles.');
      }
      final nativeProfile = _activeChannel.state.profiles
          .where((profile) => profile.id == profileId)
          .firstOrNull;
      final profile =
          nativeProfile ??
          (discoveredProfile?.id == profileId ? discoveredProfile : null);
      if (profile == null) {
        throw StateError('Hermes profile "$profileId" is not available.');
      }

      final generation = _activationGeneration;
      await _activeChannel.selectProfile(
        profileId,
        allowDiscovered: nativeProfile == null,
      );
      _requireCurrentProfileSelection(generation, currentId, profileId);
      final targetId = GatewayContactId(
        gatewayId: currentId.gatewayId,
        profileId: profileId,
      );
      if (!_contacts.any((contact) => contact.id == targetId)) {
        final gatewayLabel = _contacts
            .where((contact) => contact.id.gatewayId == currentId.gatewayId)
            .map((contact) => contact.gatewayLabel)
            .firstOrNull;
        final sessions = _activeChannel.state.sessions;
        _contacts = sortGatewayContacts([
          ..._contacts,
          GatewayContact(
            id: targetId,
            gatewayLabel: gatewayLabel ?? currentId.gatewayId,
            profileName: profile.displayName.isEmpty
                ? profile.id
                : profile.displayName,
            latestSession: sessions.firstOrNull,
            sessionCount: sessions.length,
            availability: GatewayAvailability.online,
            lastRefreshedAt: _now().toUtc(),
          ),
        ]);
        await _saveContacts();
        _requireCurrentProfileSelection(generation, currentId, profileId);
      }
      _activeContactId = targetId;
      await _rememberActiveSelection();
      notifyListeners();
    } finally {
      release.complete();
    }
  }

  void _requireCurrentProfileSelection(
    int generation,
    GatewayContactId expectedContact,
    String profileId,
  ) {
    if (generation != _activationGeneration ||
        _activeContactId != expectedContact ||
        _activeChannel.state.selectedProfileId != profileId) {
      throw StateError(
        'The active gateway changed while selecting the profile.',
      );
    }
  }

  Future<void> removeGateway(String gatewayId) async {
    if (_activeContactId?.gatewayId == gatewayId) await showDirectory();
    await _store.deleteProfile(gatewayId);
    _configsById.remove(gatewayId);
    try {
      await _cache.removeGateway(gatewayId);
    } catch (_) {
      // The authoritative delete already succeeded; stale cache rows are
      // dropped by the next refresh.
    }
    _contacts = sortGatewayContacts(
      _contacts.where((contact) => contact.id.gatewayId != gatewayId),
    );
    _gateways = [
      for (final gateway in _gateways)
        if (gateway.id != gatewayId) gateway,
    ];
    notifyListeners();
  }

  Future<void> activate(
    GatewayContactId id, {
    String? preferredSessionId,
  }) async {
    final contact = _contacts.firstWhere((item) => item.id == id);
    if (!contact.chatAvailable) {
      throw StateError('This Hermes profile is not available for chat.');
    }
    final config = _configsById[id.gatewayId];
    if (config == null) throw StateError('Gateway is no longer saved.');
    final generation = ++_activationGeneration;

    if (_activeContactId != null) await _activeChannel.disconnect();
    if (generation != _activationGeneration) return;
    _activeContactId = id;
    notifyListeners();

    void clearFailedActivation() {
      if (generation == _activationGeneration && _activeContactId == id) {
        _activeContactId = null;
        notifyListeners();
      }
    }

    try {
      await _activeChannel.connect(
        baseUrl: config.baseUrl,
        apiKey: config.apiKey,
      );
      if (generation != _activationGeneration) return;
      if (!_activeChannel.state.isConnected) {
        clearFailedActivation();
        return;
      }
      if (!contact.isFallbackProfile) {
        await _activeChannel.selectProfile(
          contact.id.profileId,
          allowDiscovered: true,
        );
      }
      if (generation != _activationGeneration) return;

      final resolvedPreferredSessionId =
          preferredSessionId != null &&
              _activeChannel.state.sessions.any(
                (session) => session.id == preferredSessionId,
              )
          ? preferredSessionId
          : null;
      final sessionId = resolvedPreferredSessionId ?? contact.latestSession?.id;
      final session = sessionId == null
          ? null
          : _activeChannel.state.sessions
                .where((candidate) => candidate.id == sessionId)
                .firstOrNull;
      if (resolvedPreferredSessionId == null && session?.source == 'telegram') {
        if (_activeChannel.state.canCreateSessions) {
          await _activeChannel.createSession();
          if (generation != _activationGeneration) return;
        } else {
          // Keep Telegram history discoverable without presenting its active
          // conversation as the current Wing chat.
          _activeChannel.clearActiveSession();
        }
      } else if (sessionId == null) {
        // Opening a profile is an explicit chat action; give it a writable
        // session when it has no prior session at all.
        if (_activeChannel.state.canCreateSessions) {
          await _activeChannel.createSession();
          if (generation != _activationGeneration) return;
        }
      } else if (session != null) {
        try {
          await _activeChannel.selectSession(session.id);
        } catch (_) {
          // A stale or slow session preview must not block a healthy gateway.
        }
      }
      await _rememberActiveSelection();
    } catch (_) {
      clearFailedActivation();
      rethrow;
    }
  }

  Future<void> showDirectory() async {
    ++_activationGeneration;
    await _activeChannel.disconnect();
    _activeContactId = null;
    await _clearRememberedSelection();
    notifyListeners();
  }

  Future<void> _rememberActiveSelection() async {
    final contactId = _activeContactId;
    if (contactId == null) return;
    final selection = GatewayContactSelection(
      contactId: contactId,
      sessionId: _activeChannel.state.activeSession?.id,
    );
    final operation = _selectionPersistenceTail.then(
      (_) => _cache.saveSelection(selection),
    );
    _selectionPersistenceTail = operation.catchError((Object _) {});
    try {
      await operation;
    } catch (_) {
      // A failed local preference write must not break a healthy chat.
    }
  }

  Future<void> _clearRememberedSelection() async {
    final operation = _selectionPersistenceTail.then(
      (_) => _cache.clearSelection(),
    );
    _selectionPersistenceTail = operation.catchError((Object _) {});
    try {
      await operation;
    } catch (_) {
      // Selection persistence is a convenience, not a navigation dependency.
    }
  }

  void _onActiveChannelChanged() {
    if (_activeContactId == null ||
        !_activeChannel.state.isConnected ||
        _activeChannel.state.activeSession == null) {
      return;
    }
    unawaited(_rememberActiveSelection());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startForegroundRefresh();
      unawaited(refresh());
    } else {
      _foregroundTimer?.cancel();
      _foregroundTimer = null;
    }
  }

  void _startForegroundRefresh() {
    if (_foregroundTimer != null) return;
    _foregroundTimer = _periodicTimer(
      const Duration(seconds: 60),
      (_) => unawaited(refresh()),
    );
  }

  @override
  void dispose() {
    _foregroundTimer?.cancel();
    if (_observingActiveChannel) {
      _activeChannel.removeListener(_onActiveChannelChanged);
    }
    if (_started) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

String? _profileIdFromEndpoint(String baseUrl) {
  final segments = Uri.tryParse(baseUrl)?.pathSegments ?? const <String>[];
  return segments.length == 2 &&
          segments.first == 'p' &&
          segments.last.trim().isNotEmpty
      ? segments.last.trim()
      : null;
}

String _gatewayLabelForProfile(String label, String? profileId) {
  final trimmed = label.trim();
  if (profileId == null) return trimmed;
  final suffix = ' · $profileId';
  return trimmed.toLowerCase().endsWith(suffix.toLowerCase())
      ? trimmed.substring(0, trimmed.length - suffix.length).trim()
      : trimmed;
}
