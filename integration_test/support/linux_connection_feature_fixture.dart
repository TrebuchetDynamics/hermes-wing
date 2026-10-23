import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/core/hermes/client/hermes_api_config.dart';
import 'package:wing/core/hermes/local_discovery/local_hermes_home_discovery.dart';
import 'package:wing/core/hermes/ssh/managed_ssh.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/providers/managed_ssh_connection_controller.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/hermes_chat/widgets/platform_local_connection_panel.dart';
import 'package:wing/l10n/app_localizations.dart';

import 'direct_first_run_native_fixture.dart';
import 'remote_connection_retry_native_fixture.dart';

Finder connectionControl(String name) => find.byKey(ValueKey(name));

/// Synthetic transport only; channel, connection form and directory stay real.
/// No socket or real credential is accepted. Receipts contain counts, not values.
class LinuxConnectionFeatureFixture extends RemoteConnectionRetryNativeFixture {
  final configurations = <HermesApiConfig>[];
  final readOrigins = <String>[];
  final authorizationKinds = <String>[];

  @override
  HermesApiClient client(HermesApiConfig config) {
    if (!{
      DirectFirstRunNativeFixture.origin,
      'https://other.example.invalid',
    }.contains(config.baseUri.origin)) {
      throw StateError('Only disposable synthetic origins permitted');
    }
    configurations.add(config);
    return super.client(config);
  }

  @override
  Future<String> get(Uri uri, Map<String, String> headers) {
    readOrigins.add(uri.origin);
    final auth = headers['Authorization'];
    authorizationKinds.add(switch (auth) {
      null => 'absent',
      'Bearer synthetic-original' => 'original',
      'Bearer synthetic-replacement' => 'replacement',
      _ => 'unexpected',
    });
    if (auth != null &&
        auth != 'Bearer synthetic-original' &&
        auth != 'Bearer synthetic-replacement') {
      throw StateError('Only synthetic authorization permitted');
    }
    return super.get(uri, {
      for (final entry in headers.entries)
        if (entry.key != 'Authorization') entry.key: entry.value,
    });
  }
}

/// Metadata and picker fault injection, not native chooser acquisition.
class ConnectionHomeMetadata implements LocalHermesHomePlatform {
  final inspections = <String>[];
  LocalHermesHomeStatus? denied;
  @override
  bool get isSupported => true;
  @override
  String get userHome => '/synthetic';
  @override
  Future<LocalHermesHomeInspection> inspectDirectory(String path) async {
    inspections.add(path);
    return denied == null
        ? LocalHermesHomeInspection.directory(path)
        : LocalHermesHomeInspection.unavailable(denied!);
  }
}

/// Stops at the real controller's host-review seam; never opens SSH or Agent.
class ConnectionTrustForward extends ManagedSshForward {
  int attempts = 0;
  int reviews = 0;
  int cancellations = 0;
  bool? accepted;

  @override
  Future<ManagedSshTunnel> connect({
    required ManagedSshConfig configuration,
    required ManagedSshCredentials authentication,
    ManagedSshHostKeyVerifier? verifyHostKey,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    attempts++;
    reviews++;
    accepted = await verifyHostKey!(
      configuration,
      ManagedSshHostKey('ssh-ed25519', List.filled(32, 7)),
    );
    // No positive connection is synthesized, even if the trust fence regresses.
    throw const ManagedSshException(ManagedSshFailure.hostKeyRejected);
  }

  @override
  Future<void> disconnect() async => cancellations++;
}

class LinuxConnectionHarness {
  final fixture = LinuxConnectionFeatureFixture();
  final store = RetryNativeStore();
  final home = ConnectionHomeMetadata();
  late final channel = RetryNativeChannel(fixture);
  late final directory = HermesGatewayDirectory(
    store: store,
    cache: GatewayContactCache(),
    loader: HermesApiGatewaySummaryLoader(clientBuilder: fixture.client),
    activeChannel: channel,
  );
  late ProviderContainer container;
  late List<Override> overrides;
  Future<String?> Function() picker = () async => null;

  Future<void> mount(
    WidgetTester tester, {
    ManagedSshConnectionController? ssh,
    HermesConnectionMode mode = HermesConnectionMode.local,
  }) async {
    overrides = [
      hermesChannelProvider.overrideWith((_) => channel),
      hermesEndpointStoreProvider.overrideWithValue(store),
      hermesEndpointTestClientProvider.overrideWithValue(fixture.client),
      hermesGatewayDirectoryProvider.overrideWith((_) => directory),
      platformLocalHomeDiscoveryProvider.overrideWithValue(
        LocalHermesHomeDiscovery(platform: home),
      ),
      platformLocalDirectoryPickerProvider.overrideWithValue(() => picker()),
      if (ssh != null)
        managedSshConnectionControllerProvider.overrideWithValue(ssh),
      hermesVoiceCaptureServiceProvider.overrideWithValue(null),
      hermesTextToSpeechServiceProvider.overrideWithValue(null),
    ];
    container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(
            initiallyEditingConnection: true,
            initialConnectionMode: mode,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void replaceSsh(ManagedSshConnectionController controller) {
    overrides = [
      ...overrides.where(
        (override) => override.origin != managedSshConnectionControllerProvider,
      ),
      managedSshConnectionControllerProvider.overrideWithValue(controller),
    ];
    container.updateOverrides(overrides);
  }

  Future<void> activate(WidgetTester tester, String name) async {
    await tester.ensureVisible(connectionControl(name));
    await tester.tap(connectionControl(name));
    await tester.pumpAndSettle();
  }

  Future<void> edit(WidgetTester tester, String name, String value) async {
    await tester.ensureVisible(connectionControl(name));
    await tester.enterText(connectionControl(name), value);
    await tester.pumpAndSettle();
  }
}

/// One terminal inventory, published only after all public-control cases pass.
/// Driver observation binds these rows to this still-running GTK process.
class LinuxConnectionCases {
  LinuxConnectionCases()
    : root = Platform.environment['WING_LINUX_TEST_ROOT'] ?? '' {
    final directory = Directory(root);
    if (!Platform.isLinux ||
        !directory.existsSync() ||
        directory.resolveSymbolicLinksSync() != root ||
        directory.parent.resolveSymbolicLinksSync() !=
            Directory.systemTemp.resolveSymbolicLinksSync() ||
        !RegExp(r'^wing-linux-qualification-[a-zA-Z0-9_-]+$').hasMatch(
          directory.uri.pathSegments.where((s) => s.isNotEmpty).last,
        ) ||
        !File('$root/.wing-linux-test-owner').existsSync() ||
        Platform.environment['XDG_CONFIG_HOME'] != '$root/config' ||
        Platform.environment['HOME'] != '$root/home' ||
        Platform.environment['XDG_DATA_HOME'] != '$root/data' ||
        Platform.environment['XDG_CACHE_HOME'] != '$root/cache' ||
        Platform.environment['DBUS_SESSION_BUS_ADDRESS'] == null) {
      throw StateError('Owned GTK/D-Bus campaign environment required');
    }
  }
  final String root;
  final rows = <Map<String, Object>>[];

  void record(
    String id,
    List<String> features,
    Map<String, int> operations, {
    int owners = 1,
    bool unsupported = false,
    String? reason,
  }) {
    rows.add({
      'id': id,
      'feature_ids': features,
      'route_ids': ['/hermes/add'],
      'backend': 'production-api-channel/synthetic-read-transport',
      'input': 'framework-public-controls',
      'storage': 'in-memory-endpoint-and-trust-fault-injection',
      'status': unsupported ? 'unsupported' : 'pass',
      if (unsupported) 'negative_assertion': true,
      'skip_reason': ?reason,
      'native_pid': pid,
      'owner_count': owners,
      'operation_counts': operations,
    });
  }

  Future<void> publish(WidgetTester tester) async {
    expect(rows.map((row) => row['id']).toSet().length, 5);
    final target = File('$root/feature-cases.json');
    final temporary = File('${target.path}.partial');
    temporary.writeAsStringSync(
      jsonEncode({'schema': 1, 'cases': rows}),
      flush: true,
    );
    temporary.renameSync(target.path);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 2)),
    );
  }
}
