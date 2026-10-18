# Canonical submission, pending queue and clarification contract

## Verdict and scope

`PARITYUPDATE-002-5c` · `CHAT-FIDELITY` · HD-CHAT, HD-DRAFT, HD-QUEUE, HD-CLARIFY.
**Source contract resolved; no product implementation or runtime qualification.**

Start here: the admission, queue and clarification matrices below. This is the
[source-only pending-input follow-up](official-desktop-parity-refresh-2026-10-18.md#pending-input),
not permission to submit, mutate a queue, answer a question or change Agent.

The unmodified pin provides canonical durable admission, authoritative FIFO and
row-specific controls, plus two distinct clarification mechanisms. None is
currently consumed as that contract by Wing. Two guarantees must **not** be
combined from different transports:

- Canonical `prompt.submit` deduplicates a stable submission identity and returns
  an admission receipt, **not a send-time `user_row_id` receipt**. Desktop's optional
  user-row binding is also used with standalone serve, whose submit schema lacks
  `submission_id` and whose statuses are different. A durable admitted payload is
  not proof of a durable transcript row with a correlatable row ID. [A1–A5, A12–A13, D1–D2, T1, T9]
- Canonical generation-bound single-question prompts have snapshot/replay support.
  Local viewer batch `clarify.lock` uses an in-memory request registry instead;
  this pin does **not establish authoritative reconnect restoration of its batch
  questions and partially locked answers**. Desktop's ability to display supplied
  `lockedAnswers` is not evidence that this owner supplies them after reconnect.
  [A2, A4, A7–A11, D5, T6–T8, T10]

These are precise unavailable boundaries, not requests for upstream changes.
Current Android SSH → profiles/multi-session → canonical Bot Chat → touch priorities,
Files/slash deferrals and existing owners remain unchanged. No matrix runtime cell
or product support classification advances.

### Evidence identity and authority

- Agent: `a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70`; official Desktop tree:
  `cee4414aae0817b7ff45c76fbfd010dcd753ecf5`.
- Wing caller/test baseline: `83893c1a0fa686372f1f1fdf7aa72a7fdf3ac3c2`.
  The matrix's older global Wing inspection pin is retained as history.
- The ledger binds exact inclusive ranges and whole-file SHA-256 to those pins.
  Agent blobs were read into task-temporary storage from immutable official raw
  URLs and checked against the pinned Git tree's blob identities. The permanent
  reference checkout, installed runtime and personal services were untouched.
- All test citations mean **assertions inspected, not tests executed**. Commands
  described below are wire contracts, not commands run by this task.

Canonical `/api/ws` authentication, private interactive tickets versus dashboard
credentials, home/instance binding and resume incompatibilities are separately
resolved in the [attachment contract](canonical-gateway-attachment-contract.md).
Its feasibility is not a new remote operation grant. `runtime.describe` advertises
`durable-admission-v1` and replay labels, not an exhaustive operation/authorization
catalog. Canonical declarations and handlers establish a source contract; only the
connected unmodified Agent's exact supported wire, grants and current ownership
can admit a future Wing operation. Desktop preload/private IPC or `mode:local`
queue selection alone cannot do that. [A3, D3, T11]

Keep connection/origin + attempt generation, authenticated principal, Agent
home/profile, owner instance/authority epoch, logical session, replay epoch/sequence,
and admission/execution generation distinct. The same session ID may occur in two
profiles. A host-scoped connection may explicitly route `profile` to a currently
served sibling; a profile-bound connection cannot. No global profile selection,
foreground-socket substitution, replacement conversation or other-transport retry.
Operator access never transfers the original admission's principal identity.
[A3–A4, T12]

## 1. Submission and durable receipts

### Operation matrix

| Operation | Exact contract and authorization | Source disposition / nearest assertions |
| --- | --- | --- |
| `session.resume`, `session.events.since` | Read/reconcile the selected profile/session; `session:read`. Snapshot supplies subscription, epochs, revision, execution generation, ordered pending rows and generation-bound prompts; pending rows carry `input_id`, text, status and optional controls/steering. | Existing canonical source contract, not Wing's legacy `lazy:true` resume. Snapshot/replay is not mutation replay. [A2–A4, T8, T11] |
| `prompt.submit` | Attached session required; `session:submit`. `{session_id,submission_id,text,…}` (legacy canonical alias `input_id`; use one stable ID). Admission key is authenticated principal + target session + request ID in the owning profile store. Canonicalized admitted payload **and intent** are digest-bound; queued admission is the normal path even for an idle session. | Same key + same payload returns the same admission at its current status; changed payload/intent returns `admission_conflict`. New sends require new IDs even for equal text. Canonical `queued` does not select an independent client queue or a steer intent. [A2–A5, T1, T12] |
| `prompt.receipt` | `{session_id,admission_id,include_result?}`. Requires `session:submit`, matching target, and original principal or `session:control`. Optional result/usage only for terminal work with a saved result. | Reads current admission, not a submit-by-ID status endpoint. Receipt carries `admission_id`, `ref`, `sequence`, `status`, `outcome`, `authority_epoch`, nullable `execution_generation`; no `submission_id` echo or `user_row_id`. Desktop adds its own submitted ID after checking destination. [A1, A3–A4, D2, T11–T12] |
| Standalone serve `prompt.submit` | Different `PromptSubmitParams/Result`: no stable submission-ID field; statuses `streaming/queued/steered/redirected`; optional `user_row_id` only when proven, absent on queued/steered/redirected inputs. | Handler writes a user row before starting its worker when persistence succeeds and captures that row's ID for the ACK. Tests inspect durable-at-submit and two equal prompts receiving different rows. This does **not** provide canonical stable retry plus durable-row correlation. [A12–A13, A15, T9] |

`submission_id` is a client retry identity, `admission_id` is an Agent-issued
accepted-work identity, `input_id` in a pending row echoes its request identity,
and a transcript row ID is a fourth identity. Do not substitute one for another or
match a row by equal text/newest occurrence. Canonical receipts can be masked as
started until completion publication catches up; an ACK is never model output.
[A1–A5, D1–D2]

### Admission status matrix

| Authoritative status | Meaning and exact retry | Deliberate changed send / recovery |
| --- | --- | --- |
| `queued` | Committed durable input, ordered by Agent sequence; not proof that inference started or a user transcript row was written. Exact explicit retry returns its existing admission, not another FIFO row. | New ID means separate input at the tail, not edit/retry. Read pending projection before offering controls. [A4–A5, T1–T2] |
| `started` | Claimed for one execution generation; exact retry must not execute it again. A queued steer transfer also projects `started` with `steering:true`. | No replacement/queued cancellation success may be inferred from cached queued state. Stop targets the exact generation and remains uncertain until authoritative settlement. [A4–A6, T2–T4] |
| `terminal` | Settled outcome (for example completed, failed, rejected, interrupted, cancelled or steered); exact retry does not promise a new completion event. | Read receipt/transcript; do not synthesize output or a missing durable user-row ID. A new ID is new work, never recovery of this receipt. [A1, A4–A6, D1, T1–T3] |
| `unknown` | Previously started work lost across an owner epoch (or unresolved settlement); FIFO followers stay blocked. Exact submit retry returns unknown, not permission to execute. | Reconcile and offer explicit generation-bound resolution where authorized. New input can queue behind unknown but cannot resolve it. Never auto-resend, change transport, or mark idle from socket loss. [A4–A5, D1, T1, T5] |

### Exact retry is not a changed send

Desktop captures scope/attachments, retains prepared params and identity, and
restores only the matching composer scope. An explicit restored-draft retry can
reuse its ID; equal text in a fresh send does not inherit an uncertain identity.
The optional row binding targets only that send's optimistic occurrence. Its
canonical adapter injects the submitted identity into the client-facing receipt;
that is not an additional server guarantee. [D1–D2, D7, T13]

For a future Wing adapter, preserve the exact owner, principal, ID and normalized
payload (including supported attachment/presentation fields); edits are new intent.
The pin compares the admitted payload, not text alone. Do not acquire a different
principal after reconnect and assume the old ID still deduplicates it. Unknown
ACK/timeout/malformed receipt is not pre-admission rejection. Desktop's identityless
downgrade is narrowly limited to explicit pre-handler refusal, and is **not** a
fallback admitted by this study for Wing. [A3–A5, D1, T1, T12]

On reconnect, read authoritative snapshot/replay and correlate pending `input_id`
with retained intent. `prompt.receipt` needs the admission ID; the pending set does
not include settled history. If an ACK and its ID were lost and pending readback
cannot resolve them, remain uncertain; only a separately qualified, **explicit
exact retry** could reconcile through submit. Never silently replay cached
mutations or mint a new ID to escape uncertainty. No indefinite receipt-retention
or safe retry after deletion/pruning is established by this study. [A1–A5]

## 2. Authoritative pending FIFO and controls

One Agent-owned FIFO per logical session; queued rows survive owner replacement,
while old started rows become unknown and pause the drain. The cap is 32 queued
admissions, including while paused. Clients project sequence/status, never reorder
or maintain a second authoritative queue. Server execution of already accepted
work is not Wing replaying cached writes. [A4–A6, T1–T3]

### Queue operation matrix

`profile` routing remains explicit on the owning connection where supported;
identity fields below are in addition to that envelope.

| Operation | Params / grants / availability | Commit, replay and race result |
| --- | --- | --- |
| `prompt.cancel` | `{session_id,admission_id}`; receipt access as above (`session:submit`, own principal or control). | Still queued → terminal/cancelled; settlement retires observers once. Already terminal → existing receipt. Initially started → `stale_generation`, unknown → `unknown_execution`. If handler read queued but drain claims before cancellation, it hard-interrupts **that claim's generation** and may return started, not proof of completion. This race additionally needs `session:control`. A concurrent steer transfer is refused, not cancelled. [A3–A6, T2–T4] |
| `prompt.resolve_unknown` | `{session_id,admission_id,execution_generation}`; `session:control` plus receipt access. | Explicit acknowledgement, never requeues lost input. Same-transaction transcript closure + terminal/interrupted resumes followers; if this owner captured a completed result before failed settlement, commit that result instead. Stale/non-unknown generation is refused; exact settled resolution can return its prior receipt. Closure failure rolls back and leaves the unknown fence. [A1, A3–A5, T5] |
| `prompt.steer_queued` | `{session_id,admission_id}`; `session:control` plus receipt access. Offer only if this pending row advertises `controls:['steer',…]`; interactive source, visible nonempty plain-text payload only. | Atomic transfer out of queue, bound to current running generation; cannot also run as a queued turn. Exact transfer retry does not deliver twice. Not queued → `admission_started`; idle/no receiving agent → `session_idle`/`steer_unavailable`; ineligible row → `unsupported_control`. [A2, A5–A6, T2–T3] |
| `prompt.replace_queued` | `{session_id,admission_id,submission_id,text,attachments?,display_kind?,title_preview?}`; attached session, `session:submit` plus receipt access. Not inherently a `session:control` verb. Offer only advertised `replace`; old-row eligibility is narrow like steer. | One admission transaction retires old queued row and appends a **new** admission at FIFO tail; not an in-place edit and never cancel-then-submit. Exact retry binds old admission + new ID + payload; reusing new ID for another old row is `admission_conflict`. Claim wins → `admission_started`, no new admission. Definitive pre-commit transaction refusal (including capacity/validation rejection) commits neither half; a generic storage error can occur **after commit** during readback, observer settlement or media cleanup. Preserve uncertainty: reconcile or deliberately retry the identical old-admission/new-ID/payload tuple, never infer non-commit or cancel-and-submit. Cap is checked before old-row retirement, so even replacement can return `queue_full`. [A2–A6, T2–T3] |
| `session.interrupt` | `{session_id,execution_generation}`; `session:control`. | Hard interrupt (including pre-adoption latch), scoped background work interruption; stale generation refused. Returns a session handle, **not** terminal cancellation proof and not blanket cancellation of pending followers. [A2–A4, T4, T14] |

The Desktop cancel helper's comment still says a race-to-start is simply refused;
the pinned Agent handler and nearest race test instead implement the queued-read →
claimed → hard-interrupt path above. Trust the handler/test, not that comment. [D4, A3, T4]

### Queue status/control matrix

| Row status | Cancel | Resolve unknown | Steer queued / replace queued |
| --- | --- | --- | --- |
| `queued` | Cancel or exact claim-race Stop; re-read receipt. | Refuse stale generation/non-unknown. | Only row-advertised controls; transaction arbitrates a racing claim. |
| `started` | Refuse if initially observed started; do not generalize the queued-read race exception. | Refuse while known started. | Refuse `admission_started`, except exact already-committed steer replay. |
| `terminal` | Return existing receipt; in-flight internal steering marker is not cancellable. | Matching generation plus terminal/interrupted **or any saved result** returns its receipt; otherwise stale. This check does not require prior resolution provenance. | Exact committed steer or replacement replay only; no new edit of spent work. |
| `unknown` | `unknown_execution`, never success. | Explicit exact admission + lost generation, with authority checks. | No new queued control on that row; followers remain queued until resolution. |

Sources for every cell: dispatch/control [A3], authority [A4], transactions [A5],
queued handlers [A6]; nearest assertions [T1–T5].

A steer transfer projects `started, steering:true` until its receiving claim settles.
Consumed text + completed claim → terminal/steered; delivered text under failure or
interruption → interrupted. Text the agent never consumed returns to its original
FIFO position; commit/delivery race may return `steer_unavailable`. Owner death
mid-transfer marks it interrupted, **never automatically replays it**. Keep its
rank while steering: disappearance is not proof it was spent. [A4–A6, T3]

## 3. Staged clarification, Confirm and Skip

Clarification is not ordinary `prompt.submit`, a steer or an approval choice.
There are **two** unmodified canonical paths:

1. Default generation-bound `clarify.request` event / snapshot prompt →
   `clarify.respond {session_id,execution_generation,prompt_id,answer}` with
   `session:respond`. `PendingControls` owns one live question, retires expired or
   settled prompts, and rejects stale generations. Desktop presents a one-question
   batch-shaped card and translates its apparent `clarify.lock` to this wire;
   null Skip becomes empty-string answer. [A3–A4, A10–A11, D8, T8, T10, T16]
2. A local-viewer turn explicitly admitted with `clarify_batch:true` → one `clarify`
   server request carrying `session_id` and `questions` (`qid/question/choices/multi_select`).
   Its JSON-RPC `srq-…` ID binds `clarify.lock {request_id,question_id,answer,profile?}`.
   **No `session_id` or execution-generation field is in this lock schema**: the
   server resolves the request's own stream/session and requires an attached actor
   with `session:respond`. Equal session IDs on a different profile cannot answer.
   [A7–A9, A11, A13, T6–T7]

The pinned Desktop submit-params builder does not set `clarify_batch`; the ordinary
canonical path above therefore must not be described as an opted-in multi-question
batch merely because the shared panel supports one. [D1, A11, D8]

### Clarification operation/status matrix

| State / action | Authoritative result and safe interpretation |
| --- | --- |
| Preview or locally staged picks | Tool-argument synthetic qids are disabled display only. Single/multi-select/free text stays local until deliberate Confirm; no request identity means no answer operation. [D5, T15] |
| Live batch Confirm | Capture owner + request ID + real qids; send locks **sequentially**, awaiting each before the next. Empty staged answers use null (skip that question); final accepted lock returns `ok, remaining:[]` and settles submitted. Multi-select is a JSON-string array, not a second submission. [A7–A9, D5, T6, T15] |
| Partial locks / failed Confirm | Earlier accepted locks survive a later failure. While request remains open, locking a qid again replaces its prior answer; locks are **not immutable** and Confirm is not an atomic batch transaction. Do not invent rollback, mark all answers saved, or replay remaining locks automatically. [A8–A9, D5, T6–T7] |
| Skip / plain Escape (batch) | Respond to captured server request ID with `{}` (no `answers`), not a prompt send. Result is cancelled **with already locked answers retained**; unconfirmed local picks were never locked. A closing frame with an answers map overlays prior locks and normally settles submitted. [A8–A9, A14, D6, T7, T15] |
| Timeout / interrupt / cancel after partial locks | Timed-out/cancelled result retains locked answers; `request.cancel` closes other viewers' matching card and contains no answers. This is not confirmation that every staged answer arrived. [A8–A9, A14, T6–T7] |
| Stale/request-mismatched batch | Unknown/closed request, foreign stream/profile, unattached actor or missing respond authority → `expired`, **not success**. Unknown qid on a live entitled request → `invalid_params`; malformed IDs/extra keys rejected. Do not move answers to a new request with coincidentally equal question text/qids. [A3, A7–A8, T6] |
| Default single question / stale generation | Reconcile live prompt ID/generation; answer only that question. Already expired/resolved prompt returns already_resolved, wrong kind/invalid answer refuses, stale generation refuses. This is not the batch lock registry. [A3–A4, A10, D8, T8, T10, T16] |
| Reconnect / process replacement | Generation-bound prompts have snapshot hydration. Batch registry/locks are process-memory only; this source does not project them into canonical snapshot `prompts`, nor establish persisted batch recovery. Desktop fixture-provided batch `questions/answers` and local staging reset are not producer proof. Keep uncertain partial state unavailable until authoritative readback; never silently resend answers. [A2, A4, A8–A11, D5, T6–T8, T10] |

Desktop's Confirm loop awaits calls but does not validate each returned `expired`
status before clearing its card. Do not copy that optimistic presentation as proof
of authoritative success. Its next-request reset and locked-answer pre-staging are
useful presentation patterns, not a missing request/lock recovery API. Any future
Wing batch implementation must distinguish expired from saved, preserve partial
locks without claiming all-or-nothing, and resolve the reconnect gap separately.
[A7–A8, D5]

## 4. Wing callers and bounded disposition

| Group | Inspected Wing boundary | Disposition |
| --- | --- | --- |
| HD-CHAT | Native lifecycle sends profile/runtime session + text, no submission ID; accepts legacy streaming/queued/steered/redirected. Unrecognized ACK becomes uncertain; reconnect is reconciliation without send. Stop lacks canonical generation params and expects a legacy status receipt. Nearest lifecycle tests preserve uncertainty and zero duplicate submits. [W1, W5] | Canonical stable admission/receipt adapter **absent**, not enabled by broadening a status allowlist. Canonical send-time durable-row receipt **absent at this pin**; standalone row evidence cannot fill it. |
| HD-DRAFT | Volatile gateway/profile/session draft + generation-conditional restoration; captured submission stores no canonical ID/frozen wire params. [W2, W6] | Keep owner-safe draft behavior. A restored draft is not an exact canonical retry; bounded identity/payload work remains separate from per-pane presentation. |
| HD-QUEUE | Bounded process-local FIFO, session parking/removal/requeue; message flow drains when eligible, except native serve is explicitly excluded. No authoritative admission ID or row controls. [W3–W4, W7] | Not canonical pending projection; never wire its local drain/requeue to canonical reconnect. Exact server FIFO/control contracts exist in source, but Wing consumer/authentication/operation gates and qualification are absent. |
| HD-CLARIFY | Native lifecycle interface offers text/interrupt/approval only; non-approval server requests receive unsupported-operation response. [W1, W8] | Both canonical clarification consumers and staging model **absent**. Approval correlation is not question correlation. Source-traced single-question feasibility does not establish complete batch/reconnect fidelity. |

A separately bounded successor could adapt canonical admission/receipt and pending
read projection **after** canonical attachment and exact operation/grant gating,
with explicit retry/changed-send tests and generation-bound Stop. Queue controls
must use advertised per-row verbs and the transaction/race semantics above; no
local queue replacement. Single-question clarification can be evaluated separately
from opted-in batches. Do not promise the combined durable-row or reconnect batch
guarantees without an exact unmodified advertised producer contract. This analysis
admits no implementation successor automatically and blocks no existing Android work.

Preserve the [API/state](../adr/api-and-state.md) and
[security](../adr/security-and-privacy.md) rules: server state wins; no automatic
mutation replay; owner uncertainty is not idle/completed; no shadow queue/backend,
raw Agent files, arbitrary shell, provider effects or personal-service actions.

## Documentation validation and update triggers

Complete offline gate for this documentation-only task: `git diff --check`; matrix
JSON parse; verify each ledger path/range/whole-file SHA-256 against its immutable
pin and Agent Git blob identity; source-check every operation against the named
handler/nearest assertions; verify changed local links and preservation of **all**
matrix runtime cells. These are documentation checks, **not executed protocol tests**.
No Flutter/browser build, Agent/application test, ticket mint, inference, queue
write, answer, device or live connection was exercised. Linux/Android and real
Agent compatibility remain separate authorized qualification work.

Revisit when the Agent pin, admitted payload/schema, receipt shape, queue controls,
claim/cancel/replace transaction, clarification producer/registry/snapshot, Desktop
adapter or Wing caller changes. Retrace and rehash; never only repin citations or
promote unrelated historical fixtures.

## Pinned source ledger

`A` = Agent handler/schema, `D` = official Desktop caller, `T` = nearest inspected
upstream assertions, `W` = Wing caller/test. Ranges are inclusive; SHA-256 covers
the **whole file**, not only the excerpt. Resolve A/D/T paths under
[the immutable Agent tree](https://github.com/NousResearch/hermes-agent/tree/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70),
and W paths under
[the immutable Wing tree](https://github.com/TrebuchetDynamics/hermes-wing/tree/83893c1a0fa686372f1f1fdf7aa72a7fdf3ac3c2).
A blob citation is `blob/<pin>/<path>#L<start>-L<end>` for each listed range.

<!-- source-ledger:start -->
| ID | Source path | Inclusive ranges | Whole-file SHA-256 |
| --- | --- | --- | --- |
| A1 | `tui_gateway/contracts/canonical.py` | `24-76,330-350` | `b6746b6434a44abf6bb0adb44aedcd19275d23d23a1ff0c05873ee130945941d` |
| A2 | `tui_gateway/contracts/canonical_sessions.py` | `74-152,199-266,290-316` | `d42e0a19edaadd99c3767cbb5db4fae8b82e34d616a9ffc61f490257a86a72c0` |
| A3 | `gateway/session_controls.py` | `90-99,140-173,188-198,239-330,484-495,561-641,675-709,726-791` | `36b5c66f45d2a0108bbc6b5df6eb3df2e9837195aa1da50379a209e11b2211c1` |
| A4 | `gateway/session_authority.py` | `140-176,245-317,347-365,537-595,615-672,700-786,848-851,879-893` | `9aae73408c70b57383d60d203469473454f30421256bcc3e43765650fd61b419` |
| A5 | `hermes_state_runtime.py` | `124-259,264-367,437-447,639-679` | `a4d2068fffcd61652e0ab02385b4f1e7c83e28a6c7a9b305acc25549eb77f59f` |
| A6 | `gateway/session_queued_controls.py` | `22-75,82-133,136-240` | `0c4e6a7054a891c5a625d4ce4940c2257555d75ac217ab8db6ce2302052ef903` |
| A7 | `gateway/session_clarify_lock.py` | `14-38` | `547297e0ad7ddae8f65808a317b3ea9db848acf441dce7da4f5854a4f52cc8e2` |
| A8 | `gateway/session_server_requests.py` | `25-38,40-93,112-173` | `27fb4abf8612568a94cea83cbf29616a595a7feff3fb4bded0302cf20ea495d7` |
| A9 | `gateway/session_clarify_batch.py` | `16-42` | `36e3ce02ec9d07f2f821cc1721a47e1ab2ff6f65d0b21499553dde4291475f30` |
| A10 | `gateway/session_pending_controls.py` | `40-101` | `c8ae36accdce384e09c62025bbe93ef11b07e82139b11625f1c94ccc0d56d3f1` |
| A11 | `gateway/session_cli_turn.py` | `25-62,157-164` | `23f46855c1b4bc9fc59e7a54326fb0bf34de57fbb0e555811b72dc4a3904a899` |
| A12 | `tui_gateway/methods_prompt.py` | `612-637,937-953` | `13308080918f6c740fe06719751ef9126f49c271d81686f0ca7ec6921c0da8c0` |
| A13 | `tui_gateway/contracts/prompt_voice.py` | `26-85,257-278` | `f9e9d26aaf9f8d6c4a85359d90d54285b8463ecde9df93a2509902db6fe574ae` |
| A14 | `tools/clarify_batch.py` | `16-31` | `edc24ee71490dbea0abbbdfc4b957776e82ea12782ac0a5a614e0febc5894c78` |
| A15 | `tui_gateway/session_workdir.py` | `673-763` | `079bec4a960a280194ccd0ea429625ab336dd1ba801b530bfbdcb981f5920b3a` |
| D1 | `apps/desktop/src/app/session/hooks/use-prompt-actions/submit.ts` | `1080-1105,1116-1179,1210-1296` | `54127a8b43762a771f67cbef5be47dc4ce2e2b80445e6b00e97cab1282040ea3` |
| D2 | `apps/desktop/src/api/canonical-protocol.ts` | `596-615,668-682` | `c4bee44975226234197da59b39e8fc36ec7033b34fc0177708e6e894adfa2a3e` |
| D3 | `apps/desktop/src/store/composer-queue.ts` | `13-73` | `8f5856d9ec91cd72f9aef05bdf58f1e0cb4e72b09d0849b8374476c771f07cb9` |
| D4 | `apps/desktop/src/app/chat/composer/discard-lost-prompt.ts` | `4-67` | `84959418773a825cb2184a36a0b96e06a9259eb12f383a678f26c5726e17cc15` |
| D5 | `apps/desktop/src/components/assistant-ui/clarify/pending.tsx` | `31-218,244-254` | `5b0661f7ae0719ba5c85641c23dda6d90e0379221d70112cd1b75e0e590f4037` |
| D6 | `apps/desktop/src/store/clarify.ts` | `230-249` | `e4520fd99d642b47e419338a92def847bf1a823ac79d2c9cc4bcc3825481203c` |
| D7 | `apps/desktop/src/app/chat/composer/hooks/use-composer-submit.ts` | `107-169,419-431` | `a7b5091e42f231f831dd4aae3ee4efd91117fd0744fd53b1d6d392c4ffb3a01e` |
| D8 | `apps/desktop/src/api/client.ts` | `401-406` | `d32cbc9442865dcab9d0a8d85176c4ea71f08af5b1c6b1b29079fc8c13252c9d` |
| T1 | `tests/hermes_state/test_runtime_admission.py` | `17-94` | `d97821b2a183e32fa93447418f6bce0601d712433c5c9f850dd3c0fdea3faf01` |
| T2 | `tests/gateway/test_prompt_queued_controls.py` | `77-251` | `29b566fcb573bcb963e5a0c0f6ea0b6d079dc77cc4e3817f69342a4bafef8922` |
| T3 | `tests/gateway/test_prompt_queued_transfer.py` | `31-175,244-381,436-536` | `5a1e3c88efdc478f274db275e4b71995f4c0439ddd79417a74fb16c55eac01c6` |
| T4 | `tests/gateway/test_prompt_cancel_claimed.py` | `1-33` | `9c80557be9df546728947a3fd69e24e8e7479a50186c33375439bacb5e9cc354` |
| T5 | `tests/gateway/test_unknown_receipt_boundaries.py` | `22-93` | `ff4aad54d7fcfb433e1b0eb33b6e523ea4880d169d040675c73a8f36e11f2e0d` |
| T6 | `tests/gateway/test_clarify_lock_owner.py` | `63-226` | `e28355bf851e884cf6dbc93d902b941c62e832e951c375b50537127145c53304` |
| T7 | `tests/gateway/test_clarify_lock_keeps_locked_answers.py` | `15-83` | `dd4b20ec81732bf6f00ab2ba3ed94e2542579b4cb821aeb4e7ba7f422174e87f` |
| T8 | `tests/gateway/test_shared_clarify.py` | `8-37` | `0f94573400a3e11281edbe86252d7a178542625e9d1e8c6e12befd1c269fff94` |
| T9 | `tests/tui_gateway/test_submit_time_user_row.py` | `35-108` | `baa5cd1a9e314d471f0ba422a0b035f4637edc79bc9fd6fad2988078a7b8692f` |
| T10 | `apps/desktop/src/api/canonical-clarify-lifecycle.test.ts` | `24-126` | `4a87b3a9e77cccb758a655e84b1870fbfd15a145d00656296a464cd25bd0e837` |
| T11 | `tests/gateway/test_canonical_wire_contract.py` | `25-56` | `9a0a0280895f81031c552b099183c19b0a5de5d8a9d701933d016492dbc1d516` |
| T12 | `tests/gateway/test_session_operator_scope.py` | `13-125` | `ecb49eab798b05476da6174b4cd444dd804d3da292194593b9209fcf4070eb60` |
| T13 | `apps/desktop/src/app/chat/composer/hooks/use-composer-submit.restore-scoping.test.tsx` | `285-337,544-596` | `9160df16e6c7311c0fccbcdb9f1aa71713dcd56e42a5842dab135759f53b25fb` |
| T14 | `tests/gateway/test_canonical_stop_hard_cancel.py` | `1-62` | `b89af683dfdf280a97244d4d8611307834ff87a77ed39f6552e2d6c98537ead6` |
| T15 | `apps/desktop/src/components/assistant-ui/clarify/clarify-tool.test.tsx` | `733-885,1054-1100` | `6dc7e3be7d2ebc1bf2da1e354e9b45c10901160ed95f0777bef111a5f3de6d20` |
| T16 | `tests/gateway/fixtures/authority_clarify_peer.py` | `88-122` | `c89e9a15aa4e75708fa792daaf745a983a76a5e36fdc5b6c62b04a4bd65bb616` |
| W1 | `lib/core/hermes/client/hermes_web_lifecycle.dart` | `222-247,300-425` | `d468d69c565fd142180e635e470217d18ccf8ca172ac806b3353fb3b55167090` |
| W2 | `lib/features/hermes_chat/composer/hermes_composer_draft_store.dart` | `7-35,83-111` | `d37aeddee9687202254e541af28577313eeaa6ed0f25344650d01894721d6145` |
| W3 | `lib/features/hermes_chat/controllers/hermes_follow_up_queue.dart` | `7-169` | `74cb2ac5d5e637eba905da0dbb769c63ce5655426a2b561f53e20f2e7a5320be` |
| W4 | `lib/features/hermes_chat/composer/hermes_chat_message_flow.dart` | `315-332,383-463` | `c4c1aadc53fb3d372a4068545f668ceb312bbea1b9c4c4979b1530fbbf79c56e` |
| W5 | `test/core/hermes/client/hermes_web_lifecycle_test.dart` | `392-450,470-490` | `7be8f6ed5a115b80bfa4558d5fb44b97028eb18a73cd9b271076e0092e37708e` |
| W6 | `test/features/hermes_chat/composer/hermes_composer_draft_store_test.dart` | `8-54` | `71f1c60a1cb728b7e134c8047c9ec3623c7c9b48fe757fbd2d6a20afe3b3d09c` |
| W7 | `test/features/hermes_chat/controllers/hermes_follow_up_queue_test.dart` | `19-113` | `86287d2e83b8f536ce12028c8d9e8c82ab95e09bb2ed741490bb09638ac4b72e` |
| W8 | `lib/core/hermes/models/hermes_web_reads.dart` | `4-20` | `d6dd5a6871167279a02d8952ce437ca04f911dd83784929aa79a4530f8beb2b2` |
<!-- source-ledger:end -->
