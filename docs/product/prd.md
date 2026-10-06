# Hermes Wing product requirements

Status: current product direction

Pending decisions: [continuity retention](continuity-retention-proposal.md) and
[notification contracts](notification-contract-proposal.md) are proposals, not
approved storage or delivery features. See the
[capability claim audit](capability-claim-audit.md) before expanding support claims.

## Product

Hermes Wing is a Flutter client for Hermes Agent on desktop, web, and mobile.
The accepted direction is a 1:1 Hermes Desktop product/behavior port, with Flutter
desktop and wide web as the fidelity baseline while preserving mobile usability.
Match feature coverage, navigation, terminology, interactions and recovery;
platform-native implementation may differ, but product deviations must be explicit.
See [product boundaries](../adr/product.md) and the
[parity ledger](hermes-desktop-parity.md).

Full local Desktop functionality is the target through separately designed,
reviewed bounded native integration. Remote mode may expose a smaller exact-
capability-gated subset; browser width grants no host-local authority. These are
accepted requirements, not claims of shipped parity or approved native contracts.

Hermes Agent remains authoritative for profiles, projects, providers, models,
sessions, tools, schedules, memory, and gateway state.

## Architecture

Hermes Wing uses two authenticated connections:

- the **Hermes Agent data plane** for chat, sessions, runs, tools, approvals, and
  every supported Agent API; and
- the **Wing Link management plane** for remote setup, pairing, runtime lifecycle,
  diagnostics, and reviewed compatibility operations that require host access.

Wing Link runs beside Hermes Agent. It is remote-capable on an explicitly
configured private/VPN interface, but it is not a chat proxy, arbitrary shell,
general file manager, or second Agent backend.

## Leading acceptance outcome

The next milestone is local connection → explicit profile/model/session selection
→ actual Chat generation → correlated approval and authoritative Stop → leave and
relaunch → restore exactly the same session without duplicate sends.

Acceptance requires authoritative identity, model, history and terminal-outcome
readback; one submission per deliberate send; and no sends, session creation or
approval replay caused by restoration. Keyboard operation and compact/mobile
usability must remain available. The
[daily-workflow plan](../plans/2026-10-03-desktop-daily-workflow.md) owns the detailed
verification matrix and evidence requirements. Fixture output and source/unit
checks do not establish live generation, native execution or milestone acceptance.
This integrated outcome remains unqualified; supporting shell polish does not
substitute for it.

## Core journeys

These journeys describe intended scope, not uniform current support. Their
priority follows the leading outcome above; availability remains operation- and
platform-specific.

1. Install or connect to a trusted Hermes host and pair without placing bearer
   credentials in a QR code.
2. Choose a profile and session, send text or voice transcripts, follow events,
   answer approvals, and stop or resume work.
3. Inspect health and perform explicit lifecycle or recovery actions.
4. Create, clone, rename, describe, and delete profiles through Agent-owned or
   fixed Wing Link contracts.
5. Browse approved host folders—without listing files—and create a per-profile
   Hermes Project for a repository or subfolder.
6. Configure providers and models remotely through typed write-only contracts;
   provider secrets are never returned.

## Product rules

- Advertise only operations supported by the connected Agent and Wing Link.
- Keep remote mutations explicit; never queue or replay them after reconnect.
- Use stable resource IDs and opaque directory handles, not client-supplied host
  paths. Wing Link returns child folders only, never file entries.
- Keep secrets in platform secure storage. Prefer trusted HTTPS or an encrypted
  VPN remotely; future provider-secret operations must reject plaintext.
- Require confirmation for destructive, secret, filesystem-grant, and lifecycle
  actions.
- Preserve an accessible non-spatial path for every outcome.
- Make platform and release claims only from runtime evidence.

## Current status

The alpha supports direct Agent chat/runs/sessions, approvals, health, pairing,
Linux Wing Link lifecycle, bounded profile lifecycle, capability-gated provider,
model, and SOUL management, and read-only navigation of locally approved host
folders. Hermes Project creation and assignment, project-scoped Chat, signed
packages, and non-Linux Wing Link services remain planned or unqualified.

See [Wing Link](wing-link.md), [Routes](routes.md), the
[compatibility contract](hermes-compatibility.md), and the
[roadmap](../../ROADMAP.md).
