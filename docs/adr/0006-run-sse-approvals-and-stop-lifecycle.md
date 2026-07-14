# ADR 0006: Model Hermes runs as SSE-driven chat work with approvals and stop controls

Status: accepted
Date: 2026-07-07

## Context

Hermes supports both session chat streaming and `/v1/runs` with event streams. Runs can emit deltas, tool events, approval requests, terminal success/failure/cancel events, and stop requests. Hermes Agent 0.18 accepts `input`; older fixtures accepted `message`.

## Decision

For supported endpoints, Navivox uses run transport for streamed work and treats SSE events as the source of live transcript state. Run events drive assistant deltas, tool progress rows, approval requests, terminal states, and server stop. The client sends both `input` and `message` when starting a run for compatibility across Hermes Agent versions. ADR 0026 generalizes this HTTP-command and SSE lifecycle to other Hermes control-plane domains.

Ordinary Hermes requests have a bounded timeout, and an SSE stream that stays open without any activity is failed after a bounded idle interval so the UI cannot remain permanently stuck in a streaming turn.

## Consequences

- `stopActiveTurn` should stop the server run when `/v1/runs/{run_id}/stop` is available and always cancel local stream state.
- Approval UI must be tied to the active run and tolerate the run disappearing before an answer is sent.
- SSE decoding, stream errors, dropped streams, and terminal events are core behavior and require tests.
- Compatibility shims should be removed only after supported Hermes Agent versions converge.

## Edge cases

- Streams that close before a terminal event are failures unless reconciled by server history.
- Approval events missing an approval id fail the active assistant turn instead of showing an unanswerable approval.
- Stale run submissions, disconnects, and session switches must not mutate a newer connection.
- Local stop must still work when the server stop endpoint is absent.

## Evidence

- `README.md:20-24`
- `lib/core/hermes/channel/hermes_channel.dart:29-48`
- `lib/core/hermes/client/hermes_api_client.dart:173-214`
- `lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart:24-30`
- `lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart:88-237`
- `lib/core/hermes/channel/api_channel/hermes_api_channel_approvals.dart`
- `test/core/hermes/channel/hermes_api_channel_test.dart:20-28`
