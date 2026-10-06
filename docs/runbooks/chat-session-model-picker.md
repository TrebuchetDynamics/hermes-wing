# Searchable Chat session-model picker

## User flow

On a connected Chat session whose Agent advertises exact `model_options` read
and `session_model_lock` write operations with the required grants, choose the
composer's model control. It is available in both wide and compact idle layouts.
This opens the existing **Use a model for this session** sheet, not Providers.

- Search existing model IDs, provider display labels or provider slugs without
  regard to case. Search input is limited to 200 characters.
- Use **Provider** to filter one provider or **All selectable providers**.
  **Clear model search** retains the filter; **Reset filters** clears both.
- The authoritative current provider/model appears first when it matches the
  filter. Reopening uses the confirmed active-session lock rather than the
  catalog default. Without a confirmed lock, catalog default/fallback selection
  applies. An unavailable locked identity cannot be confirmed until an eligible
  row is explicitly selected. Other rows retain catalog order. Duplicate model IDs show provider
  label and slug to distinguish their raw identities.
- Select a row, then explicitly choose **Use for session**. Filtering never
  changes the draft model. The **Selected** summary remains explicit even when
  search or a provider filter hides that row.
- No results and empty selectable catalogs have distinct states. No custom
  model/provider or base URL entry is offered.
- Confirmation disables competing controls and dismissal. Rejection keeps the
  raw identity, query and filter with a generic error; choosing **Use for
  session** again is an explicit retry. Cancel or Escape before confirmation
  performs no mutation. Search receives initial focus only on wider layouts;
  narrow layouts do not unnecessarily summon a software keyboard.

Only `HermesModelOptions.selectableProviders` supplies rows: authenticated,
current, user-defined and reviewed user-config/custom sources, with nonempty
model lists. Visibility in a catalog is not authorization. Model reads, search
and filtering perform no provider probing, inference, restart or profile write.
Locks use the existing direct Agent channel, not Wing Link.

The caller invalidates a picker after inventory replacement, connection,
capability, profile transition, session switch or active generation changes,
including changes that return to the original identity. It checks again after
confirmation so a late completion cannot close a stale picker as saved. Reopen
from the current Chat context after such a change; no mutation is replayed.

## Session catalog loading

The composer admits one model-picker opening per Chat screen, from catalog read
through sheet dismissal. Repeated activation while that opening is pending is
ignored in both the session-only and legacy branches: it does not start another
read, stack sheets or queue duplicate load feedback. Cancel closes the only sheet
without writing a model. Dismissal, read failure or suppressed obsolete completion
releases the opening guard so a fresh explicit opening works. An owner change does
not cancel an issued read or release its guard early; wait for it to settle before
opening from the new context.

Before the session-only sheet opens, its catalog load is fenced to the initiating
Chat context. A profile change, profile roundtrip, session switch or connection
transition invalidates that opening. An obsolete success or failure opens no
sheet and shows no load snackbar, even when the original identity returns.
Current-owner failures retain the generic load feedback. Open the composer model
control again explicitly to use the current context; issued reads are not
cancelled and model writes are not replayed.

`hermes_chat_session_picker_load_owner_test.dart` exercises the real Chat screen
and public composer control with deterministic delayed success/failure for those
transitions, current-owner success/error, fresh explicit reopening and unmount.
Every load-only case asserts zero session-lock and profile-assignment writes.
The existing profile-roundtrip screen regression now expects silent suppression,
not a stale load snackbar. This is Linux widget-runner evidence only, not native
desktop, browser, live-provider, packaged or integrated parity qualification.

## Legacy inventory loading

When only the exact legacy `models` read and `models_assignment` write are
advertised, the composer continues to open the existing profile model-assignment
sheet. Its delayed inventory read is fenced to the initiating Chat context.
Profile/connection/capability changes, profile selection, session changes and
unsettled restoration invalidate admission, even if the original identity returns.
A stale completion neither opens a replacement owner's sheet nor reports a load
error there. A fresh explicit opening still works; current-owner read errors keep
the existing generic feedback. This does not add session-lock support or replay
any mutation.

`hermes_chat_model_inventory_owner_test.dart` mounts real Chat with the production
API channel and directory over deterministic reads. It exercises delayed success
and failure across profile replacement, profile roundtrip and same-owner reconnect,
plus same-owner success/error controls. This is widget evidence, not native,
browser, live-provider or packaged qualification.

## Evidence scope and reproduction

`hermes_chat_model_picker_open_order_test.dart` exercises repeated public composer
activation during delayed success/failure in both branches, exactly one admitted
read, no offstage sheet after Cancel, no queued duplicate load snackbar, explicit
failure retry and ordinary reopening, with zero lock/assignment writes. It also
checks capability revoke/restore during pending success/failure and fresh reopening.
These are deterministic Linux Flutter widget tests, not native/browser/live evidence.

The widget runner exercises a 303-row selectable synthetic catalog, duplicate
IDs, excluded unconfigured provider, combined filters, authoritative success and
redacted failure/retry, stale inventory, owner changes, pending/disposed widgets,
keyboard traversal, selected semantics, reduced motion and a 390px viewport with
300px keyboard inset and 200% text scaling.

The deterministic Chromium journeys open the production picker through full
Chat, search/filter/select, reject the first confirmation and accept an explicit
retry at 390px and 1280px. They read the synthetic fixture's selected session
runtime back, reopen with that identity first, and confirm unchanged to verify
exactly three mutation attempts with the same raw pair. Fixture setup and receipt
routes exist only in `serve_web.mjs`; production API contracts are unchanged.

```sh
flutter gen-l10n
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 \
  test/features/hermes_chat/widgets/session_model_picker_sheet_test.dart \
  test/features/hermes_chat/widgets/session_model_picker_search_test.dart \
  test/features/hermes_chat/screens/hermes_chat_session_picker_test.dart \
  test/features/hermes_chat/screens/hermes_chat_session_picker_load_owner_test.dart \
  test/features/hermes_chat/screens/hermes_chat_model_picker_open_order_test.dart \
  test/core/hermes/channel/hermes_api_channel_test.dart
flutter build web --release --no-pub -t lib/main_e2e.dart
PORT=20867 HERMES_E2E_PORT=20868 node serve_web.mjs
# In another terminal, after HTTP readiness:
PLAYWRIGHT_BROWSERS_PATH=/opt/data/cache/wing-playwright \
WING_APP_URL=http://127.0.0.1:20867/ HERMES_E2E_PORT=20868 \
  ./node_modules/.bin/playwright test \
  playwright/tests/regression/session-model-picker.spec.mjs --retries=0
```

Use free loopback fixture ports; do not stop an existing listener. The browser
cache path above is this development container's existing project-lock cache.
Actual available toolchain: Flutter 3.47.5 / Dart 3.13.4, not intended 3.44.2;
no dependencies or lockfiles were upgraded. JavaScript web builds emit existing
Wasm dry-run and optional Cupertino font warnings. This is not real provider
inference, Android hardware/native Linux, software keyboard hardware, signed
release, full provider administration or full upstream parity qualification.

UI provenance: upstream Desktop `ModelPicker.tsx` at
`2ed89070bc6c9e8231a37bb55df8a7722a3776b8`. Flutter equivalents preserve its
search, provider filtering, stable current-first order, reset and keyboard
outcomes; they do not port Electron events or base-URL input. Agent source
`gateway/platforms/api_server.py`'s `_handle_session_model_lock` and nearest
`tests/gateway/test_session_api.py` confirm existing session-lock ownership.
These reference checkouts were inspected, not modified or executed as new
runtime qualification.
