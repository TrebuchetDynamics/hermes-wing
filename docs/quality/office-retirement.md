# Wing-only Office retirement candidate

Task: `t_1b62d210`; source task: `DOC-OFFICE-ACCESSIBLE-EQUIVALENT`, goal `OFFICE`.
Status: implementation candidate; independent native same-card review and canonical
integration/publication are separate. This is not full Desktop qualification.

## Admission and authority

Clean detached source: `e0fa79b06a61cbf9290637458395e91e22d37db5`.
Accepted authority: [official-only product decision](../adr/product.md#official-desktop-features-only).
The [pinned Office comparison](office-contact-session-reference.md#scope-and-verdict)
finds no Office-named official surface at Agent reference
`158fd638da1629c8e62caf9ade1515d162def8ab`. Bots is not an Office equivalent.
That original comparison and other historical receipts are unchanged.

Before edits, the original frozen `runtime_bundle.py` invoked
`autowork/scripts/pass_workspace.py` with manifest
`pass-cee7833efc00d917-d3bfa09fe3a04a58a92c15c3cdeca38e.json`, SHA-256
`2c730c462b79a9869f50b127058e6737ab80a38fcad9edc9203d27d02e6f1164`, and the
matching isolated workspace. Result: exit 0, `worker_start_admitted`.
Frozen helper bundle SHA-256:
`758654a324ff224f2e0e4d1fedae64aefbd50c7a184e6de98cb4f987fa11a6d7`.
The original run tool history establishes ordering; this receipt alone does not.
Review must inspect an isolated exact finish-commit snapshot, never rerun initial
clean-base admission against implemented files or repin that manifest.

## Connected scope and preservation

- Delete OfficeScreen and its exclusive widget tests/Maestro flow; remove the route,
  constant, shell destinations and Chat local slash entry. There is no replacement
  Office/Bots surface and no new backend, dependency, service or asset.
- Preserve the Connections profile-count plural under `connectionProfileCount`;
  delete other Office localization input and regenerate both localization outputs.
- Reuse the existing Page not found / Return to chat fallback. The retained router
  regression opens the literal obsolete URL without connect, create, select or send,
  checks the original profile/session identity, then explicitly returns to Chat.
- Derive the desktop group split from existing `workflowDestinations.length`, rather
  than the obsolete hard-coded three entries. Regression assertions keep Providers
  under Utilities and Schedules under Workflow in expanded/icon-only mode.
- Adapt shell/slash/router tests, browser journeys, integration aggregators and
  visual-review fixtures. Visual review has 12 routes, 24 light/dark screenshots,
  with dark review starting at step 13. These fixture edits are not device evidence.
- Shared gateway directory/contact/cache/session and core transport/storage logic
  are unchanged. Retained owner fencing, denial, saved credentials/identity, exact
  restoration and no-replay regression targets remain; none is removed to pass tests.
- Current routes, product support and navigation/readiness guidance describe removal.
  The canonical TODO/goal ledger remains pending review; historical evidence is not
  rewritten or upgraded to current support.

Owned paths are the cumulative finish diff: router/constants; shell/presentation;
Chat layout; Connections count caller; ARB/generated localization; Office deletions;
affected router/shell/slash/tooling tests; integration callers; Maestro fixture/runner;
browser surfaces/navigation and their existing keyboard actor; current docs and this
receipt. Core storage, upstream/runtime/copies/forks, services and unrelated
configuration/dependencies are excluded. Canonical dirty endpoint-store work and its
two dirty tests are not included. Exact files/modes/deletions and commit/ref are in
the native finish handoff, not a self-referential commit identifier in this file.

## Checks and recovery evidence

Observed environment: Linux-hosted Flutter 3.44.2, framework `c9a6c48423`, engine
`77e2e94772`, Dart 3.12.2, DevTools 2.57.0; Python 3.12.14; Node v26.7.0 (not the
repository's recommended Node 22); system Chromium 152.0.7977.75.

Unchanged lockfile SHA-256:

- `pubspec.lock`: `f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89`
- `package-lock.json`: `f32c4b4d226bf6cef1a1f66733d4c2e065e0656d1223e89f17ceb68f42429b63`

Executed setup/iteration: `flutter pub get --offline --enforce-lockfile`,
`flutter gen-l10n`, format changed Dart, `flutter analyze --no-pub` (no issues),
and the four-target Office fallback/shell/navigation/slash test command (68 pass).
After the desktop group-split repair, the final gate revalidates the affected union.
`npm ci --ignore-scripts` returned zero vulnerabilities and preserved its lockfile.

Compiled JS-release builds of `lib/main_e2e.dart` passed. Existing flutter_tts Wasm
cast and missing Cupertino font-family dry-run warnings remain; no Wasm support is
claimed. The fixture server is task-owned, loopback-only, with synthetic Agent state.
No personal service, upstream runtime, credential or live-provider access is involved.

Browser recovery found a stale Profiles-as-shell bootstrap after earlier overlay
changes; the navigation oracle now starts at Connections and explicitly opens and
closes Profiles/Settings from retained Chat. Deleting Office also exposed the real
hard-coded shell group split, repaired above. Reindexing alternating keyboard keys
exposed a reverse-focus loop on the unavailable Providers surface; retained entries
keep their original pre-removal directions. That extra reverse Providers journey is
not qualified here and needs coordinator follow-up, not an invented passing result.
The retained Chat overlay adds enough controls to exceed the actor's old 32-key
search bound; the existing bounded actor now allows 64, without dropping focus,
viewport, pixel-change, route, owner or mutation assertions. One final grouping,
expanded/icon-only and 390px More keyboard journey passed in 54.1s before the gate.

Final acceptance is executed by the frozen `finish_task.py` gate. Exact argv,
exit codes, union counts, browser results and finish SHA/ref are recorded in the
same-card native handoff. The union covers router/shared widgets, directory/cache/
restoration, Connections, core session ownership/storage/authorization, slash denial,
and changed tooling/integration fixture contracts. Gate checks also include l10n,
format, analyze, deterministic E2E build, both affected Playwright specs, scoped
closure/lockfile checks and `git diff --check`. A gate failure is not acceptance.

## Acceptance mapping and limits

| Criterion | Oracle |
| --- | --- |
| No Office-only route/navigation/runtime | No Office reference under lib; exclusive files absent; source closure check |
| Obsolete URL cannot activate or mutate | Actual-router fallback test and compiled browser recovery with unchanged owner and zero mutations |
| Retained navigation is keyboard operable | Shell group/scroll/200% widget tests plus compiled navigation, overlay Close and compact More recovery |
| Shared owner/session/security behavior retained | Unchanged shared-source diff and directory/restoration/channel/storage/authorization regression union |
| Localization/fixtures/delivery consumers closed | Regenerated outputs, analyze, integration aggregate imports and visual-review sequence check; compiled E2E target |
| Owned local commit and independent review | Exact frozen finish receipt and native same-card review request; not self-approval |

Implemented: coherent offline retirement only. Qualified: named fake-channel
unit/widget and deterministic compiled Chromium journeys on Linux, bounded by
actual gate results. Delivered: local task ref at successful finish, not canonical
main, remote publication, deployment or installation. Independent review remains
pending. Native Linux GTK, physical Android/iOS, screen readers, real secure storage,
live Agent/provider, package installation and full Desktop parity are NOT_CHECKED.
Production/native packaging was not exercised; no Office-exclusive asset/export or
dependency was found in the source/manifests. Readiness and legacy historical receipts
are not runtime qualification.

Ponytail full: delete the unsupported feature; reuse the not-found recovery,
presentation grouping, plural localization and existing test/fixture seams. Verified
`ponytail:ponytail` guidance was loaded from the installed plugin. No speculative
Bots UI, abstractions, new dependencies, backend state or optional methods were added.
Suggested next canonical task remains `DOC-PERSONA-CONFLICT-EVIDENCE`, subject to
coordinator readiness/ownership; this worker does not dispatch it. Costs and
independent-review duration are unknown, not estimated from passing test counts.
