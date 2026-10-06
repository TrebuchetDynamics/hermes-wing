# Loaded-transcript file export

Status: browser slice accepted after same-card tester/reviewer verification on
`t_7ce5f032`. Linux saving and full Linux/web validation on `t_38174cb7` have
executor evidence only; independent same-card review remains pending. This does
not complete M5 or qualify a release.

## User flow and boundaries

Open Chat's existing Copy transcript action (More actions at compact widths).
Copy as text and Copy as Markdown remain available. On web, Save as text and
Save as Markdown explicitly request a local browser download; on Linux they open
the native GTK save dialog. The sheet states
that all currently loaded turns are included, not just the presentation window,
and that older unfetched history is excluded. Export never fetches history,
changes selection, submits a prompt or invokes Wing Link/Agent file operations.

The Save choice captures the current transcript synchronously, not when the sheet
first opens. Channel, origin, profile, session and existing composer ownership
generation bind the action: a changed owner must reopen the actions. The immutable
UTF-8 bytes are not rebuilt after a platform wait. Dismissal before Save writes
nothing; overlapping actions are excluded. A disposed or superseded owner cannot
write through the save seam or receive a late success notice.

Files use fixed names `hermes-transcript.txt` and `hermes-transcript.md`, with
`text/plain;charset=utf-8` and `text/markdown;charset=utf-8` respectively. No title,
endpoint, credential or host path influences the filename. Text/Markdown reuse
the existing copy serializers: message text and metadata keep the shared redaction
policy; attachment names now also pass through that policy for both copy and save.
Tool payloads remain excluded. Ordinary content/Markdown semantics are preserved,
including inert HTML source; this flow adds no executable preview. Redaction is
pattern-based, not a promise to anonymize all personal content. Choose a private
local destination and review the file before distributing it.

Output is capped at 4 MiB of UTF-8. A conservative preflight additionally bounds
source UTF-16 units plus 256 units per loaded turn before redaction/serialization;
it can reject a large input even when redaction would shrink the output. Rejection
is explicit and never truncates turns. Files contain the same serializer output
as copy, without a BOM or added loaded-history note. No transcript is staged in
ordinary preferences, logs or temporary disk files by Wing. Browser Blob memory
URLs are revoked after 30 seconds; the browser manages its download destination.

## Platforms and outcome wording

Web uses the existing package:web Blob and anchor download facilities. Linux uses
the existing file_selector save-location API and writes the captured bytes directly
to the user's selected local file. Ownership is rechecked after the dialog and
before writing; cancellation writes nothing. A write failure reports a redacted
error, not success. Once a filesystem write starts, changing owners cannot roll it
back; the UI still suppresses a stale success notice. Selected paths are never
persisted or reported to Agent/Wing Link. Other native targets retain the unsupported
explanation; plugin availability alone does not qualify macOS/Windows/Android/iOS.

Wing reports "download requested", never that the OS definitely saved the file.
Browser policy, an OS prompt or the user's cancellation can prevent persistence
without notifying the anchor API. Check browser downloads. The tested Chromium
harness independently waits for the actual download event, checks failure, reads
the actual file and compares its bytes; it is not a production save override.
Linux reports "saved" only after the file write finishes. This is distinct from
the browser's "download requested" wording. Other browsers, Android, other native
desktop targets and Wasm are not qualified here.

## Linux native executor evidence (not independent acceptance)

On Flutter 3.44.2/Dart 3.12.2 with the unchanged enforced lockfile, the compiled
Linux debug app ran under an owned
Xvfb display, private DBus session and disposable HOME/XDG state. The six native
export tests passed: text and Markdown at 390/1280, all 250 loaded Unicode turns
compared byte-for-byte with the real clipboard, Escape cancellation, and owner
change while the real GTK dialog remained open. The latter wrote no file and no
late success notice. Native semantics labels, no history fetch and no image send
were asserted. The harness overrides only the Agent channel/storage with synthetic
fixtures, not the save plugin or filesystem. It is not real Agent inference.

Run `scripts/run_linux_native_input_e2e.sh` with its required Fluxbox/X11 tools,
qualified Flutter and an owned `TMPDIR`. It executes input and export targets
separately and returns failure if either fails. Bare Flutter's simple GTK input
target still leaves literal `u00e9` after an earlier emoji commit; no Flutter or
test workaround was applied. A different, real IBus 1.5.32 target passes all four
original native-input tests, including emoji commit, Escape cancellation and
collapsed composing ranges, real open-file picker and minimize/restore. That
target requires the official GTK IBus module, `xkb:us::eng` engine and GTK
extension with its dictionary data. In rootless extraction, only the extension
uses an official PRoot process-local dictionary-path binding; Wing and Flutter
run natively outside PRoot. The app's loaded IBus module was independently
verified. This is named container-local X11/GTK evidence, not generic stock
desktop, Wayland, CJK IME, screen-reader/TalkBack, native voice or release
qualification. Full-suite and independent review gates remain separate.

The broader executor checks also reproduce and repair a Linux transcript pinch
conflict with selectable text: two pointers claim the scale gesture together,
without removing desktop selection or context menus. The Android/Linux widget
variants pass, but an Android variant on a Linux runner is not Android device
qualification. Current locked-run evidence includes 1,898 unit/widget tests,
1,061 native feature regressions, and two separate keyring processes proving
independent credential persistence without using a personal keyring. The native
profile stress run originally hit the existing ten-minute timeout for 1 MB of
repeated code blocks. The local extent-aware Markdown viewport repair now passes
the original ten-case native profile matrix in one process with unchanged
deadlines. Its regression records a transient mount peak of 6–7 instead of 1,000
at distant jumps; mixed natural extents, layout invalidation, selection and exact
code copy remain tested. Large paragraphs and tables still have substantial
latency; this is not a 60-fps qualification. The two specifically authorized
inherited test files received formatting-only changes and the broad format gate
now passes. Live Agent/provider and destructive disposable-host suites require
explicit target/credential/mutation authorization and remain unexecuted, not
passed; see the card's final-source coverage matrix. Independent same-card review
has not yet accepted this Linux/web repair.

## Browser baseline verification (parent card)

Executor exercised Linux Flutter unit/widget tests and compiled JS-release
Chromium only (Flutter 3.47.5, Dart 3.13.4, Node 26.5.1). The subsequent Linux/web
card exercises Flutter 3.44.2/Dart 3.12.2 with the unchanged lock; Node 22 remains
unexercised. Do not merge those receipts with this historical browser baseline.

- Initial regression failed because the unsupported export explanation was absent.
- 22 focused service/actual Chat tests passed: full loaded 250-turn text/Markdown,
  Unicode, immutable bytes, byte limits, redacted metadata/attachments/tool exclusion,
  original Markdown source, confirmation-time updates, stable snapshots, origin/
  profile/session races, cancellation/disposal/failure/repeated taps, unsupported
  native gating and compact 390px/200% text semantic keyboard activation.
- 1,110 affected tests passed across `test/features/hermes_chat`,
  `test/core/hermes/channel`, `test/core/hermes/client`, `test/shared/security`:
  rich-transcript, window, message-action accessibility, restoration and picker
  regressions are included. Analyze passed.
- Release `main_e2e` build passed; inherited flutter_tts Wasm dry-run and Cupertino
  font warnings remain. These warnings are not Wasm/native qualification.
- 16 compiled Chromium checks passed with workers=1/retries=0: export plus
  production journey, window, session-model picker and restoration at 390/1280px.
  Four actual downloads matched independent expected 250-turn content: text
  8,263 bytes, Markdown 9,013 bytes at each width, with fixed filename/MIME and
  clipboard equality. Export caused zero remote mutations and zero history reads;
  all 250 turns remained loaded while only 100 rows were allocated. Escape added
  no third download. Tests assert no browser page errors.

Relevant commands (use unused loopback ports; stop only your owned fixture):

```bash
flutter gen-l10n
flutter analyze
flutter test test/features/hermes_chat/export \
  test/features/hermes_chat/screens/hermes_chat_transcript_export_test.dart --concurrency=1
flutter test test/features/hermes_chat test/core/hermes/channel \
  test/core/hermes/client test/shared/security --concurrency=1
flutter build web --release -t lib/main_e2e.dart
PORT=9120 HERMES_E2E_PORT=9121 node serve_web.mjs
# In another terminal; choose your installed Chromium executable.
CHROME_EXECUTABLE=/opt/data/cache/wing-playwright/chromium-1228/chrome-linux64/chrome \
WING_APP_URL=http://127.0.0.1:9120/ npx playwright test \
  playwright/tests/regression/transcript-export.spec.mjs \
  playwright/tests/regression/production-chat-journey.spec.mjs \
  playwright/tests/regression/chat-window.spec.mjs \
  playwright/tests/regression/session-model-picker.spec.mjs \
  playwright/tests/regression/session-restoration.spec.mjs --workers=1 --retries=0
node --check playwright/tests/regression/transcript-export.spec.mjs
git diff --check
```

The inherited fixed synthetic long-transcript fixture was reused without edits.
Downloads and bounded sanitized receipts are in the task's executor evidence
attachment. They prove compiled product downloading, not live Agent inference,
scoped-auth qualification, server export or arbitrary artifact retrieval. See
[long-conversation reading](chat-long-conversation.md) and [routes](../product/routes.md).

## Exact-owner failure feedback repair (t_aaa10f17)

Same-card review approved this repair in native run 106; task `t_aaa10f17`
is done. The reviewer independently reran the 127 focused export/copy/service
cases, formatting, analyzer and scoped whitespace checks, all with exit 0.
Native review is an approval lane, not native application execution. Export
feedback now checks the existing channel identity, origin/profile/session tuple,
composer generation and mounting predicate after both successful and rejected
settlement. An already-started save that rejects after an owner change no longer
shows an unrelated error in the replacement conversation. This does not cancel,
undo or automatically retry a platform write. Same-owner failures still show the
existing sanitized error and release the pending action guard for explicit retry.

Actual `HermesChatScreen` widget RED:

```bash
flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_transcript_export_test.dart --plain-name 'delayed export rejection session text 390.0' --reporter expanded
```

Before the production edit, exit 1: expected no matching candidates but found one
widget displaying "The transcript could not be exported. No success was confirmed.
Try again explicitly." The identical command passed after the one-line feedback
fence (exit 0). The local saver fake admits the write before waiting and then
rejects; it does not use post-wait owner cancellation to simulate rejection.

Final focused checks (all exit 0):

```bash
dart format --output=none --set-exit-if-changed lib/features/hermes_chat/screens/hermes_chat_screen.dart test/features/hermes_chat/screens/hermes_chat_transcript_export_test.dart
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 --reporter=json test/features/hermes_chat/screens/hermes_chat_transcript_export_test.dart test/features/hermes_chat/screens/hermes_chat_transcript_clipboard_test.dart test/features/hermes_chat/export
git diff --check -- lib/features/hermes_chat/screens/hermes_chat_screen.dart test/features/hermes_chat/screens/hermes_chat_transcript_export_test.dart docs/runbooks/chat-transcript-export.md
```

Parsed focused result: 127 passed, zero failures, zero skips. Additive cases cover
text/Markdown at 390/1280 widths: delayed rejection across session, profile, origin,
same-tuple channel replacement, A-to-B-to-A generation and disposal; current-owner
rejection with no automatic replay and one explicit retry; delayed current-owner
saved feedback. Original export/copy/service tests and assertions remain unchanged.
Task-relative source inspection confirms no serializer, payload, platform adapter,
import, dependency, shared lifecycle or backend changes. Baseline hashing confirms
unowned repository bytes are unchanged. Scoped local links resolve.

Evidence and source fingerprints are retained in the profile-local
`autogoal/transcript-export-feedback/t_aaa10f17/` receipt directory. These are Linux
host unit/widget checks with synthetic injected saving, not filesystem/dialog,
compiled browser, native desktop, Android, screen-reader, live Agent, full-suite,
full-workflow, full-parity or release qualification; all those remain NOT_CHECKED
for this repair. Earlier native/browser acceptance and blocked cards are unchanged.
