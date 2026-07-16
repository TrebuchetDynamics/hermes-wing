import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel_state.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/features/hermes_chat/diagnostics/hermes_diagnostics_export.dart';

void main() {
  test('diagnostics are redacted and deterministic', () {
    const secret = 'sk-private-diagnostic-value';
    final diagnostics = hermesDiagnosticsExport(
      const HermesChannelState(
        status: HermesConnectionStatus.connected,
        sessions: [
          HermesSession(
            id: 'session-1',
            source: 'api',
            title: 'Authorization: Bearer sk-private-diagnostic-value',
          ),
        ],
        activeSessionId: 'session-1',
        optionalResourceErrors: {
          HermesOptionalResource.skills: 'failed',
          HermesOptionalResource.models: 'failed',
        },
      ),
    );

    expect(diagnostics, isNot(contains(secret)));
    expect(
      diagnostics,
      contains('Optional inventory failures: models, skills'),
    );
    expect(diagnostics, contains('Secrets: excluded'));
    expect(diagnostics, contains('Transcripts: excluded'));
    expect(diagnostics, contains('Local paths: excluded'));
  });
}
