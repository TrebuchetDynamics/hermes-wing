# Navivox Data Model

Status: planning draft
Updated: 2026-05-16
Source: current HTTP/WebSocket gateway contract and Navivox PRD

## 1. Model Principles

- Gormes is authoritative for agents, sessions, config, tools, provider
  settings, and voice profiles.
- Flutter caches local UI state and safe snapshots only.
- Tokens and secrets are never serialized into route paths, screenshots, debug
  logs, or exported diagnostics.
- Local persistence starts minimal. Add a database only when offline history,
  voice run retention, or draft recovery needs it.
- Every model should be rebuildable from server state plus local connection
  settings.

## 2. Gateway Connection

Represents one saved way to reach a Navivox gateway.

| Field | Type | Notes |
|-------|------|-------|
| `id` | string | Local UUID. |
| `label` | string | Human-friendly name, default from host. |
| `base_url` | string | From `gormes navivox connect-info`. |
| `healthz_url` | string | Usually `base_url + /healthz`. |
| `host` | string | Parsed host for display. |
| `port` | integer | Parsed or reported port. |
| `host_source` | string | `local`, `tailscale`, `wireguard`, `tun-other`, or `manual`. |
| `auth_mode` | string | Server-reported when known. |
| `token_required` | boolean | From `connect-info` or status probe. |
| `token_ref` | string | Local secure-storage reference, never the token value. |
| `exposure_mode` | string | Server-reported mode. |
| `last_health_status` | string | `unknown`, `ok`, `offline`, `blocked`. |
| `last_stream_status` | string | `disconnected`, `connecting`, `connected`, `reconnecting`. |
| `last_error_code` | string | Safe error code. |
| `created_at` | timestamp | Local creation time. |
| `updated_at` | timestamp | Local update time. |

Example:

```json
{
  "id": "local-gateway",
  "label": "Local Gormes",
  "base_url": "http://127.0.0.1:8765",
  "healthz_url": "http://127.0.0.1:8765/healthz",
  "host_source": "local",
  "token_required": true,
  "token_ref": "secure:navivox/local-gateway",
  "exposure_mode": "local",
  "last_health_status": "ok",
  "last_stream_status": "connected"
}
```

## 3. Gateway Status Snapshot

Mirrors `GET /v1/navivox/status`.

| Field | Type | Notes |
|-------|------|-------|
| `enabled` | boolean | Server channel enabled state. |
| `bind_host` | string | Safe to display. |
| `port` | integer | Gateway port. |
| `exposure_mode` | string | `local`, `tailscale`, `wireguard`, `vpn`, or `public`. |
| `auth_mode` | string | `static_token`, `pairing_token`, or `tailscale_identity`. |
| `sessions` | integer | Count. |
| `ws_connections` | integer | Count. |
| `observed_at` | timestamp | Local observation time. |

The app should keep the latest status snapshot for UI display, but should not
treat cached status as authorization.

## 4. Session

Mirrors server session state.

| Field | Type | Notes |
|-------|------|-------|
| `session_id` | string | Server id. |
| `last_request_id` | string | Optional. |
| `created_at` | timestamp | Server timestamp. |
| `updated_at` | timestamp | Server timestamp. |
| `subscribers` | integer | Server count. |
| `active_agent_id` | string | Future server field. |
| `local_title` | string | Optional local display title. |

Sessions are loaded from `/v1/navivox/sessions` and updated by stream events.

## 5. Messages

Messages are local render objects derived from user input and gateway events.

| Field | Type | Notes |
|-------|------|-------|
| `id` | string | Local or server id. |
| `session_id` | string | Owning session. |
| `request_id` | string | Correlates user turn and assistant stream. |
| `author` | enum | `user`, `assistant`, `system`. |
| `kind` | enum | `text`, `tool_call`, `voice`, `error`. |
| `text` | string | Redacted when marked private. |
| `is_final` | boolean | Streaming completion state. |
| `created_at` | timestamp | Local or server timestamp. |
| `updated_at` | timestamp | Updated during stream. |

Assistant deltas should update one message per request rather than appending a
new bubble for every delta.

## 6. Tool Calls

Tool calls are first-class UI objects.

| Field | Type | Notes |
|-------|------|-------|
| `tool_call_id` | string | Stable id from event or local generated id. |
| `session_id` | string | Owning session. |
| `request_id` | string | Turn correlation id. |
| `tool_name` | string | Display-safe tool name. |
| `status` | enum | `queued`, `running`, `needs_approval`, `approved`, `denied`, `completed`, `failed`. |
| `summary` | string | Short safe summary. |
| `input_preview` | object | Redacted preview. |
| `output_preview` | object | Redacted preview. |
| `artifacts` | list | Safe artifact refs. |
| `requires_approval` | boolean | Future approval state. |
| `redaction_level` | enum | `none`, `partial`, `hidden`. |
| `started_at` | timestamp | Optional. |
| `completed_at` | timestamp | Optional. |

Raw JSON belongs behind a debug affordance. The default renderer is
`ToolCallCard`.

## 7. Agent Draft And Profile

The natural-language seed flow produces an editable draft.

### 7.1 Agent Seed Request

| Field | Type | Notes |
|-------|------|-------|
| `seed` | string | Example: `screen inbound leads`. |
| `base_agent_id` | string | Optional template/source agent. |
| `session_id` | string | Optional context. |

### 7.2 Agent Draft

| Field | Type | Notes |
|-------|------|-------|
| `draft_id` | string | Server or local id. |
| `name` | string | Editable. |
| `description` | string | Editable. |
| `instructions` | string | Editable. |
| `tools` | list | Draft tool settings. |
| `voice_profile` | object | Draft voice defaults. |
| `stt_profile` | object | Draft STT defaults. |
| `safety_policy` | object | Approval/escalation/redaction settings. |
| `validation_errors` | list | Server field errors. |

### 7.3 Tool Setting

| Field | Type | Notes |
|-------|------|-------|
| `tool_name` | string | Tool id. |
| `enabled` | boolean | Draft value. |
| `permission` | enum | `allow`, `ask`, `deny`. |
| `redaction_policy` | enum | `default`, `strict`. |

## 8. Voice Profile And Voice Run

### 8.1 Voice Profile

| Field | Type | Notes |
|-------|------|-------|
| `profile_id` | string | Server id. |
| `label` | string | Display name. |
| `stt_provider` | string | Optional. |
| `stt_model` | string | Optional. |
| `tts_provider` | string | Optional. |
| `tts_voice` | string | Optional. |
| `locale` | string | Optional. |
| `speed` | number | Optional. |

### 8.2 Voice Run

Voice runs should exist before persistent audio upload/playback features.

| Field | Type | Notes |
|-------|------|-------|
| `voice_run_id` | string | Stable id. |
| `session_id` | string | Owning session. |
| `request_id` | string | Turn correlation id. |
| `capture_status` | enum | `idle`, `recording`, `transcribing`, `submitted`, `failed`. |
| `transcript` | string | Device or server transcript. |
| `transcript_source` | enum | `device`, `server`, `manual`. |
| `confidence` | number | Optional. |
| `duration_ms` | integer | Optional. |
| `stt_profile_id` | string | Optional. |
| `tts_profile_id` | string | Optional. |
| `retention_policy` | string | Required before audio persistence. |

## 9. Config Models

Config admin is schema-driven and server-authoritative.

### 9.1 Config Schema

| Field | Type | Notes |
|-------|------|-------|
| `schema_version` | string | Server version. |
| `sections` | list | Section definitions. |
| `generated_at` | timestamp | Server timestamp. |

### 9.2 Config Field

| Field | Type | Notes |
|-------|------|-------|
| `path` | string | Example: `navivox.exposure_mode`. |
| `label` | string | Display label. |
| `type` | enum | `string`, `integer`, `boolean`, `enum`, `object`, `array`, `secret`. |
| `required` | boolean | Validation hint. |
| `enum_values` | list | Optional. |
| `default` | any | Optional. |
| `secret` | boolean | Secret field marker. |
| `restart_required` | boolean | Server hint. |
| `risk_level` | enum | `low`, `medium`, `high`. |

### 9.3 Redacted Config Value

| Field | Type | Notes |
|-------|------|-------|
| `path` | string | Field path. |
| `value` | any | Non-secret value only. |
| `secret_status` | string | `unset`, `configured`, `external`, `unknown`. |
| `source` | string | Safe source evidence. |
| `updated_at` | timestamp | Optional. |

### 9.4 Draft Change

| Field | Type | Notes |
|-------|------|-------|
| `path` | string | Field path. |
| `old_value` | any | Non-secret only. |
| `new_value` | any | Redacted for secret changes. |
| `validation_state` | enum | `unknown`, `valid`, `invalid`. |
| `requires_confirmation` | boolean | High-risk fields. |

## 10. Local Settings

| Field | Type | Notes |
|-------|------|-------|
| `theme` | enum | `system`, `dark`, `light`. |
| `density` | enum | `compact`, `comfortable`. |
| `app_lock_enabled` | boolean | Local only. |
| `lock_timeout_seconds` | integer | Local only. |
| `wake_word` | string | Local voice hint. |
| `text_fallback_enabled` | boolean | Always true by default. |

## 11. Persistence Plan

### 11.1 In-Memory First

Use in-memory provider state for:

- Active connection.
- Active session.
- Current chat transcript.
- Setup errors.
- Agent draft before apply.

### 11.2 Secure Storage

Use secure storage for:

- Gateway tokens.
- Local app unlock material.

Never store:

- Secret values read from server config.
- Raw provider keys.
- Unredacted sensitive tool output.

### 11.3 Optional Database

Add a database only when the product needs durable:

- Message history.
- Voice run records.
- Agent draft recovery.
- Config schema snapshots.

Before adding one, define migrations, clear-local-data behavior, redaction
policy, and export policy.

## 12. Event Mapping

| Gateway Event | Model Update |
|---------------|--------------|
| `session_started` | Create/update `Session`; set active session. |
| `assistant_delta` | Append text to one assistant `Message` for the request. |
| `assistant_message` | Upsert/finalize assistant `Message`. |
| `tool_call_started` | Create or update `ToolCall` with running status. |
| `tool_call_finished` | Update `ToolCall` status, summary, and artifacts. |
| `error` | Append safe system/error `Message`. |
| `done` | Mark active turn complete. |

## 13. Redaction Rules

- Token fields store only `token_ref` and status.
- Secret config values store only `secret_status` and source evidence.
- Tool inputs/outputs default to `redaction_level=partial` unless server marks
  them safe.
- Voice transcripts can be marked private and omitted from diagnostics.
- Diagnostic export must strip tokens, secrets, private transcripts, and hidden
  tool payloads.
