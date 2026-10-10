# Plan reference policy

## Flutter port target

All Wing plans use **Nous Research Hermes Desktop**, located at
`hermes-agent/apps/desktop/`, as the application to port to Flutter.
The official repository is
[NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent/tree/main/apps/desktop).
Read its `README.md`, `AGENTS.md`, `src/AGENTS.md` and `DESIGN.md` before deriving a slice.
The [reference record](../quality/official-desktop-reference.md) owns provenance
and withdrawal of earlier separate-app parity conclusions.

The inspected local Agent revision is
`158fd638da1629c8e62caf9ade1515d162def8ab`.
This identifies a checkout, not live upstream freshness or a released application.
Keep the upstream checkout read-only. A Flutter port reproduces official app
behavior without copying Electron internals or modifying Hermes Agent.

## Using retained plans

The reference notice at the top of each plan governs its current use.
Historical bodies preserve their original proposals, implementation sequences
and executed Wing checks. They are not current product authority.
Old app versions, feature lists, source names, graphs and screenshots must not
be reassigned to the official app without a fresh source comparison.

Use [the current product decision](../adr/product.md),
[PRD](../product/prd.md), [roadmap](../../ROADMAP.md) and
[root backlog](../../TODO.md) for accepted scope and ordering.
Wing Link is deprecated and is not a port prerequisite.
Conduit and Hermes Mobile can inform techniques, not replace the product reference.
Deferred proposals and superseded Agent contracts remain deferred or superseded.

## Re-baseline acceptance

Existing tasks `CONNECTION-OFFICIAL-DESKTOP-PORT` and `PARITY-OFFICIAL-MATRIX`
own connection tracing and rebuilding the withdrawn feature matrix.
Preserve their dependencies and active ownership. Do not create duplicate tasks.

For each new port slice:

1. Record the official app revision and real source components.
2. Trace transport, authentication, profile and process ownership into nearest tests.
3. Identify the Wing caller and exact supported contract. Similar labels are not compatibility proof.
4. Implement the smallest Flutter slice with recovery and accessibility tests.
5. Record named-platform execution separately from source comparison and fixture checks.

Retain passing Wing checks only for the Wing behavior and source they exercised.
Re-baselining plans does not qualify existing UI, JSON-RPC/HTTP compatibility,
native execution, complete parity or delivery to main.

## Applying the official knowledge study

The [maintained knowledge findings](../analysis/official-desktop-graphify.md#bounded-knowledge-study-and-planning-consequences)
come from the pinned official Desktop source, not the retired separate application.
Graph queries and inspected test assertions are source evidence only.

- `CONNECTION-OFFICIAL-DESKTOP-PORT`: use shared gateway ownership, timeout/abort,
  headless launch and request-lease findings to trace one production connection slice.
- `PARITY-OFFICIAL-MATRIX`: map boot, pane composition, replay, Stop and expired-input
  outcomes into real source/test references and separate Linux/Android acceptance.
- `DOC-PARITY-TAB-CONTRACT`: trace official pane/session ownership and keyboard/close
  behavior before implementing supported multi-conversation presentation.
- The [daily-use plan](2026-10-03-desktop-daily-workflow.md#official-lifecycle-source-trace)
  applies warm/cold replay and input/Stop scenarios to existing recovery acceptance.

Preserve milestone focus, dependencies and live worker ownership. The study does
not authorize a transport migration, dynamic plugin system, new host-management
service, Agent edits, personal-runtime changes or release. Wing Link stays deprecated.
Deep semantic gaps are readings within the corresponding implementation tasks,
not additional preflight cards that replace working vertical slices.

## Plan locations

- [Current and retained plans](.) contain roadmap, daily workflow and integration records.
- [Detailed implementation plans](../superpowers/plans/) retain task-by-task sequences.

The notices apply to both collections. The task ledger remains the executable
backlog; unchecked boxes in historical plans do not dispatch work.
