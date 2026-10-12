import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';

import 'package:wing/core/hermes/models/hermes_capabilities.dart';

import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/core/wing_link/wing_link_client.dart';
import 'package:wing/features/profiles/screens/profiles_screen.dart';
import 'package:wing/features/profiles/widgets/profile_editor_sheet.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/routes/app_routes.dart';
import 'package:wing/shared/widgets/wing_skeleton.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';
import '../hermes_chat/support/fake_hermes_endpoint_store.dart';
import '../hermes_chat/support/fake_hermes_gateway_directory.dart';

HermesCapabilityDocument _profileCapabilities(
  List<String> scopes, {
  bool advertisesDelete = true,
  bool advertisesSoul = false,
  bool advertisesRead = true,
  bool advertisesModels = false,
  bool advertisesModelLock = false,
}) => HermesCapabilityDocument.fromJson({
  'schema_version': 1,
  'profile_context': {
    'type': 'query',
    'name': 'profile',
    'required': true,
    'default_profile_id': 'default',
  },
  'auth': {'type': 'bearer', 'required': true, 'granted_scopes': scopes},
  'endpoints': {
    if (advertisesRead)
      'profiles': {
        'method': 'GET',
        'path': '/api/profiles',
        'required_scopes': ['profiles:read'],
      },
    if (advertisesModels)
      'model_options': {
        'method': 'GET',
        'path': '/api/model/options',
        'profile_scoped': true,
        'required_scopes': ['models:read'],
      },
    if (advertisesModelLock)
      'session_model_lock': {
        'method': 'POST',
        'path': '/api/sessions/{session_id}/model',
        'profile_scoped': true,
        'required_scopes': ['models:write'],
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
    if (advertisesDelete)
      'profile_delete': {
        'method': 'DELETE',
        'path': '/api/profiles/{name}',
        'required_scopes': ['profiles:write'],
      },
    if (advertisesSoul) ...{
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
  },
});

class _GatedProfileSelectionChannel extends FakeHermesChannel {
  _GatedProfileSelectionChannel({
    required super.capabilities,
    required super.profiles,
    required super.selectedProfileId,
  });

  final selectionGate = Completer<void>();
  int selectionAttempts = 0;

  @override
  Future<void> selectProfile(
    String profileId, {
    bool allowDiscovered = false,
    bool deferSessionSelection = false,
  }) async {
    selectionAttempts += 1;
    await selectionGate.future;
    await super.selectProfile(
      profileId,
      allowDiscovered: allowDiscovered,
      deferSessionSelection: deferSessionSelection,
    );
  }
}

Widget _profilesTestApp(
  HermesChannel channel, {
  double textScale = 1.0,
  bool startSetup = false,
  HermesGatewayDirectory? directory,
  WingLinkClientBuilder? wingLinkClientBuilder,
}) => ProviderScope(
  overrides: [
    hermesChannelProvider.overrideWithValue(channel),
    hermesGatewayDirectoryProvider.overrideWith(
      (ref) =>
          directory ??
          HermesGatewayDirectory(
            store: FakeHermesEndpointStore(profiles: const []),
            cache: FakeGatewayContactCache(),
            loader: FakeGatewaySummaryLoader(const {}),
            activeChannel: channel,
          ),
    ),
    if (wingLinkClientBuilder != null)
      wingLinkClientBuilderProvider.overrideWithValue(wingLinkClientBuilder),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
      ),
      child: child!,
    ),
    home: ProfilesScreen(startSetup: startSetup),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final editing in [false, true]) {
    testWidgets(
      'provider replacement fences held ${editing ? 'edit' : 'create'} action',
      (tester) async {
        FakeHermesChannel owner(String name) => FakeHermesChannel(
          capabilities: _profileCapabilities([
            'profiles:read',
            'profiles:write',
          ]),
          profiles: [
            HermesProfile(id: 'default', displayName: name, revision: 'r1'),
          ],
          selectedProfileId: 'default',
        );
        final first = owner('First');
        final second = owner('Second');
        addTearDown(first.dispose);
        addTearDown(second.dispose);
        final directory = directoryFor(
          configs: const [],
          loader: FakeGatewaySummaryLoader(const {}),
          activeChannel: first,
        );
        await tester.pumpWidget(_profilesTestApp(first, directory: directory));
        await tester.pumpAndSettle();
        await tester.tap(
          editing
              ? find.widgetWithText(OutlinedButton, 'Edit')
              : find.text('New Profile'),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Profile name'),
          'Changed',
        );
        final action = tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, editing ? 'Save' : 'Create'),
            )
            .onPressed!;
        await tester.pumpWidget(_profilesTestApp(second, directory: directory));
        action();
        await tester.pumpAndSettle();
        expect(first.createProfileCalls, isEmpty);
        expect(first.renameProfileCalls, isEmpty);
        expect(second.createProfileCalls, isEmpty);
        expect(second.renameProfileCalls, isEmpty);
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, editing ? 'Save' : 'Create'),
              )
              .onPressed,
          isNull,
        );
        await tester.tap(find.text('Cancel').last);
        await tester.pumpAndSettle();
        expect(find.text('Second'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('late selection from replaced Agent cannot open Chat', (
    tester,
  ) async {
    final first = _GatedProfileSelectionChannel(
      capabilities: _profileCapabilities(['profiles:read']),
      profiles: const [
        HermesProfile(id: 'coder', displayName: 'Coder', revision: 'r1'),
      ],
      selectedProfileId: 'default',
    );
    final second = FakeHermesChannel(
      capabilities: _profileCapabilities(['profiles:read']),
      profiles: const [
        HermesProfile(id: 'default', displayName: 'Second', revision: 'r2'),
      ],
    );
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    final directory = directoryFor(
      configs: const [],
      loader: FakeGatewaySummaryLoader(const {}),
      activeChannel: first,
    );
    final router = GoRouter(
      initialLocation: AppRoutes.agents,
      routes: [
        GoRoute(
          path: AppRoutes.agents,
          builder: (_, _) => const ProfilesScreen(),
        ),
        GoRoute(
          path: AppRoutes.hermes,
          builder: (_, _) => const Scaffold(body: Text('Chat destination')),
        ),
      ],
    );
    addTearDown(router.dispose);
    Widget app(FakeHermesChannel channel) => ProviderScope(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpWidget(app(first));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Chat'));
    await tester.pump();
    await tester.pumpWidget(app(second));
    first.selectionGate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Chat destination'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
    expect(second.selectProfileCalls, isEmpty);
  });

  for (final modelSupport in ['absent', 'denied', 'supported']) {
    testWidgets(
      'direct Agent controls and catalog with legacy metadata $modelSupport',
      (tester) async {
        tester.view.physicalSize = const Size(900, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final caps = _profileCapabilities(
          [
            'profiles:read',
            'profiles:write',
            if (modelSupport == 'supported') 'models:read',
            'models:write',
          ],
          advertisesModels: modelSupport != 'absent',
          advertisesModelLock: true,
        );
        final requests =
            <
              ({
                String method,
                Uri uri,
                Map<String, String> headers,
                Object? body,
              })
            >[];
        final profiles = <String, Map<String, Object?>>{
          'default': {
            'id': 'default',
            'name': 'Default',
            'revision': 'r-default',
          },
          'coder': {'id': 'coder', 'name': 'Coder', 'revision': 'r-coder'},
        };
        final channel = HermesApiChannel(
          clientBuilder: (config) => HermesApiClient(
            config: config,
            get: (uri, headers) async {
              requests.add((
                method: 'GET',
                uri: uri,
                headers: headers,
                body: null,
              ));
              return switch (uri.path) {
                '/health' => '{"status":"ok"}',
                '/v1/capabilities' => jsonEncode({
                  'schema_version': 1,
                  'profile_context': {
                    'type': 'query',
                    'name': 'profile',
                    'required': true,
                    'default_profile_id': 'default',
                  },
                  'auth': {
                    'type': 'bearer',
                    'required': true,
                    'granted_scopes': caps.auth.grantedScopes,
                  },
                  'endpoints': {
                    for (final entry in caps.endpoints.entries)
                      entry.key: {
                        'method': entry.value.method,
                        'path': entry.value.path,
                        'profile_scoped': entry.value.profileScoped,
                        'required_scopes': entry.value.requiredScopes,
                      },
                  },
                }),
                '/api/profiles' => jsonEncode({
                  'data': profiles.values.toList(),
                }),
                '/api/sessions' => '{"data":[{"id":"fixture-session"}]}',
                '/api/sessions/fixture-session/messages' =>
                  '{"object":"list","session_id":"fixture-session","data":[],"order":"latest"}',
                '/api/model/options' =>
                  '{"providers":[{"provider":"synthetic","label":"Synthetic","models":["example/model"],"authenticated":true}]}',
                _ => throw StateError('Unexpected Agent read'),
              };
            },
            post: (uri, headers, body) async {
              requests.add((
                method: 'POST',
                uri: uri,
                headers: headers,
                body: jsonDecode(body),
              ));
              if (uri.path == '/api/sessions/fixture-session/model') {
                return '{"session_id":"fixture-session","runtime":{"provider":"synthetic","model":"example/model","model_lock":"accepted"}}';
              }
              expect(uri.path, '/api/profiles');
              profiles['writer'] = {
                'id': 'writer',
                'name': 'Writer',
                'revision': 'r-writer',
              };
              return jsonEncode({'profile': profiles['writer']});
            },
            patch: (uri, headers, body) async {
              requests.add((
                method: 'PATCH',
                uri: uri,
                headers: headers,
                body: jsonDecode(body),
              ));
              profiles['writer'] = {
                'id': 'writer',
                'name': 'Renamed',
                'revision': 'r-renamed',
              };
              return jsonEncode({'profile': profiles['writer']});
            },
            delete: (uri, headers) async {
              requests.add((
                method: 'DELETE',
                uri: uri,
                headers: headers,
                body: null,
              ));
              profiles.remove('writer');
              return '{"id":"writer","deleted":true}';
            },
          ),
        );
        addTearDown(channel.dispose);
        final legacyRecoveries = <String?>[];
        final directory = HermesGatewayDirectory(
          store: FakeHermesEndpointStore(
            profiles: const [
              HermesEndpointConfig(
                id: 'agent',
                baseUrl: 'https://agent.example',
                apiKey: 'fixture-agent',
                wingLinkOrigin: 'https://link.example',
                wingLinkToken: 'fixture-legacy',
                wingLinkPendingCredentialId: 'fixture-pending',
              ),
              HermesEndpointConfig(
                id: 'other-agent',
                baseUrl: 'https://other-agent.example',
                wingLinkOrigin: 'https://other-link.example',
                wingLinkToken: 'fixture-other-legacy',
                wingLinkPendingCredentialId: 'fixture-other-pending',
              ),
            ],
          ),
          cache: FakeGatewayContactCache(),
          loader: FakeGatewaySummaryLoader({
            'agent': gatewaySummary(['default', 'coder']),
          }),
          activeChannel: channel,
          pendingCredentialRecovery: (config) async {
            legacyRecoveries.add(config.id);
            return false;
          },
        );
        await directory.refresh();
        expect(legacyRecoveries, isEmpty);
        await directory.activateGateway('agent');
        expect(
          channel.state.isConnected,
          isTrue,
          reason:
              '${channel.state.errorMessage}; ${requests.map((r) => r.uri.path).toList()}',
        );
        await channel.selectProfile('default');
        legacyRecoveries.clear();
        var linkConstructions = 0;
        var linkRequests = 0;
        final router = GoRouter(
          initialLocation: AppRoutes.agents,
          routes: [
            GoRoute(
              path: AppRoutes.agents,
              builder: (_, _) => const ProfilesScreen(),
            ),
            GoRoute(
              path: AppRoutes.hermes,
              builder: (_, _) => const HermesChatScreen(),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              hermesChannelProvider.overrideWithValue(channel),
              hermesGatewayDirectoryProvider.overrideWith((_) => directory),
              hermesVoiceCaptureServiceProvider.overrideWithValue(null),
              hermesTextToSpeechServiceProvider.overrideWithValue(null),
              wingLinkClientBuilderProvider.overrideWithValue(({
                required origin,
                required token,
                required hostFingerprint,
              }) {
                linkConstructions++;
                return WingLinkClient(
                  origin: origin,
                  token: token,
                  get: (_, _) async {
                    linkRequests++;
                    return '{"profiles":[]}';
                  },
                );
              }),
            ],
            child: MaterialApp.router(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Coder'), findsOneWidget);
        expect(
          requests.where((r) => r.uri.path == '/api/profiles'),
          isNotEmpty,
        );
        // No native profile-provider assignment contract exists. Do not expose
        // the legacy setup catalog or configuration mutation in this editor.
        await tester.tap(find.text('New Profile'));
        await tester.pumpAndSettle();
        final editor = tester.widget<ProfileEditorSheet>(
          find.byType(ProfileEditorSheet),
        );
        expect(editor.canConfigure, isFalse);
        expect(editor.loadModelOptions, isNull);
        expect(requests.where((r) => r.method == 'POST'), isEmpty);
        await tester.tap(find.text('Cancel').last);
        await tester.pumpAndSettle();
        expect(requests.where((r) => r.method != 'GET'), isEmpty);
        expect(
          legacyRecoveries,
          isEmpty,
          reason: 'Cancel must not recover Link',
        );
        await tester.tap(find.text('New Profile'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Profile name'),
          'Writer',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Create'));
        await tester.pumpAndSettle();
        expect(find.byType(ProfileEditorSheet), findsNothing);
        expect(
          legacyRecoveries,
          isEmpty,
          reason: 'Create must not recover Link',
        );
        expect(find.text('Writer'), findsOneWidget);
        Finder writerCard() => find.ancestor(
          of: find.text(profiles['writer']!['name']! as String),
          matching: find.byType(Card),
        );
        final edit = find.descendant(
          of: writerCard(),
          matching: find.widgetWithText(OutlinedButton, 'Edit'),
        );
        await tester.ensureVisible(edit);
        await tester.tap(edit);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Profile name'),
          'Renamed',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
        await tester.pumpAndSettle();
        expect(legacyRecoveries, isEmpty, reason: 'Edit must not recover Link');
        expect(find.text('Renamed'), findsOneWidget);
        final chat = find.descendant(
          of: writerCard(),
          matching: find.widgetWithText(FilledButton, 'Chat'),
        );
        await tester.ensureVisible(chat);
        await tester.tap(chat);
        await tester.pumpAndSettle();
        expect(channel.state.selectedProfileId, 'writer');
        expect(channel.state.activeSessionId, 'fixture-session');
        if (modelSupport == 'supported') {
          await tester.tap(
            find.byKey(const ValueKey('hermes-composer-model-chip')),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey('session-model-synthetic/example/model')),
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Use for session'));
          await tester.tap(find.text('Use for session'));
          await tester.pumpAndSettle();
          final lock = channel.state.sessionModelLocks['fixture-session']!;
          expect(lock.accepted, isTrue);
          expect(lock.provider, 'synthetic');
          expect(lock.model, 'example/model');
          expect(channel.state.selectedProfileId, 'writer');
          expect(channel.state.activeSessionId, 'fixture-session');
          final write = requests
              .where((r) => r.uri.path == '/api/sessions/fixture-session/model')
              .single;
          expect(write.method, 'POST');
          expect(write.uri.queryParameters['profile'], 'writer');
          expect(write.body, {
            'provider': 'synthetic',
            'model': 'example/model',
          });
          expect(
            channel.state.modelOptions!.providers.single.slug,
            'synthetic',
          );
          expect(
            requests
                .where((r) => r.uri.path == '/api/model/options')
                .single
                .uri
                .queryParameters['profile'],
            'writer',
          );
        } else {
          expect(
            tester
                .widget<ActionChip>(
                  find.byKey(const ValueKey('hermes-composer-model-chip')),
                )
                .onPressed,
            isNull,
          );
          expect(
            requests.where((r) => r.uri.path == '/api/model/options'),
            isEmpty,
          );
        }
        expect(
          legacyRecoveries,
          isEmpty,
          reason: 'Model selection must not recover Link',
        );
        router.pop();
        await tester.pumpAndSettle();
        final remove = find.descendant(
          of: writerCard(),
          matching: find.widgetWithText(TextButton, 'Delete profile'),
        );
        await tester.ensureVisible(remove);
        await tester.tap(remove);
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(TextButton, 'Delete profile').last,
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).last, 'Renamed');
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Delete profile'));
        await tester.pumpAndSettle();
        expect(find.byType(ProfileEditorSheet), findsNothing);
        expect(
          legacyRecoveries,
          isEmpty,
          reason: 'Delete must not recover Link',
        );
        expect(channel.state.profiles.any((p) => p.id == 'writer'), isFalse);
        final writes = requests
            .where(
              (r) =>
                  r.method != 'GET' && r.uri.path.startsWith('/api/profiles'),
            )
            .toList();
        expect(
          requests.where((r) => r.method != 'GET').length,
          modelSupport == 'supported' ? 4 : 3,
        );
        expect(writes.map((r) => [r.method, r.uri.path, r.body]), [
          [
            'POST',
            '/api/profiles',
            {'name': 'Writer', 'clone_from': 'default'},
          ],
          [
            'PATCH',
            '/api/profiles/writer',
            {'name': 'Renamed'},
          ],
          ['DELETE', '/api/profiles/writer', null],
        ]);
        expect(writes[1].headers['If-Match'], 'r-writer');
        expect(writes[2].headers['If-Match'], 'r-renamed');
        expect(
          requests.every(
            (r) =>
                r.uri.host == 'agent.example' &&
                r.headers['Authorization'] == 'Bearer fixture-agent',
          ),
          isTrue,
        );
        expect(linkConstructions, 0);
        expect(linkRequests, 0);
        expect(legacyRecoveries, isEmpty);
        expect(
          directory.configForGateway('agent')!.wingLinkToken,
          'fixture-legacy',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final mode in ['denied', 'write-only', 'absent', 'no-document']) {
    testWidgets('legacy metadata cannot restore denied Agent access $mode', (
      tester,
    ) async {
      final channel = FakeHermesChannel(
        capabilities: mode == 'no-document'
            ? null
            : _profileCapabilities(
                mode == 'write-only'
                    ? ['profiles:write']
                    : mode == 'absent'
                    ? ['profiles:read']
                    : [],
                advertisesRead: mode != 'absent',
              ),
      );
      addTearDown(channel.dispose);
      final directory = directoryFor(
        configs: const [
          HermesEndpointConfig(
            id: 'legacy',
            baseUrl: 'https://agent.example',
            wingLinkOrigin: 'https://link.example',
            wingLinkToken: 'fixture-only',
          ),
        ],
        loader: FakeGatewaySummaryLoader({
          'legacy': gatewaySummary(['default']),
        }),
        activeChannel: channel,
      );
      await directory.refresh();
      await directory.activateGateway('legacy');
      var constructions = 0;
      var requests = 0;
      await tester.pumpWidget(
        _profilesTestApp(
          channel,
          directory: directory,
          startSetup: true,
          wingLinkClientBuilder:
              ({required origin, required token, required hostFingerprint}) {
                constructions++;
                return WingLinkClient(
                  origin: origin,
                  token: token,
                  get: (_, _) async {
                    requests++;
                    return '{"profiles":[]}';
                  },
                );
              },
        ),
      );
      await tester.pumpAndSettle();
      expect(constructions, 0);
      expect(requests, 0);
      expect(find.text('Profiles unavailable'), findsOneWidget);
      expect(find.byType(ProfileEditorSheet), findsNothing);
      expect(channel.createProfileCalls, isEmpty);
      expect(
        directory.configForGateway('legacy')!.wingLinkToken,
        'fixture-only',
      );
    });
  }

  for (final width in [390.0, 1280.0]) {
    testWidgets(
      'local profile search metadata, literal clear and keyboard at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final channel = FakeHermesChannel(
          capabilities: _profileCapabilities([
            'profiles:read',
            'profiles:write',
          ]),
          selectedProfileId: 'default',
          profiles: [
            const HermesProfile(
              id: 'default',
              displayName: 'Home',
              revision: 'r1',
            ),
            const HermesProfile(
              id: 'coder',
              displayName: 'Coding Profile',
              revision: 'r2',
              description: 'Review [draft].*',
              model: 'Example/Small',
            ),
            HermesProfile.fromJson({
              'id': 'bare',
              'name': null,
              'revision': 'r3',
              'description': null,
              'model': null,
            }),
          ],
        );
        addTearDown(channel.dispose);
        await tester.pumpWidget(_profilesTestApp(channel, textScale: 2));
        await tester.pumpAndSettle();
        final search = find.byKey(const ValueKey('profiles-search'));
        expect(search, findsOneWidget);
        expect(find.byTooltip('Clear profile search'), findsNothing);
        for (final query in [
          'CODER',
          'coding PROFILE',
          'review [DRAFT].*',
          'example/SMALL',
        ]) {
          await tester.enterText(search, query);
          await tester.pumpAndSettle();
          expect(find.text('Coding Profile'), findsOneWidget);
          expect(find.text('Home'), findsNothing);
          expect(find.text('Active chat'), findsNothing);
          expect(channel.state.selectedProfileId, 'default');
        }
        await tester.enterText(search, 'not present');
        await tester.pumpAndSettle();
        expect(find.text('No matching profiles'), findsOneWidget);
        expect(find.text('No profiles available'), findsNothing);
        expect(find.text('New Profile'), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(search).controller!.text, isEmpty);
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('bare'), findsOneWidget);
        expect(find.text('Active chat'), findsOneWidget);
        expect(find.bySemanticsLabel('Search profiles'), findsOneWidget);
        expect(channel.selectProfileCalls, isEmpty);
        expect(channel.connectCalls, isEmpty);
        expect(channel.createProfileCalls, isEmpty);
        expect(channel.renameProfileCalls, isEmpty);
        expect(channel.deleteProfileCalls, isEmpty);
        expect(channel.readProfileSoulCalls, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'profile search preserves same-owner updates, loses read authority and does not resurrect',
    (tester) async {
      final caps = _profileCapabilities(['profiles:read']);
      final channel = FakeHermesChannel(
        capabilities: caps,
        profiles: const [
          HermesProfile(id: 'first', displayName: 'First', revision: 'r1'),
          HermesProfile(id: 'second', displayName: 'Second', revision: 'r2'),
        ],
      );
      addTearDown(channel.dispose);
      await tester.pumpWidget(_profilesTestApp(channel));
      await tester.pumpAndSettle();
      final search = find.byKey(const ValueKey('profiles-search'));
      await tester.enterText(search, 'second');
      channel.replaceCapabilitiesAndProfiles(
        _profileCapabilities(['profiles:read']),
        const [
          HermesProfile(
            id: 'first',
            displayName: 'First refreshed',
            revision: 'r3',
          ),
          HermesProfile(
            id: 'second',
            displayName: 'Second refreshed',
            revision: 'r4',
          ),
        ],
      );
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(search).controller!.text, 'second');
      expect(find.text('First refreshed'), findsNothing);
      expect(find.text('Second refreshed'), findsOneWidget);
      channel.replaceCapabilitiesAndProfiles(
        _profileCapabilities([]),
        channel.state.profiles,
      );
      await tester.pumpAndSettle();
      expect(search, findsNothing);
      expect(find.text('Profiles unavailable'), findsOneWidget);
      channel.replaceCapabilitiesAndProfiles(caps, channel.state.profiles);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(search).controller!.text, isEmpty);
      expect(find.text('First refreshed'), findsOneWidget);
    },
  );

  testWidgets(
    'filtered profile create retains full clone inventory and server rejection',
    (tester) async {
      final channel = FakeHermesChannel(
        createProfileFails: true,
        capabilities: _profileCapabilities(['profiles:read', 'profiles:write']),
        profiles: const [
          HermesProfile(id: 'default', displayName: 'Home', revision: 'r1'),
          HermesProfile(
            id: 'coder',
            displayName: 'Coding Profile',
            revision: 'r2',
          ),
        ],
      );
      addTearDown(channel.dispose);
      await tester.pumpWidget(_profilesTestApp(channel));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('profiles-search')),
        'no match',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('New Profile'));
      await tester.pumpAndSettle();
      final editor = tester.widget<ProfileEditorSheet>(
        find.byType(ProfileEditorSheet),
      );
      expect(editor.profiles.map((p) => p.id), ['default', 'coder']);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Profile name'),
        'coder',
      );
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create'));
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();
      expect(channel.createProfileCalls, [
        {'name': 'coder', 'cloneFrom': 'default'},
      ]);
      expect(find.byType(ProfileEditorSheet), findsOneWidget);
    },
  );

  testWidgets(
    'profile lifecycle creates, uses, edits persona, renames, and removes an agent',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final channel = FakeHermesChannel(
        capabilities: _profileCapabilities(const [
          'profiles:read',
          'profiles:write',
        ], advertisesSoul: true),
        profiles: const [
          HermesProfile(
            id: 'default',
            displayName: 'Hermes One',
            revision: 'rev-default',
          ),
        ],
        selectedProfileId: 'default',
        profileSoul: const HermesProfileSoul(
          soul: 'Initial persona.',
          revision: 'soul-1',
        ),
      );
      addTearDown(channel.dispose);
      final router = GoRouter(
        initialLocation: AppRoutes.agents,
        routes: [
          GoRoute(
            path: AppRoutes.agents,
            builder: (_, _) => const ProfilesScreen(),
          ),
          GoRoute(
            path: AppRoutes.hermes,
            builder: (_, _) => const Scaffold(body: Text('Chat destination')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hermesChannelProvider.overrideWithValue(channel),
            hermesGatewayDirectoryProvider.overrideWith(
              (ref) => directoryFor(
                configs: const [],
                loader: FakeGatewaySummaryLoader(const {}),
                activeChannel: channel,
              ),
            ),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'New Profile'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Lifecycle Agent',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();
      expect(channel.createProfileCalls, [
        {'name': 'Lifecycle Agent', 'cloneFrom': 'default'},
      ]);
      expect(find.text('Lifecycle Agent'), findsOneWidget);

      Finder lifecycleCard() => find.ancestor(
        of: find.text('Lifecycle Agent'),
        matching: find.byType(Card),
      );
      final chat = find.descendant(
        of: lifecycleCard(),
        matching: find.widgetWithText(FilledButton, 'Chat'),
      );
      await tester.ensureVisible(chat);
      await tester.tap(chat);
      await tester.pumpAndSettle();
      expect(channel.selectProfileCalls, ['lifecycle-agent']);
      expect(channel.state.selectedProfileId, 'lifecycle-agent');
      expect(find.text('Chat destination'), findsOneWidget);

      router.go(AppRoutes.agents);
      await tester.pumpAndSettle();
      final edit = find.descendant(
        of: lifecycleCard(),
        matching: find.widgetWithText(OutlinedButton, 'Edit'),
      );
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      expect(channel.readProfileSoulCalls, ['lifecycle-agent']);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'Lifecycle Renamed');
      await tester.enterText(fields.last, 'Updated persona.');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(channel.renameProfileCalls.single, {
        'profileId': 'lifecycle-agent',
        'name': 'Lifecycle Renamed',
        'revision': 'rev-new',
      });
      expect(channel.writeProfileSoulCalls.single, {
        'profileId': 'lifecycle-agent',
        'soul': 'Updated persona.',
        'revision': 'soul-1',
      });
      expect(find.text('Lifecycle Renamed'), findsOneWidget);

      final renamedCard = find.ancestor(
        of: find.text('Lifecycle Renamed'),
        matching: find.byType(Card),
      );
      final remove = find.descendant(
        of: renamedCard,
        matching: find.widgetWithText(TextButton, 'Delete profile'),
      );
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete profile').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Lifecycle Renamed');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete profile'));
      await tester.pumpAndSettle();

      expect(channel.deleteProfileCalls.single, {
        'profileId': 'lifecycle-agent',
        'revision': 'rev-next',
      });
      expect(find.text('Lifecycle Renamed'), findsNothing);
      expect(channel.state.selectedProfileId, 'default');
    },
  );

  testWidgets('connection errors are bounded and offer Chat recovery', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.error,
      errorMessage: 'private endpoint and server stack trace',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();

    expect(
      find.text('Profiles could not be loaded from Hermes.'),
      findsOneWidget,
    );
    expect(find.textContaining('private endpoint'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Open chat'), findsOneWidget);
  });

  testWidgets(
    'disconnected channel shows a neutral select-gateway prompt, not the '
    'unavailable lock state',
    (tester) async {
      final channel = FakeHermesChannel.disconnected();
      addTearDown(channel.dispose);

      await tester.pumpWidget(_profilesTestApp(channel));
      await tester.pumpAndSettle();

      expect(find.text('Select a gateway'), findsOneWidget);
      expect(find.text('Profiles unavailable'), findsNothing);
    },
  );

  testWidgets('gateway picker activates the selected gateway', (tester) async {
    final channel = FakeHermesChannel.disconnected();
    addTearDown(channel.dispose);
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(id: 'alpha', label: 'Alpha', baseUrl: 'https://a'),
        HermesEndpointConfig(id: 'beta', label: 'Beta', baseUrl: 'https://b'),
      ],
      loader: FakeGatewaySummaryLoader({
        'alpha': gatewaySummary(['default']),
        'beta': gatewaySummary(['default']),
      }),
      activeChannel: channel,
    );
    await directory.refresh();

    await tester.pumpWidget(_profilesTestApp(channel, directory: directory));
    await tester.pumpAndSettle();
    expect(channel.connectCalls, isEmpty);
    await tester.tap(find.text('Connect chat'));
    await tester.pumpAndSettle();
    expect(channel.connectCalls.single.baseUrl, 'https://a');
    channel.connectCalls.clear();
    await tester.tap(find.byKey(const ValueKey('agents-gateway-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beta').last);
    await tester.pumpAndSettle();

    expect(channel.connectCalls.single.baseUrl, 'https://b');
    expect(directory.activeContactId?.gatewayId, 'beta');
  });

  testWidgets('write access opens the create-agent editor', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const [
        'profiles:read',
        'profiles:write',
      ]),
      profiles: const [
        HermesProfile(
          id: 'default',
          displayName: 'Hermes One',
          revision: 'rev-default',
        ),
      ],
      selectedProfileId: 'default',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Create profile'), findsOneWidget);
    expect(find.text('Clone from'), findsOneWidget);
  });

  testWidgets('read-only profile token hides mutation actions', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const ['profiles:read']),
      profiles: const [
        HermesProfile(
          id: 'coder',
          displayName: 'Coding Agent',
          revision: 'rev-1',
          skillsCount: 4,
        ),
      ],
      selectedProfileId: 'coder',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();

    expect(find.text('Coding Agent'), findsOneWidget);
    expect(find.text('ID: coder'), findsOneWidget);
    expect(find.text('Active chat'), findsOneWidget);
    expect(find.text('New Profile'), findsNothing);
    expect(find.text('Delete profile'), findsNothing);
    expect(find.text('Edit'), findsNothing);
  });

  testWidgets('Agent name placeholders enable profile editing', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const [
        'profiles:read',
        'profiles:write',
      ]),
      profiles: const [
        HermesProfile(id: 'coder', displayName: 'Coding Agent', revision: 'c'),
      ],
      selectedProfileId: 'coder',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(OutlinedButton, 'Edit'), findsOneWidget);
    expect(find.text('Delete profile'), findsOneWidget);
    expect(find.bySemanticsLabel('Chat with Coding Agent'), findsOneWidget);
    expect(find.bySemanticsLabel('Edit Coding Agent'), findsOneWidget);
    expect(find.bySemanticsLabel('Delete Coding Agent'), findsOneWidget);
  });

  testWidgets('edit sheet respects a missing profile delete endpoint', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const [
        'profiles:read',
        'profiles:write',
      ], advertisesDelete: false),
      profiles: const [
        HermesProfile(id: 'coder', displayName: 'Coding Agent', revision: 'c'),
      ],
      selectedProfileId: 'coder',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Delete profile'), findsNothing);
  });

  testWidgets('shows a loading indicator while connecting', (tester) async {
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.connecting,
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pump();

    expect(find.byType(WingSkeletonList), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(WingSkeletonList)).label,
      contains('Loading profiles'),
    );
  });

  testWidgets('shows a connection error when the channel is in error', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.error,
      errorMessage: 'boom',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();

    expect(
      find.text('Profiles could not be loaded from Hermes.'),
      findsOneWidget,
    );
  });

  testWidgets('shows an unavailable message without profile access', (
    tester,
  ) async {
    final channel = FakeHermesChannel(capabilities: null);
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();

    expect(find.text('Profiles unavailable'), findsOneWidget);
  });

  testWidgets('shows an empty state with read access but no agents', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const ['profiles:read']),
      profiles: const [],
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();

    expect(find.text('No profiles available'), findsOneWidget);
  });

  testWidgets('seeds the default profile as selected on mount', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const ['profiles:read']),
      profiles: const [
        HermesProfile(id: 'default', displayName: 'Hermes One', revision: 'd'),
        HermesProfile(id: 'coder', displayName: 'Coding Agent', revision: 'c'),
      ],
      // Nothing explicitly selected yet.
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();

    // Exactly one row is marked selected, and it is the default agent.
    expect(find.text('Active chat'), findsOneWidget);
    final selectedCard = find.ancestor(
      of: find.text('Active chat'),
      matching: find.byType(Card),
    );
    expect(
      find.descendant(of: selectedCard, matching: find.text('Hermes One')),
      findsOneWidget,
    );
  });

  testWidgets('uses a compact two-column profile layout on wide screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const ['profiles:read']),
      profiles: const [
        HermesProfile(id: 'default', displayName: 'Hermes One', revision: 'd'),
        HermesProfile(id: 'coder', displayName: 'Coding Agent', revision: 'c'),
        HermesProfile(
          id: 'writer',
          displayName: 'Writing Agent',
          revision: 'w',
        ),
      ],
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();

    final cards = find.byType(Card);
    expect(cards, findsNWidgets(3));
    expect(
      tester.getTopLeft(cards.at(1)).dx,
      greaterThan(tester.getTopLeft(cards.at(0)).dx),
    );
    expect(
      tester.getTopLeft(cards.at(2)).dy,
      greaterThan(tester.getTopLeft(cards.at(0)).dy),
    );
  });

  testWidgets('marks the selected agent with a selected semantics node', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const ['profiles:read']),
      profiles: const [
        HermesProfile(id: 'coder', displayName: 'Coding Agent', revision: 'c'),
      ],
      selectedProfileId: 'coder',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && (widget.properties.selected ?? false),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the default agent cannot be deleted from the list', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const [
        'profiles:read',
        'profiles:write',
      ]),
      profiles: const [
        HermesProfile(id: 'default', displayName: 'Hermes One', revision: 'd'),
        HermesProfile(id: 'coder', displayName: 'Coding Agent', revision: 'c'),
      ],
      selectedProfileId: 'default',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();

    // Only the non-default agent exposes a delete affordance.
    expect(find.text('Delete profile'), findsOneWidget);
    expect(find.text('New Profile'), findsOneWidget);
  });

  testWidgets('tapping Chat selects the profile client-side', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const ['profiles:read']),
      profiles: const [
        HermesProfile(id: 'default', displayName: 'Hermes One', revision: 'd'),
        HermesProfile(id: 'coder', displayName: 'Coding Agent', revision: 'c'),
      ],
      selectedProfileId: 'default',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();

    final coderChat = find.widgetWithText(FilledButton, 'Chat').last;
    await tester.ensureVisible(coderChat);
    await tester.pumpAndSettle();
    await tester.tap(coderChat);
    await tester.pumpAndSettle();

    expect(channel.selectProfileCalls, ['coder']);
  });

  testWidgets('failed profile selection is announced and remains recoverable', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const ['profiles:read']),
      profiles: const [
        HermesProfile(id: 'default', displayName: 'Hermes One', revision: 'd'),
        HermesProfile(id: 'coder', displayName: 'Coding Agent', revision: 'c'),
      ],
      selectedProfileId: 'default',
      selectProfileFails: true,
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();
    final coderChat = find.widgetWithText(FilledButton, 'Chat').last;
    await tester.ensureVisible(coderChat);
    await tester.pumpAndSettle();
    await tester.tap(coderChat);
    await tester.pumpAndSettle();

    final error = find.text('Hermes could not complete that profile change.');
    expect(error, findsOneWidget);
    expect(tester.getSemantics(error).flagsCollection.isLiveRegion, isTrue);
    expect(find.text('Coding Agent'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Chat opens the selected profile in chat', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const ['profiles:read']),
      profiles: const [
        HermesProfile(id: 'default', displayName: 'Hermes One', revision: 'd'),
        HermesProfile(id: 'coder', displayName: 'Coding Agent', revision: 'c'),
      ],
      selectedProfileId: 'default',
    );
    addTearDown(channel.dispose);
    final router = GoRouter(
      initialLocation: AppRoutes.agents,
      routes: [
        GoRoute(
          path: AppRoutes.agents,
          builder: (_, _) => const ProfilesScreen(),
        ),
        GoRoute(
          path: AppRoutes.hermes,
          builder: (_, _) => const Scaffold(body: Text('Chat destination')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesGatewayDirectoryProvider.overrideWith(
            (ref) => directoryFor(
              configs: const [],
              loader: FakeGatewaySummaryLoader(const {}),
              activeChannel: channel,
            ),
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final coderChat = find.widgetWithText(FilledButton, 'Chat').last;
    await tester.ensureVisible(coderChat);
    await tester.pumpAndSettle();
    await tester.tap(coderChat);
    await tester.pumpAndSettle();

    expect(channel.selectProfileCalls, ['coder']);
    expect(find.text('Chat destination'), findsOneWidget);
  });

  testWidgets('Android Back returns from profile chat to the profile list', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const ['profiles:read']),
      profiles: const [
        HermesProfile(id: 'coder', displayName: 'Coding Agent', revision: 'c'),
      ],
      selectedProfileId: 'coder',
    );
    addTearDown(channel.dispose);
    final router = GoRouter(
      initialLocation: AppRoutes.agents,
      routes: [
        GoRoute(
          path: AppRoutes.agents,
          builder: (_, _) => const ProfilesScreen(),
        ),
        GoRoute(
          path: AppRoutes.hermes,
          builder: (_, _) => const Scaffold(body: Text('Chat destination')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesGatewayDirectoryProvider.overrideWith(
            (ref) => directoryFor(
              configs: const [],
              loader: FakeGatewaySummaryLoader(const {}),
              activeChannel: channel,
            ),
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Chat'));
    await tester.pumpAndSettle();
    expect(find.text('Chat destination'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Profiles'), findsWidgets);
    expect(find.text('Coding Agent'), findsOneWidget);
  });

  testWidgets('rapid Chat taps push only one route', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const ['profiles:read']),
      profiles: const [
        HermesProfile(id: 'default', displayName: 'Hermes One', revision: 'd'),
      ],
      selectedProfileId: 'default',
    );
    addTearDown(channel.dispose);
    final router = GoRouter(
      initialLocation: AppRoutes.agents,
      routes: [
        GoRoute(
          path: AppRoutes.agents,
          builder: (_, _) => const ProfilesScreen(),
        ),
        GoRoute(
          path: AppRoutes.hermes,
          builder: (_, _) => const Scaffold(body: Text('Chat destination')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesGatewayDirectoryProvider.overrideWith(
            (ref) => directoryFor(
              configs: const [],
              loader: FakeGatewaySummaryLoader(const {}),
              activeChannel: channel,
            ),
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final chat = find.widgetWithText(FilledButton, 'Chat');

    await tester.tap(chat);
    await tester.tap(chat, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Chat destination'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Profiles'), findsWidgets);
    expect(find.text('Hermes One'), findsOneWidget);
  });

  testWidgets('shows progress and blocks repeat taps while switching agents', (
    tester,
  ) async {
    final channel = _GatedProfileSelectionChannel(
      capabilities: _profileCapabilities(const ['profiles:read']),
      profiles: const [
        HermesProfile(id: 'coder', displayName: 'Coding Agent', revision: 'c'),
      ],
      selectedProfileId: 'default',
    );
    addTearDown(() {
      if (!channel.selectionGate.isCompleted) channel.selectionGate.complete();
      channel.dispose();
    });

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();

    final coderChat = find.widgetWithText(FilledButton, 'Chat').last;
    await tester.scrollUntilVisible(
      coderChat,
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(coderChat);
    await tester.pump();

    expect(channel.selectionAttempts, 1);
    expect(find.text('Switching…'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Switching…'))
          .onPressed,
      isNull,
    );

    channel.selectionGate.complete();
    await tester.pumpAndSettle();

    expect(find.text('Switching…'), findsNothing);
    expect(channel.selectProfileCalls, ['coder']);
  });

  testWidgets('rename updates the visible display name', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const [
        'profiles:read',
        'profiles:write',
      ]),
      profiles: const [
        HermesProfile(id: 'coder', displayName: 'Coding Agent', revision: 'c'),
      ],
      selectedProfileId: 'coder',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Renamed Coder');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(channel.renameProfileCalls, [
      {'profileId': 'coder', 'name': 'Renamed Coder', 'revision': 'c'},
    ]);
    expect(find.text('Renamed Coder'), findsOneWidget);
  });

  testWidgets('retains content and actions at 200% text scale', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const [
        'profiles:read',
        'profiles:write',
      ]),
      profiles: const [
        HermesProfile(
          id: 'coder',
          displayName: 'Coding Agent with a longer profile name',
          revision: 'c',
          skillsCount: 4,
        ),
      ],
      selectedProfileId: 'coder',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel, textScale: 2.0));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Coding Agent with a longer profile name'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );

    expect(tester.takeException(), isNull);
    expect(
      find.text('Coding Agent with a longer profile name'),
      findsOneWidget,
    );
    expect(find.text('New Profile'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
  });
}
