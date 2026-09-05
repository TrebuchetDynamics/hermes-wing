import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/core/wing_link/wing_link_client.dart';
import 'package:wing/features/enrollment/providers/hermes_enrollment_provider.dart';
import 'package:wing/features/enrollment/screens/hermes_enrollment_screen.dart';
import 'package:wing/features/enrollment/services/hermes_connect_intent_source.dart';
import 'package:wing/features/gateway/screens/gateway_screen.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/local_setup/screens/termux_hermes_setup_screen.dart';
import 'package:wing/features/profiles/widgets/profile_directory_browser_sheet.dart';
import 'package:wing/features/providers/screens/providers_screen.dart';
import 'package:wing/features/schedules/screens/schedules_screen.dart';
import 'package:wing/features/settings/providers/theme_settings_provider.dart';
import 'package:wing/features/settings/screens/settings_screen.dart';
import 'package:wing/features/soul/screens/soul_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/features/voice/services/platform/device_speech_recognition_availability.dart';
import 'package:wing/router/app_router.dart';
import 'package:wing/theme/wing_theme.dart';

import '../test/features/hermes_chat/support/fake_hermes_endpoint_store.dart';
import '../test/features/hermes_chat/support/fake_hermes_gateway_directory.dart';
import 'support/maestro/feature_channel.dart';
import 'support/maestro/interaction_fixture.dart';

String _randomFixtureValue() => base64Url.encode(
  List<int>.generate(24, (_) => Random.secure().nextInt(256)),
);

class _FixtureIntents implements HermesConnectIntentSource {
  String mode = 'valid';
  String payload() => mode == 'invalid'
      ? 'invalid fixture handoff'
      : Uri(
          scheme: 'wing',
          host: 'connect',
          queryParameters: {
            'origin': 'https://fixture.example',
            'code': _randomFixtureValue(),
          },
        ).toString();
  @override
  Future<String?> initialPayload() async => null;
  @override
  Future<String?> consumeInitialPayload() async => null;
  @override
  Future<String?> scanQrCode() async => payload();
  @override
  Future<String?> importQrImage() async => payload();
  @override
  Stream<String> payloadEvents() => const Stream.empty();
}

const _fingerprint = 'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final fixture = FeatureFixture();
  await fixture.initialize();
  runApp(
    ProviderScope(
      overrides: [
        hermesChannelProvider.overrideWithValue(fixture.channel),
        hermesAttachmentPickerProvider.overrideWithValue(
          fixture.interactions.pick,
        ),
        hermesGatewayDirectoryProvider.overrideWith((ref) => fixture.directory),
        hermesEndpointStoreProvider.overrideWithValue(fixture.store),
        hermesConnectIntentSourceProvider.overrideWithValue(fixture.intents),
        hermesEnrollmentControllerProvider.overrideWith(
          (ref) => fixture.enrollment(),
        ),
        routerProvider.overrideWithValue(fixture.router),
      ],
      child: _FixtureApp(fixture: fixture),
    ),
  );
}

/// Only this test entrypoint contains the scenario controls. Every destination
/// below is a production screen; no control is compiled into lib/main.dart.
class FeatureFixture {
  final channel = MaestroFeatureChannel();
  final interactions = InteractionFixture();
  final store = FakeHermesEndpointStore();
  final intents = _FixtureIntents();
  late HermesGatewayDirectory directory;
  late GoRouter router;
  final scale = ValueNotifier<double>(1);
  String trustMode = 'valid';
  bool revoked = false;
  bool grantRevoked = false;
  int directoryPages = 0;
  int exchanges = 0;
  bool diagnosticsClipboardSafe = false;
  bool? microphonePermissionGranted;

  Future<void> initialize() async {
    directory = directoryFor(
      configs: [
        HermesEndpointConfig(
          id: 'fixture',
          label: 'Fixture gateway',
          baseUrl: 'https://fixture.example',
          wingLinkOrigin: 'https://management.example',
          wingLinkToken: _randomFixtureValue(),
          wingLinkHostFingerprint: _fingerprint,
          wingLinkDeviceId: 'cred_fixture',
        ),
        const HermesEndpointConfig(
          id: 'secondary',
          label: 'Secondary fixture',
          baseUrl: 'https://secondary.example',
        ),
      ],
      loader: FakeGatewaySummaryLoader({
        'fixture': gatewaySummary(['default']),
        'secondary': gatewaySummary(['default']),
      }),
      activeChannel: channel,
    );
    await directory.refresh();
    await directory.activateGateway('fixture');
    await channel.selectSession('sess_1');
    router = GoRouter(
      initialLocation: '/qa',
      routes: [
        GoRoute(path: '/qa', builder: (context, state) => _hub(context)),
        for (final route in <String, Widget>{
          '/providers': const ProvidersScreen(),
          '/soul': const SoulScreen(),
          '/settings': const SettingsScreen(),
          '/settings/voice': const VoiceSettingsScreen(),
          '/settings/diagnostics': const DiagnosticsSettingsScreen(),
          '/tasks': const SchedulesScreen(),
          '/hermes': const HermesChatScreen(),
          '/enroll': const HermesEnrollmentScreen(),
          '/setup/local': const TermuxHermesSetupScreen(),
        }.entries)
          GoRoute(path: route.key, builder: (_, _) => route.value),
        GoRoute(
          path: '/gateway',
          builder: (_, _) =>
              GatewayScreen(wingLinkClientBuilder: (_) => trustClient()),
        ),
      ],
    );
  }

  HermesEnrollmentController enrollment() => HermesEnrollmentController(
    endpointStore: store,
    inspectEnrollment: ({required origin, required code}) async =>
        HermesEnrollmentPreview(
          label: 'Fixture enrollment',
          origin: origin.toString(),
          scopes: const ['chat:write'],
          expiresAt: intents.mode == 'expired'
              ? DateTime.utc(2000)
              : DateTime.now().add(const Duration(minutes: 5)),
        ),
    exchangeEnrollment: ({required origin, required code}) async {
      exchanges++;
      if (intents.mode == 'used') throw StateError('fixture code already used');
      return HermesIssuedOperatorToken(
        token: _randomFixtureValue(),
        label: 'Fixture enrollment',
        credentialId: 'hoc_fixture',
      );
    },
  );

  WingLinkClient trustClient() => WingLinkClient(
    origin: Uri.parse('https://management.example'),
    token: _randomFixtureValue(),
    hostFingerprint: _fingerprint,
    get: (uri, headers) async {
      if (trustMode == 'expired') throw const WingLinkHttpException(401);
      if (trustMode == 'upgrade') throw const WingLinkUpgradeRequired();
      return jsonEncode(
        uri.path == '/meta'
            ? {
                'protocol_generation': 2,
                'minimum_protocol_generation': 1,
                'supported_protocol_generations': [1, 2],
                'version': 'fixture',
                'host_fingerprint': trustMode == 'changed'
                    ? 'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'
                    : _fingerprint,
                'capabilities': ['device.self.read'],
              }
            : {
                'device_id': 'cred_fixture',
                'name': 'Fixture device',
                'scopes': ['health.read', 'profile.read'],
                'created_at': '2026-01-01T00:00:00Z',
                'legacy': false,
              },
      );
    },
    delete: (uri, headers) async {
      revoked = true;
      return '';
    },
  );

  Future<void> browse(BuildContext context) => showProfileDirectoryBrowser(
    context,
    loadRoots: () async => grantRevoked
        ? []
        : const [
            WingLinkDirectory(
              handle: 'dirh_rootAAAAAAAAAAAAAAAAAA',
              name: 'Fixture root',
            ),
          ],
    loadChildren: (handle, offset) async {
      if (grantRevoked) throw StateError('fixture grant revoked');
      directoryPages++;
      if (handle != 'dirh_rootAAAAAAAAAAAAAAAAAA') {
        return const WingLinkDirectoryPage(directories: []);
      }
      return WingLinkDirectoryPage(
        directories: [
          WingLinkDirectory(
            handle: offset == 0
                ? 'dirh_childAAAAAAAAAAAAAAAAA'
                : 'dirh_childBBBBBBBBBBBBBBBBB',
            name: offset == 0 ? 'Fixture folder one' : 'Fixture folder two',
          ),
        ],
        nextOffset: offset == 0 ? 1 : null,
      );
    },
  );

  Widget _hub(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Maestro fixture')),
    body: ListView(
      children: [
        for (final entry in const <String, String>{
          'Providers fixture': '/providers',
          'SOUL fixture': '/soul',
          'Gateway fixture': '/gateway',
          'Settings fixture': '/settings',
          'Voice settings fixture': '/settings/voice',
          'Diagnostics fixture': '/settings/diagnostics',
          'Schedules fixture': '/tasks',
          'Chat fixture': '/hermes',
          'Pairing fixture': '/enroll',
          'Local setup fixture': '/setup/local',
        }.entries)
          ListTile(
            title: Text(entry.key),
            onTap: () => context.push(entry.value),
          ),
        ListTile(
          title: const Text('Directories fixture'),
          onTap: () => browse(context),
        ),
      ],
    ),
  );

  Future<void> controls() async {
    // Fixture inspection must not restore the chat IME behind the dialog.
    FocusManager.instance.primaryFocus?.unfocus();
    final context = router.routerDelegate.navigatorKey.currentContext!;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fixture controls'),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Credential writes: ${channel.setProviderCredentialCalls.length}',
                ),
                Text(
                  'Credential removals: ${channel.removeProviderCredentialCalls.length}',
                ),
                Text('Model attempts: ${channel.modelAttempts}'),
                Text('Model writes: ${channel.assignModelCalls.length}'),
                Text('Persona writes: ${channel.soulWrites}'),
                Text('Deleted sessions: ${channel.deleteSessionCalls.length}'),
                Text('Submitted turns: ${channel.submittedTurns}'),
                Text(
                  'Approval decisions: ${channel.respondToApprovalCalls.length}',
                ),
                Text('Directory pages: $directoryPages'),
                Text('Enrollment exchanges: $exchanges'),
                Text('Management revoked: $revoked'),
                Text('Diagnostics clipboard safe: $diagnosticsClipboardSafe'),
                Text(
                  'Microphone permission granted: $microphonePermissionGranted',
                ),
                Text(
                  'Native spellcheck: ${WidgetsBinding.instance.platformDispatcher.nativeSpellCheckServiceDefined}',
                ),
                Text(
                  'Secondary saved: ${directory.configForGateway('secondary') != null}',
                ),
                Text(
                  'Secondary updated: ${directory.configForGateway('secondary')?.baseUrl == 'https://updated.example'}',
                ),
                Text(
                  'Secondary credential present: ${directory.configForGateway('secondary')?.apiKey?.isNotEmpty == true}',
                ),
                Text('Picker calls: ${interactions.pickerCalls}'),
                Text('Emoji submitted: ${channel.emojiSubmitted}'),
                Text('Text attachment sent: ${channel.textAttachmentSent}'),
                Text('Image attachment sent: ${channel.imageAttachmentSent}'),
                Text('Text export matches: ${interactions.textExportMatches}'),
                Text(
                  'Markdown export matches: ${interactions.markdownExportMatches}',
                ),
                Text('Group saved: ${interactions.groupSaved}'),
                Text('Group moved: ${interactions.groupMoved}'),
                Text('Group deleted: ${interactions.groupDeleted}'),
                for (final action in <String, FutureOr<void> Function()>{
                  for (final mode in [
                    'text',
                    'image',
                    'binary',
                    'oversize',
                    'invalid',
                    'cancel',
                    'deferred',
                  ])
                    'Pick $mode fixture': () => interactions.pickerMode = mode,
                  'Complete fixture picker': interactions.completePick,
                  'Select first session': () => channel.selectSession('sess_1'),
                  'Select second session': () =>
                      channel.selectSession('sess_2'),
                  'Select draft profile': () async {
                    if (!channel.state.profiles.any(
                      (p) => p.id == 'draft-profile',
                    )) {
                      await channel.createProfile(name: 'draft-profile');
                    }
                    await channel.selectProfile('draft-profile');
                  },
                  'Select default profile': () =>
                      channel.selectProfile('default'),
                  'Check transcript clipboard': interactions.checkExport,
                  'Check persisted groups': interactions.checkGroups,
                  'Inject revision conflict': () => channel.conflictNext = true,
                  'Revoke write grants': channel.revokeWrites,
                  'Fail schedule refresh': () => channel.failJobs = true,
                  'Restore schedule refresh': () => channel.failJobs = false,
                  'Revoke directory grant': () => grantRevoked = true,
                  'Disconnect fixture': () => channel.setOffline(true),
                  'Reconnect fixture': () => channel.setOffline(false),
                  'Enable session pagination': () =>
                      channel.setSessionPagination(hasMore: true),
                  'Enable earlier history': () {
                    channel.earlierAvailable = true;
                    channel.notifyListeners();
                  },
                  'Use large text': () => scale.value = 2,
                  'Use normal text': () => scale.value = 1,
                  'Changed host identity': () => trustMode = 'changed',
                  'Expired device credential': () => trustMode = 'expired',
                  'Unsupported protocol': () => trustMode = 'upgrade',
                  'Invalid pairing input': () => intents.mode = 'invalid',
                  'Expired pairing input': () => intents.mode = 'expired',
                  'Used pairing input': () => intents.mode = 'used',
                  'Valid pairing input': () => intents.mode = 'valid',
                  'Prepare fixture paste': () =>
                      Clipboard.setData(ClipboardData(text: intents.payload())),
                  'Check microphone permission': () async {
                    microphonePermissionGranted =
                        (await const MethodChannelDeviceSpeechRecognitionDiagnosticsProbe()
                                .read())
                            .microphonePermissionGranted;
                  },
                  'Check diagnostics clipboard': () async {
                    final text = (await Clipboard.getData(
                      Clipboard.kTextPlain,
                    ))?.text;
                    final credential = directory
                        .configForGateway('fixture')
                        ?.wingLinkToken;
                    diagnosticsClipboardSafe =
                        text != null &&
                        text.length < 8192 &&
                        text.startsWith('Hermes Wing diagnostics') &&
                        text.contains('Secrets: excluded') &&
                        (credential == null || !text.contains(credential)) &&
                        !text.contains('fixture-only-input') &&
                        !text.contains('Fixture initial persona');
                  },
                }.entries)
                  TextButton(
                    onPressed: () async {
                      await action.value();
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Text(action.key),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close controls'),
          ),
        ],
      ),
    );
  }
}

class _FixtureApp extends ConsumerWidget {
  const _FixtureApp({required this.fixture});
  final FeatureFixture fixture;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(wingThemeSettingsProvider);
    return MaterialApp.router(
      title: 'Hermes Wing Maestro fixture',
      routerConfig: fixture.router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: wingLightTheme,
      darkTheme: wingDarkTheme,
      themeMode: appearance.mode,
      builder: (context, child) => ValueListenableBuilder<double>(
        valueListenable: fixture.scale,
        builder: (context, scale, _) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: Column(
            children: [
              Expanded(child: child!),
              SafeArea(
                top: false,
                child: Material(
                  child: Wrap(
                    children: [
                      TextButton(
                        onPressed: fixture.controls,
                        child: const Text('Fixture controls'),
                      ),
                      TextButton(
                        onPressed: () => fixture.router.go('/qa'),
                        child: const Text('Fixture home'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
