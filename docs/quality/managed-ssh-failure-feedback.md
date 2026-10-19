# Managed SSH failure feedback — WING-001-b3

Status: recovered offline candidate; required whole-train validation remains held.
This is not integration, native qualification or proof that the reported phone
connects to its target.

## Retained repair

The accepted [plan](../plans/2026-10-18-ssh-failure-feedback.md) traces a source
mechanism: Agent bootstrap publishes `connectionFailureKind`, but unsuccessful
SSH adoption tears down that state before presenting a generic result. The
controller captures only the safe category before joined cleanup and delivers it
to the still-current localized panel. Cancellation, stale ownership and no
acquisition remain distinct from actual failures.

SSH authentication/trust/timeout retain separate typed explanations. Recovery
load/save and channel-preflight storage rejection are classified at those
operations, never by exception-text parsing. A captured channel-intent guard
rejects obsolete feedback across replacement preflight and connect/disconnect
roundtrips, including return to an identical disconnected state.

The existing summary/live region and Connect action reveal through enclosing
scroll views without animation or focus theft. Long explanations reveal their
start and remain scrollable to retry. Attempt credentials/key selection clear;
non-secret target fields remain. No protocol probing, automatic retry, remote
service management, trust-policy change or Agent mutation is added.

## Source-bound evidence

The retained attempt on `36f4155f87e4c6ddaa1123a1c9baba0989081663` recorded 169
focused passes and 9 opt-in skips. Its production-channel fixtures cover API
401/403/incompatible bootstrap feedback after held cleanup, actual Chat entry at
320×480 / 200% text with an 80px simulated inset, summary/Connect viewport bounds,
hit testing, live-region semantics and a deliberate fresh-auth keyboard retry.
The resulting full Chat is rendered separately at 800×1200. Real HTTP serve
fixtures cover 401/403/404 without fallback or mutation. Storage, unknown failure,
pending tunnel loss, cancellation and replacement regressions remain retained.
These are historical Linux-hosted deterministic checks, not fresh acceptance on
coordinator-combined source.

Independent review of that attempt identified preflight-storage feedback and
post-cleanup intent-fencing gaps. Both were reproduced RED and repaired, with
focused regressions passing. The retained full test command did not finish:
2,975 passes and 54 failures were interim counts before timeout, not terminal
suite totals. No successful full gate or browser build was supplied by that run.

## Fresh recovery checks on `3dfdba5f` plus this candidate

- The retained focused SSH/form/entry command passed **169 tests**, with **9
  opt-in skips**. `flutter test --no-pub --concurrency=1
  test/core/hermes/channel/` additionally passed **593 tests**.
- `flutter gen-l10n`, whole-source format verification, `flutter analyze --no-pub`,
  `npm audit` (zero vulnerabilities) and `git diff --check` passed.
- `flutter build web --release -t lib/main_e2e.dart` completed. Its dependency
  WebAssembly dry-run/font warnings do not establish WebAssembly or native support.
- Fresh `npm run web:e2e` rebuilt the deterministic target and stopped in its first
  default spec: **11 passed, 1 failed**. The failing case is **Tools inventory
  supports search and resolved-tool disclosure**, waiting for the **Default Tools**
  button. Later default specs did not run. This is not a green browser gate.
- The required full test command was not repeated on the unchanged failed
  runtime/test baseline. Its mandatory terminal result remains unavailable until
  the coordinator supplies the combined source below. No failure is waived.

These passes are tied only to this recovered candidate, not the reviewed tab
candidate or a canonical combined train.

## Recovery and held train input

The [recovery handoff](../tasks/held-offline-recovery.md#recovery-sequence) assigns
combined-source assembly to the existing coordinator. The resumed worker
recovered its own idle candidate rather than recreating regressions or importing
another task's changes. The assigned `3dfdba5f` baseline does not contain the
reviewed tab repair `3b7871db`; its runtime/test input is unchanged from the old
SSH attempt's baseline. The retained layout/gateway test prerequisite repairs
remain in this candidate for coordinator reconciliation, not duplicate ownership.

The MCP plan's apparent missing-task failure is the accepted hash-ID parser
defect owned by **PLANGAP-001-2f**. Its plan map and archived task body already
exist. No task-ID, disposition, coordinator-owned queue edit or product decision
is required from this SSH worker. Parser and Chat repairs must be combined before
whole-repository gates are repeated. Inventory-keyboard/footer failures retain
their existing owners. Do not waive failing checks or repin historical receipts.

## Unverified live tail

The installed APK and reported phone failure remain unreproduced. Native SSH,
platform secure storage, actual IME/TalkBack and live Agent reachability remain
with **BACKEND-SSH-CONNECT-LIVE** and **BACKEND-SSH-KEY-NATIVE-LIVE**. Linux widget
fixtures and Android platform overrides are not device evidence. No live
credentials, provider spending, service restart, push or deployment was attempted.
