# Connections health refresh ownership

Status: independently accepted on `t_a260473a` through the canonical same-card
executor75 → tester76 → reviewer77 chain after tester74 reproduced unowned
channel-published errors. This bounded Connections reliability
slice does not qualify a live Agent/provider, native app/device or full parity.

## Behavior and boundary

[Connections](../product/routes.md) exposes an explicit detailed-health read only
for its eligible connected Chat owner and the exact advertised `GET
/health/detailed` operation, supported schema/profile context and every required
grant. Profile selection in progress is ineligible. Management-host selection
alone never connects Chat; a different host cannot refresh the connected Agent.
Profiles grouped under the same host remain eligible without changing Chat.

Refresh/loading/failure/retry UI belongs to the channel and directory instances,
Agent origin/profile/connectivity, selected management host and current authorized
read. Screen-local synchronous listeners observe each transition, including
A → B → A, disconnect/reconnect or grant loss/restoration before a frame. Owner
transfer clears pending and already-shown failure state without reading anything.
A new owner can immediately start its own explicit refresh. Late old success,
failure and cleanup cannot finish or fail that newer action. Ordinary health and
still-authorized required-grant updates preserve the pending read. UI keys use
opaque objects, not endpoints or credentials.

Channel-published optional-resource errors have no management-owner provenance.
The screen adopts failures from the current connection bootstrap and its own
still-owned explicit action, never by rendering the shared error map directly.
It keeps only the last successful detailed-health display read for the same
channel/origin/profile in a weak, screen-lifetime cache, so an old loader failure
cannot erase the new owner's display or restore Retry after A → B → A. A changed
Agent identity never reuses that display read. Shared channel data/errors are
untouched, and ordinary successful same-owner updates remain visible. A current
failure notice and its disabled Retry remain visible while an explicit retry is
pending; only current success clears them.

Refresh and Retry share the same synchronous single-read guard. Pending controls
are disabled, including repeated activations before a rebuild. Basic-health
fallback, absent detailed support and failed/unavailable health retain their
existing distinct messages; raw errors are never displayed. The Refresh semantic
node retains its label, button identity and disabled state while spinning, with a
tap action only when eligible. Retry has its own node. No automatic read/replay,
Chat mutation, host lifecycle permission, Wing Link trust/revocation change or
shared channel architecture is introduced.

## Evidence and limits

- Regression-first: the initial 30-test matrix compiled on locked Flutter and
  reproduced owner leaks (29 failures; the same-owner case passed). Final 48
  ownership tests cover same-ID replacement, both old/new completion orders,
  same-frame channel/profile/host/authority roundtrips, shown failures, exact
  schema/method/path/base/additional grants, management versus Chat host, grouped
  same-host profiles, success/failure, no writes and same-owner health updates.
  Tester74 subsequently found that the original fake threw without publishing
  the error used by the production loader. Revision75 first reproduced four
  actual-loader shown/late-error leaks (five controls passed), plus a same-ID
  channel roundtrip fallback leak (one failing regression). The original matrix
  now publishes and clears detailed-health errors before completing requests.
  Twelve durable production `HermesApiChannel`/client/directory widget tests cover
  shown/late failures across management roundtrips, both newer-result orderings,
  explicit single-read retry and initial/reconnect bootstrap fallback. Additional
  tests verify directory-only replacement and same-ID channel roundtrip display.
- 885 nearby Linux unit/widget tests pass: Connections, Providers, Profiles,
  gateway directory, shared channel/API, Tools and Schedules. Existing saved-host,
  connect/disconnect, Wing Link trust and self-revocation tests are unchanged.
- Linux widgets at 390/1280px use 200% text and reduced motion: independent
  refresh/retry semantics, actual Tab/Enter activation and no overflow pass.
- A fresh JS-release `main_e2e` build passes 19 selected Chromium journeys repeated
  three times (57 executions, retries=0). Eighteen health receipts cover initial
  success/error/basic fallback and explicit delayed refresh/retry at both widths.
  Each supported journey reads health once during normal connection bootstrap,
  then exactly once per explicit action, with no duplicate pending action or
  other request. Unsupported detailed health makes zero detailed reads. Actual
  bounded response JSON is read back; Chat/profile/session/model state is
  unchanged and there are no mutations or page errors. Accepted inventory and
  existing Gateway/browser-surface cases also pass.
- Browser host transitions are not provisioned by this fixture; the mandatory
  widget owner matrix supplies that race proof. Browser 200% text, actual screen
  readers, Agent/provider/native app/device, Node 22, Wasm, full repository gate
  and release support are not claimed. `t_38174cb7` remains unmet and requires
  supported private Codex OAuth and source-bound post-slice revalidation.

Actual tools: Flutter 3.44.2 (`c9a6c48423`), Dart 3.12.2, Linux widget runner;
Playwright 1.61.1, Chromium 149.0.7827.55, Node 26.5.1 (not intended Node 22).
The JS build retains existing flutter_tts Wasm dry-run and Cupertino font warnings.
Localization copy did not change; no ARB or generated localization edit is needed.

Initial analysis caught a test-only brace/deprecated-API issue; a shell invocation
also selected the global SDK and failed a native-hook kernel version check before
tests. Final evidence uses the explicit locked executable throughout. Browser
iterations corrected fallback semantic-group selection and replaced DOM-only
focus/unscoped pending key events with actual Tab traversal and targeted disabled
health activations; no Flutter SDK/DOM patch, timeout increase or test retry was
used. Chromium also exposed the missing pending-refresh button semantics, now
fixed and covered by widget semantics assertions.

The sanitized source-bound archive contains task-only diffs against the inherited
baseline, source/build hashes, exact command/exit records, regression logs and
bounded browser receipts. Attachment readback determines download availability;
no notification destination or wake guarantee is claimed. The card was created
without a notification subscription; the operator's existing watchdog observes it.

## Reproduction

Use an isolated Wing source snapshot, the locked Flutter 3.44.2 executable,
existing installed Node dependencies and unused owned loopback fixture ports.
Do not include either upstream reference clone in validation.

```bash
dart format --output=none --set-exit-if-changed \
  lib/features/gateway/screens/gateway_screen.dart \
  test/features/gateway/gateway_health_ownership_test.dart \
  test/features/gateway/gateway_health_loader_ownership_test.dart
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 --reporter expanded \
  test/features/gateway test/features/providers test/features/profiles \
  test/features/hermes_chat/gateways test/core/hermes/channel \
  test/core/hermes/hermes_api_test.dart test/features/tools test/features/schedules
flutter build web --release --no-pub -t lib/main_e2e.dart
node --check playwright/tests/regression/connections-health.spec.mjs
PORT=8947 HERMES_E2E_PORT=8948 node serve_web.mjs
# Separate terminal, with WING_APP_URL and CHROME_EXECUTABLE set:
npx playwright test --config=playwright.config.mjs \
  playwright/tests/regression/connections-health.spec.mjs \
  playwright/tests/regression/provider-search.spec.mjs \
  playwright/tests/regression/profile-search.spec.mjs \
  playwright/tests/regression/tools-search.spec.mjs \
  playwright/tests/regression/schedule-search.spec.mjs \
  playwright/tests/regression/browser-surfaces.spec.mjs \
  --grep 'Connections health|Gateway status|Providers|Profiles|Tools|Schedules' \
  --retries=0 --repeat-each=3
git diff --check
```

## Keyboard-only compiled-browser workflows

`t_88121eee` is executor-verified, pending independent same-card tester/reviewer
acceptance. Six new JS-release Chromium journeys cover initial detailed success,
sanitized failure and unsupported exact operation at 390×1400 and 1280×1400px.
After deterministic connection/accessibility/reduced-motion bootstrap, only
Tab, Shift+Tab, Enter and Space act on the UI. Exact named focus, forward shell
escape and backward return are recorded without activating shell or host actions.
Fourteen focused/unfocused crop pairs have independently decoded RGB differences.

The new actual-client/router regression reproduced Refresh's missing focus
semantics at both widths before the production fix. The label/tap-only wrapper
discarded the IconButton's focus semantics. Refresh now merges the child's focus
with its explicit label/button/disabled state, excludes only the decorative
spinner, and keeps the tooltip outside that merge so hovering does not duplicate
the accessible name. Existing single-read and ownership guards are unchanged.
The E2E read-only state summary also exposes the actual channel status rather
than comparing two missing fields; it does not change channel state.

Supported journeys record nine complete bootstrap GET/readbacks (one detailed
read) and exactly two subsequent host-scoped `GET /health/detailed` requests with
empty query. Each deliberate action starts one controlled pending read; safe
health-only key activation and forward/backward traversal cause no duplicates.
Delayed HTTP 503 produces only sanitized current-owner fallback; explicit Space
on Retry completes HTTP 200 and clears it. Unsupported journeys record eight
bootstrap GET/readbacks, no detailed read, no workflow requests and no health
actions. Before/after Chat profile/session/provider/model/status is exactly
`default` / `e2e-hermes-session` / null / null / connected, with zero mutations
and page errors. Null assignments are fixture readback, not model qualification.

Locked format/analyze and affected Flutter checks pass: 1,223 mandated cases plus
138 gateway-directory cases, 1,361 unique executions total, zero skips. Only 65
hidden infrastructure events are excluded; a real loading-named case is retained.
All 40 required Chromium cases pass with retries=0/workers=1, including the six
new cases and unchanged Connections health tests. Focused runs overlap these
counts and are not added. Exact commands, identities, bounded responses, source
and served-JS hashes, regression failures and RGB crops are retained under
`.dart_tool/kanban-evidence/t_88121eee/`; no attachment availability is implied.

Qualification remains Linux deterministic widgets (200% text/reduced motion,
both widths, no overflow) and fresh compiled Chromium at the stated 1400px height,
not arbitrary-height, browser 200% text, native desktop, Android, actual screen
reader, real Agent/provider, Wasm, release or complete M4/M5/parity acceptance.
Node 26.5.1 differs from intended 22; no tooling upgrade was made. The private
selected-model actual-service requirement on `t_38174cb7` remains unchanged.
