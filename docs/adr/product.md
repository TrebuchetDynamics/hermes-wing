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

## Wing Link deprecation

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

Existing management code, routes, installers and stored credentials remain in the
worktree until explicit retirement work completes. Their security and authority
rules still apply during migration. Do not erase paired records, restart personal
runtimes or weaken checks to hide this dependency. Missing advertised Agent APIs
leave an operation unavailable with an explanation; do not replace Wing Link with
an unrestricted shell or shadow domain backend. See the removal tasks in
[root TODO](../../TODO.md#now--next).

This accepted direction is not evidence of removal, native discovery integration
or phone setup qualification.

## Flexible guidance

- Match Desktop navigation and wording by default; document deliberate deviations.
- Use platform-native presentation where required, preserving Desktop behavior and accessibility.
- Unsupported capabilities should be hidden or explained instead of imitated with unreliable local state.
- Product and platform support claims require matching runtime evidence.

Use [CONTEXT.md](../../CONTEXT.md) for current product language and route names.
