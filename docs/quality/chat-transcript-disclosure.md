# Chat transcript reasoning disclosure comparison

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


This receipt compares one reasoning disclosure in Desktop and Wing. It records source behavior, one executed Wing regression, and a remaining state-label deviation.

## Scope and source identity

Task: `DOC-CHAT-TRANSCRIPT-DISCLOSURE`, card `t_0de1df01`, goal `CHAT-FIDELITY`.
The [task acceptance](../../TODO.md) requires disclosure, focus and recovery evidence.
The [parity boundary](../product/hermes-desktop-parity.md#reference-and-evidence-boundary)
is the product reference. The [earlier receipt](chat-fidelity-reference.md#executed-checks-and-coverage-limits)
completed the prerequisite, not this comparison.

Only this new receipt and card-local ignored evidence were authored. Supported
`goals.py task/evidence/render` operations maintain the shared ledger separately.
No composer comparison, implementation, upstream edits, installs or live actions
were performed. Pre-existing dirty files were read only.

Desktop reference: `withdrawn source citation`, HEAD
`withdrawn reference revision`. Its
[agent instructions](official-desktop-reference.md#withdrawn-evidence) were read before inspection.
`git -C hermes-desktop status --short` showed five pre-existing `.claude`
deletions, preserved. The inspected `HistoryRow.tsx`, `MessageList.tsx` and
`main.css` have no local diff. No remote-latest claim is made. `lat` was not
available on PATH. Direct source reads replaced knowledge-graph lookup; no
upstream functionality or knowledge graph was changed.

Wing HEAD: `1afe1307e37ee1ddfa1f7d67ad047509e99c8784`. This is a dirty working-tree
inspection, not a claim that all inspected behavior belongs to that commit.
The timeline, viewport controller and selected test have no local diff. The
caller layout and English localization have pre-existing edits. Their inspected
snapshot hashes are retained below, without copying private data.

| Wing file | SHA-256 of inspected bytes |
| --- | --- |
| `lib/features/hermes_chat/presentation/hermes_chat_timeline.dart` | `bf9e930b0107266ec5c06a5932f3c1e563e6841f61ae69c2787b7a1c80dc4783` |
| `lib/features/hermes_chat/screens/state/hermes_chat_layout.dart` | `2a4edc243fe86b94f037e2b18221d3e462210d0cba4ba281715c1883d591a660` |
| `lib/l10n/app_en.arb` | `4fa2248f82098094868b3f14814650fe00e58e2e1f7e87b7498662310249e19d` |
| `test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart` | `d45263f76a4a421908bbb7d1f173df30a367699efdda4986b710857d72907266` |

## One interaction: reveal reasoning, then collapse it

The comparison starts with a reasoning row in the transcript. The user activates
its summary to inspect the body, then activates the same summary to collapse it.
Streaming completion changes the reference summary without requiring disclosure.

### Desktop source behavior

[HistoryRow.tsx](official-desktop-reference.md#withdrawn-evidence):18–90
exports `ReasoningRow`. `useState(false)` initializes a collapsed disclosure.
A native `button` exposes `aria-expanded={open}` and toggles `open` on click.
The body remains mounted in a `pre`; CSS controls its visible height.
[main.css](official-desktop-reference.md#withdrawn-evidence):7026–7040
uses `0fr` when collapsed, `1fr` when open, and clips the inner content.
This is source inspection, not an executed visibility or accessibility assertion.

[MessageList.tsx](official-desktop-reference.md#withdrawn-evidence):375–387
keys `ReasoningRow` by `msg.id`. It passes `active` only when loading and the
reasoning row is the last visible row. The row uses `chat.thinking` while active
and `chat.thought` otherwise, switching its spinner to a brain icon. The caller
comment specifies “Thinking…” during streaming and completed “Thought” after an
answer or history load. A completed row need not be opened to see that distinction.

Focus is provided through the native button, not a custom focus-transfer handler
in `ReasoningRow`. The toggle does not replace that button or request focus
elsewhere. Tab/Enter/Space operation and actual focus retention were not run.
These source properties do not establish a screen-reader result.

For recovery, the keyed component retains its local `open` state while the same
instance remains mounted. `active` changes do not reset `open`. A remount starts
collapsed again. There is no persistence or reconnect callback in this component.
This does not prove the caller preserves the instance across session changes,
window eviction, navigation, reconnect or process relaunch.

### Wing source and caller

[hermes_chat_layout.dart](../../lib/features/hermes_chat/screens/state/hermes_chat_layout.dart):1090–1152
passes `state.activeMessages` to `_HermesTranscriptList` with the current profile
identity and viewport controller. The
[timeline](../../lib/features/hermes_chat/presentation/hermes_chat_timeline.dart):177–242
routes `HermesTurnKind.reasoning` to `_ReasoningCard`, retaining row identity through
`KeyedSubtree`. It does not pass an active/loading flag to that card.

The same timeline at 463–507 builds a keyed Card containing `ExpansionTile`.
It supplies no `initiallyExpanded`, expansion controller, expansion callback,
custom focus handler or per-status title. The title always uses `reasoningTitle`;
[English copy](../../lib/l10n/app_en.arb):636 is “Reasoning”. The body uses
`HermesRichText(..., selectable: true)` after `_safeHermesUiText`.
The [text helper](../../lib/features/hermes_chat/screens/widgets/hermes_chat_error.dart):318
calls `wingRedactSensitiveText`. The
[rich-text widget](../../lib/features/hermes_chat/presentation/hermes_rich_text.dart):15–35
is the existing shared Markdown presentation, not Desktop's plain `pre`.
Do not remove redaction or replace accepted bounded rendering to imitate Desktop.

The tile delegates focus, toggle semantics and collapse behavior to Flutter.
The selected regression proves initial collapse and pointer opening, not keyboard
activation, re-collapse or focus retention. No Wing-specific focus movement is
implemented in `_ReasoningCard` itself.

The [viewport controller](../../lib/features/hermes_chat/presentation/hermes_transcript_viewport.dart):14–107
retains process-local row keys only for visible unique Agent IDs. It removes
non-retained rows and clears keys on owner/origin changes. This supports stable
mounted-row identity, not durable disclosure state. The card does not explicitly
persist expansion across navigation, eviction, reconnect or relaunch. Those paths
remain unverified, rather than reported as either preserved or broken.

## Finding and smallest discriminating oracle

Confirmed source deviation: Wing's reasoning summary is always “Reasoning” with a
fixed psychology icon. Desktop distinguishes active “Thinking…” from completed
“Thought” and changes its activity indicator. The Wing card ignores turn status,
and its caller supplies no active flag. This difference is visible in the source
without opening the body. It is not a new runtime finding or a full-parity verdict.

Bounded equivalence: both implementations offer a collapsed summary and an
expandable reasoning body. Only Wing's initial collapse and pointer reveal were
executed here. Complete equivalence for focus, collapse and recovery is unproven.

The smallest follow-up oracle is one deterministic Wing widget journey for the
same reasoning identity: start with a trailing streaming row, Tab to its summary,
activate with Enter, then complete the answer and collapse with Space. Assert
active/completed summary distinction, hidden/visible body, expanded semantics,
and retained summary focus through the update. This should distinguish the
confirmed label deviation before implementation. It should also expose missing
keyboard/focus coverage without confusing it with provider generation.

Keep owner-switch/window-eviction/reconnect restoration as separate recovery
checks. Preserve unique row identity, bounded transcript projection, selectable
redacted content and existing tool activity presentation. `_ToolActivityGroup`
was inspected only as an adjacent boundary, not compared or modified. No new
card was enqueued and no recovery contract or backend capability was added.

## Executed checks and limits

Commands ran from the Wing repository on Linux. The selected test uses
`FakeHermesChannel`, not an Agent, provider, native window or physical device.

| Exact command | Observed result | Evidence boundary |
| --- | --- | --- |
| `flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart --plain-name 'reasoning is available in a collapsed readable card'` | PASS, 1 test | Title present, body initially absent, pointer tap reveals the synthetic body. |
| `python .dart_tool/chat-transcript-disclosure/check_receipt.py` | PASS | New receipt local links/anchors, whitespace, and new-file diff check only. |
| `python ~/.hermes/shared-skills/repo-docs/scripts/goals.py validate <repo>` | PASS, `ok` | Shared ledger structure and evidence rules, not parity acceptance. |

The [selected regression](../../test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart):787–810
completes the answer before pumping, then taps “Reasoning”. It does not assert
streaming labels, collapse, focus, keyboard semantics or recovery. Desktop's
[MessageList tests](official-desktop-reference.md#withdrawn-evidence):44–67
mock `ReasoningRow`; those assertions cannot prove the real disclosure interaction.
No Desktop tests were executed.

Card-local evidence is under ignored `.dart_tool/chat-transcript-disclosure/`:
`reasoning-test.log`, `check_receipt.py`, `receipt-check.log`, and `ledger-check.log`.
The whitespace helper accepts Git exit 0/1 only with empty diagnostics for
`git diff --no-index --check /dev/null docs/quality/chat-transcript-disclosure.md`.
Exit 1 represents the new-file diff, not a whitespace failure.

The supported helper marks `DOC-CHAT-TRANSCRIPT-DISCLOSURE` done, records the
executed checks and renders goal coverage. It derives `CHAT-FIDELITY` as `met`
because all three registered tasks are now done and passing evidence exists.
That mechanical ledger status does not prove the remaining disclosure parity.
This receipt retains the confirmed deviation and unexecuted focus/recovery oracles.
The first card-local ledger wrapper failed its stale expected-`partial` assertion
after the supported writes. The ledger itself validated successfully. The wrapper
was corrected to check the helper-derived status without altering other tasks.
Same-card native review is the final delivery step, not runtime parity approval.

NOT_CHECKED: Desktop runtime, keyboard-only disclosure, re-collapse, focus
retention, screen-reader output, streaming transition, reconnect, window eviction,
session/profile switching, process relaunch, native desktop, compiled web, Android,
live Agent/provider, packaging/release and full transcript/tool parity. Analyzer,
formatter and broader suites were not run for this new receipt-only change.

Applied the project's STE-inspired writing profile to this receipt. Scoped
wording and meaning were reviewed against the cited source. Mechanical checks
cover links and whitespace; full ASD-STE100 dictionary compliance was not verified.
