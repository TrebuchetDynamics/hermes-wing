import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/core/hermes/client/hermes_api_config.dart';
import 'package:wing/core/hermes/client/hermes_api_transport.dart';
import 'package:wing/core/hermes/policy/hermes_transport_policy.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/channel/hermes_approval_request.dart';
import 'package:wing/core/hermes/client/platform/hermes_api_transport_io.dart'
    as io_transport;
import 'package:wing/core/hermes/models/hermes_run.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/hermes_chat/widgets/session_model_picker_sheet.dart';
import 'package:wing/l10n/app_localizations.dart';

// First live-qualification slice: actual authenticated production reads only.
// Do not connect the channel here: qualify only explicitly approved reads.
// This target does not qualify generation, approvals, Stop or relaunch.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  if (Platform.environment['WING_LIVE_PHASE'] != null) {
    _journeyMain();
    return;
  }
  testWidgets('isolated production Agent readiness without mutations', (
    tester,
  ) async {
    final raw = Platform.environment['WING_LIVE_AUTH'];
    final root = Platform.environment['WING_LIVE_ROOT'];
    if (raw == null || root == null) {
      fail(
        'Use scripts/run_linux_desktop_live_workflow.sh --native-read-only.',
      );
    }
    final owned = Directory(root).resolveSymbolicLinksSync();
    expect(owned.split('/').last, startsWith('wing-linux-live.'));
    expect(Platform.environment['HOME'], '$owned/home');
    expect(Platform.environment['XDG_CONFIG_HOME'], '$owned/config');
    expect(Platform.environment['DBUS_SESSION_BUS_ADDRESS'], isNull);
    final input = jsonDecode(raw) as Map<String, dynamic>;
    expect(input['mode'], 'read-only');
    expect(input['approved_disposable'], true);
    expect(input['approved_reads'], true);
    expect(input['provider'], 'openai-codex');
    expect(input['model'], 'gpt-6.1-sol');
    expect(
      input['expires_at'] as num,
      greaterThan(DateTime.now().millisecondsSinceEpoch / 1000),
    );
    final origin = Uri.parse(input['origin'] as String);
    expect(origin.scheme, 'http');
    expect(origin.host, '127.0.0.1');
    expect(origin.path, '/p/${input['profile']}');
    expect(origin.userInfo, isEmpty);
    expect(origin.query, isEmpty);
    expect(origin.fragment, isEmpty);
    final client = HermesApiClient(
      config: HermesApiConfig.fromBaseUrl(
        input['origin'] as String,
        apiKey: input['api_key'] as String,
      ),
      // Every mutation seam is denied before transport. A future caller cannot
      // accidentally spend inference or create replacement state during reads.
      post: unsupportedHermesApiPost,
      patch: unsupportedHermesApiPatch,
      put: unsupportedHermesApiPut,
      delete: unsupportedHermesApiDelete,
      postStream: unsupportedHermesApiPostStream,
    );
    try {
      final capabilities = await client.capabilities();
      final policy = HermesTransportPolicy(capabilities);
      expect(capabilities.supportsSchema, true);
      expect(capabilities.auth.required, true);
      expect(policy.supportsRunsTransport, true);
      expect(policy.supportsRunStatus, true);
      expect(policy.supportsRunApprovalResponse, true);
      expect(policy.supportsRunStop, true);
      final session = await client.getSession(input['session'] as String);
      expect(session.id, input['session']);
      await client.sessionMessagesPage(session.id, limit: 20);
      final options = await client.getModelOptions();
      expect(
        options.providers.any(
          (provider) =>
              provider.slug == 'openai-codex' &&
              provider.authenticated &&
              provider.models.contains('gpt-6.1-sol'),
        ),
        true,
      );
      // Authentication/model readiness is not inference readiness. No prompt,
      // content, endpoint, credential or exception text is emitted as evidence.
    } catch (_) {
      fail(
        'Production Agent readiness failed (details intentionally discarded).',
      );
    }
  });
}

/// Counts mutation attempts before transport, never refunds ambiguous failures.
/// This is not a provider-call meter: tool continuations remain server-owned.
class LiveWorkflowMutationBudget {
  LiveWorkflowMutationBudget({required this.session, required this.phase});
  final String session;
  final String phase;
  int submits = 0;
  int approvals = 0;
  int stops = 0;
  int locks = 0;
  String? run;
  String? request;
  bool armed = false;
  Map<String, int> get counts => {
    'submits': submits,
    'approvals': approvals,
    'stops': stops,
    'model_locks': locks,
  };

  void admit(String path, Map<String, dynamic> body) {
    if (!armed || !{'write', 'verify'}.contains(phase)) {
      throw StateError('No explicit mutation intent.');
    }
    if (path == '/api/sessions/$session/model' &&
        locks == 0 &&
        submits == 0 &&
        body['provider'] == 'openai-codex' &&
        body['model'] == 'gpt-6.1-sol') {
      locks++;
      return;
    }
    if (path == '/v1/runs' &&
        locks == 1 &&
        submits == 0 &&
        body['session_id'] == session) {
      submits++;
      return;
    }
    if (phase == 'write' &&
        run != null &&
        request != null &&
        path == '/v1/runs/$run/approval' &&
        approvals == 0 &&
        stops == 0 &&
        body['request_id'] == request &&
        body['choice'] == 'once' &&
        body['resolve_all'] != true) {
      approvals++;
      return;
    }
    if (phase == 'write' &&
        run != null &&
        path == '/v1/runs/$run/stop' &&
        submits == 1 &&
        stops == 0) {
      stops++;
      return;
    }
    throw StateError('Mutation outside qualification budget.');
  }
}

void _journeyMain() {
  testWidgets('prepared actual-Agent Chat journey and native relaunch', (
    tester,
  ) async {
    // Both entry points fail closed; invoking Flutter directly is not a bypass.
    requireQualifiedLiveBudget();
    final raw = Platform.environment['WING_LIVE_AUTH'];
    final root = Platform.environment['WING_LIVE_ROOT'];
    final phase = Platform.environment['WING_LIVE_PHASE'];
    if (raw == null ||
        root == null ||
        phase == null ||
        !{'write', 'verify'}.contains(phase)) {
      fail('Use the reviewed live-workflow launcher.');
    }
    final input = jsonDecode(raw) as Map<String, dynamic>;
    expect(input['mode'], 'live');
    expect(Platform.environment['HOME'], '$root/home');
    expect(Platform.environment['XDG_CONFIG_HOME'], '$root/config');
    final session = input['session'] as String;
    final profile = input['profile'] as String;
    final origin = Uri.parse(input['origin'] as String);
    expect(origin.host, '127.0.0.1');
    expect(origin.path, '/p/$profile');
    final budget = LiveWorkflowMutationBudget(session: session, phase: phase);
    final previous = phase == 'verify'
        ? jsonDecode(File('$root/cache/live-write.json').readAsStringSync())
              as Map<String, dynamic>
        : null;
    final store = _LiveEndpointStore(input);
    HermesApiClient buildClient(HermesApiConfig config) => HermesApiClient(
      config: config,
      post: (uri, headers, body) async {
        expect(uri.origin, origin.origin);
        expect(uri.path, startsWith(origin.path));
        final path = uri.path.substring(origin.path.length);
        budget.admit(path, jsonDecode(body) as Map<String, dynamic>);
        final response = await io_transport.defaultPost(uri, headers, body);
        if (path == '/v1/runs') {
          final run = HermesRun.fromJson(
            jsonDecode(response) as Map<String, Object?>,
          );
          expect(run.sessionId, session);
          expect(run.id, isNotEmpty);
          budget.run = run.id;
        }
        return response;
      },
      patch: unsupportedHermesApiPatch,
      put: unsupportedHermesApiPut,
      delete: unsupportedHermesApiDelete,
      postStream: unsupportedHermesApiPostStream,
    );
    final channel = HermesApiChannel(clientBuilder: buildClient);
    addTearDown(channel.dispose);
    final cache = GatewayContactCache();
    final directory = HermesGatewayDirectory(
      store: store,
      cache: cache,
      loader: HermesApiGatewaySummaryLoader(clientBuilder: buildClient),
      activeChannel: channel,
    );
    await directory.start();
    if (phase == 'write') {
      expect(await cache.loadSelection(), isNull);
      final contact = directory.contacts.singleWhere(
        (c) => c.id.profileId == profile,
      );
      await directory.activate(contact.id, preferredSessionId: session);
    }
    expect(channel.state.isConnected, true);
    expect(channel.state.selectedProfileId, profile);
    expect(channel.state.activeSessionId, session);
    expect(directory.restorationFailure, isNull);
    expect(budget.counts.values.every((n) => n == 0), true);
    final probe = buildClient(
      HermesApiConfig.fromBaseUrl(
        input['origin'] as String,
        apiKey: input['api_key'] as String,
      ),
    );
    final before = await probe.getSession(session);
    final beforeMessages = await probe.sessionMessages(session);
    if (previous != null) {
      expect(previous['native_pid'], isNot(pid));
      expect(before.messageCount, previous['message_count']);
      expect(
        _historyIdentity(beforeMessages.map((m) => m.id)),
        previous['history_identity'],
      );
      expect(channel.state.sessionModelLocks, isEmpty);
      final stopped = await probe.getRunStatus(previous['run_id'] as String);
      expect(stopped.sessionId, session);
      expect(stopped.status, HermesRunLifecycle.cancelled);
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(store),
          hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    budget.armed = true;
    await tester.tap(find.byKey(const ValueKey('hermes-composer-model-chip')));
    await _liveWait(
      tester,
      () => find.byType(SessionModelPickerSheet).evaluate().isNotEmpty,
    );
    await tester.enterText(
      find.byKey(const ValueKey('session-model-search')),
      'gpt-6.1-sol',
    );
    await tester.pumpAndSettle();
    final model = find.byKey(
      const ValueKey('session-model-openai-codex/gpt-6.1-sol'),
    );
    await tester.ensureVisible(model);
    await tester.tap(model);
    await tester.pumpAndSettle();
    final use = find.widgetWithText(FilledButton, 'Use for session');
    await tester.ensureVisible(use);
    await tester.tap(use);
    await _liveWait(
      tester,
      () => channel.state.sessionModelLocks[session]?.accepted == true,
    );
    expect(channel.state.sessionModelLocks[session]?.provider, 'openai-codex');
    expect(channel.state.sessionModelLocks[session]?.model, 'gpt-6.1-sol');
    HermesApprovalRequest? pending;
    final subscription = channel.approvalRequests.listen((event) {
      pending = event;
    });
    addTearDown(subscription.cancel);
    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      phase == 'write'
          ? 'Say QA ready, then request exactly one terminal command: printf WING_QA. Do not read files, access a network, write anything, or call any other tool. After approval, reply briefly.'
          : 'Reply with one short sentence confirming this conversation continued. Do not use tools.',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    if (phase == 'write') {
      await _liveWait(
        tester,
        () =>
            pending != null && find.text('Approve once').evaluate().isNotEmpty,
      );
      final request = pending!;
      expect(request.id, isNotEmpty);
      expect(request.runId, budget.run);
      expect(request.sessionId, session);
      expect(request.profileId, profile);
      expect(request.command?.trim(), 'printf WING_QA');
      budget.request = request.id;
      await tester.tap(find.text('Approve once'));
      await _liveWait(tester, () => budget.approvals == 1);
      await tester.tap(find.widgetWithText(ActionChip, 'Stop'));
      await _liveWait(tester, () => budget.stops == 1);
    }
    await _liveWait(
      tester,
      () =>
          !channel.state.hasUnreconciledRun &&
          !channel.state.isSessionStreaming(session) &&
          budget.run != null,
    );
    final canonical = await probe.getRunStatus(budget.run!);
    expect(canonical.sessionId, session);
    expect(
      canonical.status,
      phase == 'write'
          ? HermesRunLifecycle.cancelled
          : HermesRunLifecycle.completed,
    );
    await channel.reconcileActiveSession();
    final after = await probe.getSession(session);
    final messages = await probe.sessionMessages(session);
    expect(
      messages.where((m) => m.role == 'user').length,
      beforeMessages.where((m) => m.role == 'user').length + 1,
    );
    expect(budget.counts, {
      'submits': 1,
      'approvals': phase == 'write' ? 1 : 0,
      'stops': phase == 'write' ? 1 : 0,
      'model_locks': 1,
    });
    final receipt = {
      'phase': phase,
      'native_pid': pid,
      'run_id': budget.run,
      'message_count': after.messageCount,
      'history_identity': _historyIdentity(messages.map((m) => m.id)),
      'owner_identity': _historyIdentity([origin.toString(), profile, session]),
      'counts': budget.counts,
      'canonical_status': canonical.status.name,
      'provider_calls':
          after.apiCallCount == null || before.apiCallCount == null
          ? null
          : after.apiCallCount! - before.apiCallCount!,
    };
    if (previous != null) {
      expect(receipt['owner_identity'], previous['owner_identity']);
    }
    File('$root/cache/live-$phase.json').writeAsStringSync(jsonEncode(receipt));
    budget.armed = false;
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

String _historyIdentity(Iterable<String> values) =>
    sha256.convert(utf8.encode(jsonEncode(values.toList()))).toString();

void requireQualifiedLiveBudget() {
  // Charging submitted runs is insufficient: approval/tool continuations can
  // invoke the provider again without another client mutation. Keep the prepared
  // journey disabled until an authoritative ceiling is qualified.
  throw UnsupportedError('LIVE_INFERENCE_BOUND_NOT_QUALIFIED');
}

Future<void> _liveWait(WidgetTester tester, bool Function() ready) async {
  final deadline = DateTime.now().add(const Duration(seconds: 60));
  while (!ready() && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  if (!ready()) fail('Live workflow checkpoint failed (details redacted).');
}

class _LiveEndpointStore extends EmptyHermesEndpointStore {
  const _LiveEndpointStore(this.input);
  final Map<String, dynamic> input;
  @override
  Future<List<HermesEndpointConfig>> loadProfiles() async => [
    HermesEndpointConfig(
      id: 'live-qa',
      label: 'Disposable QA',
      baseUrl: input['origin'] as String,
      apiKey: input['api_key'] as String,
    ),
  ];
}
