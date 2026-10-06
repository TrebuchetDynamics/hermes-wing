# Desktop continuation — focused restoration verification

Occurrence: 2026-10-03 21:28 local. Bounded single-owner verification; no implementation changes.

## Ownership and scope

Current goal checkpoint and latest [wave receipt](2026-10-03-desktop-daily-workflow-wave.md) explicitly release producer/reviewer scopes. Primary session release message corroborated this. Native delegation and terminal tools returned no live handles; process census showed no Flutter/Dart/Xvfb execution before this run. Claimed only the [goal execution ledger](../plans/2026-10-03-desktop-port-goal.md) and this receipt, with scratch logs under the wing profile. No workers spawned.

## Executed evidence

Toolchain: Flutter 3.44.2, framework c9a6c48423, Dart 3.12.2; Linux host. SDK reports user-branch/unknown source. Target: deterministic Flutter test runner, not a native application or browser.

```sh
flutter test --no-pub --concurrency=1 --reporter=json \
  test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart \
  test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart \
  test/features/hermes_chat/gateways/gateway_selection_write_race_test.dart
```

Exit 0; parsed JSON non-hidden test completions: **49 passed, 0 failed, 0 skipped**; final event `success: true`. Command ran 03:29:59–03:30:03 UTC on October 4 (October 3 local). Assertions cover exact remembered off-page session/profile and canonical history with zero mutations; unsupported operation/schema/grants, 401/403/404/503, timeout and incompatible metadata; late metadata/history against owner changes; delayed preference-write fencing. Production seam: `HermesGatewayDirectory` with `HermesApiChannel` and injected deterministic API transport. These are existing regressions, not new behavior or independently accepted runtime evidence.

SHA-256 comparison of existing Dart files under `lib`, `test`, and `integration_test` before/after all commands returned unchanged. No full suite repeated, no format/analyze required for unchanged Dart sources.

Logs: `/home/xel/.hermes/profiles/wing/cache/scratch/desktop-cron-2128-restoration/`:
- `restoration.log`: JSON test events.
- `sdk.log`: exact SDK output; command exit 0.
- `job-list.log`: `hermes cron list`, exit 0.
- `results.json`: command timestamps/exits and unchanged-source check.

## Blockers and scheduler observation

Fresh read-only `pkg-config --exists` results: GTK exit 0; libsecret-1, gstreamer-1.0, gstreamer-app-1.0 and gstreamer-audio-1.0 each exit 1. Xvfb is available. No native launcher retried and no installation attempted. Native execution still requires owner-approved provisioning. Live inference still requires approved isolated target and supported private auth; no credential inspection or runtime mutation attempted.

Scheduler readback lists actual job `6f218a559ed2` active, this execution `59b8f71ba4a747e382cc08136c214a52` running, next scheduled time 21:38:30 local. It also reports a catch-up dispatch for the missed 20:56 fire at 21:28 (32m late), contrary to the goal's skip-missed-ticks policy. This worker performed only this one bounded occurrence; it did not backfill, retry or change scheduler configuration. That scheduler-level mismatch requires owner attention, not an unapproved job edit. Scheduling is not evidence of continuous uptime.

## Close and next checkpoint

Focused recovery gate passed; lease released in the goal ledger. Next dependency-ready scope: exclusively claim a fresh compiled wide/compact browser workflow/reload gate from daily-workflow step 4, with bounded process lifetime and exact artifact/fixture evidence. Do not repeat this unchanged focused gate or full suites merely to fill a tick. Native and actual provider qualification remain separate blocked gates. No cards, roadmap, upstream references, personal runtime, packages, commits or release state changed.

Receipt/ledger whitespace and local-link validation are recorded in the goal ledger. Run summary: not_available — host accounting not exposed.
