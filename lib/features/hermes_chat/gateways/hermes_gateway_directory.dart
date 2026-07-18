// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/client/hermes_api_client.dart';
import '../../../core/hermes/client/hermes_api_config.dart';
import '../../../core/hermes/models/hermes_session.dart';
import '../../../core/hermes/setup/hermes_endpoint_store.dart';
import 'gateway_contact.dart';
import 'gateway_contact_cache.dart';

class GatewaySummary {
  const GatewaySummary({
    required this.profiles,
    required this.sessionsByProfile,
    this.unscopedSessions = const [],
  });

  final List<HermesProfile> profiles;
  final Map<String, List<HermesSession>> sessionsByProfile;
  final List<HermesSession> unscopedSessions;
}

typedef GatewayPeriodicTimerFactory =
    Timer Function(Duration duration, void Function(Timer) callback);

abstract interface class GatewaySummaryLoader {
  Future<GatewaySummary> load(HermesEndpointConfig config);
}

class HermesApiGatewaySummaryLoader implements GatewaySummaryLoader {
  const HermesApiGatewaySummaryLoader();

  @override
  Future<GatewaySummary> load(HermesEndpointConfig config) async {
    final client = HermesApiClient(
      config: HermesApiConfig.fromBaseUrl(
        config.baseUrl,
        apiKey: config.apiKey,
      ),
    );
    await client.health();
    final capabilities = await client.capabilities();
    final supportsProfiles = capabilities.advertisesEndpoint(
      'profiles',
      'GET',
      '/api/profiles',
    );
    if (!supportsProfiles) {
      return GatewaySummary(
        profiles: const [],
        sessionsByProfile: const {},
        unscopedSessions: await client.listSessions(),
      );
    }
    final profiles = await client.listProfiles();
    return GatewaySummary(
      profiles: profiles,
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
    this.maxConcurrent = 3,
  }) : assert(maxConcurrent > 0),
       _store = store,
       _cache = cache,
       _loader = loader,
       _activeChannel = activeChannel,
       _now = now ?? DateTime.now,
       _periodicTimer = periodicTimer ?? Timer.periodic;

  final HermesEndpointStore _store;
  final GatewayContactCache _cache;
  final GatewaySummaryLoader _loader;
  final HermesChannel _activeChannel;
  final DateTime Function() _now;
  final GatewayPeriodicTimerFactory _periodicTimer;
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

  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _contacts = await _cache.load();
    notifyListeners();
    await refresh();
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      _startForegroundRefresh();
    }
  }

  Future<void> refresh() async {
    final generation = ++_refreshGeneration;
    _refreshing = true;
    notifyListeners();
    final configs = await _store.loadProfiles();
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
    await _cache.save(_contacts);
    notifyListeners();
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
      final projected = summary.profiles.isEmpty
          ? [
              GatewayContact(
                id: GatewayContactId(
                  gatewayId: gatewayId,
                  profileId: 'default',
                ),
                gatewayLabel: config.displayLabel,
                profileName: 'Default agent',
                latestSession: _latestSession(summary.unscopedSessions),
                sessionCount: summary.unscopedSessions.length,
                availability: GatewayAvailability.online,
                lastRefreshedAt: refreshedAt,
                isFallbackProfile: true,
              ),
            ]
          : [
              for (final profile in summary.profiles)
                GatewayContact(
                  id: GatewayContactId(
                    gatewayId: gatewayId,
                    profileId: profile.id,
                  ),
                  gatewayLabel: config.displayLabel,
                  profileName: profile.displayName,
                  latestSession: _latestSession(
                    summary.sessionsByProfile[profile.id] ?? const [],
                  ),
                  sessionCount:
                      summary.sessionsByProfile[profile.id]?.length ?? 0,
                  availability: GatewayAvailability.online,
                  lastRefreshedAt: refreshedAt,
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
    );
    final displayLabel = normalizedLabel ?? config.baseUrl;
    _configsById[gatewayId] = HermesEndpointConfig(
      id: gatewayId,
      label: normalizedLabel,
      baseUrl: config.baseUrl,
      apiKey: config.apiKey,
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
    await _cache.save(_contacts);
    notifyListeners();
  }

  Future<void> reconnectGateway(String gatewayId) async {
    final config = _configsById[gatewayId];
    if (config == null) throw StateError('Gateway is no longer saved.');
    await _refreshGateway(config, _refreshGeneration);
    await _cache.save(_contacts);
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

  Future<void> removeGateway(String gatewayId) async {
    if (_activeContactId?.gatewayId == gatewayId) await showDirectory();
    await _store.deleteProfile(gatewayId);
    _configsById.remove(gatewayId);
    await _cache.removeGateway(gatewayId);
    _contacts = sortGatewayContacts(
      _contacts.where((contact) => contact.id.gatewayId != gatewayId),
    );
    _gateways = [
      for (final gateway in _gateways)
        if (gateway.id != gatewayId) gateway,
    ];
    notifyListeners();
  }

  Future<void> activate(GatewayContactId id) async {
    final contact = _contacts.firstWhere((item) => item.id == id);
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
        await _activeChannel.selectProfile(contact.id.profileId);
      }
      if (generation != _activationGeneration) return;

      final latestId = contact.latestSession?.id;
      if (latestId != null &&
          _activeChannel.state.sessions.any(
            (session) => session.id == latestId,
          )) {
        try {
          await _activeChannel.selectSession(latestId);
        } catch (_) {
          // A stale or slow session preview must not block a healthy gateway.
        }
      }
    } catch (_) {
      clearFailedActivation();
      rethrow;
    }
  }

  Future<void> showDirectory() async {
    ++_activationGeneration;
    await _activeChannel.disconnect();
    _activeContactId = null;
    notifyListeners();
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
    if (_started) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
