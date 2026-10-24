# Parallel local Desktop outcomes — 2026-10-24

This batch implements five bounded Desktop outcomes. It does not establish full
Desktop parity or named-platform release acceptance. The official source for
these slices is `NousResearch/hermes-agent@14e1e43a23761b369641208e204365cd6cb9399d`.
The pinned sources were read without changing the Agent reference or runtime.

## Integrated outcomes

| Outcome | Implementation and boundary |
| --- | --- |
| Chat text direction | Appearance → Chat display exposes Auto/RTL/LTR, searchable canonical field links, local persistence and unchanged draft/source text. Code stays LTR; inline-code links retain safe pointer/keyboard activation and exact selection-copy order. Auto retains the existing renderer. |
| Thinking disclosure | The local Collapse thinking by default control governs automatic streaming preview after preference hydration. Preview is capped at 160px and follows new content until the user scrolls away; explicit disclosure wins. Previewed content can remain visible on completion, while historical completed blocks start closed. |
| Pinned sessions | Sidebar, Chat and session picker share one local pin store. Saved contact reuse requires matching endpoint/profile; unsaved endpoints use an opaque digest. Ambiguous legacy direct records remain inert and preserved. Pending actions reject owner change, away/return, removed sessions and disposal. |
| Schedules | Alphabetical selectable jobs and one detail; narrow/large-text layouts offer Back with query and list-position recovery. Exact read gates and server authority remain in place. This is not cron CRUD, delivery or history support. |
| Skills | Category facets compose OR within categories and AND with literal search. Same-owner refresh/tab visits retain filters; exact owner/grant changes and stale callbacks are fenced. Discovery, installation and MCP administration remain unavailable. |

Scoped receipts and source traces:

- [Text direction implementation](../tasks/plan-clone03-local-frontier.md)
- [Thinking disclosure and renderer regressions](chat-reasoning-preferences.md)
- [Pinned sessions and connection-owner repair](sidebar-pinned-sessions.md)
- [Schedules list/detail](schedules-master-detail.md)
- [Skills category filters](skills-category-filters.md)

## Integration validation

Status: incremental publication with focused validation. Full-suite and full
browser qualification remain pending; this receipt is not a release gate pass.

Toolchain: Flutter 3.44.2 / Dart 3.12.2 and Node.js 22.22.2. Locked packages
use the existing warm cache; manifests and lockfiles are unchanged. Browser
journeys use the deterministic local fixture, never the user's Agent/account.

Executed integration checks:

- `flutter analyze --no-pub`: passed after merging current main.
- `flutter test --no-pub --concurrency=1` with
  `hermes_chat_screen_auth_recovery_test.dart`,
  `hermes_chat_session_disclosure_test.dart` and
  `hermes_chat_pin_owner_connection_test.dart`: 46 passed after merging main.
  The SSH regression now opens Advanced before expecting its optional Agent port.
- `dart format --output=none --set-exit-if-changed lib test integration_test`:
  passed on all 703 files after formatting the SSH regression test.
- `flutter build web --release --no-pub -t lib/main_e2e.dart`: passed on the
  integrated feature source before the latest main sessions-region addition.
- Chromium deterministic checks: all six new local-outcome journeys passed;
  12 browser-surface cases passed; active Thinking profile-switch cases passed
  at 390/1280px. The two wide rendered Settings host replacement cases passed
  after granting their multiple history roundtrips a 120-second total budget;
  individual action/assertion deadlines and all assertions remain unchanged.
- `npm ci` and `npm audit --audit-level=low`: passed, zero vulnerabilities.
- `npm run readme:assets`: passed with current assets visually inspected.
  The semantic crop retains the complete prompt, file activity and summary.
- `python3 integration_test/run_linux_production_startup.py`: isolated Linux
  startup passed on integrated feature source before the latest main merge;
  child commands returned zero, cleanup succeeded, and the window was inspected.
  This is startup evidence, not native input or full Linux qualification.

The whole serial Flutter run was stopped after exposing an obsolete SSH assertion
from the earlier form cleanup. That assertion is repaired and its focused target
passes; the whole suite has not completed on this candidate. The default browser
run was also interrupted after finding the renamed Theme menu selector and
Thinking disclosure semantics. Both are repaired and focused checks pass, but the
complete default runner, including the final reasoning-disclosure journey, has
not yet completed. Existing nine opt-in Flutter skips remain unchanged.

The initial local browser harness assumed an unacknowledged session title and
filled Flutter fields before their editing client attached. Corrected tests use
the confirmed fixture row and deliberate focus; query, Back, persistence and
zero-mutation assertions remain. Worker receipts above retain their own source
revisions and focused evidence; they do not imply whole-candidate qualification.

## Remaining parity

The full Settings tree, canonical concurrent tabs/panes, durable submissions,
clarifications/queue recovery, Projects/directory grants, positive provider
credential lifecycle, MCP/memory administration, terminal/review, artifacts and
other unimplemented Desktop contributions remain open under their exact contracts.
The managed-files root is an accepted divergence from Desktop's terminal root.

No actual Agent generation, approval/Stop, provider mutation, physical microphone,
Android/macOS/Windows runtime or signed installation/update/rollback is qualified
by this batch. Linux startup, widget and Chromium evidence remain distinct; no
paired official Desktop/Wing visual acceptance or parity percentage is inferred.
The task CLI is unavailable here, so this receipt does not invent task transitions
or claim that the PARITY goal is complete.
