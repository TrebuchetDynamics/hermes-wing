# Linux shared regression qualification

This is the bounded shared-regression lane from the
[Linux campaign plan](../plans/2026-10-21-linux-feature-qualification.md), not a
full Linux support verdict. The [driver](../../scripts/run_linux_feature_qualification.py)
records source/tool/dependency fingerprints, exact commands, machine-reporter test
IDs/results, native process observations, log digests and owned cleanup in private
schema-1 receipts. Do not publish those receipts: they contain host paths.

## Selection and limits

The [native adapter](../../integration_test/linux_feature_regression_test.dart)
retains its existing selected app/feature/router/shared suites and adds current
Bot Chat channel/navigation, transcript encoding/Linux saving and paged-export UI
suites. Existing rich-transcript and slash-command suites include local timestamp
semantics and aliases. The [inventory regression](../../test/tooling/linux_feature_adapter_inventory_test.dart)
checks required current suites, import/registration correspondence, duplicates,
stale paths and aliases. Its machine-reporter output contains exact
`selected_suites` and `unselected_suites` paths from the current tree; an old
83-import comment is not coverage evidence. Unselected suites are **not native
qualification** and stay visible rather than being counted as passes.

The engine is real Flutter/GTK under X11/Xvfb; the selected service seams remain
deterministic. Preferences, secure storage and text input are mocked. File-selector
registration is reset to the method-channel seam mocked by the imported saver
suite: writes to disposable files do not qualify an actual native chooser.
The adapter preserves Android's existing `includeHostChecks: false` entry:
host source checks and the Linux-only saver suite are not run there. No Android
runtime qualification follows from this Linux lane.

The gateway Back cases establish whether the composer is focused. On desktop,
initial autofocus intentionally makes Back dismiss focus first. Navigation and
active-work guard assertions now explicitly start unfocused; the separate focused
case still verifies draft/owner retention and focus dismissal. No production Back
policy is changed.

## Complete bounded dispatch

Follow the [driver prerequisites](linux-qualification-driver.md#inspection),
including explicit reviewed dependency prefix, `PUB_CACHE`, Flutter 3.44.2/bundled
Dart 3.12.2, Node 22, private output and owned fixture ports. Resolve packages offline
without changing the lockfile. Use fresh output after any source/tool/input change.

The four **disjoint** native batches cover every case in the selected adapter:

| Batch | Selection | Child bound |
| --- | --- | --- |
| `core` | Inventory regression, then non-screen cases except the two timer-title families below | 900 seconds per child |
| `screens` | All `test/features/hermes_chat/screens/` cases | 900 seconds |
| `delete-timers` | All three `failed delete needs fresh typed confirmation:` cases in the profile editor | 1500 seconds |
| `create-timers` | Both `create failure clears credential and never replays:` cases in the profile editor | 900 seconds |

All five timer cases retain their **full six-minute observation** and assertions.
A live engine waits wall-clock time, unlike the host fake clock. They are neither
skipped nor shortened. Run these fixed batches as separate bounded commands when
one foreground command cannot accommodate the complete campaign:

```sh
python3 scripts/run_linux_feature_qualification.py --lane shared \
  --shared-batch core --output-dir "$TMPDIR/linux-qualification"
python3 scripts/run_linux_feature_qualification.py --lane shared \
  --shared-batch screens --output-dir "$TMPDIR/linux-qualification"
python3 scripts/run_linux_feature_qualification.py --lane shared \
  --shared-batch delete-timers --output-dir "$TMPDIR/linux-qualification"
python3 scripts/run_linux_feature_qualification.py --lane shared \
  --shared-batch create-timers --output-dir "$TMPDIR/linux-qualification"
python3 scripts/run_linux_feature_qualification.py --lane shared \
  --output-dir "$TMPDIR/linux-qualification"
```

Use the task's `autowork-run timeout ...` wrapper for long commands. Each batch
owns a separate snapshot, copied SDK/dependencies, build tree, Xvfb/D-Bus and state.
The final ordinary command validates matching terminal batch receipts and log
contents before joining them; missing batches are executed, never synthesized.
A batch-only pass is not a complete lane pass. Stale inputs, altered logs,
missing/overlapping/misselected native cases, failed results, skips or incomplete
cleanup cannot become a passing complete lane. Framework teardown entries remain
identifiable separately from product cases. Completed batches retain failure rows
and exact exits. An incomplete batch makes the join fail closed; its child receipt
and logs remain authoritative, and later unrun batches are not passes.

## Qualification record

Task `LINUXQA-001-dbb6605f` completed the selected offline fixture lane on Linux
GTK/X11 under Xvfb and headless Chromium, using Flutter 3.44.2/bundled Dart 3.12.2
and Node 22.22.2. The source-input SHA-256 shared by native and browser receipts is:

```text
e7f89940a1fa54f600879d673c3538ecbac9636d26537854ded82a73b290a849
```

| Check | Terminal result |
| --- | --- |
| Python driver regression module | 19 passed |
| Adapter inventory regression | 1 passed; 88 selected suites, all 88 observed at runtime; 132 explicitly unselected |
| Shared native `core` / `screens` | 776 / 350 cases passed |
| Native delete / create timer families | 3 / 2 cases passed, each observed for at least 360,000 ms |
| Native total | 1,131 product cases passed, zero skips |
| Reporter reconciliation | 1,141 selected IDs = 1,141 terminal IDs: 1,131 native cases, 1 inventory case, 9 hidden framework records |
| Compiled browser suite | 90 selected IDs = 90 recorded across all 9 default specs: 89 passed, 1 expected live-Agent skip, zero flaky cases |
| Gateway Back host-binding regression | All 3 adjacent Back cases passed; also included in the native screen batch |
| Full analysis / formatting | No analysis issues; 644 Dart files checked, zero formatting changes |

The skipped browser case is `regression/hermes-live-say-hi.spec.mjs` / “Hermes Wing
sends a say-hi turn through the live Hermes Agent”: no live target was configured.
It is not a deterministic fixture pass. Per-spec selected/actual JSON, raw reporter
IDs, exact unselected suite paths, log/receipt digests and five full-duration timer
observations are retained with the private task evidence. The shared join verified
all four batch receipts; owned process groups were gone and isolated states removed.
Numbers are scoped to this fingerprint, not a later integrated source or full-gate
speedup claim.

The whole Dart-suite check is owned by the runner on the merged tree and was not
run or claimed by this worker. These results do not mark that gate, PARITY or full
Linux qualification complete.

Real Linux keyring/persistence and chooser behavior, native IME/physical input,
Wayland, screen readers, microphone/acoustic behavior, actual Agent/SSH/provider
authentication and packaged install/upgrade/rollback retain their existing live
qualification gates. Browser compilation and mocked native-engine suites do not
close them or establish official Desktop parity.

Update this page when adapter imports, batch selectors, plugin mocks, receipt
validation or the corresponding focused suite inventory changes.
