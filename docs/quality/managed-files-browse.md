# Agent-managed Files: read-only Wing candidate

## Scope and authority

Implements `FILES-TERMINAL-BROWSE` under the
[owner-approved managed-root exception](../adr/product.md#owner-approved-files-surface-the-agents-managed-files-root),
not the deferred terminal-cwd contract. This is an offline candidate receipt,
not canonical integration, device qualification or Desktop Files parity.
`FILES-TERMINAL-DOWNLOAD` extends this candidate with individual raw downloads
and verified native saving, described below. Real picker/device qualification
remains open.

Chat exposes **Files** in the compact overflow menu and wide toolbar. Native
Linux/Android serve readers can request the current connection's managed policy;
messaging-only connections and browser transport render unavailable without file
requests. Existing Local, native SSH-forward and HTTPS gateway serve connections
retain their owning authenticated reader. Opening Files does not connect Chat,
select a profile/session, submit a prompt or change Agent configuration.

The displayed connection/profile/conversation identify the current Wing context;
these routes are connection/deployment scoped, **not profile/session folder
APIs**. The root is not a Hermes home, Project or terminal cwd.

## Gate, bounds and recovery

- Every admitted listing/preview requires matching nonempty `root`/`locked_root`
  and `can_change_path: false`. Missing/inconsistent metadata, root changes and
  malformed paths fail closed. This candidate supports canonical POSIX paths;
  filesystem root `/` is deliberately unavailable to avoid a host-wide browser.
  Neither Windows path shapes nor unlocked policies receive a fallback.
- Initial listing must be the advertised root with `parent: null`. Navigation
  uses only the current page's directory/parent handles. Prior-page handles are
  discarded. Client traversal/outside-handle validation is additional input
  checking, **not** canonical or symlink containment authority.
- Agent owns canonical containment and sensitive-path denial. Managed entries use
  `is_directory`, unlike `/api/fs/list`'s `isDirectory`. Confined aliases retain
  their display names and canonical targets; broken-link placeholders are not
  readable. Preview identity checks the canonical target, not the alias basename.
- Listings admit at most 500 entries and 512 KiB on the wire. Preview source and
  decoded text are limited to 64 KiB, with a 128 KiB streaming response ceiling,
  including unknown content lengths. Known oversized files are refused before
  reading. Oversized content is rejected, not silently truncated.
- Previews are selectable **literal** strict UTF-8 text, including HTML. Binary
  control bytes/invalid UTF-8 are refused. There is no HTML execution, WebView or
  download-byte reconstruction.
- Browse/preview use authenticated `GET /api/files` and `GET /api/files/read`;
  individual downloads additionally use `GET /api/files/download`.
  Credentials remain in the reader's Authorization header, never URLs.
  Redirects are not followed. Raw server errors, paths and content are not logged
  or persisted. The volatile dialog does not put file data into Chat state.
- Connection, reader and profile/session selection generations fence each lease,
  including same-tuple roundtrips. The opening action captures its lease before
  deferred route construction: owner changes before the first frame cause zero
  reads. Visible data clears on owner loss; late responses and cached controls
  cannot act on a replacement attempt. Retry explicitly starts at the current root.
- Loading, empty, denied, unavailable, oversized, binary, failure and changed-owner
  states have localized explanations. Native list tiles/buttons support touch
  and keyboard input; Close/Escape dismisses without changing Chat. Header
  compactness follows actual layout constraints, including embedded narrow panes.

## Source-bound server-policy oracles

Unmodified upstream pin: `14e1e43a23761b369641208e204365cd6cb9399d`.
Public raw-source bytes were rechecked during this attempt; these hashes match
those inspected by the earlier candidate. The local read-only reference checkout
is at a different revision and was not changed to obtain this pin.

| Upstream source | SHA-256 |
| --- | --- |
| `hermes_cli/web_routers/files.py` | `5e41dfe3bebb392492a836b532239ff67843ae70dfbdc2b0777d78658e40c828` |
| `hermes_cli/web_server_files.py` | `a8183d13e98b42acc35c2450c863edec2aff349226c6d568d456d69bbd99e448` |

- [`_resolve_managed_path`](https://github.com/NousResearch/hermes-agent/blob/14e1e43a23761b369641208e204365cd6cb9399d/hermes_cli/web_server_files.py#L302-L345)
  refuses `..` with 400, canonicalizes existing targets and refuses absolute or
  resolved symlink targets outside a locked root with 403.
- [`_managed_file_entry`](https://github.com/NousResearch/hermes-agent/blob/14e1e43a23761b369641208e204365cd6cb9399d/hermes_cli/web_server_files.py#L372-L433)
  checks resolved-target containment and separates alias name from target path.
- [`list_managed_files` / `_managed_readable_file`](https://github.com/NousResearch/hermes-agent/blob/14e1e43a23761b369641208e204365cd6cb9399d/hermes_cli/web_routers/files.py#L515-L581)
  filter sensitive listing paths and refuse sensitive resolved read paths. Root
  listings have no parent; read responses include policy metadata.

These are **static source-bound denial oracles**, not executed upstream tests or
proof of a deployment. Wing HTTP fixtures prove client traversal/outside-handle
refusal and sanitized propagation of simulated symlink/sensitive-path 403 denials.
They do not prove actual filesystem confinement or race safety. See the
[corrected wire contract](../analysis/terminal-files-feasibility.md#managed-files-root-the-owner-selected-alternative).

## Reconciliation on the repaired baseline

This attempt reuses the task-only delta from retained candidate
`6200cc0066bf8a8e396f3285f24b5446cefc0672` on baseline
`7ec14e40429ace569e883a0ef192ed1c04934d89`, rather than duplicating the Files
implementation. `MAIN-REPAIR-004` is coordinator-verified in that baseline.
The repaired rich-transcript test remains byte-identical to the baseline
(Git blob `b49253e295ca763ed14eeeb0530c9fbf0abec4c4`); Files changes neither its
assertions nor message styling. See the
[repair and held-integration evidence](../tasks/main-offline-test-repair-6036dbc3.md).

The earlier held candidates and their raw exit-1 receipts remain historical
evidence, not accepted work or a waiver of the merged gate. The checks below are
fresh results on the repaired baseline plus the reused Files delta. The runner
still owns the normal merged full-suite gate after this local task commit;
these worker checks do not establish green main or integration acceptance.

## Offline checks and regression scope

`flutter gen-l10n` regenerated both localization outputs from `app_en.arb`.
The focused command
`flutter test --no-pub --concurrency=1 test/core/hermes/client/hermes_managed_files_test.dart test/core/hermes/channel/hermes_local_serve_reads_test.dart test/features/hermes_chat/hermes_managed_files_dialog_test.dart`
passes all 18 cases. Its regressions cover locked/unlocked policy, confined
aliases, traversal/outside handles, denial redaction, preview bounds, stale leases,
compact/wide entry, literal preview, keyboard parent navigation, explicit retry,
and ownership loss before opening or during a read.

Final required module run,
`flutter test --no-pub --concurrency=1 test/core/hermes/ test/features/hermes_chat/`:
**3010 passed, nine existing opt-in SSH fixture cases skipped, zero failures;
process exit 0.** `MANAGED_SSH_FIXTURE` was not supplied; those skips do not
qualify actual SSH file access. No baseline-failure exception is used.
`flutter analyze --no-pub` reports no issues. The release JS build of
`lib/main_e2e.dart` succeeds; existing third-party TTS Wasm dry-run and missing
Cupertino font warnings are not Wasm/native qualification.

After rebuilding, `npm run web:e2e` with Node 22 and Chromium passes 91 cases;
one live-service case is intentionally skipped. The changed smoke module passes
all eight cases, including unavailable Files with no managed-file requests on
browser/messaging transport. These are Linux-host deterministic checks, not native
Linux/Android application runs. The task report retains exact commands and final
formatting/documentation checks.

The formerly held case, `message surfaces use the compact Desktop corner
treatment`, now passes in isolation (one case). The complete rich-transcript and
desktop-geometry modules also pass together (95 cases), preserving independent
user 3.2px and flat-assistant 0px assertions supplied by the prerequisite repair.
No Files styling repair, removed assertion, skip or gate-classifier override was
introduced. Local tests and browser fixtures still do not replace the runner's
merged full-suite result.

## Outstanding deployment and device cells

Before qualifying a named live target, verify its actual serve credential,
locked policy and refusal of `..`, absolute outside-root paths, symlinks and
sensitive files. Wing makes no runtime/configuration change. Agent's managed GET
resolver may create a missing configured root (`create_root=True`); use a
prepared, pre-existing root and check for incidental server mutations. Zero Wing
mutation requests is not proof of zero server-side writes.

Native Linux keyboard and Android touch/device operation, screen readers, actual
SSH/HTTPS file permissions, live Agent behavior and containment/concurrency races
are **NOT_CHECKED** here. Host-root `/` and non-POSIX policies stay unavailable.
No live service or physical device was exercised. The browse receipt above does
not qualify the download extension below. Terminal-cwd Files parity remains
explicitly unclaimed.

## Individual download extension — FILES-TERMINAL-DOWNLOAD

The dialog offers a separate **Download file** button for each listed file,
including binary files without opening their preview. Only the current bounded
listing's handles, the same advertised locked root and the qualified owning
serve reader can authorize retrieval. Browser/messaging connections and other
native platforms receive no save action. No upload, Agent edit/delete, recursive
folder download, external URL launch or content execution is added.

- Raw `GET /api/files/download?path=…` uses the owning reader's Authorization
  header, never a token-bearing URL. Profile/session folder parameters are not
  invented for this connection-scoped managed route. Redirects, partial responses
  and encoded representations are refused. Both known and unknown response
  lengths have an 8 MiB ceiling and a 30-second retrieval deadline.
- Progress reports retrieved bytes, then distinguishes destination selection and
  local verification. Retry is explicit, with a new attempt identity. Cancellation,
  denial, disconnect, owner change, dialog disposal and corrupt readback cannot
  publish a verified-save receipt. Downloaded bytes stay volatile outside Chat
  and preferences; neither errors nor diagnostics expose destination paths/content.
- Suggested names come from the selected entry, not Content-Disposition. Path
  separators, control/bidi characters and non-ASCII characters become underscores;
  leading dots/dashes, reserved device names and excessive length are handled.
  The native chooser, not the Agent filename, selects the device destination.
- Linux uses the existing GTK Save As plugin and a second explicit replacement
  confirmation, even when a destination did not previously exist. Existing links
  and special files are refused. A private same-directory staging file is written,
  then atomically renamed over the chosen destination entry: a link swapped in
  after validation cannot redirect the truncating write to its target. This
  replaces the file entry, not its metadata or hard-linked siblings. The actual
  final destination is read back and compared byte-for-byte with the raw response.
  Publication reserves the canonical destination until any submitted rename
  settles, even after cancellation/timeout; another save to that destination fails
  explicitly rather than letting an older pending rename overwrite a verified retry.
- Android uses `ACTION_CREATE_DOCUMENT`, keeping the content URI exclusively in
  the native channel. The system creates a new document rather than silently
  overwriting an existing one. Attempt IDs reserve an outstanding chooser until
  its result returns; stale choices cannot target a later attempt. Descriptor
  reads and writes run off the UI thread with cancellation signals and closeable
  attempt-owned resources. Native and Dart comparisons both require exact bytes.
  At most two native I/O jobs run without an accumulating retry queue; an occupied
  provider lane returns an actionable failure rather than waiting behind it.
  Descriptor/signal cancellation and best-effort deletion use separate bounded,
  no-queue pools, so a stuck delete does not hold up cancellation or grow a queue.
- After destination consent, local I/O has a 30-second deadline. Cancel escapes
  pending work and requests handle/descriptor closure; subsequent explicit retries
  have independent ownership. OS chooser interaction itself has no automatic
  deadline. A provider/kernel call that ignores cancellation can outlive the UI;
  it cannot restore a success receipt or authorize another destination. Android
  partial-document deletion and Linux staging cleanup are best effort, not rollback
  guarantees. An interruption after final replacement may leave an unconfirmed
  destination. No automatic retry or silent replay occurs.

The raw handler and nearest download tests were also inspected in the read-only
upstream checkout at `158fd638da1629c8e62caf9ade1515d162def8ab`
(`hermes_cli/web_routers/files.py`, `tests/hermes_cli/test_web_server_files.py`).
This source inspection is not an executed upstream test or deployed receipt.

Readback proves equality with the **retrieved response**, not an immutable remote
revision: the Agent download route provides no source snapshot/digest or atomic
policy-discovery-plus-download contract. Live deployment confinement, source
changes and local destination races beyond the final-entry symlink swap still
require target qualification. No Agent changes are made.

### Offline oracles and remaining native receipts

The focused Flutter command is:

```sh
flutter test --no-pub --concurrency=1 test/core/hermes/client/hermes_managed_files_test.dart test/core/hermes/client/hermes_web_read_test.dart test/features/hermes_chat/hermes_managed_file_save_test.dart test/features/hermes_chat/hermes_managed_files_dialog_test.dart
```

It passes 27 tests, covering authenticated text/binary bytes, unknown-length bounds,
redirect/denial refusal, progress, explicit retry, cancellation/disconnect/owner
loss, real temporary Linux file writes/readback, hostile suggested names, overwrite
consent, deterministic destination-link replacement during open, stalled-open
cancellation/retry isolation, cancelled pending-rename destination reservation,
and mocked Android channel choice/write/cancel/release
identity. The transport source-contract allowlist includes the new internal native
reader part, not another public native import path.

`ManagedFileSaveJobTest` adds two JVM oracles for Android's production byte-I/O
helper: text/binary readback mismatch refusal and actively closing a stalled
stream followed by successful new work. They pass with cached Kotlin 2.2.20 and
JUnit 4.13.2. The Gradle unit-test task could not resolve an existing uncached
AndroidX test-runner version in offline mode; standalone JVM execution does not
qualify Activity, picker, provider or engine lifecycle behavior. The Android debug
APK builds, with existing SDK/Kotlin plugin warnings; it was not installed.

Final required module run,
`flutter test --no-pub --concurrency=1 test/core/hermes/ test/features/hermes_chat/`,
passes **3022 cases, nine existing opt-in SSH fixture skips, zero failures**.
`flutter analyze --no-pub` reports no issues; changed-Dart formatting and scoped
local-link/anchor/readback checks pass. Exact commands and the Gradle environment
failure are recorded in the task report. Existing source-bound managed-root denial
receipts above are reused without upgrading them to deployment evidence.

Separate pending native cells remain: (1) real Linux GTK Save As, keyboard input,
permissions, overwrite/cancel, disk failure and final destination readback; (2)
Android document provider create/readback for text/binary/hostile names, denial,
blocked I/O, cancellation, Activity recreation and owner/disconnection races.
Both need a named target and the owning authorized Agent connection. Fixture and
JVM results, download-start signals and APK compilation do not qualify either cell.
