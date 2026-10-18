# M3 failed new-profile setup: historical attribution and current proof gap

Task: `DOC-M3-ROLLBACK-EVIDENCE`. **Read-only evidence inspection; no rollback
run or profile creation.** Start with the [enrollment/profile checkpoint](m3-enrollment-profile-contract-checkpoint.md)
and [Agent-owned mutation requirements](../adr/api-and-state.md#required-agent-owned-mutation-contract).
This page attributes one reported failure; it does not qualify M3 or enable setup.

## Evidence identity and ownership

| Inspected material | Exact revision / identity | Evidence class |
| --- | --- | --- |
| Wing baseline (`git rev-parse HEAD`) | `45de04652f99c1b09f92ce94a66eb2cbd53a2d00` | Current callers, tests and retained sanitized receipts; documentation-only task. |
| Unmodified Agent reference (`git -C <reference> rev-parse HEAD`) | `158fd638da1629c8e62caf9ade1515d162def8ab` | Source/test inspection, not an installed runtime identity. Official Desktop shares this repository/revision. |
| Archived Wing Link implementation/tests and original provider receipt (`git show <revision>:<path>`) | `95fa98eb4ac91f123c0163c84fdd42d545cd7826` | Retired Go management path, not current Wing support. |
| Historical physical APK, as recorded by the receipt | SHA-256 `d8baa2be39fe209d1686ead4dec0ec6011c729e6d7c97057c99664bc45825d3a`; worktree base `92a3d418b425d6ef095eb304e1f2ba18cfcd0392` **plus uncommitted concurrent work** | Artifact attribution reported in history, not an exact source-to-failed-attempt binding. |

The coordinator assigned this isolated branch. The local [task index](../../TODO.md)
and `goals.json` at the baseline mark this task open/Next and its dependency
`DOC-M3-CONTRACT-CHECKPOINT` done; checkpoint commit
`1a3a7fe0716bfec88123c8fff03e9d41e4a0b033` is an ancestor. Local execution-slot
metadata identifies this task/worktree; the local coordinator status reported one
active worker. This is not a live issue-tracker lease or a release of another
worker's ownership. No other task was selected or adopted.

Docs map: checkpoint → retained provider receipt → archived Go handler/harness;
current Wing caller and unmodified Agent publication boundary → remaining gap.
Only sanitized repository receipts and source/test text were inspected. No private
runtime logs, credentials, personal Agent state, installs or live operations were
accessed; no Go, Flutter or upstream tests were executed.

## One selected historical failure

The retained [physical provider report](provider-chat-physical-2026-09-05.md#setup-and-regression-evidence)
reports that an earlier `z-ai/glm-5.3-flash` readiness retry exceeded its bounded
deadline and the attempted profile was rolled back. The report describes a physical
Samsung SM-S928B / Android 16 client and isolated Linux Agent/Wing Link processes
over authenticated loopback through USB reverse mappings. These are **historical
reported observations**, not platforms exercised by this task.

The report's later successful profile/chat/deletion is a different outcome; it
must not stand in for the failed attempt. Its [companion JSON](provider-chat-physical-2026-09-05.json)
records `original_profiles_unchanged: true` and final isolated-state cleanup, but
has **no failed-attempt profile ID, operation ID, before/after inventory or
incarnation/revision comparison**. The prose says the original user profile listing
was unchanged after the overall run; it does not bind that statement to the exact
failed setup or prove unchanged source configuration/credentials.

The original receipt is present at the archived revision above. Compared with
that revision, the retained Markdown only appends a separate PR-CI follow-up;
its JSON is unchanged. Neither the shared-worktree base nor the later committed
Go source proves which exact bytes executed this failed attempt. No missing
private evidence is inferred from the receipt's statement that private artifacts
were retained outside the repository.

## Source-bound cleanup: what the archived Go path establishes

All `[H…]` references below are pinned to the archived Wing revision, not Agent.
These are source and test-assertion findings, **not new passing test results**.

| Seam | Inspected source / nearest test | Supported proof and limit |
| --- | --- | --- |
| Bind cleanup to the newly requested name | [`profileBackend.create`][H1]:1203–1250 normalizes the requested ID, checks inventory for a collision and validates an explicit clone source before issuing create. It returns the created ID even after some applied/post-create-read failures. | Tracks a newly created name for cleanup; a preflight check and process mutex do not establish authoritative incarnation safety against another process. |
| Setup failure → cleanup | [`performCreateProfile` / `rollbackCreatedProfile`][H2]:832–875 calls configure only on the created row; any configure error invokes `deleteCreated(row.ID)`. Cleanup uses a 30-second context detached from request cancellation; cleanup errors are joined, not success. | A timeout/error returned by readiness follows this branch. This is compensating deletion, not an atomic create/configure transaction or crash-safe receipt. |
| Readiness boundary | [`configure`][H3]:1017–1105 scopes config/auth/readiness to the new profile. Readiness error or a response other than the accepted `Hi` yields a postcondition error. The production [`ReadHermes` closure][H4]:220–227 uses bounded capture with a 30-second command timeout. | Explains a source path consistent with the reported deadline failure; does not prove that exact timeout occurred or that no inference/billing effect occurred before cleanup. Historical readiness explicitly sends a prompt. This is not a current setup recipe. |
| Deletion postcondition | [`deleteCreated` / `confirmDeletedLocked`][H5]:1329–1358 validates the mutable ID, issues deletion for that ID, increments local mutation generation and checks inventory for absence. A failed read/remaining row returns an error. | Absence is checked when inventory is readable; no sibling-content comparison, authoritative expected incarnation/revision or durable failure receipt is required by this helper. |
| Nearest readiness rejection | [`TestProfileCreateRollsBackWhenReadinessDoesNotAnswerHi`][H6]:971–984 uses a fake non-`Hi` response, expects HTTP 502 and absence of the new `notreadyqa` map entry. [`TestProfileReadinessAllowsOnlyKnownStartupNotice`][H6]:986–1018 rejects missing/extra/repeated output with matching map absence. | Handler/harness cleanup assertions, not an actual process timeout or filesystem/secret cleanup test. |
| Adjacent failure coverage | [`TestProfileCreateRollsBackWhenProviderCredentialSetupFails`][H7]:833–851 expects HTTP 503, new-map-entry absence and an exact last delete command. [`TestProfileCreateRollbackSurvivesRequestCancellation`][H8]:931–969 checks cancellation during fake secret setup, new-map-entry absence and that delete command. | Supports target-bound compensating cleanup and cancellation detachment in the fake harness, not recovery after service/process death. |
| Existing-profile protection is narrower | The [harness][H9]:97–244 seeds `default` and `link`, uses a map and injected CLI/secret callbacks; fake delete removes the addressed map entry. The failure cases above do **not** assert the complete remaining map or source identity/content. [`TestProfileUpdateRejectsExistingConfigurationBeforeMutation`][H10]:1021–1044 rejects a separate existing-profile configuration request before any CLI/secret command. | No assertion of preserved existing-profile incarnation, config, credentials or sessions across the selected failed creation. Rejection of a different update is not that proof. |

**Historical verdict:** source-bound deletion of the newly created name is supported
by the inspected implementation and fake-handler assertions. A real readiness-timeout
rollback is reported, but **failure-specific cleanup plus unchanged existing-profile
identity is not fully attributable** from the sanitized receipt and tests. Do not
upgrade the receipt's whole-run preservation boolean to exact-ID/incarnation proof.

## Current Agent-only boundary

- Current [Profiles editor construction](../../lib/features/profiles/screens/profiles_screen.dart):453–461
  supplies no configurable `onCreate`. The [editor](../../lib/features/profiles/widgets/profile_editor_sheet.dart):421–440
  calls channel create with name/clone; the [API client](../../lib/core/hermes/client/hermes_api_client.dart):558–566
  sends only those fields. No historical provider/readiness/cleanup sequence is wired here.
- [Channel create](../../lib/core/hermes/channel/api_channel/hermes_api_channel_profiles.dart):160–177
  requires exact `profile_create` POST `/api/profiles` with `profiles:write`;
  [mutation reconciliation](../../lib/core/hermes/channel/api_channel/hermes_api_channel_profiles.dart):307–330
  refreshes inventory with connection fencing, not delete-on-failure rollback.
  [Editor owner tests](../../test/features/profiles/profile_editor_sheet_test.dart):27–84
  and [screen mutation-owner tests](../../test/features/profiles/profiles_mutation_owner_test.dart):84–265
  test fake late-completion/control fencing, not Agent rollback or unchanged sibling state.
- At the inspected Agent revision, the [API-server capability table][U1]:67–110
  does not advertise Wing's profile-create operation. Its [capabilities test][U2]:937–961
  is not a setup/rollback test. Dashboard [REST create][U3]:803–873 and native
  [`profiles.create`][U4]:305–346 perform post-create work with separate/best-effort
  outcomes, not the retired Go transaction.
- Agent [`create_profile`][U5]:1401–1481 builds hidden staging, removes that staging
  on an exception during construction/publication, then can register/notify lifecycle
  after publication. [Nearest clone tests][U6]:150–184 verify source symlink-content
  preservation and publish-after-strip on successful clones. They do not inject the
  selected readiness failure or prove whole-setup rollback after publication.

The [checkpoint's current gap](m3-enrollment-profile-contract-checkpoint.md#3-agentdesktop-create-handlers-are-not-the-missing-wing-contract)
therefore remains: historical Wing Link compensation is not an advertised
Agent-owned rollback contract, existing-profile mutation qualification or permission
to restore a compatibility adapter. [Never modify Agent](../adr/runtime-and-delivery.md#hard-boundary-never-modify-hermes-agent),
edit its files or delete a reused name to manufacture that proof.

## Missing proof and disposition

A complete receipt for this failure would need a single correlated failed operation,
exact executing artifact/runtime identity, authoritative new-profile identity and
incarnation, pre-existing source/sibling identities plus authorized unchanged-state
readback, and a bounded cleanup/partial/unknown outcome including partial secret
state. Inventory absence, a toast, a timeout or a final cleanup boolean alone is
insufficient. Such evidence is **missing from the inspected corpus**, not claimed
impossible or silently present in private logs.

Offline acceptance is the bounded attribution/gap above; no implementation, test,
upstream or user-state change is required. M3 and current new-profile rollback remain
**UNVERIFIED**. Pending live: only after a suitable unmodified authoritative contract
and approved isolated target exist, separately qualify failure/readback and native
secure-storage behavior. This page authorizes no new attempt, credentials, provider
call, service operation or profile creation. No platform was exercised here.

Revisit when an attributable sanitized failed-attempt receipt becomes available,
Agent advertises changed create/identity/outcome guarantees, or Wing wires a different
create path. Re-pin the sources and repeat independent contract/security review;
do not carry historical claims onto an uninspected runtime.

## Pinned archived and reference sources

[H1]: https://github.com/TrebuchetDynamics/hermes-wing/blob/95fa98eb4ac91f123c0163c84fdd42d545cd7826/wing_link/internal/app/serve.go#L1203-L1250
[H2]: https://github.com/TrebuchetDynamics/hermes-wing/blob/95fa98eb4ac91f123c0163c84fdd42d545cd7826/wing_link/internal/app/serve.go#L832-L875
[H3]: https://github.com/TrebuchetDynamics/hermes-wing/blob/95fa98eb4ac91f123c0163c84fdd42d545cd7826/wing_link/internal/app/serve.go#L1017-L1105
[H4]: https://github.com/TrebuchetDynamics/hermes-wing/blob/95fa98eb4ac91f123c0163c84fdd42d545cd7826/wing_link/internal/app/bootstrap.go#L220-L227
[H5]: https://github.com/TrebuchetDynamics/hermes-wing/blob/95fa98eb4ac91f123c0163c84fdd42d545cd7826/wing_link/internal/app/serve.go#L1329-L1358
[H6]: https://github.com/TrebuchetDynamics/hermes-wing/blob/95fa98eb4ac91f123c0163c84fdd42d545cd7826/wing_link/internal/app/serve_test.go#L971-L1018
[H7]: https://github.com/TrebuchetDynamics/hermes-wing/blob/95fa98eb4ac91f123c0163c84fdd42d545cd7826/wing_link/internal/app/serve_test.go#L833-L851
[H8]: https://github.com/TrebuchetDynamics/hermes-wing/blob/95fa98eb4ac91f123c0163c84fdd42d545cd7826/wing_link/internal/app/serve_test.go#L931-L969
[H9]: https://github.com/TrebuchetDynamics/hermes-wing/blob/95fa98eb4ac91f123c0163c84fdd42d545cd7826/wing_link/internal/app/serve_test.go#L97-L244
[H10]: https://github.com/TrebuchetDynamics/hermes-wing/blob/95fa98eb4ac91f123c0163c84fdd42d545cd7826/wing_link/internal/app/serve_test.go#L1021-L1044
[U1]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py#L67-L110
[U2]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/gateway/test_api_server.py#L937-L961
[U3]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/profiles.py#L803-L873
[U4]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/methods_profiles.py#L305-L346
[U5]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/profiles.py#L1401-L1481
[U6]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_profile_clone_channels.py#L150-L184
