# M4 historical host restart: approval is not health or rollback

Task: `DOC-M4-HOST-LIFECYCLE-EVIDENCE`. **Read-only historical attribution, not
current support, replacement acceptance or permission to operate Wing Link.**
Start with the [messaging-platform contract](m4-messaging-platform-contract.md)
and [Agent-only delivery decision](../adr/runtime-and-delivery.md#agent-only-delivery).

## Verdict and inspected identities

**The archived `lifecycle.restart` policy is routine, not a host-local approval
receipt. No corresponding HTTP restart handler was found at the inspected pin.**
Local service restart, trust-tier update approval, Link liveness and restored
on-disk links are different boundaries. Their tests/receipts cannot be composed
into an approved remote restart or a healthy recovered predecessor.

| Material | Pinned identity | Evidence ceiling |
| --- | --- | --- |
| Wing task baseline, `git rev-parse HEAD` | `f372a78af413eabd04de0407837123e55a394878` | Current source/tests, retained sanitized reports and task state; no runtime execution. |
| Archived Wing source/tests, `git rev-parse 918e7c318bab1d91f348570e2309598d729ecb9c^{commit}` | `918e7c318bab1d91f348570e2309598d729ecb9c` | Last parent of service/delivery removal; inspected using `git show`, never restored into the product or executed. |
| Removal commit, ancestor of baseline | `bce4ec5fb9109d29520b81260f13bad93c6f2cb7` | Source removal, not installed-service uninstallation or credential revocation. |
| Sanitized [host verification report](2026-10-03-host-verification.md#verdict-and-provenance) | Reports `ca149a82189c8c9e5abd98b376bfeae1e43f6f3f` **plus unrelated dirty work**, observed UTC `2026-10-04T00:50:10Z` | Historical reported test exits; not immutable artifact or exact dirty-source identity. Later archived-source links do not rebind those executed bytes. |

Docs map: platform trace → archived approval/dispatch and local service command →
health/updater tests → sanitized report and recorder contract → current retirement
boundary. Only repository source/test text and sanitized retained reports were
read; no private logs, credentials, installed state, upstream runtime, service
commands, installs or network requests were used.

The coordinator assigned this exact isolated branch/task. At baseline, the local
`goals.json` tracker marks `DOC-M4-PLATFORM-CONTRACT` done and this task open/Next;
its trace commit `c0c90a4295d08a5431bc36aa9324e0cb057a9425` is an ancestor.
The [continuation ledger](../plans/2026-10-03-desktop-port-goal.md) contains no
matching task claim. These are local admission checks, **not a fresh external
issue-tracker lease or release of another worker's ownership**. No other task was
selected. `CONNECTION-LINK-RETIREMENT` in the baseline [task index](../../TODO.md)
already records delivered offline removal with named Linux/Android replacement
acceptance still open. This page hands evidence back to that owner; it neither
reopens deletion work nor closes replacement acceptance.

## One historical approval boundary

All `[H…]` links below identify **archived Wing code**, not Hermes Agent APIs.
Line ranges refer to `918e7c318bab1d91f348570e2309598d729ecb9c`. Test assertions
were inspected, **not rerun**.

| Seam | Source and nearest regression | What it proves / does not prove |
| --- | --- | --- |
| Restart risk classification | [Policy][H1]:26–59 defines `lifecycle.restart` as `TierRoutine`; [policy test][H2]:13–33 explicitly expects routine and rejects an unknown operation. | A policy label, not host approval or evidence that a route exists. [Store request][H1]:115–126 accepts only sensitive/trust approval requests, not routine ones. |
| Gate versus decision | [HTTP approval gate][H3]:31–113 reserves an operation using device, method/route, idempotency key and digest, rejects changed-payload reuse, and returns early for routine operations at 87–89. Non-routine requests consume an exact approval or create a five-minute pending request. [Host CLI][H3]:115–178 calls `Decide`; [store][H1]:167–224 records the host decision and matches device/route/digest/key on one-use consumption. | Generic approval machinery does not turn routine restart into a locally approved action. The store has no separate stable resource incarnation or expected-revision field; do not infer those guarantees from a digest alone. |
| Binding tests are not restart tests | [Store tests][H2]:50–87, 118–174 cover persisted one-use consumption, changed key and legacy unkeyed denial. [Unspent mismatch test][H4]:13–67 varies device, route, digest and key **before consumption**, reopens the store, then consumes only the original request. | Valuable historical binding assertions, but their selected operation is **profile deletion**, not host restart, platform administration or revoked-caller recovery. |
| Actual local restart path | [CLI dispatch][H5]:62–71 calls `WingLinkServiceCommand`; [Linux command][H6]:86–114 invokes the fixed user service through `systemctl`, then checks Link health. | Explicit host-local OS invocation, not a remote device approval flow. The command does not call `approvalGate`. This is source description, not a command to run or current Wing functionality. |
| HTTP lifecycle-related path is different | [Dispatcher][H7]:449–600 includes Link health, update, setup and operation routes, but no restart route. Archived `wing_link/` search finds `OpLifecycleRestart`/`lifecycle.restart` only in policy and its test. Update dispatch at 516–522 requires `ScopeLifecycleWrite`; [update handler][H8]:32–60 checks production-key/activation availability before its **trust-tier `update.apply`** gate ([policy][H1]:43–53). | A lifecycle grant and update approval do not authorize an arbitrary restart. A possible update restart callback is not a standalone restart endpoint. Production update refusal is not permission to bypass keys, configure activation or recreate the removed backend. |

**Attributed result:** the retained sources establish a routine restart policy and
a separate local service command, **not an operation-bound remote restart approval**.
The missing proof is a correlated restart request → authorized exact resource →
fresh host decision → exact execution/outcome receipt. Neither the policy name nor
profile-delete approval tests supply it. This is historical missing evidence, not
a proposal to add that flow to Wing Link.

## Health and rollback receipts stay separate

| Evidence | Supported observation | Ceiling / missing proof |
| --- | --- | --- |
| Link health producer and probe | [Dispatcher][H7]:479–481 returns `status: ok` and protocol version for `/healthz`, before device authorization. [Probe][H9]:20–48 accepts HTTP 200, sets a timeout and refuses redirects. [Tests][H10]:10–55 exercise a loopback fixture, redirect rejection and refusal unless external mode is explicitly selected. | Process/HTTP liveness, not authenticated Agent readiness, exact process-generation identity, Telegram state, approval or permission to restart. The probe does not verify response-body identity. |
| Healthy-service reuse | [Linux helper][H6]:79–84 skips setup when configuration matches and Link health succeeds. [Reuse test][H11]:34–56 injects setup and asserts it was not called; unit-boundary test at 58–99 checks generated unit text. | No real service-manager restart in these cases; generated unit text is not installed isolation or health evidence. |
| Update failure restores links | [Updater][H12]:405–467 swaps/syncs links, invokes injected restart/health and restores links on failure. [Restart-failure test][H13]:561–586 expects prior `current`, absent prior `previous`, and zero health calls. [Health-failure test][H13]:625–651 expects both prior links and exactly **one restart, one health call**. | Filesystem rollback, not a restarted healthy predecessor. After restoration the implementation makes no second restart/health call. These fixtures do not execute a release binary or service. |
| Sanitized executed report | [Host report](2026-10-03-host-verification.md#exact-observed-receipts) reports passing Go, focused updater/service-boundary and four Node validator tests, while explicitly holding exact-artifact native lifecycle/recovered-service health. | Prior reported execution, not fresh execution here. It explicitly says **no exact-artifact phase receipt was emitted**. No successful native restart, host approval or recovered process can be inferred. |
| Recorder schema and synthetic phase fixtures | [Archived recorder][H14]:8–42 validates six ordered phases and receipt identities; :43–64 verifies release artifacts and hashes only `bundle/wing` from the client archive; :78–117 revalidates phase data and writes an immutable index/phase file. [Tests][H15]:8–51 use synthetic manifests, hashes and observation booleans; wrong predecessor bytes or false restored-health observation fail. | Receipt validation is not an observed lifecycle. Health/previous verification remain operator assertions; active-file hashes are not running-process identity or the complete installed client bundle. No approval ID/device/route/key/digest correlation exists in these phase receipts. |

The old [service recorder guide](linux-service-receipts.md) is historical and its
script is deleted. The sanitized report supplies no complete phase sequence/index
to inspect; none is tracked in this checkout's receipt inventory. This bounded
absence finding does **not** claim that private artifacts never existed. Do not
invent receipts, set observation flags, restore a recorder, restart a personal
service or collect private state to fill it.

## Current support and remaining proof

- **Messaging administration:** the [platform trace](m4-messaging-platform-contract.md#one-exact-admin-operation-disable-telegram-configuration)
  separately evaluates one Telegram configuration write. Its Agent/Desktop pin
  and conclusions belong to that prior inspection, not a new upstream inspection
  here. Link approval policy, `/healthz`, or release rollback provides none of its
  missing exact advertised grant, resource, approval or concurrency guarantees.
- **Current health:** [Connections](../../lib/features/gateway/screens/gateway_screen.dart):20–22,
  307–344, 412–446, 724–752 exposes selected-owner Agent health refresh and status
  text, not lifecycle or platform toggles. [Nearest tests](../../test/features/gateway/gateway_screen_test.dart):348–499
  inspect read-only diagnostics, absent Restart, refresh, stale failure, basic
  fallback and scope denial. These are source assertions, not new passing UI tests.
- **Retirement:** [delivery receipt](link-delivery-retirement.md) and current
  [absence guard](../../test/tooling/link_delivery_retirement_test.mjs):11–54
  distinguish removal of source/delivery dependencies from preserved installed
  runtimes and inert credentials. No legacy code/tests or services are recreated;
  no shell bridge, shadow backend or native SSH lifecycle authority replaces them.
  [Routes](../product/routes.md) and [threat model](../security/threat-model.md)
  continue to keep missing lifecycle operations unavailable.
- **Remaining proof, not execution authority:** historical remote restart approval
  and exact-artifact recovered-predecessor process/health correlation are absent
  from this inspected evidence. They remain historical gaps, not prerequisites to
  revive Link. Separately, only an eligible **unmodified Agent** contract and a
  separately admitted disposable target could support future lifecycle qualification:
  exact authorization/resource and approval binding, stale/replayed request denial,
  source/artifact/target/process correlation and activation versus restored-health
  outcomes. Named Linux/Android direct setup/migration acceptance remains with
  `CONNECTION-LINK-RETIREMENT`, not satisfied by any old service receipt.

## Validation and update triggers

Documentation-only on a Linux host. No product tests were added or run;
Flutter/browser/native apps, physical devices, installed services, live Agent or
messaging accounts were not exercised. The offline validator checked two changed
pages, 16 local targets/anchors,
15 pinned historical paths and 26 source-linked ranges, plus source ancestry,
local dependency state and retired-path absence. No tracked JSON phase/index
receipt or incoming anchor to the renamed historical guide heading was found.
Fresh-context independent `reviewer` contract/security inspection found no
Critical/Important issues; its one Minor wording finding was verified against
the external-mode guard and corrected. That review did not attest external leases
or runtime outcomes. Final link/source and `git diff --check` results are recorded
in the task report. This does not qualify any platform or authorize service actions.

Revisit only on changed authoritative Agent lifecycle/approval contracts, Wing
health/gates, retirement acceptance, or newly supplied **sanitized source-bound**
historical receipts. Preserve the original dirty-source attribution; never repin
an old test result to later source or replace missing proof with compilation.

## Archived Wing sources

[H1]: https://github.com/TrebuchetDynamics/hermes-wing/blob/918e7c318bab1d91f348570e2309598d729ecb9c/wing_link/internal/approval/approval.go
[H2]: https://github.com/TrebuchetDynamics/hermes-wing/blob/918e7c318bab1d91f348570e2309598d729ecb9c/wing_link/internal/approval/approval_test.go
[H3]: https://github.com/TrebuchetDynamics/hermes-wing/blob/918e7c318bab1d91f348570e2309598d729ecb9c/wing_link/internal/app/approval.go
[H4]: https://github.com/TrebuchetDynamics/hermes-wing/blob/918e7c318bab1d91f348570e2309598d729ecb9c/wing_link/internal/approval/security_current_boundary_test.go
[H5]: https://github.com/TrebuchetDynamics/hermes-wing/blob/918e7c318bab1d91f348570e2309598d729ecb9c/wing_link/internal/app/cli.go
[H6]: https://github.com/TrebuchetDynamics/hermes-wing/blob/918e7c318bab1d91f348570e2309598d729ecb9c/wing_link/internal/app/service_linux.go
[H7]: https://github.com/TrebuchetDynamics/hermes-wing/blob/918e7c318bab1d91f348570e2309598d729ecb9c/wing_link/internal/app/serve.go
[H8]: https://github.com/TrebuchetDynamics/hermes-wing/blob/918e7c318bab1d91f348570e2309598d729ecb9c/wing_link/internal/app/update.go
[H9]: https://github.com/TrebuchetDynamics/hermes-wing/blob/918e7c318bab1d91f348570e2309598d729ecb9c/wing_link/internal/app/service_health.go
[H10]: https://github.com/TrebuchetDynamics/hermes-wing/blob/918e7c318bab1d91f348570e2309598d729ecb9c/wing_link/internal/app/service_health_test.go
[H11]: https://github.com/TrebuchetDynamics/hermes-wing/blob/918e7c318bab1d91f348570e2309598d729ecb9c/wing_link/internal/app/service_linux_test.go
[H12]: https://github.com/TrebuchetDynamics/hermes-wing/blob/918e7c318bab1d91f348570e2309598d729ecb9c/wing_link/internal/release/updater.go
[H13]: https://github.com/TrebuchetDynamics/hermes-wing/blob/918e7c318bab1d91f348570e2309598d729ecb9c/wing_link/internal/release/updater_test.go
[H14]: https://github.com/TrebuchetDynamics/hermes-wing/blob/918e7c318bab1d91f348570e2309598d729ecb9c/scripts/record_linux_service_qualification.mjs
[H15]: https://github.com/TrebuchetDynamics/hermes-wing/blob/918e7c318bab1d91f348570e2309598d729ecb9c/test/tooling/linux_service_qualification_test.mjs
