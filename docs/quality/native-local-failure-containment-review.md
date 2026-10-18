# Metadata-only native operation: failure containment

## Scope and verdict

Task: `DOC-NATIVE-FAILURE-BOUNDARY`, the dependent proof slice after
[the operation review](native-local-integration-contract-review.md). This is
read-only source, nearest-test and sanitized receipt inspection, not a behavior
change, native activation right, privileged design approval or platform acceptance.

**Verdict:** the existing Linux metadata operation fences admission of stale
results; it does **not** establish hard cancellation, bounded OS completion or
bounded canonical-path output. Retain only its existing discovery/manual-connect
scope. An unresolved directory read is not an unknown Agent mutation, and leaving
Local is not evidence that OS work stopped. Nothing here admits a launcher,
helper, installation, credential acquisition or management fallback.

Binding criteria come from the living [client](../adr/client.md#decision),
[API/state](../adr/api-and-state.md#decision),
[security/privacy](../adr/security-and-privacy.md#decision),
[runtime/delivery](../adr/runtime-and-delivery.md#agent-only-delivery) and
[product](../adr/product.md#official-desktop-features-only) decisions, plus the
[threat model](../security/threat-model.md#current-controls-and-adversarial-cases).
The [reviewed first operation](../plans/2026-10-03-desktop-local-integration-design.md#first-operation-existing-metadata-inspection),
[failure contract](../plans/2026-10-03-desktop-local-integration-design.md#failure-and-recovery-contract)
and [removal criteria](../plans/2026-10-03-desktop-local-integration-design.md#admission-rollback-and-removal-criteria)
remain proposals/criteria under those decisions, not extra permissions.

## Assignment and evidence pins

Initial `git status --short --branch` was clean on the assigned isolated task
branch. Coordinator slot metadata identified this attempt's running worker;
process inspection matched it. The predecessor slot was closed with commit
`f97016600e9ac61591302bcaea4162d0d883b2bc`, which is an ancestor of this baseline.
No other task was selected, no ownership release was inferred, and no task index
was edited.

Pins obtained by `git rev-parse HEAD` and `git -C ../../hermes-agent rev-parse HEAD`:

| Source | Revision | Evidence ceiling |
| --- | --- | --- |
| W: Wing baseline | `2ddbb51b69044c71411e32168750a9a92db4c731` | Source/tests inspected below, unchanged by this task |
| R/D: read-only Agent and official Desktop subtree | `158fd638da1629c8e62caf9ade1515d162def8ab` | Reference only; Desktop `HEAD:apps/desktop` tree `2038178ee53e13cde6fe297daa2484a868e7d3a3` |

R/D was clean. Root and Desktop area `AGENTS.md` guides were read. No installed
runtime source, personal Hermes home, credential store or live Agent was accessed.
The predecessor's installed-runtime pin is historical context, not re-inspected
runtime evidence. Re-pin and re-review on source/contract drift; these pins do not
identify the latest upstream or an active server.

Docs map: live metadata discovery/panel/caller and nearest tests supply W claims;
R/D lifecycle/tests supply only a non-transferable comparison; living decisions
supply acceptance criteria. The predecessor and two historical receipts below
supply context, not new executed checks. This page fills the cancellation,
unknown-outcome, bounds and removal proof gap without altering the reviewed plan.

## Exact source and nearest-test trace

Paths/line ranges refer to W unless prefixed D (relative to R). Tests were
**inspected, not executed**; no regression test is needed for this docs-only task.

| Seam | Observed source | Inspected proof and limit |
| --- | --- | --- |
| Input and result shape | `lib/core/hermes/local_discovery/local_hermes_home_discovery.dart:16-48`: Linux support gate, absolute selected path, maximum 4096 input characters, no C0/DEL, invalid/missing HOME never falls back to cwd. `local_hermes_home_types.dart:3-31` in the same directory: five statuses and optional ephemeral canonical path | `test/core/hermes/local_discovery/local_hermes_home_discovery_test.dart:16-92`: default-only inspection, unsupported denial, invalid input/HOME, sanitized unexpected failure and Android refusal. No cancellation token/deadline/result-size contract in the platform interface |
| Metadata IO | `lib/core/hermes/local_discovery/local_hermes_home_platform_io.dart:19-47`: await symlink resolution, then canonical-directory stat; only directory metadata, no enumeration/content/process access. Error codes 2/20 map to absent/notDirectory; other filesystem failures and stat-notFound map unreadable | Same test file `:94-177`: repeat inspection after symlink retarget, vanished target, stat failure, missing directory, regular file and redacted permission failure. Not a stable snapshot, containment or ownership proof |
| Async admission | `lib/features/hermes_chat/widgets/platform_local_connection_panel.dart:58-122`: generation increments on default read, chooser start, enabled change and disposal; `_current` requires mounted/enabled/current generation. Chooser admission checked both before selected inspection and before display | `test/features/hermes_chat/widgets/platform_local_connection_behavior_test.dart:99-152,271-298`: cancel versus selected metadata, stale default beaten by selection, picker after mode exit ignored, selected inspection after exit/re-entry ignored. These exercise completers/fakes, not an OS cancellation acknowledgment |
| Visible pending/result | Panel `:93-122,148-190`: `_picking` lasts through chooser **and** selected inspection; prior result remains visible until replaced, chooser disabled while picking/busy, direct form remains composed. Null inspection displays inspecting; successful canonical path is local `Text` | Behavior tests `:155-180` deny readiness for unavailable statuses. No named test proves never-settling IO, slow real filesystem, resolved-path length/control characters or cross-entry resource bounds |
| Production mode ownership | `lib/features/hermes_chat/screens/state/hermes_chat_layout.dart:278-300` mounts the panel only for Local with `enabled: true`; `lib/features/hermes_chat/screens/hermes_chat_screen.dart:641-652` abandons the form attempt on deliberate mode change | Mode changes unmount this panel; its generic enabled-transition fence also exists but is not separately covered by the named tests. Form intent/credential handling remains the caller's responsibility, not metadata's |

The unsupported browser seam is
`lib/core/hermes/local_discovery/local_hermes_home_platform_unsupported.dart:3-18`;
IO support itself is Linux-only. Injecting a test platform or overriding Flutter's
target does not prove native support on Android, macOS, Windows or web.

## Cancellation and late-result criteria

These are operation-specific acceptance criteria, not claims of newly added UX.

| Event | Current containment | Required interpretation / remaining proof |
| --- | --- | --- |
| Native chooser returns null | No selected inspection. Keep the prior result; if none exists, start a fresh default inspection. The chooser-start generation has already fenced the old default | Cancellation is not always zero additional IO: pending-default cancellation can cause that fresh read. Existing cancel test covers a settled default, not this branch. Never infer connect/save/Agent readiness |
| New selection while default pending | New generation rejects the old default; only current selected result can replace display | Result-order fence only; old default IO still may finish. Existing delayed-default test proves admission order, not termination |
| Mode change / route disposal | Reject picker result before selected IO if already stale; reject an already-started inspection at its later completion. Disabled panel clears metadata; disposal increments generation | No cancel API is called on chooser or filesystem Future. Panel departure is not picker closure, IO completion or memory/resource release proof. Returning to Local creates fresh inspection, not saved-path recovery |
| Picker/metadata exception | Panel catches chooser/selected errors; discovery catches metadata errors and returns unreadable without raw error text | Show only enum-derived failure, never raw exception/path diagnostics. Re-entry/another deliberate selection is a read, not installation repair or automatic mutation retry |
| Busy changes during metadata IO | Busy prevents another chooser start; it is not part of `_current` | A same-generation result may still update metadata during explicit connection. This cannot authenticate or retarget the connection: panel owns no channel/store and passes no selected folder into its child form |

`_picking` prevents duplicate choices only within the current panel state. It is
reset on enabled changes, and a replacement panel has fresh state. This is **not**
a process-wide single-flight guarantee: old OS work may coexist with a new entry.
No claim that one native dialog globally exists, or that all outstanding reads
are drained on exit, follows from the current tests.

## Slow IO, output bounds and unknown outcomes

- **Latency/resource proof missing:** no timer, deadline, cancellation handle,
  worker isolation, drain acknowledgment or global concurrency budget exists at
  this seam. A non-settling default can leave inspecting visible indefinitely;
  a non-settling selected inspection keeps Choose disabled for that panel's
  lifetime. The child direct form is not gated on discovery completion, but real
  OS dialog modality, UI responsiveness and exit latency were not exercised.
- **Output proof missing:** the 4096-character/C0/DEL check applies to selected
  input, not the resolved path. The returned canonical path has no explicit size
  or character revalidation before local `Text`. Raw *exceptions* are suppressed;
  a successful private path is intentionally visible locally. Do not call all
  output redacted, sanitized or bounded. No path may be serialized to requests,
  preferences, logs or diagnostics; the reviewed panel has no such sink.
- **Filesystem uncertainty:** resolve then stat can race rename, deletion,
  permission change or symlink retarget. A directory result is a point-in-time
  observation, never a directory grant, durable handle, Project, selected runtime
  or binding to the Agent endpoint. No later operation may trust it as authority.
- **Pending/abandoned read:** while pending, no status is known. After exit, the
  result is inadmissible even if IO succeeds; current result types have no timeout,
  cancelled or unknown status. Do not invent a receipt or relabel silence as
  absent/success. There is no submitted Agent mutation to reconcile or roll back
  in this metadata operation. No filesystem snapshot or OS rollback is promised.
- **Different unknown outcome:** if the user separately submits Send, approval,
  Stop, a save or administration, metadata completion/cancel proves nothing about
  it. [API/state](../adr/api-and-state.md#decision) requires authoritative recovery
  for unknown submissions and forbids alternate-transport or implicit replay;
  [client transport qualification](../adr/client.md#transport-qualification)
  separates local teardown, Stop request and authoritative terminal outcome.
  Those contracts and their existing gates are not changed or newly qualified.

A future bounded implementation must separately specify and verify deadline,
late-completion rejection, actual cancellation capability (or explicitly limited
abandonment), canonical-output bounds and outstanding-work/resource behavior.
A timeout wrapper alone cannot prove a blocked OS call stopped. No new numeric
limit, helper protocol or process authority is invented by this review.

## Receipts and reference guarantees that do not transfer

The sanitized [direct Local enrollment receipt](local-setup-enrollment-native.md#implemented-behavior-and-scope)
records GTK journeys over production metadata/store paths with synthetic Agent
HTTP and secure storage; chooser cancel/selection are provider overrides, **not**
an actual OS chooser. Its [qualification ceiling](local-setup-enrollment-native.md#qualification-and-delivery-boundary)
explicitly excludes real chooser, keychain and Agent authentication. It does not
prove today's candidate or slow/cancelled filesystem behavior. Only the committed
receipt was inspected; ignored archives/screenshots were not retrieved or rerun.

The [historical setup-recovery receipt](local-setup-recovery.md#change-and-authority)
describes a retired typed host setup/controller, Stop and disposal cancellation.
It is not the metadata operation and its old separate-Desktop parity citation is
[withdrawn](official-desktop-reference.md#withdrawn-evidence). Its cancellation,
process cleanup or helper bounds cannot be inherited. No setup is offered here.

D `apps/desktop/electron/local-backend-lifecycle.ts:5-17,44-117` tracks starts and
owned children, aborts on shutdown, fences spawn and bounds teardown waiting
(default 7000 ms). Nearest `local-backend-lifecycle.test.ts:23-89,151-181` in the
same directory covers late-spawn refusal, pre-claim child ownership and bounded
waiting with fake timers, plus a child-process case. These tests were inspected,
not run. A wait ending at a deadline is not proof every task/child completed;
Desktop's process ownership is not Wing filesystem cancellation or authorization
to copy its launcher. No Agent handler is involved in the first metadata read.

## Disable, replacement and removal criteria

Apply the reviewed plan's removal rules within the living ADRs, without expanding
privilege to compensate for missing proof:

1. **Disable the affected metadata affordance if its boundary fails:** content or
   credential access, path persistence/transmission, treating discovery as runtime
   readiness, unauthorized path ingress, or a containment/availability defect
   that cannot be safely bounded. Fail closed on unsupported platforms. Missing
   proof must remain explicit; this review alone neither implements a fix nor
   orders removal of the existing narrow UI.
2. **Remove narrowly:** default discovery/chooser/path display and their ephemeral
   state may be removed without altering the direct authenticated connection form,
   saved endpoint/profile/session identities, secure credentials or inert legacy
   records. Stop admitting outstanding results; do not claim removal kills OS
   work. Never delete the chosen directory, Agent state or secure slots, stop a
   personal service, or migrate a folder into a Project as "cleanup".
3. **Do not replace reads with privilege:** a hung/missing home, failed chooser or
   unavailable output bound does not admit shell probes, arbitrary executable/
   arguments/config paths, file-content scans, a broker or bootstrap. The
   [Agent immutability boundary](../adr/runtime-and-delivery.md#hard-boundary-never-modify-hermes-agent)
   still prohibits patches to any installed/reference/copied Agent.
4. **Replacement needs new proof:** supersede manual metadata guidance only after
   an exact authoritative unmodified Agent contract and separately reviewed Wing
   operation are qualified. Name identity/authentication, fixed shapes/bounds,
   consent, cancellation/unknown-outcome recovery and preservation/removal tests.
   Disable that operation on contract/auth/identity drift; never downgrade auth or
   replay writes through another surface. There is no shipped helper here to
   uninstall and no Agent transaction to undo.

## Validation and remaining qualification

Documentation-only offline gate: verify source revision/blob stability, all changed
local Markdown links/anchors and cited line ranges, independent contract/security
review, and scoped whitespace. No tests added or executed, SDK/package installs,
Agent calls, credential acquisition, native chooser invocation or live actions.
The full Flutter/browser/release gate is not runtime evidence for this read-only
review and is outside its relevant documentation checks.

Independent fresh-context `reviewer` run
`32f9d3ef-18d7-465c-9b82-6af4a4742fec` returned **APPROVE — DOCS ONLY**, with no
Critical, Important or Minor findings. It verified the contract/security claims,
links, cited source/tests and non-transferable reference/receipt guarantees.
It did not independently attest historical worker/process ownership. This is a
subagent review, not a human security audit or native/live acceptance.
Reviewed new-page SHA-256 before this closeout bookkeeping:
`5aac404e524b2e12d9b7a2fe1e1727f370281e116adbf8a932382c9a38097def`;
predecessor page with cross-link:
`6c37568e31573addfaf5dd0a3b437f3e4987a1365fdc273ebe267c1dce55fb97`.
Only review/check bookkeeping followed that review.

Final offline commands:

- `python3 "$TMPDIR/verify_native_failure_review.py"`: pass; revision/Desktop
  tree pins, ten unchanged Wing source/test blobs, two unchanged reference blobs,
  21 local Markdown links/anchors, 18 source/test line ranges and exactly the two
  owned documentation changes verified. This temporary checker is not shipped.
- `git diff --check` and `git diff --cached --check`: pass for the final candidate,
  including the new page in the staged check.
- `git show --format= --check HEAD`: pass on the single local task commit.

Coordinator integration and remote publication are separate; neither is performed
by this worker.

Platforms exercised: none at runtime; Linux-hosted source inspection only.
Remaining live proof is the actual Linux chooser's cancel/exit behavior, delayed/
failed filesystem responsiveness and outstanding-work behavior on an isolated
named target. Other platforms, OS keyring, Agent auth/capabilities, process death/
cleanup and any future privileged operation need their own scoped receipts; none
is activated by preparation. NATIVE-INTEGRATION remains unqualified.

Update this receipt if the platform interface, IO strategy, panel generation/busy
logic, caller lifecycle, path sinks, reference lifecycle or living decisions change.
