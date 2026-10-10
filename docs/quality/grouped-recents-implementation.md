# Source-grouped loaded sidebar recents

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Card `t_8181e7ae` implements `PORT-GROUPED-RECENTS` under `PARITY-COMPOSITION`.
Implementation is executor-verified and ready for native same-card review;
review approval is not claimed. Broad composition parity remains partial.

## Delivered contract

[ShellSessionAccess](../../lib/features/hermes_chat/widgets/shell_session_access.dart)
projects the current owner's loaded sessions into insertion-ordered source groups.
Exact nonblank source strings are identities; blank/whitespace-only sources share
Unknown source. First encounter determines group order and incoming row order is
preserved within each group. Redacted display collisions do not merge groups or
change exact session IDs. No title, model, path, Project or date inference occurs.

Headings use the additive localized `shellSessionSource` string and existing
`sessionUnknownSource`. Display values reuse `wingRedactedPreview` with a 48-character
source bound and the existing 80-character row bound. Headings are semantic headers,
not additional keyboard stops. This first delivery deliberately adds no group
collapse state, persistence, refresh, cache, sorting or paging.

The existing `_identity`, synchronous generation invalidation, `_settled`, pending
single-flight guard, exact `_activate` ID checks and acknowledgement-before-navigation
are unchanged. Open and explicit New remain ordinary Flutter buttons. Sidebar
collapse and compact resize dispose the old session widget lifetime. All Agent
session/domain authority stays on the existing direct channel; Wing Link is untouched.

This is the approved intermediate source-grouping deviation, NOT Desktop
Project/workspace/folder grouping parity. Full session search, pins, paging and
management remain in Chat. The accepted reference and observable oracles are in
[grouped-recents-reference.md](grouped-recents-reference.md#bounded-port-grouped-recents-contract).
The permanent `withdrawn source citation` clone and its instructions were inspected read-only;
the completed comparison was not redone. No upstream edits were made.

## Changed-file receipt

- `lib/features/hermes_chat/widgets/shell_session_access.dart`: pure source projection
  and semantic group headings; no action/ownership contract changes.
- `test/shared/widgets/app_shell_grouped_recents_test.dart`: interleaved/blank/custom
  sources, equal titles, colliding path-redacted labels, exact whitespace-sensitive
  identities, same-owner re-projection, real Enter/Space and reverse traversal,
  captured obsolete callbacks and pending duplicate/failure/retry/compact/capability.
- `playwright/tests/regression/global-session-access.spec.mjs`: source heading,
  short-height active/nonactive exact Open, same-row rendered focus captures,
  reverse navigation and exact API assertions. Long Chat traversal is split at an
  actual Sessions control rather than changing the bounded shared keyboard helper.
- `lib/l10n/app_en.arb`, `app_localizations.dart`, `app_localizations_en.dart`: only
  the additive `shellSessionSource` key/method belongs to this card. Pre-existing
  dictation and model-authority localization changes were preserved.
- This receipt and narrow goals.py task/evidence/render updates.

`lib/shared/widgets/app_shell.dart`, its focus-traversal test and `serve_web.mjs`
were used but not edited. Other pre-existing dirty changes remain untouched.

## Executed checks

Main repository: `<repo>`.
For isolation, QA used a copy at `build/t_8181e7ae/qa` with explicit Wing source,
test, web, asset and fixture inputs; upstream clones, credentials, runtime state
and unrelated services were excluded. Node dependencies were reused via symlink.
The following commands were actually executed, all final checks exit 0:

```sh
# Main repository
flutter pub get
flutter gen-l10n
dart format lib/features/hermes_chat/widgets/shell_session_access.dart test/shared/widgets/app_shell_grouped_recents_test.dart
dart format --output=none --set-exit-if-changed lib/features/hermes_chat/widgets/shell_session_access.dart test/shared/widgets/app_shell_grouped_recents_test.dart
git diff --check

# In build/t_8181e7ae/qa
flutter pub get
flutter analyze
flutter test --no-pub --concurrency=1 test/shared/widgets/app_shell_global_session_access_test.dart test/shared/widgets/app_shell_grouped_recents_test.dart test/shared/widgets/app_shell_profile_footer_test.dart test/shared/widgets/app_shell_focus_traversal_test.dart
flutter build web --release -t lib/main_e2e.dart
# Card-owned fixture, background; health verified with curl before browser use
PORT=8879 HERMES_E2E_PORT=8880 node serve_web.mjs
curl --fail --silent --output /dev/null http://127.0.0.1:8879/
WING_APP_URL=http://127.0.0.1:8879/ CHROME_EXECUTABLE=/usr/bin/chromium npx playwright test --config=playwright.config.mjs playwright/tests/regression/global-session-access.spec.mjs --workers=1 --output=test-results/grouped-recents
```

Analyzer: no issues. Final focused suite: 72 passing tests. Final Chromium:
1 passing test, no retries, unexpected failures, skips or page errors. Web build:
fresh release JavaScript artifact passed; existing flutter_tts Wasm dry-run and
Cupertino font warnings remain, not Wasm qualification.

Two earlier browser runs failed at the keyboard helper's 32-key search bound:
first returning from Chat with forward traversal, then after explicit New with
reverse traversal. The traces showed the intended control was reachable; the
scoped test now traverses backwards and splits the longer path at Sessions.
No production or excluded shell changes were needed. A subsequent passing run
used the improved same-row focus capture; earlier fixed-crop images are superseded.

Ledger checks also executed successfully:

```sh
python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py task <repo> PORT-GROUPED-RECENTS done
# Each executed check above recorded with its exact cwd/command and pass/fail:
python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py evidence <repo> PARITY-COMPOSITION --kind executed --ref '<exact command>' --result pass
python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py render <repo>
python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py validate <repo>
```

Readback confirms `PORT-GROUPED-RECENTS` is done and `PARITY-COMPOSITION` remains
partial. Failed traversal evidence is retained alongside the final passing run;
no broader parity status was promoted.

## Acceptance mapping and retained evidence

Small evidence is retained locally under `build/t_8181e7ae/evidence/` (ignored):
`flutter-tests.log`, `playwright-results.json`, `global-session-receipt.json`,
`global-session-semantics.txt`, focused/unfocused PNG crops and `source-sha256.txt`.
The QA copy/build and its fixture are removed after recording evidence, not shared
worktree build outputs. Exact current source hashes match the tested copy for the
changed source/test/localization files and the excluded shell/fixture dependencies.

1. Projection: the authored grouping target asserts every loaded ID once, exact
   first-encounter/in-group order, blank/custom sources, equal titles, colliding
   redacted labels and same-owner append/removal/update. The authoritative list and
   active ID remain unchanged; incidental channel/directory/model/approval counters
   are zero. Missing source decoding already maps to blank in HermesSession.fromJson.
2. Exact action/recovery: grouping tests use actual Enter and Space for active and
   nonactive equal-title rows at 1280x600/2x text, plus Tab/Shift+Tab. Pending tests
   prove one request, no early navigation, explicit failure/retry and invalidated
   compact/capability late completion. The freshly rerun original global-session
   target covers owner A-B-A, endpoint, reconnect, contact/directory/channel/lifetime
   replacement, row removal, route departure, collapse/disposal, capability denial
   and explicit New. It also verifies stale errors remain silent.
3. Presentation lifetime: authored and nearest shell targets exercise focus/scroll
   and reverse traversal at short height/2x text, obsolete callbacks after
   collapse/compact return and no incidental work. Chromium exercises actual
   Tab/Shift+Tab/Enter/Space at 1280x600 and compact 390x844 then wide return.
   Same-row crops were inspected: the identical readable label is retained;
   focused fill differs visibly from the unfocused outlined/background row.
   The test checks actual named focus, viewport containment and rendered pixels.

The browser request receipt asserts each Open is exactly one
`GET /api/sessions/synthetic-global-other/messages` with `profile=default`,
`limit=500`, `offset=0`, `order=latest`; active Open does not create a replacement.
Explicit New produces exactly one profile-scoped POST with the acknowledged ID
and one exact-ID history GET. Group traversal, feature navigation, collapse,
expand and compact/wide return add zero requests. The only non-GET is that explicit
New POST; no prompt, approval or model mutation is sent. Initial connect/inventory
reads are recorded separately, not mislabeled as grouping work.

## Limits and defaults

Native desktop, Android/device, live Agent/provider, screen-reader execution,
Wasm, packaging/release/deployment: NOT_CHECKED. Browser coverage uses the existing
single-source `e2e` fixture; interleaved/custom/redaction collision coverage is in
production-shell widgets, not fabricated backend data. No full-history, Project,
workspace, pin persistence or group-disclosure support is claimed. No native/device
or personal runtime mutation was performed; no commits, staging or publication.

Questions: none. Defaults applied: source grouping only; no group disclosure,
persistence, extra requests, native/system/device actions or publication.
