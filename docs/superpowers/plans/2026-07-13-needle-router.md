# Needle Voice-Command Router Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Opt-in on-device routing of voice transcripts to local app commands via the Needle model, per `docs/superpowers/specs/2026-07-13-needle-router-design.md`.

**Architecture:** New `lib/features/voice_commands/` module owns everything Needle (engine promoted from the spike, catalog, validator/snapper, router, dispatcher). `HermesVoiceInputController` gains one injectable seam tried after STT and before draft/submit; the chat screen renders instant snackbars or confirmation chips. Feature is a runtime toggle (default OFF); the engine `.so` ships in every APK via CI.

**Tech Stack:** Flutter/Dart 3.12, dart:ffi (existing vendored binding), Riverpod 3, shared_preferences, flutter_tts, Maestro (on-device verification).

## Global Constraints

- **Augment-only:** the router may only add a local shortcut; it can never block, alter, or replace the Hermes path. Feature OFF ⇒ behavior identical to today. Non-executed paths deliver the transcript where it would have gone anyway.
- **Privacy:** transcripts are never logged (`print`/`debugPrint` forbidden on transcript content) or persisted. Engine options keep `"auto_handoff": false`; `CACTUS_NO_CLOUD_TELE=1` stays set before init.
- **Latency guard:** router resolution has a hard 1.5 s timeout; timeout ⇒ fallthrough.
- **Confidence is ignored by design** (engine pins it at 1.0).
- Work on branch `feat/needle-router` created from current `main`. Stage only files each task names; NEVER `git add -A`. Pre-existing dirty files (CONTEXT.md, README.md, docs/adr/*, etc.) belong to the user — leave untouched.
- Run `flutter analyze` on touched paths and `dart format` on created files before every commit.
- The existing `needle_spike` eval screen keeps working (still gated by `NEEDLE_SPIKE`); it must compile against the promoted module after Task 1.

---

### Task 1: Promote spike core into `lib/features/voice_commands/core/`

**Files:**
- Move (git mv): `lib/features/needle_spike/services/needle_engine.dart` → `lib/features/voice_commands/core/needle_engine.dart`
- Move: `lib/features/needle_spike/services/needle_result.dart` → `lib/features/voice_commands/core/needle_result.dart`
- Move: `lib/features/needle_spike/services/needle_model_install_service.dart` → `lib/features/voice_commands/core/needle_model_install_service.dart`
- Move: `lib/features/needle_spike/ffi/cactus.dart` → `lib/features/voice_commands/ffi/cactus.dart`
- Modify: `lib/features/needle_spike/services/needle_spike_service.dart`, `lib/features/needle_spike/providers/needle_spike_providers.dart`, `lib/features/needle_spike/screens/needle_spike_screen.dart` (imports only)
- Modify: `test/features/needle_spike/*.dart` (imports only); Move: `test/features/needle_spike/needle_result_test.dart` → `test/features/voice_commands/needle_result_test.dart`, `test/features/needle_spike/needle_model_install_service_test.dart` → `test/features/voice_commands/needle_model_install_service_test.dart`, `test/features/needle_spike/native_call_queue_test.dart` → `test/features/voice_commands/native_call_queue_test.dart`

**Interfaces:**
- Consumes: existing spike code (no behavior change).
- Produces: `package:navivox/features/voice_commands/core/needle_engine.dart` exporting `NeedleEngineApi`, `NeedleEngine`, `NeedleEngineException`, `NativeCallQueue`; `core/needle_result.dart` exporting `NeedleResult`, `NeedleFunctionCall`; `core/needle_model_install_service.dart` exporting `NeedleModelInstallService`. The vendored FFI file's relative import inside `needle_engine.dart` becomes `../ffi/cactus.dart`.

- [ ] **Step 1: Create branch and move files**

```bash
git checkout main && git pull --ff-only
git checkout -b feat/needle-router
mkdir -p lib/features/voice_commands/core lib/features/voice_commands/ffi test/features/voice_commands
git mv lib/features/needle_spike/services/needle_engine.dart lib/features/voice_commands/core/needle_engine.dart
git mv lib/features/needle_spike/services/needle_result.dart lib/features/voice_commands/core/needle_result.dart
git mv lib/features/needle_spike/services/needle_model_install_service.dart lib/features/voice_commands/core/needle_model_install_service.dart
git mv lib/features/needle_spike/ffi/cactus.dart lib/features/voice_commands/ffi/cactus.dart
git mv test/features/needle_spike/needle_result_test.dart test/features/voice_commands/needle_result_test.dart
git mv test/features/needle_spike/needle_model_install_service_test.dart test/features/voice_commands/needle_model_install_service_test.dart
git mv test/features/needle_spike/native_call_queue_test.dart test/features/voice_commands/native_call_queue_test.dart
```

- [ ] **Step 2: Fix imports**

In `lib/features/voice_commands/core/needle_engine.dart`: change `import '../ffi/cactus.dart' as cactus;` — the path is unchanged textually but verify it resolves (`core/` → `../ffi/` = `voice_commands/ffi/` ✓).
In the three remaining spike files and the two spike test files (`needle_tool_catalog_test.dart` stays put; `needle_spike_screen_test.dart`, `needle_spike_service_test.dart`), update imports:
- `../services/needle_engine.dart` / `package:navivox/features/needle_spike/services/needle_engine.dart` → `package:navivox/features/voice_commands/core/needle_engine.dart`
- same pattern for `needle_result.dart` and `needle_model_install_service.dart`.
In the three moved test files, update `package:navivox/features/needle_spike/services/...` → `package:navivox/features/voice_commands/core/...`.

- [ ] **Step 3: Run the full moved+spike suite**

Run: `flutter test test/features/voice_commands test/features/needle_spike && flutter analyze lib/features/voice_commands lib/features/needle_spike`
Expected: all tests pass (same counts as before the move), analyze clean. This is a pure refactor — any behavior diff is a bug.

- [ ] **Step 4: Commit**

```bash
git add -A lib/features/voice_commands lib/features/needle_spike test/features/voice_commands test/features/needle_spike
git commit -m "refactor(voice-commands): promote needle engine core out of spike"
```
(`git add -A` scoped to these four directories is the correct way to record the moves; nothing else may be staged.)

---

### Task 2: Command model and catalog

**Files:**
- Create: `lib/features/voice_commands/models/voice_command.dart`
- Create: `lib/features/voice_commands/services/voice_command_catalog.dart`
- Test: `test/features/voice_commands/voice_command_catalog_test.dart`

**Interfaces:**
- Produces:
  - `enum VoiceCommandId { navigateToScreen, showStatus, stopVoiceRun, toggleContinuousMode, startVoiceRun, newSession, switchSession, setTtsVoice, setSpeechRate }` with `String get wireName` (snake_case, e.g. `navigate_to_screen`).
  - `enum VoiceCommandTier { instant, confirm }`
  - `class VoiceRouteResult { VoiceCommandId command; Map<String, Object?> args; VoiceCommandTier tier; String transcript; String describe(); }` — `describe()` returns the human line the chip/snackbar shows (e.g. `Switch to session "groceries"?`).
  - `abstract final class VoiceCommandCatalog { static String toolsJson; static VoiceCommandId? byWireName(String name); }` — the Cactus/OpenAI tools JSON for the nine commands (same schema shapes as the spike catalog, minus `send_message`, which is the fallthrough path by definition).

- [ ] **Step 1: Write the failing test**

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/voice_commands/models/voice_command.dart';
import 'package:navivox/features/voice_commands/services/voice_command_catalog.dart';

void main() {
  test('catalog exposes nine tools whose names round-trip to ids', () {
    final decoded = jsonDecode(VoiceCommandCatalog.toolsJson) as List<dynamic>;
    expect(decoded, hasLength(9));
    for (final tool in decoded) {
      final name =
          ((tool as Map)['function'] as Map)['name'] as String;
      expect(VoiceCommandCatalog.byWireName(name), isNotNull,
          reason: 'unmapped tool $name');
    }
    expect(VoiceCommandCatalog.byWireName('send_message'), isNull);
    expect(VoiceCommandId.navigateToScreen.wireName, 'navigate_to_screen');
  });

  test('describe renders a human-readable action line', () {
    const result = VoiceRouteResult(
      command: VoiceCommandId.switchSession,
      args: {'session_name': 'groceries'},
      tier: VoiceCommandTier.confirm,
      transcript: 'switch to my groceries session',
    );
    expect(result.describe(), 'Switch to session "groceries"?');
    const nav = VoiceRouteResult(
      command: VoiceCommandId.navigateToScreen,
      args: {'screen': 'settings'},
      tier: VoiceCommandTier.instant,
      transcript: 'open the settings screen',
    );
    expect(nav.describe(), 'Opening Settings');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/voice_commands/voice_command_catalog_test.dart`
Expected: FAIL — files don't exist.

- [ ] **Step 3: Implement**

Create `lib/features/voice_commands/models/voice_command.dart`:

```dart
enum VoiceCommandId {
  navigateToScreen('navigate_to_screen'),
  showStatus('show_status'),
  stopVoiceRun('stop_voice_run'),
  toggleContinuousMode('toggle_continuous_mode'),
  startVoiceRun('start_voice_run'),
  newSession('new_session'),
  switchSession('switch_session'),
  setTtsVoice('set_tts_voice'),
  setSpeechRate('set_speech_rate');

  const VoiceCommandId(this.wireName);

  final String wireName;
}

enum VoiceCommandTier { instant, confirm }

/// A validated, snapped, ready-to-dispatch local command. Carrying the
/// original transcript lets decline paths deliver it to Hermes unchanged.
class VoiceRouteResult {
  const VoiceRouteResult({
    required this.command,
    required this.args,
    required this.tier,
    required this.transcript,
  });

  final VoiceCommandId command;
  final Map<String, Object?> args;
  final VoiceCommandTier tier;
  final String transcript;

  String describe() {
    switch (command) {
      case VoiceCommandId.navigateToScreen:
        final screen = args['screen'] == 'settings' ? 'Settings' : 'Hermes';
        return 'Opening $screen';
      case VoiceCommandId.showStatus:
        return 'Showing connection status';
      case VoiceCommandId.stopVoiceRun:
        return 'Stopping voice capture';
      case VoiceCommandId.toggleContinuousMode:
        return args['enabled'] == true
            ? 'Turn on continuous voice?'
            : 'Turning off continuous voice';
      case VoiceCommandId.startVoiceRun:
        return 'Start listening?';
      case VoiceCommandId.newSession:
        return 'Start a new session?';
      case VoiceCommandId.switchSession:
        return 'Switch to session "${args['session_name']}"?';
      case VoiceCommandId.setTtsVoice:
        return 'Use voice "${args['voice']}"?';
      case VoiceCommandId.setSpeechRate:
        return 'Set speech rate to ${args['rate']}?';
    }
  }
}
```

Create `lib/features/voice_commands/services/voice_command_catalog.dart` — identical schema style to the spike's `NeedleToolCatalog` (`{'type': 'function', 'function': {name, description, parameters}}`), with these nine entries and a lookup:

```dart
import 'dart:convert';

import '../models/voice_command.dart';

/// Real command surface offered to Needle. `send_message` is intentionally
/// absent: unmatched transcripts fall through to Hermes, which IS the send
/// path — modeling it as a tool would only invite wrong-tool swallowing.
abstract final class VoiceCommandCatalog {
  static Map<String, dynamic> _tool(
    String name,
    String description,
    Map<String, dynamic> properties,
    List<String> required,
  ) {
    return {
      'type': 'function',
      'function': {
        'name': name,
        'description': description,
        'parameters': {
          'type': 'object',
          'properties': properties,
          'required': required,
        },
      },
    };
  }

  static final List<Map<String, dynamic>> tools = [
    _tool('navigate_to_screen', 'Open one of the app screens.', {
      'screen': {
        'type': 'string',
        'enum': ['hermes', 'settings'],
        'description': 'Which screen to open.',
      },
    }, ['screen']),
    _tool('show_status', 'Show the agent connection status.', {}, []),
    _tool('stop_voice_run', 'Stop listening / stop the current voice capture.',
        {}, []),
    _tool('toggle_continuous_mode',
        'Turn hands-free continuous voice mode on or off.', {
      'enabled': {
        'type': 'boolean',
        'description': 'true to enable continuous mode.',
      },
    }, ['enabled']),
    _tool('start_voice_run', 'Start listening for the next voice command.',
        {}, []),
    _tool('new_session', 'Start a fresh chat session.', {}, []),
    _tool('switch_session', 'Switch to a named chat session.', {
      'session_name': {
        'type': 'string',
        'description': 'Name of the session to switch to.',
      },
    }, ['session_name']),
    _tool('set_tts_voice', 'Change the text-to-speech voice.', {
      'voice': {'type': 'string', 'description': 'Voice name to use.'},
    }, ['voice']),
    _tool('set_speech_rate', 'Change how fast replies are read aloud.', {
      'rate': {
        'type': 'number',
        'description': 'Speech rate multiplier; 1.0 is normal.',
      },
    }, ['rate']),
  ];

  static final String toolsJson = jsonEncode(tools);

  static final Map<String, VoiceCommandId> _byWire = {
    for (final id in VoiceCommandId.values) id.wireName: id,
  };

  static VoiceCommandId? byWireName(String name) => _byWire[name];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/voice_commands/voice_command_catalog_test.dart`
Expected: 2 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/voice_commands/models/voice_command.dart lib/features/voice_commands/services/voice_command_catalog.dart test/features/voice_commands/voice_command_catalog_test.dart
git commit -m "feat(voice-commands): command model and real tool catalog"
```

---

### Task 3: Validator and arg snapping

**Files:**
- Create: `lib/features/voice_commands/services/voice_command_validator.dart`
- Test: `test/features/voice_commands/voice_command_validator_test.dart`

**Interfaces:**
- Consumes: `VoiceCommandId`, `VoiceCommandTier`, `VoiceRouteResult`, `VoiceCommandCatalog.byWireName` (Task 2); `NeedleFunctionCall` (Task 1).
- Produces:
  - `class VoiceCommandContext { const VoiceCommandContext({required this.sessionTitles, required this.voiceNames}); final List<String> sessionTitles; final List<String> voiceNames; }` — live candidates supplied by the caller at validation time.
  - `abstract final class VoiceCommandValidator { static VoiceRouteResult? validate(NeedleFunctionCall call, {required String transcript, required VoiceCommandContext context}); }` — returns null (fallthrough) for unknown tools, missing/unsnappable args; otherwise a snapped `VoiceRouteResult` with the correct tier. Tier rule: `toggle_continuous_mode` is instant when `enabled == false`, confirm when true; `navigate_to_screen`, `show_status`, `stop_voice_run` instant; everything else confirm.
  - Snapping rules (all case-insensitive, whitespace-normalized):
    - enum snap: exact → else token-containment (`"settings screen"` contains token `settings` → `settings`); ambiguous/no hit → null.
    - boolean: accepts bool, `"true"/"false"`, `"on"/"off"`.
    - rate: num or numeric string; clamped to 0.25–3.0; non-numeric → null.
    - `session_name`: fuzzy against `context.sessionTitles` — exact (normalized) → else unique title containing the spoken words or vice versa → else null. Snapped value is the REAL title.
    - `voice`: same fuzzy rule against `context.voiceNames`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/voice_commands/core/needle_result.dart';
import 'package:navivox/features/voice_commands/models/voice_command.dart';
import 'package:navivox/features/voice_commands/services/voice_command_validator.dart';

void main() {
  const context = VoiceCommandContext(
    sessionTitles: ['groceries', 'work notes', 'holiday plans'],
    voiceNames: ['en-GB-standard', 'nova', 'en-US-standard'],
  );

  VoiceRouteResult? run(String name, Map<String, Object?> args) {
    return VoiceCommandValidator.validate(
      NeedleFunctionCall(name: name, arguments: args),
      transcript: 't',
      context: context,
    );
  }

  test('unknown tool falls through', () {
    expect(run('send_message', {'text': 'hi'}), isNull);
    expect(run('made_up_tool', {}), isNull);
  });

  test('enum snapping repairs off-enum echo', () {
    final r = run('navigate_to_screen', {'screen': 'settings screen'});
    expect(r!.args['screen'], 'settings');
    expect(r.tier, VoiceCommandTier.instant);
    expect(run('navigate_to_screen', {'screen': 'kitchen'}), isNull);
  });

  test('toggle tier depends on direction and accepts on/off strings', () {
    expect(run('toggle_continuous_mode', {'enabled': 'off'})!.tier,
        VoiceCommandTier.instant);
    expect(run('toggle_continuous_mode', {'enabled': true})!.tier,
        VoiceCommandTier.confirm);
    expect(run('toggle_continuous_mode', {'enabled': 'maybe'}), isNull);
  });

  test('rate parses and clamps; junk falls through', () {
    expect(run('set_speech_rate', {'rate': 0.5})!.args['rate'], 0.5);
    expect(run('set_speech_rate', {'rate': '9'})!.args['rate'], 3.0);
    expect(run('set_speech_rate', {'rate': 'faster'}), isNull);
  });

  test('session fuzzy-snaps to a real title or falls through', () {
    expect(run('switch_session', {'session_name': 'Groceries'})!
        .args['session_name'], 'groceries');
    expect(run('switch_session', {'session_name': 'work'})!
        .args['session_name'], 'work notes');
    expect(run('switch_session', {'session_name': 'poetry'}), isNull);
  });

  test('voice fuzzy-snaps; the spike wrong-tool artifact falls through', () {
    expect(run('set_tts_voice', {'voice': 'nova'})!.args['voice'], 'nova');
    // The spike produced set_tts_voice{voice: faster} for "speak faster
    // please" — an unresolvable voice must fall through, not execute.
    expect(run('set_tts_voice', {'voice': 'faster'}), isNull);
  });

  test('no-arg commands validate to their tier', () {
    expect(run('show_status', {})!.tier, VoiceCommandTier.instant);
    expect(run('new_session', {})!.tier, VoiceCommandTier.confirm);
    expect(run('start_voice_run', {})!.tier, VoiceCommandTier.confirm);
    expect(run('stop_voice_run', {})!.tier, VoiceCommandTier.instant);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/voice_commands/voice_command_validator_test.dart`
Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Implement**

```dart
import '../core/needle_result.dart';
import '../models/voice_command.dart';
import 'voice_command_catalog.dart';

/// Live snap candidates. Supplied fresh per validation so session titles and
/// installed voices are never cached stale.
class VoiceCommandContext {
  const VoiceCommandContext({
    required this.sessionTitles,
    required this.voiceNames,
  });

  final List<String> sessionTitles;
  final List<String> voiceNames;
}

/// Guardrail layer: unknown tool or unsnappable args return null, which the
/// router treats as fallthrough-to-Hermes. Nothing here throws.
abstract final class VoiceCommandValidator {
  static VoiceRouteResult? validate(
    NeedleFunctionCall call, {
    required String transcript,
    required VoiceCommandContext context,
  }) {
    final id = VoiceCommandCatalog.byWireName(call.name);
    if (id == null) return null;
    final args = <String, Object?>{};
    switch (id) {
      case VoiceCommandId.navigateToScreen:
        final screen =
            _snapEnum(call.arguments['screen'], const ['hermes', 'settings']);
        if (screen == null) return null;
        args['screen'] = screen;
      case VoiceCommandId.toggleContinuousMode:
        final enabled = _snapBool(call.arguments['enabled']);
        if (enabled == null) return null;
        args['enabled'] = enabled;
      case VoiceCommandId.setSpeechRate:
        final rate = _snapRate(call.arguments['rate']);
        if (rate == null) return null;
        args['rate'] = rate;
      case VoiceCommandId.switchSession:
        final title =
            _snapFuzzy(call.arguments['session_name'], context.sessionTitles);
        if (title == null) return null;
        args['session_name'] = title;
      case VoiceCommandId.setTtsVoice:
        final voice = _snapFuzzy(call.arguments['voice'], context.voiceNames);
        if (voice == null) return null;
        args['voice'] = voice;
      case VoiceCommandId.showStatus:
      case VoiceCommandId.stopVoiceRun:
      case VoiceCommandId.startVoiceRun:
      case VoiceCommandId.newSession:
        break;
    }
    return VoiceRouteResult(
      command: id,
      args: args,
      tier: _tierFor(id, args),
      transcript: transcript,
    );
  }

  static VoiceCommandTier _tierFor(VoiceCommandId id, Map<String, Object?> args) {
    switch (id) {
      case VoiceCommandId.navigateToScreen:
      case VoiceCommandId.showStatus:
      case VoiceCommandId.stopVoiceRun:
        return VoiceCommandTier.instant;
      case VoiceCommandId.toggleContinuousMode:
        return args['enabled'] == false
            ? VoiceCommandTier.instant
            : VoiceCommandTier.confirm;
      case VoiceCommandId.startVoiceRun:
      case VoiceCommandId.newSession:
      case VoiceCommandId.switchSession:
      case VoiceCommandId.setTtsVoice:
      case VoiceCommandId.setSpeechRate:
        return VoiceCommandTier.confirm;
    }
  }

  static String _normalize(Object? value) =>
      '$value'.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static String? _snapEnum(Object? raw, List<String> allowed) {
    if (raw == null) return null;
    final v = _normalize(raw);
    if (allowed.contains(v)) return v;
    final hits = allowed
        .where((a) => v.split(' ').contains(a) || a.split(' ').contains(v))
        .toList();
    return hits.length == 1 ? hits.single : null;
  }

  static bool? _snapBool(Object? raw) {
    if (raw is bool) return raw;
    switch (_normalize(raw)) {
      case 'true' || 'on':
        return true;
      case 'false' || 'off':
        return false;
      default:
        return null;
    }
  }

  static double? _snapRate(Object? raw) {
    final value = raw is num ? raw.toDouble() : double.tryParse('$raw'.trim());
    if (value == null) return null;
    return value.clamp(0.25, 3.0);
  }

  static String? _snapFuzzy(Object? raw, List<String> candidates) {
    if (raw == null) return null;
    final v = _normalize(raw);
    if (v.isEmpty) return null;
    final exact =
        candidates.where((c) => _normalize(c) == v).toList();
    if (exact.length == 1) return exact.single;
    final partial = candidates
        .where((c) =>
            _normalize(c).contains(v) || v.contains(_normalize(c)))
        .toList();
    return partial.length == 1 ? partial.single : null;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/voice_commands/voice_command_validator_test.dart`
Expected: 7 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/voice_commands/services/voice_command_validator.dart test/features/voice_commands/voice_command_validator_test.dart
git commit -m "feat(voice-commands): validator with enum/bool/rate/fuzzy snapping"
```

---

### Task 4: VoiceCommandRouter (engine orchestration, timeout, auto-suspend)

**Files:**
- Create: `lib/features/voice_commands/services/voice_command_router.dart`
- Test: `test/features/voice_commands/voice_command_router_test.dart`

**Interfaces:**
- Consumes: `NeedleEngineApi` + `NeedleResult.fromEngineJson` (Task 1), `VoiceCommandCatalog.toolsJson` (Task 2), `VoiceCommandValidator.validate` + `VoiceCommandContext` (Task 3).
- Produces: `class VoiceCommandRouter { VoiceCommandRouter({required NeedleEngineApi engine, required Future<String?> Function() modelDirProvider, required VoiceCommandContext Function() contextProvider, Duration timeout = const Duration(milliseconds: 1500)}); Future<VoiceRouteResult?> route(String transcript); bool get suspended; }`
  - `route` returns null when: transcript empty; model dir null (not installed); engine load/complete fails; timeout elapses; parse yields no/invalid call; router is suspended.
  - Engine options: `'{"max_tokens": 128, "temperature": 0, "force_tools": true, "tool_rag_top_k": 0, "auto_handoff": false}'` (verbatim from the spike).
  - Auto-suspend: 3 engine failures (exception or `success == false`) in the router's lifetime set `suspended = true`; every later `route` returns null immediately. Timeouts do NOT count as failures (slow ≠ broken).
  - Serialization: one in-flight route at a time; a second call while busy returns null immediately (voice input is serialized upstream anyway; never queue).

- [ ] **Step 1: Write the failing test**

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/voice_commands/core/needle_engine.dart';
import 'package:navivox/features/voice_commands/models/voice_command.dart';
import 'package:navivox/features/voice_commands/services/voice_command_router.dart';
import 'package:navivox/features/voice_commands/services/voice_command_validator.dart';

class _ScriptedEngine implements NeedleEngineApi {
  _ScriptedEngine(this.responses);

  final List<Future<String> Function()> responses;
  int calls = 0;
  bool loaded = false;

  @override
  bool get isLoaded => loaded;

  @override
  Future<void> load(String modelDir) async => loaded = true;

  @override
  Future<String> complete({
    required String messagesJson,
    required String toolsJson,
    required String optionsJson,
  }) {
    return responses[calls++ % responses.length]();
  }

  @override
  Future<void> unload() async => loaded = false;
}

const _statusCall =
    '{"success": true, "response": "", "function_calls": '
    '[{"name": "show_status", "arguments": {}}]}';

VoiceCommandRouter _router(NeedleEngineApi engine,
        {Duration timeout = const Duration(milliseconds: 1500)}) =>
    VoiceCommandRouter(
      engine: engine,
      modelDirProvider: () async => '/model',
      contextProvider: () =>
          const VoiceCommandContext(sessionTitles: [], voiceNames: []),
      timeout: timeout,
    );

void main() {
  test('routes a valid call to a snapped result', () async {
    final router = _router(_ScriptedEngine([() async => _statusCall]));
    final result = await router.route('is the agent connected');
    expect(result!.command, VoiceCommandId.showStatus);
    expect(result.transcript, 'is the agent connected');
  });

  test('uninstalled model returns null without touching the engine', () async {
    final engine = _ScriptedEngine([() async => _statusCall]);
    final router = VoiceCommandRouter(
      engine: engine,
      modelDirProvider: () async => null,
      contextProvider: () =>
          const VoiceCommandContext(sessionTitles: [], voiceNames: []),
    );
    expect(await router.route('is the agent connected'), isNull);
    expect(engine.calls, 0);
  });

  test('timeout falls through and does not count toward suspension', () async {
    final never = Completer<String>();
    final router = _router(
      _ScriptedEngine([() => never.future]),
      timeout: const Duration(milliseconds: 50),
    );
    expect(await router.route('anything'), isNull);
    expect(router.suspended, isFalse);
  });

  test('three engine failures suspend the router', () async {
    final router = _router(
      _ScriptedEngine([() async => throw const NeedleEngineException('boom')]),
    );
    for (var i = 0; i < 3; i++) {
      expect(await router.route('x'), isNull);
    }
    expect(router.suspended, isTrue);
    final engine2 = _ScriptedEngine([() async => _statusCall]);
    // Suspended router short-circuits even with a healthy engine call queue.
    expect(await router.route('is the agent connected'), isNull);
  });

  test('concurrent route returns null for the second caller', () async {
    final gate = Completer<String>();
    final engine = _ScriptedEngine([() => gate.future]);
    final router = _router(engine);
    final first = router.route('one');
    expect(await router.route('two'), isNull);
    gate.complete(_statusCall);
    expect((await first)!.command, VoiceCommandId.showStatus);
    expect(engine.calls, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/voice_commands/voice_command_router_test.dart`
Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Implement**

```dart
import 'dart:async';
import 'dart:convert';

import '../core/needle_engine.dart';
import '../core/needle_result.dart';
import '../models/voice_command.dart';
import 'voice_command_catalog.dart';
import 'voice_command_validator.dart';

/// Turns one transcript into at most one validated local command. Every
/// abnormal path returns null — the caller then routes to Hermes unchanged.
class VoiceCommandRouter {
  VoiceCommandRouter({
    required NeedleEngineApi engine,
    required Future<String?> Function() modelDirProvider,
    required VoiceCommandContext Function() contextProvider,
    this.timeout = const Duration(milliseconds: 1500),
  })  : _engine = engine,
        _modelDirProvider = modelDirProvider,
        _contextProvider = contextProvider;

  static const String optionsJson =
      '{"max_tokens": 128, "temperature": 0, "force_tools": true, '
      '"tool_rag_top_k": 0, "auto_handoff": false}';

  static const int _maxFailures = 3;

  final NeedleEngineApi _engine;
  final Future<String?> Function() _modelDirProvider;
  final VoiceCommandContext Function() _contextProvider;
  final Duration timeout;

  bool _busy = false;
  int _failures = 0;

  bool get suspended => _failures >= _maxFailures;

  Future<VoiceRouteResult?> route(String transcript) async {
    final trimmed = transcript.trim();
    if (trimmed.isEmpty || suspended || _busy) return null;
    _busy = true;
    try {
      final modelDir = await _modelDirProvider();
      if (modelDir == null) return null;
      final raw = await _complete(trimmed, modelDir).timeout(timeout);
      if (raw == null) return null;
      final parsed = NeedleResult.fromEngineJson(raw, wallLatencyMs: 0);
      if (!parsed.success) {
        _failures += 1;
        return null;
      }
      if (parsed.functionCalls.isEmpty) return null;
      return VoiceCommandValidator.validate(
        parsed.functionCalls.first,
        transcript: trimmed,
        context: _contextProvider(),
      );
    } on TimeoutException {
      return null;
    } on Exception {
      _failures += 1;
      return null;
    } finally {
      _busy = false;
    }
  }

  Future<String?> _complete(String transcript, String modelDir) async {
    if (!_engine.isLoaded) {
      await _engine.load(modelDir);
    }
    return _engine.complete(
      messagesJson: jsonEncode([
        {'role': 'user', 'content': transcript},
      ]),
      toolsJson: VoiceCommandCatalog.toolsJson,
      optionsJson: optionsJson,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/voice_commands/voice_command_router_test.dart`
Expected: 5 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/voice_commands/services/voice_command_router.dart test/features/voice_commands/voice_command_router_test.dart
git commit -m "feat(voice-commands): router with timeout, busy-guard, auto-suspend"
```

---

### Task 5: Settings model — voiceCommandsEnabled, speechRate, ttsVoiceName

**Files:**
- Modify: `lib/shared/voice/voice_settings.dart` (NavivoxVoiceSettings)
- Modify: `lib/features/settings/providers/voice_settings_provider.dart`
- Test: `test/features/settings/voice_command_settings_test.dart` (new)

**Interfaces:**
- Consumes: existing `NavivoxVoiceSettings` (fields `continuousVoiceEnabled`, `speakRepliesEnabled`, `pocketSpeechTtsEnabled`, `pocketSpeechModel`, `pocketSpeechVoicePack`, `commandWord`) and `NavivoxVoiceSettingsController extends Notifier<NavivoxVoiceSettings>` with its `_loadPrefs`/`_save` shared_preferences pattern (READ BOTH FILES FIRST and mirror their exact style, including `copyWith` if present).
- Produces: `NavivoxVoiceSettings` gains `bool voiceCommandsEnabled` (default `false`), `double speechRate` (default `1.0`), `String? ttsVoiceName` (default null) — wired through constructor, `copyWith`, and prefs persistence with keys `voice_commands_enabled`, `tts_speech_rate`, `tts_voice_name`. Controller gains `void setVoiceCommandsEnabled(bool)`, `void setSpeechRate(double)` (clamp 0.25–3.0 before storing), `void setTtsVoiceName(String?)` — each updating state and calling `_save()` exactly like the existing setters.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/settings/providers/voice_settings_provider.dart';
import 'package:navivox/shared/voice/voice_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults: router off, rate 1.0, no voice', () {
    const s = NavivoxVoiceSettings();
    expect(s.voiceCommandsEnabled, isFalse);
    expect(s.speechRate, 1.0);
    expect(s.ttsVoiceName, isNull);
  });

  test('setters persist and clamp', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller =
        container.read(navivoxVoiceSettingsProvider.notifier);
    await container.read(navivoxVoiceSettingsProvider.notifier).ready;
    controller.setVoiceCommandsEnabled(true);
    controller.setSpeechRate(9.0);
    controller.setTtsVoiceName('nova');
    final state = container.read(navivoxVoiceSettingsProvider);
    expect(state.voiceCommandsEnabled, isTrue);
    expect(state.speechRate, 3.0);
    expect(state.ttsVoiceName, 'nova');
  });
}
```

Adaptation allowance: if the controller exposes no `ready` future for prefs loading, follow whatever synchronization the existing settings tests use (check `test/features/settings/` first); asserted behaviors stay identical.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/settings/voice_command_settings_test.dart`
Expected: FAIL — fields don't exist (compile error).

- [ ] **Step 3: Implement**

In `NavivoxVoiceSettings`: add the three fields to the constructor (with defaults above), field declarations, and `copyWith`. In the controller: add the three setters and extend `_loadPrefs`/`_save` with the three keys, mirroring existing lines exactly (e.g. `prefs.getBool('voice_commands_enabled') ?? false`). Store `speechRate` via `prefs.setDouble`, `ttsVoiceName` via `setString` (remove the key when null).

- [ ] **Step 4: Run tests**

Run: `flutter test test/features/settings && flutter analyze lib/shared/voice lib/features/settings`
Expected: new + existing settings tests pass, analyze clean.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/voice/voice_settings.dart lib/features/settings/providers/voice_settings_provider.dart test/features/settings/voice_command_settings_test.dart
git commit -m "feat(voice-commands): settings fields for router toggle, rate, voice"
```

---

### Task 6: TTS engine bindings — voice list and applied rate/voice

**Files:**
- Modify: `lib/features/voice/services/tts/text_to_speech_service.dart`
- Test: `test/features/voice/tts_voice_binding_test.dart` (new)

**Interfaces:**
- Consumes: existing `FlutterTtsEngine` abstract interface (has `setSpeechRate(double)`, `speak(String)`, `setLanguage`, `setVolume`...) and its `PluginFlutterTtsEngine` impl wrapping `FlutterTts`; `NavivoxVoiceSettings.speechRate/ttsVoiceName` (Task 5). READ THE FILE FIRST — there is a concrete TTS service class in it that calls the engine before speaking; apply settings there.
- Produces:
  - `FlutterTtsEngine` gains `Future<List<String>> voiceNames();` and `Future<void> setVoiceByName(String name);`. `PluginFlutterTtsEngine` implements them via `_flutterTts.getVoices` (list of maps with `name`/`locale`; return the `name` values as `List<String>`) and `_flutterTts.setVoice({'name': name, 'locale': <locale for that name>})` (cache the voices list to resolve locale).
  - The flutter_tts-backed `TextToSpeechService` implementation in this file applies, before each `speak`: `engine.setSpeechRate((0.5 * settings.speechRate).clamp(0.0, 1.0))` (flutter_tts's normalized scale, 0.5 = normal) and, when `settings.ttsVoiceName != null`, `engine.setVoiceByName(settings.ttsVoiceName!)` guarded by try/catch (a bad voice name must not break speech). It already receives settings or must gain a `VoiceSettingsReader settings` parameter following the file's existing reader-injection style.
  - Produces for Task 7: the voice-name list source is `FlutterTtsEngine.voiceNames()`.

- [ ] **Step 1: Write the failing test** (fake engine records calls)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/voice/services/tts/text_to_speech_service.dart';
import 'package:navivox/shared/voice/voice_settings.dart';

class _RecordingEngine implements FlutterTtsEngine {
  final calls = <String>[];
  // Implement every FlutterTtsEngine member: record invocations like
  // calls.add('rate:0.75') / calls.add('voice:nova') / calls.add('speak');
  // voiceNames() returns ['nova', 'en-GB-standard'].
  // (Write the full override set against the real interface when
  // implementing; noSuchMethod is forbidden — keep it explicit.)
}

void main() {
  test('speak applies clamped rate and voice before speaking', () async {
    final engine = _RecordingEngine();
    final service = buildFlutterTtsService(
      engine: engine,
      settings: () => const NavivoxVoiceSettings(
        speechRate: 1.5,
        ttsVoiceName: 'nova',
      ),
    );
    await service.speak('hello');
    expect(engine.calls, containsAllInOrder(['rate:0.75', 'voice:nova', 'speak']));
  });

  test('unknown voice is swallowed, speech still happens', () async {
    final engine = _RecordingEngine()..failVoice = true;
    final service = buildFlutterTtsService(
      engine: engine,
      settings: () =>
          const NavivoxVoiceSettings(ttsVoiceName: 'ghost'),
    );
    await service.speak('hello');
    expect(engine.calls, contains('speak'));
  });
}
```

Adaptation allowance: `buildFlutterTtsService` stands for however the file actually constructs its flutter_tts-backed `TextToSpeechService` (factory/constructor name per the real file — read it first, keep the two asserted behaviors identical, add `failVoice` as a bool on the fake that makes `setVoiceByName` throw).

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/voice/tts_voice_binding_test.dart`
Expected: FAIL — new members missing.

- [ ] **Step 3: Implement** per Produces above. Any other existing `FlutterTtsEngine` implementations/fakes in lib/ or test/ gain the two members (grep `implements FlutterTtsEngine`).

- [ ] **Step 4: Run tests**

Run: `flutter test test/features/voice && flutter analyze lib/features/voice`
Expected: all pass, clean.

- [ ] **Step 5: Commit**

```bash
git add lib/features/voice/services/tts/text_to_speech_service.dart test/features/voice/tts_voice_binding_test.dart
git commit -m "feat(voice-commands): tts voice enumeration and applied rate/voice"
```

---

### Task 7: CommandDispatcher

**Files:**
- Create: `lib/features/voice_commands/services/voice_command_dispatcher.dart`
- Test: `test/features/voice_commands/voice_command_dispatcher_test.dart`

**Interfaces:**
- Consumes: `VoiceRouteResult`/`VoiceCommandId` (Task 2); `HermesChannel.createSession({String? title})`, `selectSession(String sessionId)`, `state.sessions` (`HermesSession{id, title, ...}`); `NavivoxVoiceSettingsController.setContinuousVoiceEnabled/setSpeechRate/setTtsVoiceName` (Task 5).
- Produces:

```dart
class VoiceCommandDispatcher {
  VoiceCommandDispatcher({
    required HermesChannel Function() channel,
    required void Function(String path) navigate,
    required NavivoxVoiceSettingsController Function() settings,
    required void Function(String message) showNotice,
    required void Function() stopVoiceCapture,
    required void Function() startVoiceCapture,
  });

  Future<void> dispatch(VoiceRouteResult result);
}
```

  - `navigate_to_screen` → `navigate(args['screen'] == 'settings' ? AppRoutes.settings : AppRoutes.hermes)`
  - `show_status` → `showNotice(<connection line from channel().state — 'Connected' / 'Disconnected' plus model name if present>)`
  - `stop_voice_run` → `stopVoiceCapture()`; `start_voice_run` → `startVoiceCapture()`
  - `toggle_continuous_mode` → `settings().setContinuousVoiceEnabled(args['enabled'] as bool)` + notice
  - `new_session` → `await channel().createSession()` + notice
  - `switch_session` → resolve `args['session_name']` (already a REAL title from the validator) to its `HermesSession.id` via `channel().state.sessions` (normalized title equality); not found (race) → `showNotice('Session no longer exists.')`; else `await channel().selectSession(id)`
  - `set_tts_voice` → `settings().setTtsVoiceName(args['voice'] as String)` + notice
  - `set_speech_rate` → `settings().setSpeechRate(args['rate'] as double)` + notice
  - Every dispatch wraps its body in try/catch → `showNotice('Command failed: <e.runtimeType>')` (no transcript content).

- [ ] **Step 1: Write the failing test** — fakes for channel (reuse `FakeHermesChannel` from `test/features/hermes_chat/support/fake_hermes_channel.dart` if it records `createSession`/`selectSession`; extend it there if not — check first), a recording settings controller (subclass in test overriding the three setters to record), recorded `navigate`/`showNotice`/`stop`/`start` closures. Cover: navigate-to-settings path string; new_session calls channel; switch_session resolves title→id and unknown title notices; toggle calls setter with false; rate/voice reach setters; a throwing channel surfaces as a notice, never a throw.

```dart
// Test skeleton (complete per the fakes above):
test('switch_session resolves real title to session id', () async {
  final channel = FakeHermesChannel()
    ..seedSessions([HermesSession(id: 's1', source: 'x', title: 'groceries')]);
  String? selected;
  channel.onSelectSession = (id) => selected = id;
  final dispatcher = _dispatcher(channel: channel);
  await dispatcher.dispatch(const VoiceRouteResult(
    command: VoiceCommandId.switchSession,
    args: {'session_name': 'groceries'},
    tier: VoiceCommandTier.confirm,
    transcript: 't',
  ));
  expect(selected, 's1');
});
```

(Write the full suite — one test per command binding plus the error-notice case; `_dispatcher` is a local helper wiring all fakes.)

- [ ] **Step 2: Run to verify it fails** — `flutter test test/features/voice_commands/voice_command_dispatcher_test.dart` → FAIL (file missing).

- [ ] **Step 3: Implement** per the Produces table. Import `AppRoutes` from `package:navivox/router/app_routes.dart`.

- [ ] **Step 4: Run tests** — dispatcher suite + `flutter analyze lib/features/voice_commands` → all green.

- [ ] **Step 5: Commit**

```bash
git add lib/features/voice_commands/services/voice_command_dispatcher.dart test/features/voice_commands/voice_command_dispatcher_test.dart test/features/hermes_chat/support/fake_hermes_channel.dart
git commit -m "feat(voice-commands): dispatcher binding commands to app services"
```

---

### Task 8: Controller seam in HermesVoiceInputController

**Files:**
- Modify: `lib/features/hermes_chat/controllers/hermes_voice_input_controller.dart`
- Test: extend `test/features/hermes_chat/controllers/hermes_voice_input_controller_test.dart`

**Interfaces:**
- Consumes: `VoiceRouteResult` (Task 2). The controller today (READ IT FIRST): `_capture({required bool autoSend})` branches on `HermesVoiceCaptureStatus.captured` — draft path calls `_onDraft(transcript)`, autoSend path calls `_handleLocalCommand(transcript)` (commandWord stop-words) then `startVoiceRun`/`stageVoiceRunTranscript`/`submitVoiceRun`.
- Produces: two new optional constructor readers, threaded through the factory exactly like existing ones:

```dart
typedef VoiceTranscriptRouter = Future<VoiceRouteResult?> Function(String transcript);
// New factory params (both nullable, default null — feature off ⇒ identical behavior):
//   VoiceTranscriptRouter? routeTranscript,
//   void Function(VoiceRouteResult result, {required bool autoSend})? onRoutedCommand,
```

  Behavior in the `captured` branch, BOTH paths:
  1. autoSend path: `_handleLocalCommand` (commandWord) keeps FIRST priority — it is an explicit user convention and must never lose to Needle.
  2. Then, if `routeTranscript != null`: `final routed = await routeTranscript(transcript);` — guard afterwards with the existing `_disposed || operationGeneration != _operationGeneration` check (routing awaits ~0.7 s; session may have changed) and re-check `channel.state.activeSessionId == captureSessionId`; on any guard failure treat as null.
  3. `routed != null` ⇒ `onRoutedCommand!(routed, autoSend: autoSend)` and DO NOT draft/submit (transcript consumed by the UI layer, which owns confirm/decline).
  4. `routed == null` ⇒ existing behavior verbatim.

- [ ] **Step 1: Write failing tests** (add to the existing test file, mirroring its fakes/style — `FakeVoiceCaptureService`, `FakeHermesChannel`):

```dart
test('routed transcript is consumed instead of drafted', () async {
  final channel = FakeHermesChannel();
  final routed = <VoiceRouteResult>[];
  final drafts = <String>[];
  final controller = HermesVoiceInputController(
    channel: () => channel,
    captureService: () => FakeVoiceCaptureService(
      audio: Uint8List(0),
      transcript: 'open the settings screen',
      duration: const Duration(seconds: 1),
      confidence: 0.9,
    ),
    textToSpeechService: () => null,
    settings: () => const NavivoxVoiceSettings(),
    onDraft: drafts.add,
    routeTranscript: (t) async => VoiceRouteResult(
      command: VoiceCommandId.navigateToScreen,
      args: const {'screen': 'settings'},
      tier: VoiceCommandTier.instant,
      transcript: t,
    ),
    onRoutedCommand: (result, {required autoSend}) => routed.add(result),
  );
  addTearDown(controller.dispose);
  await controller.captureDraft();
  expect(routed, hasLength(1));
  expect(drafts, isEmpty);
  expect(channel.state.voiceRuns, isEmpty);
});

test('null route falls through to the draft path unchanged', () async {
  // identical setup, routeTranscript: (_) async => null
  // expect drafts == ['<transcript>'], routed empty.
});

test('commandWord stop beats the router in continuous mode', () async {
  // settings with commandWord 'navi', transcript 'navi stop', autoSend path
  // via enableContinuous(); routeTranscript must never be invoked:
  // routeTranscript: (_) async => fail('router must not run'),
  // expect controller.continuousEnabled == false afterwards.
});
```

(Complete the second and third tests fully in the file; the existing tests show how to drive `enableContinuous` with a `FakeHermesChannel` connected state.)

- [ ] **Step 2: Run to verify failure** — new params don't exist ⇒ compile error.

- [ ] **Step 3: Implement** per Produces. Keep the factory/private-constructor pattern of the file (add the two fields through both).

- [ ] **Step 4: Run the controller suite** — `flutter test test/features/hermes_chat/controllers` → all pass (old tests unchanged — nullability guarantees today's behavior).

- [ ] **Step 5: Commit**

```bash
git add lib/features/hermes_chat/controllers/hermes_voice_input_controller.dart test/features/hermes_chat/controllers/hermes_voice_input_controller_test.dart
git commit -m "feat(voice-commands): optional routing seam in voice input controller"
```

---

### Task 9: Providers and Settings UI (toggle + model download)

**Files:**
- Create: `lib/features/voice_commands/providers/voice_command_providers.dart`
- Modify: `lib/features/settings/screens/settings_screen.dart` (new section)
- Modify: `lib/features/needle_spike/providers/needle_spike_providers.dart` (re-point to shared providers, keep eval screen working)
- Test: `test/features/voice_commands/voice_command_providers_test.dart`

**Interfaces:**
- Consumes: everything from Tasks 1–8; `getApplicationSupportDirectory` (path_provider); existing settings-screen `_SettingsSectionCard` pattern (READ the file; the Needle-spike debug section from the spike shows the shape).
- Produces (in `voice_command_providers.dart`):

```dart
final voiceCommandEngineProvider = Provider<NeedleEngineApi>((ref) {
  final engine = NeedleEngine();
  ref.onDispose(engine.unload);
  return engine; // Root-scoped: model stays resident for the app session.
});

final voiceCommandInstallServiceProvider =
    FutureProvider<NeedleModelInstallService>((ref) async {
  final support = await getApplicationSupportDirectory();
  return NeedleModelInstallService(supportDirectory: support);
});

/// Null when the feature toggle is off — the seam stays cold and today's
/// behavior is untouched (augment-only guarantee).
final voiceCommandRouterProvider = Provider<VoiceCommandRouter?>((ref) { ... });

final voiceCommandDispatcherProvider = Provider<VoiceCommandDispatcher>((ref) { ... });
```

  `voiceCommandRouterProvider` watches `navivoxVoiceSettingsProvider.select((s) => s.voiceCommandsEnabled)`; when false → null. When true → `VoiceCommandRouter(engine: ..., modelDirProvider: () async => (await ref.read(voiceCommandInstallServiceProvider.future)).installedModelDir(), contextProvider: () => VoiceCommandContext(sessionTitles: <non-null titles from ref.read(hermesChannelProvider).state.sessions>, voiceNames: <cached last-known list from the TTS engine provider — provide a small `ttsVoiceNamesProvider` FutureProvider that queries FlutterTtsEngine.voiceNames() once and caches>))`.
  `voiceCommandDispatcherProvider` wires `channel`, `navigate: (path) => ref.read(routerProvider).push(path)` (push, not go — same back-stack lesson as the spike), `settings`, `showNotice` (see Task 10 — a `voiceCommandNoticeProvider` `StateProvider<String?>` the screen listens to for snackbars), `stopVoiceCapture`/`startVoiceCapture` (callbacks injected at screen level via a late-bound `void Function()` holder class `VoiceCaptureHooks` defined in this file with settable `onStop`/`onStart` fields, defaulting to no-ops).

  Settings screen: append a `_SettingsSectionCard(title: 'On-device voice commands (beta)', icon: Icons.bolt_outlined, children: [...])` containing: a `SwitchListTile` bound to `voiceCommandsEnabled` via the settings controller; when toggled ON and `installedModelDir()` is null, show the download tile (`ListTile` with progress like the spike's install card, driving `ensureModel(onProgress:)`; failure → SnackBar + toggle stays on but router returns null until installed); when installed, a 'Delete model (16 MB)' `ListTile` that deletes the `needle_spike` support subdirectory and marker (add `Future<void> deleteModel()` to `NeedleModelInstallService`: recursive-delete `_root`, tolerate absence — include a unit test in the providers test file). Section subtitle text: 'Runs a small on-device model to execute simple commands instantly. Transcripts never leave the device.'

- [ ] **Step 1: Failing tests** — providers file: router is null when toggle off / non-null when on (ProviderContainer with mocked prefs + overridden install/channel providers); `deleteModel()` removes marker so `installedModelDir()` is null after (temp-dir test mirroring the install-service test style).
- [ ] **Step 2: Run to verify failure.**
- [ ] **Step 3: Implement** providers + settings section + `deleteModel()`; update `needle_spike_providers.dart` to alias the shared engine/install providers (`final needleEngineProvider = voiceCommandEngineProvider;` etc.) so the eval screen keeps compiling with ONE engine instance app-wide.
- [ ] **Step 4: Run** `flutter test test/features/voice_commands test/features/needle_spike test/features/settings && flutter analyze lib/features` → green.
- [ ] **Step 5: Commit**

```bash
git add lib/features/voice_commands/providers/voice_command_providers.dart lib/features/voice_commands/core/needle_model_install_service.dart lib/features/settings/screens/settings_screen.dart lib/features/needle_spike/providers/needle_spike_providers.dart test/features/voice_commands/voice_command_providers_test.dart
git commit -m "feat(voice-commands): providers, settings toggle, model download UI"
```

---

### Task 10: Chat screen wiring — instant snackbar + confirmation chip

**Files:**
- Create: `lib/features/voice_commands/widgets/voice_command_chip.dart`
- Modify: `lib/features/hermes_chat/screens/hermes_chat_screen.dart`
- Test: `test/features/voice_commands/voice_command_chip_test.dart` + extend `test/features/hermes_chat/screens/` with `hermes_chat_screen_voice_command_test.dart`

**Interfaces:**
- Consumes: Tasks 2, 7, 8, 9. READ `hermes_chat_screen.dart` first: it constructs `HermesVoiceInputController` with reader closures; wire the two new params there.
- Produces:
  - `class VoiceCommandChip extends StatefulWidget { const VoiceCommandChip({required this.result, required this.onConfirm, required this.onDecline, this.autoDeclineAfter, super.key}); }` — Material banner-style chip above the composer showing `result.describe()` with Confirm/Not now buttons; `autoDeclineAfter` (Duration?) runs a countdown then calls `onDecline` (used in continuous mode: 5 s; manual mode: null = sticky). Timer cancelled in dispose.
  - Screen behavior:
    - `routeTranscript`: `(t) => ref.read(voiceCommandRouterProvider)?.route(t) ?? Future.value(null)`.
    - `onRoutedCommand(result, autoSend:)`: instant tier → `ref.read(voiceCommandDispatcherProvider).dispatch(result)` + SnackBar `result.describe()`; confirm tier → set chip state (one at a time; a new result replaces the old chip).
    - Chip confirm → dispatch + clear chip. Chip decline/timeout → clear chip; `autoSend == false` → put `result.transcript` into the composer draft (existing draft mechanism); `autoSend == true` → `ref.read(hermesChannelProvider).sendText(result.transcript)` (documented: declined continuous commands send as plain text).
    - `VoiceCaptureHooks.onStop = () => voiceController.pause('Stopped by voice command.')`, `.onStart = () => voiceController.enableContinuous()` bound where the controller is created.
    - `showNotice` binding: `voiceCommandNoticeProvider` listener → `ScaffoldMessenger.of(context).showSnackBar(...)`, cleared after showing.
    - Suspension hint (spec requirement): after each `routeTranscript` resolution, if `ref.read(voiceCommandRouterProvider)?.suspended == true` and a `bool _suspensionNoticeShown` screen flag is false, set the flag and show one notice: 'On-device commands paused after repeated errors. They resume on app restart.' (transcript-free; shown at most once per screen lifetime; add a widget-test case for it in the screen test file with a fake router whose route() throws-counts to suspended).
- [ ] **Step 1: Failing widget tests** — chip: renders describe text; Confirm fires onConfirm once; autoDeclineAfter fires onDecline after pumping past the duration; decline button fires onDecline. Screen test (mirror `hermes_chat_screen_android_endpoint_test.dart` harness style, override router/dispatcher providers with fakes): a confirm-tier result shows the chip; tapping 'Not now' puts the transcript into the composer field.
- [ ] **Step 2: Run to verify failure.**
- [ ] **Step 3: Implement** chip widget + screen wiring.
- [ ] **Step 4: Run** the two new test files + full `flutter test test/features/hermes_chat` (regression: existing screen tests must stay green — feature off by default in their fixtures) → green; analyze clean.
- [ ] **Step 5: Commit**

```bash
git add lib/features/voice_commands/widgets/voice_command_chip.dart lib/features/hermes_chat/screens/hermes_chat_screen.dart test/features/voice_commands/voice_command_chip_test.dart test/features/hermes_chat/screens/hermes_chat_screen_voice_command_test.dart
git commit -m "feat(voice-commands): chat screen routing UX with chip and snackbar"
```

---

### Task 11: Spike-bank regression fixture

**Files:**
- Create: `test/features/voice_commands/spike_bank_regression_test.dart`

**Interfaces:**
- Consumes: `VoiceCommandRouter` (Task 4) with a fake engine; the 20 recorded spike outputs (from docs/superpowers/specs/2026-07-13-needle-spike-findings.md §2 — encode them as the fixture below).

- [ ] **Step 1: Write the test directly** (this task IS a test; red/green does not apply — it must pass immediately against Tasks 2–4 and lock the guardrail behavior):

```dart
// For each of the 20 spike transcripts: the raw function_call Needle actually
// produced on-device, and what the validated outcome must be.
// wrong-tool cases assert the SAFETY behavior, not correctness of Needle:
//  - 'take me back to the chat' → switch_session{back}: no session named
//    'back' exists in the fixture context ⇒ fallthrough (null).
//  - 'start a new conversation' → toggle_continuous_mode{true}: validates ⇒
//    CONFIRM tier (chip absorbs the wrong tool; asserted as confirm).
//  - 'speak faster please' → set_tts_voice{faster}: no such voice ⇒ null.
//  - 'open the settings screen' → navigate_to_screen{settings screen} ⇒
//    snapped to 'settings', instant.
```

Build `_cases` as a list of `(transcript, rawEngineJson, expected)` records covering all 20 rows from the findings; run each through a `VoiceCommandRouter` whose fake engine returns `rawEngineJson`, with `contextProvider` supplying `sessionTitles: ['groceries', 'work notes']` and `voiceNames: ['nova', 'en-GB-standard']`. Assert per case: expected command id + snapped args + tier, or null. Twenty asserts, table-driven (`for (final c in _cases) { test(c.transcript, ...) }`).

- [ ] **Step 2: Run** `flutter test test/features/voice_commands/spike_bank_regression_test.dart` → 20 pass. If any fail, the validator (Task 3) has a gap — fix the validator, never the fixture expectations, unless the expectation contradicts the guardrail table above.
- [ ] **Step 3: Commit**

```bash
git add test/features/voice_commands/spike_bank_regression_test.dart
git commit -m "test(voice-commands): lock spike-bank guardrail behavior"
```

---

### Task 12: CI engine build + full verification + docs

**Files:**
- Modify: `.github/workflows/release-alpha.yml`
- Modify: `scripts/spike/maestro_eval.yaml` → Create: `scripts/voice_commands/maestro_router_check.yaml` (new flow; old one stays)
- Modify: `docs/superpowers/specs/2026-07-13-needle-router-design.md` (status → Implemented, deviations noted)

- [ ] **Step 1: CI step.** In `.github/workflows/release-alpha.yml`, in the `Signed Android APK` job, insert BEFORE the `Build signed release APK` step (currently ~line 40):

```yaml
      - name: Build Cactus engine (arm64)
        run: |
          sudo apt-get update && sudo apt-get install -y cmake ninja-build
          bash scripts/spike/build_cactus_engine.sh
```

(The script auto-detects the NDK from `$ANDROID_HOME/ndk/*` present on ubuntu-latest; it fails loudly if `cactus_init` isn't exported — that guard is the CI gate.)

- [ ] **Step 2: Maestro router check** — create `scripts/voice_commands/maestro_router_check.yaml`: launch (stopApp) → Settings → enable 'On-device voice commands' switch → download model (extendedWaitUntil the delete tile, 240 s) → back to Hermes tab → (typing path can't exercise the mic; this flow verifies enablement + download only; command routing is verified manually per Step 4). Reuse the multiline-matcher lessons: `"Settings\nTab 2 of 2"`, `(?s).*` patterns.

- [ ] **Step 3: Full local gate.**

```bash
flutter test && flutter analyze
flutter build apk --release
```
Expected: all green; release build includes the `.so` (verify: `unzip -l build/app/outputs/flutter-apk/app-release.apk | grep libcactus_engine`).

- [ ] **Step 4: On-device smoke (needs attached phone + operator).** Install the release APK, enable the toggle, download the model, then speak: 'open the settings screen' (expect instant navigation + snackbar), 'switch to my groceries session' (expect chip; decline → transcript lands in composer), any ordinary sentence (expect normal Hermes send). Record results in the design doc's status note.

- [ ] **Step 5: Update design-doc status and commit.**

```bash
git add .github/workflows/release-alpha.yml scripts/voice_commands/maestro_router_check.yaml docs/superpowers/specs/2026-07-13-needle-router-design.md
git commit -m "ci(voice-commands): build engine in release pipeline; router smoke flow"
```

- [ ] **Step 6: Merge decision** — report to the user: branch `feat/needle-router` ready; merging to main is their call.
