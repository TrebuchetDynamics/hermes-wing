# Hermes Desktop UI Gap Audit

Source reference: `https://github.com/fathah/hermes-desktop`, inspected from `/tmp/hermes-desktop/src/renderer/src/screens/Layout/Layout.tsx`, `/tmp/hermes-desktop/src/renderer/src/screens/Chat/*`, and `/tmp/hermes-desktop/previews/*.png`.

Current Hermes Wing evidence:

- `playwright/screenshots/hermes-connected-desktop-scaffold.png`
- `playwright/screenshots/hermes-connected-mobile-scaffold.png`
- `playwright/screenshots/hermes-connect.png`
- `playwright/screenshots/settings.png`
- `playwright/screenshots/hermes-active-session-bar.png`

## Design target

Hermes Wing is inspired by Hermes Desktop and adapted for Flutter. Pursue capability parity and preserve Hermes One structure, hierarchy, status language, and product identity without translating Electron implementation details. Keep Telegram chat ergonomics on phones: a fast bottom composer, right-aligned user bubbles, low chrome, large touch targets, and simple session controls.

## What is now close after the first scaffold slice

| Hermes Desktop aspect | Hermes Wing current state | Status |
| --- | --- | --- |
| Chat-first main route | `/hermes` is primary and routes directly into Hermes sessions. | Close |
| Persistent desktop session list | Desktop/tablet widths now show a 320px session rail next to the chat pane. | Close structurally |
| Mobile chat priority | Mobile keeps a single-pane chat with bottom composer and bottom nav. | Intentionally Telegram-like |
| Empty chat hero | Empty sessions now show a centered Hermes mark, title, subtitle, and prompt chips. | Close structurally |
| Composer action affordances | Composer now has model, voice, ready/stop, retry, and diagnostics chips above the Telegram-like text row. | Close structurally |
| Capability inventory placement | Capability chip wall moved out of the main chat surface into Diagnostics. | Better than before |

## Current gap audit after implemented desktop-parity slices

### 1. Visual identity and dark product shell

**Desktop:** dark, high-contrast shell; strong Hermes One logo; selected nav rows on dark cards; muted borders; polished black/blue surfaces.

**Hermes Wing:** desktop/tablet now use Hermes Dark with near-black surfaces, blue selected states, dark cards/chips, and a stronger `HERMES ONE` treatment. Mobile keeps the simpler Telegram-like flow.

**Remaining gap:** fine-grain Desktop polish: tighter hover/pressed states, more deliberate dividers, and richer desktop density tuning. The major dark-shell mismatch is now closed.

### 2. Desktop shell/sidebar branding

**Desktop:** left shell has large `HERMES ONE` branding, pinned navigation, recent sessions, footer profile, collapse control.

**Hermes Wing:** desktop/tablet now have a branded `HERMES ONE` shell and persistent session rail. The app rail is intentionally minimal: Hermes + Settings.

**Remaining gap:** footer/profile/collapse affordances and the approved parity navigation. On phones, adapt Office, Kanban, and Discover to task-focused navigation rather than copying the desktop rail.

### 3. Composer shape and density

**Desktop:** one large rounded command bar contains multiline text, attachments, mic, model picker, reasoning/auto mode, fast/action chip, folder/context, web toggle, and send.

**Hermes Wing:** desktop/tablet now use a single rounded command bar with message field, voice toggle, model/voice/ready/retry/diagnostics chips, attachments, mic, and send. Mobile keeps the Telegram-like composer.

**Remaining gap:** folder/context, web/tool toggles, and richer model/reasoning controls should wait for stable Hermes Agent support.

### 4. Active sessions / tabs

**Desktop:** active runs appear as tabs at the top of the chat area (`ActiveSessionsBar`), supporting multi-run switching.

**Hermes Wing:** session rail shows active/forked/other sessions, and desktop/tablet now add a compact active-session bar above the chat pane with current session, status, model, and message count.

**Remaining gap:** true multi-run tab switching like Desktop's `ActiveSessionsBar` still depends on Hermes exposing multiple simultaneous mobile-safe active runs. Skip on mobile.

### 5. Tool, reasoning, and approval timeline

**Desktop:** reasoning and tool calls are folded into dedicated rows (`ReasoningRow`, `ToolActivityGroup`), sharing one assistant avatar per turn and avoiding raw event spam.

**Hermes Wing:** final chat bubbles remain Telegram-like, while tool calls, approvals, errors, and assistant turns now render as grouped/inline assistant-side timeline cards with desktop avatars.

**Remaining gap:** optional `Thought`/reasoning rows when Hermes exposes stable reasoning events; otherwise avoid inventing fake reasoning UI.

### 6. Settings/status dashboard

**Desktop:** Settings and Gateway screens are card dashboards with connection, model/provider, health, diagnostics, and appearance controls.

**Hermes Wing:** settings now use a Hermes Agent dashboard with status, connection, appearance, diagnostics, and local voice cards. It is simpler than Desktop's full Gateway/Providers screens, which is intentional for mobile.

**Copy later:** add richer provider/tool details through capability-gated Hermes Agent endpoints; keep local host administration desktop-only.

### 7. Session search and history polish

**Desktop:** session history is first-class in the sidebar with richer recent-session affordances.

**Hermes Wing:** rail groups active/forked/other sessions, supports actions, and now includes desktop/tablet search/filter with visible result counts. Richer history polish, recency metadata, and keyboard-first switching can still improve later.

**Copy later:** add command-palette style session switching and richer recent-session metadata once the session list grows.

## Completed implementation slice: Hermes Dark + branded desktop shell polish

Evidence:

- `lib/theme/wing_theme.dart` now defines `wingHermesDarkTheme` with near-black Hermes surfaces, blue accents, dark cards/chips, and rounded dark inputs.
- `lib/shared/widgets/app_shell.dart` applies Hermes Dark to desktop/tablet shell widths and adds a `HERMES ONE` branded rail header.
- `playwright/screenshots/hermes-dark-desktop-scaffold.png` shows dark shell, dark session rail, dark chat pane, dark empty state chips, and dark composer.
- `playwright/screenshots/hermes-dark-mobile-scaffold.png` shows mobile staying Telegram-like: single pane, bottom nav, bottom composer, and large touch targets.

## Completed implementation slice: Desktop composer command bar

Evidence:

- `lib/features/hermes_chat/screens/hermes_chat_screen.dart` now switches composer layout by available width.
- Desktop/tablet chat panes use a single rounded `hermes-desktop-command-bar` containing the message field, voice toggle, model/voice/ready/retry/diagnostics chips, attachments, mic, and send.
- Mobile keeps the previous Telegram-like two-row bottom composer.
- `playwright/screenshots/hermes-commandbar-desktop-scaffold.png` shows the Desktop-like command bar in the dark Hermes shell.
- `playwright/screenshots/hermes-commandbar-mobile-scaffold.png` shows mobile still using the Telegram-style bottom composer.

## Completed implementation slice: Tool activity grouping + desktop session search

Evidence:

- `lib/features/hermes_chat/screens/hermes_chat_screen.dart` now renders transcripts through `_HermesTranscriptList`.
- Consecutive Hermes `toolCall` turns collapse into `_ToolActivityGroup`, a left-aligned expandable card similar to Hermes Desktop's `ToolActivityGroup` pattern.
- Individual tool rows remain available inside the expanded group with running/completed/failed icons and redacted previews/results.
- Desktop/tablet `_HermesSessionRail` now has `Search sessions`, clear action, and visible result counts, matching Desktop's first-class session-history direction.
- User and assistant text remains in simple Telegram-style right/left bubbles.

## Completed implementation slice: Inline approval timeline

Evidence:

- Pending approvals are now rendered by `_HermesTranscriptList` as inline left-aligned approval cards after transcript rows instead of a full-width top-of-chat banner.
- The approval card keeps review/deny/allow/approve actions, pending count, risk copy, and malformed/unavailable states.
- This better matches Hermes Desktop's chat-flow cards while preserving mobile-safe approval buttons.

## Completed implementation slice: Inline failure/status timeline polish

Evidence:

- Chat errors now render through `_HermesTranscriptList` as compact left-aligned failure cards rather than full-width chrome above the composer.
- Failure cards keep contextual recovery text plus Details/Reconnect/Retry actions.
- The card shape matches the bounded assistant-side approval/tool cards, while mobile still keeps simple bottom composer ergonomics.

## Completed implementation slice: Desktop assistant turn/avatar polish

Evidence:

- `_AssistantTimelineItem` adds a lightweight Hermes avatar column around assistant-side text, tool, approval, and failure rows on desktop/tablet widths.
- Widths below the desktop command-bar breakpoint keep the previous Telegram-like mobile bubble rhythm without assistant avatar chrome.
- This makes tool/approval/final-answer sequences read closer to Hermes Desktop's one-assistant-turn timeline while preserving right-aligned user bubbles.

## Completed implementation slice: Hermes settings/status dashboard

Evidence:

- `lib/features/settings/screens/settings_screen.dart` now renders a Hermes Agent dashboard instead of basic list tiles.
- Card sections cover Hermes Agent status, Connection, Appearance, Diagnostics, and Local voice preferences.
- The dashboard shows endpoint, auth-present/not-shown state, health/version, model, run transport, session/inventory counts, and an Open Hermes action.
- Cards stay stacked and mobile-simple; no Desktop-only nav sprawl was added.

## Completed implementation slice: Desktop active-session bar

Evidence:

- `lib/features/hermes_chat/screens/hermes_chat_screen.dart` now adds `_HermesActiveSessionBar` on desktop/tablet chat panes.
- The bar mirrors Hermes Desktop's top active-session/tabs region without becoming a full multi-run tab system: current session pill, ready/streaming/transport status, model, and message count.
- Mobile stays single-pane and Telegram-like; the active-session bar is hidden below the desktop command-bar breakpoint.

## Completed implementation slice: VPN/mobile reconnect clarity

Evidence:

- `HermesChannelState` now carries the connected API origin and whether a bearer key was used, so connected/status surfaces can describe the real VPN endpoint instead of falling back to localhost placeholders.
- Chat error recovery now uses a true reconnect path against the current/saved endpoint instead of routing through destructive Disconnect, preserving saved VPN profiles and secure API-key storage.
- When the app resumes from background, recoverable connected/error states reconnect against the saved/current VPN endpoint instead of waiting for manual setup.
- The connect form hydrates from the saved endpoint profile when available, which keeps reopen/reconnect behavior aligned with the mobile-over-VPN use case.
- Settings now prefers the live connected endpoint/auth state and still hides the API key value.

## Recommended next implementation slice

**Polish and harden visual QA artifacts** is now the highest-impact remaining slice.

Suggested scope:

1. Refresh screenshot artifacts for the active-session bar, settings dashboard, assistant timeline, session search, and mobile composer.
2. Add focused widget/E2E assertions for the settings dashboard cards and desktop active-session bar.
3. Review any future Desktop-only surfaces against the explicit non-copy list before adding them.

## Keep from Telegram

- Right-aligned user bubbles and left-aligned assistant bubbles.
- Bottom composer with large touch targets.
- Mobile single-pane flow.
- Sessions and diagnostics as sheets/dialogs on phones.
- Plain-language errors and retry near failed turns.

## Port by capability, not literally

- Replace Electron window chrome and traffic lights with Flutter's platform-native desktop shell.
- Port install/update flows as desktop host capabilities; mobile and web use remote endpoints.
- Preserve Office, Kanban, and Discover outcomes, adapting their navigation and interaction density per form factor.
- Gate folder, worktree, process, SSH, and local-file controls to supported desktop hosts.
- Do not claim parity from matching screenshots alone; each capability needs contract and behavior evidence.
