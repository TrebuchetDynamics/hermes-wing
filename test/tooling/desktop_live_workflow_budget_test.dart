import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/linux_desktop_live_workflow_test.dart';

void main() {
  test(
    'direct native invocation cannot bypass unqualified inference ceiling',
    () {
      expect(requireQualifiedLiveBudget, throwsUnsupportedError);
    },
  );
  Map<String, dynamic> lock() => {
    'provider': 'openai-codex',
    'model': 'gpt-6.1-sol',
  };
  LiveWorkflowMutationBudget budget(String phase) =>
      LiveWorkflowMutationBudget(session: 'qa-session', phase: phase);

  test('startup and restoration have no mutation authority', () {
    final guard = budget('write');
    expect(
      () => guard.admit('/v1/runs', {'session_id': 'qa-session'}),
      throwsStateError,
    );
    expect(
      () => guard.admit('/api/sessions/qa-session/model', lock()),
      throwsStateError,
    );
    expect(guard.counts.values, everyElement(0));
  });

  test('one model lock, send, correlated once approval and Stop', () {
    final guard = budget('write')..armed = true;
    guard.admit('/api/sessions/qa-session/model', lock());
    guard.admit('/v1/runs', {'session_id': 'qa-session'});
    guard.run = 'qa-run';
    guard.request = 'qa-request';
    guard.admit('/v1/runs/qa-run/approval', {
      'request_id': 'qa-request',
      'choice': 'once',
    });
    guard.admit('/v1/runs/qa-run/stop', {});
    expect(guard.counts, {
      'model_locks': 1,
      'submits': 1,
      'approvals': 1,
      'stops': 1,
    });
    expect(
      () => guard.admit('/v1/runs', {'session_id': 'qa-session'}),
      throwsStateError,
    );
    expect(
      () => guard.admit('/v1/runs/qa-run/approval', {
        'request_id': 'qa-request',
        'choice': 'once',
      }),
      throwsStateError,
    );
    expect(() => guard.admit('/v1/runs/qa-run/stop', {}), throwsStateError);
  });

  test(
    'wrong owner, provider, session, request, batch and unexpected mutations fail',
    () {
      final guard = budget('write')..armed = true;
      expect(
        () => guard.admit('/api/sessions/other/model', lock()),
        throwsStateError,
      );
      expect(
        () => guard.admit('/api/sessions/qa-session/model', {
          'provider': 'other',
          'model': 'gpt-6.1-sol',
        }),
        throwsStateError,
      );
      expect(() => guard.admit('/api/sessions', {}), throwsStateError);
      guard.admit('/api/sessions/qa-session/model', lock());
      expect(
        () => guard.admit('/v1/runs', {'session_id': 'other'}),
        throwsStateError,
      );
      guard.admit('/v1/runs', {'session_id': 'qa-session'});
      guard.run = 'qa-run';
      guard.request = 'qa-request';
      expect(
        () => guard.admit('/v1/runs/other/approval', {
          'request_id': 'qa-request',
          'choice': 'once',
        }),
        throwsStateError,
      );
      expect(
        () => guard.admit('/v1/runs/qa-run/approval', {
          'request_id': 'other',
          'choice': 'once',
        }),
        throwsStateError,
      );
      expect(
        () => guard.admit('/v1/runs/qa-run/approval', {
          'request_id': 'qa-request',
          'choice': 'always',
        }),
        throwsStateError,
      );
      expect(
        () => guard.admit('/v1/runs/qa-run/approval', {
          'request_id': 'qa-request',
          'choice': 'once',
          'resolve_all': true,
        }),
        throwsStateError,
      );
      expect(() => guard.admit('/v1/runs/other/stop', {}), throwsStateError);
      expect(guard.approvals, 0);
      expect(guard.stops, 0);
    },
  );

  test(
    'relaunch phase permits one reselection/send and no approvals or Stop',
    () {
      final guard = budget('verify')..armed = true;
      guard.admit('/api/sessions/qa-session/model', lock());
      guard.admit('/v1/runs', {'session_id': 'qa-session'});
      guard.run = 'qa-run';
      guard.request = 'qa-request';
      expect(
        () => guard.admit('/v1/runs/qa-run/approval', {
          'request_id': 'qa-request',
          'choice': 'once',
        }),
        throwsStateError,
      );
      expect(() => guard.admit('/v1/runs/qa-run/stop', {}), throwsStateError);
      expect(
        () => guard.admit('/v1/runs', {'session_id': 'qa-session'}),
        throwsStateError,
      );
      expect(guard.counts, {
        'model_locks': 1,
        'submits': 1,
        'approvals': 0,
        'stops': 0,
      });
    },
  );

  test(
    'ambiguous dispatch consumes its slot and invalid phases cannot write',
    () {
      final guard = budget('verify')..armed = true;
      guard.admit('/api/sessions/qa-session/model', lock());
      guard.admit('/v1/runs', {'session_id': 'qa-session'});
      // No response/run binding: a transport failure must not enable retry.
      expect(
        () => guard.admit('/v1/runs', {'session_id': 'qa-session'}),
        throwsStateError,
      );
      final invalid = budget('other')..armed = true;
      expect(
        () => invalid.admit('/api/sessions/qa-session/model', lock()),
        throwsStateError,
      );
    },
  );
}
