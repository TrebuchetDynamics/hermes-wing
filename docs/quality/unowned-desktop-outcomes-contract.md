# Uncovered Desktop outcomes: seven contract dispositions

## Verdict and evidence boundary

`PARITYUPDATE-004-48` · Goal `PARITY`. Start with the seven-row table, then
read the operation detail for the selected row. **Source research resolved;
no feature implementation or runtime qualification.** The
[accepted scope](official-desktop-parity-refresh-2026-10-18.md#unowned-outcomes)
does not expand an active task or make an optional feature an Android prerequisite.

- Official Agent pin: `a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70`;
  Desktop subtree: `cee4414aae0817b7ff45c76fbfd010dcd753ecf5`.
- Wing inspected at task baseline `8ed7c2fc8fe5391e44d9417b10f631dd3b57fec6`.
  The matrix's older global Wing pin remains historical. This document adds
  contract depth, not positive support, routes, task acceptance or platform cells.
- Source was read from the official commit archive in task-temporary storage;
  cited files were checked against that commit's Git-tree blob identities.
  The evidence ledger binds exact inclusive ranges and whole-file SHA-256.
  Tests below are **inspected assertions, not executed upstream tests**.
- No Agent/reference/runtime changes, requests to personal services, playback,
  transcript export/import, secret access, package loading, control or generation
  were performed. Missing guarantees stay missing; no invented endpoint/grant.

## Admission shared by the Agent-owned rows

The RPC names below are declared handlers/contracts, **not proof that a connected
Agent advertises them to Wing**. On the canonical gateway, a method absent from
the authority can reach the legacy sidecar only after `-32601` and only with the
entire interactive capability set: `session:create`, `session:read`,
`session:submit`, `session:control`, `session:approve`, `session:respond`.
Foreign list/preview/import are explicitly allowed session-namespace exceptions.
Worker-adoption and empty grants do not reach that fallback. These are actual
coarse native transport grants, not invented `vault:write`, `pet:generate`,
`display:control` or package permissions. A read grant alone is insufficient.
The ticket profile and explicit supported profile routing must still match the
served authority; a vanished secondary home is refused. [G1] [G2] [G3] [G4]

Desktop source presence, a missing-method probe, `gateway.ready`, provider
availability, or enabled plugin registration is not Wing's exact-operation
advertisement/authorization gate. Every future request needs its verified
transport/schema, operation, grants and captured connection + profile + resource
identity. The [attachment contract](canonical-gateway-attachment-contract.md)
owns private interactive/native-HTTP acquisition; this study does not implement
it. Dashboard REST uses its authenticated session/token seams, or a verified
native HTTP principal (`http:owner` through that attachment contract), not a
universal bearer grant inferred from an unrelated read. [G5]

For all rows: owner means connection ID/authenticated origin/transport generation
plus authoritative profile/home, not an ambient `default` label. Capture resource
identity before awaiting; retire late UI results on owner change. Reconnect may
refresh reads, never replay writes, spend, adoption, import, unlock or lease
acquisition. An aborted client await is not proof an Agent mutation was cancelled.
These are Wing requirements under the [API](../adr/api-and-state.md) and
[security](../adr/security-and-privacy.md) ADRs; row details distinguish actual
source guarantees from requirements still unavailable.

## Seven-row disposition

| Outcome | Authority / positive source outcome versus Wing availability | Identity, effects and recovery | Accessible equivalent / existing overlap |
| --- | --- | --- | --- |
| **HD-EXPORT** — [all-message JSON](#hd-export) | Authenticated `GET /api/sessions/{id}/messages` pages support Desktop's JSON assembly, including compacted/ancestor history; no frozen multi-page export snapshot is established. Wing additionally implements a bounded Linux fixed-reader paged JSON consumer; [offline evidence and qualification limits](paged-session-json-export.md) do not close the runtime cells. [E1–E5] | Captured connection/profile/stored ID and resolved lineage; read then deliberate local download of private content. No cancellation/owner fence in this helper, no cross-page revision. Reconnect must restart an explicit read, never silently save. | Labeled JSON action, progress/cancel/error and native/browser save without clipboard fallback; existing `PARITY-DOC-EXPORT-FEEDBACK` and message-action/device qualification own loaded exports, not this missing completeness outcome. |
| **HD-IMPORT** — [foreign list/preview/continue](#hd-import) | `session.foreign.list`, `.preview`, `.import` exist; Agent adopts/mints atomically and deduplicates per provenance. No preview-content binding or redacted preview guarantee. Wing has no foreign browser/import consumer. [I1–I7] | Connection/profile + source-host handle + source provenance → returned stored ID. Import writes new Agent history, not a prompt or backup restore. Close suppresses navigation, not commit; reconnect refreshes/reconciles without import replay. | Text list/preview, source/destination, truncation and explicit Continue/Back; `VERIFY-DIAGNOSTICS-ATOMIC-RECOVERY` / `DOC-DIAGNOSTICS-BACKUP-CONTRACT` remain backup owners, not foreign import. |
| **HD-RADIO** — [optional local player](#hd-radio) | Client-local default-disabled contribution; station search, pins and explicit playback need no Agent operation/grant. No Wing player exists. [R1–R3] | Plugin-local preferences, station ID/HTTPS stream, window/play generation; external directory/media traffic, no Agent credential. Disable destroys playback; cross-window play stops the prior player; late media ignored. Agent reconnect grants nothing. | Named search/station/pin/Play/Pause/volume/mute/error controls, no waveform/sound-only status. `PARITY-OFFICIAL-MATRIX-LIVE` is qualification only, not implementation coverage. |
| **HD-VAULT** — [credential sources/items](#hd-vault) | Metadata-only `vault.list` / `.sources`, local `.add` / `.remove`, external `.source.set` / `.unlock` / `.lock` exist. No Wing Vault consumer; endpoint secure storage is a different asset. [V1–V5] | Connection/profile + source name or item ID/origin; encrypted local secret writes / manager session unlock. Owner-keyed remount clears drafts; no revision/idempotent add or revoke-on-disconnect guarantee. Read status after reconnect, never resend a secret. | Labeled source/locked-state/item forms, obscured write-only inputs and explicit cancel; `DOC-NATIVE-FAILURE-BOUNDARY` / `DOC-ACCOUNT-REVOCATION-EVIDENCE` stay adjacent, not Vault coverage. |
| **HD-PLUGIN-PACKAGES** — [Agent/Desktop halves](#hd-plugin-packages) | `plugins.manage` actions and `.catalog.lookup` are Agent-owned; Electron probe/install/reconcile/remove and JS loading are client-local. No Wing package manager or Flutter plugin ABI. [P1–P11] | Agent profile + canonical plugin key/name/pin versus app-global Desktop package identity. Network, disk/config writes and possible code activation; timeout is uncertain and blocks starting the other half. No atomic dual-half transaction or durable replay receipt. | Keyboard list/details, provenance/consent and separate install/activation/failure outcomes; `DOC-M4-MCP-CONFIG-CONTRACT` / `DOC-NATIVE-FAILURE-BOUNDARY` do not own package lifecycle. |
| **HD-SCREEN** — [observe and human lease](#hd-screen) | `display.status`, `.observe`, `.lease.acquire` / `.release` and ticketed RFB bridge enforce viewer input, not just view-only UI. Lifecycle verbs are separate. No Wing viewer/control consumer or non-canvas screen equivalent. [S1–S9] | Connection/profile/home key + transport-minted viewer + lease epoch + one-use display ticket. Watching exposes pixels; input/paste controls a computer. Clean close hands back; dropped stream keeps exclusion; new RPC transport cannot claim old viewer. | Text status/lease and keyboard Take over/Hand back are necessary but not equivalent access to screen content. `ANDROID-CANONICAL-BOT-CHAT` remains name-based chat/roster only; native-boundary work grants no computer control. |
| **HD-PETS** — [generate/hatch/adopt/discard](#hd-pets) | `pet.generate.status`, `.generate`, `.hatch`, `.cancel`, `.select`, `.remove` (optional `.rename`) exist; stage/install and adoption differ. No Wing pet flow. No proven full profile/run-bound reconnect contract. [T1–T6] | Connection/profile + draft token/index, separate hatch cancel token, resulting slug; provider calls/spend, reference-image upload, files and active-pet config. Cooperative Stop cannot refund/cancel an in-flight provider call; no durable job receipt/retry dedupe. | Text progress/errors, named drafts/static preview, reduced motion, explicit Stop/Adopt/Discard without animation dependence. Mascot assets and `PARITY-OFFICIAL-MATRIX-LIVE` do not implement or qualify this optional flow. |

Citation groups in the overview refer to the individually ranged ledger entries
below (for example E1–E5 means E1, E2, E3, E4 and E5).

## HD-EXPORT

**Exact read and composition.** Desktop calls `getAllSessionMessages(id, profile)`;
its requests use `limit=500&offset=N&order=oldest&include_compacted=true` on
`GET /api/sessions/{id}/messages?profile=P`. The handler caps each page at 500,
resolves compression lineage, includes ancestors, projects display fields and
returns `session_id`, `profile`, `messages`, `pagination`. The helper accumulates
until a short/empty page, stops above **32,000,000 JSON characters**, and also
accepts missing pagination as legacy completeness. That last fallback is not
sufficient evidence for a new Wing completeness claim. [E2] [E3]

The local JSON wrapper has `exported_at`, requested `session_id`, supplied title
and session metadata (or null), `message_count`, and `messages`; it is not a raw
Agent database backup. Messages are server-projected records, not just painted
turns. The helper overwrites its resolved ID each page but the wrapper uses the
requested ID; it does not check a stable resolved ID/profile/revision across
pages or freeze the initial metadata. Concurrent compression/edits/deletes can
invalidate offset completeness. No snapshot token, total-count proof, abort
signal or same-owner-before-download check is established by this path. [E1] [E2] [E3]

**Disposition:** bounded whole-history paging is source-supported; atomic,
point-in-time all-message export is not proven. The separately scoped
[Linux paged JSON consumer](paged-session-json-export.md) adds bounded raw paging,
identity/drift checks, private-file consent and save cancellation offline, without
claiming atomic completeness or native/live qualification. Preserve the existing
loaded text/Markdown scope and Linux-only native saver. Never silently truncate and call it complete,
write Agent files, invoke backup CLI, or replace a denied JSON operation with
clipboard text. The nearest inspected tests assert bounded oldest-first paging,
safe-load refusal, 500 cap and compacted-history inclusion—not a frozen export
transaction or cancellation of the JSON helper. [E4] [E5]

## HD-IMPORT

**Exact calls.** On the captured owner's socket, `session.foreign.list
{profile,source?:claude|codex,offset?,limit?}` returns host, opaque handles,
next offset and unreadable count. Candidate paging defaults to 25, maximum 50;
parsing refuses logs above 32 MiB. `session.foreign.preview {profile,id}` returns
the last 40 normalized turns, at most 8,000 characters each, total/truncated,
`already_imported` ID and cwd. These payloads include transcript/title/excerpt,
host and cwd; **bounded is not redacted**. Do not put them in diagnostics,
preferences, URLs or test fixtures. Source discovery is on the Agent host, not
an Android file picker or arbitrary client path. [I2] [I3] [I4] [V3]

`session.foreign.import {profile,id}` returns `{session_id,already_imported}`.
The handle is SHA-256 of source name and path, **not content**; every preview/import
re-resolves and re-parses current source. Agent records provenance (`tool`,
source path, foreign session ID), normalizes history and atomically adopts an
existing import or creates one. Dedupe is by tool + foreign session ID, falling
back to tool + path when no foreign ID, within the destination store. Same-origin
concurrent imports share the returned ID; another profile can import separately.
A title collision gets a suffix, and a non-existing cwd is not assigned. Source
logs are not modified. This is not idempotency for arbitrary changed payloads:
there is no expected source digest/mtime at commit, preview-to-import revision
or guarantee of updating an already imported snapshot. [I4] [I5] [I6]

**Cancellation/recovery.** Desktop aborts the view's awaits on unmount and opens
only a still-mounted result; its test intentionally still observes an owner hint
from a late import. The Agent may have committed. Use returned authoritative
identity/readback, not optimistic local transcript seeding; do not auto-repeat
Continue on reconnect. The nearest tests cover concurrent dedupe, profile stores,
fabricated/path handles, rollback and no late navigation, not preview immutability
or post-import canonical activation under a changed owner. [I1] [I6] [I7]

**Disposition:** foreign read/bounded preview and transactional dedupe are
source-supported; safe private projection, exact deployed admission and
preview-confirmation identity remain integration gaps. Backup/atomic recovery
acceptance must not be reused to close them.

## HD-RADIO

**Exact local actions.** `register(ctx)` contributes only a statusbar player,
`defaultEnabled:false`; `play`, `stop`/toggle, next station, favorite, volume and
mute operate in the renderer. Storage keys `local.favorites`, `local.station`,
`local.volume` live under the plugin storage namespace, not Agent profile state.
No connection/profile/session identity or Agent RPC is applicable. HTTPS URLs
reject embedded user/password; directory discovery/search uses Radio Browser
with omitted credentials, bounded requests/timeouts and abort signals. Playback
opens the selected external stream; a CORS/audio-analysis failure can retry once
as ordinary playback. Artist metadata has separate external network effects;
none is permission to send Agent credentials. [R1] [R2]

**Lifecycle and limits.** Enabling alone creates no audio or fetch; explicit Play
starts media. Play generation fences old events; disabling disposes audio,
listeners, channel and audio context; another window's play sends `elsewhere`.
Intentional Pause is destructive; an externally paused intact stream can resume,
including Desktop's editable-field paste/dictation-completion behavior. That
behavior is not permission for Wing to auto-start on focus, Agent reconnect or
app relaunch. Pins survive locally; no Agent authoritative reconciliation is
needed. The inspected tests cover off-by-default/no-autoplay and disable/late
media events, not named-platform audio, third-party availability or accessibility
qualification. [R1] [R3]

**Disposition:** the authority question is resolved as client-local, not blocked
on a missing Agent API. Optional implementation remains separate, lower-priority
and must preserve deliberate audio/network intent and text/keyboard controls;
it must not introduce a runtime plugin loader merely to deliver a player.

## HD-VAULT

**Exact reads/writes.** All carry explicit supported profile context on the
captured connection: `vault.sources {}` returns installed/enabled/unlocked state;
`vault.list {}` returns enabled/unlocked-source item **metadata**, including
backend and login identifier metadata, never passwords. Locked external sources
contribute no items. `vault.source.set {name,enabled}` changes manager opt-out
config and locks on disable; enabling does not install or authenticate a manager.
`vault.unlock {name,password}` consumes a master password through the backend;
`vault.lock {name?}` forgets that manager's session token (all if omitted).
`vault.add {kind,label,origin?,secret}` writes a local login/payment/address and
returns only ID. `vault.remove {id}` removes from the **local** vault and returns
`removed`; an external listing is not remote-manager delete authority. [V2] [V3]

**Secret and concurrency boundary.** Desktop routes by connection+profile and
keys/remounts the panel by owner; source metadata is stale on remount/open.
Secrets are consumed from refs, not retained mutation variables; dialogs clear
password/drafts. Agent add scrubs submitted secret values from errors; unlock
scrubs its password. List metadata is still sensitive, and these localized
scrubs do not establish blanket redaction of every backend exception. No readback
of secrets, secret-bearing deep link, transcript, ordinary storage or reuse of
Wing endpoint credentials is permissible. Source locking is not provider-key
revocation or logout of an endpoint. [V1] [V2] [V5]

`remove` returning true then false is tested idempotent; add/source toggles/unlock
have no durable idempotency receipt or expected revision here. Cancelling a dialog
before submission is safe; closing or disconnecting after submission does not
undo an add, lock a manager, or prove an unlock failed. Reconnect reads the same
owner's sources/items; uncertain writes need reconciliation/fresh intent, not
secret replay. Tests assert password-free add/list/errors, opt-out persistence,
launch-profile scoping under multiplexing, owner-switch draft wiping and late
list/cache isolation; they do not qualify external manager lifetimes. [V4] [V5]

**Disposition:** source-safe local add/list primitives exist, but no Wing
advertised Vault contract, revision-safe item/source editor or qualified external
unlock path is established. Keep each unavailable independently.

## HD-PLUGIN-PACKAGES

**Agent half.** The wire method is `plugins.manage`, **not** separate callable
`plugins.install` / `plugins.update` routes. Actions are `list`, `toggle
{key|name,enable}`, `install {identifier|repo|catalog_name,ref?,force?,enable?}`,
`update {name,accept_capabilities?}`, `remove {name}`, `settings {key,values}`;
`onboarding` / `presence {names}` are catalog metadata. All have profile context.
Rows expose canonical key, package/source/pin, Desktop-half presence, settings
schema and activation metadata; `install_dir` is a private host path, not a
Wing file grant. `plugins.catalog.lookup {name}` returns found (repo/SHA/subdir),
invalid_name, unknown or unavailable from the backend catalog/kill list. Lookup
and list can resolve network-backed catalog metadata; they are not a zero-network
or secret-free-content promise. [P2] [P3] [P10] [P11]

Install can clone/write and enable/activate code. Catalog update can require
renewed capability consent and otherwise refuses non-catalog installs; removal
is for user installs, not bundled code. Settings refuse secret fields and
undeclared/badly typed keys; Desktop's separate environment-secret route is not
admitted by this study. Persisted settings, installed package and actual
`activation` / live-now / deferred / restart results must remain separate; MCP
server configuration alone does not implement package management. No expected
revision/durable idempotency contract is established for these actions. [P2] [P7] [P8]

**Desktop half.** Native bridge operations `probePluginRepo`,
`installDesktopPlugin`, `reconcileDesktopPlugins`, `removeDesktopPlugin` terminate
in Electron IPC (`hermes:plugin:probe`, `hermes:plugin:installDesktop`,
`hermes:fs:reconcileDesktopPlugins`, `hermes:plugin:removeDesktop`). They act on
the app-global plugin root, not a remote profile's filesystem. A local unified
Agent package's UI half is copied/reconciled; remote or Desktop-only packages
need a separate local clone. Runtime loading evaluates JS via blob `import()`
and registration. Neither Agent `has_desktop_half` nor a catalog row grants Wing
native execution, filesystem access or a Flutter ABI. [P1] [P4] [P5] [P6]

**Cancellation/recovery.** Agent install timeout is explicitly uncertain: do not
start the Desktop half or offer an automatic retry. Refresh captured-owner
inventory; do not promise rollback of one completed half when the other fails,
that closing a modal cancels clone/activation, or that a profile switch unloads an
app-global half. Tests assert refusal of non-catalog update, Desktop-half pairing,
secret-safe schema writes and unknown-install fencing; no atomic cross-host
package transaction/reconnect receipt is proven. [P7] [P8] [P9]

**Disposition:** authority split resolved, lifecycle unimplemented in Wing.
Agent package reads/writes, local contribution outcomes, secret settings and
arbitrary code loading remain separately gated; no copied Electron loader or
Git/shell fallback is a permissible successor.

## HD-SCREEN

**Exact calls and identities.** `display.status {profile}` returns runtime,
`profile_key` and public lease; `display.thumbnail` is separately read-only and
suppressed while a human holds control or the epoch changes during capture.
`display.observe {profile,viewer_id?}` requires an already running RFB/sandbox
screen; it mints a viewer for the **RPC transport**, reusing a requested ID only
if minted on that transport. It returns viewer ID and one-use nominal 30-second
ticket for `/api/display/ws`, bound to profile home and provider `bot-desktop`.
Snapshots/events expose a viewer hash, not the holder capability. `display.lease.acquire
{profile,viewer_id,reason?}` takes control; `display.lease.release {profile,viewer_id?,force?}`
hands it back, with foreign viewer checks and explicit force semantics. [S3] [S6] [S9]

The bridge validates host/Origin/client policy, consumes the ticket, and filters
keyboard, pointer and clipboard bytes against the authoritative lease. Desktop
forwards clipboard text only from an explicit paste event while not view-only,
with a size check; no background clipboard polling is admitted. [S1] A human
takeover is last-writer-wins, epoch increments; stale-holder release cannot yank
another holder. Cross-process lease checks refresh within 250ms; this is not a
zero-race global OS lock. Tool-level lease checks do **not** sandbox same-user
terminal/scripts that bypass those tools. Watching may reveal another human's
screen; the lease is input exclusion, not pixel confidentiality. [S4] [S5]

**Credentials and lifecycle.** Desktop places `display_ticket` in the WS query;
that is a recorded upstream behavior, **not a Wing-approved secret URL**. Wing's
security ADR prohibits it. A secret-safe supported native delivery design is
unresolved; do not copy this URL, mint tickets in this task, or patch Agent.
`display.start`, `.stop {force?}`, `.install` and `.switchSandboxImage` are
separate runtime/package/config effects in the handler, excluded from a viewer
slice. A missing running screen stays unavailable, never triggers lifecycle. [S2] [S3] [S4]

**Cancel/stale/reconnect.** Desktop's attach generation retires stale completions;
hiding retains stream, unmount closes with 1000. Clean bridge close (1000/1001)
releases only the holder; abnormal/code-less drop preserves the human lease so
Agent tools cannot resume into a login. Stream reattach spends a fresh ticket;
same RPC transport can reuse its minted viewer, but full RPC reconnect/restart
may mint a new ID and cannot silently reclaim the old exclusion. Explicit
Hand back/force is distinct from reconnection. A 4000 control-taken close has
bounded watch reattach, 4401 requires a new ticket, 4001 means no screen. Source
tests assert forged viewer refusal, guarded stop/release, ticket provider/home
and single use, and clean-versus-dropped lifetime. [S1] [S3] [S4] [S6] [S7] [S8]

**Disposition:** observation/lease source contract exists, but Wing secure ticket
delivery, full reconnect-owner recovery and an accessible non-canvas content/control
equivalent are unresolved. Keyboard lease buttons alone do not close parity.
This does not expand canonical Bot Chat, SSH forwarding or Files/terminal work.

## HD-PETS

**Exact sequence.** `pet.generate.status {profile?}` reports configured
reference-capable providers, not consent, credit, authorization or successful
inference. `pet.generate {profile?,prompt,referenceImage?,count?,style?,provider?}`
clamps drafts to 1–4 and returns token + index/data-URI drafts; progress first
publishes a token-only init frame. `pet.hatch {profile?,token,index,name,
cancelToken?,prompt?,description?,style?,provider?}` creates/installs a spritesheet
pet but does not activate it. `pet.select {profile?,slug}` installs if needed
and changes active-pet config; `.remove {profile?,slug}` deletes it and tries
active-config cleanup. Optional `.rename {profile?,slug,name}` can change slug;
adoption must use the returned slug. A preview is therefore already a disk
mutation, not merely local UI. [T1] [T2] [T4]

**Cancellation/identity gaps.** `pet.cancel {token,profile?}` sets a process-local
cooperative flag; hatch uses a separate cancel token to avoid generate cleanup
races. It does not stop/refund a provider call already in flight. The server's
staging root uses the current Hermes home; status/generate/hatch deliberately use
`scoped=False` while select/remove/rename use the profile-scoped wrapper. Canonical
secondary fallback supplies an outer scope in some cases [G1]; that does not
prove identical explicit-profile/secret scope for every standalone/launch-home
path. Cancellation flags are token-only, not owner/revision-bound receipts;
`pet.hatch.progress` lacks a draft token in this producer. No durable generation
job/status/resume or changed-request deduplication is established. [T2] [T3] [T4] [T5]

Desktop uses monotonic client run IDs, abort plus best-effort `pet.cancel`,
separate hatch cancel identity, and best-effort removal if a cancelled hatch
still returns a slug. Closing can leave work background-running; failure or
lost response is not proof no pet/file/provider effect occurred. Draft staging
is swept after one hour; token existence is not a durable result receipt.
Do not replay generate/hatch/select/remove on reconnect or auto-discard against
a replacement owner. Prompt/reference images, progress, slugs and provider
errors require private bounded handling; upstream generation logging is not a
Wing diagnostic allowlist. [T1] [T3] [T5]

**Disposition:** staged generation/adoption source semantics resolved, but safe
profile/run ownership, spending consent, cancellation/reconnect reconciliation
and deployed admission remain unqualified. No direct generate/hatch/cancel
handler regression was found in pinned `tests/`; the nearest inspected Desktop
gallery test proves only post-selection metadata/sprite synchronization, not
image calls, cancellation or owner isolation. Do not promote it to those claims.
A named/static preview with textual progress and reduced motion remains required,
not qualification supplied by a mascot animation. [T6]

## Successors and ownership

No new task is scheduled and no archived task is reopened. The matrix's existing
owner/association IDs remain intact; this document closes source research only.

A **conditional bounded read-only successor** can be specified for foreign
list/preview, separately from Continue/import: owner is the PARITY coordinator,
not the backup owner; depends on a Wing transport with verified exact
`session.foreign.list` / `.preview` admission and profile routing. Scope is the
captured-owner paged source list and ephemeral bounded text preview only—no
import/send/file-picker/backup, source path selection or persisted foreign catalog.
Acceptance must cover denied/missing operations (zero calls), max-50 candidate
pages and explicit pagination, 40-turn/8,000-character truncation disclosure,
host/cwd omission from persisted/diagnostic projections, owner change during list
and preview, cancel/Back, reconnect read refresh with zero writes, and keyboard /
screen-reader / large-text operation. Use one public-seam regression per changed
behavior and separate named-platform live qualification. This is **not runnable
until its transport/admission dependency is satisfied**, and is not an Android
priority prerequisite. [I2] [I3] [I4]

Radio has no missing Agent authority dependency, but a complete optional media
successor must first bind platform media/network/privacy and lifecycle acceptance;
none is added here. Do not propose broad export/import/Vault/packages/Screen/Pets
implementations across the explicit gaps above. Current Android SSH → profiles /
multi-session → canonical Bot Chat → touch priorities, deferred Files/slash gates,
paused jobs and existing external qualification gates remain unchanged.

## Documentation checks and update triggers

Required gate for this document: `git diff --check`, JSON parsing of
`docs/product/hermes-desktop-feature-matrix.json`, and verification of every
recorded operation against its pinned caller/handler/nearest tests plus every
citation's exact path/ranges/SHA-256. Validate local links and unchanged matrix
runtime objects/other rows. These are **documentation/source checks**, not
executed protocol tests, playback, Agent operations or Linux/Android acceptance.
This documentation-only slice changes no application behavior and adds no tests.
Actual commands/results belong to the worker report.

Revisit a row when its pinned producer/handler/schema/auth seam changes, an exact
connected-Agent advertisement becomes available, a Wing consumer lands, or a
named-platform receipt is supplied. Recheck the source first; do not repin to hide
drift or change a runtime result just because source research is complete.

## Pinned evidence ledger

All paths below are relative to the official Agent repository at the full pin
above. Each SHA-256 is of the **whole file**, not the quoted range. Multiple
ranges share that file identity. G/E/I/R/V/P/S/T label groups cover shared
admission, export, import, Radio, Vault, packages, Screen and Pets respectively.
No source test named here was run. Wing's unavailable/loaded-only observations
are additionally bound to W1–W5 below, not inferred from upstream absence.

| Ref | Exact source path and inclusive range links | Whole-file SHA-256 |
| --- | --- | --- |
| G1 | `tui_gateway/ws_legacy_fallback.py` · [30–73](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tui_gateway/ws_legacy_fallback.py#L30-L73), [84–167](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tui_gateway/ws_legacy_fallback.py#L84-L167) | `f7e4a0c98b870f1b05f9cec5ccc0257003f41f7e1fe98b14be908f963995295b` |
| G2 | `tui_gateway/ws.py` · [348–372](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tui_gateway/ws.py#L348-L372) | `7be64287e04a5a6994f792313cf8123680c329d70f53644020e689e99015ef4f` |
| G3 | `gateway/runtime_bootstrap.py` · [8–24](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/gateway/runtime_bootstrap.py#L8-L24) | `35b5dda25294337a6f6f6f60ab737d959136471bd7a98e91858273dbb75415f2` |
| G4 | `tests/tui_gateway/test_tui_gateway_ws.py` · [509–540](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tests/tui_gateway/test_tui_gateway_ws.py#L509-L540) | `2e40e63ceccaa2fea3c9c81e4862e2881b1c8c90e61a5d92347299f92849d469` |
| G5 | `hermes_cli/web_server.py` · [456–492](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/hermes_cli/web_server.py#L456-L492) | `f714b6d06ab22663887ce1e7ff092c2ddc73fab7b3254b567bd1d41f0aff670b` |
| E1 | `apps/desktop/src/lib/session-export.ts` · [29–59](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/lib/session-export.ts#L29-L59) | `3fc687a21f2f1eb935495a63f362c4629689eeae2bb41087d18fcd6c074eaa36` |
| E2 | `apps/desktop/src/api/sessions.ts` · [668–714](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/api/sessions.ts#L668-L714) | `316ba4a9b5a4e1f898328b56796a8eb180dc5360f9ba56ba82dcdcc03a11a64c` |
| E3 | `hermes_cli/web_routers/sessions.py` · [739–785](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/hermes_cli/web_routers/sessions.py#L739-L785) | `f1850450cb3060f211075cb5a884ca5307509ea570767c1efe4d9bbe70d9a66b` |
| E4 | `apps/desktop/src/hermes.test.ts` · [576–613](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/hermes.test.ts#L576-L613) | `0a8fdc9cb183d1c9e52e8047a05ffa7afc9c3c169d82b46b2d3f6313f8ed239e` |
| E5 | `tests/hermes_cli/test_web_server.py` · [2368–2452](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tests/hermes_cli/test_web_server.py#L2368-L2452) | `f514f0aadfc46da2fd17accd2d1f4315dae49ec3c25aea7e8c1b0018bb3c3422` |
| I1 | `apps/desktop/src/app/session-import/index.tsx` · [35–114](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/app/session-import/index.tsx#L35-L114) | `145df64f2df3881da182486cf1304e652da98b8990a33bfd22489e954ea4cc1f` |
| I2 | `apps/desktop/src/app/session-import/api.ts` · [36–49](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/app/session-import/api.ts#L36-L49) | `bd02d5dcfcf1b255f49b745820daadfd3b7036195f458d03c3680863dda7b9b7` |
| I3 | `tui_gateway/methods_session_foreign.py` · [9–42](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tui_gateway/methods_session_foreign.py#L9-L42) | `2dd0c73482b1cc40ff7f7c460575fd22ea9ceb08cb4726e4f33c005032564e03` |
| I4 | `hermes_cli/foreign_sessions_browser.py` · [22–96](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/hermes_cli/foreign_sessions_browser.py#L22-L96) | `d8419c271558eee3014c3679d5f4cc972fdf7b2328fe97510cce655bcfd9812c` |
| I5 | `hermes_state_portability.py` · [164–209](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/hermes_state_portability.py#L164-L209) | `3eca72538fae87b2fccac6fd3be8f44654d4a589184cd7d9664fbd63141fa001` |
| I6 | `tests/tui_gateway/test_session_foreign.py` · [10–97](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tests/tui_gateway/test_session_foreign.py#L10-L97) | `1868120f942c029c962e80a4eac322ae69c3b268b95c677feab02bac5f06344f` |
| I7 | `apps/desktop/src/app/session-import/index.test.tsx` · [49–102](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/app/session-import/index.test.tsx#L49-L102) | `96a18279aa3f887298276d7728727a3f997b31d84c119966b0fcaed449405ab0` |
| R1 | `apps/desktop/src/plugins/radio/plugin.js` · [94–365](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/plugins/radio/plugin.js#L94-L365), [455–470](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/plugins/radio/plugin.js#L455-L470), [600–697](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/plugins/radio/plugin.js#L600-L697) | `ecf4ef2519dbb18778374cee423c7dec895080125c395e55f322a84ed6f810af` |
| R2 | `apps/desktop/src/contrib/plugin.ts` · [196–216](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/contrib/plugin.ts#L196-L216) | `417a0d36aea8db62ee8245f5bc8b1a240302a76a343da59e0e55ee8a9794fdec` |
| R3 | `apps/desktop/src/contrib/radio-plugin.test.ts` · [34–87](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/contrib/radio-plugin.test.ts#L34-L87) | `41111112da7d6022c755e28ce17872d203dba41d982534fd70ff3f10d65034e8` |
| V1 | `apps/desktop/src/app/settings/vault-settings.tsx` · [159–375](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/app/settings/vault-settings.tsx#L159-L375) | `0edeb2e65c3fd717b90b748a75acef6d47a03c02afe742a1e2ccc1be18afd9be` |
| V2 | `tui_gateway/methods_vault.py` · [42–185](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tui_gateway/methods_vault.py#L42-L185) | `96e81ffbe290005d931e3e4b086797efd15fe89396b4067a687abff465346766` |
| V3 | `tui_gateway/contracts/profiles_vault_complete_foreign_subagents.py` · [447–559](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tui_gateway/contracts/profiles_vault_complete_foreign_subagents.py#L447-L559), [565–632](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tui_gateway/contracts/profiles_vault_complete_foreign_subagents.py#L565-L632) | `f4c537181ff334c9d7ffb14e6daae8755aedd6c4137989c323708ebf9f6ab630` |
| V4 | `tests/tui_gateway/test_vault_methods.py` · [50–177](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tests/tui_gateway/test_vault_methods.py#L50-L177) | `e7c99b97a1e2b6d16d2e5925f1d73b5df8125056f92108c52bc5143ef98b2b46` |
| V5 | `apps/desktop/src/app/settings/vault-settings.owner.test.tsx` · [86–165](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/app/settings/vault-settings.owner.test.tsx#L86-L165) | `afc85155ee7939eb3376f6a8ac896184c07e0363c4e480877e9c3b3e997c0af0` |
| P1 | `apps/desktop/src/app/settings/plugin-install-run.ts` · [31–214](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/app/settings/plugin-install-run.ts#L31-L214) | `79ba7de025f8d3e679231a8027c57cee18df41d47e1883d43ab48c8ac6e3909a` |
| P2 | `tui_gateway/methods_tools.py` · [1656–1845](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tui_gateway/methods_tools.py#L1656-L1845) | `1072d2339211229b575c56671c7cb989ef66f127deebcdb09bd8031b4cd600c5` |
| P3 | `tui_gateway/methods_plugin_catalog.py` · [21–41](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tui_gateway/methods_plugin_catalog.py#L21-L41) | `654fc3a222d86a7f474d99273f36b293dc1345bff2c7ad62ad22a92ab67f568a` |
| P4 | `apps/desktop/electron/fs-ipc.ts` · [116–178](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/electron/fs-ipc.ts#L116-L178) | `916d9a8a48c608f3764697ccb553547f797b783fdff890294986c6a2bca8b360` |
| P5 | `apps/desktop/electron/desktop-plugin-install.ts` · [412–490](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/electron/desktop-plugin-install.ts#L412-L490) | `711d07038d4c472edb1fb9c36a4090a117505bda8057ef1dd3391d4389c18a23` |
| P6 | `apps/desktop/src/contrib/runtime-loader.ts` · [380–429](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/contrib/runtime-loader.ts#L380-L429) | `f2e33d943aef03664c7a2a32d503cc6ff7d34a50f3d534d967b02b778c66af69` |
| P7 | `tests/tui_gateway/test_plugins_manage_install.py` · [7–81](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tests/tui_gateway/test_plugins_manage_install.py#L7-L81) | `e27976e45e60ef88ad07b187c08857cb826103d146ea59efa6b62a23343af5f2` |
| P8 | `tests/tui_gateway/test_plugins_manage_settings.py` · [39–66](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tests/tui_gateway/test_plugins_manage_settings.py#L39-L66) | `cef78295ede42876c3c7d344761e6c316a2b0738aad1d6edcf893f1fd8d12fc6` |
| P9 | `apps/desktop/src/app/settings/plugin-install-modal.test.tsx` · [327–396](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/app/settings/plugin-install-modal.test.tsx#L327-L396) | `220fbef70c9bdfea490af51a098f6f7b3df13a67142d9ced1317cbd32f55ee96` |
| P10 | `tui_gateway/contracts/tools_mcp_plugins.py` · [615–649](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tui_gateway/contracts/tools_mcp_plugins.py#L615-L649) | `532fd04a74be7113640c8d15f2c9588f22b2881f20aff62eec5ee7973cc27469` |
| P11 | `tests/tui_gateway/test_plugins_catalog_lookup.py` · [32–58](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tests/tui_gateway/test_plugins_catalog_lookup.py#L32-L58) | `c1c2375519c921d8f1a79b3bbd22e6c0324bf0a8efebe530641e438ce10bc07f` |
| S1 | `apps/desktop/src/plugins/hermes-bots/screen-pane.tsx` · [156–325](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/plugins/hermes-bots/screen-pane.tsx#L156-L325), [374–409](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/plugins/hermes-bots/screen-pane.tsx#L374-L409) | `f94665685e77dbc44e9ec69e3dc8933118dfb51aad0813e27d5f4f85b93e01e5` |
| S2 | `apps/desktop/src/plugins/hermes-bots/screen-connection.ts` · [164–190](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/plugins/hermes-bots/screen-connection.ts#L164-L190) | `212214fc13580c33744d51f2f5963bcd81e4be311e107147580c9b6ac2419465` |
| S3 | `tui_gateway/methods_display.py` · [50–265](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tui_gateway/methods_display.py#L50-L265) | `b7329a48665d1129f0637250b5facfd4ac2a6735c0d45f8755dbfcc134107849` |
| S4 | `hermes_cli/web_routers/display.py` · [61–90](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/hermes_cli/web_routers/display.py#L61-L90), [121–244](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/hermes_cli/web_routers/display.py#L121-L244) | `2539107ba2b8a98e2510c29fb04f61885eb33f11bdf49926961810da97f16e60` |
| S5 | `tools/bot_desktop/lease.py` · [1–18](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tools/bot_desktop/lease.py#L1-L18), [203–249](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tools/bot_desktop/lease.py#L203-L249) | `6c49998bed955a236ca90bef1975352a09ae38acb7cb18115fed81c2129a21b9` |
| S6 | `tests/tui_gateway/test_display_methods.py` · [88–194](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tests/tui_gateway/test_display_methods.py#L88-L194) | `83bc46852fc017ccd6f6baf3c55fee96923c946b05f80629a434b0b71f93be9f` |
| S7 | `tests/hermes_cli/test_display_ws_ticket.py` · [15–59](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tests/hermes_cli/test_display_ws_ticket.py#L15-L59) | `17a6fb7cbd19fb98ed1f4649febbbb75613f8a26e6e884996bc91151b654f91d` |
| S8 | `tests/hermes_cli/test_display_ws_drop_keeps_lease.py` · [53–65](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tests/hermes_cli/test_display_ws_drop_keeps_lease.py#L53-L65) | `ed734d1c45f9658096961c66f55b593ae5c68406eb12ebbce65fb5c8499ee533` |
| S9 | `hermes_cli/dashboard_auth/ws_tickets.py` · [21–65](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/hermes_cli/dashboard_auth/ws_tickets.py#L21-L65) | `c0a1a63623df7c7291d06a85c18f583ab112fa8b73ccc6359bbdbbd938f376a7` |
| T1 | `apps/desktop/src/store/pet-generate.ts` · [134–215](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/store/pet-generate.ts#L134-L215), [239–450](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/store/pet-generate.ts#L239-L450), [466–646](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/store/pet-generate.ts#L466-L646) | `7ea0640e13c3d44adead30c996fdf708370cfa1ff3d9715ca8e4696856d0785d` |
| T2 | `tui_gateway/methods_session.py` · [186–201](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tui_gateway/methods_session.py#L186-L201), [1568–1622](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tui_gateway/methods_session.py#L1568-L1622), [1644–1655](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tui_gateway/methods_session.py#L1644-L1655), [1683–1820](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tui_gateway/methods_session.py#L1683-L1820) | `4c90fb8bb321a9f38a4fc515c2e7e1cbe624c6f93a24464d4cb51f5c1f356582` |
| T3 | `tui_gateway/server.py` · [1885–1970](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tui_gateway/server.py#L1885-L1970) | `ced7eefae39a290693cd6e8c53b7a3595638108080b1e753828388566d278b8b` |
| T4 | `tui_gateway/contracts/billing_delegation_pets.py` · [494–592](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tui_gateway/contracts/billing_delegation_pets.py#L494-L592) | `e4093448bfad9eb3ea25749e2277431421ff63e2bc3f3fe9ed429692276b820d` |
| T5 | `agent/pet/generate/orchestrate.py` · [86–162](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/agent/pet/generate/orchestrate.py#L86-L162) | `241f048b8beacf48c084e2bbbd6edf38bc0b65ce45224789f49273a236fb63df` |
| T6 | `apps/desktop/src/store/pet-gallery.test.ts` · [169–210](https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/store/pet-gallery.test.ts#L169-L210) | `b9e2bbff950d993cec059ae8f5b0e2e3e0dd7a411930723c2b88111dff3c9d90` |

### Wing baseline evidence

Paths are relative to Wing at `8ed7c2fc8fe5391e44d9417b10f631dd3b57fec6`.
W1/W2 implement loaded-only save; W3/W4 bound current route/Tools absence;
W5 asserts unavailable native export and loaded-only scope (inspected, not run).

| Ref | Exact source path and inclusive range link | Whole-file SHA-256 |
| --- | --- | --- |
| W1 | `lib/features/hermes_chat/screens/hermes_chat_screen.dart` · [1422–1475](https://github.com/TrebuchetDynamics/hermes-wing/blob/8ed7c2fc8fe5391e44d9417b10f631dd3b57fec6/lib/features/hermes_chat/screens/hermes_chat_screen.dart#L1422-L1475) | `84d1a8aaca5031c24d1ad6f1e5cd7d89c66af9a4336c6031f5d9a21526a3d221` |
| W2 | `lib/features/hermes_chat/export/hermes_transcript_export_io.dart` · [8–42](https://github.com/TrebuchetDynamics/hermes-wing/blob/8ed7c2fc8fe5391e44d9417b10f631dd3b57fec6/lib/features/hermes_chat/export/hermes_transcript_export_io.dart#L8-L42) | `e86f92c4b86de42dea75a103f3ff0b58d2920624dbcda93465bfaa0851a6a8c6` |
| W3 | `lib/router/providers/app_router.dart` · [60–204](https://github.com/TrebuchetDynamics/hermes-wing/blob/8ed7c2fc8fe5391e44d9417b10f631dd3b57fec6/lib/router/providers/app_router.dart#L60-L204) | `3543fa91c3c67618ae210039d245a005a343a26da8ea9249b936577e2710c119` |
| W4 | `test/features/tools/tools_screen_test.dart` · [62–83](https://github.com/TrebuchetDynamics/hermes-wing/blob/8ed7c2fc8fe5391e44d9417b10f631dd3b57fec6/test/features/tools/tools_screen_test.dart#L62-L83) | `c57d9a7d76894d65b49fc2d6216b22a83da3fe26a649cff7fc4515d22fd4ddff` |
| W5 | `test/features/hermes_chat/screens/hermes_chat_transcript_export_test.dart` · [114–161](https://github.com/TrebuchetDynamics/hermes-wing/blob/8ed7c2fc8fe5391e44d9417b10f631dd3b57fec6/test/features/hermes_chat/screens/hermes_chat_transcript_export_test.dart#L114-L161) | `237033a9b17f40ddc08f44460c119c2cc6c20b2cd503685fdee317ff3a926a17` |
