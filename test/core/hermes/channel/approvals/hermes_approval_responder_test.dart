import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/approvals/hermes_approval_responder.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/core/hermes/client/hermes_api_config.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';

const _runsCapableCapabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true},
  "features": {
    "session_chat_streaming": true,
    "run_submission": true,
    "run_status": true,
    "run_events_sse": true,
    "run_stop": true,
    "run_approval_response": true,
    "tool_progress_events": true
  },
  "endpoints": {
    "runs": {"method": "POST", "path": "/v1/runs"},
    "run_status": {"method": "GET", "path": "/v1/runs/{run_id}"},
    "run_events": {"method": "GET", "path": "/v1/runs/{run_id}/events"},
    "run_approval": {"method": "POST", "path": "/v1/runs/{run_id}/approval"},
    "run_stop": {"method": "POST", "path": "/v1/runs/{run_id}/stop"}
  }
}
''';

const _runsWithoutApprovalCapabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true},
  "features": {
    "run_submission": true,
    "run_events_sse": true
  },
  "endpoints": {
    "runs": {"method": "POST", "path": "/v1/runs"},
    "run_events": {"method": "GET", "path": "/v1/runs/{run_id}/events"}
  }
}
''';

HermesChannelState _stateFor(String capabilities) => HermesChannelState(
  capabilities: HermesCapabilityDocument.fromJson(
    jsonDecode(capabilities) as Map<String, Object?>,
  ),
);

HermesApiClient _client({
  Future<void> Function(Uri uri, Map<String, String> headers, String body)?
  onPost,
}) => HermesApiClient(
  config: HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642'),
  post: (uri, headers, body) async {
    await onPost?.call(uri, headers, body);
    return '{}';
  },
);

void main() {
  group('HermesApprovalResponder.respond', () {
    test('rejects blank approval ids before POST and reports', () async {
      final responder = HermesApprovalResponder();
      responder.registerApproval('appr_1', 'run_1');
      final posted = <String>[];
      final reported = <String>[];
      final client = _client(
        onPost: (uri, h, b) async {
          posted.add(uri.path);
        },
      );

      await expectLater(
        responder.respond(
          client: client,
          state: _stateFor(_runsCapableCapabilitiesFixture),
          approvalId: '   ',
          decision: HermesApprovalDecision.once,
          activeRunIds: ['run_1'],
          reportError: reported.add,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message.toString(),
            'message',
            contains('approval id is missing'),
          ),
        ),
      );

      expect(posted, isEmpty);
      expect(reported, hasLength(1));
      expect(reported.single, contains('approval id is missing'));
    });

    test(
      'uses the run identity when current Agent omits an approval id',
      () async {
        final responder = HermesApprovalResponder();
        final posts = <(Uri, Map<String, Object?>)>[];
        final client = _client(
          onPost: (uri, h, body) async {
            posts.add((uri, jsonDecode(body) as Map<String, Object?>));
          },
        );

        await responder.respond(
          client: client,
          state: _stateFor(_runsCapableCapabilitiesFixture),
          approvalId: '',
          runId: 'run_current',
          decision: HermesApprovalDecision.once,
          activeRunIds: ['run_current'],
        );

        expect(posts.single.$1.path, '/v1/runs/run_current/approval');
        expect(posts.single.$2, {'choice': 'once'});
      },
    );

    test(
      'denies when capabilities forbid run approvals and reports the message',
      () async {
        final responder = HermesApprovalResponder();
        responder.registerApproval('appr_1', 'run_1');
        final posted = <String>[];
        final reported = <String>[];
        final client = _client(
          onPost: (uri, h, b) async {
            posted.add(uri.path);
          },
        );

        await expectLater(
          responder.respond(
            client: client,
            state: _stateFor(_runsWithoutApprovalCapabilitiesFixture),
            approvalId: 'appr_1',
            decision: HermesApprovalDecision.once,
            activeRunIds: ['run_1'],
            reportError: reported.add,
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message.toString(),
              'message',
              contains('did not advertise approval responses'),
            ),
          ),
        );

        // The current channel behavior reports the denial to state.errorMessage
        // before throwing, so the responder must too.
        expect(posted, isEmpty);
        expect(
          reported.single,
          contains('did not advertise approval responses'),
        );
      },
    );

    test(
      'rejects when neither the mapping nor a single run resolves',
      () async {
        final responder = HermesApprovalResponder();
        final posted = <String>[];
        final reported = <String>[];
        final client = _client(
          onPost: (uri, h, b) async {
            posted.add(uri.path);
          },
        );

        await expectLater(
          responder.respond(
            client: client,
            state: _stateFor(_runsCapableCapabilitiesFixture),
            approvalId: 'appr_1',
            decision: HermesApprovalDecision.once,
            activeRunIds: ['run_1', 'run_2'],
            reportError: reported.add,
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message.toString(),
              'message',
              contains('active run is no longer available'),
            ),
          ),
        );

        expect(posted, isEmpty);
        expect(reported.single, contains('active run is no longer available'));
      },
    );

    test(
      'resolves the run from the registered mapping with several active runs',
      () async {
        final responder = HermesApprovalResponder();
        responder.registerApproval('appr_1', 'run_1');
        final posts = <(Uri, Map<String, Object?>)>[];
        final client = _client(
          onPost: (uri, h, body) async {
            posts.add((uri, jsonDecode(body) as Map<String, Object?>));
          },
        );

        await responder.respond(
          client: client,
          state: _stateFor(_runsCapableCapabilitiesFixture),
          approvalId: '  appr_1  ',
          decision: HermesApprovalDecision.always,
          activeRunIds: ['run_1', 'run_2'],
          selectedProfileId: 'coder',
        );

        final (uri, body) = posts.single;
        expect(uri.path, '/v1/runs/run_1/approval');
        expect(uri.queryParameters['profile'], 'coder');
        expect(body, {'approval_id': 'appr_1', 'choice': 'always'});
      },
    );

    test(
      'resolves the run from the single active run when unregistered',
      () async {
        final responder = HermesApprovalResponder();
        final posts = <(Uri, Map<String, Object?>)>[];
        final client = _client(
          onPost: (uri, h, body) async {
            posts.add((uri, jsonDecode(body) as Map<String, Object?>));
          },
        );

        await responder.respond(
          client: client,
          state: _stateFor(_runsCapableCapabilitiesFixture),
          approvalId: 'appr_2',
          decision: HermesApprovalDecision.once,
          activeRunIds: ['run_7'],
        );

        final (uri, body) = posts.single;
        expect(uri.path, '/v1/runs/run_7/approval');
        expect(body, {'approval_id': 'appr_2', 'choice': 'once'});
      },
    );

    test('success removes the registered mapping', () async {
      final responder = HermesApprovalResponder();
      expect(responder.registerApproval('appr_1', 'run_1'), isTrue);
      final client = _client();

      await responder.respond(
        client: client,
        state: _stateFor(_runsCapableCapabilitiesFixture),
        approvalId: 'appr_1',
        decision: HermesApprovalDecision.once,
        activeRunIds: ['run_1'],
      );

      // The mapping is gone and, with two runs active, the fallback cannot
      // hide a stale entry.
      expect(responder.resolveRunId('appr_1', ['run_1', 'run_2']), isNull);
      expect(responder.forgetApproval('appr_1'), isFalse);
      expect(responder.registerApproval('appr_1', 'run_1'), isTrue);
    });

    test(
      'failure while the run is active reports the redacted error and rethrows',
      () async {
        final responder = HermesApprovalResponder();
        responder.registerApproval('appr_1', 'run_1');
        final reported = <String>[];
        final client = _client(
          onPost: (uri, h, b) async => throw StateError('approval failed'),
        );

        await expectLater(
          responder.respond(
            client: client,
            state: _stateFor(_runsCapableCapabilitiesFixture),
            approvalId: 'appr_1',
            decision: HermesApprovalDecision.once,
            activeRunIds: ['run_1'],
            safeError: (error) => 'REDACTED:$error',
            reportError: reported.add,
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('approval failed'),
            ),
          ),
        );

        expect(reported, hasLength(1));
        expect(
          reported.single,
          startsWith('Could not answer approval: REDACTED:'),
        );
        // A transient failure keeps the mapping so a later attempt can retry.
        expect(responder.resolveRunId('appr_1', ['run_1']), 'run_1');
      },
    );

    test(
      'failure after the run ended is swallowed without reporting',
      () async {
        final responder = HermesApprovalResponder();
        responder.registerApproval('appr_1', 'run_1');
        final activeRunIds = <String>['run_1'];
        final reported = <String>[];
        final client = _client(
          onPost: (uri, h, b) async {
            // The run ended while the response was in flight: the channel's
            // terminal cleanup forgets the mapping and the active run before
            // the error is inspected.
            responder.forgetApprovalsForRun('run_1');
            activeRunIds.clear();
            throw StateError('approval failed after the run ended');
          },
        );

        await responder.respond(
          client: client,
          state: _stateFor(_runsCapableCapabilitiesFixture),
          approvalId: 'appr_1',
          decision: HermesApprovalDecision.once,
          activeRunIds: activeRunIds,
          safeError: (error) => 'REDACTED:$error',
          reportError: reported.add,
        );

        expect(reported, isEmpty);
      },
    );

    test('trimmed blank ids still report before the capability gate', () async {
      final responder = HermesApprovalResponder();
      final reported = <String>[];
      // Even without run-approval capabilities, a missing id reports first.
      await expectLater(
        responder.respond(
          client: _client(),
          state: _stateFor(_runsWithoutApprovalCapabilitiesFixture),
          approvalId: '  ',
          decision: HermesApprovalDecision.once,
          activeRunIds: ['run_1'],
          reportError: reported.add,
        ),
        throwsStateError,
      );
      expect(reported.single, contains('approval id is missing'));
    });

    test('forgetApprovalsForRun and forgetApproval remove mappings', () async {
      final responder = HermesApprovalResponder();
      responder.registerApproval('appr_a', 'run_1');
      responder.registerApproval('appr_b', 'run_1');
      responder.registerApproval('appr_c', 'run_2');

      responder.forgetApprovalsForRun('run_1');

      expect(responder.resolveRunId('appr_a', ['run_1', 'run_2']), isNull);
      expect(responder.resolveRunId('appr_b', ['run_1', 'run_2']), isNull);
      // The other run's approvals are untouched.
      expect(responder.resolveRunId('appr_c', ['run_1', 'run_2']), 'run_2');

      expect(responder.forgetApproval('appr_c'), isTrue);
      expect(responder.forgetApproval('appr_c'), isFalse);

      responder.clear();
      expect(responder.resolveRunId('appr_c', ['run_1', 'run_2']), isNull);
    });
  });
}
