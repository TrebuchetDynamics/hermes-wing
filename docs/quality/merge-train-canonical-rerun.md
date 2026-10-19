# Canonical train: repaired non-browser gate receipt

Task: `MT-RERUN-TRAIN`. **All five applicable non-browser gates pass on the repaired candidate.**

This completes the local source/check handoff from the
[retained-source recovery sequence](../tasks/held-offline-recovery.md#recovery-sequence).
Coordinator integration and the separately indexed browser phase are not implied.
The [required checks](../../CONTRIBUTING.md#required-checks) remain authoritative;
no [remaining train gate](merge-train-shell-status-bar.md#remaining-gates) is waived.

## Captured execution input

Preflight before Flutter commands:

| Command | Exit | Output |
| --- | ---: | --- |
| `git rev-parse HEAD HEAD^{tree}` | 0 | HEAD `e128e09a4552207951f8b4a5df0109badf2e8e40`; base tree `7c24de257d12a9d127ceaa4338eb45d153c338c8`. |
| `git status --short --branch` | 0 | Clean `autowork/MT-RERUN-TRAIN`; no preserved overlay was present in the refreshed workspace. |
| `git merge-base --is-ancestor 80e41ed8 HEAD` | 0 | Compatible-lock commit is an ancestor. |
| `git rev-parse HEAD:pubspec.lock` | 0 | `8a84003a7a7b1fbc26f25e2e09892baec2e6e66d`; working lock matches. |

The existing assembly was recovered directly from its immutable Git tree, **not
rebuilt from producers**. Its patch from `35d7976a` to
`a2213ffd78bf6a485e09de0d218cc617f273a78e` matches SHA-256
`1c169ec1c114a01213ace13f55d17d3de9516ddf60f4281656abd40ce2c3d886`.
All 737 source-closure members matched before any correction was applied.
The original 47-file assembly remains byte-identical to that delivered tree.

Only the two assigned existing-owner corrections were then collected. Both
producer slots were held with inactive recorded worker birth identities; their
reports and file hashes were captured read-only and rechecked around adoption.
No producer worktree, queue snapshot, admission pin or coordinator ledger changed.

| Existing repair | Paths | Exact patch SHA-256 |
| --- | ---: | --- |
| `PARITYUPDATE-005-11` | 2 | `a93d24bea9d2f940d4a37122767c1373d07b5d20814fa3d3c76cee70a1707a9c` |
| `PARITYUPDATE-006-f4` | 5 | `7f10ba76058a050437142389cf151c29ce70e82d77d9fa1a7745742b6fa32e5c` |

The Profiles correction keeps the already-eager inventory/search mounted as one
scroll child with grouped keyboard traversal; the existing public-seam test now
also requires the same FocusNode after Tab/Shift+Tab. The footer correction matches
the actual alpha-composited painted border, retaining the minimum 24 pixels and
adding a rendered missing-focus negative control. Its validator explicitly rejects
both zero and 23 pixels. No assertion was weakened or novel feature repair added.

## Frozen repaired source identity

- **Checked tree:** `9f02da853b3e63732c50d26140b7247896e67f9c`.
- HEAD plus **54 attributable paths**: original 47, Profiles repair 2, footer
  repair 5. The actual index remained unchanged during checks; the tree was
  captured with a task-private index, not a merge or branch switch.
- Combined source patch SHA-256:
  `83ccc1e4194f80ec3ba553dcf019f552e9ec6e24ae5f786d6ef1f1da4c3a53b6`.
- Overlay fingerprint (sorted compact JSON of path → SHA-256):
  `25641d0049550c8db383a65bf24318e1d54bc7d56dca24400d5bf384ab263999`.
- **737-file runtime/test/browser/dependency closure**:
  `4c9f0dfb99ce972ce4e1f93ffd006eb96cca774ade9bce976da118fd17c75846`.
  Canonicalization is SHA-256 of ordered `path + NUL + Git blob ID + newline`
  from `git ls-tree -r` under `lib`, `test`, `integration_test`, `playwright`,
  `pubspec.yaml`, `pubspec.lock`, `package.json`, and `package-lock.json`.
- All **1,531 captured input hashes** stayed unchanged after every check.
  This receipt was added afterward; the final local commit differs from the
  checked tree only by this documentation file. Its identity belongs in the
  worker report, avoiding a self-referential receipt.

This is the matched repaired source handoff for Tab, parser, SSH and native
consumers. The supported coordinator integration/source-refresh path may consume
the local task commit; this worker did not modify consumer checkouts or their
assignments. An earlier source receipt is not silently repinned to these repairs.

## Environment and focused checks

Linux host; cached Flutter 3.44.2 / Dart 3.12.2 and Node.js 22.22.2 / npm 10.9.7.
Task scratch was disk-backed ext4 with over 2 GiB free. Existing versioned caches
were reused; no SDK installation or shared cleanup. Fixtures ran serially with
`AUTOWORK_PORT_BASE=20140`, within the assigned 20100–20199 range.

| Command / selection | Exit | Outcome |
| --- | ---: | --- |
| `flutter pub get --offline --enforce-lockfile` | 0 | Baseline lock unchanged; retained localization output unchanged. |
| Focused correction/Profiles/overlay/footer/parser selection, exact command in `checks.json` | 0 | **241 passed**. Includes all eight inventory keyboard cases, shell/overlay traversal, Profiles suite, painted-focus negative control and native runner validators. |
| `python3 -B integration_test/run_linux_profile_footer_native.py --self-check` | 0 | Strict receipt self-check passed. |
| `python3 -B integration_test/run_linux_shell_compact_return.py --self-check` | 0 | Shared harness self-check passed. |
| `flutter test --no-pub --concurrency=1 test/features/hermes_chat/ test/router/` | 0 | **2,014 passed**, terminal result in 664.10 seconds. |

No repository sharded check runner was available. Fresh repaired-source
Chat/router log SHA-256:
`bed7fec5caabd2951c6c66d126536707a394d5b39fca54ce73a18124b8624507`.
The unchanged count does not mean reuse of the older 2,014-case receipt: this
command was executed anew against the repaired source closure.

## Five canonical non-browser gates

Each command ran separately, once, on the same frozen repaired input on
2026-10-19 UTC. The full-suite subprocess limit was 1,770 seconds; it completed
normally within that bound. No timeout or partial aggregate is accepted.

| Exact command | Exit | Terminal outcome |
| --- | ---: | --- |
| `dart format --output=none --set-exit-if-changed lib test integration_test` | 0 | 619 files checked; zero changes. |
| `flutter analyze` | 0 | No issues found; dependency lock unchanged. |
| `flutter test --concurrency=1` | 0 | **4,044 passed, 9 skipped, 0 failed**, completed in 1,592.68 seconds. |
| `npm audit` | 0 | Found 0 vulnerabilities. |
| `git diff --check` | 0 | Whitespace clean; final receipt subsequently checked too. |

Full-suite log SHA-256:
`1ce1dbe12271fd7480565a910feaa7b9de52689eafa67bbad4f6d4e23dd54b56`.
The nine opt-in skips are reported as skips, not platform/live qualification.
Both previously failing public seams are now green in the completed full suite.

## Independent review

Fresh-context read-only review found no important/critical issue. It independently
reconstructed all three patches in memory, verified all 54 frozen path hashes and
1,531 input hashes, and checked exact producer attribution. It verified preserved
permission/owner/request checks, real Tab/Shift+Tab/Close behavior, same-FocusNode
assertion, actual painted pixels, strict negative control and receipt thresholds.
It ran the two validator self-checks, not Flutter/build/native/live gates.

Review SHA-256:
`090d23bd96535ceb718884852cdb95b06df7c9766bdc9b2dc660948fad9829dc`.
The previously stated direct held-successful-Stop owner-roundtrip coverage limit
remains a limit, not a new defect or additional test claim. Producer-native
receipts in the footer documentation remain historical/source-specific; they are
not native qualification of this repaired aggregate.

## Artifacts and remaining delivery boundary

Task-private `$TMPDIR/train-followup/` contains `handoff.json`,
`frozen-source.json` (all input/overlay hashes), `repair-members.json`,
`delivered-source.patch`, both exact repair patches, `repaired-source.patch`,
`checks.json`, complete terminal `.log`/`.exit` pairs and `review.md`.
The worker report records their exact local location and the final local commit.
The committed source, tree/closure/patch fingerprints and this receipt provide
source identity if scratch is later retired; scratch is not release evidence.

Earlier reports under Git-common `autowork-execution/slot-history/MT-RERUN-TRAIN/`
retain the historical failure/timeout and `a2213ffd` two-failure results. They are
not failures of this current green input and were not rerun while unchanged.
The SSH owner's subsequent 89-pass browser receipt resolved its old Tools
finding on its matched candidate; it is not a fresh browser receipt for this
new Profiles/footer input.

No web build/browser journey was run by this non-browser task. The indexed
`MT-VERIFY-BROWSER-GATES` phase retains its fresh-build-before-E2E checks on matching
source. No browser or canonical integration is waived or claimed here.

Only Linux-host Flutter widget/unit/loopback tooling and Python validator checks
were exercised. No new native desktop UI/GTK journey, physical device, microphone,
live Agent/provider, installation, signing, update, publication or retired service
Go operation was exercised or qualified. Android/live and platform acceptance
remain separate. No merge, rebase, branch switch, upstream edit or push occurred.
