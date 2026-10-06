# Persona editor ownership

Status: ownership repair `t_294eb674` independently accepted through executor78 →
tester79 → reviewer80. Document fidelity follow-up `t_5881bb6b` is executor-verified
and awaits independent same-card tester → reviewer acceptance. These are bounded
M3/M4 reliability slices, not live Agent/provider or native-device qualification.

## Behavior

The [Persona route](../product/routes.md) and Profiles modal reuse the same
`ProfileEditorSheet`. Its volatile draft, SOUL revision, read generation,
loading/error state and explicit save belong to the current channel instance,
Agent origin, selected profile, edited profile and eligible connection/authority.
Opaque object tokens fence completions; origins and credentials are not UI keys.

Synchronous listeners observe owner loss even when host/profile selection,
disconnect/reconnect or authority loss/restoration happens before the next frame.
Replacement discards the local draft/revision and loads the eligible owner's
SOUL once. Ordinary same-owner notifications and profile-row revision changes do
not reload or erase a draft. The Profiles modal additionally becomes ineligible
when its captured management source changes; changing back does not revive that
old modal. Cancel and reopening provide the current-source editor.

Read and write require supported explicit profile-query context, the exact
advertised `GET` and `PUT /api/profiles/{name}/soul` operations, their base grants
and every additional declared scope. Profile selection in progress is ineligible.
Existing disconnected, profile-needed and unsupported route states remain.
Unsupported editing makes zero SOUL reads/writes.

Save captures channel, profile, draft bytes and SOUL revision before awaiting
anything. A synchronous guard admits one write even with double activation.
Owner changes fence late success, failure, cleanup, conflict reload and route
closure. A conflict rereads only its still-current owner; no automatic mutation
replay occurs. Read failure clears writable revision/content and offers explicit
Retry. Errors use localized bounded copy, not raw server messages. Save retains
its semantic label and disabled button identity while pending. No new persisted
SOUL copy, Wing Link persona operation or generic ownership framework is added.

An already-submitted write can finish at its original Agent after local ownership
is lost. Local fencing is not server cancellation, rollback or proof of failure.
The existing profile create/rename/delete/setup/catalog/approval flows remain
shared; Wing Link continues to own only reviewed host-management compatibility.

## Standalone completion and keyboard-only editing

Status: `t_d393d318` executor-verified; a fresh independent default run on the
same card must approve it. Historical multi-profile review routing is not a
dependency for this slice. This does not finish full live qualification.

Standalone `/soul` **Cancel** discards the volatile editor and lands on
`/profiles`. Successful **Save**, including unchanged-document completion with
zero PUTs, has the same landing. Read/write failures and revision conflicts
remain in the editor. Shared optional completion/cancel callbacks leave the
Profiles modal's existing dismissal and setup/catalog/approval behavior intact.
The standalone route also checks that its page is still current: shell pages
remain mounted during the 200ms exit transition, so a late success must not
replace a destination already chosen. The pending Persona Save retains a named
disabled button; its decorative spinner no longer supplies a loadingSpinner role.

Regression-first actual-router tests reproduced non-poppable Cancel and changed
Save at both widths, the exit-transition redirect race, and the pending Save
role loss. The real `HermesApiChannel`/`HermesApiClient`, directory and router
matrix now passes 26 cases at 390/1280px, height 1400px, with 200% text and reduced
motion. It covers cancel/reopen, unchanged/changed save, synchronous duplicate
activation, pending-read disposal, rejected-write explicit retry, 412 reread,
late old-owner success/failure/conflict and actual Profiles modal dismissal.
The broader affected run passes 1943 unique tests/1943 executions/zero skips;
only 111 hidden infrastructure cases are excluded, not real loading-named tests.
Focused cases overlap that run and are not added to its total. Nonwriting format
and `flutter analyze --no-pub` pass on locked Flutter 3.44.2/Dart 3.12.2.

Fresh JS-release Chromium passes all 54 mandated journeys, workers=1/retries=0/
zero skips. Twelve new Persona journeys at 390/1280px, height 1400px, use only
Tab/Shift+Tab/Enter/Space plus ordinary text-selection/typing keys after permitted
connection, profile-inventory, semantics and reduced-motion bootstrap. They enter
and reopen through real shell controls, never clicks, field fills/focus, DOM
actions or hash navigation. On compact layouts More uses an imperative route
push, whose URL does not reflect `/soul`; the visible heading/editor proves entry
and their removal plus Profiles proves completion. The wide rail additionally
checks the `/soul` URL. Named Chat controls are focus-only, never activated.

Each journey covers field escape/backward return, Cancel/Save, and Retry when
read failure applies. Controlled pending PUT traversal and disabled activation
make no duplicates. Cancel/unchanged Save make zero PUTs; write failure retains
the exact draft until deliberate retry; 412 rereads padded authoritative newer
text before explicit re-edit/save with its newer revision. Existing production
profile mutations refresh the host-scoped profile collection after success/412;
receipts assert those exact reads too, not an invented zero-read contract.
Every request records origin/path/query/method/If-Match/body and every response
has bounded complete JSON/UTF-8 readback. Padded multiline LF and Unicode bytes,
including combining characters, survive persistence and keyboard reopen. Exact
Chat profile/session/provider/model/status is unchanged; null provider/model are
actual fixture readbacks, not model qualification. No other mutation occurs.

The source-bound evidence includes 38 PNG pairs decoded into RGB pixel counts,
coordinates and focused/unfocused colors for field, Cancel, Save and applicable
Retry. Field outer-edge changes prove more than a blinking caret or unequal PNG
files. The focus observer only recognizes the native textarea's implicit textbox
role; it does not move focus. Original ownership/fidelity/browser assertions and
default fixture capabilities are unchanged.

Reproduce using the locked SDK and qualified Chromium executable, an owned
fixture (`PORT=8995 HERMES_E2E_PORT=8996 node serve_web.mjs`), `WING_APP_URL` and
`CHROME_EXECUTABLE`:

```bash
flutter test --no-pub test/features/soul/persona_route_completion_test.dart \
  --concurrency=1 --reporter json
dart format --output=none --set-exit-if-changed \
  lib/features/profiles/widgets/profile_editor_sheet.dart \
  lib/features/soul/screens/soul_screen.dart \
  test/features/soul/persona_route_completion_test.dart
flutter analyze --no-pub
flutter test --no-pub test/core/hermes test/features/profiles test/features/soul \
  test/features/gateway test/features/hermes_chat test/features/providers \
  test/features/tools test/features/schedules test/shared/widgets test/router \
  --concurrency=1 --reporter json
flutter build web --release --no-pub -t lib/main_e2e.dart
node --check playwright/tests/regression/persona-keyboard.spec.mjs
node --check playwright/support/inventory_keyboard.mjs
npx playwright test playwright/tests/regression/persona-keyboard.spec.mjs \
  playwright/tests/regression/persona-ownership.spec.mjs \
  playwright/tests/regression/profile-keyboard.spec.mjs \
  playwright/tests/regression/profile-search.spec.mjs \
  playwright/tests/regression/connections-keyboard.spec.mjs \
  playwright/tests/regression/connections-health.spec.mjs \
  playwright/tests/regression/provider-keyboard.spec.mjs \
  playwright/tests/regression/inventory-keyboard.spec.mjs \
  playwright/tests/regression/browser-surfaces.spec.mjs \
  --retries=0 --workers=1
git diff --check
```

Durable ignored evidence is under `.dart_tool/kanban-evidence/t_d393d318/`:
task-only baseline diff, inherited/source/build hashes, red/green commands/exits,
case identities, sanitized complete receipts, keyboard traces and decoded RGB.
The runtime is Node 26.5.1 rather than intended 22; no upgrade was performed.
Existing flutter_tts Wasm dry-run/Cupertino-font warnings remain. Qualification
is deterministic Linux Flutter widgets and compiled Chromium at the named sizes,
not arbitrary height, browser 200% text, CRLF browser input, native desktop,
Android, real screen readers, actual Agent/provider, Wasm, distribution, full
repository gate or a completed milestone. No localization change was needed.

## Contract trace and evidence

### Exact document fidelity follow-up

`HermesProfileSoul.fromJson` now requires a literal `soul` string and preserves
it without trimming, newline conversion or Unicode normalization. Empty and
whitespace-only documents are valid and distinct from missing/null, numeric,
boolean, map/list or dashboard `content`/`exists` responses. Malformed content
throws a fixed, content-free error; the editor cannot acquire a writable revision
from that read. Metadata coercion, revision admission, response handling and exact
operation/context/all-grants gates are unchanged. A malformed successful PUT
acknowledgement reports failure, not rollback or an automatic retry.

The regression-first tests reproduced actual model/client/editor loss of spaces,
tabs, blank lines, padded Unicode and CRLF, and malformed content admission. An
empty input remains empty; the padded PUT acknowledgement also proves decoding is
not merely echoing the submitted draft. Production channel/client widgets cover
no-edit activation with zero writes, explicit whitespace-only/clear-to-empty
saves, fresh reload and padded revision-conflict reread/explicit retry.

Locked Flutter 3.44.2/Dart 3.12.2 analysis, changed-Dart format and 1654 affected
tests pass (1604 inherited plus 50 fidelity tests). The existing ownership and
390/1280px 200%-text/reduced-motion keyboard/semantics checks remain included.
Fresh JS-release `main_e2e` Chromium passes 19 unique journeys, 19 executions,
retries=0. Eight Persona receipts assert padded multiline initial text, explicit
padded Unicode request JSON/UTF-8 bytes, If-Match, exact successful readback and
actual editor disposal/reload; conflict recovery preserves padded server text
and retries only explicitly. Browser inputs use LF; CRLF, whitespace-only and
empty cases are production-client/widget evidence, not browser-input claims.

Run the reproduction commands below with the changed-Dart format list extended
by `lib/core/hermes/models/hermes_profile.dart`,
`test/core/hermes/client/hermes_profile_soul_fidelity_test.dart` and
`test/features/profiles/profile_persona_fidelity_test.dart`. One browser execution
per journey is sufficient for this follow-up (`--repeat-each=1 --retries=0`).
The evidence archive retains command exits, red/green logs, exact test enumeration,
task-only baseline diff, source/build hashes and sanitized byte receipts. No ARB
or generated localization change was needed. Same-card independent acceptance and
source-bound full live revalidation remain required for this follow-up.

### Independently accepted ownership predecessor

- The inherited editor initialized SOUL once and checked only `mounted` after a
  read. The initial three regression tests reproduced missing replacement loads.
  Replaying the final replacement tests against the captured inherited baseline
  compiles and reproduces all three failures, including visible `A draft` in B.
- `SoulScreen` and the Profiles caller use the shared exact capability predicate.
  The modal supplies a captured-source admission callback and synchronous source
  notifications; its catalog callback remains bound to the captured Link client.
- Production channel SOUL methods capture the connected client and check exact
  operation/context/revision guards. The client adds explicit `profile` query
  context and sends `{soul: ...}` with `If-Match`. Three real channel/client widget
  tests exercise deferred old-host success/failure and an original-host submitted
  write across reconnect, rather than only a fake that throws.
- Upstream `hermes-agent/hermes_cli/web_routers/profiles.py` and
  `tests/hermes_cli/test_web_profile_soul_writes.py` were inspected read-only.
  That checkout's dashboard SOUL handler uses a different unscoped
  `content`/`exists` contract. It is not evidence that Wing's advertised scoped
  `soul`/`revision` adapter is available on an installed Agent. No upstream edits,
  registration/authentication synthesis or fallback contract were introduced.
- Final affected suite: 1604 unique Linux unit/widget tests pass across core
  Hermes, Profiles, Persona, Connections, Chat, Providers, Tools and Schedules.
  This includes 43 new persona ownership/client tests. Matrix coverage includes
  replacement, same-frame host/profile/selecting/connectivity/grant roundtrips,
  exact read/write operation/method/path/schema/additional scopes, ordinary
  updates, stale saves, conflict reload, management-source invalidation and
  disposal. The pending Save semantic-label regression first failed at both
  widths, then passed after the focused fix.
- Linux widgets at 390/1280px exercise 200% text and reduced motion, independent
  field/error/Retry/Save controls, actual Tab/Enter activation and no overflow.
- Fresh JS-release `main_e2e` Chromium: 19 selected unique journeys repeated three
  times, 57 executions, retries=0, all passing. Eight unique Persona journeys
  produce 24 receipts for read/edit/explicit save, read failure/retry, write
  failure/explicit retry and revision-conflict reconciliation at both widths.
  Receipts assert exact profile/path/payload/revisions and compare fixture saved
  persona/revision JSON bytes via readback. Only explicit SOUL PUTs mutate;
  no create/rename/delete/Chat/inference occurs. Connections and accepted Profiles
  search/browser-surface journeys also pass, with 18 health receipts.

## Reproduction and limits

Use the explicit locked Flutter 3.44.2 executable (Dart 3.12.2), an isolated Wing
source snapshot without reference clones, existing Node dependencies and unused
owned loopback fixture ports. These gates ran with exits 0:

```bash
dart format --output=none --set-exit-if-changed \
  lib/core/hermes/channel/hermes_channel_state.dart \
  lib/features/profiles/screens/profiles_screen.dart \
  lib/features/profiles/widgets/profile_editor_sheet.dart \
  lib/features/soul/screens/soul_screen.dart \
  test/features/profiles/profile_editor_sheet_test.dart \
  test/features/profiles/profile_persona_ownership_test.dart \
  test/features/profiles/profile_persona_client_ownership_test.dart
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 --reporter expanded \
  test/core/hermes test/features/profiles test/features/soul \
  test/features/gateway test/features/hermes_chat test/features/providers \
  test/features/tools test/features/schedules
flutter build web --release --no-pub -t lib/main_e2e.dart
node --check playwright/tests/regression/persona-ownership.spec.mjs
PORT=18767 HERMES_E2E_PORT=18768 node serve_web.mjs
# Separate terminal with WING_APP_URL and CHROME_EXECUTABLE set:
npx playwright test playwright/tests/regression/persona-ownership.spec.mjs \
  playwright/tests/regression/profile-search.spec.mjs \
  playwright/tests/regression/connections-health.spec.mjs \
  playwright/tests/regression/browser-surfaces.spec.mjs \
  --grep 'Persona|Profiles|Gateway status|Connections health' \
  --retries=0 --workers=1 --repeat-each=3
git diff --check
```

The archive records exact executable paths/commands, source/build hashes,
task-only diffs against the inherited baseline, test enumeration and sanitized
receipts. No localization changes were needed. Browser iterations corrected
Flutter semantic-group/live-announcement selectors and focused the textarea
before value assertions, without SDK/DOM patching, raised timeouts or retries.
The predecessor's inert multiline Unicode fixture had no boundary whitespace and
did not qualify document fidelity. The follow-up above replaces that fixture with
padded strings and repairs the document decoder, without changing ownership.

Actual environment: Linux widget runner, Playwright 1.61.1, Chromium 149.0.7827.55
and Node 26.5.1 (not intended Node 22). The JS build retains existing flutter_tts
Wasm dry-run and Cupertino-font warnings. Browser owner replacement is not
provisioned by this fixture; the widget matrix supplies that race proof. Browser
200% text, real screen readers, actual Agent/provider, native app/device, Wasm,
full repository gate and release support are not claimed. Full live qualification
`t_38174cb7` remains unmet and needs source-bound post-slice revalidation.

Connections predecessor acceptance is separately canonical on `t_a260473a`
(executor75 → tester76 → reviewer77); it does not approve this persona change.
No native automatic wake subscription or invented delivery destination is
claimed; the operator's existing watchdog inspects progress.
