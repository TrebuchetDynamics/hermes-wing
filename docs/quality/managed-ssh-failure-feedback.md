# Managed SSH failure feedback — WING-001-b3

Status: offline feedback repair verified on baseline
`83fcbc032a7c871c17258d8b46a58a18bd4fea04`. The runtime changes and regressions
already arrived through `414f5b49`; this closeout updates their evidence, without
reimporting patches or duplicating implementation. Integration acceptance remains
with the runner. The reported installed-phone failure is not reproduced.

## Implemented behavior

The accepted [plan](../plans/2026-10-18-ssh-failure-feedback.md) identifies a source
mechanism: Agent bootstrap publishes a typed failure, but unsuccessful SSH
adoption clears channel state during teardown. The
[controller](../../lib/features/hermes_chat/providers/managed_ssh_connection_controller.dart)
captures only an allowlisted category, joins owned cleanup and reports it to the
still-current [localized panel](../../lib/features/hermes_chat/widgets/managed_ssh_connection_panel.dart).
Cancellation, stale ownership and no acquisition remain distinct from an active
attempt's genuine failure.

SSH authentication/trust/timeout and Agent authentication/incompatible/unavailable
surface failures retain separate explanations. Recovery load/save and channel
preflight storage rejection are classified at those producing operations, never
by parsing exception text. The
[channel intent guard](../../lib/core/hermes/channel/hermes_api_channel.dart)
fences old feedback across replacement preflight and connect/disconnect
roundtrips, including a return to identical disconnected state.

The existing [form](../../lib/features/hermes_chat/widgets/managed_ssh_connection_form.dart)
reveals its persistent summary/live region and Connect action through enclosing
scroll views without animation or focus theft. Long explanations reveal their
start and remain scrollable to retry. Attempt credentials/key selection clear;
non-secret target fields remain. Retry requires fresh authentication after owned
cleanup settles. No automatic retry, protocol probing, remote service management,
trust-policy change or Agent mutation is introduced.

## Observable regression evidence

The existing [production-composition cases](../../test/features/hermes_chat/widgets/managed_ssh_connection_panel_test.dart)
exercise API 401/403 and incompatible bootstrap responses after held cleanup.
At **320×480 / 200% text / simulated 80px inset**, the user scrolls up while
pending; actual summary and Connect bounds, hit testing and live-region semantics
are asserted without a test-side reveal after failure. Fresh-auth keyboard retry
is submitted at that size, once. The resulting full Chat is rendered separately
at 800×1200 and reaches exact profile/session/history once.

[Explicit serve fixtures](../../test/features/hermes_chat/providers/managed_ssh_serve_reads_test.dart)
exercise real HTTP 401/403/404 category preservation without fallback or mutation.
The panel/provider regressions also cover storage denial, SSH authentication and
timeout, unknown failure, pending tunnel loss, cancellation and replacement.
[Form tests](../../test/features/hermes_chat/widgets/managed_ssh_connection_form_test.dart)
prove that long feedback is revealed and retry remains reachable by ordinary
scrolling. Changed/denied host keys still fail closed. Fixtures are not native
SSH, secure-storage or screen-reader qualification.

## Fresh checks on this baseline

- Listed SSH/form/provider/entry/core checks: **163 passed, 9 opt-in skips**.
- Broader named Chat/router/channel checks: **2,613 passed**.
- Format verification: **624 files**, zero changes. Analysis found no issues;
  npm audit found zero vulnerabilities. Diff and changed local links passed.
- Fresh deterministic web build followed by all nine default browser specs:
  **89 passed, 1 opt-in live skip**, zero unexpected or flaky results.

Six cases initially encountered occupied fixture ports. Each passed its one
isolated rerun on unused ports within the assigned range; the complete listed
SSH command then passed on that subrange. No listener was stopped and no test
assertion, fixture or runtime source was changed. Those transient test IDs remain
in the worker report's `unrelated_failures`, not as task blockers.

The worker did **not** run the full test check: the runner owns that check on the
merged tree before review, and its result is the acceptance gate. Named suites
above are scoped evidence, not a substitute or a claimed whole-suite pass.
Earlier recovery counts, timeouts and held-source/browser findings remain in
this file's history; they are not current results or new source prerequisites.

## Still unverified

Fixing feedback does not establish target connectivity. The reported phone/APK,
native SSH authentication and host trust, platform secure storage, actual
IME/TalkBack and live Agent reachability remain unverified under
**BACKEND-SSH-CONNECT-LIVE** and **BACKEND-SSH-KEY-NATIVE-LIVE**. Executed checks were
Linux-hosted deterministic widgets/platform overrides and Chromium. No live
credentials, provider spending, service restart, push or deployment was attempted.
