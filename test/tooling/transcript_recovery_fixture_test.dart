import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/hermes_api.dart';

import '../../integration_test/support/transcript_recovery_native_fixture.dart';

void main() {
  test(
    'native fixture permits issued-run reattachment but rejects unissued events',
    () async {
      final fixture = TranscriptRecoveryNativeFixture();
      addTearDown(fixture.dispose);
      final client = fixture.buildClient(
        HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642'),
      );
      Future<void> read(String id) async {
        final events = client.runEvents(id).toList();
        fixture.event('message.delta', {'delta': 'Synthetic bounded event'});
        await fixture.streams.last.close();
        expect(await events, hasLength(1));
      }

      final first = await client.startRun(
        sessionId: 'synthetic-reconnect',
        message: 'Synthetic first',
      );
      await read(first.id);
      await read(first.id);
      final next = await client.startRun(
        sessionId: 'synthetic-reconnect',
        message: 'Synthetic next',
      );
      await read(next.id);
      expect(() => client.runEvents('run_5'), throwsStateError);
      expect(
        fixture.requests
            .where((r) => r['method'] == 'SSE')
            .map((r) => r['path']),
        [
          '/v1/runs/${first.id}/events',
          '/v1/runs/${first.id}/events',
          '/v1/runs/${next.id}/events',
          '/v1/runs/run_5/events',
        ],
      );
    },
  );
  test(
    'native fixture fences every unused transport and foreign read owner',
    () async {
      final fixture = TranscriptRecoveryNativeFixture();
      addTearDown(fixture.dispose);
      final client = fixture.buildClient(
        HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642'),
      );
      await expectLater(
        client.updateSessionTitle('synthetic-reconnect', title: 'Synthetic'),
        throwsStateError,
      );
      await expectLater(
        client.writeProfileSoul(
          profileId: 'default',
          soul: 'Synthetic',
          revision: 'synthetic',
        ),
        throwsStateError,
      );
      await expectLater(
        client.deleteSession('synthetic-reconnect'),
        throwsStateError,
      );
      expect(
        () => client.streamSessionChat(
          'synthetic-reconnect',
          message: 'Synthetic',
        ),
        throwsStateError,
      );
      await expectLater(
        client.listSessions(profile: 'foreign'),
        throwsStateError,
      );
      final foreign = fixture.buildClient(
        HermesApiConfig.fromBaseUrl('http://synthetic.invalid'),
      );
      await expectLater(foreign.health(), throwsStateError);
      expect(fixture.requests.map((r) => r['method']), [
        'PATCH',
        'PUT',
        'DELETE',
        'POST-SSE',
        'GET',
        'GET',
      ]);
      expect(fixture.mutations.length, 4);
    },
  );
}
