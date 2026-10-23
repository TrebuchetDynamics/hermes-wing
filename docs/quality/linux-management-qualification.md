# Linux management fixture qualification

## Scope

The management lane of the [Linux campaign](../plans/2026-10-21-linux-feature-qualification.md)
exercises the [GTK target](../../integration_test/linux_management_feature_qualification_test.dart)
with an [inert HTTP fixture](../../integration_test/support/linux_management_feature_fixture.dart)
below the production API client/channel, management directory, editors and router.
There is no Agent process, socket, provider account, inference, OAuth browser,
installer or schedule mutation. Advertised operations are synthetic Wing contracts,
not a claim that a deployed Agent provides them. No production behavior changes.

Input is framework taps and mocked text input, not OS or physical keyboard input.
Preferences, endpoint storage and diagnostic clipboard are mocked. Voice controls
only change local preferences; capture, playback and acoustics are not exercised.
Linux's missing native spellcheck service is asserted unavailable, not overridden.

## Run and receipt

Resolve the [driver prerequisites](linux-qualification-driver.md#inspection), then:

```sh
python3 scripts/run_linux_feature_qualification.py --lane management \
  --output-dir "$TMPDIR/linux-qualification"
```

Use fresh private output for changed source/tool/dependency inputs. The existing
driver owns capture, environment isolation, GTK process observation and cleanup;
this lane does not patch its registration or relax validation.

The target requires the driver's marked `WING_LINUX_TEST_ROOT` directly under
TMPDIR and exact HOME/XDG identities. After all journeys succeed it atomically
renames `feature-cases.json.partial` to `feature-cases.json`, then retains its GTK
process for a one-second observation window. Schema-1 rows contain case/family/route
identities, backend/input/storage classifications, native PID, owner and operation
counts. Receipts contain no bodies, credentials or endpoint origins.

The **33 unique rows** comprise 12 passing offered-subset/recovery/denial/alias
assertions and 21 unsupported negative assertions. Counts include journey bootstrap
requests; owner counts denote deliberate action-owner incarnations after bootstrap.
Absent-route rows instead count zero route-opening requests and zero writes.
An unsupported row is never positive parity evidence.

## Case, route and action join

IDs below have the `management.` prefix. Each row is a bounded journey, not a
claim that the whole Desktop family or every platform is qualified.

| Case | Composed route(s) | Public actions and observable contract | Family |
| --- | --- | --- | --- |
| `persona-revision-recovery` | `/soul`, `/profiles` | Save failure retains draft; HTTP 412 loads authoritative revision; explicit retry sends `s2` after two `s1` attempts; stale conflict cannot initiate recovery reads | HD-PROFILE |
| `profiles-lifecycle-owner` | `/profiles` | Local Search/Clear; New Profile/Create with exact clone; Edit/Save and Delete confirmation with exact IDs/revisions; obsolete editor cannot submit and pending completion cannot alter new owner | HD-PROFILE |
| `provider-secret-recovery` | `/providers` | Local Search/Clear; empty obscured Manage credential input; Set failure/explicit retry with exact synthetic profile/env-var/body; hostile raw response secret ignored; separate Validate/redacted detail and Remove | HD-PROVIDER |
| `provider-stale-owner` | `/providers` | Stale sheet Set makes no request; admitted old-owner Set cannot update replacement inventory or dismiss its sheet | HD-PROVIDER |
| `model-explicit-assignment` | `/providers` | Choose model; local preset save/apply/delete; Refresh catalog; revisioned main Assign failure/retry and auxiliary Vision assignment preserving main selection | HD-MODEL |
| `read-only-inventory-recovery` | `/tools`, `/tasks` | Independent Search/Clear, toolset disclosure, refresh failure/recovery; Enabled/Disabled filters, Search/Clear filters, failed refresh/Retry; exact scoped GETs and zero writes | HD-SKILLS, HD-SCHEDULE |
| `connections-health-recovery` | `/gateway` | Detailed health Refresh/failure/Retry; exact unscoped GETs, unchanged Chat tuple and zero writes | HD-GATEWAY |
| `authority-missing`, `authority-denied`, `authority-read-only` | `/profiles`, `/soul`, `/providers`, `/tools`, `/tasks`, `/gateway` | Nine channel mutations reject before dispatch; missing/denied optional reads make no requests; read-only provider/model inventory cannot expose mutation controls | HD-PROFILE, HD-PROVIDER, HD-MODEL, HD-SKILLS, HD-SCHEDULE, HD-GATEWAY (authority denial only) |
| `settings-diagnostics` | `/settings`, `/settings/voice`, `/settings/diagnostics`, `/gateway` | Theme mode/palette, transcript scale/avatar, Connections/Voice/Diagnostics links; three persisted voice switches, language, nonblank command word; Copy failure/Retry with redacted bounded hostile metadata; zero Agent writes | HD-SETTINGS, HD-DIAG |
| `legacy-agents-alias` | `/agents` → `/profiles` | Actual compatibility redirect, not another administration destination | HD-PROFILE |
| `unavailable-administration` | `/profiles`, `/providers`, `/tools`, `/tasks`, `/gateway` | Missing Project/OAuth/MCP/job/plugin/lifecycle actions remain absent; OAuth provider explains host sign-in and has no API-key form | HD-OAUTH, HD-PROJECT, HD-MCP, HD-SCHEDULE, HD-GATEWAY, HD-PLUGINS (unsupported subsets) |

Each `absent-HD-*` case opens the negative destination below, asserts **Page not
found**, activates **Return to chat**, and verifies zero opening requests/writes.
These deliberately uncomposed URLs test generic recovery, not hypothetical feature
URLs or the absence of every possible overlay. Partial-route controls are checked
separately above.

| Family | Negative destination |
| --- | --- |
| HD-OAUTH | `/oauth` |
| HD-PROJECT | `/projects` |
| HD-MCP | `/mcp` |
| HD-MEMORY | `/memory` |
| HD-KANBAN | `/kanban` |
| HD-ARTIFACTS | `/artifacts` |
| HD-PREVIEW | `/preview` |
| HD-TERMINAL | `/terminal` |
| HD-CLOUD | `/cloud` |
| HD-ACCOUNT | `/account` |
| HD-IMPORT | `/import` |
| HD-STARMAP | `/starmap` |
| HD-GUIDE | `/guide` |
| HD-PLUGINS | `/plugins` |
| HD-RADIO | `/radio` |
| HD-VAULT | `/vault` |
| HD-PLUGIN-PACKAGES | `/packages` |
| HD-SCREEN | `/screen` |
| HD-PETS | `/pets` |
| HD-SKILLS (discovery subset) | `/discover` |

This lane accounts for 27 of the [50 inventory families](../product/hermes-desktop-feature-matrix.json).
Connections/Chat/access lanes own the other 23 and remaining composed routes/actions,
including enrollment, local setup, Add Hermes, Chat/session and platform controls.
The final report/checker owns the complete family and [actual route/action](../product/routes.md)
union. The pinned matrix is unchanged; neither a family count nor a negative route
check establishes positive Desktop parity.

## Observations and remaining gates

The required management campaign passed on the recovered candidate based on
`3012482c42a027fa1daaf75e9e0cfc672ea31fdb`, reusing the three-file qualification
candidate `34ab767e1cfc2e9390989f15b03dba7794e67b82`. Readiness was `true` with no
preflight errors. The driver dispatched the registered management GTK target and
recorded its terminal exit **0**: all **12 journeys** passed, with **33 unique
schema-1 rows** (12 passing assertions and 21 unsupported negative assertions).

The exercised target was Linux x86_64 GTK under owned Xvfb/D-Bus, using Flutter
3.44.2, Dart 3.12.2 and Node 22.22.2. `campaign.json` pins the complete current
source input map and tool/package/native-dependency fingerprints; `management.json`
retains the command, log/case digests and observed live GTK process identities.
All owned process groups exited and isolated HOME/XDG/build state was removed.
Private receipts and logs stay outside Git; the worker report identifies them and
binds their input hashes to the final task commit. Analysis, formatting and scoped
document readback checks are recorded separately.

Earlier pre-dispatch native-only-package refusals and standalone GTK results are
historical, not relabeled passing receipts. This recovery used the current shared
validator and provisioned locked dependencies/native prefix; it changed neither
shared driver policy nor package contents to manufacture readiness. The passing
management lane does not certify the other campaign lanes, the integrated full
suite or the final 50-family/action union. Partial/failed runs cannot publish a
complete case inventory.

Actual Agent revision conflict/provider custody, live authentication/OAuth,
physical audio, Wayland/IME, screen readers and packaged installation/upgrade remain
NOT_CHECKED. Reuse the campaign's existing gates, including
`VERIFY-PERSONA-LIVE-COMPATIBILITY` and `PARITY-NATIVE-LINUX-LIVE`. Overall Linux
qualification and PARITY remain partial/unverified; fixtures do not waive those gates.
