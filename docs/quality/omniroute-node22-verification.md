# OmniRoute retirement: Node.js 22 offline verification

Task: `VERIFY-OMNIROUTE-NODE22-CLOSURE`. Required surviving offline checks pass;
historical Go checks remain unavailable. **Not SECURITY or release acceptance.**

## Candidate and environment

Retirement baseline: `92beb1dcddbf2be638ac7819f3a636ec25ba75e2`.
Candidate base: `0b9cc27d9b7df5265dedd19622b106579c385ee9`, tree
`72b7368bd9aa2413d216aca4783404d951f267c9`. The original worktree was clean;
execution resumed with this evidence document preserved. The executed candidate
is that base plus the `pubspec.lock` repair fingerprinted below. Production code,
tests and root npm inputs are unchanged. The accompanying commit also updates
this document and links it from the historical review; no runtime inputs change
after these checks. The final commit identity belongs in the worker report,
avoiding a self-referential receipt.

Host: Linux x86_64; Node.js `v22.22.2`, npm `10.9.7`; Flutter `3.44.2`, framework
`c9a6c484230f8b5e408ec57be1ef71dee1e77020`, Dart `3.12.2`.
The existing Node 22 executable was selected through `PATH` for every check below.
Package caches used `$AUTOWORK_CACHE/npm-22` and
`$AUTOWORK_CACHE/dart-pub-3.12.2`. Raw logs are task-local under
`$TMPDIR/omniroute-evidence/final/`; they are not shipped artifacts.

## Commands and observed outcomes

| Exact command | Exit | Outcome |
| --- | --- | --- |
| `npm audit --audit-level=high` | 0 | Zero vulnerabilities in the retained root lock; no audit suppression or dependency edits. |
| `node --test test/tooling/omniroute_retirement_test.mjs` | 0 | One test passed; zero failures/skips. |
| `flutter pub get --offline` | 0 | Repaired the Dart lock to match Flutter 3.44.2; seven dependency changes, no manifest edits. |
| `flutter pub get --offline --enforce-lockfile` | 0 | Repaired lock resolves unchanged. |
| `flutter test --no-pub test/features/profiles/profile_catalog_test.dart` | 0 | All seven tests passed, including generic Agent catalog retention without discovery/setup controls. |
| `git diff --exit-code -- package.json package-lock.json pubspec.yaml test/tooling/omniroute_retirement_test.mjs test/features/profiles/profile_catalog_test.dart` | 0 | All named unaffected inputs preserved. |

The runner explicitly widened Touches to include protected `pubspec.lock`
before repair. SDK-compatible resolution changed `intl 0.20.3` to `0.20.2`,
`matcher 0.12.20` to `0.12.19`, `meta 1.19.0` to `1.18.0`, `test 1.31.1` to
`1.31.0`, `test_api 0.7.12` to `0.7.11`, `test_core 0.6.18` to `0.6.17`, and
`vector_math 2.4.3` to `2.2.0`, updating their package hashes. The SDK pins the
latter matcher, meta, test_api and vector_math versions. No overrides, installer
recreation or audit suppression were introduced. The predecessor lock SHA-256 was
`8c0c0624de03bccffd0fe05aa17cc2fc5b66e7b9c53dcaafec9ae88e65677854`;
passing results above apply only to the repaired candidate, not that predecessor.

## Retirement and historical checks

The existing [Node retirement guard](../../test/tooling/omniroute_retirement_test.mjs)
checks absence of the bundled manifest and OmniRoute references in tracked active
client/service/protocol/release/workflow inputs, retaining the exact historical
license citation exception. It also verifies that the workflow keeps the high
severity root audit and Flutter analyzer gates. Its pass is a textual removal
check, not runtime CLI/HTTP qualification.

`git ls-files wing_link lib/core/wing_link` returned no entries (exit 0).
The entire service and client subtree was subsequently removed in
`bce4ec5fb9109d29520b81260f13bad93c6f2cb7`. Thus the former `omniroute-setup`
command, `--with-omniroute` flag, `/v1/host/omniroute` handler, discovery capability,
installer assets and release component have no shipped Wing service implementation
in this candidate. No removed CLI was invoked, no server was started, and no
installed external runtime was inspected or changed.

The following historical Go checks are **UNAVAILABLE / NOT RUN**, with no exit
status or passing result. Their module, implementation and tests are deleted:

```sh
(cd wing_link && go test ./internal/app -run '^TestRetiredOmniRouteIntegrationIsUnavailable$' -count=1)
(cd wing_link && go test ./internal/protocol -run '^TestRetiredOmniRouteIsRejected$' -count=1)
(cd wing_link && go test ./internal/audit -run '^TestRetiredDiscoveryAuditHistoryRemainsReadable$' -count=1)
```

These names were inspected read-only at the retirement baseline. The last test
previously exercised decoding of the `omniroute.discover` audit operation. There
is no retained Wing audit decoder to qualify on the current candidate; historical
audit readability is **unverified**, not inferred from deletion. No historical
service or installer was restored to make a check runnable.

The retained [profile catalog test](../../test/features/profiles/profile_catalog_test.dart)
contains the generic Agent-owned `omniroute` provider fixture and asserts the
absence of special discovery/setup controls. All seven cases passed in the
Linux-hosted Flutter widget/unit runner. This qualifies that deterministic seam,
not native app interaction or a live Agent catalog request.

Scheduled card `t_a466ece0` input reconciliation is limited to the
[historical review](omniroute-install-review.md): its embedded manifest/lock and
installer checks refer to deleted inputs and cannot be replayed on this candidate.
The root audit above is fresh, not a reinterpretation of that card's failed
embedded audit. No card, schedule, lease or remediation-owner routing was changed;
current external scheduler state was not inspected.

## Input SHA-256 bindings

| Input | SHA-256 |
| --- | --- |
| `package.json` | `c5acb3d1eae19f0f20c119745fd3ee5b0677457e01e9b14fcd3d8f1266b4e833` |
| `package-lock.json` | `f32c4b4d226bf6cef1a1f66733d4c2e065e0656d1223e89f17ceb68f42429b63` |
| `test/tooling/omniroute_retirement_test.mjs` | `ffc23de3fef8df27bea3997c7b7698259982afb294bfeea8517dc20efffd11e6` |
| `test/features/profiles/profile_catalog_test.dart` | `cdd84d5622db7e566e06a133e3941208d39c3a26862c04bba527468d35752adc` |
| `pubspec.yaml` | `7986bd3eaa967657f453e08f0522a4254496393699dc9640a7aba7de4cf1a43a` |
| `pubspec.lock` | `f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89` |

Log SHA-256: `npm-audit.log` =
`6d8c5c8f3d7684adb070417bd608d01ae90aa3dc26a65af03ffda4955f38d9a3`;
`retirement.log` =
`0e9bfd5fe45caf6223c643ed94dc12b3fffbc378fb26c162c3770a9d2be5ca7f`;
`pub-repair.log` =
`072889bd54db25700950f202714e6773c265c5da50fef10362a230c375f9c138`;
`pub-get.log` =
`d4cb7a3c68b4133b4f6e58c67ff5bfd13725d8021e930388cdc98da8a575919d`;
`profile-catalog.log` =
`787c0975b786dc4c17c6f45014aa4b2d707112ea212cac2da4dfba498b147ecd`.

This is offline Linux-host evidence only. SECURITY, historical audit compatibility
and release acceptance remain open; missing Go checks are not converted to passes.
No native app, physical device, live Agent/provider, external installation, service
lifecycle, inference, signing or distribution was qualified. Revalidate this receipt
when the candidate source, checks, dependency inputs or selected toolchain change.
