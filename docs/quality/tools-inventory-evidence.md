# Tools inventory: source-bound evidence

Status: offline evidence receipt; native/live qualification NOT_CHECKED.
Task: `DOC-M4-INVENTORY-EVIDENCE` / `t_83c90727`; goal M4 remains partial.
This receipt maps existing behavior, not new administration or Desktop parity.
See [route support](../product/routes.md), [API authority](../adr/api-and-state.md)
and [M4](../../ROADMAP.md#m4--discover-and-administer-supported-agent-work).

## Source and execution identity

- Wing base: `5e9671e8d1db8a465398e4c9a9087ebe5758b330`; this task changes
  only this receipt. Production, tests, fixtures and dependency manifests are unchanged.
- Read-only Agent/Desktop reference: `158fd638da1629c8e62caf9ade1515d162def8ab`.
  Upstream findings below are inspection, not an upstream test run or runtime claim.
- Original pinned `pass_workspace.py` guard returned `worker_start_admitted`
  before edits; manifest SHA-256
  `f5ae0b5ba5be85f35a785e5ccb9f2e7687613831c0fcb231cd33b2fb3ee5fb0a`.
  Exact admission and finish/ref receipts belong to the native card handoff.
- Exercised: Linux x86_64 Flutter widget-test runner, Flutter 3.44.2 framework
  `c9a6c48423`, Dart 3.12.2. No installed native UI or browser was exercised.
- `pubspec.yaml` SHA-256:
  `7986bd3eaa967657f453e08f0522a4254496393699dc9640a7aba7de4cf1a43a`.
  `pubspec.lock` SHA-256:
  `f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89`.
  `package-lock.json` SHA-256:
  `f32c4b4d226bf6cef1a1f66733d4c2e065e0656d1223e89f17ceb68f42429b63`.
- Initial `flutter test --no-pub` failed before test loading because the isolated
  checkout lacked generated package configuration, not a missing manifest dependency.
  `flutter pub get --offline --enforce-lockfile` succeeded using cached packages;
  tracked manifests/locks remained unchanged. No package install or network fetch
  was needed. The focused rerun passed; no production repair was required.

## Exact read contract, without inferred administration

Wing's [channel state](../../lib/core/hermes/channel/hermes_channel_state.dart)
lines 193–196, 244–255 requires supported schema and exact `skills: GET /v1/skills`
and `toolsets: GET /v1/toolsets` endpoint descriptors. Every declared required scope
must be granted (including the existing wildcard rule). A descriptor marked
`profile_scoped` also requires the supported explicit query-profile context.
Read visibility grants no install/update/delete, toolset toggle, MCP or discovery authority.
The later [one-toolset toggle trace](toolset-toggle-contract.md) separates the
official Desktop/dashboard write from this API-server inventory and records its
profile/platform, authentication and conflict limits; Wing writes remain unavailable.

Important distinction: the inspected Agent `gateway/platforms/api_server.py`
lines 78–89, 2536–2575 advertises those exact read routes, bearer authentication,
and no `required_scopes`, `granted_scopes`, `profile_scoped` or `profile_context`
fields for them. It omits `schema_version`; Wing's
[capability parser](../../lib/core/hermes/models/hermes_capabilities.dart)
lines 25–29 treats that pre-versioning response as schema 1. Missing endpoint
scopes parse as an empty requirement list, not an invented `skills:read` grant.
The tests' `skills:read` / `tools:read` descriptors are simulated stricter contracts,
not proof that this upstream revision implements those grants.

Both upstream handlers are decorated with `_require_auth`; `_check_auth` at
lines 1562–1608 checks the URL-selected profile's bearer key and fails closed for
an unconfigured named profile. The no-key default branch is test/manual wiring;
normal connection requires a key. Skills return a list envelope with installed
metadata; toolsets return `platform: api_server` and enabled/configured/resolved
names (handlers at lines 2951–2994). Nearest inspected tests:
`tests/gateway/test_api_server.py:937–1049`,
`TestCapabilitiesEndpoint.test_capabilities_advertises_plugin_safe_contract`,
`TestSkillsEndpoint.test_skills_returns_list_envelope`, and
`TestToolsetsEndpoint.test_toolsets_returns_resolved_tools`. These tests use patched
catalog inputs; they were NOT_RUN here.

Upstream profile routing uses `/p/<profile>/…` and rejects foreign/unserved prefixes
(`api_server.py:1674–1743`). Do not infer upstream named-profile selection from a
`?profile=` query. Wing's [API config](../../lib/core/hermes/client/hermes_api_config.dart)
lines 132–151 preserves an enrolled path-profile identity and rejects a different
requested ID; otherwise it adds an explicit query. Query-profile selection in
these widgets is simulated, not qualification of upstream multiplex support.

The [API client](../../lib/core/hermes/client/hermes_api_client.dart) lines 97–112
reads bounded skill/toolset models with the selected profile; the
[shared reload path](../../lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart)
lines 279–331 independently gates both reads and publishes only when client,
profile, connection generation, profile-selection generation and request generation
still match. There is no fallback catalog/backend or mutation replay.

## One public journey and its executed oracles

Open Tools for the connected owner, inspect installed skills and toolsets, search
both independently, Tab to each clear button and press Enter, focus a toolset and
press Enter to disclose resolved names, then explicitly Refresh inventory.
This is read-only inventory, not a tool execution surface.

The [screen](../../lib/features/tools/screens/tools_screen.dart) binds search and
section state to channel/host/profile (lines 104–114), hides unavailable sections
before considering cached names (325–331, 503–509), and applies trimmed,
case-insensitive literal substring filtering (332–342, 510–522). Name-only chips
have no metadata search. The section clear buttons and `ExpansionTile` reuse
Flutter controls; there is no extra keyboard abstraction. Refresh ownership
includes status, profile transition and read availability (170–218); stale callbacks
cannot dispatch refresh or display another owner's late failure. Current-owner
errors use bounded localized feedback, not raw transport text.

Executed [screen tests](../../test/features/tools/tools_screen_test.dart):

- `shows and searches bounded installed skill metadata` and
  `shows and searches bounded resolved toolset metadata`: field matching and disclosure.
- `filtering a long selectable inventory preserves layout`, duplicate-name test,
  and `retains inventory at 200% text scale`: rendering regression checks.
- `refresh preserves active inventory search filters`, `refresh reloads advertised
  tool inventory`, and `refresh failure shows bounded retry feedback`: explicit recovery.
- `declared catalog scopes must also be granted`, `unsupported inventories fail
  closed instead of looking empty`, and `load failures are distinct and do not
  expose raw errors`: denial/stale content/error separation.

Executed [ownership tests](../../test/features/tools/tools_search_ownership_test.dart):

- `independent keyboard clear, semantics and disclosure at 390.0 px / 200%`
  and the `1280.0 px / 200%` case: named input semantics, focusable clear buttons,
  Tab/Enter activation, independent queries, Enter disclosure, no incidental
  `loadToolInventory` call and no voice transcript send. These are viewport tests,
  not physical Android or Linux accessibility-stack qualification.
- `actual channel old read false/true after host/profile roundtrip is ignored`
  (four generated cases): real `HermesApiChannel` with injected deterministic
  transport; delayed success/failure cannot replace current metadata, query or feedback.
- `direct connected host/profile roundtrip discards both private queries`,
  `distinct channel with identical host/profile IDs resets search`, and
  `late refresh from replaced client cannot affect current feedback`: exact owner fences.
- `losing one inventory grant resets only that section` and the generated
  `grant/operation/disconnected/error loss hides controls; return does not restore
  search` cases: no stale disclosure and no restored private search on recovery.
- `same-owner updates and refresh errors retain independent queries`,
  `late old refresh cannot affect a new owner query or feedback`, and
  `empty and name-only inventories remain distinct from no matches`: bounded recovery
  without inventing detailed inventory.

Command/result at unchanged executable source:

```text
flutter test --no-pub --concurrency=1 test/features/tools/tools_screen_test.dart test/features/tools/tools_search_ownership_test.dart
PASS: 33 tests; All tests passed! Runner elapsed display 00:06.
flutter analyze --no-pub
PASS: No issues found! Reported analysis duration 5.8s.
```

Existing [compiled-browser regression](../../playwright/tests/regression/tools-search.spec.mjs)
asserts local filtering/clear/disclosure cause no reads, explicit refresh causes
exactly the two advertised GETs, response metadata is read back, and mutation
requests/page errors are absent. Inspected only, NOT_RUN in this card; no prior
browser receipt is upgraded to evidence at this candidate. Likewise, nearest
API bounds/channel regressions are source leads, not additional executed checks.

## Smallest remaining named-platform proof

NOT_CHECKED: a Linux native Wing Tools journey against an isolated authenticated,
unmodified Agent with synthetic, non-personal inventory. Enroll one explicit
path-profile endpoint, keyboard-search both sections, Tab/Enter clear independently,
Enter-disclose a resolved toolset, and explicitly refresh. Observe bounded metadata
and exact read requests, zero mutations/tool execution, focus and screen-reader
labels at enlarged text. Exercise a rejected credential and reconnect to that same
owner; verify unavailable/bounded recovery without stale metadata or query leakage.
A second isolated served profile/owner with a delayed old read can extend the
scenario to native A→B→A proof, but does not follow from this offline run.

That scenario needs separately authorized isolated runtime/credentials and native
UI instrumentation; this card neither starts a runtime nor accesses personal state.
The existing query-profile fake cannot replace real path-profile proof. If the
unmodified target cannot supply a required operation, retain unavailable behavior;
never patch Agent, infer a grant or add a shadow backend.

M4 is not complete: native/live inventory and supported administration still need
operation-specific evidence. Android, installed desktop accessibility, live bearer
failure, browser execution, mutations and official Desktop parity are NOT_CHECKED.
The coordinator's next bounded slice is `DOC-M4-SCHEDULE-INVENTORY-EVIDENCE` after
this task's independent review/ledger closure permits it; no successor is dispatched here.

## Smallest-change decision

Ponytail full applied directly to this documentation-only change using the supplied
session rules and bundled `autowork/references/ponytail.md`: reuse existing channel,
providers, tests and browser oracle; add only this receipt. No missing in-scope
regression was observed, so skip new tests, production changes, dependency/config
changes, abstractions and speculative administration. Callers, fixtures, exports
and localization need no changes. No user data is mutated or exported.

Markdown local targets and `git diff --check` are required finish checks, recorded
with exact results on the card. Owned commit/native review handoff is separate
from review approval, canonical integration and publication; none is claimed by
this offline receipt alone. Costs/review duration are unknown, not estimated.
