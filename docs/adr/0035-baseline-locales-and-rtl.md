# ADR 0035: Preserve baseline locales and RTL behavior

Status: accepted
Date: 2026-07-13

Navivox uses Flutter's generated localization support and preserves the frozen Hermes Desktop locale set before Electron retirement: `ar`, `en`, `es`, `he`, `id`, `ja`, `pl`, `pt-BR`, `pt-PT`, `tr`, `zh-CN`, and `zh-TW`. Android may ship English-first while parity work is incomplete, but every new user-facing Navivox string is externalized when introduced.

## Locale behavior

The application follows the supported system locale by default and offers a persisted client-local override. Unsupported or missing development strings fall back to English. Region-specific Portuguese and Chinese resources remain distinct.

App-owned navigation, controls, validation, errors, accessibility labels, setup, settings, and host-adapter messages are localized. Hermes-generated content, prompts, transcripts, tool output, profile names, paths, code, command lines, provider/model identifiers, and server-authored free text are not translated.

Dates, times, numbers, plurals, and placeholders use locale-aware formatting. Dynamic values are kept separate from translation templates and isolated for bidirectional rendering. Translation resources never construct routes, URLs, commands, or authorization decisions.

## RTL behavior

Arabic and Hebrew use end-to-end RTL layout for app chrome, navigation, forms, dialogs, focus traversal, gestures, and directional icons. Code, terminal output, identifiers, URLs, and other inherently LTR content retain an isolated LTR presentation. Implementations use directional start/end APIs rather than hard-coded left/right layout.

## Evidence

English remains the source locale. Release translations require fluent review rather than unreviewed machine output. CI checks generated localization resources, placeholder consistency, and missing critical-flow keys. Per-locale layout tests cover overflow and 200% text scaling; Arabic and Hebrew additionally require Android and desktop RTL receipts. A critical flow with untranslated app-owned text or broken RTL behavior is not validated.

Locales added by Hermes Desktop before the retirement cutoff enter the delta ledger like any other capability change.
