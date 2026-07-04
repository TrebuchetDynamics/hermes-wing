import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/hermes/channel/hermes_channel.dart';
import 'package:navivox/core/hermes/models/hermes_capabilities.dart';
import 'package:navivox/core/hermes/models/hermes_chat_turn.dart';
import 'package:navivox/core/hermes/models/hermes_health.dart';
import 'package:navivox/core/hermes/models/hermes_job.dart';
import 'package:navivox/core/hermes/models/hermes_session.dart';
import 'package:navivox/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:navivox/features/hermes_chat/diagnostics/hermes_diagnostics_export.dart';
import 'package:navivox/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:navivox/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:navivox/shared/voice/text_to_speech_service.dart';

import '../../shared/fakes/voice_capture_service_fakes.dart';
import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';

Widget _wrap(
  FakeHermesChannel channel, {
  Widget Function()? screenBuilder,
  FakeHermesEndpointStore? endpointStore,
}) {
  return ProviderScope(
    overrides: [
      hermesChannelProvider.overrideWithValue(channel),
      if (endpointStore != null)
        hermesEndpointStoreProvider.overrideWithValue(endpointStore),
    ],
    child: MaterialApp(home: screenBuilder?.call() ?? const HermesChatScreen()),
  );
}

void main() {
  testWidgets(
    'shows a connect form when disconnected and connects with entered values',
    (tester) async {
      final channel = FakeHermesChannel.disconnected();
      await tester.pumpWidget(_wrap(channel));

      expect(
        find.byKey(const ValueKey('hermes-base-url-field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('hermes-connect-button')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Android emulator: http://10.0.2.2:8642'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Physical device: LAN/VPN/Tailscale URL'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('hermes-transcript')), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('hermes-base-url-field')),
        'http://10.0.2.2:8642',
      );
      await tester.enterText(
        find.byKey(const ValueKey('hermes-api-key-field')),
        'secret',
      );
      await tester.tap(find.byKey(const ValueKey('hermes-connect-button')));
      await tester.pumpAndSettle();

      expect(channel.connectCalls, hasLength(1));
      expect(channel.connectCalls.single.baseUrl, 'http://10.0.2.2:8642');
      expect(channel.connectCalls.single.apiKey, 'secret');
      expect(find.byKey(const ValueKey('hermes-transcript')), findsOneWidget);
    },
  );

  testWidgets('Hermes setup presets fill common base URLs', (tester) async {
    final channel = FakeHermesChannel.disconnected();
    await tester.pumpWidget(_wrap(channel));

    await tester.tap(find.byKey(const ValueKey('hermes-preset-android')));
    await tester.pump();
    var field = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-base-url-field')),
    );
    expect(field.controller?.text, 'http://10.0.2.2:8642');

    await tester.tap(find.byKey(const ValueKey('hermes-preset-local')));
    await tester.pump();
    field = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-base-url-field')),
    );
    expect(field.controller?.text, 'http://127.0.0.1:8642');

    await tester.tap(find.byKey(const ValueKey('hermes-preset-remote')));
    await tester.pump();
    field = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-base-url-field')),
    );
    expect(field.controller?.text, isEmpty);
  });

  testWidgets('shows the connect error message when connecting failed', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.error,
      errorMessage: 'Hermes API rejected the request credentials',
    );
    await tester.pumpWidget(_wrap(channel));

    expect(
      find.text('Hermes API rejected the request credentials'),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows connected Hermes capability status and local voice boundary',
    (tester) async {
      final channel = FakeHermesChannel(
        capabilities: _capabilitiesFixture,
        detailedHealth: const HermesHealthStatus(
          status: 'ok',
          platform: 'hermes-agent',
          version: '0.16.0',
          gatewayState: 'running',
          activeAgents: 0,
        ),
        models: const ['hermes-agent'],
        skills: const ['github', 'ascii-art'],
        enabledToolsets: const ['default'],
        jobs: const [HermesJob(id: 'job_1', name: 'Morning check')],
      );
      await tester.pumpWidget(_wrap(channel));

      expect(
        find.byKey(const ValueKey('hermes-capability-strip')),
        findsOneWidget,
      );
      expect(find.text('Hermes Agent hermes-agent'), findsOneWidget);
      expect(find.text('Runs/tool progress enabled'), findsOneWidget);
      expect(find.text('Voice uses device speech-to-text'), findsOneWidget);
      expect(find.text('Version: 0.16.0'), findsOneWidget);
      expect(find.text('Gateway: running'), findsOneWidget);
      expect(find.text('Active agents: 0'), findsOneWidget);
      expect(find.text('Models: hermes-agent'), findsOneWidget);
      expect(find.text('Skills: 2'), findsOneWidget);
      expect(find.text('Toolsets enabled: 1'), findsOneWidget);
      expect(find.text('Jobs: 1'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('hermes-surfaces-chip')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('hermes-surfaces-chip')));
      await tester.pumpAndSettle();
      expect(find.text('Hermes surface readiness'), findsOneWidget);
      expect(find.text('Server realtime voice/audio'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Jobs/schedules admin'),
        240,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Jobs/schedules admin'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Raw diagnostics/log export'),
        240,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Raw diagnostics/log export'), findsOneWidget);
      expect(find.text('Deferred'), findsWidgets);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('hermes-skills-chip')));
      await tester.pumpAndSettle();
      expect(find.text('Hermes skills'), findsOneWidget);
      expect(find.text('github'), findsOneWidget);
      expect(find.text('ascii-art'), findsOneWidget);
    },
  );

  testWidgets(
    'advertised realtime voice still explains Navivox uses device STT',
    (tester) async {
      final channel = FakeHermesChannel(
        capabilities: _realtimeVoiceCapabilitiesFixture,
      );
      await tester.pumpWidget(_wrap(channel));

      expect(
        find.text('Server voice advertised; using device STT'),
        findsOneWidget,
      );
      expect(find.text('Server realtime voice advertised'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('hermes-surfaces-chip')));
      await tester.pumpAndSettle();
      expect(find.text('Server realtime voice/audio'), findsOneWidget);
      expect(find.text('Deferred'), findsWidgets);
    },
  );

  test('Hermes diagnostics export is bounded and excludes secrets', () {
    final export = hermesDiagnosticsExport(
      HermesChannelState(
        status: HermesConnectionStatus.connected,
        capabilities: _capabilitiesFixture,
        detailedHealth: const HermesHealthStatus(
          status: 'ok',
          platform: 'hermes-agent',
          version: '0.16.0',
          gatewayState: 'running',
          activeAgents: 1,
        ),
        models: const ['hermes-agent'],
        skills: const ['github'],
        enabledToolsets: const ['default'],
        jobs: const [HermesJob(id: 'job_1', name: 'Morning check')],
        sessions: const [
          HermesSession(id: 'sess_1', source: 'fake', title: 'Ops'),
        ],
        activeSessionId: 'sess_1',
        messages: {
          'sess_1': [
            HermesChatTurn(
              id: 'msg_1',
              sessionId: 'sess_1',
              author: HermesTurnAuthor.user,
              text: 'NAVIVOX_DO_NOT_EXPORT_TOKEN transcript text',
              createdAt: DateTime.utc(2026),
            ),
            HermesChatTurn(
              id: 'tool_1',
              sessionId: 'sess_1',
              author: HermesTurnAuthor.assistant,
              kind: HermesTurnKind.toolCall,
              toolCall: HermesToolCall(
                name: 'read_file',
                status: 'completed',
                preview: 'raw_tool_payload_preview',
                result: 'raw_tool_payload_result',
              ),
              createdAt: DateTime.utc(2026),
            ),
          ],
        },
      ),
    );

    expect(export, contains('Navivox Hermes diagnostics'));
    expect(export, contains('Connection: connected'));
    expect(export, contains('Active messages: 2'));
    expect(export, contains('Run transport: available'));
    expect(export, contains('Realtime voice: not advertised'));
    expect(export, contains('Config write: not advertised'));
    expect(export, contains('Memory write: not advertised'));
    expect(export, contains('Surface readiness:'));
    expect(export, contains('Server realtime voice/audio: Deferred'));
    expect(export, contains('Legacy durable reconnect: Blocked'));
    expect(export, contains('Jobs: 1'));
    expect(export, contains('Secrets: excluded'));
    expect(export, isNot(contains('Authorization')));
    expect(export, isNot(contains('secret')));
    expect(export, isNot(contains('NAVIVOX_DO_NOT_EXPORT_TOKEN')));
    expect(export, isNot(contains('raw_tool_payload')));
  });

  testWidgets('opens bounded Hermes diagnostics from the app bar', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilitiesFixture,
      detailedHealth: const HermesHealthStatus(
        status: 'ok',
        platform: 'hermes-agent',
        version: '0.16.0',
        gatewayState: 'running',
        activeAgents: 0,
      ),
      models: const ['hermes-agent'],
      skills: const ['github'],
      enabledToolsets: const ['default'],
    );
    await tester.pumpWidget(_wrap(channel));

    await tester.tap(find.byKey(const ValueKey('hermes-diagnostics-button')));
    await tester.pumpAndSettle();

    expect(find.text('Hermes diagnostics'), findsOneWidget);
    final diagnostics = tester.widget<SelectableText>(
      find.byKey(const ValueKey('hermes-diagnostics-text')),
    );
    expect(diagnostics.data, contains('Navivox Hermes diagnostics'));
    expect(diagnostics.data, contains('Run transport: available'));
    expect(diagnostics.data, contains('Secrets: excluded'));
    expect(diagnostics.data, isNot(contains('Authorization')));
  });

  testWidgets('sessions panel selects another Hermes session', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilitiesFixture,
      sessions: const [
        HermesSession(id: 'sess_1', source: 'fake', title: 'One'),
        HermesSession(id: 'sess_2', source: 'fake', title: 'Two'),
      ],
    );
    await tester.pumpWidget(_wrap(channel));

    await tester.tap(find.byKey(const ValueKey('hermes-sessions-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hermes-session-row-sess_2')));
    await tester.pumpAndSettle();

    expect(channel.state.activeSessionId, 'sess_2');
    expect(find.text('Two'), findsOneWidget);
  });

  testWidgets('sessions panel filters and selects a matching Hermes session', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilitiesFixture,
      sessions: const [
        HermesSession(id: 'sess_1', source: 'fake', title: 'Incident review'),
        HermesSession(id: 'sess_2', source: 'fake', title: 'Morning check'),
      ],
    );
    await tester.pumpWidget(_wrap(channel));

    await tester.tap(find.byKey(const ValueKey('hermes-sessions-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('hermes-session-search-field')),
      'morning',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-session-row-sess_1')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('hermes-session-row-sess_2')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('hermes-session-row-sess_2')));
    await tester.pumpAndSettle();

    expect(channel.state.activeSessionId, 'sess_2');
  });

  testWidgets('sessions panel shows no results for unmatched search', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilitiesFixture,
      sessions: const [
        HermesSession(id: 'sess_1', source: 'fake', title: 'Incident review'),
      ],
    );
    await tester.pumpWidget(_wrap(channel));

    await tester.tap(find.byKey(const ValueKey('hermes-sessions-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('hermes-session-search-field')),
      'morning',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-session-row-sess_1')),
      findsNothing,
    );
    expect(find.text('No Hermes sessions match “morning”.'), findsOneWidget);
  });

  testWidgets('renames a Hermes session from the sessions panel', (
    tester,
  ) async {
    final channel = FakeHermesChannel(capabilities: _capabilitiesFixture);
    await tester.pumpWidget(_wrap(channel));

    await tester.tap(find.byKey(const ValueKey('hermes-sessions-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hermes-session-menu-sess_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('hermes-session-title-field')),
      'Mobile ops',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-session-title-save')));
    await tester.pumpAndSettle();

    expect(channel.renameSessionCalls, [
      {'sessionId': 'sess_1', 'title': 'Mobile ops'},
    ]);
    expect(find.text('Mobile ops'), findsOneWidget);
  });

  testWidgets('forks a Hermes session from the sessions panel', (tester) async {
    final channel = FakeHermesChannel(capabilities: _capabilitiesFixture);
    await tester.pumpWidget(_wrap(channel));

    await tester.tap(find.byKey(const ValueKey('hermes-sessions-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hermes-session-menu-sess_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fork'));
    await tester.pumpAndSettle();

    expect(channel.forkSessionCalls, ['sess_1']);
    expect(find.text('Forked session'), findsWidgets);
  });

  testWidgets(
    'deletes a Hermes session from the sessions panel after confirmation',
    (tester) async {
      final channel = FakeHermesChannel(capabilities: _capabilitiesFixture);
      await tester.pumpWidget(_wrap(channel));

      await tester.tap(find.byKey(const ValueKey('hermes-sessions-button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('hermes-session-menu-sess_1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('hermes-session-delete-confirm')),
      );
      await tester.pumpAndSettle();

      expect(channel.deleteSessionCalls, ['sess_1']);
      expect(
        find.text(
          'No Hermes sessions. Create a new session to start chatting.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('sending composer text appends the turn and clears the field', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await tester.pumpWidget(_wrap(channel));

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      'hello hermes',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(find.text('hello hermes'), findsOneWidget);
    expect(find.text('echo: hello hermes'), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    expect(field.controller!.text, isEmpty);
  });

  testWidgets(
    'tapping the mic button captures and submits a voice transcript',
    (tester) async {
      final channel = FakeHermesChannel();
      await tester.pumpWidget(
        _wrap(
          channel,
          screenBuilder: () => HermesChatScreen(
            voiceCaptureServiceOverride: successfulVoiceCaptureService(
              transcript: 'turn the lights on',
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('hermes-mic-button')));
      await tester.pumpAndSettle();

      expect(channel.sentVoiceTranscripts, ['turn the lights on']);
      expect(find.text('turn the lights on'), findsOneWidget);
      expect(find.text('echo: turn the lights on'), findsOneWidget);
    },
  );

  testWidgets(
    'continuous voice speaks the reply then automatically re-arms capture',
    (tester) async {
      final channel = FakeHermesChannel();
      final tts = FakeTextToSpeechService();
      final captures = QueueVoiceCaptureService([
        testVoiceCapture('first question'),
        testVoiceCapture('second question'),
      ]);
      await tester.pumpWidget(
        _wrap(
          channel,
          screenBuilder: () => HermesChatScreen(
            voiceCaptureServiceOverride: captures,
            textToSpeechServiceOverride: tts,
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('hermes-continuous-voice-switch')),
      );
      await tester.pumpAndSettle();

      expect(channel.sentVoiceTranscripts, [
        'first question',
        'second question',
      ]);
      expect(tts.spoken, ['echo: first question', 'echo: second question']);
    },
  );

  testWidgets('saves the endpoint to the store after a successful connect', (
    tester,
  ) async {
    final channel = FakeHermesChannel.disconnected();
    final store = FakeHermesEndpointStore();
    await tester.pumpWidget(_wrap(channel, endpointStore: store));

    await tester.enterText(
      find.byKey(const ValueKey('hermes-base-url-field')),
      'http://10.0.2.2:8642',
    );
    await tester.enterText(
      find.byKey(const ValueKey('hermes-api-key-field')),
      'secret',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-connect-button')));
    await tester.pumpAndSettle();

    expect(store.saveCalls, hasLength(1));
    expect(store.saveCalls.single.baseUrl, 'http://10.0.2.2:8642');
    expect(store.saveCalls.single.apiKey, 'secret');
  });

  testWidgets('does not save to the store when connecting fails', (
    tester,
  ) async {
    final channel = _FailingConnectHermesChannel();
    final store = FakeHermesEndpointStore();
    await tester.pumpWidget(_wrap(channel, endpointStore: store));

    await tester.enterText(
      find.byKey(const ValueKey('hermes-base-url-field')),
      'http://10.0.2.2:8642',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-connect-button')));
    await tester.pumpAndSettle();

    expect(store.saveCalls, isEmpty);
  });

  testWidgets('disconnect clears the store and returns to the connect form', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    final store = FakeHermesEndpointStore(
      initial: const HermesEndpointConfig(baseUrl: 'http://10.0.2.2:8642'),
    );
    await tester.pumpWidget(_wrap(channel, endpointStore: store));

    await tester.tap(find.byKey(const ValueKey('hermes-disconnect-button')));
    await tester.pumpAndSettle();

    expect(store.clearCalls, 1);
    expect(find.byKey(const ValueKey('hermes-connect-button')), findsOneWidget);
  });

  testWidgets('renders a pending approval and answers approve/deny', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await tester.pumpWidget(_wrap(channel));

    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: 'appr_1',
        toolCallId: 'call_1',
        prompt: 'Run rm -rf /tmp/scratch?',
        risk: 'high',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-approval-banner')),
      findsOneWidget,
    );
    expect(find.text('Run rm -rf /tmp/scratch?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('hermes-approval-once')));
    await tester.pumpAndSettle();

    expect(channel.respondToApprovalCalls, [
      {'approvalId': 'appr_1', 'decision': HermesApprovalDecision.once},
    ]);
    expect(find.byKey(const ValueKey('hermes-approval-banner')), findsNothing);
  });

  testWidgets('denying an approval answers with the deny decision', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await tester.pumpWidget(_wrap(channel));

    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: 'appr_1',
        toolCallId: 'call_1',
        prompt: 'Run rm -rf /tmp/scratch?',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hermes-approval-deny')));
    await tester.pumpAndSettle();

    expect(channel.respondToApprovalCalls, [
      {'approvalId': 'appr_1', 'decision': HermesApprovalDecision.deny},
    ]);
  });

  testWidgets('approving for the session answers with the session decision', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await tester.pumpWidget(_wrap(channel));

    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: 'appr_1',
        toolCallId: 'call_1',
        prompt: 'Read files in the workspace?',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hermes-approval-session')));
    await tester.pumpAndSettle();

    expect(channel.respondToApprovalCalls, [
      {'approvalId': 'appr_1', 'decision': HermesApprovalDecision.session},
    ]);
  });

  testWidgets('shows a stop control while a turn is streaming and stops it', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await tester.pumpWidget(_wrap(channel));

    expect(find.byKey(const ValueKey('hermes-stop-button')), findsNothing);

    channel.beginStreamingTurn('keep going forever');
    // A streaming turn renders a perpetual progress indicator, so pump a
    // bounded number of frames instead of pumpAndSettle (which would hang).
    await tester.pump();

    expect(find.byKey(const ValueKey('hermes-stop-button')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('hermes-stop-button')));
    await tester.pump();

    expect(channel.stopActiveTurnCalls, 1);
  });

  testWidgets('renders a tool-call turn as a status card, not plain text', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await tester.pumpWidget(_wrap(channel));

    channel.addToolCallTurn(
      const HermesToolCall(name: 'bash', status: 'running', preview: 'ls -la'),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-tool-turn-tool-0')),
      findsOneWidget,
    );
    expect(find.text('bash'), findsOneWidget);
    expect(find.text('ls -la'), findsOneWidget);
    // Not rendered as a plain chat bubble alongside user/assistant text.
    expect(find.text('tool.started: bash'), findsNothing);
  });
}

class _FailingConnectHermesChannel extends FakeHermesChannel {
  _FailingConnectHermesChannel()
    : super(status: HermesConnectionStatus.disconnected);

  @override
  Future<void> connect({required String baseUrl, String? apiKey}) async {
    // Connecting fails; state stays disconnected/error rather than connected.
  }
}

const _realtimeVoiceCapabilitiesFixture = HermesCapabilityDocument(
  object: 'hermes.api_server.capabilities',
  platform: 'hermes-agent',
  model: 'hermes-agent',
  auth: HermesAuthCapability(type: 'bearer', required: true),
  features: {'realtime_voice': true},
  endpoints: {},
);

const _capabilitiesFixture = HermesCapabilityDocument(
  object: 'hermes.api_server.capabilities',
  platform: 'hermes-agent',
  model: 'hermes-agent',
  auth: HermesAuthCapability(type: 'bearer', required: true),
  features: {
    'session_chat_streaming': true,
    'run_submission': true,
    'run_status': true,
    'run_events_sse': true,
    'run_stop': true,
    'run_approval_response': true,
    'tool_progress_events': true,
    'realtime_voice': false,
  },
  endpoints: {
    'session_chat_stream': HermesEndpointCapability(
      method: 'POST',
      path: '/api/sessions/{session_id}/chat/stream',
    ),
    'session_update': HermesEndpointCapability(
      method: 'PATCH',
      path: '/api/sessions/{session_id}',
    ),
    'session_delete': HermesEndpointCapability(
      method: 'DELETE',
      path: '/api/sessions/{session_id}',
    ),
    'session_fork': HermesEndpointCapability(
      method: 'POST',
      path: '/api/sessions/{session_id}/fork',
    ),
    'runs': HermesEndpointCapability(method: 'POST', path: '/v1/runs'),
    'run_status': HermesEndpointCapability(
      method: 'GET',
      path: '/v1/runs/{run_id}',
    ),
    'run_events': HermesEndpointCapability(
      method: 'GET',
      path: '/v1/runs/{run_id}/events',
    ),
    'run_approval': HermesEndpointCapability(
      method: 'POST',
      path: '/v1/runs/{run_id}/approval',
    ),
    'run_stop': HermesEndpointCapability(
      method: 'POST',
      path: '/v1/runs/{run_id}/stop',
    ),
  },
);
