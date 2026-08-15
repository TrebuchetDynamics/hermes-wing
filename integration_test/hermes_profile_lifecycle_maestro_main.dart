import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_profile.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
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
        profiles: [
          for (final id in _profileIds)
            HermesProfile(
              id: id,
              displayName: _preferences.getString('profile-name-$id') ?? id,
              revision: 'profile-rev-$id-1',
              description: 'Authoritative fixture profile $id',
              model: id == 'sdrhf-vigia' ? 'auto/best-coding' : 'gpt-5.6-sol',
              gatewayRunning: id != 'default',
            ),
        ],
        selectedProfileId: 'default',
      );

  final SharedPreferences _preferences;
  final Set<String> _knownProfileIds = {..._profileIds};

  late final Map<String, HermesProfileSoul> _souls = {
    for (final id in _profileIds)
      id: HermesProfileSoul(
        soul:
            _preferences.getString('profile-soul-$id') ?? 'persona-initial-$id',
        revision: 'soul-rev-$id-1',
      ),
  };

  @override
  Future<void> selectProfile(
    String profileId, {
    bool allowDiscovered = false,
  }) async {
    if (!_knownProfileIds.contains(profileId)) {
      throw StateError('unknown fixture profile $profileId');
    }
    final sessionId = 'session-$profileId';
    replaceSessions([
      HermesSession(id: sessionId, source: 'fixture', title: profileId),
    ], activeSessionId: sessionId);
    await super.selectProfile(profileId, allowDiscovered: allowDiscovered);
  }

  @override
  Future<void> createProfile({required String name, String? cloneFrom}) async {
    await super.createProfile(name: name, cloneFrom: cloneFrom);
    final id = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    _knownProfileIds.add(id);
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
            description: 'Cloned from ${cloneFrom ?? 'default'}',
            model: cloneFrom == 'mineru' ? 'gpt-5.6-sol' : profile.model,
            gatewayRunning: true,
          )
        else
          profile,
    ]);
  }

  @override
  Future<void> renameProfile({
    required String profileId,
    required String name,
    required String revision,
  }) async {
    await super.renameProfile(
      profileId: profileId,
      name: name,
      revision: revision,
    );
    await _preferences.setString('profile-name-$profileId', name.trim());
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
      revision: 'soul-rev-$profileId-2',
    );
    await _preferences.setString('profile-soul-$profileId', soul);
  }

  @override
  Future<void> deleteProfile({
    required String profileId,
    required String revision,
  }) async {
    final deletedSelection = state.selectedProfileId == profileId;
    await super.deleteProfile(profileId: profileId, revision: revision);
    if (deletedSelection && state.profiles.isNotEmpty) {
      await selectProfile(state.profiles.first.id);
    }
    _knownProfileIds.remove(profileId);
    _souls.remove(profileId);
    await _preferences.remove('profile-name-$profileId');
    await _preferences.remove('profile-soul-$profileId');
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
    beginStreamingTurn(text);
    completeStreamingTurn(
      text: 'PROFILE_RECEIPT::$profileId::$sessionId::$text::assistant',
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final channel = ProfileLifecycleFixtureChannel(preferences);
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
    );
  }
}
