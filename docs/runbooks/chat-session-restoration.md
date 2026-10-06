# Remembered session recovery

Hermes Wing restores the saved gateway/profile/session tuple when reopening Chat
or retrying activation. A session absent from the first inventory page is not
assumed deleted. Wing reads that exact session from Hermes Agent and then uses
its existing canonical history and detached-run reconciliation path. It does not
scan every inventory page, create a fallback session, send a message, or replay
mutations during recovery. With no saved preference, existing explicit-open and
Telegram isolation behavior is unchanged; a valid remembered Telegram session
is restored as itself.

## Authority and gating

These reads go directly to the selected Hermes Agent connection with its current
credential and explicit advertised query profile or enrolled `/p/<id>` scope.
Wing Link credentials and traffic are not involved. Exact off-page admission
requires a present supported capability document and the advertised operations:

- `session`: `GET /api/sessions/{session_id}`.
- `session_messages`: `GET /api/sessions/{session_id}/messages`.

Every scope declared by each operation must be granted. No extra scope is
invented for an authenticated operation declaring none. Metadata must have
`object: hermes.session`, a session object, and the exact requested string ID.
An already-loaded row needs no metadata lookup; history authorization still
applies. Normal unknown-session mutation guards are not relaxed. Existing
bounded transport and latest-page history limits remain in use.

## Pending and failure behavior

Recovery replaces the writable conversation with an accessible status, Retry,
and Choose session. Send, new-session shortcuts, and stale composer callbacks
cannot target an inventory default while the saved identity is unsettled.
Unsupported operations/grants, credential rejection, unavailable resources,
transient errors, and incompatible metadata receive bounded localized messages.
A generic 404 does not prove deletion and does not erase the remembered tuple.
Retry reads the same tuple. Opening or cancelling the existing session picker
does not transfer ownership; actually choosing a session does.

If reconnecting fails before the intended profile is selected, Choose session
and other picker entry points stay unavailable with an explanation to Retry.
The connection's default-profile inventory is not a valid alternative for the
remembered profile. Once that profile has loaded, explicit choice remains
available even if restoring its remembered conversation fails.

Activation suppresses intermediate connect/profile persistence. Metadata and
history admission are fenced by client, connection, profile, session-selection,
and activation ownership. Preference writes retain the existing serialized tail
and check validity again after asynchronous preferences acquisition, immediately
before issuing the write. Issued writes finish before a subsequent clear/new
choice, so a delayed older write cannot finish after and undo that later choice.
Returning to the directory/Disconnect clears startup selection; Remove also
forgets the saved connection locally. Neither action stops the host Agent.

## Deterministic verification

### Uncertain detached-run status

Run-status HTTP 404 is not proof of absence or completion: the Agent also uses
the same response for foreign-owned and ownerless runs. Wing retains the exact
detached-run lease and unresolved Send guard across reconnect, session Retry and
channel recreation. Recovery does not resend the prompt or open a stream based
on that ambiguous response. The existing “still active” message means ownership
is unresolved here; it is not a confirmed running status.

A later exact terminal status plus successful canonical-history read can settle
that retained ownership through the existing recovery path. History visible from
bootstrap alone does not settle it. If status remains unavailable, Send remains
refused for that session; reconnect is a read retry, not guaranteed resolution.
The bounded regression evidence is in the
[ambiguous-404 repair receipt](../quality/2026-10-06-m2-ambiguous-404.md).
History identity is validated at the shared HTTP page boundary before cache,
pagination, model-history or transcript admission and detached-run settlement.
Envelope and every row require nonempty string session identities; malformed,
ownerless or unrelated history fails closed, including empty foreign pages.
Exact-session pages require no extra reads. Compaction ancestors and a resolved
tip require fresh, authorized Agent metadata and bounded one-row history probes:
each parent must have ended `compression` and resolve to the same tip. A parent
pointer alone, cached inventory or response-supplied lineage list is not a grant.
The proof stops after 100 distinct sessions; unavailable metadata, grants,
cycles or divergent resolution refuse that page without partial admission.

A failed bootstrap history read leaves the connection in an error state, with
the durable lease retained and Send refused. Failed earlier-history reads keep
the good transcript and offset, allowing an explicit read retry. Existing
connection/profile/session/caller fences also cover the additional lineage reads.
See the [history-identity receipt](../quality/2026-10-06-m2-history-identity.md).
Shared baseline hydration and earlier-message pagination reject declared history
operations before history I/O unless their schema, exact method/path, all required
grants and declared profile context are supported. Supported legacy documents
omitting the baseline history advertisement still permit ordinary history reads;
strict remembered/off-page restoration and lineage proof still require explicit
advertisement. Denial retains terminal ownership and refuses Send; a later
authorized read can settle it. See the
[history-admission receipt](../quality/2026-10-06-m2-history-admission.md).
These deterministic checks do not qualify live M2 recovery.

Regression files:

- `test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart`:
  real channel/client plus directory, off-page and already-loaded identities,
  explicit profile and synthetic Agent credential authority, canonical history,
  no intermediate default persistence or restoration mutations.
- `test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart`:
  exact operation/schema/grant failure matrix; metadata/history HTTP and timeout
  failures; Retry/foreground activation; valid remembered Telegram; parked
  metadata/history across directory, Remove, disposal, manual selection, another
  profile/host, and identical-ID host reuse.
- `test/features/hermes_chat/gateways/gateway_selection_write_race_test.dart`:
  real SharedPreferences platform acquisition and issued-write gates; final
  stored absence/tuple after invalidation, directory, Remove, and manual choice.
- `test/features/hermes_chat/screens/hermes_chat_session_restoration_test.dart`:
  390px, 200% text and reduced motion, semantics, keyboard Retry/Choose,
  cancellation/explicit ownership, stale Send rejection, and scoped drafts.
- `test/features/hermes_chat/screens/hermes_chat_restoration_draft_race_test.dart`:
  real parked metadata/history cannot replace an explicitly chosen B draft.
- `test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart`:
  actual foreground lifecycle activation failure, retained tuple and no
  intermediate writes, keyboard Retry/Choose, profile-catalog gating and picker
  cancellation at 390px, 200% text and reduced motion.
- `playwright/tests/regression/session-restoration.spec.mjs`: compiled Flutter
  Chromium at 390px/1280px, genuine 50-row page one/10-row page two, UI selection
  of session 050, persisted reload, exact lookup failure/Retry, picker cancel,
  manual choice during pending read, canonical message IDs and stored tuple.
  Each journey attaches fixture readback with zero restoration mutations.

Race assertions use explicit completion gates and response/frame fences, not
sleep-based timing. Existing channel uncertainty/duplicate guards, profile
attachment/approval isolation, endpoint storage, long-conversation windowing,
and session-model picker remain required regressions.

Validation uses installed Flutter/Dart without dependency upgrades:

```sh
/opt/flutter/bin/flutter --no-version-check gen-l10n
/opt/flutter/bin/flutter --no-version-check analyze --no-pub
/opt/flutter/bin/flutter --no-version-check test --no-pub --concurrency=1 \
  test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart \
  test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart \
  test/features/hermes_chat/gateways/gateway_selection_write_race_test.dart \
  test/features/hermes_chat/screens/hermes_chat_session_restoration_test.dart \
  test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart \
  test/features/hermes_chat/screens/hermes_chat_restoration_draft_race_test.dart
/opt/flutter/bin/flutter --no-version-check build web --release --no-pub -t lib/main_e2e.dart
node --check serve_web.mjs
# In a separate terminal, use free loopback ports and stop this server afterward:
PORT=8978 HERMES_E2E_PORT=8979 node serve_web.mjs
# Verify readiness before running the browser suite:
curl --fail http://127.0.0.1:8979/health
PLAYWRIGHT_BROWSERS_PATH=/opt/data/cache/wing-playwright \
  WING_APP_URL=http://127.0.0.1:8978/ HERMES_E2E_PORT=8979 \
  ./node_modules/.bin/playwright test \
  playwright/tests/regression/session-restoration.spec.mjs \
  playwright/tests/regression/hermes-smoke.spec.mjs \
  playwright/tests/regression/chat-window.spec.mjs \
  playwright/tests/regression/session-model-picker.spec.mjs --retries=0 --reporter=list

git diff --check
```

## Qualification limits

The exercised targets are the Linux Flutter widget runner and deterministic
compiled Flutter Chromium, not a deployed Agent or provider. This does not
qualify physical Android/process death/keystore, iOS, native GTK, voice/acoustic
behavior, push, inference, or full Desktop parity. Reference Agent registration
is contract evidence, not proof that every installed host advertises this read.
Unadvertised recovery is explicitly unsupported rather than simulated.
Independent tester and reviewer acceptance is required on the implementation card.
