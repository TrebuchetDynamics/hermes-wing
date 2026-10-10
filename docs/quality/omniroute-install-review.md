# OmniRoute installer dependency review

## Historical scope after retirement

The committed retirement removes this installer, its embedded npm inputs and
special setup/discovery operations. The sections below retain their original
commands and outcomes. They are not current installation guidance or proof that
remaining dependencies pass. See the [current design](../spec.md#security-compatibility-and-delivery)
and [security successor](../../TODO.md#now--next). Do not recreate these deleted inputs
to repeat the old audit.

The optional local Wing Link installer pins OmniRoute 3.8.51 and its npm
dependency closure. It does not expose a remote install operation, start a
server, provision a provider credential, or change Hermes profiles.

## Unresolved upstream dependency recheck — 2026-10-07

Card `t_a466ece0` freshly ran both named high-severity gates on the preserved
working-tree locks. `npm audit --audit-level=high` exits 0;
`npm audit --prefix wing_link/internal/app/omniroute_assets --audit-level=high`
exits 1. JSON variants confirm zero root findings and 11 embedded findings
(six low, one moderate, four high, zero critical). No dependency was changed.

The current GitHub advisory API for
[GHSA-vfj7-8cjw-p6xm](https://github.com/advisories/GHSA-vfj7-8cjw-p6xm)
reports `<=3.0.3` with no first patched version. Fresh `npm view` metadata
reports Braces latest 3.0.3, micromatch latest 4.0.8 (requires Braces `^3.0.3`),
http-proxy-middleware latest 4.2.0 (requires micromatch `^4.0.8`) and OmniRoute
latest 3.8.51 (requires http-proxy-middleware `^4.0.0`). The embedded lock already
resolves exactly those versions. Neither a published Braces patch nor a newer
parent closure removes this chain. npm's suggested OmniRoute 3.8.48 is inside
the ACP advisory range; it is not an acceptable repair. The existing OmniRoute
3.8.51 / Next 16.3.6 pins and all reviewed overrides remain untouched.

Delivery tracing confirms `omniroute.go` embeds these two runtime npm files,
writes them into the owner-only staging directory and uses
`npm ci --ignore-scripts --omit=dev`. Existing installations must match the
embedded lock byte-for-byte. Therefore fixing only browser tooling would not
repair the packaged installer. There is no corrected packaged closure to test.

On Linux / Node 26.7.0,
`(cd wing_link && go test -p 2 ./internal/app -run '^TestOmniRoute' -count=1 -v)`
exits 0, including pin, altered-integrity refusal and failed-readiness checks.
The opt-in real-install test is **SKIPPED**, not consumer evidence. Node 22
installed-consumer/CLI checks, locked installs, the full Go suite, fresh Flutter
web build and E2E are **NOT_CHECKED** in this occurrence: no authorized safe
dependency change was available, so broad checks cannot establish audit closure.
Native/live runtime, image build/run/deployment and release remain **NOT_CHECKED**.

Full audit/registry/advisory responses, command exits and SHA-256 fingerprints
of both manifests/locks and installer source/tests are retained locally in
`.task-evidence/t_a466ece0/receipt.json` and its adjacent files (ignored evidence,
not shipped artifacts). Base HEAD: `1afe1307e37ee1ddfa1f7d67ad047509e99c8784`;
the receipt fingerprints identify the dirty predecessor source actually inspected.
FIX-NPM-AUDIT remains unfinished and SECURITY remains partial. The technical gap
is upstream. The later owner-decision entry
[BLK-20261007-006](../../BLOCKERS.md#blk-20261007-006--remaining-npm-audit-highs-with-no-published-fix)
records whether to retain that known risk or allow incompatible overrides.
Its default retains reviewed pins until upstream fixes exist. That decision does
not make the audit pass or grant implementation acceptance or review approval.

## Current patched closure — 2026-10-06

OmniRoute 3.8.51 is outside the affected range (`<=3.8.50`) of
[the ACP custom-agent RCE advisory](https://github.com/advisories/GHSA-hf57-cqmx-p4gr).
Its published package still pins Next 16.3.5, so the embedded manifest overrides
Next to the first patched version, 16.3.6, for
[the Node ImageResponse RCE advisory](https://github.com/advisories/GHSA-vcvr-r3jv-pc5j).
The prior reviewed overrides remain: `adm-zip` 0.6.1, DOMPurify 3.4.16 and
`sharp` 0.35.5. The complete lock was regenerated with lifecycle scripts disabled.

The root `npm audit --audit-level=high --json` exits 0 with no findings.
The embedded audit exits 1 with 11 affected-package findings: six low, one
moderate, four high, zero critical. This is a partial repair, not a clean audit.
[Braces <=3.0.3](https://github.com/advisories/GHSA-vfj7-8cjw-p6xm) has no
published patched version; its high finding propagates through micromatch,
http-proxy-middleware and OmniRoute. smol-toml 1.8.0 and inherited KaTeX findings
also remain. Do not downgrade OmniRoute to npm's suggested 3.8.48: it is inside
the direct ACP advisory's affected range. FIX-NPM-AUDIT remains open.

On Linux with Node 26.7.0, an isolated `npm ci --ignore-scripts --omit=dev`
and `npm ls` passed. The existing consumer harness passed ZIP, Sharp PNG,
Transformers image resize and DOMPurify version checks. It now additionally
checks that the published `dist/server.js` resolves Next 16.3.6, loads its
`startServer` export without calling it, and generates a small PNG through
`next/og`. The package tarball has precompiled application chunks; these checks
do not independently certify every bundled application module as vulnerability-free.
CLI `--version` and `--help` passed in an owned temporary HOME without creating
files there. Focused OmniRoute and full Wing Link Go suites passed, including
altered-integrity refusal and failed-readiness non-activation tests.

No installed runtime was changed, no server was started, and no inference,
provider setup, Android installation, image build or release was qualified.
These are dependency and isolated consumer checks, not live service qualification.

## Historical dependency correction — 2026-09-05

The initial lock failed `npm audit --omit=dev` with eight findings (six high,
one moderate, one low), including inherited findings in parent packages. The
review added exact root overrides for:

- `adm-zip` 0.6.0: [archive memory-allocation advisory](https://github.com/advisories/GHSA-xcpc-8h2w-3j85).
- `sharp` 0.35.3: [libvips advisories](https://github.com/advisories/GHSA-f88m-g3jw-g9cj).
- DOMPurify 3.4.13: [sanitization advisory](https://github.com/advisories/GHSA-55q2-fjhq-7xh7).

That review's regenerated lock reported zero known vulnerabilities at the time;
it is not the current audit result. npm lifecycle scripts
remain disabled. The normal Go test checks the locked versions and integrity
fields; future dependency changes must repeat the audit.

Dependency review rejects the lowercase `apache-2.0` metadata published by
`@pierre/diffs` 1.2.12 and `@pierre/theming` 0.0.2. Both package manifests declare
that license; the diffs tarball includes the Apache 2.0 text, and the
[upstream monorepo license](https://github.com/pierrecomputer/pierre/blob/4f60f29f3b9caf95945ea505bd0cc8b97acb8850/LICENSE.md)
also supplies Apache 2.0. CI allows only these exact package/version license
metadata exceptions. Vulnerability checks and the denied-license list remain
enforced.

## Historical compatibility and qualification — 2026-09-05

A fresh locked installation was tested on Linux with Node 24.19.0. OmniRoute's
version/help probes passed. A synthetic ZIP creation/read round trip passed,
and Hugging Face Transformers decoded and resized a synthetic PNG through the
patched sharp dependency. DOMPurify sanitized event-handler and script input in
Chromium. The archive and transformer checks are also included in the opt-in
real-install Go test:

```bash
cd wing_link
WING_TEST_OMNIROUTE_INSTALL=1 go test ./internal/app -run '^TestOmniRouteRealInstall$' -count=1
```

These checks cover the exercised APIs across the two 0.x minor upgrades. They
do not qualify all OmniRoute integrations, model inference, provider sign-in,
Android installation, or background service operation. No model was downloaded,
no provider request was sent, and no OmniRoute server was started for this review.
