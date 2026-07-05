import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  testWidgets('shows auth recovery copy without echoing secrets', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.error,
      errorMessage: '401 unauthorized for Bearer secret-api-key',
    );
    await tester.pumpWidget(_wrap(channel));

    expect(find.text('Hermes API rejected the API key.'), findsOneWidget);
    expect(
      find.text('Check the endpoint API key in Hermes and try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('secret-api-key'), findsNothing);
  });

  testWidgets('shows offline recovery copy for unreachable endpoints', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.error,
      errorMessage: 'SocketException: connection refused',
    );
    await tester.pumpWidget(_wrap(channel));

    expect(find.text('Hermes endpoint is unreachable.'), findsOneWidget);
    expect(
      find.text(
        'Check the base URL, network, VPN, and that Hermes API server is running.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows offline recovery copy for broader network failures', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.error,
      errorMessage: 'HandshakeException: Network is unreachable',
    );
    await tester.pumpWidget(_wrap(channel));

    expect(find.text('Hermes endpoint is unreachable.'), findsOneWidget);
    expect(
      find.text(
        'Check the base URL, network, VPN, and that Hermes API server is running.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows offline recovery copy for common OS network resets', (
    tester,
  ) async {
    final connectChannel = FakeHermesChannel(
      status: HermesConnectionStatus.error,
      errorMessage: 'ECONNRESET: broken pipe for Bearer secret-net-key',
    );
    await tester.pumpWidget(_wrap(connectChannel));

    expect(find.text('Hermes endpoint is unreachable.'), findsOneWidget);
    expect(find.textContaining('secret-net-key'), findsNothing);

    final chatChannel = FakeHermesChannel(
      errorMessage: 'SocketException: No route to host, errno = ECONNREFUSED',
    );
    await tester.pumpWidget(_wrap(chatChannel));
    await tester.pumpAndSettle();

    expect(find.text('Hermes stream dropped.'), findsOneWidget);
    expect(
      find.text(
        'Check the endpoint/network and send again when Hermes is reachable.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hermes-chat-error-reconnect')),
      findsOneWidget,
    );
  });

  testWidgets('shows offline recovery copy for DNS/abort failures', (
    tester,
  ) async {
    final connectChannel = FakeHermesChannel(
      status: HermesConnectionStatus.error,
      errorMessage:
          'SocketException: Temporary failure in name resolution for secret-dns-token',
    );
    await tester.pumpWidget(_wrap(connectChannel));

    expect(find.text('Hermes endpoint is unreachable.'), findsOneWidget);
    expect(find.textContaining('secret-dns-token'), findsNothing);

    final chatChannel = FakeHermesChannel(
      errorMessage:
          'SocketException: Software caused connection abort; name or service not known',
    );
    await tester.pumpWidget(_wrap(chatChannel));
    await tester.pumpAndSettle();

    expect(find.text('Hermes stream dropped.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('hermes-chat-error-reconnect')),
      findsOneWidget,
    );
  });

  testWidgets('shows expired API key recovery copy without secrets', (
    tester,
  ) async {
    final connectChannel = FakeHermesChannel(
      status: HermesConnectionStatus.error,
      errorMessage: '419 token expired for secret-expired-key',
    );
    await tester.pumpWidget(_wrap(connectChannel));

    expect(find.text('Hermes API rejected the API key.'), findsOneWidget);
    expect(
      find.text('Check the endpoint API key in Hermes and try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('secret-expired-key'), findsNothing);

    final chatChannel = FakeHermesChannel(
      errorMessage: 'invalid token expired for secret-expired-key',
    );
    await tester.pumpWidget(_wrap(chatChannel));
    await tester.pumpAndSettle();

    expect(find.text('Hermes API rejected the saved API key.'), findsOneWidget);
    expect(
      find.text(
        'Reconnect with a fresh Hermes API key, then retry this message.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('secret-expired-key'), findsNothing);
    expect(
      find.byKey(const ValueKey('hermes-chat-error-reconnect')),
      findsOneWidget,
    );
  });

  testWidgets('shows in-chat auth recovery copy without secrets', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      errorMessage: '403 forbidden for Bearer secret-stream-key',
    );
    final store = FakeHermesEndpointStore(
      initial: const HermesEndpointConfig(baseUrl: 'http://127.0.0.1:8642'),
    );
    await tester.pumpWidget(_wrap(channel, endpointStore: store));

    expect(find.byKey(const ValueKey('hermes-chat-error')), findsOneWidget);
    expect(find.text('Hermes API rejected the saved API key.'), findsOneWidget);
    expect(
      find.text(
        'Reconnect with a fresh Hermes API key, then retry this message.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('secret-stream-key'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('hermes-chat-error-reconnect')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-disconnect-confirm-dialog')),
      findsOneWidget,
    );
    expect(store.clearCalls, 0);
    expect(find.textContaining('secret-stream-key'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('hermes-disconnect-confirm')));
    await tester.pumpAndSettle();

    expect(store.clearCalls, 1);
    expect(find.byKey(const ValueKey('hermes-connect-button')), findsOneWidget);
    expect(find.textContaining('secret-stream-key'), findsNothing);
  });

  testWidgets('in-chat error details sheet redacts raw failures', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      errorMessage:
          'SocketException failed for Authorization: Bearer secret-stream-token and https://user:pass@example.test/path /home/alice/.hermes/config.json C:\\Users\\Alice\\.hermes\\config.json',
    );
    await tester.pumpWidget(_wrap(channel));

    await tester.tap(find.byKey(const ValueKey('hermes-chat-error-details')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-error-details-sheet')),
      findsOneWidget,
    );
    expect(find.text('Redacted error details'), findsOneWidget);
    expect(find.textContaining('secret-stream-token'), findsNothing);
    expect(find.textContaining('user:pass'), findsNothing);
    expect(find.textContaining('Bearer [redacted]'), findsOneWidget);
    expect(
      find.textContaining('https://[redacted]@example.test'),
      findsOneWidget,
    );
    expect(find.textContaining('[redacted-path]'), findsWidgets);
    expect(
      find.textContaining('/home/alice/.hermes/config.json'),
      findsNothing,
    );
    expect(
      find.textContaining('C:\\Users\\Alice\\.hermes\\config.json'),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('hermes-error-details-redaction-note')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hermes-error-details-copy')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('hermes-error-details-copy')));
    await tester.pump();

    expect(find.text('Copied redacted Hermes error details.'), findsOneWidget);
  });

  testWidgets('connect error details sheet redacts raw failures', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.error,
      errorMessage:
          '401 unauthorized for api_key=secret-connect-token at https://user:pass@example.test',
    );
    await tester.pumpWidget(_wrap(channel));

    await tester.ensureVisible(
      find.byKey(const ValueKey('hermes-connect-error-details')),
    );
    await tester.tap(
      find.byKey(const ValueKey('hermes-connect-error-details')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-error-details-sheet')),
      findsOneWidget,
    );
    expect(find.text('Hermes API rejected the API key.'), findsWidgets);
    expect(find.textContaining('secret-connect-token'), findsNothing);
    expect(find.textContaining('user:pass'), findsNothing);
    expect(find.textContaining('api_key=[redacted]'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('hermes-error-details-copy')),
      findsOneWidget,
    );
  });

  testWidgets('hides retry when chat transport is unavailable', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _noChatTransportCapabilitiesFixture,
    );
    channel.addFailedExchange('cannot retry yet');
    await tester.pumpWidget(_wrap(channel));

    expect(find.byKey(const ValueKey('hermes-chat-error')), findsOneWidget);
    expect(find.byKey(const ValueKey('hermes-chat-error-retry')), findsNothing);
    expect(find.text('echo: cannot retry yet'), findsNothing);
  });

  testWidgets('shows bounded copy for unsupported chat transport errors', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _noChatTransportCapabilitiesFixture,
    );
    channel.addFailedExchange(
      'cannot send here',
      errorMessage:
          'Hermes did not advertise a supported chat transport for this endpoint.',
    );
    await tester.pumpWidget(_wrap(channel));

    expect(
      find.text('Hermes endpoint does not support chat turns.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Connect to a Hermes API server that advertises session chat streaming or run events.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('hermes-chat-error-retry')), findsNothing);
  });

  testWidgets('shows stream recovery copy for run event stream failures', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.addFailedExchange(
      'needs events',
      errorMessage: 'Hermes run event stream failed to open: events offline',
    );
    await tester.pumpWidget(_wrap(channel));

    expect(find.text('Hermes stream dropped.'), findsOneWidget);
    expect(
      find.text(
        'Check the endpoint/network and send again when Hermes is reachable.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hermes-chat-error-retry')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hermes-chat-error-reconnect')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('hermes-chat-error-reconnect')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-disconnect-confirm-dialog')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('hermes-disconnect-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('hermes-connect-button')), findsOneWidget);
  });

  testWidgets('shows bounded copy for malformed approval requests', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.addFailedExchange(
      'needs approval',
      errorMessage: 'Hermes approval request was missing an approval id.',
    );
    await tester.pumpWidget(_wrap(channel));

    expect(
      find.text('Hermes sent an incomplete approval request.'),
      findsOneWidget,
    );
    expect(
      find.text('Retry when Hermes can provide an approval id for this run.'),
      findsOneWidget,
    );
  });

  testWidgets('shows bounded copy for terminal Hermes run events', (
    tester,
  ) async {
    final cancelled = FakeHermesChannel();
    cancelled.addFailedExchange(
      'cancelled turn',
      errorMessage: 'Hermes run was cancelled.',
    );
    await tester.pumpWidget(_wrap(cancelled));

    expect(find.text('Hermes run was cancelled.'), findsOneWidget);
    expect(find.text('Start a new turn when you are ready.'), findsOneWidget);

    final failed = FakeHermesChannel();
    failed.addFailedExchange('failed turn', errorMessage: 'Hermes run failed.');
    await tester.pumpWidget(_wrap(failed));
    await tester.pumpAndSettle();

    expect(find.text('Hermes run failed.'), findsOneWidget);
    expect(
      find.text(
        'Check Hermes, then retry this message when the run is recoverable.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('hides failed-turn retry while another turn is active', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.addFailedExchange('failed turn');
    channel.beginStreamingTurn('active turn');
    await tester.pumpWidget(_wrap(channel));

    expect(find.byKey(const ValueKey('hermes-chat-error')), findsOneWidget);
    expect(find.byKey(const ValueKey('hermes-chat-error-retry')), findsNothing);

    channel.completeStreamingTurn();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-chat-error-retry')),
      findsOneWidget,
    );
  });

  testWidgets('retries the last failed Hermes text turn from chat error', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.addFailedExchange('retry the report');
    await tester.pumpWidget(_wrap(channel));

    expect(find.byKey(const ValueKey('hermes-chat-error')), findsOneWidget);
    expect(find.text('Hermes stream dropped.'), findsOneWidget);
    expect(find.text('Retry last message'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('hermes-chat-error-retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('hermes-chat-error')), findsNothing);
    expect(find.text('echo: retry the report'), findsOneWidget);
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
        jobs: const [
          HermesJob(
            id: 'job_1',
            name: 'Morning check',
            enabled: true,
            state: 'idle',
            scheduleDisplay: 'Every day at 09:00',
            nextRunAt: '2026-07-05T09:00:00Z',
            lastError: 'token=secret-job-token',
          ),
        ],
      );
      await tester.pumpWidget(_wrap(channel));

      expect(
        find.byKey(const ValueKey('hermes-capability-strip')),
        findsOneWidget,
      );
      expect(find.text('Hermes Agent hermes-agent'), findsOneWidget);
      expect(find.text('Runs SSE enabled'), findsOneWidget);
      expect(find.text('Voice: device STT -> Hermes text'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Continuous voice — device STT to Hermes text'),
        findsOneWidget,
      );
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
      expect(
        find.byKey(const ValueKey('hermes-admin-surfaces-note')),
        findsOneWidget,
      );
      expect(find.text('Server realtime voice/audio'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Jobs/schedules admin'),
        240,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Jobs/schedules admin'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Messaging gateways'),
        240,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Messaging gateways'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Persona/SOUL'),
        240,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Persona/SOUL'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Raw diagnostics/log export'),
        240,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Raw diagnostics/log export'), findsOneWidget);
      expect(find.text('Deferred'), findsWidgets);
      expect(
        find.byKey(const ValueKey('hermes-surfaces-copy')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('hermes-surfaces-copy')));
      await tester.pump();
      expect(
        find.text('Copied Hermes surface readiness summary.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('hermes-skills-chip')));
      await tester.pumpAndSettle();
      expect(find.text('Hermes skills'), findsOneWidget);
      expect(find.text('github'), findsOneWidget);
      expect(find.text('ascii-art'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('hermes-jobs-chip')));
      await tester.pumpAndSettle();
      expect(find.text('Hermes jobs'), findsOneWidget);
      expect(
        find.text(
          'Read-only inventory. Mobile create/edit/delete scheduling is not available.',
        ),
        findsOneWidget,
      );
      expect(find.text('Morning check'), findsOneWidget);
      expect(
        find.textContaining('Schedule: Every day at 09:00'),
        findsOneWidget,
      );
      expect(find.textContaining('Next: 2026-07-05T09:00:00Z'), findsOneWidget);
      expect(find.textContaining('token=[redacted]'), findsOneWidget);
      expect(find.textContaining('secret-job-token'), findsNothing);
    },
  );

  testWidgets('attachments control explains deferred mobile media safely', (
    tester,
  ) async {
    final channel = FakeHermesChannel(capabilities: _attachmentsCapabilities);
    await tester.pumpWidget(_wrap(channel));

    await tester.tap(find.byKey(const ValueKey('hermes-attachments-button')));
    await tester.pumpAndSettle();

    expect(find.text('Hermes attachments/media'), findsOneWidget);
    expect(
      find.textContaining('advertises attachments or multimodal chat'),
      findsOneWidget,
    );
    expect(
      find.textContaining('No files, photos, transcripts, or local paths'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('hermes-attachments-close')));
    await tester.pumpAndSettle();
    expect(find.text('Hermes attachments/media'), findsNothing);
  });

  testWidgets('files/context control explains deferred mobile files safely', (
    tester,
  ) async {
    const filesCapabilities = HermesCapabilityDocument(
      object: 'hermes.api_server.capabilities',
      platform: 'hermes-agent',
      model: 'hermes-agent',
      auth: HermesAuthCapability(type: 'bearer', required: true),
      features: {
        'session_chat_streaming': true,
        'files_api': true,
        'context_folders_api': true,
      },
      endpoints: {
        'session_chat_stream': HermesEndpointCapability(
          method: 'POST',
          path: '/api/sessions/{session_id}/chat/stream',
        ),
      },
    );
    final channel = FakeHermesChannel(capabilities: filesCapabilities);
    await tester.pumpWidget(_wrap(channel));

    await tester.tap(find.byKey(const ValueKey('hermes-files-context-button')));
    await tester.pumpAndSettle();

    expect(find.text('Hermes files/context folders'), findsOneWidget);
    expect(
      find.textContaining('advertises file or context-folder capabilities'),
      findsOneWidget,
    );
    expect(
      find.textContaining('No local file paths, folder names, transcripts'),
      findsOneWidget,
    );
    expect(find.textContaining('/Users/'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('hermes-files-context-close')));
    await tester.pumpAndSettle();
    expect(find.text('Hermes files/context folders'), findsNothing);
  });

  testWidgets('jobs dialog stays read-only when jobs admin is advertised', (
    tester,
  ) async {
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    const jobsAdminCapabilities = HermesCapabilityDocument(
      object: 'hermes.api_server.capabilities',
      platform: 'hermes-agent',
      model: 'hermes-agent',
      auth: HermesAuthCapability(type: 'bearer', required: true),
      features: {'jobs_admin': true},
      endpoints: {
        'jobs': HermesEndpointCapability(method: 'GET', path: '/api/jobs'),
      },
    );
    final channel = FakeHermesChannel(
      capabilities: jobsAdminCapabilities,
      jobs: const [
        HermesJob(
          id: 'job_1',
          name: 'Morning check',
          state: 'idle',
          scheduleDisplay: 'Every day at 09:00',
          lastError: 'token=secret-job-token',
        ),
      ],
    );
    await tester.pumpWidget(_wrap(channel));

    await tester.tap(find.byKey(const ValueKey('hermes-jobs-chip')));
    await tester.pumpAndSettle();

    expect(find.text('Hermes jobs'), findsOneWidget);
    expect(
      find.text(
        'Read-only inventory. Hermes advertises jobs admin, but Navivox has not enabled mobile create/edit/delete scheduling.',
      ),
      findsOneWidget,
    );
    expect(find.text('Morning check'), findsOneWidget);
    expect(find.text('Create'), findsNothing);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsNothing);
    expect(find.byKey(const ValueKey('hermes-job-copy-job_1')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('hermes-job-copy-job_1')));
    await tester.pump();

    expect(find.text('Copied redacted Hermes job details.'), findsOneWidget);
    expect(copiedText, contains('Hermes job'));
    expect(copiedText, contains('Morning check'));
    expect(copiedText, contains('token=[redacted]'));
    expect(copiedText, isNot(contains('secret-job-token')));
  });

  testWidgets('capability detail lists redact secret-looking values', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilitiesFixture,
      models: const [
        'Bearer secret-model-token verbose model details verbose model details verbose model details model-tail',
        'ghp_'
            'abcdefghijklmnopqrstuvwxyz123456',
      ],
      skills: const [
        'github',
        'token=secret-skill-token verbose skill details verbose skill details verbose skill details verbose skill details verbose skill details verbose skill details verbose skill details verbose skill details skill-tail',
      ],
      enabledToolsets: const [
        'api_key=secret-toolset-key verbose toolset details verbose toolset details verbose toolset details verbose toolset details verbose toolset details verbose toolset details verbose toolset details verbose toolset details toolset-tail',
      ],
      jobs: const [
        HermesJob(
          id: 'job_1',
          name:
              'secret-job-token verbose job details verbose job details verbose job details verbose job details verbose job details verbose job details verbose job details verbose job details job-tail',
        ),
      ],
    );
    await tester.pumpWidget(_wrap(channel));

    expect(find.textContaining('Bearer [redacted]'), findsOneWidget);
    expect(find.textContaining('ghp_[redacted]'), findsOneWidget);
    expect(find.textContaining('secret-model-token'), findsNothing);
    expect(
      find.textContaining(
        'ghp_'
        'abcdefghijklmnopqrstuvwxyz123456',
      ),
      findsNothing,
    );
    expect(find.textContaining('model-tail'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('hermes-skills-chip')));
    await tester.pumpAndSettle();
    expect(find.textContaining('token=[redacted]'), findsOneWidget);
    expect(find.textContaining('secret-skill-token'), findsNothing);
    expect(find.textContaining('skill-tail'), findsNothing);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hermes-toolsets-chip')));
    await tester.pumpAndSettle();
    expect(find.textContaining('api_key=[redacted]'), findsOneWidget);
    expect(find.textContaining('secret-toolset-key'), findsNothing);
    expect(find.textContaining('toolset-tail'), findsNothing);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hermes-jobs-chip')));
    await tester.pumpAndSettle();
    expect(find.textContaining('[redacted]'), findsAtLeastNWidgets(1));
    expect(find.textContaining('secret-job-token'), findsNothing);
    expect(find.textContaining('job-tail'), findsNothing);
  });

  testWidgets('health chips redact and bound secret-looking values', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilitiesFixture,
      detailedHealth: const HermesHealthStatus(
        status: 'ok',
        platform: 'hermes-agent',
        version:
            'secret-version-token verbose version details verbose version details verbose version details version-tail',
        gatewayState:
            'token=secret-gateway-token verbose gateway details verbose gateway details verbose gateway details gateway-tail',
        activeAgents: 0,
      ),
    );
    await tester.pumpWidget(_wrap(channel));

    expect(find.textContaining('Version: [redacted]'), findsOneWidget);
    expect(find.textContaining('Gateway: token=[redacted]'), findsOneWidget);
    expect(find.textContaining('secret-version-token'), findsNothing);
    expect(find.textContaining('secret-gateway-token'), findsNothing);
    expect(find.textContaining('version-tail'), findsNothing);
    expect(find.textContaining('gateway-tail'), findsNothing);
  });

  testWidgets('disables composer when no chat transport is advertised', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: const HermesCapabilityDocument(
        object: 'hermes.api_server.capabilities',
        platform: 'hermes-agent',
        model: 'hermes-agent',
        auth: HermesAuthCapability(type: 'bearer', required: false),
        features: {},
        endpoints: {},
      ),
    );
    await tester.pumpWidget(_wrap(channel));

    expect(
      find.byKey(const ValueKey('hermes-chat-transport-unavailable')),
      findsOneWidget,
    );
    final composer = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    expect(composer.enabled, isFalse);
    expect(composer.decoration?.hintText, 'Chat transport unavailable');
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('hermes-send-button')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('hermes-mic-button')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<Switch>(
            find.byKey(const ValueKey('hermes-continuous-voice-switch')),
          )
          .onChanged,
      isNull,
    );
  });

  testWidgets(
    'advertised realtime voice still explains Navivox uses device STT',
    (tester) async {
      final channel = FakeHermesChannel(
        capabilities: _realtimeVoiceCapabilitiesFixture,
      );
      await tester.pumpWidget(_wrap(channel));

      expect(
        find.text(
          'Server audio advertised; Navivox uses device STT -> Hermes text',
        ),
        findsOneWidget,
      );
      expect(find.text('Server realtime voice advertised'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('hermes-surfaces-chip')));
      await tester.pumpAndSettle();
      expect(find.text('Server realtime voice/audio'), findsOneWidget);
      expect(find.text('Blocked'), findsWidgets);
    },
  );

  testWidgets(
    'advertised generic audio API is blocked until server audio is wired',
    (tester) async {
      final channel = FakeHermesChannel(
        capabilities: const HermesCapabilityDocument(
          object: 'hermes.api_server.capabilities',
          platform: 'hermes-agent',
          model: 'hermes-agent',
          auth: HermesAuthCapability(type: 'bearer', required: true),
          features: {'audio_api': true},
          endpoints: {},
        ),
      );
      await tester.pumpWidget(_wrap(channel));

      expect(
        find.text(
          'Server audio advertised; Navivox uses device STT -> Hermes text',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('hermes-surfaces-chip')));
      await tester.pumpAndSettle();
      expect(find.text('Server realtime voice/audio'), findsOneWidget);
      expect(
        find.textContaining('server audio/realtime voice is advertised'),
        findsOneWidget,
      );
      expect(find.text('Blocked'), findsWidgets);
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
    expect(export, contains('Run stop: available'));
    expect(export, contains('Run approval response: available'));
    expect(export, contains('Tool progress events: advertised'));
    expect(export, contains('Realtime voice: not advertised'));
    expect(export, contains('Audio API: not advertised'));
    expect(
      export,
      contains('Voice path: device STT -> Hermes text; server audio not wired'),
    );
    expect(export, contains('Config write: not advertised'));
    expect(export, contains('Memory write: not advertised'));
    expect(export, contains('Endpoint routes:'));
    expect(
      export,
      contains(
        'session_chat_stream=POST /api/sessions/{session_id}/chat/stream',
      ),
    );
    expect(export, contains('Surface readiness:'));
    expect(export, contains('Server realtime voice/audio: Deferred'));
    expect(export, isNot(contains('Legacy durable reconnect')));
    expect(export, contains('Jobs: 1'));
    expect(export, contains('Secrets: excluded'));
    expect(export, contains('Raw logs: excluded'));
    expect(export, contains('Tool payloads: excluded'));
    expect(export, contains('Transcripts: excluded'));
    expect(export, contains('Local paths: excluded'));
    expect(export, isNot(contains('Authorization')));
    expect(export, isNot(contains('secret')));
    expect(export, isNot(contains('NAVIVOX_DO_NOT_EXPORT_TOKEN')));
    expect(export, isNot(contains('raw_tool_payload')));
  });

  test('Hermes diagnostics redacts dynamic metadata fields', () {
    final export = hermesDiagnosticsExport(
      HermesChannelState(
        status: HermesConnectionStatus.connected,
        capabilities: const HermesCapabilityDocument(
          object: 'hermes.api_server.capabilities',
          platform: 'hermes-agent',
          model: 'secret-model-token',
          auth: HermesAuthCapability(type: 'bearer', required: true),
          features: {
            'session_chat_streaming': true,
            'api_key=secret-feature-key': true,
            'Set-Cookie: session=secret-cookie-token': true,
            'ghp_'
                    'abcdefghijklmnopqrstuvwxyz123456':
                true,
          },
          endpoints: {
            'Authorization: Bearer secret-endpoint-token':
                HermesEndpointCapability(method: 'GET', path: '/safe'),
            'xoxb-'
                '123456789012-abcdefabcdefabcdef': HermesEndpointCapability(
              method: 'GET',
              path: '/slack',
            ),
          },
        ),
        detailedHealth: const HermesHealthStatus(
          status:
              'ok token=secret-status-token eyJhbGciOiJIUzI1NiJ9.'
              'eyJzdWIiOiIxMjM0NTY3ODkwIn0.signaturevalue',
          platform:
              'https://user:secret-url-pass@example.test/api /home/alice/.hermes/config.json',
          version: 'sk-1234567890abcdef',
          gatewayState:
              'Authorization: Bearer secret-gateway-token Cookie: sid=secret-cookie-token Basic secret-basic-token C:\\Users\\Alice\\.hermes\\config.json',
          activeAgents: 1,
        ),
        models: const ['model-secret-model-token'],
        sessions: const [
          HermesSession(
            id: 'sess_1',
            source: 'fake',
            title: 'Ops secret-session-token',
          ),
        ],
        activeSessionId: 'sess_1',
      ),
    );

    expect(export, contains('[redacted]'));
    expect(export, contains('sk-[redacted]'));
    expect(export, isNot(contains('secret-model-token')));
    expect(export, isNot(contains('secret-feature-key')));
    expect(export, isNot(contains('secret-cookie-token')));
    expect(export, isNot(contains('secret-url-pass')));
    expect(export, isNot(contains('secret-basic-token')));
    expect(export, isNot(contains('secret-endpoint-token')));
    expect(export, isNot(contains('secret-status-token')));
    expect(
      export,
      isNot(
        contains(
          'ghp_'
          'abcdefghijklmnopqrstuvwxyz123456',
        ),
      ),
    );
    expect(
      export,
      isNot(
        contains(
          'xoxb-'
          '123456789012-abcdefabcdefabcdef',
        ),
      ),
    );
    expect(export, isNot(contains('eyJhbGciOiJIUzI1NiJ9')));
    expect(export, isNot(contains('secret-gateway-token')));
    expect(export, isNot(contains('secret-session-token')));
    expect(export, contains('[redacted-path]'));
    expect(export, isNot(contains('/home/alice/.hermes/config.json')));
    expect(export, isNot(contains('C:\\Users\\Alice\\.hermes\\config.json')));
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
    expect(diagnostics.data, contains('Run stop: available'));
    expect(diagnostics.data, contains('Run approval response: available'));
    expect(diagnostics.data, contains('Secrets: excluded'));
    expect(diagnostics.data, isNot(contains('Authorization')));
  });

  testWidgets('session selection failures show bounded recovery feedback', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilitiesFixture,
      selectSessionFails: true,
      selectSessionFailureMessage:
          '${List.filled(20, 'select failed detail').join(' ')} tail-marker',
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

    expect(channel.selectSessionCalls, ['sess_2']);
    expect(channel.state.activeSessionId, 'sess_1');
    expect(find.textContaining('Could not open session:'), findsOneWidget);
    expect(find.textContaining('tail-marker'), findsNothing);
  });

  testWidgets('session failure feedback redacts secrets', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilitiesFixture,
      selectSessionFails: true,
      selectSessionFailureMessage:
          '403 Bearer secret-session-key Authorization: Basic c2VjcmV0 https://admin:hunter2@x.test?password=hunter2 X-API-Key: secret-header-key; Cookie: secret-cookie; auth=secret-auth',
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

    final feedback = tester.widget<Text>(
      find.textContaining('Could not open session:'),
    );
    final text = feedback.data!;
    expect(text, contains('[redacted]'));
    expect(text.length, lessThanOrEqualTo(200));
    expect(text, isNot(contains('secret-session-key')));
    expect(text, isNot(contains('secret-api-key')));
    expect(text, isNot(contains('hunter2')));
    expect(text, isNot(contains('c2VjcmV0')));
    expect(text, isNot(contains('secret-header-key')));
    expect(text, isNot(contains('secret-cookie')));
    expect(text, isNot(contains('secret-auth')));
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

  testWidgets('session changes clear stale pending approval banners', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilitiesFixture,
      sessions: const [
        HermesSession(id: 'sess_1', source: 'fake', title: 'One'),
        HermesSession(id: 'sess_2', source: 'fake', title: 'Two'),
      ],
    );
    await tester.pumpWidget(_wrap(channel));

    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: 'appr_1',
        toolCallId: 'call_1',
        prompt: 'Approve stale session action?',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Approve stale session action?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('hermes-sessions-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hermes-session-row-sess_2')));
    await tester.pumpAndSettle();

    expect(channel.state.activeSessionId, 'sess_2');
    expect(find.text('Approve stale session action?'), findsNothing);
    expect(channel.respondToApprovalCalls, isEmpty);
  });

  testWidgets(
    'late approval response does not remove same-id approval in new session',
    (tester) async {
      final approvalGate = Completer<void>();
      final channel = FakeHermesChannel(
        capabilities: _capabilitiesFixture,
        approvalResponseGate: () => approvalGate.future,
        sessions: const [
          HermesSession(id: 'sess_1', source: 'fake', title: 'One'),
          HermesSession(id: 'sess_2', source: 'fake', title: 'Two'),
        ],
      );
      await tester.pumpWidget(_wrap(channel));

      channel.emitApprovalRequest(
        const NavivoxApprovalRequest(
          id: 'appr_same',
          toolCallId: 'call_old',
          prompt: 'Approve old session action?',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('hermes-approval-once')));
      await tester.pump();

      await channel.selectSession('sess_2');
      await tester.pump();

      channel.emitApprovalRequest(
        const NavivoxApprovalRequest(
          id: 'appr_same',
          toolCallId: 'call_new',
          prompt: 'Approve new session action?',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Approve new session action?'), findsOneWidget);

      approvalGate.complete();
      await tester.pump();
      await tester.pump();

      expect(find.text('Approve new session action?'), findsOneWidget);
      expect(channel.respondToApprovalCalls, [
        {'approvalId': 'appr_same', 'decision': HermesApprovalDecision.once},
      ]);
    },
  );

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

    expect(find.text('Showing 1 of 2 sessions'), findsOneWidget);
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

  testWidgets('sessions panel redacts secret-looking session metadata', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilitiesFixture,
      sessions: const [
        HermesSession(
          id: 'sess_1',
          source: 'fake',
          title:
              'Bearer secret-session-token verbose active title details verbose active title details verbose active title details active-title-tail',
          preview:
              'api_key=secret-preview-key verbose session preview details verbose session preview details verbose session preview details verbose session preview details verbose session preview details session-preview-tail',
          parentSessionId: 'secret-parent-token',
          lastActive: 'token=secret-last-active timestamp-tail',
        ),
      ],
    );
    await tester.pumpWidget(_wrap(channel));

    await tester.tap(find.byKey(const ValueKey('hermes-sessions-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Bearer [redacted]'), findsAtLeastNWidgets(1));
    expect(find.textContaining('api_key=[redacted]'), findsOneWidget);
    expect(find.textContaining('Forked from [redacted]'), findsOneWidget);
    expect(find.textContaining('secret-session-token'), findsNothing);
    expect(find.textContaining('secret-preview-key'), findsNothing);
    expect(find.textContaining('secret-parent-token'), findsNothing);
    expect(find.textContaining('secret-last-active'), findsNothing);
    expect(find.textContaining('active-title-tail'), findsNothing);
    expect(find.textContaining('session-preview-tail'), findsNothing);
  });

  testWidgets('session search does not match redacted secret metadata', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilitiesFixture,
      sessions: const [
        HermesSession(
          id: 'sess_1',
          source: 'fake',
          title: 'Bearer secret-session-token',
          preview: 'api_key=secret-preview-key',
          parentSessionId: 'secret-parent-token',
        ),
        HermesSession(id: 'sess_2', source: 'fake', title: 'Visible ops'),
      ],
    );
    await tester.pumpWidget(_wrap(channel));

    await tester.tap(find.byKey(const ValueKey('hermes-sessions-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('hermes-session-search-field')),
      'secret-preview-key',
    );
    await tester.pumpAndSettle();

    expect(find.text('No Hermes sessions match “[redacted]”.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('hermes-session-row-sess_1')),
      findsNothing,
    );
    expect(find.textContaining('secret-session-token'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('hermes-session-search-field')),
      '[redacted]',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-session-row-sess_1')),
      findsNothing,
    );
    expect(find.text('No Hermes sessions match “[redacted]”.'), findsOneWidget);
  });

  testWidgets('sessions panel groups active, forked, and other sessions', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilitiesFixture,
      sessions: const [
        HermesSession(id: 'sess_1', source: 'fake', title: 'Active ops'),
        HermesSession(id: 'sess_2', source: 'fake', title: 'Backlog'),
        HermesSession(
          id: 'fork_1',
          source: 'fake',
          title: 'Forked incident',
          parentSessionId: 'sess_1',
        ),
      ],
    );
    await tester.pumpWidget(_wrap(channel));

    await tester.tap(find.byKey(const ValueKey('hermes-sessions-button')));
    await tester.pumpAndSettle();

    expect(find.text('Active session'), findsOneWidget);
    expect(find.text('Forked sessions'), findsOneWidget);
    expect(find.text('Other sessions'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('hermes-session-row-sess_1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hermes-session-row-fork_1')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('hermes-session-search-field')),
      'forked',
    );
    await tester.pumpAndSettle();

    expect(find.text('Showing 1 of 3 sessions'), findsOneWidget);
    expect(find.text('Active session'), findsNothing);
    expect(find.text('Forked sessions'), findsOneWidget);
    expect(find.text('Other sessions'), findsNothing);
    expect(
      find.byKey(const ValueKey('hermes-session-row-fork_1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hermes-session-row-sess_1')),
      findsNothing,
    );
  });

  testWidgets('sessions panel can search forked sessions by group label', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      sessions: const [
        HermesSession(id: 'active', source: 'fake', title: 'Active'),
        HermesSession(
          id: 'branch_1',
          source: 'fake',
          title: 'Incident branch',
          parentSessionId: 'root_parent',
        ),
      ],
    );
    await tester.pumpWidget(_wrap(channel));

    await tester.tap(find.byKey(const ValueKey('hermes-sessions-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('hermes-session-search-field')),
      'forked',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-session-row-branch_1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hermes-session-row-active')),
      findsNothing,
    );
  });

  testWidgets('sessions panel can search forked sessions by parent id', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      sessions: const [
        HermesSession(id: 'active', source: 'fake', title: 'Active'),
        HermesSession(
          id: 'fork_1',
          source: 'fake',
          title: 'Incident branch',
          parentSessionId: 'root_parent',
        ),
      ],
    );
    await tester.pumpWidget(_wrap(channel));

    await tester.tap(find.byKey(const ValueKey('hermes-sessions-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('hermes-session-search-field')),
      'root_parent',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-session-row-fork_1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hermes-session-row-active')),
      findsNothing,
    );
    expect(find.textContaining('Forked from root_parent'), findsOneWidget);
  });

  testWidgets('sessions panel sorts non-active groups by recent activity', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      sessions: const [
        HermesSession(id: 'active', source: 'fake', title: 'Active'),
        HermesSession(
          id: 'older',
          source: 'fake',
          title: 'Older other',
          lastActive: '2026-01-01T00:00:00Z',
        ),
        HermesSession(
          id: 'newer',
          source: 'fake',
          title: 'Newer other',
          lastActive: '2026-07-01T00:00:00Z',
        ),
      ],
    );
    await tester.pumpWidget(_wrap(channel));

    await tester.tap(find.byKey(const ValueKey('hermes-sessions-button')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Last active 2026-07-01T00:00:00Z'),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.text('Newer other')).dy,
      lessThan(tester.getTopLeft(find.text('Older other')).dy),
    );
  });

  testWidgets('session create actions hide when not advertised', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: const HermesCapabilityDocument(
        object: 'hermes.api_server.capabilities',
        platform: 'hermes-agent',
        model: 'hermes-agent',
        auth: HermesAuthCapability(type: 'bearer', required: false),
        features: {},
        endpoints: {},
      ),
    );
    await tester.pumpWidget(_wrap(channel));

    expect(find.byKey(const ValueKey('hermes-new-session')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('hermes-sessions-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('hermes-sessions-new')), findsNothing);
  });

  testWidgets(
    'sessionless endpoint without create shows actionable empty state',
    (tester) async {
      final channel = FakeHermesChannel(
        capabilities: _noChatTransportCapabilitiesFixture,
        sessions: const [],
      );
      await tester.pumpWidget(_wrap(channel));

      expect(
        find.text(
          'No Hermes sessions are available, and this endpoint did not advertise session creation.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('hermes-new-session')), findsNothing);
      expect(find.byKey(const ValueKey('hermes-transcript')), findsNothing);

      final composer = tester.widget<TextField>(
        find.byKey(const ValueKey('hermes-composer-field')),
      );
      expect(composer.enabled, isFalse);
    },
  );

  testWidgets('new session failures show bounded recovery feedback', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilitiesFixture,
      createSessionFails: true,
    );
    await tester.pumpWidget(_wrap(channel));

    await tester.tap(find.byKey(const ValueKey('hermes-new-session')));
    await tester.pumpAndSettle();

    expect(channel.createSessionCalls, [null]);
    expect(find.textContaining('Could not create session:'), findsOneWidget);
  });

  testWidgets('sessions panel keeps copy details while mutation actions hide', (
    tester,
  ) async {
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final channel = FakeHermesChannel(
      sessions: const [
        HermesSession(
          id: 'sess_1',
          source: 'fake',
          title: 'Secret session token=hidden-token',
          preview: 'Preview with Bearer secret-session-token',
        ),
      ],
    );
    await tester.pumpWidget(_wrap(channel));

    await tester.tap(find.byKey(const ValueKey('hermes-sessions-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-session-row-sess_1')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('hermes-session-menu-sess_1')));
    await tester.pumpAndSettle();

    expect(find.text('Copy details'), findsOneWidget);
    expect(find.text('Rename'), findsNothing);
    expect(find.text('Fork'), findsNothing);
    expect(find.text('Delete'), findsNothing);

    await tester.tap(find.text('Copy details'));
    await tester.pumpAndSettle();

    expect(
      find.text('Copied redacted Hermes session details.'),
      findsOneWidget,
    );
    expect(copiedText, isNotNull);
    expect(copiedText, contains('Hermes session'));
    expect(copiedText, contains('token=[redacted]'));
    expect(copiedText, contains('Bearer [redacted]'));
    expect(copiedText, isNot(contains('hidden-token')));
    expect(copiedText, isNot(contains('secret-session-token')));
  });

  testWidgets('sessions panel clears a filtered search', (tester) async {
    final channel = FakeHermesChannel(
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

    await tester.tap(find.byKey(const ValueKey('hermes-session-search-clear')));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-session-search-field')),
    );
    expect(field.controller?.text, isEmpty);
    expect(
      find.byKey(const ValueKey('hermes-session-row-sess_1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hermes-session-row-sess_2')),
      findsOneWidget,
    );
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

  testWidgets('session no-results query echo is bounded', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilitiesFixture,
      sessions: const [
        HermesSession(id: 'sess_1', source: 'fake', title: 'Incident review'),
      ],
    );
    final longQuery = List.filled(8, 'unmatchedsegment').join('-');
    final preview = '${longQuery.substring(0, 64)}…';
    await tester.pumpWidget(_wrap(channel));

    await tester.tap(find.byKey(const ValueKey('hermes-sessions-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('hermes-session-search-field')),
      longQuery,
    );
    await tester.pumpAndSettle();

    expect(find.text('No Hermes sessions match “$preview”.'), findsOneWidget);
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

  testWidgets('rename dialog does not prefill unsafe or overlong titles', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilitiesFixture,
      sessions: [
        HermesSession(
          id: 'sess_1',
          source: 'fake',
          title: List.filled(8, 'very long existing session title').join(' '),
        ),
      ],
    );
    await tester.pumpWidget(_wrap(channel));

    await tester.tap(find.byKey(const ValueKey('hermes-sessions-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hermes-session-menu-sess_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextFormField>(
      find.byKey(const ValueKey('hermes-session-title-field')),
    );
    expect(field.initialValue, isEmpty);
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
      final channel = FakeHermesChannel(
        capabilities: _capabilitiesFixture,
        sessions: const [
          HermesSession(
            id: 'sess_1',
            source: 'fake',
            title:
                'Delete Bearer secret-delete-token verbose delete title details verbose delete title details verbose delete title details delete-title-tail',
          ),
        ],
      );
      await tester.pumpWidget(_wrap(channel));

      await tester.tap(find.byKey(const ValueKey('hermes-sessions-button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('hermes-session-menu-sess_1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Bearer [redacted]'), findsWidgets);
      expect(find.textContaining('secret-delete-token'), findsNothing);
      expect(find.textContaining('delete-title-tail'), findsNothing);
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

  testWidgets('queues composer text while a Hermes turn is streaming', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('current');
    await tester.pumpWidget(_wrap(channel));

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      'follow up',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-queued-follow-up')),
      findsOneWidget,
    );
    expect(find.textContaining('follow up'), findsOneWidget);
    expect(find.text('echo: follow up'), findsNothing);

    channel.completeStreamingTurn();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('hermes-queued-follow-up')), findsNothing);
    expect(find.text('follow up'), findsOneWidget);
    expect(find.text('echo: follow up'), findsOneWidget);
  });

  testWidgets('queued follow-ups are bounded while streaming', (tester) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('current');
    await tester.pumpWidget(_wrap(channel));

    for (var index = 1; index <= 5; index++) {
      await tester.enterText(
        find.byKey(const ValueKey('hermes-composer-field')),
        'follow up $index',
      );
      await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
      await tester.pump();
    }

    expect(find.textContaining('Queued 5 follow-ups'), findsOneWidget);
    expect(find.textContaining('+3 more'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      'follow up 6',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-queued-follow-up-error')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Queued follow-ups are full (5)'),
      findsOneWidget,
    );
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    expect(field.controller!.text, 'follow up 6');
    expect(find.text('echo: follow up 6'), findsNothing);
  });

  testWidgets('queued follow-up banner redacts secret-looking text', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('current');
    await tester.pumpWidget(_wrap(channel));

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      'use Bearer secret-queued-token and api_key=secret-queued-key',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-queued-follow-up')),
      findsOneWidget,
    );
    expect(find.textContaining('Bearer [redacted]'), findsOneWidget);
    expect(find.textContaining('api_key=[redacted]'), findsOneWidget);
    expect(find.textContaining('secret-queued-token'), findsNothing);
    expect(find.textContaining('secret-queued-key'), findsNothing);

    channel.completeStreamingTurn();
    await tester.pumpAndSettle();

    expect(
      channel.state.activeMessages.any(
        (turn) => turn.text.contains('secret-queued-token'),
      ),
      isTrue,
      reason: 'redaction is display-only; queued send keeps the user text',
    );
  });

  testWidgets('queued follow-up copy details are bounded and redacted', (
    tester,
  ) async {
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('current');
    await tester.pumpWidget(_wrap(channel));

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      'use Bearer secret-queued-token and api_key=secret-queued-key',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('hermes-queued-follow-up-copy')),
    );
    await tester.pump();

    expect(copiedText, contains('Hermes queued follow-ups'));
    expect(copiedText, contains('Queued: 1'));
    expect(copiedText, contains('Bearer [redacted]'));
    expect(copiedText, contains('api_key=[redacted]'));
    expect(copiedText, isNot(contains('secret-queued-token')));
    expect(copiedText, isNot(contains('secret-queued-key')));
    expect(
      find.text('Copied redacted Hermes queued follow-ups.'),
      findsOneWidget,
    );
  });

  testWidgets('queued follow-up clear confirmation is bounded and redacted', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('current');
    await tester.pumpWidget(_wrap(channel));

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      'use Bearer secret-clear-token and api_key=secret-clear-key',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('hermes-queued-follow-up-cancel')),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-queued-follow-up-clear-dialog')),
      findsOneWidget,
    );
    expect(find.textContaining('Bearer [redacted]'), findsWidgets);
    expect(find.textContaining('api_key=[redacted]'), findsWidgets);
    expect(find.textContaining('secret-clear-token'), findsNothing);
    expect(find.textContaining('secret-clear-key'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('hermes-queued-follow-up-clear-keep')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('hermes-queued-follow-up')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('hermes-queued-follow-up-cancel')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('hermes-queued-follow-up-clear-confirm')),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('hermes-queued-follow-up')), findsNothing);
  });

  testWidgets('queued follow-up waits for its original session', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilitiesFixture,
      sessions: const [
        HermesSession(id: 'sess_1', source: 'fake', title: 'One'),
        HermesSession(id: 'sess_2', source: 'fake', title: 'Two'),
      ],
    );
    channel.beginStreamingTurn('current');
    await tester.pumpWidget(_wrap(channel));

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      'stay with session one',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pump();

    await channel.selectSession('sess_2');
    await tester.pump();

    expect(channel.state.activeSessionId, 'sess_2');
    expect(
      find.byKey(const ValueKey('hermes-queued-follow-up')),
      findsOneWidget,
    );
    expect(find.textContaining('stay with session one'), findsOneWidget);
    expect(
      find.textContaining('Waiting for the original session.'),
      findsOneWidget,
    );
    expect(find.text('echo: stay with session one'), findsNothing);
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const ValueKey('hermes-queued-follow-up-send-now')),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(
      find.byKey(const ValueKey('hermes-queued-follow-up-open-session')),
    );
    await tester.pump();

    expect(channel.state.activeSessionId, 'sess_1');
    expect(
      find.byKey(const ValueKey('hermes-queued-follow-up')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Waiting for the original session.'),
      findsNothing,
    );
  });

  testWidgets('queued follow-up open-session failures are bounded', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilitiesFixture,
      sessions: const [
        HermesSession(id: 'sess_1', source: 'fake', title: 'One'),
        HermesSession(id: 'sess_2', source: 'fake', title: 'Two'),
      ],
    );
    channel.beginStreamingTurn('current');
    await tester.pumpWidget(_wrap(channel));

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      'stay with session one',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pump();

    await channel.selectSession('sess_2');
    await tester.pump();
    channel.selectSessionFails = true;
    channel.selectSessionFailureMessage =
        '${List.filled(20, 'secret-open-session-token').join(' ')} tail-marker';

    await tester.tap(
      find.byKey(const ValueKey('hermes-queued-follow-up-open-session')),
    );
    await tester.pumpAndSettle();

    expect(channel.state.activeSessionId, 'sess_2');
    expect(
      find.byKey(const ValueKey('hermes-queued-follow-up')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Could not open queued follow-up session:'),
      findsOneWidget,
    );
    expect(find.textContaining('secret-open-session-token'), findsNothing);
    expect(find.textContaining('tail-marker'), findsNothing);
  });

  testWidgets('queued follow-up clears when its original session is deleted', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilitiesFixture,
      sessions: const [
        HermesSession(id: 'sess_1', source: 'fake', title: 'One'),
        HermesSession(id: 'sess_2', source: 'fake', title: 'Two'),
      ],
    );
    channel.beginStreamingTurn('current');
    await tester.pumpWidget(_wrap(channel));

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      'delete with original session',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pump();

    await channel.selectSession('sess_2');
    await tester.pump();
    expect(
      find.byKey(const ValueKey('hermes-queued-follow-up')),
      findsOneWidget,
    );

    await channel.deleteSession('sess_1');
    await tester.pump();

    expect(find.byKey(const ValueKey('hermes-queued-follow-up')), findsNothing);
    expect(find.textContaining('delete with original session'), findsNothing);
  });

  testWidgets('queued follow-up banner stays bounded with many long messages', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('current');
    await tester.pumpWidget(_wrap(channel));

    for (final text in [
      'first follow up with a deliberately long body that should be shortened',
      'second follow up with enough text to remain visible',
      'third follow up hidden behind the remaining count',
    ]) {
      await tester.enterText(
        find.byKey(const ValueKey('hermes-composer-field')),
        text,
      );
      await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
      await tester.pump();
    }

    expect(find.textContaining('Queued 3 follow-ups'), findsOneWidget);
    expect(
      find.textContaining('first follow up with a deliberately long body'),
      findsOneWidget,
    );
    expect(find.textContaining('+1 more'), findsOneWidget);
    expect(find.textContaining('third follow up hidden behind'), findsNothing);
  });

  testWidgets('queues multiple follow-ups and sends them in order', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('current');
    await tester.pumpWidget(_wrap(channel));

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      'first follow up',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      'second follow up',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pump();

    expect(find.textContaining('Queued 2 follow-ups'), findsOneWidget);
    expect(find.textContaining('first follow up'), findsOneWidget);
    expect(find.textContaining('second follow up'), findsOneWidget);
    expect(find.text('echo: first follow up'), findsNothing);
    expect(find.text('echo: second follow up'), findsNothing);

    channel.completeStreamingTurn();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('hermes-queued-follow-up')), findsNothing);
    expect(
      channel.state.activeMessages.map((turn) => turn.text),
      containsAllInOrder([
        'first follow up',
        'echo: first follow up',
        'second follow up',
        'echo: second follow up',
      ]),
    );
  });

  testWidgets('queued follow-up waits when chat transport disappears', (
    tester,
  ) async {
    final channel = FakeHermesChannel(capabilities: _capabilitiesFixture);
    channel.beginStreamingTurn('current');
    await tester.pumpWidget(_wrap(channel));

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      'wait for transport',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pump();

    channel.setCapabilities(_noChatTransportCapabilitiesFixture);
    channel.completeStreamingTurn();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-queued-follow-up')),
      findsOneWidget,
    );
    expect(find.textContaining('wait for transport'), findsOneWidget);
    expect(
      find.textContaining('Waiting for a supported Hermes chat transport.'),
      findsOneWidget,
    );
    expect(find.text('echo: wait for transport'), findsNothing);
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const ValueKey('hermes-queued-follow-up-send-now')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'send now retries a queued follow-up after automatic send fails',
    (tester) async {
      final channel = _FlakySendHermesChannel(failuresRemaining: 1);
      channel.beginStreamingTurn('current');
      await tester.pumpWidget(_wrap(channel));

      await tester.enterText(
        find.byKey(const ValueKey('hermes-composer-field')),
        'retry manually',
      );
      await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
      await tester.pump();

      channel.completeStreamingTurn();
      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(const ValueKey('hermes-queued-follow-up')),
        findsOneWidget,
      );
      expect(channel.sendAttempts, ['retry manually']);

      await tester.tap(
        find.byKey(const ValueKey('hermes-queued-follow-up-send-now')),
      );
      await tester.pumpAndSettle();

      expect(channel.sendAttempts, ['retry manually', 'retry manually']);
      expect(
        find.byKey(const ValueKey('hermes-queued-follow-up')),
        findsNothing,
      );
      expect(find.text('echo: retry manually'), findsOneWidget);
    },
  );

  testWidgets('keeps queued follow-up when automatic send fails', (
    tester,
  ) async {
    final channel = _FailingSendHermesChannel();
    channel.beginStreamingTurn('current');
    await tester.pumpWidget(_wrap(channel));

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      'retry later',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pump();

    channel.completeStreamingTurn();
    await tester.pump();
    await tester.pump();

    expect(channel.sendAttempts, ['retry later']);
    expect(
      find.byKey(const ValueKey('hermes-queued-follow-up')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hermes-queued-follow-up-error')),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Could not send queued follow-up: Bad state: stream dropped',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('retry later'), findsOneWidget);
    expect(find.text('echo: retry later'), findsNothing);
  });

  testWidgets('queued follow-up send failures are redacted and bounded', (
    tester,
  ) async {
    final channel = _FailingSendHermesChannel(
      failureMessage:
          'stream dropped for Bearer secret-queued-send-token ${List.filled(20, 'verbose detail').join(' ')} tail-marker',
    );
    channel.beginStreamingTurn('current');
    await tester.pumpWidget(_wrap(channel));

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      'retry with secret-safe error',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pump();

    channel.completeStreamingTurn();
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-queued-follow-up-error')),
      findsOneWidget,
    );
    expect(find.textContaining('Bearer [redacted]'), findsOneWidget);
    expect(find.textContaining('secret-queued-send-token'), findsNothing);
    expect(find.textContaining('tail-marker'), findsNothing);
    expect(
      find.byKey(const ValueKey('hermes-queued-follow-up')),
      findsOneWidget,
    );
  });

  testWidgets('failed queued send remains bound to original session', (
    tester,
  ) async {
    final channel = _SessionSwitchingFailingSendHermesChannel();
    channel.beginStreamingTurn('current');
    await tester.pumpWidget(_wrap(channel));

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      'retry in first session',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pump();

    channel.completeStreamingTurn();
    await tester.pump();
    await tester.pump();

    expect(channel.sendAttempts, ['retry in first session']);
    expect(channel.state.activeSessionId, 'sess_2');
    expect(
      find.byKey(const ValueKey('hermes-queued-follow-up')),
      findsOneWidget,
    );
    expect(find.textContaining('retry in first session'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const ValueKey('hermes-queued-follow-up-send-now')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'cancels queued composer text before the current turn completes',
    (tester) async {
      final channel = FakeHermesChannel();
      channel.beginStreamingTurn('current');
      await tester.pumpWidget(_wrap(channel));

      await tester.enterText(
        find.byKey(const ValueKey('hermes-composer-field')),
        'never mind',
      );
      await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('hermes-queued-follow-up-cancel')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('hermes-queued-follow-up-clear-confirm')),
      );
      await tester.pump();

      channel.completeStreamingTurn();
      await tester.pumpAndSettle();

      expect(find.text('never mind'), findsNothing);
      expect(find.text('echo: never mind'), findsNothing);
    },
  );

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

  testWidgets('voice submit reports if chat transport disappears mid-capture', (
    tester,
  ) async {
    final channel = FakeHermesChannel(capabilities: _capabilitiesFixture);
    await tester.pumpWidget(
      _wrap(
        channel,
        screenBuilder: () => HermesChatScreen(
          voiceCaptureServiceOverride: successfulVoiceCaptureService(
            transcript: 'do not send without transport',
            captureLatency: const Duration(milliseconds: 20),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('hermes-mic-button')));
    await tester.pump();
    channel.setCapabilities(_noChatTransportCapabilitiesFixture);
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump();

    expect(channel.sentVoiceTranscripts, isEmpty);
    expect(find.text('do not send without transport'), findsNothing);
    expect(find.text('echo: do not send without transport'), findsNothing);
    final voiceError = tester.widget<Text>(
      find.byKey(const ValueKey('hermes-voice-error')),
    );
    expect(
      voiceError.data,
      'Hermes did not advertise a supported chat transport for this endpoint.',
    );
  });

  testWidgets('voice capture is discarded if the session changes mid-capture', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      sessions: const [
        HermesSession(id: 'sess_1', source: 'fake', title: 'One'),
        HermesSession(id: 'sess_2', source: 'fake', title: 'Two'),
      ],
    );
    await tester.pumpWidget(
      _wrap(
        channel,
        screenBuilder: () => HermesChatScreen(
          voiceCaptureServiceOverride: successfulVoiceCaptureService(
            transcript: 'do not cross sessions',
            captureLatency: const Duration(milliseconds: 20),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('hermes-mic-button')));
    await tester.pump();
    await channel.selectSession('sess_2');
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump();

    expect(channel.state.activeSessionId, 'sess_2');
    expect(channel.sentVoiceTranscripts, isEmpty);
    expect(find.text('do not cross sessions'), findsNothing);
    expect(find.text('echo: do not cross sessions'), findsNothing);
    expect(
      find.text(
        'Voice capture was discarded because the Hermes session changed.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('continuous voice pauses and reports when capture fails', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await tester.pumpWidget(
      _wrap(
        channel,
        screenBuilder: () => const HermesChatScreen(
          voiceCaptureServiceOverride: ThrowingVoiceCaptureService(
            'mic missing',
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('hermes-continuous-voice-switch')),
    );
    await tester.pumpAndSettle();

    expect(channel.sentVoiceTranscripts, isEmpty);
    expect(find.textContaining('Continuous voice paused.'), findsOneWidget);
    final voiceSwitch = tester.widget<Switch>(
      find.byKey(const ValueKey('hermes-continuous-voice-switch')),
    );
    expect(voiceSwitch.value, isFalse);
  });

  testWidgets('voice capture errors redact secret-looking values', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await tester.pumpWidget(
      _wrap(
        channel,
        screenBuilder: () => HermesChatScreen(
          voiceCaptureServiceOverride: ThrowingVoiceCaptureService(
            'failed with Bearer secret-voice-token and token=secret-voice-key '
            '${List.filled(20, 'verbose mic failure detail').join(' ')} tail-marker',
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('hermes-mic-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('hermes-voice-error')), findsOneWidget);
    expect(find.textContaining('Bearer [redacted]'), findsOneWidget);
    expect(find.textContaining('token=[redacted]'), findsOneWidget);
    expect(find.textContaining('secret-voice-token'), findsNothing);
    expect(find.textContaining('secret-voice-key'), findsNothing);
    expect(find.textContaining('tail-marker'), findsNothing);
  });

  testWidgets('continuous voice pauses when TTS is unavailable', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    final captures = QueueVoiceCaptureService([
      testVoiceCapture('first question'),
      testVoiceCapture('second question'),
    ]);
    await tester.pumpWidget(
      _wrap(
        channel,
        screenBuilder: () =>
            HermesChatScreen(voiceCaptureServiceOverride: captures),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('hermes-continuous-voice-switch')),
    );
    await tester.pumpAndSettle();

    expect(channel.sentVoiceTranscripts, ['first question']);
    expect(
      find.text(
        'Text-to-speech is not available here. Continuous voice paused.',
      ),
      findsOneWidget,
    );
    final voiceSwitch = tester.widget<Switch>(
      find.byKey(const ValueKey('hermes-continuous-voice-switch')),
    );
    expect(voiceSwitch.value, isFalse);
  });

  testWidgets(
    'continuous voice pauses and reports when TTS fails before re-arm',
    (tester) async {
      final channel = FakeHermesChannel();
      final captures = QueueVoiceCaptureService([
        testVoiceCapture('first question'),
        testVoiceCapture('second question'),
      ]);
      await tester.pumpWidget(
        _wrap(
          channel,
          screenBuilder: () => HermesChatScreen(
            voiceCaptureServiceOverride: captures,
            textToSpeechServiceOverride: _ThrowingTextToSpeechService(),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('hermes-continuous-voice-switch')),
      );
      await tester.pumpAndSettle();

      expect(channel.sentVoiceTranscripts, ['first question']);
      expect(
        find.text('Could not speak Hermes reply. Continuous voice paused.'),
        findsOneWidget,
      );
      final voiceSwitch = tester.widget<Switch>(
        find.byKey(const ValueKey('hermes-continuous-voice-switch')),
      );
      expect(voiceSwitch.value, isFalse);
    },
  );

  testWidgets('continuous voice pauses if session changes before re-arm', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      sessions: const [
        HermesSession(id: 'sess_1', source: 'fake', title: 'One'),
        HermesSession(id: 'sess_2', source: 'fake', title: 'Two'),
      ],
    );
    final tts = _GatedTextToSpeechService();
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
    await tester.pump();
    await tester.pump();

    expect(channel.sentVoiceTranscripts, ['first question']);
    expect(tts.spoken, ['echo: first question']);

    await channel.selectSession('sess_2');
    tts.completeSpeak();
    await tester.pumpAndSettle();

    expect(channel.state.activeSessionId, 'sess_2');
    expect(channel.sentVoiceTranscripts, ['first question']);
    expect(tts.spoken, ['echo: first question']);
    expect(
      find.text(
        'Hermes session changed before voice could re-arm. Continuous voice paused.',
      ),
      findsOneWidget,
    );
    final voiceSwitch = tester.widget<Switch>(
      find.byKey(const ValueKey('hermes-continuous-voice-switch')),
    );
    expect(voiceSwitch.value, isFalse);
  });

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
    await tester.enterText(
      find.byKey(const ValueKey('hermes-profile-label-field')),
      'Android smoke Hermes',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-connect-button')));
    await tester.pumpAndSettle();

    expect(store.saveCalls, hasLength(1));
    expect(store.saveCalls.single.baseUrl, 'http://10.0.2.2:8642');
    expect(store.saveCalls.single.apiKey, 'secret');
    expect(store.saveCalls.single.label, 'Android smoke Hermes');
  });

  testWidgets('connect profile label field redacts secret-looking labels', (
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
      find.byKey(const ValueKey('hermes-profile-label-field')),
      'Bearer secret-profile-token',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-connect-button')));
    await tester.pumpAndSettle();

    expect(store.saveCalls, hasLength(1));
    expect(store.saveCalls.single.label, 'Bearer [redacted]');
    expect(
      store.saveCalls.single.label,
      isNot(contains('secret-profile-token')),
    );
  });

  testWidgets('endpoint presets clear selected profile secrets and labels', (
    tester,
  ) async {
    final channel = FakeHermesChannel.disconnected();
    final store = FakeHermesEndpointStore(
      profiles: const [
        HermesEndpointConfig(
          id: 'lan',
          label: 'LAN Hermes',
          baseUrl: 'http://lan.example:8642',
          apiKey: 'lan-secret',
        ),
      ],
    );
    await tester.pumpWidget(_wrap(channel, endpointStore: store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('LAN Hermes'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('hermes-api-key-field')))
          .controller!
          .text,
      'lan-secret',
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('hermes-profile-label-field')),
          )
          .controller!
          .text,
      'LAN Hermes',
    );

    await tester.tap(find.byKey(const ValueKey('hermes-preset-android')));
    await tester.pump();

    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('hermes-base-url-field')),
          )
          .controller!
          .text,
      'http://10.0.2.2:8642',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('hermes-api-key-field')))
          .controller!
          .text,
      isEmpty,
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('hermes-profile-label-field')),
          )
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets('saved endpoint profiles can be selected and removed', (
    tester,
  ) async {
    final channel = FakeHermesChannel.disconnected();
    final store = FakeHermesEndpointStore(
      profiles: const [
        HermesEndpointConfig(
          id: 'lan',
          label: 'LAN Hermes',
          baseUrl: 'http://lan.example:8642',
          apiKey: 'lan-secret',
        ),
        HermesEndpointConfig(
          id: 'emu',
          label: 'Emulator Hermes',
          baseUrl: 'http://10.0.2.2:8642',
        ),
      ],
    );
    await tester.pumpWidget(_wrap(channel, endpointStore: store));
    await tester.pumpAndSettle();

    expect(find.text('Saved Hermes profiles'), findsOneWidget);
    expect(find.text('LAN Hermes'), findsOneWidget);
    expect(find.text('Emulator Hermes'), findsOneWidget);

    await tester.tap(find.text('LAN Hermes'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('hermes-base-url-field')),
          )
          .controller!
          .text,
      'http://lan.example:8642',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('hermes-api-key-field')))
          .controller!
          .text,
      'lan-secret',
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('hermes-profile-label-field')),
          )
          .controller!
          .text,
      'LAN Hermes',
    );

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('hermes-endpoint-profile-lan')),
        matching: find.byIcon(Icons.close),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('hermes-endpoint-profile-delete-dialog')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('hermes-endpoint-profile-delete-confirm')),
    );
    await tester.pumpAndSettle();

    expect(store.deleteProfileCalls, ['lan']);
    expect(find.text('LAN Hermes'), findsNothing);
    expect(find.text('Emulator Hermes'), findsOneWidget);
  });

  testWidgets('saved endpoint profiles can be renamed safely', (tester) async {
    final channel = FakeHermesChannel.disconnected();
    final store = FakeHermesEndpointStore(
      profiles: const [
        HermesEndpointConfig(
          id: 'lan',
          label: 'LAN Hermes',
          baseUrl: 'http://lan.example:8642',
          apiKey: 'lan-secret',
        ),
      ],
    );
    await tester.pumpWidget(_wrap(channel, endpointStore: store));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('hermes-endpoint-profile-rename-lan')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-endpoint-profile-rename-dialog')),
      findsOneWidget,
    );
    expect(find.textContaining('lan-secret'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('hermes-endpoint-profile-rename-field')),
      'Workstation Hermes',
    );
    await tester.tap(
      find.byKey(const ValueKey('hermes-endpoint-profile-rename-save')),
    );
    await tester.pumpAndSettle();

    expect(store.saveCalls, hasLength(1));
    expect(store.saveCalls.single.id, 'lan');
    expect(store.saveCalls.single.label, 'Workstation Hermes');
    expect(store.saveCalls.single.baseUrl, 'http://lan.example:8642');
    expect(store.saveCalls.single.apiKey, 'lan-secret');
    expect(find.text('Workstation Hermes'), findsOneWidget);
    expect(find.text('LAN Hermes'), findsNothing);
  });

  testWidgets('saved endpoint profile rename dialog redacts secrets', (
    tester,
  ) async {
    final channel = FakeHermesChannel.disconnected();
    final store = FakeHermesEndpointStore(
      profiles: const [
        HermesEndpointConfig(
          id: 'secret-profile',
          label: 'Bearer secret-profile-token',
          baseUrl: 'http://user:secret-url-token@example.com:8642',
          apiKey: 'secret-api-key',
        ),
      ],
    );
    await tester.pumpWidget(_wrap(channel, endpointStore: store));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey('hermes-endpoint-profile-rename-secret-profile'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-endpoint-profile-rename-dialog')),
      findsOneWidget,
    );
    expect(
      find.textContaining('http://[redacted]@example.com:8642'),
      findsOneWidget,
    );
    expect(find.textContaining('secret-profile-token'), findsNothing);
    expect(find.textContaining('secret-url-token'), findsNothing);
    expect(find.textContaining('secret-api-key'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('hermes-endpoint-profile-rename-cancel')),
    );
    await tester.pumpAndSettle();

    expect(store.saveCalls, isEmpty);
  });

  testWidgets('saved endpoint profile delete dialog redacts secrets', (
    tester,
  ) async {
    final channel = FakeHermesChannel.disconnected();
    final store = FakeHermesEndpointStore(
      profiles: const [
        HermesEndpointConfig(
          id: 'secret-profile',
          label: 'Bearer secret-profile-token',
          baseUrl: 'http://user:secret-url-token@example.com:8642',
          apiKey: 'secret-api-key',
        ),
      ],
    );
    await tester.pumpWidget(_wrap(channel, endpointStore: store));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(
          const ValueKey('hermes-endpoint-profile-secret-profile'),
        ),
        matching: find.byIcon(Icons.close),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-endpoint-profile-delete-dialog')),
      findsOneWidget,
    );
    expect(find.textContaining('Bearer [redacted]'), findsWidgets);
    expect(
      find.textContaining('http://[redacted]@example.com:8642'),
      findsOneWidget,
    );
    expect(find.textContaining('secret-profile-token'), findsNothing);
    expect(find.textContaining('secret-url-token'), findsNothing);
    expect(find.textContaining('secret-api-key'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('hermes-endpoint-profile-delete-cancel')),
    );
    await tester.pumpAndSettle();

    expect(store.deleteProfileCalls, isEmpty);
  });

  testWidgets('connect strips URL secret material before connect and save', (
    tester,
  ) async {
    final channel = FakeHermesChannel.disconnected();
    final store = FakeHermesEndpointStore();
    await tester.pumpWidget(_wrap(channel, endpointStore: store));

    await tester.enterText(
      find.byKey(const ValueKey('hermes-base-url-field')),
      'http://user:secret-user@example.com:8642/path?api_key=secret-query#frag',
    );
    await tester.enterText(
      find.byKey(const ValueKey('hermes-api-key-field')),
      'secret-header',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-connect-button')));
    await tester.pumpAndSettle();

    expect(channel.connectCalls.single.baseUrl, 'http://example.com:8642');
    expect(store.saveCalls.single.baseUrl, 'http://example.com:8642');
    expect(store.saveCalls.single.apiKey, 'secret-header');
  });

  testWidgets('stale connect completion does not overwrite saved endpoint', (
    tester,
  ) async {
    final channel = _SlowFirstConnectHermesChannel();
    final store = FakeHermesEndpointStore();
    await tester.pumpWidget(_wrap(channel, endpointStore: store));

    await tester.enterText(
      find.byKey(const ValueKey('hermes-base-url-field')),
      'http://old.example:8642',
    );
    await tester.enterText(
      find.byKey(const ValueKey('hermes-api-key-field')),
      'old-secret',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-connect-button')));
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-base-url-field')),
      'http://new.example:8642',
    );
    await tester.enterText(
      find.byKey(const ValueKey('hermes-api-key-field')),
      'new-secret',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-connect-button')));
    await tester.pumpAndSettle();

    channel.releaseFirstConnect();
    await tester.pumpAndSettle();

    expect(channel.connectCalls.map((call) => call.baseUrl), [
      'http://old.example:8642',
      'http://new.example:8642',
    ]);
    expect(store.saveCalls, hasLength(1));
    expect(store.saveCalls.single.baseUrl, 'http://new.example:8642');
    expect(store.saveCalls.single.apiKey, 'new-secret');
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

  testWidgets(
    'disconnect clears transient approvals, queued follow-ups, and voice loop',
    (tester) async {
      final channel = FakeHermesChannel();
      final tts = FakeTextToSpeechService();
      await tester.pumpWidget(
        _wrap(
          channel,
          screenBuilder: () =>
              HermesChatScreen(textToSpeechServiceOverride: tts),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('hermes-continuous-voice-switch')),
      );
      channel.emitApprovalRequest(
        const NavivoxApprovalRequest(
          id: 'appr_1',
          toolCallId: 'call_1',
          prompt: 'Approve stale work?',
        ),
      );
      channel.beginStreamingTurn('current');
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('hermes-composer-field')),
        'queued stale follow-up',
      );
      await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('hermes-approval-banner')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('hermes-queued-follow-up')),
        findsOneWidget,
      );

      await channel.disconnect();
      await tester.pumpAndSettle();
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('hermes-approval-banner')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('hermes-queued-follow-up')),
        findsNothing,
      );
      final voiceSwitch = tester.widget<Switch>(
        find.byKey(const ValueKey('hermes-continuous-voice-switch')),
      );
      expect(voiceSwitch.value, isFalse);
      expect(tts.stopCalls, 1);
      expect(find.text('queued stale follow-up'), findsNothing);
      expect(find.text('echo: queued stale follow-up'), findsNothing);
    },
  );

  testWidgets('disconnect confirms before clearing the store', (tester) async {
    final channel = FakeHermesChannel();
    final store = FakeHermesEndpointStore(
      initial: const HermesEndpointConfig(baseUrl: 'http://10.0.2.2:8642'),
    );
    await tester.pumpWidget(_wrap(channel, endpointStore: store));

    await tester.tap(find.byKey(const ValueKey('hermes-disconnect-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-disconnect-confirm-dialog')),
      findsOneWidget,
    );
    expect(store.clearCalls, 0);

    await tester.tap(find.byKey(const ValueKey('hermes-disconnect-confirm')));
    await tester.pumpAndSettle();

    expect(store.clearCalls, 1);
    expect(find.byKey(const ValueKey('hermes-connect-button')), findsOneWidget);
  });

  testWidgets('disconnect confirmation redacts endpoint secrets', (
    tester,
  ) async {
    final channel = FakeHermesChannel.disconnected();
    final store = FakeHermesEndpointStore();
    await tester.pumpWidget(_wrap(channel, endpointStore: store));

    await tester.enterText(
      find.byKey(const ValueKey('hermes-base-url-field')),
      'http://user:secret-url-token@example.com:8642',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-connect-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hermes-disconnect-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-disconnect-confirm-dialog')),
      findsOneWidget,
    );
    expect(
      find.textContaining('http://[redacted]@example.com:8642'),
      findsOneWidget,
    );
    expect(find.textContaining('secret-url-token'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('hermes-disconnect-cancel')));
    await tester.pumpAndSettle();

    expect(store.clearCalls, 0);
    expect(find.byKey(const ValueKey('hermes-connect-button')), findsNothing);
  });

  testWidgets('approval decisions disable when response endpoint is absent', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: const HermesCapabilityDocument(
        object: 'hermes.api_server.capabilities',
        platform: 'hermes-agent',
        model: 'hermes-agent',
        auth: HermesAuthCapability(type: 'bearer', required: false),
        features: {},
        endpoints: {
          'session_chat_stream': HermesEndpointCapability(
            method: 'POST',
            path: '/api/sessions/{session_id}/chat/stream',
          ),
        },
      ),
    );
    await tester.pumpWidget(_wrap(channel));

    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: 'appr_1',
        toolCallId: 'call_1',
        prompt: 'Approve unsupported response?',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-approval-response-unavailable')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('hermes-approval-once')),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('hermes-approval-review')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Decision buttons are disabled'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('hermes-approval-sheet-once')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('approval without id disables decisions before send', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await tester.pumpWidget(_wrap(channel));

    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: '   ',
        toolCallId: 'call_1',
        prompt: 'Approve missing id?',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-approval-id-missing')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('hermes-approval-once')),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('hermes-approval-review')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('did not include an approval id'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('hermes-approval-sheet-once')),
          )
          .onPressed,
      isNull,
    );
    expect(channel.respondToApprovalCalls, isEmpty);
  });

  testWidgets('dismisses malformed approval so queued approvals can continue', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await tester.pumpWidget(_wrap(channel));

    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: '   ',
        toolCallId: 'call_bad',
        prompt: 'Approve malformed request?',
      ),
    );
    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: 'appr_next',
        toolCallId: 'call_next',
        prompt: 'Approve valid queued request?',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Approve malformed request?'), findsOneWidget);
    expect(find.text('Approve valid queued request?'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('hermes-approval-dismiss-malformed')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Approve malformed request?'), findsNothing);
    expect(find.text('Approve valid queued request?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('hermes-approval-once')));
    await tester.pumpAndSettle();

    expect(channel.respondToApprovalCalls, [
      {'approvalId': 'appr_next', 'decision': HermesApprovalDecision.once},
    ]);
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

  testWidgets('always-allow approvals require bounded confirmation', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await tester.pumpWidget(_wrap(channel));

    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: 'appr_always',
        toolCallId: 'call_always',
        prompt: 'Allow Bearer secret-approval-token forever?',
        risk: 'high secret-risk-token',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hermes-approval-always')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-approval-always-confirm-dialog')),
      findsOneWidget,
    );
    expect(channel.respondToApprovalCalls, isEmpty);
    expect(find.textContaining('Bearer [redacted]'), findsWidgets);
    expect(find.textContaining('[redacted]'), findsWidgets);
    expect(find.textContaining('secret-approval-token'), findsNothing);
    expect(find.textContaining('secret-risk-token'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('hermes-approval-always-confirm')),
    );
    await tester.pumpAndSettle();

    expect(channel.respondToApprovalCalls, [
      {'approvalId': 'appr_always', 'decision': HermesApprovalDecision.always},
    ]);
    expect(find.byKey(const ValueKey('hermes-approval-banner')), findsNothing);
  });

  testWidgets('approval banner prompt and risk are bounded', (tester) async {
    final channel = FakeHermesChannel();
    final longPrompt =
        '${List.filled(30, 'approve long operation').join(' ')} prompt-tail';
    final longRisk =
        '${List.filled(20, 'high impact risk').join(' ')} risk-tail';
    await tester.pumpWidget(_wrap(channel));

    channel.emitApprovalRequest(
      NavivoxApprovalRequest(
        id: 'appr_1',
        toolCallId: 'call_1',
        prompt: longPrompt,
        risk: longRisk,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-approval-banner')),
      findsOneWidget,
    );
    expect(find.textContaining('prompt-tail'), findsNothing);
    expect(find.textContaining('risk-tail'), findsNothing);
    expect(find.textContaining('…'), findsAtLeastNWidgets(1));

    await tester.tap(find.byKey(const ValueKey('hermes-approval-review')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-approval-sheet-prompt')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hermes-approval-sheet-prompt-truncated')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hermes-approval-sheet-risk')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hermes-approval-sheet-risk-truncated')),
      findsOneWidget,
    );
    expect(find.textContaining('prompt-tail'), findsNothing);
    expect(find.textContaining('risk-tail'), findsNothing);
  });

  testWidgets('approval prompts redact secret-looking values', (tester) async {
    final channel = FakeHermesChannel();
    await tester.pumpWidget(_wrap(channel));

    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: 'appr_1',
        toolCallId: 'tool-secret-call',
        prompt:
            'Run with Bearer secret-approval-token and api_key=secret-api-key Cookie=sid=secret-cookie-token?',
        risk:
            'secret-risk-token https://user:secret-pass@example.test/path Authorization=Basic secret-basic-token',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Bearer [redacted]'), findsOneWidget);
    expect(find.textContaining('api_key=[redacted]'), findsOneWidget);
    expect(find.textContaining('Cookie=[redacted]'), findsOneWidget);
    expect(find.textContaining('secret-approval-token'), findsNothing);
    expect(find.textContaining('secret-api-key'), findsNothing);
    expect(find.textContaining('secret-cookie-token'), findsNothing);
    expect(find.textContaining('secret-risk-token'), findsNothing);
    expect(find.textContaining('secret-pass'), findsNothing);
    expect(find.textContaining('secret-basic-token'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('hermes-approval-review')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Bearer [redacted]'), findsAtLeastNWidgets(2));
    expect(find.textContaining('Cookie=[redacted]'), findsAtLeastNWidgets(2));
    expect(find.textContaining('https://[redacted]@'), findsAtLeastNWidgets(1));
    expect(
      find.textContaining('Authorization=Basic [redacted]'),
      findsAtLeastNWidgets(1),
    );
    expect(find.textContaining('Tool call: tool-[redacted]'), findsOneWidget);
    expect(find.textContaining('tool-secret-call'), findsNothing);
    expect(find.textContaining('secret-pass'), findsNothing);
    expect(find.textContaining('secret-basic-token'), findsNothing);
  });

  testWidgets('shows approval response progress while Hermes answers', (
    tester,
  ) async {
    final approvalGate = Completer<void>();
    final channel = FakeHermesChannel(
      approvalResponseGate: () => approvalGate.future,
    );
    await tester.pumpWidget(_wrap(channel));

    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: 'appr_1',
        toolCallId: 'call_1',
        prompt: 'Approve slow action?',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hermes-approval-once')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-approval-banner')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hermes-approval-responding')),
      findsOneWidget,
    );
    expect(find.text('Answering Hermes approval…'), findsOneWidget);
    final approveButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('hermes-approval-once')),
    );
    expect(approveButton.onPressed, isNull);

    approvalGate.complete();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('hermes-approval-banner')), findsNothing);
  });

  testWidgets('approval response completing after disconnect does not crash', (
    tester,
  ) async {
    final approvalGate = Completer<void>();
    final channel = FakeHermesChannel(
      approvalResponseGate: () => approvalGate.future,
    );
    await tester.pumpWidget(_wrap(channel));

    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: 'appr_1',
        toolCallId: 'call_1',
        prompt: 'Approve before disconnect?',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hermes-approval-once')));
    await tester.pump();
    await channel.disconnect();
    await tester.pump();

    approvalGate.complete();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('hermes-approval-banner')), findsNothing);
    expect(find.byKey(const ValueKey('hermes-connect-button')), findsOneWidget);
  });

  testWidgets('keeps approval queued when the approval response fails', (
    tester,
  ) async {
    final channel = FakeHermesChannel(approvalResponsesFail: true);
    await tester.pumpWidget(_wrap(channel));

    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: 'appr_1',
        toolCallId: 'call_1',
        prompt: 'Approve flaky action?',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hermes-approval-once')));
    await tester.pumpAndSettle();

    expect(channel.respondToApprovalCalls, [
      {'approvalId': 'appr_1', 'decision': HermesApprovalDecision.once},
    ]);
    expect(
      find.byKey(const ValueKey('hermes-approval-banner')),
      findsOneWidget,
    );
    expect(find.text('Approve flaky action?'), findsOneWidget);
    expect(find.byKey(const ValueKey('hermes-chat-error')), findsOneWidget);
    expect(
      find.text('Hermes could not record the approval decision.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('check that the run is still active'),
      findsOneWidget,
    );
  });

  testWidgets('deduplicates replayed approval requests', (tester) async {
    final channel = FakeHermesChannel();
    await tester.pumpWidget(_wrap(channel));

    const request = NavivoxApprovalRequest(
      id: 'appr_1',
      toolCallId: 'call_1',
      prompt: 'Approve replayed action?',
    );
    channel.emitApprovalRequest(request);
    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: '  appr_1  ',
        toolCallId: '  call_1  ',
        prompt: 'Approve replayed action?',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-approval-banner')),
      findsOneWidget,
    );
    expect(find.text('Approve replayed action?'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('hermes-approval-pending-count')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('hermes-approval-once')));
    await tester.pumpAndSettle();

    expect(channel.respondToApprovalCalls, [
      {'approvalId': 'appr_1', 'decision': HermesApprovalDecision.once},
    ]);
    expect(find.byKey(const ValueKey('hermes-approval-banner')), findsNothing);
  });

  testWidgets('queues multiple approval requests and resolves them in order', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await tester.pumpWidget(_wrap(channel));

    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: 'appr_1',
        toolCallId: 'call_1',
        prompt: 'First risky action?',
      ),
    );
    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: 'appr_2',
        toolCallId: 'call_2',
        prompt: 'Second risky action?',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 pending approvals'), findsOneWidget);
    expect(find.text('First risky action?'), findsOneWidget);
    expect(find.text('Second risky action?'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('hermes-approval-review')));
    await tester.pumpAndSettle();
    expect(find.text('Reviewing 1 of 2 pending approvals'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('hermes-approval-sheet-deny')));
    await tester.pumpAndSettle();
    expect(channel.respondToApprovalCalls, [
      {'approvalId': 'appr_1', 'decision': HermesApprovalDecision.deny},
    ]);

    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: 'appr_1b',
        toolCallId: 'call_1b',
        prompt: 'Replacement first risky action?',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hermes-approval-once')));
    await tester.pumpAndSettle();

    expect(channel.respondToApprovalCalls, [
      {'approvalId': 'appr_1', 'decision': HermesApprovalDecision.deny},
      {'approvalId': 'appr_2', 'decision': HermesApprovalDecision.once},
    ]);
    expect(find.text('First risky action?'), findsNothing);
    expect(find.text('Second risky action?'), findsNothing);
    expect(find.text('Replacement first risky action?'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('hermes-approval-pending-count')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('hermes-approval-deny')));
    await tester.pumpAndSettle();

    expect(channel.respondToApprovalCalls, [
      {'approvalId': 'appr_1', 'decision': HermesApprovalDecision.deny},
      {'approvalId': 'appr_2', 'decision': HermesApprovalDecision.once},
      {'approvalId': 'appr_1b', 'decision': HermesApprovalDecision.deny},
    ]);
    expect(find.byKey(const ValueKey('hermes-approval-banner')), findsNothing);
  });

  testWidgets('approval review sheet shows context and answers a decision', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await tester.pumpWidget(_wrap(channel));

    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: 'appr_1',
        toolCallId: 'call_1',
        prompt: 'Run deployment script?',
        risk: 'medium',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hermes-approval-review')));
    await tester.pumpAndSettle();

    expect(find.text('Review Hermes approval'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('hermes-approval-sheet-scroll')),
      findsOneWidget,
    );
    expect(find.text('Run deployment script?'), findsWidgets);
    expect(find.text('Risk: medium'), findsWidgets);
    expect(find.text('Tool call: call_1'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('hermes-approval-sheet-copy')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('hermes-approval-sheet-copy')));
    await tester.pump();

    expect(
      find.text('Copied redacted Hermes approval details.'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('hermes-approval-sheet-session')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('hermes-approval-session-confirm-dialog')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('hermes-approval-session-confirm')),
    );
    await tester.pumpAndSettle();

    expect(channel.respondToApprovalCalls, [
      {'approvalId': 'appr_1', 'decision': HermesApprovalDecision.session},
    ]);
    expect(find.text('Review Hermes approval'), findsNothing);
    expect(find.byKey(const ValueKey('hermes-approval-banner')), findsNothing);
  });

  testWidgets('approval review sheet can close without answering', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await tester.pumpWidget(_wrap(channel));

    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: 'appr_1',
        toolCallId: 'call_1',
        prompt: 'Inspect workspace files?',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hermes-approval-review')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hermes-approval-sheet-close')));
    await tester.pumpAndSettle();

    expect(channel.respondToApprovalCalls, isEmpty);
    expect(find.text('Review Hermes approval'), findsNothing);
    expect(
      find.byKey(const ValueKey('hermes-approval-banner')),
      findsOneWidget,
    );
    expect(find.text('Inspect workspace files?'), findsOneWidget);
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

  testWidgets('approving for the session requires bounded confirmation', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await tester.pumpWidget(_wrap(channel));

    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: 'appr_1',
        toolCallId: 'call_1',
        prompt: 'Read files with Bearer secret-session-token?',
        risk: 'medium secret-session-risk',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hermes-approval-session')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-approval-session-confirm-dialog')),
      findsOneWidget,
    );
    expect(channel.respondToApprovalCalls, isEmpty);
    expect(find.textContaining('Bearer [redacted]'), findsWidgets);
    expect(find.textContaining('secret-session-token'), findsNothing);
    expect(find.textContaining('secret-session-risk'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('hermes-approval-session-confirm')),
    );
    await tester.pumpAndSettle();

    expect(channel.respondToApprovalCalls, [
      {'approvalId': 'appr_1', 'decision': HermesApprovalDecision.session},
    ]);
  });

  testWidgets('stopping a turn clears stale approval requests', (tester) async {
    final channel = FakeHermesChannel();
    await tester.pumpWidget(_wrap(channel));

    channel.beginStreamingTurn('needs approval');
    await tester.pump();
    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: 'appr_1',
        toolCallId: 'call_1',
        prompt: 'Approve a long-running tool?',
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-approval-banner')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('hermes-stop-button')));
    await tester.pump();

    expect(channel.stopActiveTurnCalls, 1);
    expect(find.byKey(const ValueKey('hermes-approval-banner')), findsNothing);
    expect(find.text('Approve a long-running tool?'), findsNothing);
  });

  testWidgets('shows a stop control while a turn is streaming and stops it', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    final tts = FakeTextToSpeechService();
    await tester.pumpWidget(
      _wrap(
        channel,
        screenBuilder: () => HermesChatScreen(textToSpeechServiceOverride: tts),
      ),
    );

    expect(find.byKey(const ValueKey('hermes-stop-button')), findsNothing);

    channel.beginStreamingTurn('keep going forever');
    // A streaming turn renders a perpetual progress indicator, so pump a
    // bounded number of frames instead of pumpAndSettle (which would hang).
    await tester.pump();

    expect(find.byKey(const ValueKey('hermes-stop-button')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('hermes-stop-button')));
    await tester.pump();

    expect(channel.stopActiveTurnCalls, 1);
    expect(tts.stopCalls, 1);
    expect(find.byKey(const ValueKey('hermes-stop-button')), findsNothing);
    expect(find.text('Stopped.'), findsOneWidget);
  });

  testWidgets('renders a tool-call turn as a redacted status card', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await tester.pumpWidget(_wrap(channel));

    channel.addToolCallTurn(
      const HermesToolCall(
        name: 'bash secret-tool-name',
        status: 'running',
        preview: 'ls -la api_key=secret-tool-preview',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-tool-turn-tool-0')),
      findsOneWidget,
    );
    expect(find.text('bash [redacted]'), findsOneWidget);
    expect(find.textContaining('api_key=[redacted]'), findsOneWidget);
    expect(find.textContaining('secret-tool-name'), findsNothing);
    expect(find.textContaining('secret-tool-preview'), findsNothing);
    // Not rendered as a plain chat bubble alongside user/assistant text.
    expect(find.text('tool.started: bash'), findsNothing);
  });
}

class _ThrowingTextToSpeechService implements TextToSpeechService {
  @override
  Future<void> speak(String text) async {
    throw StateError('speaker unavailable');
  }

  @override
  Future<void> stop() async {}
}

class _GatedTextToSpeechService implements TextToSpeechService {
  final List<String> spoken = [];
  final _gate = Completer<void>();
  int stopCalls = 0;

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
    await _gate.future;
  }

  void completeSpeak() {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }
}

class _FailingSendHermesChannel extends FakeHermesChannel {
  _FailingSendHermesChannel({this.failureMessage = 'stream dropped'});

  final String failureMessage;
  final List<String> sendAttempts = [];

  @override
  Future<void> sendText(String text) async {
    sendAttempts.add(text);
    throw StateError(failureMessage);
  }
}

class _SessionSwitchingFailingSendHermesChannel extends FakeHermesChannel {
  _SessionSwitchingFailingSendHermesChannel()
    : super(
        sessions: const [
          HermesSession(id: 'sess_1', source: 'fake', title: 'One'),
          HermesSession(id: 'sess_2', source: 'fake', title: 'Two'),
        ],
      );

  final List<String> sendAttempts = [];

  @override
  Future<void> sendText(String text) async {
    sendAttempts.add(text);
    await selectSession('sess_2');
    throw StateError('stream dropped after session switch');
  }
}

class _FlakySendHermesChannel extends FakeHermesChannel {
  _FlakySendHermesChannel({required this.failuresRemaining});

  int failuresRemaining;
  final List<String> sendAttempts = [];

  @override
  Future<void> sendText(String text) async {
    sendAttempts.add(text);
    if (failuresRemaining > 0) {
      failuresRemaining -= 1;
      throw StateError('stream dropped');
    }
    return super.sendText(text);
  }
}

class _SlowFirstConnectHermesChannel extends FakeHermesChannel {
  _SlowFirstConnectHermesChannel()
    : super(status: HermesConnectionStatus.disconnected);

  final _releaseFirstConnect = Completer<void>();
  var _connectCount = 0;

  @override
  Future<void> connect({required String baseUrl, String? apiKey}) async {
    _connectCount += 1;
    if (_connectCount == 1) {
      connectCalls.add(FakeHermesConnectCall(baseUrl: baseUrl, apiKey: apiKey));
      await _releaseFirstConnect.future;
      return;
    }
    return super.connect(baseUrl: baseUrl, apiKey: apiKey);
  }

  void releaseFirstConnect() {
    if (!_releaseFirstConnect.isCompleted) _releaseFirstConnect.complete();
  }
}

class _FailingConnectHermesChannel extends FakeHermesChannel {
  _FailingConnectHermesChannel()
    : super(status: HermesConnectionStatus.disconnected);

  @override
  Future<void> connect({required String baseUrl, String? apiKey}) async {
    // Connecting fails; state stays disconnected/error rather than connected.
  }
}

const _noChatTransportCapabilitiesFixture = HermesCapabilityDocument(
  object: 'hermes.api_server.capabilities',
  platform: 'hermes-agent',
  model: 'hermes-agent',
  auth: HermesAuthCapability(type: 'bearer', required: false),
  features: {},
  endpoints: {},
);

const _realtimeVoiceCapabilitiesFixture = HermesCapabilityDocument(
  object: 'hermes.api_server.capabilities',
  platform: 'hermes-agent',
  model: 'hermes-agent',
  auth: HermesAuthCapability(type: 'bearer', required: true),
  features: {'realtime_voice': true},
  endpoints: {},
);

const _attachmentsCapabilities = HermesCapabilityDocument(
  object: 'hermes.api_server.capabilities',
  platform: 'hermes-agent',
  model: 'hermes-agent',
  auth: HermesAuthCapability(type: 'bearer', required: true),
  features: {
    'session_chat_streaming': true,
    'attachments_api': true,
    'multimodal_chat': true,
  },
  endpoints: {
    'session_chat_stream': HermesEndpointCapability(
      method: 'POST',
      path: '/api/sessions/{session_id}/chat/stream',
    ),
  },
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
    'session_create': HermesEndpointCapability(
      method: 'POST',
      path: '/api/sessions',
    ),
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
