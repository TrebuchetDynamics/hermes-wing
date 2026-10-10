# Hermes Mobile reference study

## Scope and status

Reference: [omarqaterge/hermes-mobile-app](https://github.com/omarqaterge/hermes-mobile-app)
at revision `45e1fcf24ae0c811cd66e6d9b3a448986a6e902d`.
This study used source and test inspection only. No reference installation,
build, test, device interaction or battery measurement was performed.
It is not a security audit or Wing runtime qualification.

Hermes Desktop remains the accepted product and behavior reference.
Hermes Mobile is a secondary source for mobile interaction and recovery scenarios.
Its architecture is React/TypeScript in a Java Android shell, with an on-device
Termux/proot runtime and a custom Agent plugin. Do not treat its plugin routes
as advertised standard Agent capabilities.

## Reuse candidates

Paths in this table refer to the pinned reference repository, not Wing files.
These recommendations do not establish implemented support or new requirements.

| Candidate | Source | Wing application and status |
| --- | --- | --- |
| Resume and request efficiency | `web/src/gateway.ts`, `activity.ts`, `health.ts` | Reuse suspended-timer and visibility scenarios around Wing's existing lifecycle path. Separate connection freshness from inventory freshness. Do not add another transport or promise battery savings. |
| Rich transcript controls | `web/src/components/Markdown.tsx` | Proposed table copying and code wrapping in the existing renderer. Diagram/math rendering needs bounded input and an accessible source fallback. Partial streamed content must remain readable. |
| Tool summaries | `web/src/fold.ts`, `order.ts`, `components/ChatItems.tsx` | Reuse ordering, error and live-tool scenarios for existing Wing grouping. Preserve canonical history after reconnect and native restart. Existing CHAT-FIDELITY tasks own qualification. |
| Notifications | `android/src/com/omarqaterge/hermesmobile/HermesService.java` | Proposal only. Distinguish urgency, suppress duplicate visible alerts and revalidate the exact request after a deliberate tap. Follow the existing notification proposal rather than copying raw resource identities into payloads. |
| Voice and Back navigation | `web/src/components/TtsPlayer.tsx`, `backstack.ts`, `live.ts` | Candidate explicit playback controls and top-layer Back behavior. Reuse existing Wing providers and routes. Physical audio and native lifecycle remain separate qualification. |

Wing's current seams include
[`HermesRichText`](../../lib/features/hermes_chat/presentation/hermes_rich_text.dart),
[`HermesChatTimeline`](../../lib/features/hermes_chat/presentation/hermes_chat_timeline.dart)
and the [chat screen lifecycle](../../lib/features/hermes_chat/screens/hermes_chat_screen.dart).
These are extension points, not proof that every candidate is implemented.
The [test plan](../test-plan.md#mobile-reference-scenarios) owns expected outcomes.
The [root backlog](../../TODO.md) retains task identities, dependencies and ownership.

## Boundaries that must remain

- Keep server state authoritative after reconnect. The reference's persistent
  outbox and automatic flush are not compatible with Wing's no-replay rule.
  Keep drafts for deliberate Send instead.
- Do not copy transcript persistence defaults from `web/src/chatcache.ts`.
  Persistent previews remain subject to the existing retention proposal.
  Resource identity must include Agent origin, profile and session.
- Do not copy direct SQLite search from `hermes-plugin/hermes-mobile/chat_search.py`
  or Agent-internal replacement from `checkpoints.py`. Use exact advertised APIs.
- Do not infer completion from heartbeat expiry. Show stale/unknown state until
  authoritative reconciliation. Expiry is not evidence that a run is Ready.
- Do not use loose spoken yes/okay matching as approval authority.
- Do not import Termux callback servers, runtime patches, client-owned schedules
  or a persistent foreground service as a remote-client requirement.

Canvas revision history is a separate contract-dependent candidate.
`web/src/components/Canvas.tsx` permits scripts in an iframe, and
`secure-bridge.ts` protects against native bridge exposure. Start any Wing
artifact preview inert and bridge-free. The existing ARTIFACTS goal does not
approve arbitrary active HTML, collaborative history or file rollback.

## Evidence limits and attribution

The reference's `docs/battery-report.md` excludes deep-sleep/Doze verification.
Its measurements do not predict Flutter energy use. Notification replies and
questions depend on an existing Activity connection; otherwise the service
falls back to a draft. Do not repeat the README claim as unconditional support.

The reference is MIT-licensed, Copyright 2026 Omar Qaterge.
Substantial copied code requires preserved notices. Inspect `THIRD_PARTY.md`
for separate attribution before importing code. No reference code was imported
by this documentation pass.

## Backlog disposition

Update existing transcript qualification tasks with relevant tool-summary cases.
Do not duplicate their native/restart work or change the CONNECTION-PATHS focus.
Table copying, code wrapping, notification delivery and additional voice controls
remain proposals unless an accepted requirement or owner decision selects them.
The existing [notification proposal](../product/notification-contract-proposal.md)
and [retention proposal](../product/continuity-retention-proposal.md) remain unapproved.
This study neither creates a new goal nor closes an existing goal.
