import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/hermes_api.dart';

import '../../integration_test/support/transcript_recovery_native_fixture.dart';

void main() {
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
