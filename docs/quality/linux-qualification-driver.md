# Linux qualification driver

The developer-only [driver](../../scripts/run_linux_feature_qualification.py)
implements the entrypoint in the [campaign plan](../plans/2026-10-21-linux-feature-qualification.md).
It does not install dependencies, admit live testing or establish Linux support.
The driver tests use synthetic filesystem/process results, not installed GTK,
Node, an Agent, a provider or a display.

## Inspection

```sh
python3 scripts/run_linux_feature_qualification.py \
  --lane preflight --output-dir "$TMPDIR/linux-qualification"
```

A completed inspection exits **0**, including when `preflight.json` says
`ready: false`. Read its `errors`. This is not native qualification. Unsafe
outputs, incomplete inspection or a mismatch against an existing campaign exit
nonzero. Runtime lanes require readiness before children start. Missing later
Dart targets do not prevent inspection and block only their selected lane.

Requirements:

- Python 3.11+, Flutter 3.44.2 with bundled Dart 3.12.2, and Node 22 on PATH.
  Inspection reads SDK metadata and performs fixed Dart/Node version queries;
  it never invokes Flutter, GTK, SSH, providers or installers.
- Checkout-local package config/graph/plugin metadata, resolved offline without
  lockfile changes. Provide `PUB_CACHE` explicitly for non-SDK roots. Names,
  versions and the graph/lock must agree. Direct constraints use Wing's current
  block-mapping exact/caret syntax; other formats fail closed, not a guessed
  general YAML resolver. Effective package import URIs must exist inside their
  attributed roots. Unrelated directories and escaping links are rejected.
- A reviewed, user-owned, non-publicly-writable **usr directory**, provided with
  `--dependency-prefix` or `WING_LINUX_DEPENDENCY_PREFIX`. There is no private
  absolute-path fallback. Its GStreamer/libsecret metadata must reference that
  same prefix, with headers and x86_64 ELF libraries present. GTK >=3.24,
  GStreamer >=1.18 and libsecret >=0.20 metadata and GTK library/header inputs are
  inspected. This is not proof of ABI loading or successful native behavior.
- A dedicated private output child of `TMPDIR`, outside source, SDK and caches.
  Nonempty output requires the matching ownership marker. Source, tool or
  dependency changes require a fresh output directory, never repinned evidence.

SDKs are copied before Flutter can acquire locks or alter caches. Absolute,
broken or escaping SDK links are refused. SDK control/engine inputs are pinned
at inspection and checked against the copy and original before terminal success.
No system installation, dependency download or shared SDK mutation is offered.

## Fixed lanes

| Lane | Dispatch |
| --- | --- |
| `preflight` | Inspection only |
| `shared` | `test/tooling/linux_feature_adapter_inventory_test.dart`, then `integration_test/linux_feature_regression_test.dart` |
| `connections` | `integration_test/linux_connection_feature_qualification_test.dart` |
| `chat` | `integration_test/linux_chat_feature_qualification_test.dart`, then the local-serve-read and transcript-keyboard Python runners |
| `management` | `integration_test/linux_management_feature_qualification_test.dart` |
| `access` | `integration_test/linux_access_feature_qualification_test.dart`, then the compact-return Python runner |
| `report` | `scripts/check_linux_feature_qualification.py --phase fixture --input <output-dir>` |

The report lane is read-only checker delegation, not native execution; it can
run without GTK readiness, but requires its checker and matching campaign inputs.
Later tasks own the proposed targets/checker. No arbitrary command, target or live
mode is accepted. Historical live/installer wrappers are never implicit children.
The runner's whole-suite gate and separately admitted browser/native/live checks
remain separate; this registry is not a claim that every planned check has run.

Children receive a current-source snapshot, copied SDK/packages, relocated native
prefix and private HOME/XDG/cache. New Dart native targets use an owned Xvfb
and D-Bus session; the older Python runners create their own Xvfb display and
reject inherited D-Bus. Inherited credentials, proxies, loader/startup injection,
display and D-Bus are absent.
Nonempty `LIVE`/`PRODUCTION` opt-ins are rejected without opening their values.
This is process/state isolation, **not a network sandbox or live authorization**.
The transcript runner uses the task-owned `AUTOWORK_PORT_BASE` with DDS disabled.

## Receipts and cleanup

Private `campaign.json` binds source revision, current file/tree hashes, tools,
package identity and native dependencies. `<lane>.json` contains readiness,
commands/exact exits, log digests, case/suite/runner records and cleanup. These
files contain private paths; do not commit or publish them. Paths and digests are
printed for private task reports. Each attempt starts at `not_run`, so interruption
cannot retain a previous pass. Original and executed-input drift fails validation.

New native targets atomically rename `feature-cases.json` directly under
`WING_LINUX_TEST_ROOT`, while their GTK PID is still alive for group observation.
The private root is `wing-linux-qualification-<suffix>`, directly under the child's
`TMPDIR`, matches HOME/XDG and has `.wing-linux-test-owner`. The document contains
integer `schema: 1` and a nonempty `cases` list. Each row supplies:

- unique nonempty `id`, nonempty string lists `feature_ids` and `route_ids`;
- nonempty `backend`, `input` and `storage` classifications;
- terminal `status`: `pass`, `fail`, `not_run`, `unsupported` or `coverage_gap`;
- a string `skip_reason` for non-run/unsupported/gap rows;
- `negative_assertion: true` for unsupported rows;
- positive integer `native_pid` and `owner_count`, and nonempty
  `operation_counts` with nonnegative integer values (never booleans).

The driver adds command index, artifact/log digest and observed process identity.
Unsupported negative assertions never establish positive feature support.
Failed/non-run/gap rows cannot produce a passing runtime lane.

The existing shared adapter does not need to invent feature-case rows. Its
`suite_runs` records contain actual machine-reporter test identities/results,
target/source/log digests and observed native PID/start ticks. Starts and terminal
IDs must match exactly; duplicate, interrupted, hidden-loader-only, skipped or
failed inventories cannot pass. These deterministic mocked suites are execution
evidence, not an automatic feature/route completeness verdict.

The three existing runners retain their validators and publish terminal cleanup
on failures as well as success. Their verification JSON, native logs and other
top-level artifacts are retained under private output subdirectories before
cleanup. Nested native exits are retained separately from Python exits and
propagated, including negative signal results. A missing/failed nested cleanup
proof preserves the outer state: the runner group's exit does not prove its
separately owned native group exited. `cleanup.state` identifies the retained
relative directory; never remove it while an owned process survives. Interrupted
or cleanup-incomplete records cannot pass.

The final checker task owns feature/route/action joining and separate fixture
versus overall Linux verdicts. Physical keyboard/resize, Wayland/IME, screen
reader, audio, actual Agent/SSH/provider and packaged-artifact gates remain open.

## Offline checks

```sh
python3 -m unittest discover -s test/tooling -p linux_feature_qualification_runner_test.py -v
python3 -B integration_test/run_linux_shell_compact_return.py --self-check
python3 -B integration_test/run_linux_local_serve_reads.py --self-check
```

These validate harness behavior only. No native runtime pass is inferred.
