# Linux Chat fixture qualification

Task: `LINUXQA-001-c7841f6e`. Scope: the current-source synthetic GTK Chat lane,
not complete Linux qualification, live Hermes Agent parity, or release acceptance.

## Entry point and evidence

```sh
autowork-run timeout 1500 python3 scripts/run_linux_feature_qualification.py \
  --lane chat --output-dir "$TMPDIR/linux-qualification"
```

Use the explicit compatible SDK, Node 22, package cache and reviewed dependency
prefix required by the [campaign driver](linux-qualification-driver.md).
The [native target](../../integration_test/linux_chat_feature_qualification_test.dart)
refuses execution outside its launcher-owned root. Its
[fixture](../../integration_test/support/linux_chat_feature_fixture.dart) publishes
schema-1 `feature-cases.json` atomically directly beneath `WING_LINUX_TEST_ROOT`,
then leaves GTK alive briefly for the driver's process observation.

Case IDs are registered independently of test execution. Missing cases become
`not_run`; exceptions leave `fail`, not synthetic success. The driver rejects an
incomplete inventory. `owner_count` describes the exercised session-owner tuples;
operation counts distinguish submissions, stale controls and deliberate fixture
cleanup. Non-run rows carry no operation-completion claim. Case metadata retains
feature identities even when a selected test never starts. Receipts and logs stay
private; they are not committed transcript or endpoint artifacts.

## Coverage inventory

All rows concern `/hermes`; Settings is also exercised as a retained-Chat overlay.
The exact IDs below use the `chat.` prefix.

| Cases | Observable outcome | Feature families |
| --- | --- | --- |
| `native-stream-stop-recovery` | Reuses production wire Send/stream/tool/approval/Stop and uncertain recovery; two sends, one accepted approval, one Stop, zero stale approval responses or replay | HD-CHAT, HD-APPROVAL, HD-STOP, HD-RESUME |
| `bot-canonical-draft` | Public Bot Chat adopts hidden canonical tip/history, excludes it from ordinary recents and restores the ordinary draft on return | HD-BOTS, HD-DRAFT |
| `bot-reject-registry`, `bot-reject-hidden`, `bot-reject-history`, `bot-reject-replacement` | Wrong registry identity, visible tip, missing reported history and delayed lookup after profile replacement cannot create, send or adopt | HD-BOTS, HD-DRAFT |
| `queue-owner-draft` | Two rendered FIFO entries remain bound to the source; its competing terminal completion cannot send into or consume the replacement session's draft | HD-QUEUE, HD-DRAFT |
| `queue-fifo` | Real loopback session-chat SSE admits exactly the original and two queued payloads in order, advancing only after each synthetic terminal result | HD-QUEUE, HD-CHAT |
| `api-tabs-search-pages` | Public exact-tab activation restores its draft; local search and explicit second-page loading do not mutate or change selection | HD-TABS, HD-SEARCH, HD-DRAFT |
| `api-session-actions` | Public pin/unpin, rename, branch and delete preserve exact identities; only the three advertised Agent mutations occur | HD-SEARCH |
| `api-model-retry` | Rejected session model selection remains available; only a separate explicit retry commits it | HD-MODEL |
| `local-timestamps` | Public slash aliases reveal/hide timestamp labels without HTTP/RPC mutation or session change | HD-COMMAND, HD-CHAT |
| `attachment-owner` | A real GTK attachment chooser completed after session replacement cannot stage a file or overwrite the new draft | HD-ATTACH, HD-DRAFT |
| `stale-stop` | A cached rendered Stop callback cannot interrupt a newer session run; subsequent explicit fixture cleanup stops are counted separately | HD-STOP |
| `json-save`, `json-refuse`, `json-cancel`, `json-owner` | Consent precedes fixed 500+1 raw-history reads; real chooser selection is separate from replacement consent, refusal, cancel and owner fencing; Unicode destination bytes and unchanged live projection are checked separately | HD-EXPORT, HD-DRAFT |
| `loaded-text`, `loaded-markdown` | Real GTK saves equal public clipboard bytes, with no history backfill | HD-EXPORT |
| `json-cancel-read` | Cancellation discards a delayed HTTP page after observing its server response completion; no partial Save is offered | HD-EXPORT |
| `streaming-overlay` | HTTP/SSE completion beneath Settings retains the mounted Chat, transcript and draft, with one submission | HD-CHAT |
| `native-contract-gaps` | Negative controls: no native-serve tabs or attachments; unsupported clarification returns a correlated negative RPC response, not approval | HD-TABS, HD-ATTACH, HD-CLARIFY |
| `json-frozen-boundary` | Consent explicitly denies frozen-snapshot/atomic-completeness/backup guarantees; cancelling makes zero raw-history reads | HD-EXPORT |
| `two-process-recovery` | Two separately launched GTK processes share only private preferences and synthetic fixture history: deliberate model/send/approval in phase one, exact off-page profile/session/history restoration with zero mutations in phase two | HD-RESUME |

## Fixture and platform limits

The native REST/RPC fixture uses synthetic bearer and one-use ticket authentication;
API HTTP/SSE scenarios use the existing credential-free Node fixture. Neither is
live authentication or provider qualification. All channels are production
`HermesApiChannel` instances. The FIFO-only loopback fixture exposes the existing
session-chat SSE contract, rather than relying on Node's advertised but unimplemented
session-stream route; it records actual submitted payloads and terminal gates.
It is test data, not a backend or product fallback.

Ordinary controls use Flutter framework pointer/text injection. File/save chooser
input uses X11 events on the owned Xvfb display and real GTK/file-selector plugins.
The delivery-gated attachment picker observer delegates to real `openFile`, verifies
the selected synthetic file, then releases it after the replacement draft exists;
it does not substitute a chosen file. Preferences and saved-contact directory dependencies are deterministic
fakes. This does not qualify physical keyboards, Wayland, IME, screen readers,
real SSH, provider execution, or packaged artifacts. Native-serve tabs, attachments
and clarification, and frozen-snapshot JSON remain unsupported subsets, even when
their negative cases pass.

The existing [stream-under-overlay harness](../../integration_test/run_linux_chat_workspace_stream.py)
and [broader daily restart harness](../../scripts/run_linux_integrated_daily_restart.sh)
remain unchanged. The new restart case reuses that harness's
[wire/state fixture](../../integration_test/support/integrated_daily_restart_fixture.dart),
with worker-reserved port allocation. It sequentially launches this same native
target in two fixed phases while the parent is idle; compiler writes never overlap.
The phases use real isolated preferences, not the ordinary cases' preference mocks.
The parent observes both distinct GTK PIDs/start ticks in its owned process group,
checks terminal exits and native termination, and embeds source hashes, child logs
and their digests in the case receipt. The second launch must restore the exact
remembered off-page session and canonical reply without a model write, Send or
approval replay. Missing phase receipts, changed source, unobserved processes or
non-terminal children fail the case. The aggregate driver still binds the complete
source/tool/dependency tree and owns final group/state cleanup.

This is a focused cold-restoration observation, not a claim that the broader daily
restart wrapper ran or that every phase of that wrapper was reproduced. Actual
Agent projection, lineage/compaction and GTK/live export acceptance remain on the
[paged JSON qualification gate](paged-session-json-export.md#pending-qualification).

## Current execution disposition

The earlier candidate `a6d6edcb` recorded 24 standalone GTK tests and a campaign
preflight refusal, not aggregate success. This continuation preserves those cases
rather than reimplementing them. The shared qualification task repaired validation
of stock native-only packages on the current baseline; no shared-driver validation,
manifest or lockfile is changed by this lane. The task-local root guard also accepts
Python tempfile's underscore suffix while retaining canonical-parent, marker,
HOME/XDG and symlink containment checks.

The first current-source campaign also reproduced an existing keyboard-runner
fixture defect on baseline `aeffb602`: it allowed only `run_1/events` although its
public GTK case deliberately creates a second run. The narrow prerequisite repair
in [the transcript fixture](../../integration_test/support/transcript_recovery_native_fixture.dart)
records issued event paths (plus its fixed recovered lease owner), allowing both
known-run reattachment and a newly issued run while still rejecting unissued event
owners. A focused [fixture regression](../../test/tooling/transcript_recovery_fixture_test.dart)
protects that distinction. This is a test-harness repair, not a transport feature,
shared-driver bypass or relaxation of origin/profile checks.

The exact Chat campaign completed on Linux X11/Xvfb GTK using Flutter 3.44.2,
Dart 3.12.2 and Node 22.22.2. Its native target completed **25 tests**, producing
25 unique schema-1 cases: **23 `pass`, two `unsupported`, and no failed, non-run or
gap rows**. The local-serve-read and transcript-keyboard runners both completed
with exit 0 and validated receipts. Both restart child phases completed with exit
0, distinct observed GTK PIDs and no live native child remaining; phase two made
zero Agent mutations. The driver recorded all three command exits as 0 and final
owned-group/state cleanup as complete. The receipt binds the frozen candidate's
actual source hashes, not merely its earlier standalone results.

Changed-Dart formatting, full `flutter analyze --no-pub`, the two-test focused
transcript-fixture module and scoped documentation link/readback checks passed.
No dependency manifest, lockfile, shared driver, Agent or product implementation
was changed. Fixture completeness remains separate from live/platform
qualification; the coordinator's full offline suite is separate and was not rerun
by this worker.

Revisit this document when the case registry, transport selection, Bot ownership,
queue admission, timestamp renderer, native picker/saver, campaign dispatch or
restart evidence changes. The [campaign plan](../plans/2026-10-21-linux-feature-qualification.md)
and existing live tasks retain their acceptance; this test lane does not close PARITY.
