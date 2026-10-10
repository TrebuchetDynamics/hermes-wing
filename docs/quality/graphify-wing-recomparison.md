# Wing graph refresh and Desktop recomparison

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


This pass rebuilt Wing's local code graph and maintained the existing parity
backlog. It changed documentation only. Production code, tests, upstream sources,
worker leases and milestone focus were not changed.

## Source boundary

Graphify 0.9.80 used local extraction with two workers, no semantic pass and no
LLM labels. Dart extraction is regex-based, not a complete Dart AST analysis.
Wing HEAD is `b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319` plus a filtered dirty-worktree
manifest. Desktop HEAD is `withdrawn reference revision`.
All 816 selected Desktop source hashes matched the retained manifest, so the
Desktop graph was reused. This does not assert upstream release freshness.

The first Wing snapshot selected 805 code files. Against the previous final
snapshot, 11 files were added, 12 changed and none removed. These include concurrent
key-authentication and Local setup work, plus earlier recovery-test repairs.
They are not changes attributable to this documentation pass.

Concurrent writers changed six selected files during analysis. One separate final
snapshot selected 806 files. Its graph remains pinned to that manifest. Two test
files had changed again when extraction finished. Further churn does not invalidate
the pinned graph, but it prevents a whole-current-worktree qualification claim.
The local receipts retain the exact drift paths and later hash rechecks.

## Serialized graph counts

| Snapshot | Nodes | Relationships | EXTRACTED | INFERRED |
| --- | ---: | ---: | ---: | ---: |
| Retained Desktop | 4,824 | 13,384 | 13,260 | 124 |
| Previous final Wing | 11,698 | 21,441 | 20,824 | 617 |
| First Wing refresh | 11,825 | 21,670 | 21,051 | 619 |
| Final pinned Wing refresh | 11,846 | 21,733 | 21,114 | 619 |

Required JSON, report and HTML files are nonempty. Node IDs are unique and all
relationship endpoints exist. Counts come from serialized JSON, not the smaller
clustered graph in the generated report. Counts do not measure product parity.
The HTML is an aggregated community view. Offline rendering was not exercised.
The first build reported 34 zero-symbol files and one partial C-header parse
failure in `linux/runner/my_application.h`. Coverage details for both snapshots
remain in their build logs. No missing-language warning was observed. That is not
proof that all language constructs are supported.

## Source-backed comparison

### Managed SSH now includes a private-key selection path

The previous comparison described a password-only Wing form. The final pinned
source now contains Private key / Password controls, deliberate `file_selector`
selection and attempt-scoped key content. The form forwards key/passphrase input
through `ManagedSshConnectionController` to existing transport callbacks. It also
has encrypted-key detection, an obscured passphrase field and an unlock check.
See `lib/features/hermes_chat/widgets/managed_ssh_connection_form.dart`,
`lib/features/hermes_chat/ssh_keys/managed_ssh_key_selection.dart` and
`lib/features/hermes_chat/providers/managed_ssh_connection_controller.dart`.

This is partial implementation, not qualified key authentication. In the pinned
selection helper, `readAsBytes` has no explicit size bound. Picker completion
checks widget mounting but does not bind its result to the form's attempt
counter. Bounded acquisition and cancellation/replacement fencing therefore
remain explicit acceptance in BACKEND-SSH-KEY-AUTH. These are source-only gaps,
not security-audit conclusions. Preserve its existing in-progress ownership.

A later live-source read found a `64 * 1024` byte limit, bounded streamed reads
and a separate picker-generation fence. Those changes are outside the final
pinned graph and have no passing check attributed by this pass. Verify and reuse
them in the existing key-authentication task instead of implementing them again.
Nine selected paths differed from the final manifest at the closing hash check.

Desktop instead saves a key-file path and uses system OpenSSH with automatic
first-use host trust. Wing uses native Dart forwarding and explicit fingerprint
review, keeps Agent authentication separate, and exposes no remote bootstrap.
Docker/WSL lifecycle and durable SSH relaunch remain separate gaps. See the
[connection comparison](../product/desktop-connection-paths.md).

The graph returns the exact EXTRACTED reference
`_ManagedSshConnectionPanelState → managedSshConnectionControllerProvider`.
The live `_submit` caller confirms it. No directed path was found from the form
State to `SelectedManagedSshKey` in the first graph, although live source calls
`SelectedManagedSshKey.read`. Missing Dart graph paths are not absent dependencies.
The controller query starts from the intended symbol but truncates 61 reached
nodes to 35 at the 1200-token budget. It is not a complete dependency inventory.

### Welcome and saved entry remain explicit

Wing retains Desktop-guided Local, SSH and Remote entry. The connection entry
gate reads secure saved ownership and offers explicit retry instead of treating
an unreadable store as an empty installation. Fresh welcome-recovery and gate
checks passed within the focused run below. This does not qualify native setup,
live authentication, physical secure storage or delivered APK fidelity.

### Shell persistence is implemented, while tabs remain separate work

The exact EXTRACTED path remains
`AppShell → wingSidebarExpandedProvider`. The live shell watches that provider.
Native two-process persistence remains unverified; a fresh provider scope is not
a process restart. Retain both existing SHELL-PERSISTENCE harness tasks.

Desktop `Layout.tsx` owns a run list, active run, close handling and keyboard tab
navigation. Wing's inspected shell composes global session access and the local
sidebar preference, not that multi-conversation tab model. Existing PARITY-TABS
entries now specify an implementation slice and a dependent reconnect slice.
Agent-owned session/run identity and authoritative Stop must not become
renderer-owned shadow domain state.

## Executed checks and limits

- Graph builds: exit 0 for both fresh Wing snapshots.
- Graphify adapter: 7 tests passed.
- Retained real two-file fixture: query, explain and path passed. The path is
  `run() --calls [EXTRACTED]--> normalize()`.
- Focused application check: 31 passed, 3 failed, exit 1. The command was
  `npm run test -- test/features/hermes_chat/widgets/managed_ssh_connection_form_test.dart test/features/hermes_chat/widgets/managed_ssh_connection_panel_test.dart test/features/enrollment/hermes_welcome_recovery_test.dart test/router/connection_entry_gate_test.dart`.
  Failures were compact enlarged-text keyboard reachability, the obsolete
  password-only explanation, and the encrypted-key passphrase control.
  Source changed during that run. The result is a mixed-state observation, not
  qualification of either frozen graph. No assertions were changed in this pass.
- Shared skills: `make -C <home>/.hermes/shared-skills test` exited 2.
  37 offline suites passed and 2 failed: `autogoal/scripts/test_native_containment.py`
  and `autogoal/scripts/test_picker_policy.py`. Unrelated repairs were not attempted.
- The earlier full-suite log records 3,750 passed, 8 skipped and zero failures.
  It has no complete source/dependency manifest and predates these changes.
  It cannot qualify the current key-authentication work. No full suite was appended
  to this comparison pass.

## Backlog handoff

`TODO.md` retains existing task IDs, dependencies and milestone focus.
BACKEND-SSH-KEY-AUTH remains in progress. Its body now names the partial key path,
remaining acquisition/recovery checks and source-only gaps. BACKEND-SSH-CONNECT
now directs workers to complete and qualify the existing Dart adapter rather
than rebuild forwarding or require an OpenSSH subprocess. DOC-BACKEND-CONTRACT
retains the single contract-review boundary without repeating Desktop research.
PARITY-TABS retains two ordered implementation/recovery tasks. Native shell
persistence remains a distinct unverified outcome.

The live ledger also contained CONNECTION-LOCAL-ENROLLMENT-NATIVE without a full
TODO body. This pass restored that body from its existing in-progress task and
the delivered Local setup recovery contract. It did not create a duplicate or
change ownership. The first eligible ledger entry is the in-progress
CONNECTION-SAVED-WORKFLOWS. The first eligible open successor is
CONNECTION-SETUP-AUTH-MATRIX. Eligibility is not writer availability.

Documentation checks passed: `goals.py validate` returned `ok`, every open or
in-progress ledger task had a full TODO body, and every non-met goal retained
an unfinished task. `fmt` plus `render` was byte-stable on the second pass.
The new comparison links resolved and `git diff --check` passed. The inspected
ledger had 2 met, 17 partial, 9 unmet and 7 unverified goals. CONNECTION-PATHS
remained the primary milestone. Scoped wording and meaning were reviewed using
the STE-inspired profile. Full ASD-STE100 dictionary compliance was not verified.

## Local artifacts

Final artifact root:
`<repo>/.task-evidence/graphify-wing-todo-refresh-final/`.
Use `wing/graphify-out/graph.json` for the full graph and
`wing/graphify-out/graph.html` for the aggregated view. The first snapshot, queries,
focused checks and shared-suite logs are retained in the sibling
`graphify-wing-todo-refresh/` directory. Receipts record source manifests, graph
metadata, commands, exits and coverage. These ignored artifacts stay local.
