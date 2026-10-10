# Global loaded-session access

> Reference correction: [official Desktop authority](../quality/official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Task `t_1c1e6f37` adds a bounded expanded desktop/wide-web sidebar section.
Implementation is completed and independently approved in same-card review run 169.
The reviewer independently passed 75 focused tests and six compiled Chromium cases.
It verified 24 scoped hashes and reused 171 unchanged neighboring test passes.
Native review identifies the approval lane, not native desktop execution.
This is not full Desktop sidebar or daily-workflow qualification.

## User behavior

From Tools, Schedules, Providers or Settings, **Loaded sessions** exposes the
current Agent owner's already-loaded inventory. **Open …** selects the exact row
through the existing channel history/recovery path; even the active row follows
that existing read/selection contract. **New Session** explicitly creates once.
Both return to Chat only after a still-current acknowledged result. Pending work
disables repeated input. Failures remain on the feature with generic, localized
feedback; there is no automatic retry or deferred navigation-first action.

The original loaded sidebar surface provides Open and New only. The later
[global session modal](../quality/global-session-modal.md) exposes the existing
session panel over feature routes through Sessions or Ctrl/Command+K. Search
receives focus, Tab/Shift+Tab stays inside, and Escape/Close returns focus to the
surviving opener. Local search adds no reads; Load more and management remain
explicit and capability-gated. Exact activation returns to Chat after acknowledgement.
Owner/resource/route loss rejects stale callbacks; cancellation/reopening never
replays New, prompts or approvals. Chat retains its full rail and compact picker.
The [adaptive panel receipt](../quality/global-session-modal-adaptive.md) adds
compact/wide and short-window keyboard access at separate 200% text/zoom.
The shared panel scrolls controls and rows together and reveals current focus
after resize; Close remains outside that scroll surface. These presentation
changes also apply to the Chat sheet. Neither receipt qualifies native/live
or screen-reader behavior. Recents live
inside the existing sidebar, not a third column. Collapse removes their focus
and semantics and invalidates in-flight caller admission. Compact layouts retain
existing Chat/Profiles/Connections/More route access; resize-back reprojects loaded
state without extra reads. The section does not retain an offstage Chat screen.

## Ownership and passive observation

`hermesDirectoryLifetimeProvider` exposes only the provider-owned directory
reference. It has no contact/session inventory or selection store, does not
construct/start the directory, and never owns directory disposal. The production
directory factory publishes its instance and detaches it synchronously on provider
disposal/invalidation. Its existing `start()` and restoration sequence are unchanged.
No existence-conditioned eager-provider read or Riverpod weak-listener seeding
is used. Painting is deferred if a descendant creates the directory during build;
action invalidation is synchronous.

Rendered controls and async admission are bound to channel, connection/profile,
directory lifetime, contact, exact history/create capability, settled restoration,
and loaded resource presence. Same-frame loss/change-back does not revive an old
intent. Route changes, collapse, section disposal, and uncertain-run ownership also
reject late results. Optional `canAccept` is propagated through the existing public
channel create/select contract; stale callers cannot admit history/pagination,
created metadata or selection. A submitted create may still finish at its original
Agent: client admission is not server rollback. No profile/model/message/approval
mutation is replayed. Directory selection persistence remains its existing job.

There is no new draft persistence. Actual GoRouter navigation replaces route-local
screens; Chat's existing volatile composer/disposal semantics remain unchanged.
Shell presentation lifetime is not a new Chat/session domain lifetime.

## Verification

### Current snapshot limit

The following source comparisons describe earlier maintenance snapshots, not
fresh qualification of the later global modal. Its separate
[receipt](../quality/global-session-modal.md) binds the current eight scoped files.
Earlier shell/caller checks retain their historical attribution.

The current `lib/shared/widgets/app_shell.dart` does not match the final manifest
for `t_1c1e6f37`. Comparison with that task's retained branch shows changed sidebar
widths, toggle placement, navigation styling and removal of the brand header.
The other 19 scoped `lib/`, `test/` and `playwright/` fingerprints still match.
Historical approval and passing results remain valid for their recorded snapshot.
They do not prove the changed shell preserves reachability and keyboard behavior.
This is a verification gap, not an observed session or authority defect.
The later [shell redesign receipt](desktop-shell-reference-fidelity.md) records
57 focused widget passes, including the global-session suite, and two compiled
Chromium journeys, including exact Open/New and compact recovery. All four final
source fingerprints in its redesign manifest match this inspected snapshot.
The passing logs are retained under `.task-evidence/desktop-shell-fidelity/`.
The manifest's final sources include the later toggle focus-outline correction.
Use `focus-fix-tests.log` and `focus-fix-browser-tests.log` for those sources;
`redesign-final-tests.log` and `redesign-browser-tests.log` precede that correction.
The later logs again record 57 widget passes and two Chromium passes.
Those historical results did not bind every caller, test and browser input.
The [current-source recheck](../quality/2026-10-06-global-sessions-current-check.md)
now supplies fresh attribution instead of reusing them. Its receipt binds 521
copied inputs and a 195-file local dependency closure at review. All 31 executor
integrity entries remain intact.

The isolated mirror's command receipt records exit 0 for 44 shell-widget cases,
nine caller/lifetime cases, a release web build and one deterministic Chromium
Open/New journey. Browser assertions retain exact history/create requests,
keyboard access, collapse and compact recovery without layout-induced requests.
These are retained execution receipts, not tests run by this documentation pass.
The [independent review receipt](../../.task-evidence/t_d06ef06d/review-run/review-validation.json)
records approved bounded acceptance. Review logs independently record 44 widget
passes, nine caller/lifetime passes, a fresh web build and one Chromium pass.
All 27 review integrity entries remain intact. The documentation recheck found
fifteen changed inputs among the 521 recorded source fingerprints, including shared
recovery code, channel tests and restoration/recreation tests.
The ledger preserves
DOC-GLOBAL-SESSIONS-CURRENT-CHECK as done and its bounded review-snapshot
acceptance. That execution does not qualify the later recovery/Stop changes.
DOC-M2-AMBIGUOUS-404 and DOC-M2-HISTORY-IDENTITY are done for bounded repairs.
DOC-M2-HISTORY-ADMISSION is done with bounded independent approval. The later
[post-repair qualification](../quality/2026-10-06-m2-post-repair-callers.md) supplies
fresh current-source shell/caller/build/browser execution: 85 focused passes and
one compiled Chromium pass. The documentation recheck matches 518 of its 519
copied inputs. `hermes_chat_death_completion_recovery_test.dart` has changed since
that receipt; the pass does not qualify this later test revision.
DOC-M2-POST-REPAIR-CALLERS remains done for its recorded execution slice;
independent same-card final approval remains unverified.
Do not repeat those unchanged checks merely for bookkeeping. Credential-denial
recreation, named-device process death and authoritative live counting remain
separate proof gaps; M2 stays unverified.
Native desktop, live generation, full suites and full parity remain unqualified.

### Retained delivery evidence

Source baseline: `ca149a82189c8c9e5abd98b376bfeae1e43f6f3f` plus the pre-existing
dirty worktree. Desktop reference: `withdrawn reference revision`,
`Layout.tsx:716–763`, read-only. [Client ADR](../adr/client.md) and
[API/state ADR](../adr/api-and-state.md) remain unchanged.

Evidence directory: `.task-evidence/t_1c1e6f37/`; the final manifest,
baseline-relative diff, exact commands/exits, parsed counts, hashes and logs are
also copied to the task's profile-local `autogoal/global-session-access/recovery/`.
The original [diagnostic](../../tools/global_session_access/README.md) is historical,
not a replacement acceptance suite.

Checks cover the actual AppShell/GoRouter, real production directory lifecycle,
real API-channel admission, and deterministic delayed widget channels. Tests prove
nonactive/active exact selection, single create, acknowledgement, single-flight,
late success/rejection, synchronous owner/contact/directory/resource loss, channel
replacement, restoration/selecting/disconnected/uncertain states, generic errors,
Tab/Shift+Tab/Enter/Space, selected named semantics, collapsed controls, short-window
reachability, 200% text/reduced motion and 390px resize recovery. Existing affected
shell, gateway, restoration, disclosure and queued-open tests are retained.

Fresh `flutter build web --release -t lib/main_e2e.dart` and the new
`playwright/tests/regression/global-session-access.spec.mjs` exercise Tools → exact
Open → Tools → New Session, visible keyboard focus, exact profile/session and
request counts, collapse/expand and compact navigation recovery. Existing desktop
navigation and page-two restoration/parked-Retry cases are run with retries=0,
workers=1, isolated ports 18737/18738 and `/usr/bin/chromium`. Node is 26.7.0,
not the recommended 22. Each final suite uses clean deterministic fixture setup;
shared fixture/server/config/helper files are unmodified.

Native desktop interaction, physical Android, screen readers, live Agent/provider
inference, full daily workflow and full parity remain NOT_CHECKED. Chromium
viewports and widget semantics are not those qualifications. No continuation was
resumed, and no Agent/Wing Link/upstream files, personal credentials, profiles,
schedules, commits or external publications were changed.
