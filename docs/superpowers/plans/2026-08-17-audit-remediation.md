# Audit Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Address the 2026-08-17 technical audit findings — land the in-flight refactor, tame the HermesApiChannel god-object, retire brittle meta-tests, and harden security-critical parsers — without disturbing unrelated product work.

**Architecture:** Four milestones. M0 lands the current pocket_speech removal and re-establishes a green validation gate. M1 applies two quick correctness fixes. M2 extracts the approvals and session concerns out of the HermesApiChannel part files into injectable services and shrinks the self-referential contract-test surface. M3 adds property-based security tests, enriches lints, and documents channel lifecycle.

**Tech Stack:** Flutter 3.44.x, Dart SDK ^3.12.0, flutter_test, Riverpod 3.x, go_router. No new runtime dependencies. Test-only dependency for M3: fast_check (optional, see Task 3.1).

## Global Constraints

- Hermes Agent remains authoritative; never invent endpoints, scopes, or profile semantics.
- Preserve unrelated dirty-worktree changes; the in-flight pocket_speech removal commits as its own logical change.
- Do not change public HermesChannel interface behavior in M1/M2; extraction is behavior-preserving.
- Never log or persist secrets; the cache-key fix must preserve cross-connection isolation.
- Run the full validation gate (AGENTS.md) after every milestone:
  `dart format --output=none --set-exit-if-changed lib test integration_test`, `flutter analyze`, `flutter test --concurrency=1`, `flutter build web --release -t lib/main_e2e.dart`, `npm run web:e2e`, `npm audit`, `(cd wing_link && go test ./...)`, `git diff --check`.
- Smallest regression test for every non-trivial behavior change.

---

# Milestone 0 — Safety net

## Task 0.1: Land the in-flight pocket_speech removal

**Status:** Implementation complete in the working tree; not yet committed.

**Files:**

- Commit as one logical change: pubspec.yaml, pubspec.lock, the deleted lib/features/voice/services/tts/pocket_speech_* files, lib/features/voice/services/tts/text_to_speech_service.dart, and the platform plugin registrants.

**Context:** The working tree removes the pocket_speech git dependency (a shell-based TTS engine) and replaces it with a _FallbackTtsBackend state machine inside FallbackTextToSpeechService so late audio from a stopped primary can never start after pause/navigation.

- [ ] **Step 1: Verify the tree is green**

Run: `flutter analyze` then `flutter test --concurrency=1`
Expected: 0 issues (or the same single info), All tests passed! (1,199 tests, 1 skip).

- [ ] **Step 2: Commit the refactor on its own branch**

```bash
git checkout -b refactor/remove-pocket-speech
git add -A ':!build' ':!.dart_tool' ':!test-results'
git commit -m "refactor(tts): remove pocket_speech dependency and fallback backend"
```

- [ ] **Step 3: Run the remainder of the gate**

```bash
(cd wing_link && go test ./...)
flutter build web --release -t lib/main_e2e.dart
npm run web:e2e
npm audit
```

Expected: all pass.

- [ ] **Step 4: Merge back to main and verify**

Merge the branch; re-run `flutter test --concurrency=1` on main. Expected: green.

**Acceptance criteria:** The pocket_speech dependency is absent from pubspec.yaml; `grep -rn pocket lib test` returns nothing; full gate green on main.

## Task 0.2: Fix final-profile deletion leaving stale snapshots

**Status:** DONE in this session (the failing test was part of the in-flight worktree).

**Files:**

- Modify: lib/core/hermes/channel/api_channel/hermes_api_channel_profiles.dart:294-296
- Test: test/core/hermes/channel/hermes_api_channel_test.dart:1023-1061 ("deleting the final profile clears every profile-owned snapshot")

**What happened:** _deleteProfile reselected a survivor when one existed but did nothing when the deleted profile was the final one, leaving selectedProfileId, sessions, activeSessionId, messages, providers, and modelInventory pointing at the deleted profile.

**Fix applied:**

```dart
if (_state.selectedProfileId != id) return;
final survivor = _state.profiles.firstOrNull;
if (survivor != null) {
  await _selectProfile(survivor.id);
  return;
}
// Deleting the final profile clears every profile-owned snapshot: there
// is no survivor to reselect, so nothing else may keep pointing at it.
_setState(
  _state.copyWith(
    clearSelectedProfileId: true,
    sessions: const [],
    clearActiveSessionId: true,
    messages: const {},
    providers: const [],
    clearModelInventory: true,
  ),
);
```

- [ ] **Step 1: Verify**

Run: `flutter test --concurrency=1 test/core/hermes/channel/hermes_api_channel_test.dart`
Expected: all channel tests pass (the profile-deletion tests included).

**Acceptance criteria:** The previously failing test passes; the full suite is green.

## Task 0.3: Rerun the complete validation gate and record evidence

**Files:**

- Modify: docs/quality/evidence-matrix.md

- [ ] **Step 1: Run the full gate**

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test --concurrency=1
flutter build web --release -t lib/main_e2e.dart
npm run web:e2e
npm audit
(cd wing_link && go test ./...)
git diff --check
```

- [ ] **Step 2: Refresh the relevant evidence rows**

Update the core-api-chat, profiles, and wing-link rows in docs/quality/evidence-matrix.md with the new worktree identity and evidence date, then run `dart run scripts/check_evidence_matrix.dart`.

Expected: checker passes; no row stale.

**Acceptance criteria:** Every gate command green; evidence matrix current per the checker.

## Task 0.4: Document the vendored forks

**Files:**

- Create: third_party/speech_to_text/CHANGELOG.md, third_party/speech_to_text/README.md, third_party/malsami/README.md

- [ ] **Step 1: Write fork rationale**

For each fork record: upstream repo + pinned commit, the exact patches applied (e.g. Android SpeechToTextPlugin.kt session-generation guards, recognizerToDestroy lifecycle), why the patch was not upstreamed (or the upstream PR number if one exists), and the upgrade path (rebase on upstream releases, or swap when a maintained alternative exists).

- [ ] **Step 2: Add a fork-drift contract test**

Add to test/tooling/: assert that pubspec.yaml pins the documented upstream commit in dependency_overrides and that no fork file diverges from the recorded patch list without a changelog entry.

**Acceptance criteria:** Both forks have rationale + patch inventory; `git diff --stat third_party` is reviewable at a glance.

---

# Milestone 1 — Quick correctness fixes

## Task 1.1: Replace the sha256(apiKey) cache discriminator

**Files:**

- Modify: lib/core/hermes/channel/hermes_api_channel.dart:2-3,108-116

**Why:** _recentTurnKey derives its discriminator from sha256(apiKey). The key is already in memory; hashing a low-entropy credential into a cache key adds no isolation and a heap dump can still recover the key. crypto and dart:convert are imported only for this line (verified: grep shows usage at line 113 only).

**Isolation requirement:** _recentTurns is not cleared on connect(), so the discriminator must change across connections to prevent a new credential on the same base URI from seeing the previous credential cached turns. _connectionGeneration increments on every connect()/reconnect and is stable within a connection — exactly the right discriminator.

- [ ] **Step 1: Write the failing test**

In test/core/hermes/channel/hermes_api_channel_tests/connection_tests.dart:

```dart
test('recent turns never survive a reconnect with a different credential', () async {
  var apiKey = 'key-one';
  final channel = HermesApiChannel(
    clientBuilder: (config) => HermesApiClient(
      config: config,
      get: (uri, headers) async => switch (uri.path) {
        '/health' => '{"status":"ok"}',
        '/v1/capabilities' => _runsCapableCapabilitiesFixture,
        '/api/sessions' => _sessionsFixture,
        '/api/sessions/sess_1/messages' => _messagesFixture,
        _ => throw StateError('unexpected GET $uri'),
      },
    ),
  );
  addTearDown(channel.dispose);
  await channel.connect(baseUrl: 'http://127.0.0.1:8642', apiKey: apiKey);
  await channel.selectSession('sess_1');
  expect(channel.state.activeMessages, isNotEmpty);

  apiKey = 'key-two';
  await channel.disconnect();
  await channel.connect(baseUrl: 'http://127.0.0.1:8642', apiKey: apiKey);
  await channel.selectSession('sess_1');
  // Cached turns under the old credential must not be visible; the GET
  // re-fetches, and if the old cache leaked, stale turns would be served.
  expect(channel.state.activeMessages, isEmpty);
});
```

(Run it first: it should FAIL today if the cache leaks across reconnects — the connection part re-fetches turns on selectSession unless a cached key matches. If it passes today, strengthen the test by asserting the exact fetch count via a counter in the get stub.)

- [ ] **Step 2: Replace the discriminator**

```dart
String _recentTurnKey(
  HermesApiClient client,
  String sessionId, {
  String? profileId,
}) {
  final profile = profileId ?? _state.selectedProfileId ?? 'default';
  return '${client.config.baseUri}|$_connectionGeneration|$profile|$sessionId';
}
```

- [ ] **Step 3: Remove now-unused imports**

Delete `import 'dart:convert';` and `import 'package:crypto/crypto.dart';` from hermes_api_channel.dart if no other usage remains (verify with `grep -n crypto|dart:convert`).

- [ ] **Step 4: Verify**

```bash
flutter analyze
flutter test --concurrency=1 test/core/hermes/channel
```

Expected: no issues; all channel tests pass.

- [ ] **Step 5: Commit**

```bash
git commit -am "fix(channel): use connection generation, not a key hash, for turn cache isolation"
```

**Acceptance criteria:** The new test passes; crypto/dart:convert imports removed if unused; no behavior change for same-connection cache hits.

## Task 1.2: Retire the tautological taxonomy tests

**Files:**

- Delete: test/features/profiles/profiles_screen_taxonomy_test.dart, test/features/hermes_chat/composer/attachments/composer_attachment_taxonomy_test.dart, test/features/hermes_chat/composer/hermes_composer_taxonomy_test.dart, test/features/hermes_chat/presentation/hermes_presentation_taxonomy_test.dart, test/features/hermes_chat/messaging/approvals/hermes_approval_taxonomy_test.dart, test/features/hermes_chat/session/hermes_session_taxonomy_test.dart, test/features/hermes_chat/voice/hermes_voice_taxonomy_test.dart

**Why:** Each asserts only that a constructor returns an instance of its own type (e.g. `expect(const ProfilesScreen(), isA<ProfilesScreen>())`). Zero behavioral value.

- [ ] **Step 1: Verify each taxonomy test has real coverage elsewhere**

For every file above, confirm the feature already has behavioral tests (they all do: profiles_screen_test.dart, composer_attachment tests, etc.). If any feature has ONLY a taxonomy test, replace it with one real widget test instead of deleting.

- [ ] **Step 2: Add one route-resolution test to replace the surface check**

In test/router/app_router_transitions_test.dart add a test that every route constant in lib/router/app_routes.dart resolves to a distinct screen widget under the app router (importing the router provider override used by the existing router tests).

- [ ] **Step 3: Delete the 7 files**

```bash
git rm test/features/profiles/profiles_screen_taxonomy_test.dart test/features/hermes_chat/composer/attachments/composer_attachment_taxonomy_test.dart test/features/hermes_chat/composer/hermes_composer_taxonomy_test.dart test/features/hermes_chat/presentation/hermes_presentation_taxonomy_test.dart test/features/hermes_chat/messaging/approvals/hermes_approval_taxonomy_test.dart test/features/hermes_chat/session/hermes_session_taxonomy_test.dart test/features/hermes_chat/voice/hermes_voice_taxonomy_test.dart
```

- [ ] **Step 4: Verify and commit**

```bash
flutter test --concurrency=1
git commit -am "test: retire tautological taxonomy tests for behavioral coverage"
```

Expected: suite green with the same total behavioral coverage minus 7 empty tests.

**Acceptance criteria:** 7 files deleted; the new route-resolution test passes; no feature lost its only test.

---

# Milestone 2 — Channel service extraction

## Task 2.1: Extract the approvals response concern

**Files:**

- Create: lib/core/hermes/channel/approvals/hermes_approval_responder.dart
- Create: test/core/hermes/channel/approvals/hermes_approval_responder_test.dart
- Modify: lib/core/hermes/channel/hermes_api_channel.dart (remove part 'api_channel/hermes_api_channel_approvals.dart', delegate instead)
- Delete: lib/core/hermes/channel/api_channel/hermes_api_channel_approvals.dart

**Interfaces:**

```dart
/// Resolves and executes approval responses for an active run. Owns the
/// approvalId -> runId mapping so the channel no longer carries it.
class HermesApprovalResponder {
  HermesApprovalResponder();

  final Map<String, String> _approvalRunIds = {};

  /// Registers an approval raised by [runId]. Returns whether this approval
  /// is new (false when already registered).
  bool registerApproval(String approvalId, String runId);

  /// The run that raised [approvalId], or when exactly one run is active,
  /// that run; otherwise null. Mirrors the channel previous resolution.
  String? resolveRunId(String approvalId, Iterable<String> activeRunIds);

  /// Executes the response. [client] must be the currently connected client;
  /// [state] is the channel state at call time (used only for the capability
  /// gate and profile); [reportError] is called with the user-facing message
  /// before rethrowing.
  Future<void> respond({
    required HermesApiClient client,
    required HermesChannelState state,
    required String approvalId,
    required HermesApprovalDecision decision,
    String? selectedProfileId,
    String Function(Object error)? safeError,
    void Function(String message)? reportError,
  });

  bool forgetApproval(String approvalId);
}
```

**Channel delegation** (in hermes_api_channel.dart):

```dart
final HermesApprovalResponder _approvalResponder = HermesApprovalResponder();

@override
Future<void> respondToApproval({
  required String approvalId,
  required HermesApprovalDecision decision,
}) =>
    _respondToApproval(approvalId: approvalId, decision: decision);

Future<void> _respondToApproval({
  required String approvalId,
  required HermesApprovalDecision decision,
}) async {
  final client = _client;
  if (client == null) {
    throw StateError('Hermes channel is not connected.');
  }
  await _approvalResponder.respond(
    client: client,
    state: _state,
    approvalId: approvalId,
    decision: decision,
    selectedProfileId: _state.selectedProfileId,
    safeError: _safeHermesError,
    reportError: (message) =>
        _setState(_state.copyWith(errorMessage: message)),
  );
}
```

**Caller evidence (run transport):** the messaging part registers approvals when approval.request events arrive. Replace `_approvalRunIds[approvalId] = runId` with `_approvalResponder.registerApproval(approvalId, runId)`, and the cleanup on terminal events with `_approvalResponder.forgetApproval(approvalId)`.

- [ ] **Step 1: Move the exact current logic into the responder** (lines 4-54 of the approvals part), parameterizing _client, _state, _setState, and _safeHermesError as above. Keep the runId resolution rule identical.
- [ ] **Step 2: Write responder unit tests** covering: missing approval id; unsupported capability gate (no error reported when capabilities forbid); run resolution via mapping vs single-active-run fallback; success removes the mapping; failure reports the redacted error and rethrows only when the run is still active.
- [ ] **Step 3: Rewire the channel** (delegate + registration sites) and delete the part file.
- [ ] **Step 4: Verify**

```bash
flutter analyze
flutter test --concurrency=1 test/core/hermes/channel
```

Expected: the existing approval tests (approval_stop_tests.dart, hermes_api_channel_test.dart approval cases, hermes_approval_queue_test.dart) all pass unchanged, proving behavior preservation.

- [ ] **Step 5: Commit**

```bash
git commit -am "refactor(channel): extract approval responses into HermesApprovalResponder"
```

**Acceptance criteria:** hermes_api_channel_approvals.dart deleted; approval behavior covered by hermes_approval_responder_test.dart + the unchanged channel tests; channel one part file lighter.

## Task 2.2: Extract the session management concern

**Files:**

- Create: lib/core/hermes/channel/sessions/hermes_session_manager.dart
- Create: test/core/hermes/channel/sessions/hermes_session_manager_test.dart
- Modify: lib/core/hermes/channel/hermes_api_channel.dart (remove part 'api_channel/hermes_api_channel_sessions.dart', delegate)
- Delete: lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart

**Interfaces:**

```dart
/// Session CRUD against the connected client, with operation de-duplication
/// and generation checks supplied by the channel via callbacks.
class HermesSessionManager {
  /// Returns the generation-guarded mutation body. [isCurrent] is checked
  /// after each await so stale responses are dropped.
  Future<void> create({required HermesApiClient client, String? title});
  Future<void> rename({
    required HermesApiClient client,
    required String sessionId,
    required String title,
  });
  Future<void> delete({
    required HermesApiClient client,
    required String sessionId,
  });
  Future<void> fork({
    required HermesApiClient client,
    required String sessionId,
    String? title,
  });
  Future<void> select({
    required HermesApiClient client,
    required String sessionId,
    required String? selectedProfileId,
    required Future<HermesChannelState> Function(String sessionId, String? profileId) loadTurns,
    required void Function(HermesChannelState) apply,
  });
}
```

**Note on seam honesty:** the current session part interleaves turn fetching, detached-run recovery, and stream lifecycle with session selection. Do NOT attempt a full extraction in one task. Scope Task 2.2 to the pure CRUD verbs (create, rename, delete, fork), which already use _deletingSessionOperations/_forkingSessionOperations de-duplication sets. Leave _selectSession (turn + detached-run coupling) in place for a follow-up task if needed; note it in the plan open items.

- [ ] **Step 1: Read the current sessions part** and copy the four CRUD methods into HermesSessionManager, parameterizing the de-duplication sets via an injectable `Set<String> Function()` per operation type so the manager stays stateless.
- [ ] **Step 2: Write manager tests** for create/rename/delete/fork: request shape (uri, method, body, profile query), de-duplication of concurrent identical operations, and 412 handling on rename/delete.
- [ ] **Step 3: Rewire the channel** and delete the part file.
- [ ] **Step 4: Verify** — `flutter analyze` + `flutter test --concurrency=1 test/core/hermes/channel` (session mutation tests must pass unchanged).
- [ ] **Step 5: Commit**

```bash
git commit -am "refactor(channel): extract session CRUD into HermesSessionManager"
```

**Acceptance criteria:** CRUD verbs live outside the channel; session mutation tests pass unchanged; the part file is deleted.

## Task 2.3: Shrink the contract-test surface

**Files:**

- Modify/Delete: test/tooling/ (17 files today)

**Keep (high value, hard to cover behaviorally):**

- package_scripts_contract_test.dart — Waydroid fixture callback ordering (native Kotlin, no Dart seam).
- hermes_readiness_audit_contract_test.dart — readiness script blocker list stays in sync with runbooks.
- evidence_matrix_contract_test.dart — staleness/checker contract.
- wing_link_docs_contract_test.dart and wing_link_distribution_contract_test.dart — Go/docs/release component wiring.

**Convert or delete the rest (12 files):** for each, decide per the deletion test:

1. If the guard is a behavioral invariant expressible in Dart (e.g. redaction ordering, JSON parsing tolerance), move it into a unit test with real inputs.
2. If the guard exists only to keep two docs/scripts textually in sync, and the code under test is exercised by CI anyway, delete it and rely on the workflow that runs the underlying script.
3. If the guard protects a release artifact (installer script contents), keep it but tighten it to semantic assertions rather than exact string positions.

- [ ] **Step 1: Inventory the 17 files** and classify each keep/convert/delete with a one-line reason (record the table in the task commit message).
- [ ] **Step 2: Perform the conversions** — for each convert, write the behavioral unit test first, run it red, then port the assertion.
- [ ] **Step 3: Delete** the delete-classified files and their now-unused fixtures.
- [ ] **Step 4: Verify and commit**

```bash
flutter test --concurrency=1
git commit -am "test: shrink source-contract surface to behavioral coverage"
```

**Acceptance criteria:** test/tooling/ has 3-5 files; every converted behavior has a unit test that fails on the real defect, not on formatting.

---

# Milestone 3 — Hardening

## Task 3.1: Property-based redaction tests

**Files:**

- Create: test/shared/security/wing_redaction_property_test.dart

**Approach:** Add fast_check to dev_dependencies (test-only). If adding the dependency is undesirable, implement the property test with a hand-rolled loop over generated credential shapes (the existing fixtures already enumerate most shapes).

- [ ] **Step 1: Define the invariants**

```dart
test('redaction never leaves a credential in its output', () {
  final samples = <String>[
    'Bearer sk-abcdefgh1234567890',
    'api_key=ABCdef123!@#',
    'https://user:pass@host:8642/path',
    'wss://host/stream?token=SECRET_TOKEN',
    'Authorization: Basic dXNlcjpwYXNz',
    'Hermes API key: sk-proj-0123456789abcdef',
  ];
  for (final sample in samples) {
    final redacted = redactHermesDiagnostics(sample);
    // Every secret-bearing fragment is gone or masked.
    for (final fragment in _fragmentsOf(sample)) {
      expect(redacted, isNot(contains(fragment)));
    }
  }
});
```

(Define _fragmentsOf per shape: token values, URL userinfo, query values.)

- [ ] **Step 2: Fuzz the prefix/suffix trimming invariant**

Redaction must hold under arbitrary truncation: for random prefixes of each sample (or with fast_check over List<String>), redact then truncate must never reintroduce a secret. Port this to a fast_check property if the dependency is added.

- [ ] **Step 3: Verify and commit**

```bash
flutter test --concurrency=1 test/shared/security
git commit -am "test(security): property-test redaction invariants"
```

**Acceptance criteria:** Both invariants pass; the truncation property is a genuine fuzz loop or fast_check property.

## Task 3.2: Property-based URL validation tests

**Files:**

- Create: test/core/hermes/client/hermes_api_config_property_test.dart

- [ ] **Step 1: Define injection-vector properties**

```dart
test('baseUrl rejects every scheme outside http/https', () {
  for (final scheme in ['javascript', 'file', 'data', 'ftp', 'ws', 'wss', 'gopher']) {
    expect(
      () => HermesApiConfig.fromBaseUrl('$scheme://host'),
      throwsArgumentError,
      reason: scheme,
    );
  }
});

test('path segments are trimmed and escaped, never raw', () {
  for (final evil in ['../etc/passwd', 'a/b/../../x', 'sess id', 'x?y=z', 'x#frag']) {
    final uri = HermesApiConfig.fromBaseUrl('http://h').sessionUri(evil);
    expect(uri.pathSegments, isNot(contains('..')));
    expect(uri.toString(), isNot(contains(evil)));
  }
});
```

- [ ] **Step 2: Property test (fast_check, if added)**

fromBaseUrl round-trip: generated valid URLs parse back to the same origin and path; generated invalid strings (blank, no scheme, scheme not http/https, host empty) always throw ArgumentError.

- [ ] **Step 3: Verify and commit**

```bash
flutter test --concurrency=1 test/core/hermes/client
git commit -am "test(security): property-test endpoint URL validation"
```

**Acceptance criteria:** Both tests pass; every vector is rejected or safely escaped.

## Task 3.3: Enrich the linter

**Files:**

- Modify: analysis_options.yaml

- [ ] **Step 1: Add rules, then fix what surfaces**

```yaml
linter:
  rules:
    avoid_print: true
    unawaited_futures: true
    use_build_context_synchronously: true
    always_specify_types: true
    prefer_const_constructors: true
    prefer_const_declarations: true
    no_leading_underscores_for_local_identifiers: true
```

Note: avoid_catches_without_on_clauses is deliberately left off because the codebase intentionally catches broad errors around voice/stream teardown; revisit only if a focused alternative appears.

- [ ] **Step 2: Verify**

```bash
flutter analyze
flutter test --concurrency=1 test/shared test/core/protocol
```

Expected: analyze reports 0 issues (or a documented, justified suppression per fix); tests unaffected.

- [ ] **Step 3: Commit**

```bash
git commit -am "style: enforce types, consts, and leading-underscore lints"
```

**Acceptance criteria:** flutter analyze clean under the enriched config.

## Task 3.4: Document the channel lifecycle

**Files:**

- Create: docs/adr/channel-lifecycle.md (or extend docs/adr/api-and-state.md per the ADR README rule: update an existing decision before adding a new one)

- [ ] **Step 1: Extract the state machine from code**

Enumerate the transitions in hermes_api_channel_connection.dart (disconnected -> connecting -> connected -> error, plus generation invalidation on reconnect) and the profile-selection generation protocol. Document: state fields, which are profile-owned (cleared on final-profile delete per Task 0.2), and the generation checks that drop stale responses.

- [ ] **Step 2: Add a transition table and connect/disconnect invariants**

Include the rule server state wins after reconnect; mutations are never queued or replayed from CONTEXT.md with the code pointer.

- [ ] **Step 3: Cross-link** from docs/adr/README.md and CONTEXT.md.

**Acceptance criteria:** A reviewer can trace any state change to its generation guard; the doc matches the code (verify by reading the connection part file).

---

## Self-Review Notes

- **Spec coverage:** Every audit finding maps to a task: god-object -> 2.1/2.2; meta-tests -> 1.2/2.3; vendored forks -> 0.4; sha256 cache key -> 1.1; property tests -> 3.1/3.2; linter -> 3.3; lifecycle docs -> 3.4; gate verification -> 0.1-0.3.
- **Placeholder scan:** All code blocks are complete. Task 2.2 deliberately leaves _selectSession extraction out (honest seam boundary, recorded in the task).
- **Type consistency:** HermesApprovalResponder.resolveRunId and registerApproval names match their call sites described in Task 2.1; HermesSessionManager method names mirror the current part-file method names (_createSession, _renameSession, _deleteSession, _forkSession).

## Open Items (outside this plan)

- _selectSession remains coupled to turn fetching and detached-run recovery (extend Task 2.2 later).
- APK size impact of sherpa_onnx — measure before release (evidence matrix row).
- Upstream or replace speech_to_text patches (tracked in Task 0.4 fork docs).
