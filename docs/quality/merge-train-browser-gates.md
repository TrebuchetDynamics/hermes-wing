# Canonical train: compiled browser gate receipt

Task: `MT-VERIFY-BROWSER-GATES`. **Fresh deterministic build and canonical
browser suite passed on the repaired combined source: 89 passed, 1 live-only
skip, 0 failed, 0 flaky, no retries.** Executed on 2026-10-19 UTC.

This is the browser phase following the [non-browser receipt](merge-train-canonical-rerun.md),
not qualification of the old historical candidate. It addresses the fresh-browser
portion of the [remaining gates](merge-train-shell-status-bar.md#remaining-gates).
Coordinator integration, live acceptance and publication are not implied.

## Frozen source and compiled identity

- Clean assigned branch `autowork/MT-VERIFY-BROWSER-GATES` at input commit
  `d121bffb24fcd0c6bc621007910332eb5c1624a9`, tree
  `773541b6605f388c0494acfd90ef7f5714c12b9e`.
- The **737-file runtime/test/browser/dependency closure** is
  `4c9f0dfb99ce972ce4e1f93ffd006eb96cca774ade9bce976da118fd17c75846`:
  identical to repaired train tree `9f02da853b3e63732c50d26140b7247896e67f9c`.
  Canonicalization matches that receipt: SHA-256 of ordered
  `path + NUL + Git blob ID + newline` from `git ls-tree -r`, under `lib`,
  `test`, `integration_test`, `playwright`, `pubspec.yaml`, `pubspec.lock`,
  `package.json`, and `package-lock.json`.
- All **1,532 tracked input file hashes** remained unchanged through build,
  browser, analyzer and full-suite attempt. Only this receipt and its crosslink
  were added later; no implementation, tests, assertions, dependencies or runner
  were changed.
- Compiled `build/web/main.dart.js` SHA-256:
  `44e0a7c71c3825b4c1e9e7ce1ea5a3ecf4c88e388833bd04679f4514e6881a6a`.
  Both the standalone build and canonical runner's mandatory fresh rebuild
  produced this value. The only differing built file was generated
  `flutter_bootstrap.js`; both complete asset manifests are retained.
- Served-build asset manifest SHA-256 (`build-after-browser.json`):
  `24d6f716b75d054dfdb25b0cec8a71889aa94e8ed0568f84c0f360b8c8d174d2`.

Linux host; Flutter 3.44.2 / Dart 3.12.2, Node 22.22.2 / npm 10.9.7,
Playwright 1.62.1, system Chromium 152.0.7977.75 (headless).
Dependencies prepared with `npm ci` and
`flutter pub get --offline --enforce-lockfile`, both exit 0; locks unchanged.
Versioned repository caches were reused. Browser environment:
`PORT=20200 HERMES_E2E_PORT=20201 CHROME_EXECUTABLE=/usr/bin/chromium`.
Live `WING_*` opt-ins were absent. Only assigned loopback ports were used;
the canonical runner stopped its own fixture server afterward.

## Completed browser gates

| Command | Exit | Terminal result |
| --- | ---: | --- |
| `timeout 1770 flutter build web --release -t lib/main_e2e.dart` | 0 | Built `build/web`; 110.56 seconds including dependency resolution. |
| `timeout 1770 npm run web:e2e` | 0 | Runner rebuilt the deterministic entrypoint, then completed all nine canonical spec processes in 946.92 seconds. |
| `git diff --check` | 0 | Receipt whitespace clean. |

The build reports existing `flutter_tts` WebAssembly dry-run interop findings
and a missing Cupertino font-family warning. The JavaScript release build
succeeded; this is not WebAssembly qualification.

[Canonical runner](../../playwright/scripts/run_tests.sh) and
[configuration](../../playwright.config.mjs) were used unchanged. Each JSON result
was archived before the next spec overwrote `playwright/results.json`; all tests
have exactly one result with retry index zero.

| Canonical spec (under `playwright/tests/`) | Passed | Skipped |
| --- | ---: | ---: |
| `regression/browser-surfaces.spec.mjs` | 12 | 0 |
| `regression/chat-workspace-overlay.spec.mjs` | 42 | 0 |
| `regression/browser-cors-streams.spec.mjs` | 2 | 0 |
| `regression/chat-approval-confirmations.spec.mjs` | 1 | 0 |
| `regression/chat-tts.spec.mjs` | 20 | 0 |
| `regression/hermes-lifecycle.spec.mjs` | 2 | 0 |
| `regression/hermes-live-say-hi.spec.mjs` | 0 | 1 |
| `regression/hermes-smoke.spec.mjs` | 8 | 0 |
| `screenshots/e2e-screenshots.spec.mjs` | 2 | 0 |

The skip is the explicit live-Agent say-hi opt-in, not a waived deterministic
failure. Browser surfaces, Tools search/disclosure, overlay ownership/history,
keyboard/focus restoration, SSE, scoped approval cancellation, speech fixture
workflows and screenshot journeys all completed. These are fixture/browser
outcomes, not official Desktop parity or native/acoustic claims.

## Exact mutation / no-incidental-mutation assertions

The 42 passing [overlay cases](../../playwright/tests/regression/chat-workspace-overlay.spec.mjs)
run at **390 and 1280 CSS pixels, each at 200% text**. Their strict array equality
assertions (lines 164, 251, 393, 452, 484, 534, 616 and 639) establish:

| Exact browser API-write sequence per case | Cases |
| --- | ---: |
| `[]` | 26 |
| `[POST /v1/runs]` | 8 |
| `[POST /api/sessions]` | 4 |
| `[POST /v1/runs, POST /api/sessions]` | 4 |

Thus these cases assert exactly **12 run submissions and 8 session creations**
in aggregate, with no additional matching writes. Idle profile/host switches,
Settings/Profiles keyboard and slash entry, Manage profiles, Back/Forward,
Escape/Close and disconnected deep-link recovery produce no incidental writes.
Active-run cases permit only the deliberate original submission; session
replacement additionally permits exactly one deliberate creation. Late old-run
completion must not replace the new owner or replay a submission.

Counting boundary: the tests observe page-originated non-GET requests under
`/api/` and `/v1/`; host-replacement cases also exclude CORS `OPTIONS`.
Test-runner `/e2e/hermes/*` reset/completion controls and read reconciliation
are not Agent mutations. Counts are established by the passing existing exact
assertions, not by a newly instrumented global request trace. Per-test titles,
source lines, expected exact sequences and terminal statuses are retained in
`mutation-counts.json`.

Additional passing exact assertions: [Office recovery](../../playwright/tests/regression/browser-surfaces.spec.mjs)
lines 64–77 requires no observed non-GET request during recovery;
[scoped approvals](../../playwright/tests/regression/chat-approval-confirmations.spec.mjs)
lines 64–66 and 96–100 require `[]` after initial cancellation and exactly
`["session", "always"]` after explicit confirmations. The lifecycle Stop case
checks an increased stop count plus authoritative `cancelled` status, **not an
exact Stop request cardinality**. No stronger universal exact-count claim is made.

## Additional offline gate and limitations

The [required offline commands](../../CONTRIBUTING.md#required-checks) were
attempted once on this unchanged source, reusing the completed browser gates:

| Command | Exit | Outcome |
| --- | ---: | --- |
| `dart format --output=none --set-exit-if-changed lib test integration_test` | 0 | 619 files; zero changes. |
| `flutter analyze` | 0 | No issues found. |
| `timeout 1770 flutter test --concurrency=1` | 124 | Environment time limit; last progress `+3095`, no completed full-suite result. |
| `npm audit` | 0 | Zero vulnerabilities. |

The full Flutter attempt reached `test/router/office_route_test.dart` when the
time limit terminated it; SIGTERM/finalization errors follow the timeout.
This is retained as an **environment failure**, not a test regression or a
full-suite pass. The earlier repaired-source non-browser receipt remains
separately source-bound; this run does not invent a new completed Flutter count.
No browser failure was hidden, waived or classified as unrelated.

## Retained evidence and handoff

Task-private `$TMPDIR/browser-gates/` retains full `.log`/`.exit` pairs, exact
command/time metadata, source-before/after manifests, both build asset manifests,
all nine browser JSON results, `browser-summary.json` and `mutation-counts.json`.
The worker report records the exact scratch location and local commit. Hashes:

| Artifact | SHA-256 |
| --- | --- |
| `build.log` | `1235e9091938fd35a1378693e3550bc103426ec101ac466a13109cdf26c481db` |
| `browser.log` | `383d8d329a47847823ec0f14d0c2511936cfba9d2df06e80a7786895af762a06` |
| `browser-summary.json` | `dc59bcab6bc69d958e026daffbe36bfd11d280455802b2a664cfb142cc01be75` |
| `mutation-counts.json` | `12f61184710ef3f6892bd8ac4215c58e91506da27e7a6d719c6293e626476c7e` |
| `full-tests.log` | `b23b63fb7029be1b37ddf97dc46ae52377e5e15ac4c12f3bb9077fdace661446` |

Fresh-context read-only review independently verified source/build identity,
all JSON outcomes, mutation accounting, published hashes and local links; no
important/critical findings. Its one citation correction was checked against
source and applied. Review retained as `review.md`, SHA-256
`26f9cef8839138b04bb8d6b00f27d8a26f79836c60aa969850e97dab0369ef03`.

Scratch logs are local diagnostic evidence, not shipped artifacts. Any change to
the captured runtime/browser inputs invalidates affected gates and requires a
fresh build and rerun. Only Linux-host headless Chromium and offline Flutter
checks were exercised. Physical Android, native desktop UI, live Agent/provider,
microphone/acoustics, installation/signing/update and human platform acceptance
remain separate live/platform work. No live backend, upstream edit, integration,
push or publication occurred.
