# Pages candidate quality and recovery

## What this gate proves

[Pages CI](../../.github/workflows/pages.yml) builds the **production** Flutter
entrypoint, puts it under `/hermes-wing/app/`, and assembles the static landing at
`/hermes-wing/`. It runs the [browser smoke](../../playwright/tests/regression/pages-landing.spec.mjs)
before upload/deployment. It never uses the old public site as candidate evidence.
The main-only push/manual-ref guard, `github-pages` environment, pinned actions,
OIDC, concurrency cancellation and scoped app base href remain in force. There is
no PR or `pull_request_target` deployment path. Concurrency is scoped to the gated
job, so a skipped non-main dispatch cannot cancel an active main deployment.
No workflow was dispatched or
public site changed for this offline task.

Relevant landing, app, shared-image producer, package, smoke/helper and README/docs
inputs trigger the existing pipeline. Its focused source contracts preserve the
landing-led headline/user-path order, maintained setup anchors, simulated image
provenance, current approved logo and alpha policy. These reuse existing owners;
[platform evidence and limits](../getting-started.md#platform-evidence-and-limits)
remains the single user-facing support matrix.

### Candidate identity, not just a cache-busting query

`node site/pages-artifact.mjs stamp <assembled-directory> <full-git-sha>` writes a
deterministic `artifact.json` **after assembly**. It records the source revision,
byte lengths and SHA-256 digests for landing HTML/CSS, every deployed landing
asset, and app index/bootstrap/loader/main script. It is build metadata, not a
runtime API, security signature or claim of live Agent qualification. It contains
no local paths, credentials, endpoints, transcripts or timestamps.

The browser smoke requires the expected revision (CI supplies
`PAGES_EXPECTED_REVISION`; local smoke defaults to `git rev-parse HEAD`) and checks
the declared asset/entrypoint bytes. It also checks local navigation targets,
setup/proof links, images/social metadata, root layout and rendered production
welcome under the app base href. Repository documentation links/anchors are
validated against the checkout, not fetched from changing GitHub pages.

After an authorized deploy, `node site/pages-artifact.mjs verify
<local-artifact.json> <page-url>` requires the **exact local manifest bytes** and
all its declared entry/asset digests. A title match or a requested revision query
alone cannot pass. Each GET requests revalidation with the revision query, rejects
redirects/HTTP failures and times out at ten seconds. There are at most six whole
verification attempts with ten-second pauses for CDN propagation. Mixed CSS, old
HTML, missing app files and an older manifest fail closed. This verifies the
listed files, not every Flutter font/CanvasKit file, live authentication, or all
CDN/browser caches. The browser initialization check covers required runtime loads.

## Offline reproduction

Use Node 22 and the maintained Flutter toolchain. CI intentionally retains Flutter
**3.44.6**; this task's local execution uses the shared cached **3.44.2 / Dart
3.12.2**, not evidence that CI's SDK was executed. Install dependencies using the
existing `flutter pub get`, `npm ci` and Playwright Chromium setup. Do not regenerate
shared images unless their producer/UI changes; this gate does not relabel fixture
captures as live product proof.

Run from the repository root with an owned `TMPDIR`. In Autowork use only the
assigned port range and shared SDK/package caches. This is the existing workflow's
non-deploy build/assembly with scratch destinations, not an alternate site build:

```bash
flutter test --no-pub test/tooling/pages_workflow_contract_test.dart \
  test/tooling/plan_backlog_traceability_test.dart \
  test/tooling/readme_assets_contract_test.dart \
  test/tooling/wing_branding_assets_test.dart
node --test test/tooling/pages_artifact_test.mjs
(
  set -euo pipefail
  stage="$(mktemp -d "${TMPDIR:?}/wing-pages.XXXXXX")"
  trap 'kill "${server_pid:-}" 2>/dev/null || true; rm -rf "$stage"' EXIT
  pages="$stage/hermes-wing"
  mkdir -p "$pages/assets"
  flutter build web --release --base-href /hermes-wing/app/ --output "$pages/app"
  cp site/index.html site/styles.css "$pages/"
  for asset in hero.svg showcase.png showcase-mobile.png runtime-flow.svg runtime-flow-mobile.svg; do
    cp "assets/readme/$asset" "$pages/assets/"
  done
  cp site/assets/app-icon.png "$pages/assets/app-icon.png"
  node site/pages-artifact.mjs stamp "$pages" "$(git rev-parse HEAD)"
  port="${AUTOWORK_PORT_BASE:-8769}"
  python3 -m http.server "$port" --bind 127.0.0.1 --directory "$stage" &
  server_pid=$!
  for attempt in {1..30}; do
    if curl --fail --silent "http://127.0.0.1:$port/hermes-wing/" >/dev/null; then break; fi
    sleep 1
  done
  PAGES_BASE_URL="http://127.0.0.1:$port/hermes-wing/" \
    npx playwright test --config=playwright.config.mjs \
    playwright/tests/regression/pages-landing.spec.mjs --reporter=list \
    --output "${TMPDIR}/wing-pages-results"
  node site/pages-artifact.mjs verify "$pages/artifact.json" "http://127.0.0.1:$port/hermes-wing/"
)
git diff --check
```

Only the owned stage and server are removed. Test evidence remains under the
named temporary results directory until its owner removes it. Do not delete a
shared build tree, kill unrelated listeners, clean the checkout or edit deployed
branches to reproduce this check. Keep the manifest from a frozen commit; stamping
a dirty tree with its base SHA does not establish committed-source provenance.

## Accessibility and performance scope

The smoke covers named landmarks/headings/links, meaningful content alternatives,
focused theme-pair text contrast (4.5:1), skip-link and keyboard CTA/guide-link
operation at 1280/390px with JavaScript disabled, 200% text and reduced motion.
A 640×450 effective viewport checks the reflow corresponding to 200% zoom from a
1280×900 desktop viewport. It is not browser-chrome zoom execution: CSS `zoom`
was deliberately not used because it does not change media-query breakpoints.
Retained screenshots support manual compact/wide inspection; these focused checks
are not a full WCAG, gradient/image-contrast or screen-reader conformance audit.

The mobile lab check logs and saves `landing-lab.json` with browser/Node versions,
host OS/architecture/CPU model (no host identity), pixel ratio, resource URLs,
sample duration and these fixed conditions:

- Desktop headless Chromium, 390×844 CSS pixels, not physical mobile hardware.
- Fresh browser context; HTTP cache disabled and service workers bypassed.
- CDP CPU slowdown 4×, latency 150ms, download 200,000 B/s (1.6 Mb/s), upload
  93,750 B/s (0.75 Mb/s); loopback static server, not public network delivery.
- Initial navigation only, no scroll/input, observed through network idle plus a
  one-second post-load window. Largest-contentful-paint ≤2,500ms, initial cumulative
  layout shifts ≤0.1, total decoded navigation/resource bytes ≤350,000. The initial
  landing must request no third-party resources or eager app bundles.

This is a single controlled lab regression, **not field Core Web Vitals**, INP,
a complete page-lifetime CLS result, a population percentile, or a speed claim for
real devices/networks. Lazy below-fold assets are checked separately for loading,
subpath correctness and provenance, not counted as initial-viewport bytes.

## Previous-artifact forward recovery

Before an authorized publication, retain the last qualified workflow run URL,
source commit, downloaded Pages artifact and its `artifact.json` in private release
evidence. Do not commit build artifacts. The existing workflow upload/retention is
not a permanent archive; download needed recovery evidence before it expires.

If public readback fails, keep the mismatch/run evidence; do not treat an older
cached page as the new candidate. Confirm the requested revision and allow the
bounded propagation retries. Persistent mismatch stops acceptance. It does not
authorize an automatic redeploy or destructive Git rollback.

For recovery, review the previous qualified artifact/source and prepare a **new
forward commit** restoring only the defective owned paths, preserving subsequent
unrelated work. Build/assemble again, stamp that new commit and run the same
candidate gates. A separately authorized main/environment deployment then publishes
that new candidate, followed by exact public readback. Preserve the failed run
and previous artifact for comparison. Never force-push, reset main, edit a legacy
`gh-pages` branch or bypass the environment to recover.

## Qualification boundary

Executed locally: Linux-hosted Chromium against a newly built production candidate
and deterministic tooling tests; no Agent/provider requests, fixture sends,
physical devices, publication or public freshness probe. Existing image captures
remain labeled simulated. Native/browser-chrome zoom, assistive technology and
real-device performance need their own evidence. Authenticated first reply and
combined live workflows stay with the existing connection/live QA owners, not a
new duplicate landing qualification task.
