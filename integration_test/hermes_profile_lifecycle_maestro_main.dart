import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/core/hermes/models/hermes_profile.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/profiles/widgets/profile_editor_sheet.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/app_router.dart';
import 'package:wing/theme/wing_theme.dart';

import '../test/features/hermes_chat/support/fake_hermes_channel.dart';

const _profileIds = <String>[
  'default',
  'cadencia',
  'link',
  'mineru',
  'portal-crazy',
  'sdrhf-vigia',
  'sidon',
  'visor-box',
  'yunobo',
];

final _profileCapabilities = HermesCapabilityDocument.fromJson({
  'schema_version': 1,
  'object': 'hermes.api_server.capabilities',
  'platform': 'hermes-agent',
  'model': 'profile-lifecycle-fixture',
  'profile_context': {
    'type': 'query',
    'name': 'profile',
    'required': true,
    'default_profile_id': 'default',
  },
  'auth': {
    'type': 'bearer',
    'required': true,
    'granted_scopes': ['profiles:read', 'profiles:write'],
  },
  'features': {'session_chat_streaming': true},
  'endpoints': {
    'session_create': {'method': 'POST', 'path': '/api/sessions'},
    'session_chat_stream': {
      'method': 'POST',
      'path': '/api/sessions/{session_id}/chat/stream',
    },
    'profiles': {
      'method': 'GET',
      'path': '/api/profiles',
      'required_scopes': ['profiles:read'],
    },
    'profile_create': {
      'method': 'POST',
      'path': '/api/profiles',
      'required_scopes': ['profiles:write'],
    },
    'profile_update': {
      'method': 'PATCH',
      'path': '/api/profiles/{name}',
      'required_scopes': ['profiles:write'],
    },
    'profile_delete': {
      'method': 'DELETE',
      'path': '/api/profiles/{name}',
      'required_scopes': ['profiles:write'],
    },
    'profile_soul': {
      'method': 'GET',
      'path': '/api/profiles/{name}/soul',
      'required_scopes': ['profiles:read'],
    },
    'profile_soul_update': {
      'method': 'PUT',
      'path': '/api/profiles/{name}/soul',
      'required_scopes': ['profiles:write'],
    },
  },
});

class ProfileLifecycleFixtureChannel extends FakeHermesChannel {
  ProfileLifecycleFixtureChannel(this._preferences)
    : super(
        capabilities: _profileCapabilities,
        profiles: _preferences.getString('profile-fixture-snapshot') != null
            ? [
                for (final row
                    in (jsonDecode(
                              _preferences.getString(
                                'profile-fixture-snapshot',
                              )!,
                            )
                            as Map<String, dynamic>)['profiles']
                        as List)
                  HermesProfile.fromJson(Map<String, Object?>.from(row as Map)),
              ]
            : [
                for (final id in _profileIds)
                  HermesProfile(
                    id: id,
                    displayName:
                        _preferences.getString('profile-name-$id') ?? id,
                    revision: 'profile-rev-$id-1',
                    description: 'Authoritative fixture profile $id',
                    model: id == 'sdrhf-vigia'
                        ? 'auto/best-coding'
                        : 'gpt-5.6-sol',
                    gatewayRunning: id != 'default',
                  ),
              ],
        selectedProfileId: 'default',
      );

  final SharedPreferences _preferences;
  Set<String> get _knownProfileIds => state.profiles.map((p) => p.id).toSet();
  final _history = <String, List<HermesChatTurn>>{};
  int setupCalls = 0;
  bool setupMatches = false;

  late final Map<String, HermesProfileSoul> _souls = {
    for (final profile in state.profiles)
      profile.id: HermesProfileSoul(
        soul:
            _preferences.getString('profile-soul-${profile.id}') ??
            'persona-initial-${profile.id}',
        revision:
            _preferences.getString('profile-soul-rev-${profile.id}') ??
            'soul-rev-${profile.id}-1',
      ),
  };

  Future<void> _persist() async {
    await _preferences.setString(
      'profile-fixture-snapshot',
      jsonEncode({
        'profiles': [
          for (final p in state.profiles)
            {
              'id': p.id,
              'name': p.displayName,
              'revision': p.revision,
              'description': p.description,
              'model': p.model,
              'gateway_running': p.gatewayRunning,
            },
        ],
      }),
    );
    for (final entry in _souls.entries) {
      await _preferences.setString(
        'profile-soul-${entry.key}',
        entry.value.soul,
      );
      await _preferences.setString(
        'profile-soul-rev-${entry.key}',
        entry.value.revision,
      );
    }
  }

  void _checkRevision(String id, String revision) {
    if (!state.profiles.any((p) => p.id == id && p.revision == revision)) {
      throw StateError('Hermes API returned HTTP 412');
    }
  }

  Future<void> configuredCreate({
    required String name,
    String? cloneFrom,
    String? description,
    String? provider,
    String? model,
    String? providerApiKey,
    String? idempotencyKey,
  }) async {
    setupCalls++;
    if (providerApiKey != null) {
      throw StateError('No credentials in this fixture');
    }
    setupMatches =
        name == 'setup-qa' &&
        cloneFrom == null &&
        description == 'Fixture setup description' &&
        provider == 'openrouter' &&
        model == 'fixture-model';
    if (!setupMatches) throw StateError('Unexpected fixture setup');
    await createProfile(name: name, cloneFrom: cloneFrom);
    replaceCapabilitiesAndProfiles(_profileCapabilities, [
      for (final p in state.profiles)
        if (p.id == name)
          HermesProfile(
            id: p.id,
            displayName: p.displayName,
            revision: p.revision,
            description: description!,
            model: model!,
            gatewayRunning: true,
          )
        else
          p,
    ]);
    await _preferences.setString('profile-provider-$name', provider!);
    await _persist();
  }

  @override
  Future<void> selectProfile(
    String profileId, {
    bool allowDiscovered = false,
  }) async {
    if (!_knownProfileIds.contains(profileId)) {
      throw StateError('unknown fixture profile $profileId');
    }
    _history.addAll(state.messages);
    final sessionId = 'session-$profileId';
    replaceSessions(
      [HermesSession(id: sessionId, source: 'fixture', title: profileId)],
      activeSessionId: sessionId,
      messages: _history,
    );
    await super.selectProfile(profileId, allowDiscovered: allowDiscovered);
  }

  @override
  Future<void> createProfile({required String name, String? cloneFrom}) async {
    final id = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    if (_knownProfileIds.contains(id) ||
        cloneFrom != null && !_knownProfileIds.contains(cloneFrom)) {
      throw StateError('Invalid fixture create');
    }
    await super.createProfile(name: name, cloneFrom: cloneFrom);
    final cloneSoul = _souls[cloneFrom];
    _souls[id] = HermesProfileSoul(
      soul: cloneSoul?.soul ?? 'persona-initial-$id',
      revision: 'soul-rev-$id-1',
    );
    replaceCapabilitiesAndProfiles(_profileCapabilities, [
      for (final profile in state.profiles)
        if (profile.id == id)
          HermesProfile(
            id: id,
            displayName: profile.displayName,
            revision: profile.revision,
            description: cloneFrom == null
                ? 'Fresh fixture profile'
                : 'Cloned from $cloneFrom',
            model:
                state.profiles
                    .where((p) => p.id == cloneFrom)
                    .firstOrNull
                    ?.model ??
                '',
            gatewayRunning: true,
          )
        else
          profile,
    ]);
    await _persist();
  }

  @override
  Future<void> renameProfile({
    required String profileId,
    required String name,
    required String revision,
  }) async {
    _checkRevision(profileId, revision);
    await super.renameProfile(
      profileId: profileId,
      name: name,
      revision: revision,
    );
    replaceCapabilitiesAndProfiles(_profileCapabilities, [
      for (final p in state.profiles)
        if (p.id == profileId)
          HermesProfile(
            id: p.id,
            displayName: p.displayName,
            revision: '$revision-next',
            description: p.description,
            model: p.model,
            gatewayRunning: p.gatewayRunning,
          )
        else
          p,
    ]);
    await _persist();
  }

  @override
  Future<HermesProfileSoul> readProfileSoul(String profileId) async {
    readProfileSoulCalls.add(profileId);
    final soul = _souls[profileId];
    if (soul == null) throw StateError('unknown fixture profile $profileId');
    return soul;
  }

  @override
  Future<void> writeProfileSoul({
    required String profileId,
    required String soul,
    required String revision,
  }) async {
    final current = _souls[profileId];
    if (current == null || current.revision != revision) {
      throw StateError('Hermes API returned HTTP 412');
    }
    writeProfileSoulCalls.add({
      'profileId': profileId,
      'soul': soul,
      'revision': revision,
    });
    _souls[profileId] = HermesProfileSoul(
      soul: soul,
      revision: '${current.revision}-next',
    );
    await _persist();
  }

  @override
  Future<void> deleteProfile({
    required String profileId,
    required String revision,
  }) async {
    if (profileId == 'default') throw StateError('Default cannot be deleted');
    _checkRevision(profileId, revision);
    final deletedSelection = state.selectedProfileId == profileId;
    await super.deleteProfile(profileId: profileId, revision: revision);
    if (deletedSelection && state.profiles.isNotEmpty) {
      await selectProfile(state.profiles.first.id);
    }
    _souls.remove(profileId);
    _history.remove('session-$profileId');
    await _preferences.remove('profile-name-$profileId');
    await _preferences.remove('profile-soul-$profileId');
    await _preferences.remove('profile-soul-rev-$profileId');
    await _preferences.remove('profile-provider-$profileId');
    await _persist();
  }

  @override
  Future<void> sendText(
    String text, {
    String? imageDataUrl,
    String? textAttachment,
    String? attachmentName,
  }) async {
    final profileId = state.selectedProfileId ?? 'missing';
    final sessionId = state.activeSessionId ?? 'missing';
    if (!_knownProfileIds.contains(profileId) ||
        sessionId != 'session-$profileId') {
      throw StateError('Fixture chat profile/session mismatch');
    }
    final provider = _preferences.getString('profile-provider-$profileId');
    final model = state.profiles.firstWhere((p) => p.id == profileId).model;
    beginStreamingTurn(text);
    completeStreamingTurn(
      text:
          'PROFILE_RECEIPT::$profileId::$sessionId::$text::assistant'
          '${provider == null ? '' : '\nMODEL_RECEIPT::$profileId::$provider::$model::$text::assistant'}',
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final channel = ProfileLifecycleFixtureChannel(preferences);
  await channel.selectProfile('default');
  runApp(
    ProviderScope(
      overrides: [hermesChannelProvider.overrideWithValue(channel)],
      child: const _ProfileLifecycleFixtureApp(),
    ),
  );
}

class _ProfileLifecycleFixtureApp extends ConsumerWidget {
  const _ProfileLifecycleFixtureApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Hermes Wing Profile Lifecycle Fixture',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: wingLightTheme,
      darkTheme: wingDarkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) => Column(
        children: [
          Expanded(child: child!),
          Material(
            child: SafeArea(
              top: false,
              child: TextButton(
                child: const Text('Fixture configured profile'),
                onPressed: () async {
                  final channel =
                      ref.read(hermesChannelProvider)
                          as ProfileLifecycleFixtureChannel;
                  await showModalBottomSheet<void>(
                    context: router.routerDelegate.navigatorKey.currentContext!,
                    isScrollControlled: true,
                    builder: (_) => ProfileEditorSheet(
                      channel: channel,
                      profiles: channel.state.profiles,
                      stableNames: true,
                      canConfigure: true,
                      onCreate: channel.configuredCreate,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
