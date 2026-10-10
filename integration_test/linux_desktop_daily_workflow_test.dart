import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/hermes_chat/widgets/session_model_picker_sheet.dart';
import 'package:wing/l10n/app_localizations.dart';

import 'support/linux_test_isolation.dart';

// Synthetic Agent API, production native HTTP/SSE channel and Chat UI, and real
// Linux selection preferences across two app processes. No Agent generation,
// secure credential enrollment, OS keyboard/IME or whole-shell acceptance.
// The combined scenario acknowledges a pair before runs. Agent metadata exposes
// model text only: restart must report the unknown pair, never a catalog default.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.shouldPropagateDevicePointerEvents = true;
  WidgetController.hitTestWarningShouldBeFatal = true;
  final root = requireLinuxTestRoot('wing-linux-daily.');
  final phase = Platform.environment['WING_DAILY_PHASE'];
  final origin = Platform.environment['WING_DAILY_ORIGIN'];
  final uri = Uri.tryParse(origin ?? '');
  if (!{'write', 'verify'}.contains(phase) ||
      uri?.scheme != 'http' ||
      uri?.host != '127.0.0.1' ||
      Platform.environment['HOME'] != '$root/home' ||
      Platform.environment['WING_ISOLATED_PREFERENCES'] != '1') {
    throw StateError('Use scripts/run_linux_desktop_daily_workflow_e2e.sh.');
  }
  final api = origin!;

  if (phase == 'write') {
    testWidgets(
      'advertised session model rejects then confirms explicit identity',
      (tester) async {
        expect(
          (await _request(
            api,
            'POST',
            '/e2e/hermes/model-picker',
          ))['synthetic'],
          true,
        );
        final channel = HermesApiChannel();
        addTearDown(channel.dispose);
        await channel.connect(baseUrl: api);
        expect(channel.state.isConnected, true);
        final session = channel.state.activeSessionId!;
        await expectLater(
          channel.lockSessionModel(
            sessionId: session,
            provider: 'alpha',
            model: 'alpha/model-99',
          ),
          throwsA(isA<Exception>()),
        );
        expect(
          (await _request(api, 'GET', '/e2e/hermes/model-picker'))['selected'],
          isNull,
        );
        await channel.lockSessionModel(
          sessionId: session,
          provider: 'alpha',
          model: 'alpha/model-99',
        );
        final receipt = await _request(api, 'GET', '/e2e/hermes/model-picker');
        expect(receipt['locks'], [
          {'provider': 'alpha', 'model': 'alpha/model-99'},
          {'provider': 'alpha', 'model': 'alpha/model-99'},
        ]);
        expect(receipt['selected'], {
          'provider': 'alpha',
          'model': 'alpha/model-99',
          'model_lock': 'accepted',
          'route_source': 'session',
        });
        final confirmed = channel.state.sessionModelLocks[session]!;
        expect(confirmed.sessionId, session);
        expect(confirmed.provider, 'alpha');
        expect(confirmed.model, 'alpha/model-99');
        expect(confirmed.accepted, true);
        expect(
          (await _request(api, 'GET', '/e2e/hermes/run-count'))['runCount'],
          0,
        );
        debugPrint(
          'MODEL_RECEIPT ${jsonEncode({'synthetic': true, 'native_pid': pid, 'session_id': confirmed.sessionId, 'provider': confirmed.provider, 'model': confirmed.model, 'locks': (receipt['locks'] as List).length, 'runs': 0, 'scenario': 'separate-model-confirmation'})}',
        );
      },
    );
  }

  testWidgets('native daily workflow $phase: correlated run and exact relaunch', (
    tester,
  ) async {
    binding.testTextInput.register();
    addTearDown(binding.testTextInput.unregister);
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    if (phase == 'write') {
      expect(
        (await _request(api, 'POST', '/e2e/hermes/lifecycle', {
          'scenario': 'desktop-daily',
        }))['synthetic'],
        true,
      );
    }
    final cache = GatewayContactCache(); // Never mock SharedPreferences here.
    final remembered = await cache.loadSelection();
    if (phase == 'write') {
      expect(remembered, isNull);
    } else {
      expect(remembered?.contactId.gatewayId, 'daily-fixture');
      expect(remembered?.contactId.profileId, 'default');
      expect(remembered?.sessionId, 'e2e-hermes-session');
    }
    // Capture counts before production startup; direct probe reads must not be
    // mistaken for metadata/history requested by restoration itself.
    final beforeRestore = await _request(api, 'GET', '/e2e/hermes/lifecycle');
    final restorationBefore = beforeRestore['restoration'] as Map;
    expect(restorationBefore['session_id'], 'e2e-hermes-session');
    final inventoryCount =
        (restorationBefore['inventory_reads'] as List).length;
    final metadataCount = (restorationBefore['metadata_reads'] as List).length;
    final historyCount = (beforeRestore['history_reads'] as List).length;
    final channel =
        HermesApiChannel(); // Production sockets, not fake transport.
    final store = _OwnedEndpointStore(api);
    final directory = HermesGatewayDirectory(
      store: store,
      cache: cache,
      loader: const HermesApiGatewaySummaryLoader(),
      activeChannel: channel,
    );
    addTearDown(
      channel.dispose,
    ); // The mounted provider owns directory disposal.
    await directory.start();
    if (phase == 'write') {
      // Explicit local connection/profile contact selection. The fixture advertises
      // query profile context, but no profile administration; do not invent it.
      final contact = directory.contacts.singleWhere(
        (c) => c.id.profileId == 'default',
      );
      await directory.activate(
        contact.id,
        preferredSessionId: 'e2e-hermes-session',
      );
    }
    expect(channel.state.isConnected, true);
    expect(channel.state.selectedProfileId, 'default');
    expect(channel.state.activeSessionId, 'e2e-hermes-session');
    expect(directory.restorationFailure, isNull);
    expect(directory.restoringSessionId, isNull);
    expect(channel.state.connectedBaseUrl, api);
    final afterRestore = await _request(api, 'GET', '/e2e/hermes/lifecycle');
    final checkpoints = <String, Map<String, int>>{
      'before_restore': _counts(beforeRestore),
      'after_restore': _counts(afterRestore),
    };
    final restorationAfter = afterRestore['restoration'] as Map;
    final firstPages = (restorationAfter['inventory_reads'] as List)
        .skip(inventoryCount)
        .where((r) => r['offset'] == 0 && r['status'] == 200);
    expect(firstPages, isNotEmpty);
    for (final page in firstPages) {
      expect(page['omitted_session_id'], 'e2e-hermes-session');
      expect(page['session_ids'], isNot(contains('e2e-hermes-session')));
    }
    expect(
      (restorationAfter['metadata_reads'] as List)
          .skip(metadataCount)
          .where(
            (r) =>
                r['profile_id'] == 'default' &&
                r['session_id'] == 'e2e-hermes-session' &&
                r['returned_session_id'] == 'e2e-hermes-session' &&
                r['status'] == 200,
          ),
      isNotEmpty,
      reason: 'An off-page pointer requires authoritative exact metadata.',
    );
    final restoredHistory = (afterRestore['history_reads'] as List)
        .skip(historyCount)
        .where(
          (r) =>
              r['session_id'] == 'e2e-hermes-session' &&
              r['profile_id'] == 'default',
        );
    expect(restoredHistory, isNotEmpty);
    if (phase == 'verify') {
      expect(
        restoredHistory.any(
          (r) => (r['message_ids'] as List).contains('canonical_run_2'),
        ),
        true,
        reason: 'Relaunch must read canonical history in this new process.',
      );
    }
    for (final key in [
      'submits',
      'approvals',
      'stops',
      'unexpected_mutations',
      'sessions',
      'model_locks',
    ]) {
      expect(
        afterRestore[key],
        beforeRestore[key],
        reason: 'Exact restoration must not create sessions or replay $key.',
      );
    }

    Future<void> mount() async {
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
    }

    if (phase == 'write') {
      await expectLater(
        channel.lockSessionModel(
          sessionId: 'e2e-hermes-session',
          provider: 'alpha',
          model: 'alpha/model-99',
        ),
        throwsA(isA<Exception>()),
      );
      expect(channel.state.sessionModelLocks, isEmpty);
      await channel.lockSessionModel(
        sessionId: 'e2e-hermes-session',
        provider: 'alpha',
        model: 'alpha/model-99',
      );
      final confirmed = channel.state.sessionModelLocks['e2e-hermes-session']!;
      expect(confirmed.accepted, true);
      expect(confirmed.provider, 'alpha');
      expect(confirmed.model, 'alpha/model-99');
    } else {
      expect(channel.state.activeSession?.model, 'alpha/model-99');
      expect(channel.state.activeSession?.hasModelConfig, true);
      expect(channel.state.sessionModelLocks, isEmpty);
    }
    await mount();
    if (phase == 'verify') {
      await tester.tap(
        find.byKey(const ValueKey('hermes-composer-model-chip')),
      );
      await _wait(
        tester,
        () => find.byType(SessionModelPickerSheet).evaluate().isNotEmpty,
      );
      await tester.pumpAndSettle();
      final picker = tester.widget<SessionModelPickerSheet>(
        find.byType(SessionModelPickerSheet),
      );
      expect(picker.currentSessionModel, isNull);
      expect(picker.requireExplicitSelection, true);
      expect(picker.options.currentProvider, 'beta');
      expect(picker.options.currentModel, 'shared');
      expect(
        find.text(
          AppLocalizations.of(
            tester.element(find.byType(SessionModelPickerSheet)),
          ).sessionModelIdentityNotReported,
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Use for session'),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.text('Cancel'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(channel.state.sessionModelLocks, isEmpty);
      final afterCancel = await _request(api, 'GET', '/e2e/hermes/lifecycle');
      checkpoints['after_cancel'] = _counts(afterCancel);
      expect(_counts(afterCancel), _counts(afterRestore));
      _assertReceipt(afterCancel);

      await tester.tap(
        find.byKey(const ValueKey('hermes-composer-model-chip')),
      );
      await _wait(
        tester,
        () => find.byType(SessionModelPickerSheet).evaluate().isNotEmpty,
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('session-model-search')),
        'alpha/model-99',
      );
      await tester.pumpAndSettle();
      final row = find.byKey(
        const ValueKey('session-model-alpha/alpha/model-99'),
      );
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();
      final use = find.widgetWithText(FilledButton, 'Use for session');
      expect(tester.widget<FilledButton>(use).onPressed, isNotNull);
      await tester.ensureVisible(use);
      await tester.tap(use);
      await _wait(
        tester,
        () => find.byType(SessionModelPickerSheet).evaluate().isEmpty,
      );
      final confirmed = channel.state.sessionModelLocks['e2e-hermes-session']!;
      expect(confirmed.accepted, true);
      expect(confirmed.provider, 'alpha');
      expect(confirmed.model, 'alpha/model-99');
      final afterSelection = await _request(
        api,
        'GET',
        '/e2e/hermes/lifecycle',
      );
      checkpoints['after_reselection'] = _counts(afterSelection);
      expect(_counts(afterSelection), {
        ..._counts(afterCancel),
        'model_locks': 3,
      });
      expect((afterSelection['model_locks'] as List).last, {
        'profile_id': 'default',
        'session_id': 'e2e-hermes-session',
        'provider': 'alpha',
        'model': 'alpha/model-99',
        'status': 'accepted',
      });
      await _submit(tester, 'Deterministic resumed prompt');
      await _wait(
        tester,
        () =>
            !channel.state.isSessionStreaming('e2e-hermes-session') &&
            channel.state.activeMessages.any((m) => m.id == 'canonical_run_3'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Deterministic fixture reply 3.'), findsOneWidget);
      expect(
        channel.state.activeMessages
            .singleWhere((m) => m.id == 'canonical_run_3')
            .text,
        'Deterministic fixture reply 3.',
      );
      final afterSend = await _request(api, 'GET', '/e2e/hermes/lifecycle');
      checkpoints['after_send'] = _counts(afterSend);
      expect(_counts(afterSend), {..._counts(afterSelection), 'submits': 3});
      expect(
        (afterSend['history_reads'] as List).any(
          (r) =>
              r['session_id'] == 'e2e-hermes-session' &&
              r['profile_id'] == 'default' &&
              (r['message_ids'] as List).contains('canonical_run_3'),
        ),
        true,
      );
    }
    if (phase == 'write') {
      await _submit(tester, 'Deterministic daily approval');
      await _wait(
        tester,
        () => find.text('Approve once').evaluate().isNotEmpty,
      );
      await tester.tap(find.text('Approve once'));
      await _wait(
        tester,
        () => !channel.state.isSessionStreaming('e2e-hermes-session'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Deterministic fixture reply 1.'), findsOneWidget);
      var receipt = await _request(api, 'GET', '/e2e/hermes/lifecycle');
      expect(receipt['approvals'], [
        {
          'run_id': 'run_1',
          'session_id': 'e2e-hermes-session',
          'profile_id': 'default',
          'request_id': 'approval_run_1',
          'choice': 'once',
        },
      ]);
      await _submit(tester, 'Deterministic daily stop');
      await _wait(
        tester,
        () => find.text('Approve once').evaluate().isNotEmpty,
      );
      await tester.tap(find.widgetWithText(ActionChip, 'Stop'));
      await _wait(tester, () => find.text('Approve once').evaluate().isEmpty);
      // The fixture acknowledges Stop without becoming terminal. Wait for an
      // actual production status read, then prove the session remains locked.
      await _waitAsync(tester, () async {
        receipt = await _request(api, 'GET', '/e2e/hermes/lifecycle');
        return (receipt['status_reads'] as List).any(
          (r) => r['run_id'] == 'run_2' && r['status'] == 'stopping',
        );
      });
      expect(channel.state.hasUnreconciledRun, true);
      final send = find.byKey(const ValueKey('hermes-send-button'));
      if (send.evaluate().isNotEmpty) {
        expect(tester.widget<IconButton>(send).onPressed, isNull);
      }
      expect(receipt['submits'] as List, hasLength(2));
      expect(receipt['stops'], [
        {
          'run_id': 'run_2',
          'session_id': 'e2e-hermes-session',
          'profile_id': 'default',
          'status': 'stopping',
        },
      ]);
      await _request(api, 'POST', '/e2e/hermes/lifecycle/terminal', {
        'run_id': 'run_2',
      });
      await channel.reconcileActiveSession();
      await _wait(tester, () => !channel.state.hasUnreconciledRun);
      receipt = await _request(api, 'GET', '/e2e/hermes/lifecycle');
      expect(
        (receipt['status_reads'] as List).any(
          (r) =>
              r['run_id'] == 'run_2' &&
              r['session_id'] == 'e2e-hermes-session' &&
              r['profile_id'] == 'default' &&
              r['status'] == 'cancelled',
        ),
        true,
      );
    }
    final beforeLeave = await _request(api, 'GET', '/e2e/hermes/lifecycle');
    checkpoints['before_reopen'] = _counts(beforeLeave);
    _assertReceipt(beforeLeave, resumed: phase == 'verify');
    expect(
      channel.state.activeMessages.any(
        (t) => t.text == 'Synthetic canonical stopped outcome.',
      ),
      true,
    );
    // Leaving the Chat widget must not clear the saved selection or send a turn.
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    unawaited(
      navigator.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Synthetic other route')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Synthetic other route'), findsOneWidget);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(channel.state.activeSessionId, 'e2e-hermes-session');
    expect(find.text('Deterministic fixture reply 1.'), findsOneWidget);
    expect(find.text('Synthetic canonical stopped outcome.'), findsOneWidget);
    final selection = await cache.loadSelection();
    expect(selection?.contactId.gatewayId, 'daily-fixture');
    expect(selection?.contactId.profileId, 'default');
    expect(selection?.sessionId, 'e2e-hermes-session');
    final afterLeave = await _request(api, 'GET', '/e2e/hermes/lifecycle');
    checkpoints['after_reopen'] = _counts(afterLeave);
    _assertReceipt(afterLeave, resumed: phase == 'verify');
    expect(_counts(afterLeave), _counts(beforeLeave));
    if (phase == 'verify') {
      expect(find.text('Deterministic fixture reply 3.'), findsOneWidget);
    }
    for (final key in [
      'submits',
      'approvals',
      'stops',
      'unexpected_mutations',
      'sessions',
      'model_locks',
    ]) {
      expect(
        afterLeave[key],
        beforeLeave[key],
        reason: 'Leaving/reopening must not replay $key.',
      );
    }
    if (phase == 'verify') {
      expect(
        (afterLeave['history_reads'] as List).where(
          (r) =>
              r['session_id'] == selection!.sessionId &&
              r['profile_id'] == 'default' &&
              (r['message_ids'] as List).contains('canonical_run_2'),
        ),
        isNotEmpty,
      );
    }
    expect(tester.takeException(), isNull);
    debugPrint(
      'CONTINUATION_RECEIPT ${jsonEncode({'phase': phase, 'synthetic': true, 'checkpoints': checkpoints})}',
    );
    debugPrint(
      'DAILY_RECEIPT ${jsonEncode({'phase': phase, 'synthetic': true, 'scenario': 'combined-model-lifecycle', 'native_pid': pid, 'gateway_id': selection!.contactId.gatewayId, 'profile_id': selection.contactId.profileId, 'session_id': selection.sessionId, 'provider': channel.state.sessionModelLocks[selection.sessionId]?.provider, 'model': channel.state.sessionModelLocks[selection.sessionId]?.model ?? channel.state.activeSession?.model, 'pair_readback': phase == 'write' ? 'acknowledged-write' : 'unsupported-until-explicit-reselection', 'model_locks': (afterLeave['model_locks'] as List).length, 'submits': (afterLeave['submits'] as List).length, 'approvals': (afterLeave['approvals'] as List).length, 'stops': (afterLeave['stops'] as List).length, 'unexpected_mutations': (afterLeave['unexpected_mutations'] as List).length})}',
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

class _OwnedEndpointStore extends EmptyHermesEndpointStore {
  const _OwnedEndpointStore(this.origin);
  final String origin;
  @override
  Future<List<HermesEndpointConfig>> loadProfiles() async => [
    HermesEndpointConfig(
      id: 'daily-fixture',
      label: 'Synthetic local fixture',
      baseUrl: origin,
    ),
  ];
}

Map<String, int> _counts(Map<String, dynamic> receipt) => {
  for (final key in [
    'submits',
    'approvals',
    'stops',
    'unexpected_mutations',
    'sessions',
    'model_locks',
  ])
    key: (receipt[key] as List).length,
};

void _assertReceipt(Map<String, dynamic> receipt, {bool resumed = false}) {
  expect(receipt['synthetic'], true);
  expect(receipt['scenario'], 'desktop-daily');
  expect(receipt['model_locks'], [
    for (final status in ['rejected', 'accepted', if (resumed) 'accepted'])
      {
        'profile_id': 'default',
        'session_id': 'e2e-hermes-session',
        'provider': 'alpha',
        'model': 'alpha/model-99',
        'status': status,
      },
  ]);
  final submits = receipt['submits'] as List;
  expect(submits.map((r) => r['message']), [
    'Deterministic daily approval',
    'Deterministic daily stop',
    if (resumed) 'Deterministic resumed prompt',
  ]);
  expect(
    submits.every(
      (r) =>
          r['session_id'] == 'e2e-hermes-session' &&
          r['profile_id'] == 'default' &&
          r['input_matches_message'] == true,
    ),
    true,
  );
  expect(receipt['approvals'] as List, hasLength(1));
  expect(receipt['stops'] as List, hasLength(1));
  expect(receipt['unexpected_mutations'], isEmpty);
  expect((receipt['runs'] as List).map((r) => r['status']), [
    'completed',
    'cancelled',
    if (resumed) 'completed',
  ]);
  final sessions = receipt['sessions'] as List;
  final messages =
      sessions.singleWhere(
            (s) => s['session_id'] == 'e2e-hermes-session',
          )['messages']
          as List;
  expect(messages.where((m) => m['role'] == 'user').map((m) => m['id']), [
    'user_run_1',
    'user_run_2',
    if (resumed) 'user_run_3',
  ]);
  expect(
    messages
        .where((m) => m['id'].toString().startsWith('canonical_'))
        .map((m) => m['id']),
    ['canonical_run_1', 'canonical_run_2', if (resumed) 'canonical_run_3'],
  );
  expect(
    sessions.singleWhere(
      (s) => s['session_id'] == 'synthetic-untouched',
    )['messages'],
    [
      {
        'id': 'untouched',
        'role': 'assistant',
        'content': 'Synthetic isolated history.',
      },
    ],
  );
}

Future<void> _submit(WidgetTester tester, String text) async {
  await tester.enterText(
    find.byKey(const ValueKey('hermes-composer-field')),
    text,
  );
  final send = find.byKey(const ValueKey('hermes-send-button'));
  await _wait(
    tester,
    () =>
        send.evaluate().isNotEmpty &&
        tester.widget<IconButton>(send).onPressed != null,
  );
  await tester.tap(send);
  await tester.pump();
}

Future<void> _wait(WidgetTester tester, bool Function() ready) =>
    _waitAsync(tester, () async => ready());

Future<void> _waitAsync(
  WidgetTester tester,
  Future<bool> Function() ready,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(deadline)) {
    if (await ready()) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('Daily workflow checkpoint timed out.');
}

Future<Map<String, dynamic>> _request(
  String origin,
  String method,
  String path, [
  Map<String, Object?>? body,
]) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
  try {
    final request = await client.openUrl(method, Uri.parse('$origin$path'));
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close().timeout(const Duration(seconds: 5));
    expect(response.statusCode, inInclusiveRange(200, 299));
    return jsonDecode(
          await utf8.decoder
              .bind(response)
              .join()
              .timeout(const Duration(seconds: 5)),
        )
        as Map<String, dynamic>;
  } finally {
    client.close(force: true);
  }
}
