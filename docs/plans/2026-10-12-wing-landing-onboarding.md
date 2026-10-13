# Wing landing page: from existing Hermes Agent to first reply

## Existing-Agent onboarding outcome

Status: Accepted

Accepted scope: the owner's landing-page improvement planning request and explicit
choice to prioritize existing Hermes users connecting their Agent and reaching a
first reply. This accepts the audience and outcome, not an unbuilt visual identity,
a live qualification result, analytics, deployment or implementation in this pass.
Visual concepts and optional demo ideas below remain recommendations.

The central queue is [TODO.md](../../TODO.md#now--next), with `goals.json` as its
execution index. Keep the existing `CONNECTION-PATHS` focus and active removal
owner. This page is a marketing/onboarding surface, not permission to redesign the
Desktop-guided Flutter application or introduce another Agent backend.

## Backlog connection

Canonical owners are `LANDING-FIRST-REPLY`, `LANDING-PRODUCT-PROOF` and
`LANDING-PAGES-QUALITY` in [TODO.md](../../TODO.md#now--next). The
[plan-to-task coverage index](README.md#plan-to-task-coverage) records their scope.
Existing `CONNECTION-SETUP-AUTH-MATRIX` and `PARITY-LIVE-WORKFLOW` retain live
qualification ownership. This plan neither dispatches them nor changes their leases.

## Located source and delivery

Source inspected at Wing `41772dbe`; public desktop viewport 1280×577 and isolated
mobile Chromium viewport 390×844 were inspected during this planning pass.

- [site/index.html](../../site/index.html): hand-written semantic landing HTML,
  copy, links, inline illustration and social metadata. This is not Flutter.
- [site/styles.css](../../site/styles.css): responsive layout, dark/cyan styling,
  focus treatments and reduced-motion rules. No site JavaScript is currently loaded.
- [site/assets/app-icon.png](../../site/assets/app-icon.png): site icon.
- [scripts/generate_readme_assets.mjs](../../scripts/generate_readme_assets.mjs):
  shared README/site artwork and deterministic UI captures, invoked by
  `npm run readme:assets`. Hero/runtime-flow SVGs are authored illustrations;
  showcase PNGs come from the deterministic fixture, not a live Agent/provider.
- [.github/workflows/pages.yml](../../.github/workflows/pages.yml): push to `main`
  with selected workflow/assets/site/lib/web/pubspec paths, or manual dispatch.
  Uses pinned actions, Flutter 3.44.6 and Node 22; builds the production Flutter
  app with `/hermes-wing/app/` base href, assembles `build/pages`, copies static
  landing HTML/CSS and selected shared assets, runs browser smoke, uploads a Pages
  artifact, deploys through the `github-pages` environment, then probes public
  landing/CSS/app/bootstrap/main-script paths. Pages concurrency cancels older runs.
  Test and generator script changes alone are not in its current push path filter.
- [pages-landing.spec.mjs](../../playwright/tests/regression/pages-landing.spec.mjs):
  assembled-artifact desktop/mobile/image/anchor/root and `/app/` initialization
  smoke. Several assertions bind to current copy and image count; change those
  intentionally alongside the redesign, without dropping behavioral coverage.
- [pages_workflow_contract_test.dart](../../test/tooling/pages_workflow_contract_test.dart):
  source-level Pages packaging/deployment regression contract.

Public `/hermes-wing/` is the landing page; `/hermes-wing/app/` is the separate
production Flutter web alpha. Pages API reports workflow-based publishing and
HTTPS enforcement. Its legacy source field says `gh-pages`; that is not the
current authoring location or a reason to edit that branch.

Latest observed successful workflow was [run 38336879182](https://github.com/TrebuchetDynamics/hermes-wing/actions/runs/38336879182),
source `c08ccc301d2e9bcfd05186ac198f2a4c11abfcd4`, including assembled browser smoke,
deployment and public probes. This is deployment evidence for that source only,
not evidence of authenticated Chat or current unbuilt recommendations.

## Evidence-backed problems

### P0: conversion stops before connection

The primary hero button is **Get started from source**, linked to the README.
**Try the web alpha** and **Open web alpha** lead to the connection form. There
is no on-page first-reply walkthrough, API enablement checklist, browser CORS
explanation or exact Wing capability prerequisite. A running Hermes CLI alone is
not sufficient. The landing should not make a prepared Hermes user rediscover
these requirements across several documents.

### P0: proof and claims need explicit provenance

The hero labels an authored SVG as a **live session trace**; that can imply a live
product capture. The later showcase correctly labels deterministic fixture
captures. Use visible and accessible illustration/fixture labels consistently.
Review feature and platform claims against current main and qualification receipts,
particularly approval choices, voice, Android confidence and administration. A
rendered approval control is not proof of all policies on every Agent. Do not
infer full Desktop parity, background reliability or live support from screenshots.

### P1: hierarchy sells architecture before the user's success

The architecture section is substantial while connection preparation and useful
success criteria are absent. Explain benefits before protocols. On the inspected
390px layout the CTA is visible and there is no horizontal overflow, but the
illustrated hero extends beyond the first viewport and actual product proof is
further below it. Improve ordering and crop discipline rather than merely shrink
all type or add more feature cards.

### P1: quality gates mostly prove that the site loads

Existing checks provide a good foundation. They do not prove API-readiness copy,
CTA-to-selected-setup continuity, keyboard completion of new interactions,
contrast, zoom, screen-reader usability, performance budgets or useful onboarding.
Public probes check known strings/files, not content freshness or first reply.
There is no measured newcomer/first-reply completion baseline in this investigation.

## Recommended visitor experience

One promise: **Use your existing Hermes Agent from another screen.**
Proposed hero wording: **Your Hermes Agent. On the screen you need.** Follow with
one concrete sentence about continuing conversations, inspecting tool work and
responding to approvals, constrained to verified capabilities.

1. **Understand:** compact identity, real product proof, one primary action
   **Connect my Agent**, and an adjacent short **Alpha · bring your own Agent**
   prerequisite. Secondary **Preview the connection screen** must make its limited
   experience clear. Source builds stay visibly disclosed, not hidden in a footer.
2. **Prepare:** primary CTA lands on `#connect`, not a generic repository page.
   Choose **Native client** or **Web alpha**. Native guidance names the supported
   OS path; Android choices retain **SSH → Remote server → Termux**. Linux Local
   guidance stays separate from browser access; the web client cannot manage SSH
   or access native secure storage. Link exact maintained guide sections.
3. **Check readiness:** enable an authenticated Agent HTTP API, verify the exact
   Wing capability contract, identify an authorized credential, and ensure the
   selected Agent profile/provider/model can reply. Use official Agent setup
   guidance plus Wing's maintained instructions; do not invent commands from memory.
   Generic health or `/v1/chat/completions` success is not full Wing compatibility.
4. **Connect:** explain native Local/SSH/Remote transport versus browser-trusted
   HTTPS and explicitly allowed CORS origin. No blanket public API binding,
   wildcard CORS, certificate bypass or new Wing Link prerequisites. Show endpoint
   and credentials only in the actual Wing application, never in landing forms,
   query strings, deep links, analytics or copied commands.
5. **Verify:** explicit user send produces an authoritative assistant reply in the
   chosen profile/session. Next demonstrate tool activity, approval, Stop and exact
   restoration only when qualified. A fixture animation cannot satisfy this step.
6. **Recover:** concise symptom-to-action guidance for API disabled, unreachable
   server, authentication denied, browser certificate/CORS rejection, unsupported
   capability and provider/model not ready. Keep drafts and setup choices intact;
   link specific help, not a generic Issues page as the only failure path.

The public landing remains static and credential-free. It neither tests arbitrary
private hosts nor proxies Agent traffic. Any readiness checks happen through
existing Wing/Agent surfaces. Disclose provider consumption before a live send;
never auto-send a demonstration or alter an existing personal Agent service.

## Page structure and content system

- **Header:** identity, Product, Connect, Status/Docs and one consistent CTA. Compact
  navigation remains operable on mobile; do not remove access to setup/help there.
- **Hero:** benefit-led statement, audience, concise maturity/prerequisites, primary
  connection action, subordinate preview, legible current UI proof.
- **Product sequence:** three annotated moments—conversation, tool/approval attention,
  return to the right session—using current deterministic captures with labels.
  Publish only supported outcomes; distinguish planned restoration/live acceptance.
- **Connection section:** concise decision path and prerequisites above, expandable
  details with semantic controls, direct links and expected results for each path.
- **Why Wing:** useful differences from staying in the CLI or official Desktop,
  including Flutter's target screens, without claiming feature-complete parity.
  State independent/open-source/MIT status and that Agent remains authoritative.
- **Trust:** who handles credentials, where data flows, no landing credential
  collection, provider dependence, privacy/support links and alpha limitations.
  Explain consequences in plain language; put full architecture in documentation.
- **Platform/status:** distinguish source/build availability, fixture/native/live
  qualification and signed-distribution availability. Link evidence owners, not
  stale broad badges. No download buttons until approved published artifacts exist.
- **FAQ/recovery:** existing CLI versus API, browser/native differences, model costs,
  running on Android, unsupported operations, safe help and setup failure paths.
- **Closing CTA/footer:** same connection action, concise build/developer path,
  docs, security/private-reporting, issue tracker, license and official Agent docs.
  Never invent customers, ratings, testimonials, benchmark wins or uptime promises.

Keep hero/navigation/setup terminology aligned with README and getting-started
owners. The landing is a guided entry, not a duplicate complete manual. Long
reference material stays linked. Future translation should cover complete
onboarding paths, not isolated headings with untranslated errors.

## Visual and interaction ambition

Recommendation: product-first editorial composition with recognizable Wing
identity, deliberate typography and real interface proof—not another neon SaaS
card grid. Preserve the icon and truthful product content. Do not treat the
current cyan/near-black skin as an immutable brand commitment or replace the
application's reference-guided visual system through marketing work.

Before the visual implementation, use the established Impeccable surface workflow
to select/record a complete composition with the owner. Compare a connection-led
composition with a product-story composition; the former is recommended for the
chosen audience. This plan does not pretend that a polished mock or a final world
has already been selected. Keep art direction separate from audience acceptance.

- First viewport must show benefit, audience, meaningful action and enough readable
  product proof on desktop and compact mobile. Test actual typography/crops rather
  than a pretty desktop screenshot alone.
- Reserve image dimensions; use responsive crops/encodes and self-hosted licensed
  assets. Move oversized imagery below the action without burying proof.
- Motion is optional, brief, stoppable and reduced-motion-safe. Avoid autoplay
  audio/video, scroll hijacking, parallax dependence and a heavy 3D/canvas hero.
- Native semantic links/buttons/disclosures, clear focus, logical heading order,
  skip link, sufficient contrast and readable line lengths. Full keyboard, 200%
  text/zoom, narrow layout and screen-reader access must survive all interactions.
- Core content/actions work without JavaScript. Add only small progressive
  enhancements if user testing shows value; do not migrate this page to Flutter,
  React, a CMS or a design dependency merely for visual polish.
- No new simulated product demo in the initial slice. A clearly labeled synthetic,
  no-network walkthrough could be considered later; it is Proposed, not an accepted
  feature or a reason to delay the real connection path.

## Search, sharing, performance and privacy

Maintain accurate title/description and a canonical landing URL. Add appropriate
social card metadata with a readable dedicated share image; verify absolute asset
URLs and mobile chat previews, not just the existing full UI screenshot. Validate
favicon/icon formats, link previews, crawlability, intentional app indexing and
subpath-correct sitemap/robots behavior if introduced. Structured application data
must use true maturity/distribution facts; no fake reviews or guaranteed rich results.

Keep the static landing lightweight. Proposed acceptance budgets: LCP ≤2.5s,
CLS ≤0.1 and INP ≤200ms where an interactive field sample exists. Lab runs must
record browser, viewport, device/throttle and cold-cache conditions; a single
resource timing sample is not a Core Web Vitals field result. Use a controlled
mobile performance budget, explicit asset sizes and lazy loading below the fold.
Do not eagerly load `/app/` just to display marketing proof. No external trackers
or fonts by default. Audit third-party requests if new services are proposed.

Measure the funnel before optimizing guesses: comprehension, selected setup path,
wrong turns, successful connection and first reply. Begin with consented moderated
sessions and redacted aggregate observations. A first small round can expose
failure modes but cannot establish a population conversion rate. Proposed research
bar: three existing Hermes users independently reach the correct setup route and
understand its success signal; actual live first-reply measurement needs authorized
QA access and budget. No arbitrary "5-minute setup" claim without timed evidence.

No analytics integration is authorized. Any later proposal requires explicit
privacy review: allowlisted aggregate event names only, no endpoint/host/profile,
credentials, transcripts, query strings or identifiers; retention and consent
must be decided. Avoid cookies/signup/newsletter infrastructure without evidence
that it serves this open-source onboarding goal.

## Delivery slices and acceptance

1. **LANDING-FIRST-REPLY — connection-first copy and guided entry.** Implement the
   honest CTA, prerequisites, selected-path handoff and compact recovery section.
   Synchronize relevant README/getting-started anchors without rewriting their
   active owners. Extend existing Pages smoke for CTA destinations and core
   readiness content. Offline qualification must not close live acceptance.
2. **LANDING-PRODUCT-PROOF — coherent product-first visual rebuild.** Build the
   selected composition across desktop/mobile using provenance-labeled current
   captures, revised hierarchy, typography, status, trust, FAQ and sharing assets.
   Run rendered keyboard/zoom/reduced-motion and browser accessibility checks;
   manual screen-reader/native-device gaps remain explicit.
3. **LANDING-PAGES-QUALITY — artifact-bound delivery and regression coverage.**
   Extend the existing pipeline rather than inventing a new host. Cover relevant
   source/test/generator inputs, staged subpath assembly, landing and `/app/`
   initialization, links, asset/provenance metadata, focused accessibility and
   controlled performance budgets. Candidate checks run before publication;
   keep publishing permission restricted to authorized main/environment events.
   Prevent untrusted fork/PR execution from acquiring Pages deployment rights.
   Public readback should verify exact artifact freshness plus key CTA/assets, with
   bounded retry for CDN propagation. Preserve pinned actions, OIDC, cancellation,
   base href and no-secret fixture discipline. Retain the previous qualified
   artifact/commit and document forward recovery; no destructive Git rollback.

Visual proof follows the first-reply content contract. CI hardening can be developed
independently. Do not block offline work on personal credentials or device access.
Reuse `CONNECTION-SETUP-AUTH-MATRIX` for authenticated connection/first reply and
`PARITY-LIVE-WORKFLOW` for the combined tool/approval/Stop/restoration proof; never
create duplicate live workers or change their leases. Full landing success stays
unverified until the applicable authorized live journey is observed.

## Verification configuration and limits

A cheap numeric proxy is **onboarding readiness points**: on-page API enablement,
exact Wing capability prerequisite, browser CORS explanation and first-reply success
criterion. Baseline is **0 of 4** at inspected source. Target **4 of 4** is content
coverage only; passing it cannot establish onboarding quality or live success.

```text
Goal: Existing Hermes users choose the right connection route and reach first reply.
Scope: site/**; selected assets/readme/**; scripts/generate_readme_assets.mjs;
       .github/workflows/pages.yml; playwright/tests/regression/pages-landing.spec.mjs;
       test/tooling/pages_workflow_contract_test.dart; affected setup docs.
Metric: onboarding_readiness_points (0..4), with visual/accessibility/live guardrails.
Direction: higher_is_better
Iterations: 3 bounded candidate passes; stop for review or plateau, not endless audits.
```

Runnable source proxy, no network or mutations:

```bash
python3 -c 'import pathlib,re; s=pathlib.Path("site/index.html").read_text(); checks=[r"API_SERVER_ENABLED|enable.{0,80}(HTTP )?API",r"/v1/capabilities",r"CORS",r"first[- ]reply"]; print(sum(bool(re.search(p,s,re.I|re.S)) for p in checks))'
```

Guard for the planning/contract owner:

```bash
flutter test --no-pub test/tooling/pages_workflow_contract_test.dart test/tooling/plan_backlog_traceability_test.dart
```

For implementation, assemble the exact Pages artifact and run its existing
`PAGES_BASE_URL=... npx playwright test --config=playwright.config.mjs playwright/tests/regression/pages-landing.spec.mjs`
command against that candidate, plus the new quality checks. Never substitute the
public old site or a mock Agent reply as evidence for a changed candidate.

This planning pass observed public rendering and read existing successful CI; it
did not enable an API, connect/authenticate, send a message, change the deployed
page, modify a pipeline, start a worker or schedule a job.
