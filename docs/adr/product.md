# Product boundaries

The only Desktop product reference is [Nous Research Hermes Desktop](https://github.com/NousResearch/hermes-agent/tree/main/apps/desktop),
locally `hermes-agent/apps/desktop/`. Prior separate-app comparisons are
[withdrawn as official parity evidence](../quality/official-desktop-reference.md).
Existing Wing test results do not establish parity with this corrected reference.

Status: current

## Decision

Hermes Wing prioritizes a 1:1 Hermes Desktop product port in Flutter: feature
coverage, navigation, terminology, interaction flows, state transitions and
recovery behavior follow Desktop rather than a separately designed client.
This is product/behavior parity, not a line-for-line Electron implementation.
The owner reaffirmed that this applies across the product, not only to feature
availability. Desktop guides welcome and connection, navigation and screen
structure, terminology, layout, visual hierarchy, interaction, Chat, sessions,
profiles, settings and recovery. Equivalent backend outcomes alone are insufficient.
Flutter and platform adaptations must preserve that experience. Necessary
differences remain explicit parity gaps, not silently accepted substitutes.
Agent authority and deprecated Wing Link code do not justify a different user experience.
Platform adaptations must preserve the reference behavior or explicitly record
the difference. This priority was accepted by the product owner on 2026-10-03;
it does not establish that parity has already been implemented or qualified.

Hermes Agent owns profiles, Projects, configuration, memory, skills, sessions,
runs, tools, schedules, approvals, gateway state, and other Agent domains. Wing
uses Hermes interfaces rather than creating a second source of truth. Hermes One
remains a separate optional authority for account and cloud features.

The owner confirmed on 2026-10-07 that Wing Link must not be required to use
Wing. Local connects directly to Hermes Agent. SSH uses a Wing-managed native
forward to Agent. Remote connects directly through supported Agent authentication.
None of these paths may require Wing Link installation, pairing or credentials.
Match Hermes Desktop's entry, wording and interaction flow rather than organizing
onboarding around host management.

This is accepted product intent, not shipped onboarding or managed SSH support.
Direct Agent connection exists. The committed enrollment places it inside pairing;
the current development worktree adds primary Add Hermes access with separate
optional setup/pairing. The [first-run receipt](../quality/direct-first-run.md)
records bounded widget/Chromium qualification on Linux. The
[native first-run receipt](../quality/direct-first-run-native.md) adds Linux GTK
fixture qualification, not main delivery, Android or live authentication. The [connection requirements](../product/prd.md#connection-path-requirements)
and backlog own the remaining implementation and qualification.

The owner-supplied APK screenshot shows a Profiles empty state with gateway-first
copy and bottom navigation, with Chat selected while the title reads Profiles.
This is not Desktop's welcome experience. Primary direct access qualifies a
connection prerequisite, not welcome fidelity or the delivered APK's parity.

## Official Desktop features only

Status: Accepted

The owner explicitly requires a **1:1 Flutter port**, implementing only product
features present in the official `hermes-agent/apps/desktop` reference. This
supersedes earlier permission to develop Wing-specific extra surfaces. Every
feature/task must identify the pinned official source and its actual user outcome,
navigation, terminology and interaction/recovery behavior before implementation.
An Agent API, a third-party client, an old matrix or an existing Wing screen alone
is not evidence that the feature belongs to Desktop.

Flutter/platform/accessibility adaptations may deliver the same reference outcome;
they may not introduce unrelated product capabilities. Missing safe Agent contracts
remain explicit gaps, not a fork, shadow backend or invented UI. Preserve Agent
immutability, user data, credential safety and current active ownership.

The established repository path is `hermes-agent/apps/desktop`. The owner's literal
`hermes-agents/apps/desktop` does not exist in this checkout; no alternate upstream
was substituted. The read-only inspected revision is `158fd638da1629c8e62caf9ade1515d162def8ab`,
not a claim of latest upstream or executed parity.

[Office source evidence](../quality/office-contact-session-reference.md#scope-and-verdict)
finds no Office-named reference surface. Retire Wing's standalone Office route and
navigation instead of enhancing it or calling the Bots roster an Office equivalent.
Preserve shared Agent profiles/connections/sessions; a canonical Bot Chat port is
separate and requires its real official contract. Existing completed Office study
remains history. The [retirement candidate](../quality/office-retirement.md) removes
the Wing-only UI without replacing it with Bots. Its offline checks do not establish
independent acceptance, canonical delivery or native/live qualification.

## Wing Link deprecation

Status: Accepted

Scope: remove Wing Link entirely, including legacy runtime and compatibility paths.
Preserve user data and security checks while retiring their consumers. This records the owner-confirmed direction
below, not approval for Agent changes, new compatibility adapters or deployment.

### Documentation retirement scope

The owner confirmed that Wing Link is fully deprecated and must be removed from
current documentation and navigation. Do not describe it as optional or supported.
Current orientation, setup guidance, requirements, design summaries and navigation
must describe direct Agent use without promoting Wing Link procedures or contracts.

Preserve historical receipts, archived plans and explicit retirement records.
They are historical evidence or removal work, not current product guidance. Keep
retained contracts out of current-user navigation; do not relabel their past
execution as evidence for replacement functionality. This documentation policy
does not claim that remaining code, services or stored credentials are removed.

Source: the owner's `/grill_with_docs` statement and questionnaire selection,
“Remove from current docs/navigation; preserve history and retirement records”.

The owner now requires deprecation of Wing Link, not merely optional pairing.
This supersedes the earlier optional-management product direction. New connection
and setup work must use Hermes Agent directly or reviewed platform-native local
operations. Do not add Wing Link installation, pairing, credentials or catalog
calls to replacement flows. Linux Local should inspect `~/.hermes` by default
and offer deliberate selection of another Hermes home. This is not an Agent
Project or conversation working-directory selection. Android Local should guide
same-phone setup and direct connection, using the mobile reference for interaction
research rather than importing its runtime modifications.

The management client/service, installers and release dependencies are removed.
Raw legacy records and secure slots remain inert and preserved. Do not erase paired records, restart personal
runtimes or weaken checks to hide this dependency. Missing advertised Agent APIs
leave an operation unavailable with an explanation; do not replace Wing Link with
an unrestricted shell or shadow domain backend. See the removal tasks in
[root TODO](../../TODO.md#now--next).

This accepted direction is not evidence of removal, native discovery integration
or phone setup qualification.

### Complete removal including legacy

Status: Accepted

Source: owner `/autoresearch plan` direction: “remove wing-link even for legacy.
In readme mentions it”. This extends retirement to all legacy implementation, not
only new-user promotion. Planning saves requirements and work; it does not launch
implementation or authorize personal service removal.

Decision: remove rather than keep an optional legacy mode or rename the service.
Hermes Agent remains authoritative. Missing Agent capabilities stay unavailable;
no replacement shell bridge or shadow backend is permitted.

The existing queue owns acceptance and delivery of this plan; implementation
retirement does not itself close native/live qualification or publication:

1. **CONNECTION-LINK-REMOVAL — finish consumer removal.** Preserve the current
   enrollment worker and its frozen contract. Then retire explicit QR/handoff routes,
   payload/controller APIs, computer setup guide, Local/Termux bootstrap, dormant
   Profiles/Connections builders and directory adapters, saved-contact metadata and
   Link credential APIs. Trace router, cancellation, reconnect and reload callers.
   Remove obsolete fixtures and localization input, then regenerate outputs. Existing
   Agent endpoint/profile/session identity and credentials must survive upgrade.
   Records lacking a usable Agent credential require explicit direct reauthentication,
   not recovery through Link. Old pairing input must fail safely with direct-connection
   guidance. Preserve raw user stores; do not auto-delete records or contact services.
2. **CONNECTION-LINK-RETIREMENT — delete delivery and service closure.** After the
   last caller is gone, remove `lib/core/wing_link/`, `wing_link/`,
   `install-wing-link.sh`, platform bundling and service hooks, release/smoke jobs,
   packaging dependencies and old test/fixture exports. Update current README, landing
   visuals, getting-started, routes, security/design/runbooks and contributor/agent
   guidance so none offers a legacy mode. Preserve Git history, archived plans and
   authentic qualification receipts as history, not navigation or shipped dependencies.
   Do not uninstall or stop an already installed personal service in this task.
3. **Verify and deliver each bounded slice.** Exercise fresh and previously saved
   Agent connections, rejected old pairing input, cancel/back, reconnect, exact-session
   restoration, credential isolation and no mutation replay. Require zero Link
   construction, network requests, subprocesses or fallback after absent/denied Agent
   capabilities. Keep TLS, origin validation, redaction, secure storage, accessibility
   and owner fencing. Delete service-specific tests only with the retired service;
   preserve or adapt still-relevant Agent security tests. Use independent review,
   scoped commits, affected integrated-tree checks and verified `origin/main` delivery.
   Native/device/provider qualification remains distinct from fixture tests.

Observed baseline at `312b929290eb3bab7ded7daf4063c9522aa1501b`: 159 owned
source/delivery files contain a Link identifier or have a Link-named path. This is
conservative text inventory, not 159 active consumers or observed usage. The scan
includes service tests within `wing_link/`; it excludes upstream, vendor/imported
assets, generated localization and historical docs. Target: zero shipped runtime
compatibility/dependencies, with historical evidence and privacy-only safeguards
classified rather than erased to improve a text count. README orientation and
first-chat instructions no longer name or illustrate the retired integration.

Graph evidence: fresh local Graphify AST for 11 `lib/core/wing_link/` files,
252 nodes; query `WingLinkClient LocalWingLinkHost setup credentials devices
directories transport` identifies `WingLinkClient` at `wing_link_client.dart:198`,
`LocalWingLinkHost` at `local_wing_link_host.dart:53` and setup at line 93.
Coverage is partial: docs, service/packaging and callers are source-inspected, not
semantically graphed; diagnostics report three collapsed import/export pairs and
one self-loop (274 raw edges versus 271 graph edges). Graph
relationships are leads, not proof of usage or acceptance.

Ready-to-run planning configuration (not execution):

```text
Goal: Remove Wing Link, including legacy runtime and packaging, without losing Agent access or user data.
Scope: lib/core/wing_link; enrollment/local_setup/profiles/gateway/saved-contact callers; wing_link; installers/platform hosts/.github/scripts; affected tests/localization/current docs.
Metric: Remaining owned source/delivery files with Link identifiers or Link-named paths; classify safety-only remnants and require zero runtime dependencies.
Direction: lower_is_better
Verify: Run the read-only inventory command below; confirm dependency/public-control guards separately.
Guard: flutter analyze --no-pub; focused caller/security tests; full affected integrated suite; deterministic web build/E2E; packaging/artifact closure; git diff --check.
Iterations: 6 bounded consumer/delivery slices, checkpoint and rescan after each.
```

Read-only inventory command, run from the repository root:

```bash
python3 -c 'import pathlib,re,subprocess; roots=("lib/","wing_link/","scripts/","android/","ios/","linux/","macos/","windows/","web/",".github/"); skip=("vendor/","third_party/","omniroute_assets/","app_localizations"); rx=re.compile(r"wing[_ -]?link|WingLink",re.I); files=subprocess.check_output(["git","ls-files"],text=True).splitlines(); print(sum(1 for f in files if (f.startswith(roots) or f in ("install-wing-link.sh","pubspec.yaml","package.json","serve_web.mjs")) and not any(s in f for s in skip) and pathlib.Path(f).is_file() and (rx.search(f) or rx.search(pathlib.Path(f).read_bytes().decode("utf-8",errors="ignore")))))'
```

Verification commands above are planned guards, not newly executed feature checks.
The inventory command was exercised and returned a numeric baseline. Skill
application: deprecation-and-migration bound data preservation and caller closure;
planning-and-task-breakdown ordered the two existing task IDs; documentation-and-adrs
kept the decision in this living owner and removed misleading README orientation.

## Flexible guidance

- Match Desktop navigation and wording by default; document deliberate deviations.
- Use platform-native presentation where required, preserving Desktop behavior and accessibility.
- Unsupported capabilities should be hidden or explained instead of imitated with unreliable local state.
- Product and platform support claims require matching runtime evidence.

Use [CONTEXT.md](../../CONTEXT.md) for current product language and route names.
