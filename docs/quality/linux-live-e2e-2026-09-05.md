# Native Linux live E2E — 2026-09-05

This run uses the native GTK/Flutter Linux application under Xvfb, a real
isolated Hermes Agent gateway, a freshly built Wing Link server, and the user's
configured OmniRoute service with real inference. Provider configuration was
copied into an owner-only temporary Agent home. Production profiles, sessions,
schedules, and messaging integrations were not used as test state.

## Findings

- The configured OmniRoute systemd user service was failed and its loopback
  endpoint refused connections. Starting the existing service restored inference.
  Wing Link then identified the real service as `authentication_required`.
- Both new setup HTTP handlers worked, but protocol metadata filtered their
  optional capabilities out. Native Wing consequently refused to call them.
  Added `profiles.model-options.read` and `host.omniroute.discover` to the
  protocol allowlist and a regression checking the real server's `/meta` response.
- Native UI polling must await network completion independently of animation
  frames. The live profile test uses explicit bounded completion conditions.
- Two enrollment tests expected an obsolete desktop-only recovery action.
  Initial intent failures now expose the same paste entry action on all targets;
  those assertions were updated.
- Three diagnostics tests tapped before the native scroll layout completed;
  waiting for the layout restored actual hit testing.
- Router tests running Android layout variants in the Linux engine now explicitly
  provide an empty Android intent event channel. These tests cover navigation,
  not the Android native plugin.

The initial complete native inventory ran 990 cases: 981 passed and the nine
harness failures above were corrected. A native rerun of all nine passed; the
three affected unit/widget suites also passed (82 tests).

## Reproduce the real-service tests

[Run script](../../scripts/run_linux_live_e2e.sh) requires two owner-only JSON
manifests and a matching isolated host service. It fails when manifests are
missing; it does not silently substitute fixtures or skip qualification.

- `WING_LIVE_PROFILE_MANIFEST`: nonempty array of objects containing `origin` and
  `token` for the isolated Agent profiles.
- `WING_LIVE_LINK_MANIFEST`: the response from a real local pairing exchange,
  after credential acknowledgment; includes `wing_link_origin` and
  `wing_link_token`.
- `WING_LIVE_LINK_BINARY`: matching Wing Link executable used for local approval
  of deletion of the test-created profile.
- `WING_LINK_STATE`: the isolated host's state file.

```bash
bash scripts/run_linux_live_e2e.sh
```

Credentials belong only in protected runtime files or process environments.
Never put their values into this document, command arguments, source fixtures,
screenshots, or a commit. This run reused extracted Linux build dependencies via
`PKG_CONFIG_PATH`, `CPATH`, `LIBRARY_PATH`, and `LD_LIBRARY_PATH`.

## Scope and limitations

The live tests cover real catalog/discovery, profile cloning and lifecycle, chat,
session CRUD/fork/reconnect, inventory reads, steering, and cancellation without
replay. They do not provision a fresh authenticated OmniRoute credential; that
operation remains unsupported in Wing. A native UI test selecting a catalog
suggestion does not prove credentials for every listed provider.

The broader native feature runner uses deterministic service seams and is
reported separately. These runs do not qualify a physical display/input device,
microphone, speech recognition, sound output, or signed distribution.

## Verified results

| Check | Result |
| --- | --- |
| Real Linux Agent UI chat, session lifecycle/reconnect, steer/stop | 3 passed through real OmniRoute inference |
| Real Linux Wing Link UI: catalog suggestions, discovery, create/rename/delete | 1 passed; real local deletion approval and authoritative cleanup verified |
| Complete native feature inventory | 990 exercised: initial 981 passed / 9 failed; all 9 corrected cases passed in the native recovery run |
| Affected enrollment, diagnostics, and routing unit/widget suites | 82 passed |
| Provider catalog widget/unit suite | 6 passed |
| Wing Link | `go test -race ./...` passed |
| Real Linux Secret Service persistence | Write and verify passed in separate native app processes via `scripts/run_linux_secure_storage_regression.sh` |
| Static validation | `flutter analyze`, shell syntax, and `git diff --check` passed |

The successful real-service command was `bash scripts/run_linux_live_e2e.sh`.
The broad native command was `flutter test -d linux
integration_test/linux_feature_regression_test.dart --reporter expanded` under
Xvfb; its nine failing cases were rerun using `--name` after their test fixes.
The broad inventory and corrective rerun are separate receipts, not a claim that
the first full run was clean. Native and unit counts overlap and must not be
added as unique feature counts.

Cleanup verified that only the isolated default profile remained. The isolated
Agent and Wing Link processes were stopped and their temporary provider
configuration, credentials, and runtime state were removed. The pre-existing
OmniRoute user service remains active after recovery. No commits or pushes were
made; the shared worktree contains other ongoing changes.
