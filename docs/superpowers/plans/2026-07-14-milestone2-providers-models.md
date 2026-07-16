# Milestone 2 — Providers & Models Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Scoped, profile-aware provider-credential and model-selection contracts + Flutter client, per `docs/superpowers/specs/2026-07-14-milestone2-providers-models-design.md`. The phone is a key-setter and model-switcher, never a key-reader.

**Architecture:** Reuse existing `hermes_cli` provider/model domain functions over `_authorize`-gated HTTP (the milestone-0 pattern), then build the Flutter client (the milestone-1 pattern). No `hermes_cli` behavior changes.

**Tech Stack:** hermes-agent (Python 3.11+, aiohttp, `uv run --extra dev pytest`); wing (Flutter 3.44, Dart 3.12, Riverpod 3, go_router 17).

## Global Constraints

- **Secret invariant (load-bearing):** no endpoint, response body, log line, error message, or capability field ever returns a raw provider key. Credential set is write-only; the Dashboard's `reveal_env_var` is NOT mirrored. Presence = `configured: bool` + masked last-4 only.
- hermes-agent work on branch `feat/providers-models` (from local `main`, which now has milestone 0); commit, NEVER push. wing on branch `feat/providers-models` (from local `main`).
- New scope domains `providers` and `models` added to `VALID_SCOPE_DOMAINS`.
- All mutations `:write`-gated via `_authorize`; assignment changes use `If-Match`; every operation carries the mandatory `?profile=` query.
- Stage only files each task names; never bare `git add -A`; leave the user's pre-existing dirty docs/ADR files untouched.
- Per-repo gates green (pytest / flutter test + analyze + format) before every commit. The hermes-agent full `tests/gateway/` run has 10 known pre-existing failures (Telegram/Wecom) — baseline-diff to confirm zero new.

---

### Task 1: Extend scope vocabulary with providers and models

**Files:**
- Modify: `hermes-agent/gateway/api_operator_auth.py` (`VALID_SCOPE_DOMAINS`)
- Modify: `hermes-agent/tests/gateway/test_api_operator_auth.py`

**Interfaces:**
- Produces: `providers:read`, `providers:write`, `models:read`, `models:write` accepted by `normalize_scopes`; `AuthPrincipal` unchanged.

- [ ] **Step 1: Failing test** — add cases: `normalize_scopes(["providers:read","models:write"])` returns them sorted/deduped; `AuthPrincipal("x", ("providers:write",), False).allows("providers:read")` is False (exact match, per milestone 0); a token with `models:read` does not satisfy `models:write`. Run: FAIL.
- [ ] **Step 2: Implement** — add `providers` and `models` to `VALID_SCOPE_DOMAINS` (READ the file; it is a set/tuple of domain names — add exactly two entries).
- [ ] **Step 3: Run** `cd hermes-agent && uv run --extra dev pytest tests/gateway/test_api_operator_auth.py -q` (all pass) + ruff.
- [ ] **Step 4: Commit** `feat(gateway): providers and models scope domains`.

---

### Task 2: Provider presence and write-only credential contract

**Files:**
- Modify: `hermes-agent/gateway/platforms/api_server.py`
- Create: `hermes-agent/tests/gateway/test_api_providers.py`

**Interfaces:**
- Consumes: `_authorize` (milestone 0); `hermes_cli.provider_catalog.provider_catalog()` → `list[ProviderDescriptor]` (has slug, label, `env_vars`, `auth_type`); the env-var config layer the Dashboard's `set_env_var`/`remove_env_var` handlers call — READ `hermes_cli/web_server.py` around the `set_env_var`/`remove_env_var`/`validate_provider_credential` handlers to find the underlying functions (`save_env_value(key, value)` under a `_profile_scope(profile)` context, the delete equivalent, and the validate/connectivity-probe helper) and reuse those directly. Do NOT proxy the Dashboard HTTP server. Do NOT mirror `reveal_env_var`.
- Produces handlers + capability entries:
  - `GET /api/profiles`-style `GET /api/providers` (`providers:read`) → `{"data": [{"slug","label","auth_type","env_vars":[...names...],"configured": bool,"key_hint": "····last4" or null}]}`. `configured`/`key_hint` derived by checking whether each provider's env var is set in the profile scope — WITHOUT returning the value. `key_hint` shows only the last 4 chars of the stored value (the single sanctioned derived disclosure); null when unset.
  - `PUT /api/providers/{slug}/credential` (`providers:write`) body `{"env_var": name, "value": secret}` → validates `env_var` belongs to the provider's descriptor, calls `save_env_value` in the profile scope, returns updated presence for that provider only. Never echoes the value.
  - `DELETE /api/providers/{slug}/credential` (`providers:write`) body/query `{env_var}` → removes it, returns presence.
  - `POST /api/providers/{slug}/credential/validate` (`providers:write`) → runs the existing connectivity/credential probe, returns `{"ok": bool, "detail": <non-secret string>}` — detail must be scrubbed so it never contains the key.

- [ ] **Step 1: Failing tests** — round-trip (set → GET shows `configured:true` + a 4-char hint, value absent from body); unknown slug → 404; env_var not in descriptor → 400; delete clears presence; `providers:read` token denied on PUT/DELETE/validate (403); validate returns ok/detail with the key absent. **Plus the invariant test `test_provider_key_never_escapes`:** set a distinctive key, then assert that key string appears in NONE of: GET /api/providers body, validate detail, the capabilities doc, or any error body. Run: FAIL.
- [ ] **Step 2: Implement** per Produces; extend the capabilities endpoint map. Grep your handler block to confirm no `save_env_value` value or `reveal` is ever serialized.
- [ ] **Step 3: Run** `uv run --extra dev pytest tests/gateway/test_api_providers.py tests/gateway/test_api_server.py -q` + ruff. **Step 4: Commit** `feat(gateway): scoped write-only provider credential contract`.

---

### Task 3: Model catalog, active/aux assignment, cache-first discovery

**Files:**
- Modify: `hermes-agent/gateway/platforms/api_server.py`
- Create: `hermes-agent/tests/gateway/test_api_models.py`

**Interfaces:**
- Consumes: `_authorize`; `hermes_cli.model_catalog.get_catalog(force_refresh=False)` (cache-first; disk cache) and `get_catalog(force_refresh=True)` (live fetch); the model-assignment config writer + `get_auxiliary_models(profile)` — READ the Dashboard `set_model_assignment`/`get_auxiliary_models` handlers (web_server.py ~4282/4393) to find the underlying config functions and the current main-slot reader, and reuse those. `ModelAssignment` shape: `scope` ("main"|"auxiliary"), `task`, `provider`, `model`.
- Produces:
  - `GET /api/models` (`models:read`) → `{"catalog": <cached get_catalog()>, "active": {"provider","model"}, "auxiliary": <get_auxiliary_models(profile)>, "revision": <opaque>}`. NO outbound fetch on this read.
  - `POST /api/models/refresh` (`models:write`) → `get_catalog(force_refresh=True)`, returns the refreshed catalog. The one gated outbound call.
  - `PUT /api/models/assignment` (`models:write`, `If-Match` against the models revision) body `{scope, task?, provider, model}` → writes via the assignment config function in the profile scope, bumps the revision, returns the new active/auxiliary + revision. 428 missing If-Match / 412 stale-no-write, reusing the milestone-0 `_require_if_match` + revision pattern (a `.hermes_api_models_revision` marker or a stat-hash of the model config file — mirror `_compute_profile_revision`).

- [ ] **Step 1: Failing tests** — GET returns cached catalog + active + auxiliary and makes no network call (monkeypatch `get_catalog` to assert `force_refresh=False` on GET); refresh calls `get_catalog(force_refresh=True)`; assignment main slot round-trip changes active; assignment auxiliary slot; missing If-Match → 428; stale → 412 no write; `models:read` denied on refresh/assignment (403). Run: FAIL.
- [ ] **Step 2: Implement** per Produces + capability entries. **Step 3: Run** `uv run --extra dev pytest tests/gateway/test_api_models.py tests/gateway/test_api_server.py -q` + ruff. **Step 4: Commit** `feat(gateway): scoped model catalog, assignment, and gated refresh`.

---

### Task 4: Typed Flutter provider/model client + channel

**Files:**
- Create: `hermes-wing/lib/core/hermes/models/hermes_provider.dart`, `lib/core/hermes/models/hermes_model_assignment.dart`
- Modify: `lib/core/hermes/client/hermes_api_client.dart`, `hermes_api_config.dart`, `hermes_api_transport*.dart` (if a new verb is needed — reuse PUT from milestone 1), `lib/core/hermes/channel/hermes_channel.dart`, `hermes_channel_state.dart`, `hermes_api_channel.dart`, add `lib/core/hermes/channel/api_channel/hermes_api_channel_providers.dart`
- Modify tests: `test/core/hermes/hermes_api_test.dart`, `test/core/hermes/channel/hermes_api_channel_test.dart`, `test/features/hermes_chat/support/fake_hermes_channel.dart`

**Interfaces:**
- Consumes: the Task 2/3 server contract; milestone-1 capability scope-gating (`auth.allows`), `profileScopedUri`, PUT transport, connection-generation guard.
- Produces: `HermesProvider {slug, label, authType, envVars, configured, keyHint}` (keyHint nullable, never a full key); `HermesModelAssignment {activeProvider, activeModel, auxiliary}`; client methods `listProviders`, `setProviderCredential({slug, envVar, value})`, `removeProviderCredential({slug, envVar})`, `validateProviderCredential({slug})`, `listModels`, `refreshModels`, `assignModel({scope, task?, provider, model, revision})`; channel methods mirroring them; `state.providers`, `state.models`. All profile-scoped; assignment sends `If-Match`; refresh is explicit. `HermesProvider.fromJson` discards blank-slug rows; NO field ever holds a full secret.

- [ ] **Step 1: Failing tests** — provider list parse (configured + keyHint, no full key); setProviderCredential sends the value in the request body but the RESULT/state exposes only presence; model list parse; assignModel sends If-Match; refresh hits the refresh endpoint; scope-gating; the two invariants (all provider/model requests carry `?profile=`; a set-credential response/state never contains the sent value). Fake channel gains the seam. Red.
- [ ] **Step 2: Implement.** **Step 3: Run** `cd hermes-wing && flutter test test/core/hermes --concurrency=1` + `flutter analyze lib/core/hermes` + format. **Step 4: Commit** `feat(hermes): typed provider/model client and channel operations`.

---

### Task 5: Providers screen, write-only credential sheet, model picker

**Files:**
- Create: `hermes-wing/lib/features/providers/screens/providers_screen.dart`, `lib/features/providers/widgets/provider_credential_sheet.dart`, `lib/features/providers/widgets/model_picker_sheet.dart`
- Create tests: `test/features/providers/providers_screen_test.dart`, `test/features/providers/provider_credential_sheet_test.dart`
- Modify: `lib/router/routes/app_routes.dart`, `lib/router/providers/app_router.dart`, `lib/shared/widgets/app_shell_presentation.dart`, `lib/l10n/app_en.arb` (+ regenerate), `test/shared/widgets/app_shell_test.dart`

**Interfaces:**
- Consumes: Task 4 channel seam, milestone-1 `/agents` screen pattern (capability-gated mutation visibility, More-overflow destination, l10n).
- Produces: `/providers` route in the More sheet + desktop-direct; provider list with `configured` badges and key-hint; a write-only credential sheet (obscured input, set/remove/validate; NEVER renders an existing key — only the `configured`/hint); a model picker for main + auxiliary slots driving `assignModel`. New app-owned strings in ARB.

- [ ] **Step 1: Failing widget tests** — `Providers` appears in More not the bottom bar; `providers:read` token hides set/remove/validate; the credential sheet never displays a stored key (assert no widget text contains a sentinel key even when `configured:true`); model picker shows catalog and calls assignModel; loading/error/empty; 200% text scale retains actions. Red.
- [ ] **Step 2: Implement** (l10n seam already exists from milestone 1). **Step 3: Run** `flutter gen-l10n && flutter test test/features/providers test/shared/widgets/app_shell_test.dart --concurrency=1 && flutter analyze && flutter build apk --debug`. **Step 4: Commit** `feat(providers): providers screen, write-only credential sheet, model picker`.

---

### Task 6: Milestone-2 receipt, ledger, and docs

**Files:**
- Create: `hermes-agent/tests/gateway/test_milestone2_receipt.py`
- Modify (wing, LEAVE UNCOMMITTED for the user given the dirty-doc entanglement — apply and report, do not stage): `docs/product/hermes-desktop-parity.md`, `docs/product/hermes-compatibility.md`, `docs/product/routes.md`, `docs/security/threat-model.md`

- [ ] **Step 1: End-to-end receipt** — `test_milestone2_receipt.py` mirroring `test_milestone0_receipt.py`: with a scoped `providers:write`+`models:write` token, set a provider credential → validate → GET providers shows configured (value absent) → refresh models → assign a main model with If-Match → GET models shows it active → assert the set key string is absent from every response and the capabilities doc. Run: passes immediately (locks the contract); if any step fails, fix the handler, never the assertion.
- [ ] **Step 2: Full validation** — hermes-agent auth+providers+models suites green + baseline-diff the full `tests/gateway/` for zero new failures; wing `flutter test` + `flutter analyze` + `flutter build apk --debug`.
- [ ] **Step 3: Docs** — apply (do not commit; report as a diff for the user): parity ledger milestone-2 row → `implementing` with a status line and remaining-before-`validated` (on-device receipt); routes `/providers` → implemented; compatibility endpoint/scope table gains the provider/model rows and the write-only-no-reveal note; threat-model gains a provider-key-never-revealed line.
- [ ] **Step 4: Commit** the receipt only (`test(gateway): milestone-2 end-to-end contract receipt`). Report the doc diff separately.
- [ ] **Step 5:** report; merge of both branches and the on-device receipt remain user-gated.
