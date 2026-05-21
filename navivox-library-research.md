# Navivox Library Research

Status: planning draft
Updated: 2026-05-16
Source: current `flutter-navivox/app/pubspec.yaml` plus feature planning

## 1. Current Dependency Baseline

The app should stay small until a feature needs a package. The current
`pubspec.yaml` contains:

| Library | Purpose | Notes |
|---------|---------|-------|
| Flutter | App framework | Required. |
| `flutter_riverpod` | State management | Connection, channel, chat, voice, and route state. |
| `go_router` | Navigation | Setup redirect and shell tabs. |
| `freezed_annotation` | Future immutable models | Annotation dependency is present; codegen should be added only when unions grow. |
| `json_annotation` | Future JSON models | Useful for generated gateway/config DTOs. |
| `uuid` | Client request ids | Used by channel messages. |
| `intl` | Formatting | Timestamps and durations. |
| `path` | Path helpers | Local cache paths when needed. |

Dependencies removed from the current app should not be reintroduced as
planning defaults. Add packages only with the feature slice that needs them and
with tests proving the package participates in the current HTTP/WebSocket
gateway loop.

## 2. HTTP/WebSocket Gateway

The current app uses `dart:io` `HttpClient` and `WebSocket`.

Current gateway client responsibilities:

- Build `/healthz`, `/v1/navivox/status`, `/v1/navivox/sessions`,
  `/v1/navivox/turn`, and `/v1/navivox/stream` URLs from a base URL.
- Convert `http` to `ws` and `https` to `wss` for stream connections.
- Attach bearer auth headers when a token is configured.
- Decode JSON server events into typed Dart objects.
- Apply reconnect backoff.

When browser/web support becomes a target, evaluate a cross-platform HTTP and
WebSocket package in that specific slice. Until then, the existing Dart IO path
is enough for mobile and desktop.

## 3. State And Navigation

### 3.1 Riverpod

Use Riverpod providers for:

- Active gateway channel.
- Connection state.
- Active server/session/agent.
- Chat message state.
- Config schema and draft state.
- Voice capture and transcript state.

Rules:

- Keep server-owned data separate from local UI drafts.
- Keep providers easy to override in tests.
- Avoid global singletons outside provider scopes.

### 3.2 GoRouter

Use GoRouter for:

- Setup redirect when no gateway-backed server is configured.
- Shell route for chat, servers, agents, and config.
- Future detail routes with stable path params.

Rules:

- Do not put tokens or secrets in route paths or query params.
- Detail routes should be mounted only when their screens work against the
  current gateway contract.

## 4. Chat UI

The planned chat foundation is `flyerhq/flutter_chat_ui` v2, but the current
app still uses a simple adapter. Introduce the chat package in the slice that
needs:

- Streaming assistant text.
- Custom tool card builders.
- Voice message bubbles.
- Agent/system control messages.

Acceptance for adding the package:

- Existing connect-and-talk tests still pass.
- Tool events render through `ToolCallCard`.
- Raw tool JSON is not the default message UI.
- Long messages, mobile widths, and desktop widths are covered by screenshots
  or widget tests.

## 5. Secure Local Storage

A secure storage package is needed when the app persists tokens or local unlock
state.

Requirements:

- Tokens are redacted in logs and UI.
- Clearing local app data removes persisted tokens.
- Linux failure modes show actionable setup errors.
- Route URLs and deep links never contain tokens.

Until secure storage lands, tests should prefer injected in-memory credentials.

## 6. Local Unlock

Use local biometric/PIN packages only for local unlock flows:

- Secret editor access.
- Viewing redacted-sensitive metadata.
- Applying high-risk config mutations.

The server still decides whether a user can mutate config. Local unlock is an
extra client-side gate, not authorization by itself.

## 7. Voice And Audio

Voice features should be added in thin slices.

Candidate package categories:

- Microphone capture.
- Platform STT for local transcript hints.
- Audio playback for server-generated speech.
- Permission prompts.

Current rule:

- The first connect-and-talk loop may submit a local transcript through the text
  turn path.
- Audio upload, server STT profiles, and TTS playback require voice run records
  first.

## 8. Generated Models

Use generated immutable models when gateway/config/voice DTOs become too large
for hand-written classes.

Good candidates:

- Gateway events with many variants.
- Config schema field types.
- Agent draft/profile/tool/voice settings.
- Voice run records.

Rules:

- Generated files and build steps must be documented.
- Tests must prove unknown server fields do not crash the app.
- Secret fields must not be serializable into logs by accident.

## 9. Persistence

Local persistence is a cache, not authority. Add a database only when one of
these needs exists:

- Offline session list.
- Searchable message history.
- Durable voice run records.
- Cached config schema snapshots.
- Agent draft recovery.

Before adding a database, define:

- Retention policy.
- Clear-local-data behavior.
- Migration strategy.
- Redaction policy for sensitive tool output and transcripts.

## 10. Config UI Packages

Schema-driven config can start with first-party Flutter form widgets.
Introduce form-builder packages only if they remove real complexity.

Required form behavior:

- Field-level server validation mapping.
- Redacted secret status.
- Diff preview.
- Confirmation for risky changes.
- Pending restart/reconnect result.

## 11. Known Limitations And Workarounds

| Limitation | Impact | Workaround |
|------------|--------|------------|
| Dart IO client is not browser-compatible | Web builds need another client layer | Defer web support to a dedicated slice. |
| Local STT varies by platform | Voice may be text-only on some devices | Always keep text turn fallback. |
| Secure storage can fail on minimal Linux installs | Persisted tokens may not be available | Show setup error and allow in-memory session. |
| Audio playback adds platform-specific behavior | TTS tests can become flaky | Start with voice run metadata before streaming audio. |
| Generated model build steps add maintenance | CI and contributors need setup | Add only when protocol shape requires it. |

## 12. Package Addition Checklist

Before adding a dependency:

1. Name the feature slice that requires it.
2. Prove it supports the target platforms for that slice.
3. Add tests or fixtures that exercise it.
4. Document failure modes.
5. Confirm it does not expand the first activation loop beyond connect and talk.
