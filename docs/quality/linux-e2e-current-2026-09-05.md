# Native Linux E2E and screenshot review — 5 September 2026

A snapshot of the shared worktree was exercised with Flutter 3.44.2's native Linux
integration-test runner under Xvfb. The live tests use real Hermes Agent, a Wing
Link binary built from this checkout, acknowledged pairing credentials, an
isolated GNOME keyring, and the serving OmniRoute provider. Only provider
configuration was copied into the private test Agent home; production sessions,
profiles, schedules, and messaging integrations were not used as test state.

## Screenshot gallery

- [Open the filterable gallery](../../test-results/linux-e2e-current-2026-09-05-verified/index.html).
- [Download all original screenshots](../../test-results/linux-e2e-current-2026-09-05-verified/linux-ui-review.zip).
- [Machine-readable state manifest](../../test-results/linux-e2e-current-2026-09-05-verified/manifest.json).

There are **83 captures across all 14 production routes**: 18 light and 18 dark
route/scroll views, plus 47 feature-state captures. All PNGs passed integrity
verification and decoded in Chromium; gallery filtering returned the five
computer-setup states. Captures span 18:24–18:27 America/Monterrey on September 5
(00:24–00:27 UTC September 6). Other active work changed UI files afterward; these
captures do not claim to show those later edits. Screenshots remain ignored local
artifacts.

| Area | Captures | Runtime evidence and boundary |
| --- | ---: | --- |
| Chat | 16 | Real provider reply, draft/send, model and emoji menus, session dialogs/search, disconnect/reconnect. Separate live tests exercise session CRUD/fork and run steer/stop. |
| Profiles | 16 | Real catalog/autocomplete, OmniRoute detection, create, rename, typed deletion guards, approved backend cleanup, directory browser state. |
| Providers | 2 | Current capability-gated administration state; no unsupported provider write claimed. |
| Tools | 6 | Real skill/toolset inventory, scrolling, filtering and empty-result recovery. |
| Schedules | 2 | Current unavailable mutation state. |
| Office | 2 | Current accessible workspace presentation. |
| Persona | 2 | Current profile/capability-gated state. |
| Gateway | 7 | Real health refresh, trust details, revocation confirmation cancelled. |
| Settings | 7 | Theme, palette, gateway actions and removal confirmation cancelled. |
| Voice settings | 6 | Preference toggles, advanced options, language and command menus; no audio qualification. |
| Diagnostics | 2 | Current bounded diagnostics presentation. |
| Enrollment | 9 | Chooser/pairing entry and all three computer tutorial steps, existing-host option, back/forward navigation. |
| Manual connection | 4 | Form and lower controls; credential values cleared before capture. |
| Local setup | 2 | Current Linux setup presentation; no service installation invoked by this tour. |

The tutorial captures were added to the reusable visual test. Its steps are
asserted through hit-testable UI controls; progressing through instructions is
not treated as proof that host installation ran.

## Results

- `bash scripts/run_linux_live_visual.sh`: **passed**, 3 minutes, wrapper exit 0.
- `bash scripts/run_linux_live_e2e.sh`: **four live flows passed** — actual provider
  reply, session lifecycle/inventory/reconciliation, run steer/stop, and Wing Link
  catalog/discovery/profile lifecycle.
- `xvfb-run -a flutter test -d linux integration_test/linux_feature_regression_test.dart --reporter expanded`:
  **1,025 cases exercised in 6m48s: 1,021 passed, four failed**. The runner imports
  all 88 current test files under app, features, routing, and shared UI.
- A focused native rerun of all four failures passed three after driver repairs:
  Office now asserts the actual app shell instead of obsolete uppercase branding;
  Settings scrolls the requested control instead of ambiguously selecting among
  multiple scrollables; the large-text voice test waits for scrolling to settle
  and asserts the control is hit-testable before tapping.
- The native **profile catalog Retry remains failing**: after Retry, the expected
  `alpha` autocomplete option is absent. This reproduces the earlier native-only
  finding. No assertion was skipped or weakened. The full suite is not green;
  the full-run and focused-rerun results are separate receipts.
- `bash scripts/run_linux_secure_storage_regression.sh`: **passed**, write and
  verify phases in two separate native app processes, wrapper exit 0.
- `flutter analyze`: **no issues**.
- `flutter test test/router/office_route_test.dart test/router/settings_routes_test.dart test/features/settings/settings_screen_test.dart test/features/profiles/profile_catalog_test.dart`:
  **17 passed** on the latest files. An initial run overlapped another session's
  Settings changes and failed its obsolete voice-toggle expectation; that
  session's updated assertion passed on rerun. Catalog Retry passes here in the
  widget runner but remains failing in the native runner.
- Changed Dart formatting, documentation links and `git diff --check`: passed.

The visual script received private manifests through `WING_LIVE_PROFILE_MANIFEST`
and `WING_LIVE_LINK_MANIFEST`, with the matching `WING_LIVE_LINK_BINARY` and
`WING_LINK_STATE`. Linux build dependencies were selected through
`PKG_CONFIG_PATH`, `CPATH`, `LIBRARY_PATH`, and `LD_LIBRARY_PATH`. Credentials were
never passed as CLI arguments, written into source, or captured in screenshots.

The first visual attempt failed before session creation because the isolated
Agent received SIGTERM. Restarting it with the same credentials allowed the
complete rerun to pass, including the same profile cleanup operations. The
termination source was not established; no application fix is claimed for it.
Its partial screenshots and log remain separate from the verified gallery.
After live checks, only the isolated default profile remained. Both test services
were stopped; private Agent state, credentials, and local pairing proof were
removed. The pre-existing OmniRoute service remained active.

## UI findings from the current captures

- Chat repeats model/readiness labels in its header and composer. The profile
  card shows a configured model while Chat uses a generic model label; clarify
  the identities using authoritative state.
- The session rail reports zero messages beside a conversation whose header and
  transcript show two. This needs a reconciliation investigation, not a visual
  hardcoded count.
- Profile cards stack several closely related status labels. A shorter hierarchy
  would improve scanning without hiding connection or enrollment state.
- Settings puts diagnostics partly below the initial viewport despite substantial
  space elsewhere. Review section sizing and vertical priorities.
- Sparse inventory and unsupported screens consume much of the desktop area.
  Prefer clear next actions where the runtime actually provides them.

These are review findings, not production changes made by this testing pass.

## Qualification limits

The live tour is not a claim that every possible feature can succeed on this
Agent. Unsupported provider/schedule/persona administration is captured as
unsupported. Fresh OmniRoute credential provisioning, OS file selection and
artifact transfer, browser control, real approval-triggering tool execution,
service installation/update/rollback, camera scanning, physical display/input,
microphone recognition and sound output were not qualified by this run.
The broader native regression suite uses deterministic service seams and is
reported separately from real-service E2E evidence.
