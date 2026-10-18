# Retained dependencies and release audit after retirement

Task: `SECURITY-RETAINED-RELEASE-AUDIT`. The retained root npm audit **passes**
with zero findings on Node.js 22. This is bounded dependency evidence, not overall
SECURITY, platform qualification or release acceptance.

## Candidate and toolchain

Executed on 2026-10-18 UTC, Linux x86_64. `git rev-parse HEAD` returned
`ddbd5848cb6626f4312a243912097af848b86346`; `git rev-parse HEAD^{tree}` returned
`08b21586ce2fc50174a3b4e3666aeab67d251954`. The task worktree was clean before
verification. This receipt and its predecessor's successor link are the only
subsequent changes; the final documentation commit is identified in the worker
report rather than self-referenced here.

The existing Node.js 22 executable was selected through `PATH` for all npm and
Node checks: `node --version` returned `v22.22.2`, and `npm --version` returned
`10.9.7`. npm used `$AUTOWORK_CACHE/npm-22`. No SDK, dependency or browser was
installed. No override, audit exclusion, installer recreation, service action,
upstream edit or publication was performed.

## Retained inputs and predecessor reuse

All six [predecessor SHA-256 bindings](omniroute-node22-verification.md#input-sha-256-bindings)
match this candidate. The verified predecessor commit is
`80e41ed833087d2249f67f85f439db146ae183b2`.

| Input | SHA-256 |
| --- | --- |
| `package.json` | `c5acb3d1eae19f0f20c119745fd3ee5b0677457e01e9b14fcd3d8f1266b4e833` |
| `package-lock.json` | `f32c4b4d226bf6cef1a1f66733d4c2e065e0656d1223e89f17ceb68f42429b63` |
| `test/tooling/omniroute_retirement_test.mjs` | `ffc23de3fef8df27bea3997c7b7698259982afb294bfeea8517dc20efffd11e6` |
| `test/features/profiles/profile_catalog_test.dart` | `cdd84d5622db7e566e06a133e3941208d39c3a26862c04bba527468d35752adc` |
| `pubspec.yaml` | `7986bd3eaa967657f453e08f0522a4254496393699dc9640a7aba7de4cf1a43a` |
| `pubspec.lock` | `f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89` |

The predecessor records passing Dart offline lock enforcement and seven catalog
widget/unit cases; those results are retained, not rerun or promoted to current
whole-tree Flutter qualification. Profiles production files are unchanged, but
other shared source and localization inputs have changed. The predecessor's
root audit is historical corroboration only: the root audit below is fresh.

Retirement-scanned inputs changed since that commit: `.github/workflows/pages.yml`
and shared Agent/SSH, voice, localization and overlay source under `lib/`. Therefore
the existing [retirement guard](../../test/tooling/omniroute_retirement_test.mjs)
was rerun on this candidate despite its own unchanged hash. No deleted Go check
was reconstructed; the predecessor's unavailable historical audit-decoder checks
remain unavailable, not passing.

## Audit result and consumer mapping

| Exact command | Exit | Observed outcome |
| --- | --- | --- |
| `npm audit` | 0 | `found 0 vulnerabilities`; no severity threshold or dependency omission. |
| `npm audit --json` | 0 | `auditReportVersion: 2`, empty `vulnerabilities`; info/low/moderate/high/critical/total all zero. |
| `node --test test/tooling/omniroute_retirement_test.mjs` | 0 | One pass, zero failures, zero skips. |

The [root manifest](../../package.json) and [lock](../../package-lock.json)
contain only browser-development dependencies. The fresh audit reports four
dependencies total; its vulnerability map is empty. There is **no remaining
retained advisory** to assign a fix or risk exception to.

| Locked consumer chain | Purpose | Current finding / compatible fix |
| --- | --- | --- |
| Root → `@playwright/test@1.62.1` → `playwright@1.62.1` → `playwright-core@1.62.1`; root also directly declares Playwright | Browser tests and artifact/browser verification tooling | None reported; no dependency change needed for this audit. |
| `playwright@1.62.1` → optional `fsevents@2.3.2` (Darwin only) | Optional platform dependency in the retained lock | None reported; not a macOS runtime test or installed-consumer qualification. |

The [historical embedded review](omniroute-install-review.md#unresolved-upstream-dependency-recheck--2026-10-07)
records Braces → micromatch → http-proxy-middleware → OmniRoute high findings,
plus inherited smol-toml/KaTeX findings. Its later
[temporary risk decision](../../BLOCKERS.md#blk-20261007-006--remaining-npm-audit-highs-with-no-published-fix)
records a different historical run with five high and twelve total findings.
Those are deleted embedded-input observations, not current root findings. The
embedded manifest/lock and Wing installer consumer are absent; no patched embedded
closure or safety of existing personal installations is claimed from removal.
The only tracked npm manifest/lock in Wing's retained scope are the root pair.

The existing decision still requires release checks and compatible-fix
investigation, with temporary known risk reviewed weekly. It authorizes no
incompatible overrides, installs, service changes or release. This receipt does
not rewrite that decision, change remediation ownership or claim to have checked
external tracker/lease state. The coordinator supplied this isolated task;
external scheduler routing was not altered.

## Retained release security gates

The [release workflow](../../.github/workflows/release-alpha.yml) selects Node.js
22 and retains `npm audit --audit-level=high` in source validation (lines 26, 93).
The [platform smoke workflow](../../.github/workflows/hermes-platform-smoke.yml)
also retains Node.js 22 and the high-severity audit (lines 58, 78). The fresh
unthresholded audit above passes without weakening either gate.

The [release evidence generator](../../scripts/release_evidence.mjs) binds
`pubspec.lock` and `package-lock.json` (line 13). Both locks and these three release
inputs are unchanged from the verified predecessor:

| Release input | SHA-256 |
| --- | --- |
| `.github/workflows/release-alpha.yml` | `082efb1fa6e87cd90a91d3f25884a44cc56782075cf23664393cc874f7bc3a35` |
| `.github/workflows/hermes-platform-smoke.yml` | `d9511c6d95ca43f19cf57129a19cc3768df713635d1ea33a15d0e7066da0b235` |
| `scripts/release_evidence.mjs` | `3a55e27bb7d1a75a2b6cb4f309a775dc57c43059918e8bf243d851fca0755d96` |

This is source inspection plus a root registry audit, not a workflow execution,
Dart advisory audit, artifact build, signing or distribution check. The broader
[required checks](../../CONTRIBUTING.md#required-checks) still apply to release
candidates. No current whole-tree Flutter/browser pass is inferred from an
unchanged lock or from the predecessor's bounded passes.

## Evidence and qualification limits

Raw command output and separate terminal exits are task-local under
`$TMPDIR/security-retained-release-audit/`, not shipped artifacts. Output SHA-256:

| Log | SHA-256 |
| --- | --- |
| `npm-audit.log` | `6d8c5c8f3d7684adb070417bd608d01ae90aa3dc26a65af03ffda4955f38d9a3` |
| `npm-audit.json` | `7e61a1dc06ccb26109029be9b95227c72eeca9eb1ad4f71a2292e97fbbf21251` |
| `retirement.log` | `39f9700271e04cfd02c0dcf3baad73eed405f13d1eeef231c1e974e94f3dddc6` |

Only Linux-hosted Node checks ran here. The documentation-only closeout gate
verified 14 local links/anchors across both changed pages, all 12 file/log hashes
above, nine unchanged predecessor inputs and the recorded audit/guard exits.
`git diff --check` passed. No new product test was added. Native apps, physical
devices, live Agent/provider authentication, historical service audit compatibility,
installation, signing, activation,
rollback and distribution remain unqualified by this task. Root audit success
closes this bounded retained-dependency check, not the whole SECURITY goal.
Recheck when dependency/release inputs, toolchain or registry advisories change.
