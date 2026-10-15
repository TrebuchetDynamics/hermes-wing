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

`LANDING-FIRST-REPLY` is complete for offline onboarding and archived in
[TODO history](../../todo.archive.md); authenticated first reply remains with
`CONNECTION-SETUP-AUTH-MATRIX`. The open `LANDING-PRODUCT-PROOF` and
`LANDING-PAGES-QUALITY` tasks in [TODO.md](../../TODO.md#now--next) own the
remaining visual and delivery outcomes. The
[plan-to-task coverage index](README.md#plan-to-task-coverage) records current
owners. `PARITY-LIVE-WORKFLOW` retains combined live qualification ownership.
This plan neither dispatches those tasks nor changes their leases.

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

1. **LANDING-FIRST-REPLY — complete; archived.** The reviewed offline onboarding
   implementation and README/getting-started handoff are recorded in
   [TODO history](../../todo.archive.md). Authenticated first reply remains an
   explicit live qualification gap owned by `CONNECTION-SETUP-AUTH-MATRIX`.
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

## README re-review: acquisition before use, tutorial before evidence

Planning continuation from the owner's supplied README re-review. Its **7.5/10**
is a provisional editorial opinion, not measured usability or a completion metric.
Only the supplied findings are addressed here; do not invent an omitted review.
Source inspected at Wing `c9608c19`: README Quickstart starts at line 61, first
chat at line 97 and source build at line 139. The guide starts with deprecated
management/development status; its direct-connection steps precede acquisition
and mix user instructions with worktree, fixture, storage and delivery history.

The README/getting-started documentation continuation was delivered under
`LANDING-FIRST-REPLY` and is recorded in [TODO history](../../todo.archive.md).
Do not reopen that task or create a duplicate. Preserve its accepted opening,
Desktop/Flutter purpose, honest preview, API readiness, network security,
credential distinction and qualification limits in future edits.

### First: reorder the README without another full rewrite

Present three explicit starting paths, each with prerequisites → actions → success:

- **Preview UI:** browser → open the hosted connection-screen preview → see the
  welcome/form. No Agent or credential is needed to inspect it; no reply is promised.
- **Connect an existing Hermes Agent:** obtain/open a suitable client first (hosted
  web, or a link to native source-build instructions), then check enabled
  authenticated API, supported capability, provider/model and native/web transport;
  connect deliberately and send the existing no-tools prompt → authoritative reply.
- **Build a native client:** Git/Flutter and target-platform tools → build/open the
  client using the maintained build guide → visible welcome screen, then continue
  to the existing-Agent path. Build success is not Agent readiness or generation.

Keep limitations adjacent to the decisions they affect. Retain incoming explicit
anchors and first-chat/build/help links. Reuse existing content rather than expanding
README into a platform manual or making readers jump past usage to obtain the app.

### Second: make getting-started a user tutorial

Recommended order: purpose and prerequisites → obtain/open Wing → prepare Agent
→ choose the connection route → send the first message → troubleshoot → data,
permissions and concise platform limitations. Link deeper native build/setup pages
and official Agent instructions instead of duplicating installation reference.

Trace labels to current main and localization before writing steps. Preserve
Android's SSH, Remote server, Termux choices; distinguish native Linux Local from
browser access. Do not promote older QR/pairing choices or restore deprecated
management setup. Local discovery not starting Agent, browser SSH/OAuth limits,
secure-storage variation and unqualified same-phone hosting remain useful user
limitations, but should say what the user can do next, not narrate a QA run.

Move worktree status, fake stores, Chromium/native receipts, keyboard-test matrices
and commit/delivery chronology out of tutorial prose. The existing `docs/quality/`
receipts and product/runbook owners retain that evidence; use a short linked
status/limits summary. Preserve historical evidence verbatim and check current
source/delivery before making any new availability claim. Relocation is not new
platform/live qualification and must not erase real limitations.

### Acceptance and verification for this continuation

- Each README starting path can be followed without searching below usage for how
  to obtain the client. Prerequisites and a truthful success signal are explicit.
- A reader can follow the tutorial through client acquisition, Agent readiness,
  selected-route connection and first-message outcome without learning repository
  worktrees, synthetic stores, qualification receipts or delivery vocabulary.
- Preserve existing anchors and resolve README → guide → platform/Agent/help links;
  compare UI wording with current implementation, not archived screenshots.
- Keep security, provider-cost warning, token/provider distinction, unsupported
  browser modes and actual qualification limits. Never broaden access to obtain a
  successful walkthrough or infer generation from a healthy endpoint.
- Add the smallest ordering/anchor regression to the existing tooling tests during
  implementation. Review the rendered Markdown and selected public UI labels;
  human first-reply observation stays with the existing live-QA owner and budget.

Verification here is observable document/route consistency, not an invented numeric
quality score. The existing landing readiness proxy does not measure tutorial
ordering. Planned implementation checks include focused README/docs contracts,
plan traceability and local anchor validation; actual command outcomes must be
recorded. Current `readme_assets_contract_test.dart` still asserts old **Try the
web alpha** wording, and `wing_link_docs_contract_test.dart` still asserts retired
Termux port/pairing text. Reproduce/classify their failures, update genuinely
obsolete expectations with behavior/security-equivalent coverage under existing
retirement ownership, and never restore obsolete instructions merely to pass.

Planning guard actually run on the isolated continuation candidate:
`flutter test --no-pub test/tooling/readme_assets_contract_test.dart test/tooling/wing_link_docs_contract_test.dart test/tooling/plan_backlog_traceability_test.dart`
exited 1: three tests passed and two failed on existing text expectations—README
`Try the web alpha` at line 68 and Termux `127.0.0.1:8654` at line 94. README,
guide, Termux runbook and test inputs are unchanged from the baseline. These are
retained failures, not newly passing guards or a reason to undo accurate copy.
Plan traceability passed; future documentation implementation must reconcile the
affected assertions while preserving security and truthful preview coverage.

Sequence this documentation correction before landing CTAs depend on the revised
guide. No new hard dependency, priority change or live worker is introduced.
Rejected alternatives: another broad README rewrite would reopen accepted fixes;
deleting all limitations would conceal risk; another audit task would duplicate a
known correction. This planning pass changes neither README nor the tutorial.

## Remaining README review: proof, readiness and useful workflow

### Current-source disposition and Conduit lessons

The owner requests README improvement informed by
[the supplied Conduit README](https://github.com/kaishi00/hermes-conduit/README.md)
and the full editorial re-review. The supplied **7.5/10** and October 12/165-line
snapshot are historical editorial judgments, not measured usability or current
source dimensions. Preserve the accepted purpose, direct Agent ownership, honest
preview, credential distinctions and security warnings; do not reopen them.

Inspected Wing base: `6125337d09627258063c44ebbddc8fbc15de923d`.
The current README has 209 lines and getting-started has 311. Inspection of both
tracked showcase PNGs confirms visible **DEMO DATA · SIMULATED SESSION**; the wide
image also says **SIMULATED RUN** and **not live synchronization**. The original
LIVE RUN contradiction is already repaired at the producer. The images still show
**Gateway readiness / echo e2e**, dense desktop text and, in the wide image, the
retired **Office** navigation entry. The remaining issue is useful, current proof,
not a missing label. No new capture, build or live session ran in this plan.

Current disposition of the supplied review:

- Acquisition paths exist and connect instructions now obtain/open Wing first.
  Improve scanning and reduce duplication; do not rebuild the solved prerequisite.
- The tutorial no longer opens with worktree/receipt history. It remains long and
  embeds route/grant details, key-storage rules and repeated readiness explanations.
- A platform matrix already lives at
  [Platform evidence and limits](../getting-started.md#platform-evidence-and-limits),
  and README links there rather than using internal routes as the primary answer.
  Keep this single user-facing owner; improve evidence precision, not create a twin.
- The no-tools smoke and optional repository-summary milestone already exist.
  Tighten the handoff and example wording; do not add a duplicate workflow.
- Full-app SSH/native/live assertions still require matching target evidence.
  Historical absence-of-delivery prose does not establish current main's absence.

Conduit source inspected: README revision
[`e2e8209a61b7809f146a401b6854f8ee6e780f87`](https://github.com/kaishi00/hermes-conduit/blob/e2e8209a61b7809f146a401b6854f8ee6e780f87/README.md).
The supplied GitHub `/README.md` URL was read through its raw-file equivalent;
this pinned revision is the README's latest path commit observed during research,
not a claim that another client's advertised features were executed.

Borrow Conduit's outcome-first opening, short **What it does → Requirements →
Connecting** progression, distinct build instructions, and explicit distinction
between server credentials and transport. Do not copy its same-database/cross-device
promise, native dashboard port 9119/login/RPC contract, iOS/App Store status, OAuth,
Cloudflare tokens, notifications/relay, CarPlay, privacy absolutes or feature list.
Conduit is editorial prior art only; official `apps/desktop` remains the product
reference and the connected Agent remains runtime authority. Its setup commands
were inspected, not executed.

### Selected approach and planner calls

This is a bounded onboarding refinement, not a new website or application design.
Use the existing open `LANDING-PRODUCT-PROOF` for the composed README/tutorial/asset
slice and `LANDING-PAGES-QUALITY` for independent artifact checks. Preserve completed
`LANDING-FIRST-REPLY`, existing dependencies, queue order, focus and live-QA owners.
No new IDs, implementation, dispatch, commits, publication or timers are authorized
by this planning pass. Existing separately authorized work is not paused.

Planner calls, rejectable without changing the owner's requested outcome:

1. Keep README around **160–180 lines**, with a benefit-led opening, existing
   primary **Set up your first chat**, secondary honest preview, and three distinct
   start choices. Put client acquisition/build before first-chat actions; remove
   repeated setup prose instead of moving all technical detail into README.
2. Keep `docs/getting-started.md` as the beginner tutorial and its existing platform
   matrix as the user-facing support owner. Do not create `platform-support.md` or
   another evidence ledger just because an earlier proposal named it. Keep exact
   section anchors where incoming links exist; add no speculative legacy aliases.
3. Tutorial spine: obtain/open Wing → prepare Agent → choose Local/SSH/Remote or
   Android Termux → enter the right credential → no-tools first reply → optional
   bounded repository summary → common errors → data/permissions and concise limits.
   Separate advanced protocol/key/reference material with links to existing
   [connection contracts](../product/desktop-connection-paths.md) and runbooks.
   Exact grant/method inventories and receipt chronology belong in technical owners,
   not the uninterrupted beginner steps. Keep route-specific SSH readiness nearby.
4. Reuse Wing's current components, capture generator, dark presentation and
   phone-attention composition. Prefer a readable synthetic demo-repository summary
   and a clearly scoped read-only file-list approval over `echo e2e`. Make command
   text unmistakably illustrative; never run it. Select a narrow readable crop
   showing context/tool result/decision, not every desktop navigation control.
   Recapture current UI so Office and other retired controls disappear. Keep
   provenance burned into wide/mobile outputs and all failure/redaction guards.
5. Keep this scope independent of a whole landing-page rebrand. Update shared
   site assets/captions only where the same producer or changed links require it;
   retain the wider existing landing acceptance rather than falsely close it from
   README-only progress. No new interactive product demo or credential collection.

Rejected approaches: a copy-only caption patch leaves stale UI and toy content;
importing Conduit's capabilities overstates Wing support; a full redesign increases
scope without fixing the tutorial; deleting limitations hides risk. No ADR, new
framework, dependency, backend, analytics or Agent mutation is needed.

### Concrete acceptance and checks

A fresh reader must find a suitable client before connection/use, identify Agent
versus provider credentials, and know the visible success/failure result without
understanding worktrees, request grants or test receipts. Preserve cost, transport,
trust, redaction and no-replay warnings. Unsupported browser SSH/OAuth and uncertain
native SSH readiness remain explicit. Explain unknowns plainly, not as brokenness.

For Chat, streaming/tools, approvals/Stop, SSH, voice, notifications and recovery,
keep platform evidence distinctions: implemented UI, simulated rendering/transport,
native exercised and authenticated live verification are not interchangeable.
Separate voice and notifications where their status differs. Link the actual
source/target evidence, verify current inclusion, and keep formal chronology in
`docs/quality/`. Neither screenshots nor a terminal SSH login qualify Wing live use.

Retain the deliberate no-tools introduction prompt. The optional second milestone
uses a non-sensitive Agent-granted demo Project, no secret reads or writes, provider
cost warning, observed tool activity and foreground return to the exact session.
Approvals are conditional on Agent actually requesting them; no guaranteed prompt,
background completion, notifications or cross-device continuity claim is added.

Verification, not an editorial score, is the acceptance metric:

- Count README lines against the 160–180 planner target; check user-path order,
  anchors, prerequisites, safe recovery and no duplicate support owner.
- Extend existing README/tooling contracts for semantic ordering, useful synthetic
  content, per-crop provenance and absence of retired Office UI. Keep security and
  unsupported-operation negatives; do not preserve obsolete text solely for tests.
- Use `flutter test --no-pub test/tooling/readme_assets_contract_test.dart
  test/tooling/wing_link_docs_contract_test.dart
  test/tooling/plan_backlog_traceability_test.dart` and `git diff --check` for the
  composed implementation. These are planned implementation checks, not passes here.
- If capture fixture/component wiring changes, run its nearest regression before
  `npm run readme:assets`; validate matching Flutter 3.44.2 and Node 22. Inspect
  wide and narrow assets at real README display sizes, plus keyboard/zoom/reduced
  motion for any changed site path. Do not substitute browser viewport evidence
  for Android/native or infer live success from deterministic captures.
- `LANDING-PAGES-QUALITY` retains fresh assembled-artifact subpath/CTA/image checks,
  console/same-origin error handling and exact artifact identity. Use its existing
  producer; a public cached site is not the changed candidate. No deployment here.

Current tests already assert simulation labels, honest preview, client acquisition,
no-tools-before-summary ordering and guide anchors. The historical two failing text
assertions recorded above describe the older planning checkpoint, not current
failure proof. Reuse input-matched evidence or run affected checks on the eventual
implementation; never remove those negative boundaries to make copy shorter.

Existing user order remains `LANDING-PAGES-QUALITY` before `LANDING-PRODUCT-PROOF`;
the former can prepare focused artifact checks independently, and the latter owns
the minimal README/tutorial/current-image batch. This plan does not reprioritize
either task or turn a whole-site rebrand into a prerequisite for README progress.
Preserve the product-proof parent until its remaining responsive site/share
acceptance passes. No unmet product question requires an interview. An independent
read-only builder check of the revised plan and both task bodies reported
“nothing important left.” This is planning readiness, not implementation or test
acceptance.

## Verification configuration and limits

A cheap numeric proxy is **onboarding readiness points**: on-page API enablement,
exact Wing capability prerequisite, browser CORS explanation and first-reply success
criterion. The original source baseline was **0 of 4**. At the current
`6125337d` inspection, the same read-only command returns **4 of 4**. This is
already-delivered content coverage, not a reason to repeat first-reply work; it
cannot measure tutorial readability, useful imagery, onboarding quality or live
success. The remaining work uses the observable acceptance above, not a fabricated
conversion rate or a fresh editorial score.

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
