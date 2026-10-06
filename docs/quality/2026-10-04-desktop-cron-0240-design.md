# Desktop continuation — restoration design clarification, 2026-10-04 02:40

## Result and scope

Updated the [native integration proposal](../plans/2026-10-03-desktop-local-integration-design.md)
under a single exact lease in the [goal ledger](../plans/2026-10-03-desktop-port-goal.md).
This incorporates the [prior source review](2026-10-04-desktop-cron-0225-native-model-review.md),
not a new transport decision, security acceptance or implementation authorization.
The coordinator topology, authentication gate and no-shadow-state boundaries remain.
ROADMAP, production, tests, browser oracle and upstream references remain read-only.

Admission: scheduler readback showed only this occurrence running and hourly
assessment completed; native delegation/terminal lists were empty. Filtered OS
QA census was empty. Prior session and ledger agree preceding ownership released.
No children, Flutter commands, services, displays or browsers were started.
The available todo tool tracks bootstrap, design clarification and closing checks;
OMH-specific routing/accounting wrappers were unavailable, and no coding handoff
or parallel implementation was attempted.

## Indexed changes and exit criteria

1. **Restoration authority row and direct API caveat:** distinguish session model
   display from volatile acknowledged selection and authorized restored-pair
   readback. [Agent `_session_response`](../../hermes-agent/gateway/platforms/api_server.py)
   and the [read-authority receipt](2026-10-04-desktop-cron-0147-runtime-pair.md)
   are the source basis. Missing pair fields do not authorize provider inference,
   synthetic confirmation, shadow storage or a repeated model POST. Exact-pair
   restoration stays an unmet acceptance criterion.
2. **Native resume/model candidates:** remove the assumption that cold lazy resume
   restores a stored pair. [Resume branch bodies](../../hermes-agent/tui_gateway/methods_session.py)
   separate warm reuse, child/watch lazy, deferred hydration, default cold and
   eager build. No mode is selected or admitted. Preserve explicit origin/profile/
   stored/runtime identities, bounded path-free projection and distinct pending,
   effective and acknowledged identity. Config reads/catalog/status rendering are
   not replacements for an exact session-pair read.
3. **Qualification gates:** require server-turn and canonical-history counts as
   well as client sends. [Auto-continuation](../../hermes-agent/tui_gateway/session_auto_continue.py)
   can schedule a turn during cold/eager resume. Require independent branch cases
   with absent/fresh/stale markers and still-live owners on a separately approved
   isolated target. No personal/global config or marker edits, invented opt-out,
   stop-after-start workaround or upstream patch. Deferred response-body evidence
   alone does not qualify hydration/build/next-turn behavior.

Nearest [warm resume tests](../../hermes-agent/tests/tui_gateway/test_resume_live_lazy_session.py)
and [auto-continue tests](../../hermes-agent/tests/tui_gateway/test_auto_continue.py)
remain inspected evidence from the prior review, not executed tests in this run.
The [metadata authority regression](../../test/features/hermes_chat/screens/hermes_chat_model_authority_test.dart)
retains its previously executed receipt; no suite was rerun here.

## Executed verification

Scratch evidence: `/home/xel/.hermes/profiles/wing/cache/scratch/desktop-cron-0240-design/`.

- Git status, scheduler readback and filtered QA census: exit 0.
- `source-before.json`: nine consumed source hashes, including ROADMAP and the
  integrated browser oracle. `design-before.md` preserves the exact pre-edit
  untracked proposal for scoped review; dirty HEAD is not a content snapshot.
- Reference status readback: Agent and Conduit clean; Desktop's existing five
  `.claude` deletions preserved. `lat` absent on PATH; no install, key provisioning
  or upstream wiki/hook writes attempted.
- Closing Python gate compares source hashes/reference statuses, validates local
  links/whitespace, checks the exact six changed original lines plus one inserted
  caveat, and runs scoped `git diff --check`. Results in `close.json`; full scoped
  design comparison in `design.diff`. This is document/static verification, not
  an upstream handler test or live qualification.

No runtime/provider/native/browser/card acceptance is claimed. No QA resource or
pending process exists from this occurrence; cleanup requires no service teardown.

## Next bounded checkpoint

Rank 1: independent review of the clarified proposal's exact-pair and resume
admission criteria, read-only, against supported unmodified contracts. Exit:
identify a supported authorized pair read and passive recovery semantics, or
record the exact unsupported boundary without approving an adapter.

Rank 2: only after separate authority/auth/target review, qualify the chosen
native branch and actual owner-selected inference. No native adapter, auth
provisioning or unchanged integrated-browser retry is dependency-ready from this
document update. Final picker/Escape/resume/count stages and native process/live
acceptance remain open. Ownership releases on the closing document/source gate.

Run summary: not_available — host accounting was not exposed.
