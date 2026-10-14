# Persona conflict recovery evidence

Task: `t_7a176ad4`; ledger task `DOC-PERSONA-CONFLICT-EVIDENCE`, goal `PERSONA`.
Status: source inspection and focused offline execution; recovery acceptance passed,
pending exact-candidate independent native review. Original failures are retained below.
No review approval, milestone closure, canonical integration or publication is claimed.

## Admission, scope and attribution

The clean detached candidate was `c22c36e2e57c10e5d0f3a787469dcec6a8d1738f`.
Before tests or edits, the pinned `pass_workspace.py` returned
`worker_start_admitted` for the original isolated workspace and
`pass-0c54e2ba0efdc023-5d6f2498dbd7420695123e52144e3311.json`, SHA-256
`060fbf288596b254e04f0ec3b6293e20e4f0a32e3b358279f61f08e3174b2590`.
The runtime manifest SHA-256 is
`b117f8dd7b6215063f34e9154476b3cf89011ef72b74e7272429e8134adb458a`.
The original native run retains the command, successful result and pre-edit ordering;
this document does not replace that admission evidence.

Original decision (Ponytail full): reuse existing oracles and write this receipt plus
an attribution link in [the completion receipt](persona-completion-evidence.md).
The read-only reach is decoder → API client → profile channel → shared editor →
standalone Persona route / Profiles modal. Tests and inert transport fixtures are
reused. The coordinator subsequently authorized one modal-entry settling correction
in the actual-router test, after the original docs-only run failed. Production,
dependency, localization, export and config remain unchanged. No user data is written.

Conflict recovery is not literal whitespace fidelity. Nor does every rejected
save preserve its draft: ordinary write failure retains the same-owner draft;
412 reconciliation replaces it with authoritative newer content. Owner changes
intentionally discard the volatile draft. Preserving the rejected draft alongside
412 readback is not implemented or proved by these oracles. This is an attribution
gap if that stronger outcome is required, not permission to add a new mechanism.

## Contract and executed oracles

References describe the admitted candidate, not a live Agent contract.

| Outcome | Inspected implementation | Executed oracle / limit |
| --- | --- | --- |
| Exact owner | [Shared editor](../../lib/features/profiles/widgets/profile_editor_sheet.dart) lines 103–185 captures mutation and Persona owner tokens. Persona source includes channel, origin, selected profile, connection/selection state, edited profile and exact eligibility; modal admission additionally observes management ownership. `_ownsPersona` rechecks synchronously. | [Ownership tests](../../test/features/profiles/profile_persona_ownership_test.dart) exercise same-frame host/profile/authority roundtrips, management replacement, stale read/write and disposal. [Production-client tests](../../test/features/profiles/profile_persona_client_ownership_test.dart) fence old-host reads and bind submitted writes to original owner. These cases passed. |
| Exact revision / authority | [Channel](../../lib/core/hermes/channel/api_channel/hermes_api_channel_profiles.dart) lines 265–300 requires exact GET/PUT operation/path/grants, supported profile query context and nonblank revision. [Client](../../lib/core/hermes/client/hermes_api_client.dart) lines 596–615 sends explicit profile query, literal `{soul: ...}` and `If-Match`. Editor lines 391–467 freezes owner/content/revision before awaiting and denies duplicate Save. | Actual-router pending-save and production-client ownership cases passed; exact method/path/operation/schema/context/additional-grant denial cases passed. This proves client gating, not server-side transactional enforcement. |
| Ordinary rejected save | Editor lines 478–495 reports bounded `profileOperationFailed`, retains draft/revision for the current owner and does not navigate or replay. | [Actual-router tests](../../test/features/soul/persona_route_completion_test.dart) lines 150–194 (`conflict=false`) passed at 390/1280px: exact draft retained, one write before deliberate retry, private raw error absent, retry uses `r1,r1`, then authoritative reopen. |
| 412 reconciliation and messaging | Editor lines 899–900 recognizes only `HermesApiStatusException` status 412. Lines 480–492 reread SOUL before displaying `profileRevisionConflict`; [English copy](../../lib/l10n/app_en.arb) says the profile changed elsewhere and the latest version has been loaded for review. Channel lines 303–328 refreshes current-host profile inventory on 412 and rethrows; this is not a mutation replay. | Actual-router `conflict=true` cases passed at both widths: editor remains open, newer authoritative text replaces rejected draft, bounded conflict message appears, one write precedes explicit re-edit/Save, revisions are `r1,r2`. |
| Conflict read failure | `_loadPersona`, editor lines 302–329, clears content and writable revision before reading. Failed reconciliation cannot admit stale writable text. | Ownership tests lines 547–574 passed: rejected draft absent, Save disabled, field disabled, deliberate Retry rereads, subsequent explicit Save uses new revision. Retained rejected-draft recovery is not proved. |
| Owner changes during conflict | Editor rechecks owner after both failed write and awaited reread; obsolete completion cannot alter replacement owner or route. An already-submitted request is not cancelled. | Ownership tests lines 575–597 and actual-router lines 236–275 passed: new-owner content/draft survives old conflict, no stale conflict/error or extra replacement read. |
| Literal fidelity (separate evidence) | [Decoder](../../lib/core/hermes/models/hermes_profile.dart) preserves a required literal string. This says nothing by itself about conflict recovery or retry intent. | [Fidelity tests](../../test/features/profiles/profile_persona_fidelity_test.dart) lines 142–175 passed: padded CRLF newer text remains exact, no replay after settling, explicit re-edit retries with `r2`; subsequent reload reads draft at `r3`. Decoder/client tests passed for empty/whitespace/Unicode/CRLF and malformed responses. |
| Actual Profiles modal | The shared editor remains the modal caller's implementation. | Original modal Save/Cancel passed at 1280px but failed at 390px / 200% before entering the editor. Recovery settles the scroll frame before the real pointer tap; both widths and both actions now pass with unchanged completion, ownership, write-count and content assertions. |

## Original checks and acceptance failure

Linux Flutter widget/unit execution used Flutter 3.44.2 framework `c9a6c48423`,
Dart 3.12.2. Router cases use 390/1280 logical pixels, height 1400, 200% text
and reduced motion with the real router/channel/client and inert transport/storage.

```bash
flutter pub get --offline --enforce-lockfile
# Exit 0; locked cached dependency resolution, no install/upgrade.
flutter test --no-pub --concurrency=1 \
  test/features/soul/persona_route_completion_test.dart \
  test/features/profiles/profile_persona_fidelity_test.dart \
  test/features/profiles/profile_persona_ownership_test.dart \
  test/features/profiles/profile_persona_client_ownership_test.dart \
  test/core/hermes/client/hermes_profile_soul_fidelity_test.dart \
  --reporter expanded
# Failed: 117 passed, 2 failed; runner elapsed 18 seconds.
```

The failed cases are `actual Profiles modal Cancel dismisses only modal at
390.0 / 200%` and the matching Save case. At test line 286 the Edit tap targets
an off-screen center below the 1400px viewport; line 288 expects one
`ProfileEditorSheet`, but finds none. Both conflict/non-conflict standalone
router cases and all fidelity/ownership/client targets pass in that same run.
The changed current Profiles screen prevents inheriting the earlier all-pass
router claim. This card neither repairs the product nor weakens/filters the
required suite; the coordinator must route the out-of-scope regression repair.

The initial shell command printed lock hashes after the runner and consequently
returned shell exit 0; the runner explicitly reported failure. That wrapper exit
is not acceptance. The mandatory finish gate must execute the test argv directly;
a `validation_failed` result is not a committed/review-ready candidate. Pending
independent exact-candidate review is separate from this failed check.

The pinned `finish_task.py` was executed with both owned docs and the full
required test argv, not a filtered subset. It returned `validation_failed`,
exit 1: offline dependency resolution, local-link checks (26 links), lockfile
identity and `git diff --check` passed; the test command returned 1 with the
same 117 passes / two compact modal failures (runner elapsed 16 seconds).
Ignored `t_7a176ad4/finish-task.json` and `finish-task.log` retain the exact
argv/exits and output. No task ref was created and HEAD remained the admitted
base. Both docs remain uncommitted in the isolated workspace for original-card
recovery; commit and native review are blocked by the out-of-scope failure.

## Same-card recovery and changed-input checks

Before the first recovery edit, the private `persona_reentry.py` and
`persona-reentry-pins.json` hashes matched respectively
`2e88a8f3625757b9117149d00152b9ae72bb62372314ee330a688833b51404d7` and
`8ea3d84e8fa48cd82c16d67369415a2f6656b4495a98aaa1f28615d4b2d6596b`.
The helper admitted the original workspace/HEAD/manifest/index/foreign-file/blobs.
This is cooperative source consistency, not a sandbox or retrospective initial admission.
The original failed finish receipts are retained as
`original-failed-finish-task.json` and `original-failed-finish-task.log` in the
same ignored evidence directory; recovery does not replace their failed result.

Diagnosis: `WidgetTester.ensureVisible` delegates to `Scrollable.ensureVisible`;
its zero-duration `ScrollPosition.ensureVisible` calls `jumpTo`. Awaiting that
future does not render the next layout frame. The test tapped the old off-screen
geometry immediately. One `pumpAndSettle` after `ensureVisible` fixes both compact
modal cases with a real pointer tap; no product scrolling defect was demonstrated.
The viewport, text scale, coverage, warnings and assertions remain unchanged.

Ponytail: source=the frozen bundle's `autowork/references/ponytail.md` fallback;
decision=settle existing scroll before tap; reuse=actual-router modal matrix and
Flutter test API; omitted=production repair, duplicate oracle, callbacks, dependency
or config additions; check=full five-target suite, 119 passed (17 seconds).

Recovery reran the full five-target command above, unchanged in arguments:
exit 0, all 119 tests passed. `flutter pub get --offline --enforce-lockfile`
passed; both lockfile hashes below remain unchanged.
`dart format test/features/soul/persona_route_completion_test.dart` reported
one file, zero changes; `flutter analyze --no-pub` reported no issues (8.1 seconds).
`git diff --check` passed. The ignored `recovery-tests.log` retains runner output.
The shell's first log-tail display had a Python syntax error after the successful
test command; a corrected readback verified the explicit 119-test pass. It is not
a substitute for the direct test argv rerun in the mandatory finish gate.

Recovery actual-router test SHA-256:
`df85b622e1b7eeb0ca17e26104b1f7e75d8fa2ab7bab2f55d729861b28f99555`.
All other executable source fingerprints below remain the original inputs.
Finish-gate argv/exits and exact committed task ref are recorded on this native card;
only a successful finish receipt permits independent review handoff.

## Original source binding and retained history

Original `persona-conflict-sources.json` SHA-256:
`6b296bd544396d64add48da0d9728b0b519a9d6c6c1434e2ebbcdc573c9fd014`.
Every non-planning snapshot fingerprint matched before edits; `TODO.md` and
`goals.json` were excluded from that comparison and were not changed.
The snapshot binds the editor, callers, decoder/client/channel, all five targets,
manifest and lockfile. The recovery test input is separately fingerprinted above.

| Input | SHA-256 |
| --- | --- |
| Current Profiles screen | `8cdadaf189bcca47ca866f3d1d11ed3b40d1f8babd354bd09e8cf55c78da2c10` |
| Shared editor | `d77c47a65d53cf6481db521d8e3f0165943db3c862e5027f2aa9d1dd8d821200` |
| Actual-router test | `e5801345894398bc2fed6ee7570d0fed8df700928ea6ef3afd553cf569c8bf6b` |
| `pubspec.lock` before/after | `f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89` |
| `package-lock.json` before/after | `f32c4b4d226bf6cef1a1f66733d4c2e065e0656d1223e89f17ceb68f42429b63` |

Historical attribution remains as recorded in [the ownership runbook](../runbooks/persona-ownership.md):
`t_294eb674` is the independently accepted ownership predecessor;
`t_5881bb6b` records whitespace fidelity, with its named ignored archive absent
from the inspected checkout. Absence is neither approval nor rejection.

The ignored `t_d393d318` archive is available. Selected `handoff.json`,
`source-hashes.json`, `route-final-identities.json`, conflict keyboard receipts at
390/1280px and the 390px ordinary-write-failure receipt all match their archive
manifest SHA-256 values. The handoff explicitly remains implementation-only and
requires independent review; no review member occurs in its manifest. Its route
enumeration records earlier conflict/non-conflict success at both widths. Sanitized
keyboard receipts distinguish 412 newer-content reconciliation from 503 draft
retention, record no automatic retry/duplicate activation, and retain exact
request/response readbacks. Their stated browser input limit is LF, not CRLF.
These are inspected historical deterministic receipts, not fresh browser execution
or approval of this candidate. Earlier differing source/dependency hashes and the
current failure forbid reusing historical broad/browser passes as current proof.

## Qualification boundary

Implemented: conflict-specific attribution, explicit retention limits, historical
failure evidence and the one-line test settling correction; no product behavior
change. Qualified: the full requested deterministic Linux widget/unit suite on the
recovery inputs, not live/native use. Delivered: attributable local task-ref commit
only after the successful finish gate; independent review, canonical integration
and publication remain separate and are not claimed here.

NOT_CHECKED: fresh Chromium/keyboard/browser CRLF, native desktop, Android/device,
real screen reader, live Agent concurrency/saves, upstream compatibility, provider
inference, full repository/release gates or distribution. Historical official
reference findings in the completion receipt remain source-only, not a verified
revision-aware deployed API. Owner fencing is not server cancellation or rollback.
PERSONA and live/full-reference qualification remain open. Required next action is
independent native review of the exact finish commit, then coordinator disposition;
the passing recovery suite does not manufacture independent acceptance.
