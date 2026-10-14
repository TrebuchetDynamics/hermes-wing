# Persona whitespace and completion evidence

Task: `t_7f735d79`; ledger proposal: `DOC-PERSONA-EVIDENCE`, goal `PERSONA`.
Status: current-source offline verification; independent same-card review pending.
This receipt does not close the PERSONA milestone or approve historical cards.

Conflict recovery has a separate [current-source attribution receipt](persona-conflict-evidence.md)
on `t_7a176ad4`: ordinary failure retains the draft, while 412 replaces it with
authoritative newer text before deliberate re-edit/retry. Its fresh acceptance
run on `c22c36e2e57c10e5d0f3a787469dcec6a8d1738f` failed two compact Profiles
modal-entry cases. Authorized same-card recovery adds one post-scroll settling
frame before the real pointer tap; the changed-input full five-target suite now
passes all 119 tests. Original failed receipts remain preserved. The older passing
matrix below is historical, not evidence for the recovery inputs or review approval.

## Admission and smallest complete change

The initial clean detached candidate was
`09d24908a170b534c54e948932e3ef28e668c0fc` (tree
`8fff5f196fc678ff6c7e30a882e14e73065b5f40`). Before tests or edits,
`pass_workspace.py` returned `worker_start_admitted` using the original
`pass-efebc396fa9a7431-89e98228244d42eb88e3c9d7a993960e.json` manifest,
SHA-256 `5474bc671f969c3bdb873020361f93ba61d2ee81e565f07fac62641015b3e4c3`,
and this card's isolated workspace. The original `persona-source.json` snapshot
SHA-256 is `18ea61925f6eb04fdefbb29f4274227df7ae5d417b03cc3e0ea7a900b8cda22f`.
The native run history retains the exact guard command and its ordering before
this receipt's creation; this paragraph is not a replacement admission record.
Planning context was read from the pinned manifest, not adopted into the candidate.

Decision (Ponytail full): execute existing integrated oracles and add this receipt
only. The actual-router oracle already exists and passes on the admitted source;
there is no missing regression or failing oracle authorizing a production repair.
Reuse the production decoder/client/channel, shared editor and router fixtures.
Omit duplicate tests, new controllers, backend adapters, configuration, dependencies,
exports and localization changes. No consumer, fixture or config needs modification.

The traced reach is decoder → API client → channel → shared editor → standalone
route and Profiles modal; the read-only Chat persona preview is another decoder
consumer. Existing ownership/fidelity tests and the actual-router fixture cover
these editing paths. This change adds no writes to user data and changes no caller.

## Current contract and executable oracles

All line references below describe the admitted candidate. Relative links are
repository navigation, not evidence of executing a live server.

| Outcome | Implementation | Executed oracle |
| --- | --- | --- |
| Literal read | [SOUL decoder](../../lib/core/hermes/models/hermes_profile.dart) lines 60–70 requires a string and preserves content; revision remains metadata. [Client](../../lib/core/hermes/client/hermes_api_client.dart) lines 596–615 sends explicit profile query context. | [Fidelity widget tests](../../test/features/profiles/profile_persona_fidelity_test.dart) lines 102–140 load exact text, unchanged Save makes zero writes, changed Save and fresh reload preserve UTF-8 bytes. [Decoder/client tests](../../test/core/hermes/client/hermes_profile_soul_fidelity_test.dart) cover spaces/tabs, blank lines, whitespace-only, empty, Unicode/combining marks and CRLF. |
| Save | [Shared editor](../../lib/features/profiles/widgets/profile_editor_sheet.dart) lines 391–495 captures content/revision/owner before awaiting, guards duplicate activation and completes only for the current owner. [Channel](../../lib/core/hermes/channel/api_channel/hermes_api_channel_profiles.dart) lines 265–300 gates exact operation, context, grants and revision. | [Actual-router tests](../../test/features/soul/persona_route_completion_test.dart) lines 317–369 assert one exact PUT, original origin/path/query, `If-Match: r1`, literal draft, pending route and disabled named Save/Cancel, then Profiles completion and authoritative reopen. |
| Unchanged Save | Shared editor compares literal content, not trimmed content; completion still occurs without a SOUL PUT. | Actual-router tests lines 195–208 assert Profiles landing, reopen and zero writes. |
| Conflict/failure | Shared editor rereads a still-current owner's SOUL on 412, shows bounded errors and never silently replays a mutation. | Actual-router tests lines 150–194 keep the route open on failure/412, redact raw error, require explicit retry and verify revisions `r1,r1` or `r1,r2`. Fidelity tests lines 142–175 preserve padded CRLF conflict readback and explicit retry bytes. |
| Cancel/read completion | [Standalone route](../../lib/features/soul/screens/soul_screen.dart) lines 41–47 and 78–87 supplies Cancel/Save callbacks, routing only while its page is current. Modal invocation retains the shared editor's `maybePop` default. | Actual-router tests lines 209–235 fence late read success/failure after cancel; lines 371–388 discard draft, land on Profiles and reread unchanged content with zero writes. |
| Embedded completion | [Profiles caller](../../lib/features/profiles/screens/profiles_screen.dart) lines 425–461 captures management/editor ownership and supplies no standalone completion override. | Actual-router tests lines 276–298 open the real Profiles modal and prove Cancel/Save dismiss only that modal, retain owner tuple and make zero/one writes. |
| Stale write/route exit | Shared editor's owner token and mounted checks fence old completion; standalone route additionally checks current page during exit transition. | Actual-router tests lines 236–275 cover old-host success/failure/conflict without changing newer draft, route or read count; lines 299–316 preserve the already-chosen Tools destination. |
| Admission/recovery | Malformed read cannot create a writable empty document; malformed successful acknowledgement is reported as failure, not rollback or permission to replay. | Fidelity tests cover invalid revisions, malformed types, explicit Retry and malformed acknowledgement. [Ownership](../../test/features/profiles/profile_persona_ownership_test.dart) and [production-client ownership](../../test/features/profiles/profile_persona_client_ownership_test.dart) tests retain exact capability and synchronous owner-change fences. |

The router fixture uses `container.read(routerProvider)`, the real
`HermesApiChannel`/`HermesApiClient` and production gateway directory; only transport
and endpoint storage are inert. It runs at 390 and 1280 logical pixels, height
1400, 200% text and reduced motion. It asserts the profile/session/provider/model/
connection/management/contact ownership tuple rather than assuming navigation is
ownership-neutral. Null fixture identities are not provider qualification.

## Historical receipts and review provenance

[The ownership runbook](../runbooks/persona-ownership.md) and
[route status](../product/routes.md) distinguish three historical cards:

- `t_294eb674`: documentation records executor78 → tester79 → reviewer80 acceptance
  of ownership repair. This is retained historical provenance, not newly verified
  review of the current candidate.
- `t_5881bb6b`: document fidelity is executor-verified; the tracked docs explicitly
  leave independent same-card tester/reviewer acceptance pending. Its named
  `.dart_tool/kanban-evidence/t_5881bb6b` directory was not available in the source
  checkout inspected in this run.
- `t_d393d318`: standalone completion is implementation-only, awaiting fresh
  independent same-card review. Its ignored source-checkout evidence archive is
  available. `handoff.json` explicitly says `implementation_only: true` and
  `same_card_independent_default_review_required: true`. It retains red/green
  Cancel, Save, route-exit and pending semantics evidence. No review artifact was
  found in that archive. Native `kanban_show` lookups for both follow-up cards
  returned not found on this board; absence is not approval or rejection.

For `t_d393d318`, selected archive members were checked against
`archive-manifest.json`: `source-hashes.json`, `handoff.json` and
`route-final-identities.json` all matched. The route case enumeration records
success at both widths. Its test hash and standalone screen hash match current
source, as do the decoder, profile channel and three fidelity/ownership tests.
However its API client, shared editor, router and `pubspec.lock` hashes differ.
Therefore historical broad-suite/browser receipts are NOT reused as current-source
qualification. Fresh focused checks below replace that inference; they do not
manufacture missing historical review acceptance. Current same-card independent
review must bind the finish-task commit/ref and original admission, not this
workspace's dirty union. Coordinator closure remains pending that review.

## Source and dependency fingerprints

SHA-256 at the admitted executable source; this card changes only this document.
The original snapshot's non-planning, existing-file fingerprints all matched.
The decoder/client/channel and decoder test below supplement that snapshot.

| Input | SHA-256 |
| --- | --- |
| `lib/core/hermes/models/hermes_profile.dart` | `ade05b101fddd56966a0e3622b1342e732b582c9b766f1237d24df38b94e4f74` |
| `lib/core/hermes/client/hermes_api_client.dart` | `f94d1a8502646caeec1f4bd6b5d4fdc2a30b4b3074d457c47e6dc86b91b3b128` |
| `lib/core/hermes/channel/api_channel/hermes_api_channel_profiles.dart` | `3ed77d6a01351a4fa8acdbb35f27f1dedd17b52a1014d6ca4fc40fec67b69082` |
| `lib/features/soul/screens/soul_screen.dart` | `1455386a1d648a7601cb8a01de8b5ed4ba55eae719bb1289aaa11eb868854406` |
| `lib/features/profiles/screens/profiles_screen.dart` | `11563eec7a32e96cbc9535db01928da4775f9a0fd2a9f8e49a4897576648892b` |
| `lib/features/profiles/widgets/profile_editor_sheet.dart` | `d77c47a65d53cf6481db521d8e3f0165943db3c862e5027f2aa9d1dd8d821200` |
| `lib/router/providers/app_router.dart` | `f00de1fb6c9810ac6817aff3434bb4a4a79262f8d99ed275810d1f3fa5b371db` |
| `test/features/soul/persona_route_completion_test.dart` | `e5801345894398bc2fed6ee7570d0fed8df700928ea6ef3afd553cf569c8bf6b` |
| `test/features/profiles/profile_persona_fidelity_test.dart` | `702ab732eda68a74a3daf12c2e938e8931db594422f1013be265979e6f32f129` |
| `test/features/profiles/profile_persona_ownership_test.dart` | `84ee82c99fac3f8fcfcb271f968a3e639881d1270ce60308a5c08657bfc5b5f3` |
| `test/features/profiles/profile_persona_client_ownership_test.dart` | `7d888b3ecc264b92243de2722fc1fc168affc8daa38347d75911eeeb4eb949b6` |
| `test/core/hermes/client/hermes_profile_soul_fidelity_test.dart` | `be1e01356471ba952fd898224e685192bd35ec0a749737c4e09963c11c935082` |
| `pubspec.lock` | `f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89` |
| `package-lock.json` | `f32c4b4d226bf6cef1a1f66733d4c2e065e0656d1223e89f17ceb68f42429b63` |

## Checks and qualification boundary

Executed on Linux with Flutter 3.44.2 framework `c9a6c48423`, Dart 3.12.2:

```bash
flutter pub get --offline --enforce-lockfile
# Exit 0; both lockfiles retained exactly.
timeout 5m flutter test --no-pub \
  test/features/soul/persona_route_completion_test.dart \
  test/features/profiles/profile_persona_fidelity_test.dart \
  test/features/profiles/profile_persona_ownership_test.dart \
  test/features/profiles/profile_persona_client_ownership_test.dart \
  --reporter expanded
# Exit 0; 92 tests passed, runner elapsed 10 seconds on initial execution.
```

The finish gate also runs the nearest decoder/client fidelity target, the same
four-target command, fingerprint/local-link checks and `git diff --check`; exact
argv/exit receipts and the attributable local commit/ref are recorded on this
native card. No Dart changed, so formatting/analyzer replay is not required for
this documentation-only delta. No failed acceptance run or product repair was
needed. Review time and model cost are unknown, not estimated as zero.

The read-only official Agent/Desktop reference was inspected at
`158fd638da1629c8e62caf9ade1515d162def8ab`. Its
`apps/desktop/src/plugins/hermes-bots/profile-config.tsx` reads SOUL through
`profiles.describe`, keeps textarea values and constructs dirty SOUL through
`ensureMessagingProtocol`. That is not Wing's advertised revision-aware contract.
The Agent dashboard `hermes_cli/web_routers/profiles.py` lines 991–1025 returns
`content/exists`, accepts `content`, writes atomically and returns `ok`; the
nearest `tests/hermes_cli/test_web_profile_soul_writes.py` covers interrupted
writes and retained mode/content. These were inspected, not executed. Similar
path names do not establish schema, scope, grant or revision compatibility. No
upstream adapter or Agent change is authorized or added. See the
[official reference boundary](official-desktop-reference.md).

Implemented: this source-bound receipt and its acceptance mapping; existing
persona behavior is unchanged. Qualified: only deterministic Linux Flutter
widget/unit journeys on the named source/toolchain and router dimensions.
Delivered: local task-ref commit only after finish gate; canonical integration
and remote publication are not performed by this worker.

NOT_CHECKED: fresh Chromium/browser keyboard or CRLF browser input, native desktop,
Android/device, real screen reader, live Agent saves/conflicts, provider inference,
full repository suite, distribution and official Desktop runtime parity. A
submitted write can finish at its original Agent after local ownership is lost;
fencing is not cancellation or rollback. PERSONA remains limited by independent
review and live/native/full-reference qualification, including the separately
tracked conflict qualification work. No canonical ledger transition is proposed
before required review acceptance. The suggested next owner-selected slice is
`DOC-M4-SCHEDULE-INVENTORY-EVIDENCE`; this worker does not enqueue or execute it.
