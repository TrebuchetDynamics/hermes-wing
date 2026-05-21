# Navivox Testing Plan

Status: planning draft
Updated: 2026-05-16

## 1. Strategy

Navivox tests should protect the connect-and-talk loop first:

1. Configure a gateway base URL and token.
2. Prove `/healthz` and `/v1/navivox/status`.
3. Open `/v1/navivox/stream`.
4. Send a text or transcript turn.
5. Render assistant events and tool events.

Tests should not depend on telephony, public networking, or privileged host
setup.

## 2. Test Pyramid

```text
            +----------------+
            |      E2E       |  5-10%: full setup to first turn
            +----------------+
         +----------------------+
         |     Integration      | 20-30%: fixture gateway and Go handler
         +----------------------+
      +----------------------------+
      |       Widget Tests         | 30-40%: setup/chat/config/agents
      +----------------------------+
   +----------------------------------+
   |            Unit Tests            | 40-50%: protocol, state, validation
   +----------------------------------+
```

## 3. Flutter Unit Tests

### 3.1 Gateway Config

**File**: `test/core/gateway/navivox_gateway_protocol_test.dart`

| Test | Input | Expected |
|------|-------|----------|
| Health URL | `http://127.0.0.1:8765` | `/healthz` |
| Status URL | Base URL with path | Path replaced with `/v1/navivox/status` |
| Stream URL | `http://host:8765` | `ws://host:8765/v1/navivox/stream` |
| Secure stream URL | `https://host` | `wss://host/v1/navivox/stream` |
| Bearer header | token present | `Authorization: Bearer <token>` |
| Empty token | blank token | no auth header |

### 3.2 Gateway Client

**File**: `test/core/gateway/navivox_gateway_client_test.dart`

| Test | Setup | Expected |
|------|-------|----------|
| Health decodes object | JSON object body | Map returned |
| Status rejects array | JSON array body | Format error |
| HTTP error | 401 body | safe exception |
| Decode event | event JSON string | typed event |
| Bad wire event | non-map payload | typed `error` event |
| Backoff clamps | attempt greater than max | bounded delay |

### 3.3 Gateway Channel

**File**: `test/core/channel/gateway_navivox_channel_test.dart`

| Test | Setup | Expected |
|------|-------|----------|
| Connect | status succeeds, stream opens | server entry added |
| Send text | connected socket | `start_turn` message sent |
| Empty text | whitespace | no message sent |
| Disconnected send | no socket | system message shown |
| Session started | event with session id | active session set |
| Assistant delta | two deltas | one growing assistant message |
| Assistant message | final event | assistant message replaced/finalized |
| Tool started | tool event | `ToolCallCard` message created |
| Tool finished | finish event | card status updates |
| Error event | error message | system message shown |

### 3.4 Router

**File**: `test/router/app_router_test.dart`

| Test | Setup | Expected |
|------|-------|----------|
| Fresh app | no gateway server | redirects to `/setup` |
| Connected app | server exists | `/chats` renders |
| Setup after connect | server exists and path `/setup` | redirects to `/chats` |
| Unknown path | invalid path | route-not-found screen |

## 4. Flutter Widget Tests

### 4.1 Setup Screen

| Test | Expected |
|------|----------|
| Shows base URL input | Operator can paste `connect-info` URL. |
| Shows token input when needed | Token value is obscured and not copied into route data. |
| Health failure | Error explains gateway is unavailable. |
| Unauthorized status | Error asks for token or server auth check. |
| Successful connect | Navigates to chat. |

### 4.2 Chat Screen

| Test | Expected |
|------|----------|
| Empty state | Composer is visible and focused. |
| User sends text | User bubble appears immediately. |
| Assistant streaming | Deltas render without duplicate bubbles. |
| Tool event | Structured card appears. |
| Voice transcript | Transcript is sent through text turn path. |
| Connection loss | Messages stay visible and reconnect state appears. |

### 4.3 Agents Screen

| Test | Expected |
|------|----------|
| Seed input | Short natural-language seed accepted. |
| Draft generated | Agent/profile/tool/voice sections displayed. |
| Edit draft | Fields remain editable before apply. |
| Apply disabled | Missing server role or validation blocks apply. |

### 4.4 Config Screen

| Test | Expected |
|------|----------|
| Schema loads | Sections and fields render from server schema. |
| Secret field | Redacted status, set/rotate/delete actions. |
| Diff preview | Non-secret before/after values shown. |
| Validation error | Field-level server error shown. |
| Risk confirmation | Exposure/provider changes require confirmation. |

### 4.5 Voice Run Lifecycle

| Test | Expected |
|------|----------|
| Capture starts | Voice run enters `recording`. |
| Device transcript ready | Voice run enters `pending_send` with `transcript_source=device`. |
| Grace cancel | Voice run enters `cancelled`; no gateway turn is sent. |
| Grace complete | Voice run enters `submitted`; existing `start_turn` receives final transcript. |
| Local command | No Voice run is created and no gateway turn is sent. |
| Capture failure | Voice run enters `failed` with safe recovery copy. |

## 5. Go Tests

### 5.1 Connect Info CLI

**Package**: `cmd/gormes`

| Test | Expected |
|------|----------|
| Disabled channel | Non-zero error points to `[navivox].enabled`. |
| Local mode JSON | Loopback base URL and health URL emitted. |
| Token redaction | Token value absent from text and JSON output. |
| VPN modes | VPN interfaces listed with host source. |
| Text output | Human-readable base URLs and health URLs. |

### 5.2 Channel Handler

**Package**: `internal/channels/navivox`

| Test | Expected |
|------|----------|
| `/healthz` | Returns status ok without auth. |
| `/v1/navivox/status` | Requires auth and reports channel status. |
| `/v1/navivox/sessions` | Lists sessions. |
| `/v1/navivox/turn` | Enqueues `gateway.EventSubmit`. |
| Stream ping | Returns `pong`. |
| Stream start turn | Creates or uses session and sends `session_started`. |
| Stream cancel | Enqueues `gateway.EventCancel`. |
| Unauthorized | Safe JSON error. |
| Bad JSON | Safe JSON error. |
| Origin policy | Allows configured origins and rejects unknown origins. |

### 5.3 Config Validation

**Package**: `internal/config`

| Test | Expected |
|------|----------|
| Disabled default | Navivox disabled and local by default. |
| Token-required auth | Missing token rejected. |
| Local exposure | Requires loopback bind. |
| VPN exposure | Requires matching active VPN interface. |
| Public exposure | Requires explicit confirmation. |
| Token secret | Secret env name and redaction classification are correct. |

## 6. Integration Tests

### 6.1 Flutter With Fixture Gateway

The fixture gateway should be an HTTP/WebSocket process or in-process test
server that implements the current endpoint contract.

| Scenario | Steps | Expected |
|----------|-------|----------|
| First connect | Enter base URL and token | Health/status pass; chat opens. |
| First turn | Send "hello" | User bubble, assistant stream, done state. |
| Unauthorized | Wrong token | Setup stays open with safe error. |
| Tool card | Emit tool start/finish events | Card appears and updates. |
| Reconnect | Close stream then reopen | State shows reconnect and recovers. |

### 6.2 Flutter With Real Go Handler

Use the Go Navivox handler in a test fixture for one narrow smoke:

1. Start handler with static token config and in-memory inbox.
2. Launch Flutter test against the handler base URL.
3. Connect from setup.
4. Send one turn.
5. Assert the Go inbox receives a `navivox` submit event.

## 7. End-To-End Scenarios

| ID | Scenario | Expected |
|----|----------|----------|
| E1 | Fresh app to first text turn | Operator reaches chat and receives streamed assistant output. |
| E2 | No telephony configured | First turn still works. |
| E3 | Token missing | Safe unauthorized state with no token leak. |
| E4 | Gateway offline | Recovery action points to host/gateway status. |
| E5 | Public exposure not confirmed | Server refuses unsafe config before app connects. |
| E6 | Tool call event | Tool card renders as structured UI. |
| E7 | Agent seed draft | Seed creates editable draft, not an auto-applied agent. |
| E8 | Config secret edit | Secret value is write-only and redacted after apply. |

### 7.1 Web E2E Gate

Navivox must keep the connect-and-talk loop working in Chrome, not only in
hosted Flutter widget tests. The required browser smoke is:

```bash
cd flutter-navivox/app
flutter test --platform chrome test/e2e/connect_and_talk_web_e2e_test.dart
flutter build web --no-web-resources-cdn
```

Flutter's `integration_test` web runner remains available for environments
with matching ChromeDriver/WebDriver configured:

```bash
cd flutter-navivox/app
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/connect_and_talk_e2e_test.dart -d chrome
```

## 8. Fixtures

Recommended fixtures:

- `test/fixtures/navivox/status_ok.json`
- `test/fixtures/navivox/status_unauthorized.json`
- `test/fixtures/navivox/session_started.json`
- `test/fixtures/navivox/assistant_delta.json`
- `test/fixtures/navivox/assistant_message.json`
- `test/fixtures/navivox/tool_call_started.json`
- `test/fixtures/navivox/tool_call_finished.json`
- `test/fixtures/navivox/error.json`
- `test/fixtures/config/navivox_schema.json`
- `test/fixtures/agents/seed_lead_screening.json`

Fixtures must not contain real tokens, transcripts from real users, provider
keys, or private tool output.

## 9. CI Commands

```bash
go test ./cmd/gormes -run NavivoxConnectInfo -count=1
go test ./internal/channels/navivox -count=1
go test ./internal/config -run Navivox -count=1
cd flutter-navivox/app && flutter test
cd flutter-navivox/app && flutter test --platform chrome test/e2e/connect_and_talk_web_e2e_test.dart
cd flutter-navivox/app && flutter build web --no-web-resources-cdn
```

Docs-only rows should also run:

```bash
go run ./cmd/progress validate
git diff --check
```

The stale-transport grep in the relevant progress row is expected to return
only explicitly historical or deleted mentions in progress evidence, generated
queue text, or comments that describe removed code.
