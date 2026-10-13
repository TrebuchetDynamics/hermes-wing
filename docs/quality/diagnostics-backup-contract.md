# Diagnostics versus backup/import authority

Status: documentation-only contract trace for `DOC-DIAGNOSTICS-BACKUP-CONTRACT`,
goal `DIAGNOSTICS-RECOVERY`, native card `t_9bb080a8`. Independent same-card review
and coordinator integration are pending; the product goal remains partial.

## Verdict and evidence identity

Wing has no typed backup, archive-validation, import or rollback operation in the
inspected API/channel/Settings surface. Official Desktop does offer archive
creation through a fixed REST wrapper. The official Agent dashboard exposes typed
import routes, but **not an archive-wide atomic restore transaction**. Per-file
replacement, upload staging and ZIP publication are different guarantees. Neither
local diagnostics reads nor session restoration authorizes any of these writes.

- Immutable Wing base: `33bf89c0cac40a189d532187765da496715d0829` (the admitted
  origin/main candidate), initially clean and detached. Only this receipt is owned.
- Initial `pass_workspace.py` returned `worker_start_admitted`, exit 0, before
  design/tests/edits, with manifest SHA-256
  `31eff4dbcdeeef715f3a2da772f6a6e87b0e13bbbce856c93f30556469b56a0f`.
  Exact command, workspace and ordering are in the original native tool history;
  this paragraph is not a substitute for admission provenance.
- Official read-only Agent/Desktop reference:
  `158fd638da1629c8e62caf9ade1515d162def8ab`, clean at inspection. It is absent
  from this isolated workspace; the canonical reference was inspected in place.
  Agent root, CLI, Desktop and renderer instructions were consulted. No upstream
  tests or Agent operations were executed and no private state was read.
- Host execution: Linux `7.0.0-31-generic`, x86_64; Flutter `3.44.2`, framework
  `c9a6c48423`, engine revision `77e2e94772`, Dart `3.12.2`, Python `3.12.14`.
  Node `v26.7.0` differs from the recommended Node 22; no Node check/build ran.
  Existing cached dependencies were resolved offline with enforced locks.

## Wing: existing reads, not recovery writes

The [API client](../../lib/core/hermes/client/hermes_api_client.dart) and
[URI configuration](../../lib/core/hermes/client/hermes_api_config.dart) contain
no backup/import endpoints or archive operation models. The
[channel interface](../../lib/core/hermes/channel/hermes_channel.dart):70–75
explicitly calls `restoreSession` read-only exact recovery; its
[implementation](../../lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart):15–54
requires advertised authorized session/message GETs, explicit selected profile
and current owner/selection guards. It reads metadata/history into client state;
it does not extract an archive, restore Agent files or roll back configuration.

[Settings diagnostics](../../lib/features/settings/screens/settings_diagnostics_screen.dart):15–111
projects previously loaded channel state; :133–151 copies the bounded export to
Clipboard and reports clipboard failure. There is no backup/import control in the
inspected Settings tree. Reuse the
[diagnostics read receipt](diagnostics-read-contract.md) for detailed health,
redaction and ownership limits, not as new runtime qualification. That receipt's
privacy/clipboard gaps remain; this trace does not repair or retest them all.

The [parity inventory test](../../test/tooling/hermes_desktop_parity_contract_test.dart):6–28
only checks that the ledger contains the label `Backup/import`. It cannot prove
support, denial, atomicity or rollback, so it was inspected but not run as a
recovery oracle. No new capability, grant, adapter, shell/config bridge, fixture,
export format or credential migration is introduced. Saved Agent credentials and
exact endpoint/profile/session identities are untouched.

## Official operation trace

All upstream paths/line ranges below refer to the immutable
[official Agent/Desktop source](https://github.com/NousResearch/hermes-agent/tree/158fd638da1629c8e62caf9ade1515d162def8ab),
not the retired separate Desktop checkout. These are inspected contracts, not
operations callable through Wing's current advertised data plane.

| Stage | Actual fixed operation and binding | Limit |
| --- | --- | --- |
| Archive creation | Desktop `src/api/system.ts:305–312` `runBackup()` sends profile-scoped POST `/api/ops/backup` with `{}`. `src/app/command-center/maintenance.tsx:124–138,218–223` launches and tails an action, notifying that it started. Agent `hermes_cli/web_models.py:397–398` is `BackupRequest(output: Optional[str])`; `web_routers/ops.py:576–592` generates a profile-owned archive path by default and spawns `backup -o`. | Start receipt `{ok,pid,name,archive?}` is not archive completion, integrity or restore success. An optional caller-selected output path exists upstream; Wing must not adopt a host-path bridge. |
| Download | GET `/api/ops/backup/download`, `ops.py:595–611`, resolves the selected profile's backup directory and target, rejects outside-directory targets and non-files. | A path-based file download is neither a secret-safe diagnostics export nor write authorization. |
| Validation | Upload route checks ZIP container validity; CLI `backup.py:731–792` checks file/ZIP, recognizable backup markers and streamed decompression/CRC before extraction. `backup_restore.py:293–341` accepts marker basenames and detects an optional wrapper prefix. | No separate typed, non-mutating validate/plan endpoint was found in these routes. ZIP markers/CRC are not whole configuration/schema compatibility or an authenticated archive identity. |
| Import existing archive | POST `/api/ops/import`, `ops.py:614–630`, `ImportRequest(archive: str, force: bool=False)` at `web_models.py:400–404`. Requires archive presence/file existence; destructive profile check precedes spawn. Fixed child command is `import <archive>` with optional `--force`. | Archive is a server path, not an opaque authorized archive resource. `force` bypasses CLI overwrite confirmation, not validation. Spawned stdin is noninteractive; default false can abort an existing-config import. |
| Upload then import | POST `/api/ops/import-upload`, `ops.py:641–663`, multipart `file`, `force=False`, optional profile. Sanitizes filename, generates profile staging path, uses bounded streamed upload, rejects non-ZIP, then invokes the same import child. | `web_routers/files.py:653–694` bounds compressed upload bytes and removes failed temporary uploads. Atomic staging rename does not make extraction atomic, nor bound total expanded restore content. |
| Rollback | `backup.py:812–910,1047–1051` publishes members individually, accumulates failures, continues and returns 1 for incomplete import. | No whole-archive rollback, expected-state revision, durable idempotent restore receipt or transaction-status reconciliation is present in this route/model/import chain. Earlier successful replacements remain after a later member fails. |

No full-backup ZIP import wrapper/control was found in the inspected Desktop
`system.ts`, maintenance panel or exact `/api/ops/import` symbol search. Desktop
does ship a different profile-bundle import below; do not conflate these journeys.
These dashboard routes are also absent from the inspected
`gateway/platforms/api_server.py` capability/API implementation; their existence
is not an advertised Wing capability.

### Separate Desktop profile-bundle import

Desktop `src/store/profile-share.ts:137–142,189–217` picks a `.tar.gz`/`.tgz`,
calls `src/api/profiles.ts:108–117` `importProfileArchive(archive, name?)`:
POST `/api/profiles/import` with `{archive,name}`. Agent
`web_models.py:455–457` is `ProfileImport`; `web_routers/profiles.py:1106–1132`
imports a **new named profile**, best-effort creates a wrapper and returns
`{ok,name,path,desktop}`. This is not in-place ZIP disaster recovery. It uses
dashboard authentication, a server path and new-name identity, not a restore
grant, expected revision or existing-profile incarnation.

`hermes_cli/profiles.py:2329–2378` requires exactly one archive root, validates
the name, rejects `default` and an existing target, extracts to a temporary tree,
removes foreign PM/runtime roots, drops the incoming profile role and publishes
with `shutil.move`. `archive_safe.py:13–27,50–72` rejects traversal, links and
non-regular/non-directory members. Invalid staged extraction is not published;
however the temporary tree is not guaranteed to share the destination filesystem,
and `shutil.move` is not a universal atomic directory transaction. No explicit
concurrent name reservation, rollback of partial cross-filesystem publication,
durable replay receipt or transaction covering Desktop overlays is shown here.
Desktop overlay application (:85–135) is independent/best-effort and can alter
global layout; refresh/select after import is also separate from persistence.
The default-profile export test `tests/hermes_cli/test_profiles.py:1387–1410`
checks `.env` exclusion, not general content noninterference. Profile-bundle
export policy does not prove full ZIP backups are secret-free.

Nearest inspected, NOT_EXECUTED failure oracle:
`tests/hermes_cli/test_profile_pm_portability.py:100–169` denies staged runtime
removal, expects import failure and no destination, and otherwise checks removal
of foreign runtime with preservation of user files. Cross-filesystem publication,
concurrent same-name import and Desktop overlay rollback remain NOT_CHECKED.

### Authorization and resource identity

Dashboard `hermes_cli/web_server.py:686–727` owns HTTP authentication: OAuth gate
when enabled, otherwise session-token enforcement for non-public `/api/` paths;
the outer token-provider seam applies only to exact opted-in routes
(`dashboard_auth/token_auth.py:27–40,75–86`). This is not evidence that Wing's
Agent Bearer credential/grants can authorize dashboard import. No named
backup/restore grant or per-operation expected revision is declared in the
inspected request models/handlers. Do not invent `backup:write` or infer writes
from detailed health, config reads or a broad administration flag.

`web_routers/_common.py:61–84` rejects omitted destructive profile on a
multiplexed host (400), but preserves launch-profile behavior on a single-profile
host. `spawn_profile_action:104–111` and
`web_server_profiles.py:438–450` validate/normalize a named profile and pass
`-p <name>` to the child; this is explicit child selection, not global `profile use`.
Profile name/path checks are not profile-incarnation, archive-ID, payload-digest,
revision or crash-replay binding. `_external/` import members additionally restore
under the user's home, outside the selected Hermes home (`backup.py:812–839`).
That scope exceeds a profile-only recovery promise.

### Atomicity, validation and activation are separate

- ZIP publication: `backup.py:220–238,604–678` holds a backup-operation slot and
  stages a hidden sibling ZIP before `os.replace`. Per-file collection errors can
  still publish an incomplete archive, return false and suppress pruning. A
  completed filename is not an all-resource coherent snapshot or successful
  import; the backup slot is not a transaction shared by every domain writer.
- Ordinary member restore: `backup_restore.py:365–460` streams/fsyncs a sibling,
  replaces a resolved target, preserves owner/mode and drops setuid/setgid.
  Its documented EXDEV/EBUSY copy fallback truncates in place: even per-file
  atomicity is conditional, not a universal platform guarantee.
- SQLite: existing DB import `backup_restore.py:491–569` stages the member and
  calls `_safe_restore_db:158–290`, checking SQLite integrity before page-copy
  restore to preserve the live inode. Refused live-safe restores are reported,
  not counted as success. Missing-file branch uses ordinary member publication;
  do not claim the same DB-integrity preflight covers every new DB. Holder and
  fallback logic is inspected only, not live-qualified here.
- `_restore_auth_json:100–155` is a separate snapshot helper with auth-store lock
  and live single-use OAuth preservation. Full ZIP `run_import` routes non-DB
  members through ordinary extraction (:905), not that helper. Snapshot auth
  semantics must not be attributed to ZIP import or to Wing saved credentials.
- Import can recreate profile wrappers and conditionally install/start a gateway
  (`backup.py:960–1045`), best-effort and before the final incomplete result.
  Non-default-home protections do not imply a universally lifecycle-free import.
  Persistence, partial failure, activation and rollback must be reported
  separately. No lifecycle/restore action was run for this card.

## Denial, failure and recovery oracles

Inspected upstream tests, **NOT_EXECUTED**:

- `tests/hermes_cli/test_web_routers_destructive_profile_scope.py:196–227,257–271`:
  import/upload included in unnamed-multiplex denial table; 400 and zero seam
  dispatch. Named import spawn carries `-p` target. This is profile routing, not
  revoked caller, concurrent revision or durable replay coverage.
- `tests/hermes_cli/test_backup.py:600–631`: damaged CRC/decompression/truncation
  refuses before touching existing home. :652–687 instead injects member failure
  after preflight, expects exit 1, preserves successful earlier/later restored
  files and removes partial residue: explicit evidence against archive rollback.
- Same file :2746–2766: refused live-safe DB restore returns incomplete, avoids
  success wording and preserves existing row counts. :2564–2591 names profile
  targeting; adjacent non-default-home service tests distinguish activation.

Executed Wing check: existing
[Settings diagnostics tests](../../test/features/settings/settings_diagnostics_screen_test.dart),
12 passing fixtures, including clipboard success, duplicate guard and failure
without a success notice, small-screen/text-scale reachability and raw-error
exclusion. Clipboard and channel are fakes on Linux; these do not test backup
execution or real host recovery. No existing inspected Wing test discriminates a
typed backup/import gate because that operation is absent. Recovery authorization,
wrong-profile archive, disk-full/crash halfway through multi-file import,
concurrent config/credential edits, revoked caller, changed-payload replay,
rollback integrity and native/live recovery journeys remain **NOT_CHECKED**.

## Executed checks and scoped fingerprints

Initial commands all exited 0 (Flutter runner reported about one second):

```sh
flutter pub get --offline --enforce-lockfile
git diff --exit-code -- pubspec.lock package-lock.json
timeout 10m flutter test --no-pub --concurrency=1 test/features/settings/settings_diagnostics_screen_test.dart
```

Finish gate acceptance reruns the exact test argv, lock diff, source fingerprints,
tracked local Markdown target/anchor checks and `git diff --check`. Exact argv,
exit codes, finish commit and task ref are recorded on the native card. No generic
full suite, analysis or build is needed for this sole documentation change.
Review duration, inference usage and cost are unknown.

SHA-256 below binds inspected source/test bytes and unchanged dependency locks;
`Wing/` is relative to the admitted workspace, `Agent/` to the clean read-only
reference. The link/hash checker checks these bytes, not runtime correctness.

```text
Wing/pubspec.lock f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89
Wing/package-lock.json f32c4b4d226bf6cef1a1f66733d4c2e065e0656d1223e89f17ceb68f42429b63
Wing/lib/core/hermes/client/hermes_api_client.dart f94d1a8502646caeec1f4bd6b5d4fdc2a30b4b3074d457c47e6dc86b91b3b128
Wing/lib/core/hermes/client/hermes_api_config.dart ec818a5ee9de04b49c4657d97d0590f79d04a131c05e21e4a9783468d8e364cc
Wing/lib/core/hermes/channel/hermes_channel.dart f44163a082049959fdfc6bbaefc282cad0a75e2fd620b7d43ef2827643d6c0dd
Wing/lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart 148816aead97af644977509989ab4f30e580ec2a628566de2e18ffcc55f0081f
Wing/lib/features/settings/screens/settings_diagnostics_screen.dart 2996193593a092f1f6a759dfa9b815246a036617a84c53267b668c4406d14baf
Wing/test/features/settings/settings_diagnostics_screen_test.dart 6ab696b7e17b132d3902de9cc59775d8b904418abfc81100137a24f213a298c6
Wing/test/tooling/hermes_desktop_parity_contract_test.dart dd9114e47a187a514ed8eceaccf485eaf3ee2a04887f17b734d2bbb865c95bea
Agent/apps/desktop/src/api/system.ts 9e6502192ca57f8cc0894d7f4794f82c671b77a082c656244f3ce91e1c0f67ea
Agent/apps/desktop/src/app/command-center/maintenance.tsx 5df752a4ee16948f2284e140509bd2808c67cb03fa16523a1afcc631d1f7d4ba
Agent/hermes_cli/web_routers/ops.py 285424cc919eaef2eaea25fb36148cac6bad6c897afda09536e4daf2e4b70e2e
Agent/hermes_cli/web_models.py 1fb71cb7d0006e6e930f2bbf181135de806af71804b767dc70e919eadcbe0f17
Agent/hermes_cli/web_routers/_common.py b2efd010d9b8b61dd27f8a26ca23adcaba734d9efba5d35af9eafaaae04b6f73
Agent/hermes_cli/web_server.py 4ecf5264dc739dc7781956abb4c9f3702548f990831a1d599a191423a5dfdf57
Agent/hermes_cli/web_server_profiles.py 6a44ed1612233ee67cdf75cc56a33fb10e42403eda9d1abb42467661b203d0ce
Agent/hermes_cli/web_routers/files.py 693e180f309490a8b399ee49e98bc04707f52e298a78068a617b322295f95750
Agent/hermes_cli/backup.py 81df93726dcddc6738af802d2d29194e90b906de6aabab1ec5b667eb826cfc3e
Agent/hermes_cli/backup_restore.py e51230158e7a628c839f5768e25168aac2287e9f8ae37f75269bc68d3d71bbd2
Agent/tests/hermes_cli/test_backup.py d3bc6a9f7ba0553a9ba1aa181faceab5b7f0c4d1a7eb6d0ac92bcf6a75beb476
Agent/tests/hermes_cli/test_web_routers_destructive_profile_scope.py a2473dc312c1afed590212b3cc4be6c7cffd976c79e19fbe439aa41fa65c4fc7
Agent/gateway/platforms/api_server.py 8824f7a56d471cf25b5feb203fcf204d394c217b2b91c753a50287b4e4ec8189
Agent/apps/desktop/src/store/profile-share.ts 7b9725e770bdc7724723cbedb7c1377ac7062964de6e331931f9d415977b5813
Agent/apps/desktop/src/api/profiles.ts e1f09df4eb3feb711acd6317ab71667dbfffc7549fbdb6dc82b1bf1329b00e24
Agent/hermes_cli/web_routers/profiles.py e03c18782f7249a8765732bb47f3c7de8133f150bcdc64fe79e5488ca7e5f8f3
Agent/hermes_cli/profiles.py 836cba8f1273021900fc595a5309b1d4be929e2c25c13c6a137fad57d935d8dd
Agent/hermes_cli/archive_safe.py a59587bca0a200d3b2b4b360aa1736f5d99b457716bdf21b42df8bccc4cd0b54
Agent/tests/hermes_cli/test_profile_pm_portability.py 1e99b5dcbbfc5d2724edde59f2a6ad77a52a29b3b95921c4e9055aeb78a22fd0
Agent/hermes_cli/dashboard_auth/token_auth.py 74af1675db6bc7efccb0eedc845d19bb5f9a9468f43ad1df7e6e384858f405eb
```

Ponytail full applied directly: one receipt, reuse existing API/channel/diagnostics
and nearest test evidence, omit implementation, invented grants/transactions,
new dependencies, extra skill ceremony and additional review lanes. Connected
callers, models, fixtures, config and exports remain unchanged because no runtime
contract is changed. This is the smallest complete evidence slice.

## Coordinator closure proposal and next bounded outcome

After independent review of the exact finish commit/admission, coordinator `wing`
may close `DOC-DIAGNOSTICS-BACKUP-CONTRACT` as a contract trace only; retain
`DIAGNOSTICS-RECOVERY` partial and existing CONNECTION-PATHS claims/order. No
ledger was edited, follow-up card enqueued, canonical integration or publication
performed. Implemented: this trace. Qualified: Linux deterministic diagnostics
fixtures only. Delivered: not integrated or published by this worker.

Next bounded outcome proposal: assess an unmodified Agent release's exact
advertised recovery contract against explicit profile incarnation/archive identity,
secret-safe bounded validation, concurrent revision, all-resource commit/rollback,
crash reconciliation and separately authorized activation. Keep unsupported Wing
backup/import unavailable unless those contracts are present; do not patch Agent
or create a direct-file/command bridge. Native/live qualification is a separate
future slice, not permission to execute backup or restore now. Android, macOS,
Windows, browser, real clipboard and live Agent restore remain NOT_CHECKED.
