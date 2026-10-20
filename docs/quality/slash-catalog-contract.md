# Curated composer commands and authoritative catalog

## Local timestamp controls

`PARITYGAP-001-3f` adds a bounded presentation-only command path. Type
`/timestamps` or `/ts`; no argument and `toggle` invert visibility, `on`/`off`
are idempotent, and `status` reports without changing it. Unrecognized arguments
on either exact alias show localized usage rather than becoming a prompt.
Help and suggestions expose both aliases; tap or keyboard selection uses the
same handler. Other unknown slash commands retain their existing message path.

Labels default off. The non-persisted
[window-scoped provider](../../lib/features/hermes_chat/providers/transcript_timestamps_provider.dart)
survives conversation/profile switches and Chat route remounts within the root
app scope; a fresh scope resets it. There is no preference write, Agent config
read/write, slash RPC, provider call, session creation or model-context change.
**Agent configuration defaults remain unsynced.** Existing active-turn, IME,
attachment and read-only admission remains in force; an attachment-bearing
submission is still an ordinary prompt, not a display command.

The [command handler](../../lib/features/hermes_chat/screens/state/hermes_chat_layout.dart)
uses dismissible local feedback. The
[existing timestamp renderer](../../lib/features/hermes_chat/presentation/hermes_chat_timeline.dart)
hides only visible labels: full localized local date/time semantics remain,
and keyboard/touch users can reveal labels through either command. Copy,
read-aloud, source timestamps and transcript serialization are unchanged.

Official read-only source at `158fd638da1629c8e62caf9ade1515d162def8ab`:
`apps/desktop/src/store/display-timestamps.ts` defaults off and reads
`display.timestamps` from config; `components/assistant-ui/thread/timeline-timestamp.tsx`
and its nearest test gate visible stamps. `src/lib/desktop-slash-registry.json`
contains both aliases; `desktop-slash-commands.ts:registryDerivedSpecs` maps
these rows to backend execution, not a local action. Wing's deliberately
unsynced local override is the accepted bounded adaptation, **not authoritative
slash execution or full timestamp/config parity**. Upstream tests were read,
not executed.

Regression coverage extends the existing slash, rich-transcript and workspace
widget modules: aliases/arguments and invalid zero-I/O, help/suggestions,
IME/active-turn/attachment/read-only admission, full-time semantics, shared
window lifetime, drafts/selection/focus, reset and 320/390/wide layouts with
200% text and keyboard insets. The existing deterministic
[transcript-export journey](../../playwright/tests/regression/transcript-export.spec.mjs)
uses public compact/touch and wide/keyboard controls and checks exact export
bytes and zero network mutations after toggling. It also corrects the old byte
expectation to include the existing baseline session-metadata header.
Linux-hosted widget and Chromium fixture checks do not qualify installed-device
IME, TalkBack, live Agent execution or other platforms. Revisit this section if
the local handler, provider lifetime, renderer or authoritative config contract
changes. The original catalog investigation below remains historical evidence.

## Result and scope

`DOC-SLASH-CATALOG-CONTRACT`, native card `t_c119f3de`, goal `SLASH-CATALOG`.
Result: an authoritative catalog exists in the official Agent JSON-RPC backend,
but the inspected direct HTTP Agent capability contract consumed by Wing does
not advertise that catalog, completion or dispatch. It is **unavailable through
Wing's current transport**, not absent from Hermes Agent. No new route, grant,
command execution or full-parity support is inferred. `SLASH-CATALOG` remains
partial under the [existing statuses](../product/hermes-desktop-parity.md#statuses).

This receipt alone is owned. Production, tests, fixtures, localization, exports,
configuration, locks and the canonical ledger are unchanged. Scope reaches the
composer's layout/message-flow parts, channel gates/API callers and their existing
fake-channel regression oracles; these are inspected/tested, not modified.
There is no user-store migration, deletion, secret access or host command.
Coordinator `wing` owns review-gated ledger closure/integration; this is a proposal
handoff, not canonical delivery.

## Source and dependency identity

- Wing admitted/executed base: `33c2af749f99db601a1051e6045464a9dbec6401`.
  The pinned `pass_workspace.py` guard returned `worker_start_admitted` before
  design, tests or edits; its argv and manifest digest are in the native run.
- Official read-only Agent and Desktop subtree:
  `158fd638da1629c8e62caf9ade1515d162def8ab`, clean at inspection.
  Root, Desktop, Desktop/src, gateway, tui_gateway and hermes_cli `AGENTS.md`
  were read before their respective source traces. This pins a checkout, not
  the installed runtime, latest release or a live catalog.
- Linux-hosted Flutter `3.44.2`, framework `c9a6c48423`, Dart `3.12.2`,
  Python `3.12.14`; observed Node `v26.7.0` (not the documented Node 22).
  No Node/browser test or install was used. Resolved `flutter_riverpod` `3.4.2`,
  `go_router` `18.0.0`; Flutter test package is SDK-owned.
- `pubspec.lock` SHA-256:
  `f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89`.
  `package-lock.json`:
  `f32c4b4d226bf6cef1a1f66733d4c2e065e0656d1223e89f17ceb68f42429b63`.
- Executed composer layout:
  `b5f9222085bbf7f9913267397d87cd5671c6e7a2b44b4011c4b0decd7cebdde4`;
  message flow:
  `838124adfbd9b856e5b256c1b981c5966ea9fe4fab858a9a40d5307f35a94342`;
  channel state:
  `2a21f95befa4de3c37fa2a3479480683a1f6c405a9b3f668fbec96bfa5b974dc`;
  slash regression test:
  `8d309e5a18cdf5c98ffd098aafadf637fd7b24f20c50e527cb7fdf1b9c1f1f48`.
  The finish receipt supplies the exact owned commit/ref independently.

## Wing command inventory and completion

The producer is
[hermes_chat_layout.dart](../../lib/features/hermes_chat/screens/state/hermes_chat_layout.dart):2223–2326,
not the historical planned standalone catalog file. It defines 16 possible
entries, including three conditional entries. `/profiles`, not `/agents`, is the
current literal, despite the older test title/localization identifier.

| Wing command | Current local action and gate | Official source comparison at pinned revision |
| --- | --- | --- |
| `/new` | Channel creates a session; conditional `canCreateSessions`. | Desktop local new-chat action; Agent registry `new` has `reset` alias and name argument. Wing does not complete those. |
| `/sessions` | Opens Wing session panel. | Desktop alias of `/resume`, a session picker with inline recent-session/search completion and Browse all action. Wing has no argument completion. |
| `/clear` | Clears composer only; no session/history deletion. | Desktop overlay aliases it to new chat, overriding registry terminal-only metadata. Same token is not equivalent behavior. |
| `/settings` | Opens Wing Settings overlay. | Absent from inspected static Desktop registry/overlay; not evidence of absence from dynamic extensions. |
| `/usage` | Displays latest loaded turn's server token counts or unavailable message. | Agent registry includes usage/rate limits and `reset` argument; Wing does not implement/reset those. |
| `/help` | Lists available Wing-owned commands in a sheet. | Desktop local help; Agent registry also accepts skills/filter arguments. Wing list is not a runtime catalog. |
| `/tools`, `/skills` | Both navigate to Wing Tools surface. | Registered Agent command families; Desktop metadata/subcommand filtering limits exposed execution. Wing navigation is not family dispatch. |
| `/gateway` | Navigates to Wing Gateway. | Agent alias of `/platforms`, marked terminal-only; Wing navigation does not manage a host service. |
| `/office` | Navigates to accessible Wing Office. | Absent from inspected static Desktop registry/overlay. |
| `/profiles` | Opens Wing Profiles overlay. | Absent as plural token; Desktop `/profile` is an explicit profile-switch action, not equivalent navigation. |
| `/providers` | Navigates to Wing Providers. | Absent from inspected static Desktop registry/overlay. |
| `/model` | Navigates to Wing Providers/model management. | Desktop hidden command opens session-model picker, resolving typed arguments. Wing bare navigation is not assignment/completion. |
| `/schedules` | Navigates to Wing Schedules. | Absent from inspected static Desktop registry/overlay. |
| `/persona` | Reads selected profile SOUL only if exact read gate and selected ID exist. | Absent token; Agent `/personality` selects a predefined personality. Do not alias these different operations. |
| `/version` | Displays bounded cached detailed-health platform/version; conditional exact read gate. | Agent registered version command. Cached health display is not execution of the runtime command. |

Wing matching (:1784–1811) starts only on a leading slash token without following
whitespace, searches command-name substrings/descriptions and sorts name prefixes
first. Desktop-keyboard arrows wrap/reveal selection; Enter/Tab **execute** the
selected local action, Escape dismisses without deleting the draft, IME composition
is ignored (:1870–1951). Tap is available without a keyboard. Suggestions are
hidden with staged attachments/active turns (:1954–1959); action execution also
refuses an active turn. Exact bare matching is trimmed/case-insensitive; it does
not parse aliases or arguments (:2211–2220).

[Message flow](../../lib/features/hermes_chat/composer/hermes_chat_message_flow.dart):25–87
tries exact local commands only without a staged attachment. Unrecognized slash
text proceeds through normal chat/send/steer/queue behavior; this is **not** a
verified slash RPC or an unavailable-command denial. The existing unknown-command
and unadvertised-persona tests assert message fallback, not runtime dispatch.

## Authoritative producers and the missing transport contract

All upstream paths below are relative to the pinned official `hermes-agent/`
checkout; they are source observations, not executed upstream tests.

- `hermes_cli/commands.py`:83–340 supplies `COMMAND_REGISTRY`, canonical names,
  aliases, argument hints and Desktop metadata. Desktop
  `src/lib/desktop-slash-registry.json` is generated static metadata; the local
  overlay in `src/lib/desktop-slash-commands.ts`:189–258 can override it (notably
  `/clear`). Comparing JSON keys alone is insufficient.
- `tui_gateway/methods_tools.py`:429–537 produces `commands.catalog` from registry,
  quick commands, plugins and skill commands. Session/profile plus workspace
  scope controls discovery; an unknown draft profile fails rather than borrowing
  the launch profile. `tui_gateway/contracts/tools_commands.py`:190–305 declares
  catalog, resolve, dispatch and slash-exec payloads/results. Catalog visibility
  is not mutation authorization; a directive may represent skill, send, prefill,
  alias, plugin or execution, not merely text to inject blindly.
- `tui_gateway/methods_complete.py`:278–331 produces `complete.slash`, binding
  skill/bundle lookup to session/profile/workspace and returning `replace_from`.
  Desktop `src/app/chat/composer/hooks/use-slash-completions.ts`:81–104, 131–243
  fetches scoped catalogs/completions, completes `/resume` locally and reconstructs
  argument stubs. `desktop-slash-commands.ts`:563–624 aligns argument suggestions
  with unavailable-subcommand execution gates. Its action/picker/dedicated-RPC/
  exec/unavailable discriminator (:86–114) is not a blanket execution grant.
- Nearest official tests inspected: `tests/tui_gateway/test_tui_gateway_server.py`
  catalog collision/filter/metadata tests (:12205–12265) and completion plain-string,
  skills/ranking/argument-stage tests (:9848–9970); Desktop
  `src/app/chat/composer/hooks/use-slash-completions.test.tsx`:80–108 covers cache
  invalidation and explicit sessionless profile identity. These are prospective
  contract oracles, **NOT_CHECKED** by execution in this task.
- Agent direct HTTP producer `gateway/platforms/api_server.py`:67–102,
  2537–2575 advertises its actual endpoint table through `/v1/capabilities`.
  It contains no command catalog, slash completion or slash dispatch endpoint.
  Wing's [API exports](../../lib/core/hermes/hermes_api.dart), client and channel
  have no consumer for the official catalog/completion RPCs. JSON-RPC availability
  in Desktop's backend does not invent an HTTP route on the selected Agent.

Thus no exact catalog method/path/grants can honestly be supplied for Wing's
current direct HTTP transport. Neither `admin`, a version string, skills inventory,
model inventory nor ordinary chat submission grants authorize it. This satisfies
the acceptance alternative **unavailable authoritative catalog on the consumed
transport**, without falsely saying Hermes has no catalog.

## Authorization, ownership and regression evidence

[Channel state](../../lib/core/hermes/channel/hermes_channel_state.dart):133–136,
171–209, 244–264 requires supported schema, exact endpoint method/path, all declared
scopes and query profile context when profile-scoped. `/new` retains the existing
no-capability legacy gate; this is not proof of advertised catalog support.
The API session caller additionally checks `session_create` before I/O and binds
the request/response to the selected profile and selection generation
([sessions](../../lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart):295–350).
`/persona` requires `profile_soul`, `GET /api/profiles/{name}/soul`, advertised/granted
`profiles:read`, every additional declared scope and selected profile identity;
its [API caller](../../lib/core/hermes/channel/api_channel/hermes_api_channel_profiles.dart):265–275
also requires profile context. `/version` requires `health_detailed`,
`GET /health/detailed`, every advertised required scope and supported context;
there is no hardcoded universal `gateway:read` requirement in that getter.
Navigation alone grants no destination mutation authority.

The same capability checks must precede any future catalog I/O, bound to current
endpoint/profile/session and request generation. Late reads cannot populate a new
owner's menu. Reconnect may reconcile reads, never replay commands/mutations.
Missing/denied operations must not acquire authority through shell/CLI dispatch,
local files or a copied Desktop fallback. Preserve the
[API/state boundary](../adr/api-and-state.md#decision) and
[threat-model controls](../security/threat-model.md#current-controls-and-adversarial-cases).

Executed commands in the admitted isolated workspace, with unchanged locks:

- `flutter pub get --offline --enforce-lockfile` — PASS; cached dependency resolution,
  no dependency installation/update request.
- `timeout 5m flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_slash_commands_test.dart --reporter expanded`
  — PASS, 48 tests, initial runner elapsed 10 seconds. Named discriminating oracles cover
  filter ordering, wrap/Tab/Escape/IME, 200% scale, new-session write-scope denial,
  Persona read/denial/fallback, version/usage, exact clear/no-send, active-run and
  unknown-command behavior. “Agents” in a test title actually exercises `/profiles`.
- `timeout 180s flutter test --no-pub test/core/hermes/hermes_surface_readiness_authorization_test.dart --reporter expanded`
  — PASS, 34 tests; schema/method/path/profile-context/missing/additional-scope
  denial stays consistent with operational gates. It is not slash-catalog support.
- `git diff --exit-code -- pubspec.lock package-lock.json` — PASS.
- Python standard-library local Markdown target/heading-anchor validation and
  receipt trailing-whitespace check — PASS, nine local links; exact argv/result
  is replayed in the native finish receipt. `git diff --check` — PASS, replayed
  at finish (the Python check also covers this initially untracked receipt).

The finish gate reruns the two test commands, lock comparison, link/anchor check
and diff check before publishing only this receipt to its local task ref. Initial
checks required no failure retry. Full analysis/suite, browser/native UI, actual
Agent authentication/catalog/dispatch, providers/inference and other platforms
are **NOT_CHECKED**. Offline Flutter widgets qualify only the named fake-channel
behaviors on the Linux-hosted test runner, not Linux GTK/Chromium/Android journeys.
Total elapsed/review time and cost were not measured; review remains independent.

## Acceptance and smallest next slice

- Current list/completion/actions: source-bound inventory and exercised existing
  composer oracles above; no stale planned-file/catalog assumption.
- Authoritative comparison: pinned registry, Desktop overlay and scoped RPC
  producers; direct HTTP endpoint producer proves the bounded unavailability.
- Exact authorization and regression oracle: existing gates/callers plus scope
  denial tests; no fabricated catalog grants. Official tests are inspected only.
- Boundaries/checks/commit: one owned documentation receipt; finish receipt binds
  checks and exact local commit/ref. Independent same-card review, integration and
  canonical ledger closure remain coordinator work.

Smallest successor proposal is the already-listed `DOC-SLASH-DENIAL-EVIDENCE`:
map one catalog/argument command unavailable through the selected HTTP Agent,
its explicit recovery to an existing supported surface and a no-privileged-I/O
oracle. Do not treat ordinary-message fallback as denial or dispatch success.
A broader dynamic-catalog implementation requires an exact advertised, authorized
unmodified Agent contract first; no upstream edits or shadow catalog. The bounded
`/clear` semantic mismatch and `/resume` argument-completion gap remain recorded,
not implemented or claimed qualified here. No successor card is created.

Decision (Ponytail full): deliver the unavailable-transport comparison in one
receipt, reuse existing producers/tests and omit a new catalog class, dependency,
route, implementation/test change or redundant broad suite. Safety and required
finish checks are retained; the table/checks above verify the scoped outcome.
