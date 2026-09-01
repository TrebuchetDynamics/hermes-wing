# Settings Information Architecture — Design

**Date:** 2026-07-17
**Status:** Implemented

## Goal

Make Settings short enough to scan on a phone while keeping gateway management and the two everyday voice controls immediately available. Move operational detail into focused pages instead of hiding capabilities or placing every control in one scroll view.

## Decisions

| Decision            | Choice                                                                                    |
| ------------------- | ----------------------------------------------------------------------------------------- |
| Structure           | Short overview plus dedicated **Voice & speech** and **Diagnostics** pages                |
| Overview priorities | Saved gateways, connection management, Continuous voice, Speak replies                    |
| Advanced controls   | Progressive disclosure inside the Voice & speech page                                     |
| Appearance section  | Remove it; it currently describes the UI but provides no setting                          |
| Debug controls      | Show only in builds where their existing feature flag is enabled                          |
| Navigation          | `/settings`, `/settings/voice`, and `/settings/diagnostics` inside the existing app shell |

## Settings overview

The `/settings` screen contains three compact sections.

### Gateways

- Show every saved Hermes gateway with label, endpoint, and text-plus-icon availability.
- Keep each gateway's existing rename, reconnect, and remove menu.
- Keep **Connect another gateway** visible.
- Keep the credential-storage explanation, but render it as supporting text rather than a full status row.
- Remove the separate Hermes Agent status dashboard and **Open Hermes** action. Connection internals belong in Diagnostics, while Chat is already available from primary navigation.

### Quick voice controls

- Show **Continuous voice** and **Speak assistant replies** as full-width switch rows.
- Add one **Voice & speech** navigation row with a short summary of the selected speech model and whether its voice pack is installed.
- The switches use the existing `wingVoiceSettingsProvider`; the overview does not introduce duplicate state.

### Diagnostics

- Show one **Diagnostics** navigation row with the current connection status as its subtitle.
- Optional-resource failures may use a warning icon and a bounded summary, never raw server errors.

## Voice & speech page

The `/settings/voice` page owns controls that are changed occasionally:

1. Continuous voice and Speak assistant replies switches, repeated for context and backed by the same provider state as the overview.
2. Pocket Speech model selection.
3. Voice-pack download, update, progress, and removal.
4. Use Pocket Speech for replies.
5. Installed voice selection, reply speed, and voice preview.
6. An **Advanced** expansion containing the command word control.

Use existing Material controls and existing async behavior. Keep destructive voice-pack and model removal confirmations. Download and preview actions retain progress, disabled, success, and recoverable error states.

## Diagnostics page

The `/settings/diagnostics` page groups read-only operational information:

- **Connection:** status, model, run transport, version, and health.
- **Inventory:** model, skill, toolset, and job counts plus bounded warning labels.
- **Sessions:** session count and whether one is active.
- **Export:** the existing **Copy diagnostics** action and its explicit secret-exclusion explanation.

Diagnostics must continue to exclude credentials, raw logs, transcripts, private paths, and raw optional-resource errors.

## Navigation and responsive behavior

- Add `AppRoutes.settingsVoice` and `AppRoutes.settingsDiagnostics` as child locations under the existing settings path.
- Register both routes inside the existing `ShellRoute`, preserving Settings as the selected primary destination through the current path-prefix logic.
- Detail pages use a standard back action and restore the overview's scroll position when returning.
- Use one vertical scroll region per page, Material touch targets of at least 48 dp, text labels for icon actions, and layouts that tolerate system text scaling.
- Tablet and desktop keep the same information architecture; content may receive a readable maximum width but does not gain a separate settings navigation system.

## State and data flow

No domain state moves and no new persistence is introduced.

- Gateway rows continue to observe `hermesGatewayDirectoryProvider` and invoke its existing rename, reconnect, remove, and enrollment paths.
- Voice controls continue to read and write `wingVoiceSettingsProvider`.
- Diagnostics continues to derive its snapshot from `hermesChannelProvider` and `hermesDiagnosticsExport`.
- Pocket Speech download services remain unchanged; only their presentation moves to the Voice & speech page.

## Error handling

- Gateway and download failures keep their existing actionable snackbar messages.
- In-progress actions remain disabled and expose progress indicators.
- Destructive actions retain confirmation dialogs.
- Diagnostics shows safe category-level warnings instead of raw exceptions.
- A failed detail-page action leaves the user on that page with current settings preserved.

## Testing

- Overview widget test: gateway management, Connect another gateway, both quick voice switches, and both detail links are visible; removed status/Appearance sections are absent.
- Routing test: `/settings/voice` and `/settings/diagnostics` render under the shell, keep Settings selected, and support Back.
- Voice page tests: existing Pocket Speech, preview, and command-word tests move with the controls and retain their behavioral assertions.
- Diagnostics page tests: safe warning rendering and bounded clipboard export remain covered.
- Responsive checks: small phone and tablet widths, large text, no horizontal overflow, and reachable 48 dp touch targets.

## Out of scope

- Settings search.
- A third navigation rail, tab bar, or nested category drawer.
- New appearance/theme preferences.
- New gateway-detail screens or changes to enrollment/storage.
- Changes to voice, diagnostics, or gateway business logic.
