# Linux desktop uninstall and retained-state evidence

Status: source-pinned offline investigation; native uninstall **NOT_CHECKED**.
Task: `DOC-DESKTOP-UNINSTALL-EVIDENCE` / `t_c4c64224`.
Wing source: `52318ebada73a142af4a24c519b2650c6a1357d3`.

## Verdict and scope

The missing procedure is a current Wing Linux **client-only removal** path with
an attributable installed bundle/launcher inventory and explicit retained-state
policy. No such producer or named-target uninstall receipt was found in the
inspected current delivery paths. Removing an executable, retiring source code,
or passing archive checks cannot prove safe uninstall or credential revocation.
[DESKTOP-DELIVERY](../product/hermes-desktop-parity.md#statuses) remains partial.

This slice adds only this evidence map. It does not uninstall anything, inspect
personal host state, run an installer, change services, delete records or edit
Agent. It leaves the canonical ledger and unrelated endpoint-store changes to
the coordinator. The [predecessor delivery map](linux-desktop-delivery-evidence.md)
is reused as context, not counted as newly executed install/update evidence.

## Current Wing producer and consumer map

| Boundary | Inspected source | What is proved / missing |
| --- | --- | --- |
| Source install and update | [Linux installer](../../scripts/install_linux.sh):5–7, 18–25, 43–84 | Default bundle destination is `$HOME/.local/opt/hermes-wing`; launcher is `$HOME/.local/bin/hermes-wing`. Both can be overridden through existing environment inputs. This is a build/install path, not an uninstall mode; extra arguments are rejected. No installed ownership manifest or removal receipt is emitted. Defaults are source expressions, not observed user paths. |
| Installed inventory | Installer:63–84; [CMake](../../linux/CMakeLists.txt):89–139 | Installer copies the complete bundle, then writes a separate launcher. Bundle includes native/plugin libraries, Flutter/AOT and data/assets, not just `wing`. A future removal procedure must identify the actual installed generation and launcher, not assume defaults or remove every matching directory. CMake build-bundle cleanup is not installed-client uninstall. |
| Existing deletion branches | Installer:65, 74–80 | EXIT cleanup removes staging; activation failure may rename backup back; successful activation deletes the previous bundle before launcher creation. These are installation housekeeping, not user-state cleanup or a verified uninstall transaction. No installer execution occurred. |
| User-facing instructions | [Getting started](../getting-started.md):50–56 | Documents build/install and launcher setup, not a qualified Linux removal/retention procedure. No `*uninstall*` script exists under current `scripts/`; a scoped `uninstall` search in `lib/` found no client removal surface. This bounded search is not a claim about every external package manager. |
| Release smoke and publication evidence | [Verifier](../../scripts/verify_release_artifacts.sh):211–234, 271–284; [aggregator](../../scripts/release_evidence.mjs):166–179 | Linux smoke extracts an archive, runs `bundle/wing` under Xvfb for five seconds, checks PID and kills it. Host receipt check set includes `linux_bundle_launch`, not installed removal or retained-state observations. No verifier, release publication or native bundle was run here. |
| Retired lifecycle receipts | [Historical service observations](linux-service-receipts.md):26–44; [retirement guard](../../test/tooling/link_delivery_retirement_test.mjs):11–34 | Historical `uninstall` phase requires absent Wing and Wing Link binaries plus service assertions. Its recorder is removed; it describes the retired management/service chain, not current client uninstall. Do not restore it or reuse its phases as current proof. |

Scoped receipt probes found no `dist/linux-release-evidence.json`,
`dist/release-verification-receipt.json` or `dist/release-qualification-index.json`
in this isolated workspace. No installed target or release candidate was selected.
This does not assert that receipts exist nowhere; none inspected here binds a
current Wing installed-target uninstall and retained-state journey.

## Retention boundaries, not a purge promise

- Agent owns profiles, Projects, sessions, tools, secrets and runtime/service
  state. Client removal must not remove Agent code/data, stop its services or
  revoke remote credentials implicitly. See [Agent-only delivery](../adr/runtime-and-delivery.md#agent-only-delivery)
  and the [threat model](../security/threat-model.md#trust-boundaries).
- [Secure endpoint store](../../lib/core/hermes/setup/secure_hermes_endpoint_store.dart):8–25,
  40–54, 97–114, 175–184, 314–337 separates preferences and secure storage,
  retains same-owner historical fields, and never reads inert token-slot bytes.
  Passive loads are not a purge. Explicit endpoint deletion/clear is a separate
  app operation: it commits the new endpoint set and removes obsolete credential
  slots. It is not an application uninstaller or a server-side revocation API.
- [Legacy preservation tests](../../test/core/hermes/setup/legacy_endpoint_preservation_test.dart):191–294
  cover mocked raw-record retention, failed-write preservation, same-owner
  roundtrip, explicit scoped deletion and unread inert token slots.
  [Secure-store tests](../../test/core/hermes/setup/secure_hermes_endpoint_store_test.dart):105–159,
  233–298 cover bundle storage, passive retention and explicit deletion/clear.
  These exercise synthetic storage, not a Linux keyring after uninstall/reinstall.
- Linux dependency pins are `flutter_secure_storage_linux` 3.0.1 and
  `shared_preferences_linux` 2.4.1 in [pubspec.lock](../../pubspec.lock).
  Exact target storage locations, keyring availability, retention after client
  removal, reinstall readability and complete erasure are **NOT_CHECKED**.
  Removing a bundle is not proof of either preservation or erasure. No host
  preference files, keyring records, raw legacy data or credentials were read.

## Official reference is not Wing removal authority

Read-only Agent/Desktop reference commit:
`158fd638da1629c8e62caf9ade1515d162def8ab`. Root, Desktop and CLI `AGENTS.md`
instructions were consulted before inspecting their respective source.
Inspected upstream files matched that commit byte-for-byte; no upstream tests ran.

Official `apps/desktop/electron-builder.config.cjs`:279–286 targets AppImage.
`apps/desktop/electron/desktop-uninstall.ts`:68–105, 132–164 gates removal on
local install ownership: bundled/light, external and Nix installs cannot invoke
the destructive callback; standard installs allow `gui`, `lite`, `full`, not
`data`. Its native-removal guidance (:166–199) concerns the official artifact,
not Wing's Flutter bundle and launcher. The helper's opening summary is not a
complete GUI-data retention contract: Agent `hermes_cli/uninstall.py`:688–746
removes Electron userData in GUI-only mode while preserving Agent/config/session
state. Its keep-data versus full Agent removal is a different operation (:756–800).
Do not offer these Agent-removing modes as Wing uninstall options.

Official caller `apps/desktop/electron/main.ts`:19036–19156 resolves the local
app, launches detached cleanup and returns before completion. The corresponding
`desktop-uninstall.test.ts`:167–220 executes sandbox cleanup against a recorder,
not the actual Agent; `desktop-uninstall-ipc.test.ts`:69–134 checks callback
exclusion/mode validation. Agent `tests/hermes_cli/test_gui_uninstall_retention.py`:12–83
uses temporary synthetic installation/data and monkeypatched paths. These tests
were inspected only; neither fixtures nor an IPC success response qualify Wing
native uninstall, retained credentials or Agent service independence.

## Source fingerprints

SHA-256 of inspected Wing inputs, verified against the admitted commit at finish:

| Input | SHA-256 |
| --- | --- |
| `scripts/install_linux.sh` | `43ebeb1063a17d575e17f0e2409fe5f5b46b71750c6b18068fc503f43b00e458` |
| `scripts/run_linux_release_build.sh` | `d0442c891e25c897ee9407a05bb955c6481c0b788283937462a7d2c949bc36d0` |
| `scripts/verify_release_artifacts.sh` | `55d84e34704d786f2b85514abd2ea94ef7057a299fcfc833d62a3ad3ae05ba32` |
| `scripts/release_evidence.mjs` | `3a55e27bb7d1a75a2b6cb4f309a775dc57c43059918e8bf243d851fca0755d96` |
| `linux/CMakeLists.txt` | `9fcd731e7f60444620731bab62e347a116549bb1f5b1fc2f10f5ae2fbe78ec12` |
| `lib/core/hermes/setup/secure_hermes_endpoint_store.dart` | `0160acac45d95fde8ca70dc8ca7f3f379c317b3e453f22a08965f1775d982735` |
| `test/tooling/package_scripts_contract_test.dart` | `a48342abf3e64b75c9d016706a18311d6779da307862014fd7a4f19023f9d3d8` |
| `test/core/hermes/setup/legacy_endpoint_preservation_test.dart` | `568f098710f709e55c68cd767f30a98a2f8833ce9737de2a5e726b0d2e4b7ef1` |
| `test/core/hermes/setup/secure_hermes_endpoint_store_test.dart` | `fc538cb59919775f0627978056798d6d72099081f290785b0be45c0b048ff722` |
| `test/tooling/link_delivery_retirement_test.mjs` | `33d13ab40c85afc6f5f83079f83db071dab7e61d1e1e65fedce70b8276231bb3` |
| `pubspec.lock` | `f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89` |
| `package-lock.json` | `f32c4b4d226bf6cef1a1f66733d4c2e065e0656d1223e89f17ceb68f42429b63` |

## Executed offline checks

Environment: Linux x86_64, kernel `7.0.0-31-generic`; Flutter 3.44.2
(framework `c9a6c48423`), Dart 3.12.2, Python 3.12.14, Node v26.7.0.
Repository baseline Node 22 was **not exercised**. No target OS/distribution,
display session, installed artifact/launcher identity or native keyring was qualified.

- `timeout 120s flutter pub get --offline --enforce-lockfile` — PASS.
- `timeout 180s flutter test --no-pub test/tooling/package_scripts_contract_test.dart --name '^Linux'` — PASS, three source-contract tests; initial 9.277 s.
- `timeout 180s flutter test --no-pub test/core/hermes/setup/legacy_endpoint_preservation_test.dart test/core/hermes/setup/secure_hermes_endpoint_store_test.dart` — PASS, 28 mocked storage/directory tests; initial 2.356 s.
- `timeout 120s node --test test/tooling/link_delivery_retirement_test.mjs` — PASS, three offline retirement/archive tests; initial 0.550 s. Archive tests execute extracted validation Python against synthetic archives, not the shell verifier or an app. Python emitted a future tar-extraction-default deprecation warning.
- `bash -n scripts/install_linux.sh scripts/run_linux_release_build.sh scripts/verify_release_artifacts.sh` — PASS, syntax only.
- `git diff --exit-code -- pubspec.lock package-lock.json` — PASS, unchanged locks.
- `python .task-evidence/t_c4c64224/check_document.py` — PASS, 15 relative links/anchors, 12 Wing source fingerprints, seven upstream blobs and document whitespace. Finish replays the same code with `python -c`.
- `git diff --check` — PASS; replayed at finish.

Exact argv, exit codes, durations and logs are retained in the ignored task
receipt alongside the finish gate receipt. No test retries were required.
Full Flutter analysis/suite, browser/native UI, installation, removal, signing,
recovery and live credentials are **NOT_CHECKED**. Review is a separate pending
native lane, not an executed check. Total time/cost were not measured.

## Exact remaining proof

Under separate explicit target/removal authority, first define a client-only
procedure with verified ownership of the installed complete bundle and launcher,
custom destination handling, symlink/unrelated-path protection and failure
reporting. Default to retaining saved Agent identities/credentials and inert raw
legacy records; data cleanup, if ever offered, needs its own explicit consent and
secret-safe contract. Do not infer a purge from removed client files.

A named Linux x64 target receipt must bind source/artifact digests, installation
inventory, OS/runtime/display inputs and timestamps to observed removal of owned
client files, unchanged Agent/service ownership, retained synthetic state and
reinstall readability through the actual storage backend. Record partial-removal
failure honestly without deleting unrelated data; keep secrets and private paths
out of public receipts. No procedure or execution is authorized by this proposal.

Implemented here: evidence map only. Qualified: bounded offline checks only.
Delivered: local task commit/review handoff; canonical integration remains with
the coordinator. DESKTOP-DELIVERY stays partial for native install/update/uninstall
and signed recovery. Next accepted queue candidate `DOC-SLASH-DENIAL-EVIDENCE`
remains a separate slice subject to fresh admission; no card was created here.
Ponytail full: one document reuses existing producers/tests; no removal script,
guard, dependency, replacement backend, ledger edit or redundant reviewer.
