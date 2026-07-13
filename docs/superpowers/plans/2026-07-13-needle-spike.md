# Needle On-Device Tool-Calling Spike Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prove (or disprove) that the Needle 26M function-calling model runs inside Navivox on Android, measuring accuracy, latency, and size, behind a `NEEDLE_SPIKE` dart-define — per the approved spec `docs/superpowers/specs/2026-07-13-needle-spike-design.md`.

**Architecture:** Vendor the Cactus v2 engine (single FFI file `cactus.dart` + prebuilt `libcactus_engine.so` in jniLibs — there is no pub package for v2). Pure-Dart layers (tool catalog, result parsing, scorecard, download service) are TDD'd; the FFI layer is isolated behind a `NeedleEngineApi` interface so everything above it is testable without the native lib. A hidden debug screen drives evaluation.

**Tech Stack:** Flutter/Dart 3.12, `dart:ffi` + `package:ffi`, `package:archive` (unzip), Riverpod 3, go_router 17, existing `VoiceCaptureService` for the mic.

## Global Constraints

- **Augment-only:** nothing here may touch or degrade the Hermes path. Spike code lives in `lib/features/needle_spike/`; the ONLY files outside it that may be modified are: `pubspec.yaml`, `.gitignore`, `lib/router/routes/app_routes.dart`, `lib/router/providers/app_router.dart`, `lib/features/settings/screens/settings_screen.dart`, plus new files under `scripts/spike/` and `android/app/src/main/jniLibs/`.
- **Privacy:** transcripts are displayed, never logged (`debugPrint`/`print` forbidden on transcript content) and never persisted. The scorecard stores counts only.
- **Gating:** all UI entry points guarded by `needleSpikeEnabled` (`bool.fromEnvironment('NEEDLE_SPIKE')`). Default builds must show no spike UI.
- **On-device only:** engine options must include `"auto_handoff": false` (Cactus defaults this to `true`, which would silently send prompts to their cloud).
- **Branch:** all work on `spike/needle`, branched from `main`. Never merge to `main`. The working tree already has 6 modified files unrelated to this spike — NEVER `git add -A`; stage only the files each task names.
- **Pinned upstream:** Cactus repo commit `49e12567c9d355a269c761619bc09eef796ab9b1`; Needle bundle `needle-cq4.zip` (16,185,061 bytes, sha256 `a3423af7d7bd2a35e08ba1f262c4796f4e97963da0a3fbe124d3a8eaae9e4098`).
- **Platform:** Android arm64-v8a only. Other platforms compile (FFI file is only imported by spike code that's dart-define-gated) but are out of scope.
- Run `flutter analyze` before every commit; it must be clean for the files you touched.

---

### Task 1: Branch, native engine build, vendored FFI binding, dependencies

**Files:**
- Create: `scripts/spike/build_cactus_engine.sh`
- Create: `lib/features/needle_spike/ffi/cactus.dart` (vendored, unmodified)
- Modify: `pubspec.yaml` (add `ffi`, `archive`)
- Modify: `.gitignore` (ignore the `.so`)

**Interfaces:**
- Produces: top-level FFI functions from the vendored file used by Task 6: `cactusInit(Pointer<Utf8> modelPath, Pointer<Utf8> corpusDir, bool cacheIndex) → Pointer<Void>`, `cactusComplete(Pointer<Void> model, Pointer<Utf8> messagesJson, Pointer<Utf8> responseBuffer, int bufferSize, Pointer<Utf8> optionsJson, Pointer<Utf8> toolsJson, Pointer<NativeFunction<TokenCallbackNative>> callback, Pointer<Void> userData, Pointer<Uint8> pcmBuffer, int pcmBufferSize) → int` (bytes written, negative = error), `cactusDestroy(Pointer<Void> model)`.

- [ ] **Step 1: Create the spike branch**

```bash
git checkout -b spike/needle
```

- [ ] **Step 2: Record the baseline APK size** (used in Task 9's findings)

```bash
flutter build apk --release
stat -c %s build/app/outputs/flutter-apk/app-release.apk | tee /tmp/needle_spike_baseline_apk_bytes.txt
```

Expected: prints a byte count (~tens of MB). Keep the number; it goes in the findings doc.

- [ ] **Step 3: Write the engine build script**

Create `scripts/spike/build_cactus_engine.sh`:

```bash
#!/usr/bin/env bash
# Builds libcactus_engine.so (Android arm64-v8a) from the pinned Cactus commit
# and installs it into android/app/src/main/jniLibs/arm64-v8a/.
set -euo pipefail

CACTUS_SHA="49e12567c9d355a269c761619bc09eef796ab9b1"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/navivox/cactus"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
jni_dir="$repo_root/android/app/src/main/jniLibs/arm64-v8a"

if [[ ! -d "$CACHE_DIR/.git" ]]; then
  git clone https://github.com/cactus-compute/cactus.git "$CACHE_DIR"
fi
git -C "$CACHE_DIR" fetch --all --quiet
git -C "$CACHE_DIR" checkout --quiet "$CACTUS_SHA"

bash "$CACHE_DIR/android/build.sh"

mkdir -p "$jni_dir"
so_path="$(find "$CACHE_DIR/android" -name libcactus_engine.so | head -1)"
if [[ -z "$so_path" ]]; then
  echo "libcactus_engine.so not produced; check NDK/CMake output above" >&2
  exit 1
fi
cp "$so_path" "$jni_dir/libcactus_engine.so"
echo "Installed $(stat -c %s "$jni_dir/libcactus_engine.so") bytes -> $jni_dir/libcactus_engine.so"
```

Then: `chmod +x scripts/spike/build_cactus_engine.sh`

- [ ] **Step 4: Run the build script**

Run: `bash scripts/spike/build_cactus_engine.sh`

Expected: `Installed <N> bytes -> .../jniLibs/arm64-v8a/libcactus_engine.so`. Requires Android NDK + CMake ≥3.10 (`android/build.sh` auto-detects `ANDROID_NDK_HOME` from `ANDROID_HOME/ndk/*`). If the NDK is missing, install via Android Studio SDK Manager and re-run. **If the build fails for engine-source reasons, STOP: that is spike finding #1 ("engine does not build for Android at pinned commit") — skip to Task 9 and write the findings doc.**

- [ ] **Step 5: Ignore the binary; vendor the FFI binding**

Append to `.gitignore`:

```
# Needle spike: locally built native engine (rebuild via scripts/spike/build_cactus_engine.sh)
android/app/src/main/jniLibs/arm64-v8a/libcactus_engine.so
```

Vendor the binding (single plain-Dart FFI file, no plugin):

```bash
mkdir -p lib/features/needle_spike/ffi
cp "${XDG_CACHE_HOME:-$HOME/.cache}/navivox/cactus/bindings/flutter/cactus.dart" lib/features/needle_spike/ffi/cactus.dart
```

Add this header comment at the top of the copied file (keep the rest byte-identical):

```dart
// Vendored from cactus-compute/cactus@49e12567c9d355a269c761619bc09eef796ab9b1
// bindings/flutter/cactus.dart — do not edit; re-vendor to update.
```

- [ ] **Step 6: Add dependencies**

In `pubspec.yaml` `dependencies:` block (after `crypto: ^3.0.7`):

```yaml
  ffi: ^2.1.4
  archive: ^4.0.2
```

Run: `flutter pub get`
Expected: resolves without conflicts.

- [ ] **Step 7: Verify the app still builds**

Run: `flutter analyze lib/features/needle_spike && flutter build apk --debug`
Expected: analyze clean (the vendored file must not raise errors; if it raises lints only, add `// ignore_for_file:` lines for those lints below the vendor header) and APK builds.

- [ ] **Step 8: Commit**

```bash
git add scripts/spike/build_cactus_engine.sh lib/features/needle_spike/ffi/cactus.dart pubspec.yaml pubspec.lock .gitignore
git commit -m "spike(needle): vendor cactus v2 FFI binding and engine build script"
```

---

### Task 2: Spike flag, tool catalog, and canned test transcripts

**Files:**
- Create: `lib/features/needle_spike/needle_spike_flag.dart`
- Create: `lib/features/needle_spike/services/needle_tool_catalog.dart`
- Create: `lib/features/needle_spike/data/needle_test_transcripts.dart`
- Test: `test/features/needle_spike/needle_tool_catalog_test.dart`

**Interfaces:**
- Produces: `const bool needleSpikeEnabled`; `NeedleToolCatalog.tools` (`List<Map<String, dynamic>>`), `NeedleToolCatalog.toolsJson` (`String`), `NeedleToolCatalog.toolNames` (`Set<String>`); `NeedleTestTranscript { String text; String expectedTool; }` and `const List<NeedleTestTranscript> needleTestTranscripts` (20 entries).

- [ ] **Step 1: Write the failing test**

Create `test/features/needle_spike/needle_tool_catalog_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/needle_spike/data/needle_test_transcripts.dart';
import 'package:navivox/features/needle_spike/services/needle_tool_catalog.dart';

void main() {
  test('catalog defines 10 uniquely named function tools', () {
    expect(NeedleToolCatalog.tools, hasLength(10));
    expect(NeedleToolCatalog.toolNames, hasLength(10));
    for (final tool in NeedleToolCatalog.tools) {
      expect(tool['type'], 'function');
      final function = tool['function'] as Map<String, dynamic>;
      expect(function['name'], isNotEmpty);
      expect(function['description'], isNotEmpty);
      final parameters = function['parameters'] as Map<String, dynamic>;
      expect(parameters['type'], 'object');
      expect(parameters, contains('properties'));
    }
  });

  test('toolsJson round-trips as JSON', () {
    final decoded = jsonDecode(NeedleToolCatalog.toolsJson) as List<dynamic>;
    expect(decoded, hasLength(10));
  });

  test('every canned transcript targets a catalog tool, two per tool', () {
    expect(needleTestTranscripts, hasLength(20));
    final counts = <String, int>{};
    for (final t in needleTestTranscripts) {
      expect(NeedleToolCatalog.toolNames, contains(t.expectedTool));
      counts[t.expectedTool] = (counts[t.expectedTool] ?? 0) + 1;
    }
    expect(counts.values.every((c) => c == 2), isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/needle_spike/needle_tool_catalog_test.dart`
Expected: FAIL — files don't exist.

- [ ] **Step 3: Implement flag, catalog, transcripts**

Create `lib/features/needle_spike/needle_spike_flag.dart`:

```dart
/// Compile-time gate for the Needle spike. Enable with
/// `--dart-define=NEEDLE_SPIKE=true`; default builds ship no spike UI.
const bool needleSpikeEnabled = bool.fromEnvironment('NEEDLE_SPIKE');
```

Create `lib/features/needle_spike/services/needle_tool_catalog.dart`:

```dart
import 'dart:convert';

/// Mock Navivox actions exposed to Needle, in the Cactus/OpenAI tools JSON
/// shape. Handlers are intentionally absent: the spike only inspects which
/// call the model emits; nothing here touches real app state.
abstract final class NeedleToolCatalog {
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
    _tool('start_voice_run', 'Start listening for a voice command.', {}, []),
    _tool('stop_voice_run', 'Stop the current voice capture.', {}, []),
    _tool('toggle_continuous_mode', 'Turn continuous voice mode on or off.', {
      'enabled': {
        'type': 'boolean',
        'description': 'true to enable continuous mode.',
      },
    }, ['enabled']),
    _tool('send_message', 'Send a chat message to the agent.', {
      'text': {'type': 'string', 'description': 'The message to send.'},
    }, ['text']),
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
    _tool('set_speech_rate', 'Change how fast speech is read aloud.', {
      'rate': {
        'type': 'number',
        'description': 'Speech rate multiplier, e.g. 1.0 is normal.',
      },
    }, ['rate']),
    _tool('show_status', 'Show the agent connection status.', {}, []),
  ];

  static final String toolsJson = jsonEncode(tools);

  static final Set<String> toolNames = tools
      .map((t) => (t['function'] as Map<String, dynamic>)['name'] as String)
      .toSet();
}
```

Create `lib/features/needle_spike/data/needle_test_transcripts.dart`:

```dart
/// Canned evaluation bank: 20 realistic voice-command transcripts, two per
/// catalog tool. `expectedTool` is what a correct parse must call.
class NeedleTestTranscript {
  const NeedleTestTranscript({required this.text, required this.expectedTool});

  final String text;
  final String expectedTool;
}

const List<NeedleTestTranscript> needleTestTranscripts = [
  NeedleTestTranscript(
    text: 'open the settings screen',
    expectedTool: 'navigate_to_screen',
  ),
  NeedleTestTranscript(
    text: 'take me back to the chat',
    expectedTool: 'navigate_to_screen',
  ),
  NeedleTestTranscript(
    text: 'start listening',
    expectedTool: 'start_voice_run',
  ),
  NeedleTestTranscript(
    text: 'begin a voice command',
    expectedTool: 'start_voice_run',
  ),
  NeedleTestTranscript(
    text: 'stop listening now',
    expectedTool: 'stop_voice_run',
  ),
  NeedleTestTranscript(
    text: 'cancel the recording',
    expectedTool: 'stop_voice_run',
  ),
  NeedleTestTranscript(
    text: 'turn on continuous mode',
    expectedTool: 'toggle_continuous_mode',
  ),
  NeedleTestTranscript(
    text: 'disable hands free mode please',
    expectedTool: 'toggle_continuous_mode',
  ),
  NeedleTestTranscript(
    text: 'tell the agent I will be ten minutes late',
    expectedTool: 'send_message',
  ),
  NeedleTestTranscript(
    text: 'send a message saying good morning',
    expectedTool: 'send_message',
  ),
  NeedleTestTranscript(
    text: 'start a new conversation',
    expectedTool: 'new_session',
  ),
  NeedleTestTranscript(
    text: 'give me a fresh session',
    expectedTool: 'new_session',
  ),
  NeedleTestTranscript(
    text: 'switch to my groceries session',
    expectedTool: 'switch_session',
  ),
  NeedleTestTranscript(
    text: 'go to the session called work notes',
    expectedTool: 'switch_session',
  ),
  NeedleTestTranscript(
    text: 'change the voice to nova',
    expectedTool: 'set_tts_voice',
  ),
  NeedleTestTranscript(
    text: 'use the british voice for speech',
    expectedTool: 'set_tts_voice',
  ),
  NeedleTestTranscript(
    text: 'speak faster please',
    expectedTool: 'set_speech_rate',
  ),
  NeedleTestTranscript(
    text: 'slow the reading speed down to half',
    expectedTool: 'set_speech_rate',
  ),
  NeedleTestTranscript(
    text: 'is the agent connected',
    expectedTool: 'show_status',
  ),
  NeedleTestTranscript(
    text: 'show me the connection status',
    expectedTool: 'show_status',
  ),
];
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/needle_spike/needle_tool_catalog_test.dart`
Expected: 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/needle_spike/needle_spike_flag.dart lib/features/needle_spike/services/needle_tool_catalog.dart lib/features/needle_spike/data/needle_test_transcripts.dart test/features/needle_spike/needle_tool_catalog_test.dart
git commit -m "spike(needle): tool catalog, spike flag, canned transcript bank"
```

---

### Task 3: Engine response parsing (`NeedleResult`)

**Files:**
- Create: `lib/features/needle_spike/services/needle_result.dart`
- Test: `test/features/needle_spike/needle_result_test.dart`

**Interfaces:**
- Produces: `NeedleFunctionCall { String name; Map<String, dynamic> arguments; }`, `NeedleResult { bool success; String? error; String response; List<NeedleFunctionCall> functionCalls; double? confidence; double? totalTimeMs; double? timeToFirstTokenMs; int wallLatencyMs; factory NeedleResult.fromEngineJson(String raw, {required int wallLatencyMs}) }`. Consumed by Tasks 6 and 7.

The engine returns JSON like (from Cactus docs):
`{"success": true, "error": null, "cloud_handoff": false, "response": "...", "function_calls": [], "confidence": 0.85, "time_to_first_token_ms": 150.5, "total_time_ms": 1250.3, ...}`.
The `function_calls` entry shape is not documented for every engine version, so parse defensively: accept `{"name": ..., "arguments": {...}}`, `{"function": {"name": ..., "arguments": ...}}`, and `arguments` given as either a JSON object or a JSON-encoded string.

- [ ] **Step 1: Write the failing test**

Create `test/features/needle_spike/needle_result_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/needle_spike/services/needle_result.dart';

void main() {
  test('parses a successful tool-call response', () {
    const raw = '{"success": true, "error": null, "response": "", '
        '"function_calls": [{"name": "send_message", '
        '"arguments": {"text": "good morning"}}], '
        '"confidence": 0.91, "time_to_first_token_ms": 12.5, '
        '"total_time_ms": 80.2}';
    final result = NeedleResult.fromEngineJson(raw, wallLatencyMs: 95);
    expect(result.success, isTrue);
    expect(result.error, isNull);
    expect(result.functionCalls, hasLength(1));
    expect(result.functionCalls.single.name, 'send_message');
    expect(result.functionCalls.single.arguments['text'], 'good morning');
    expect(result.confidence, closeTo(0.91, 1e-9));
    expect(result.totalTimeMs, closeTo(80.2, 1e-9));
    expect(result.wallLatencyMs, 95);
  });

  test('parses nested function shape with string-encoded arguments', () {
    const raw = '{"success": true, "response": "", "function_calls": '
        '[{"function": {"name": "set_speech_rate", '
        '"arguments": "{\\"rate\\": 0.5}"}}]}';
    final result = NeedleResult.fromEngineJson(raw, wallLatencyMs: 40);
    expect(result.functionCalls.single.name, 'set_speech_rate');
    expect(result.functionCalls.single.arguments['rate'], 0.5);
  });

  test('parses an engine error response', () {
    const raw = '{"success": false, "error": "model not loaded", '
        '"response": "", "function_calls": []}';
    final result = NeedleResult.fromEngineJson(raw, wallLatencyMs: 3);
    expect(result.success, isFalse);
    expect(result.error, 'model not loaded');
    expect(result.functionCalls, isEmpty);
  });

  test('malformed engine output becomes a failed result, not a throw', () {
    final result = NeedleResult.fromEngineJson('not json', wallLatencyMs: 3);
    expect(result.success, isFalse);
    expect(result.error, contains('Unparseable engine response'));
  });

  test('wrong-typed leaf fields degrade gracefully instead of throwing', () {
    const raw = '{"success": true, "error": 123, "response": 42, '
        '"confidence": "high", "total_time_ms": "slow", '
        '"time_to_first_token_ms": [], "function_calls": []}';
    final result = NeedleResult.fromEngineJson(raw, wallLatencyMs: 7);
    expect(result.success, isTrue);
    expect(result.error, isNull);
    expect(result.response, '');
    expect(result.confidence, isNull);
    expect(result.totalTimeMs, isNull);
    expect(result.timeToFirstTokenMs, isNull);
  });

  test('no tool call is represented as an empty list', () {
    const raw = '{"success": true, "response": "hello", "function_calls": []}';
    final result = NeedleResult.fromEngineJson(raw, wallLatencyMs: 5);
    expect(result.functionCalls, isEmpty);
    expect(result.response, 'hello');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/needle_spike/needle_result_test.dart`
Expected: FAIL — `needle_result.dart` doesn't exist.

- [ ] **Step 3: Implement**

Create `lib/features/needle_spike/services/needle_result.dart`:

```dart
import 'dart:convert';

class NeedleFunctionCall {
  const NeedleFunctionCall({required this.name, required this.arguments});

  final String name;
  final Map<String, dynamic> arguments;
}

/// Parsed `cactus_complete` response plus the Dart-side wall latency.
class NeedleResult {
  const NeedleResult({
    required this.success,
    required this.error,
    required this.response,
    required this.functionCalls,
    required this.confidence,
    required this.totalTimeMs,
    required this.timeToFirstTokenMs,
    required this.wallLatencyMs,
  });

  factory NeedleResult.fromEngineJson(
    String raw, {
    required int wallLatencyMs,
  }) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      decoded = null;
    }
    if (decoded is! Map<String, dynamic>) {
      return NeedleResult(
        success: false,
        error: 'Unparseable engine response (${raw.length} chars)',
        response: '',
        functionCalls: const [],
        confidence: null,
        totalTimeMs: null,
        timeToFirstTokenMs: null,
        wallLatencyMs: wallLatencyMs,
      );
    }
    return NeedleResult(
      success: decoded['success'] == true,
      error: decoded['error'] is String ? decoded['error'] as String : null,
      response: decoded['response'] is String
          ? decoded['response'] as String
          : '',
      functionCalls: _parseFunctionCalls(decoded['function_calls']),
      confidence: decoded['confidence'] is num
          ? (decoded['confidence'] as num).toDouble()
          : null,
      totalTimeMs: decoded['total_time_ms'] is num
          ? (decoded['total_time_ms'] as num).toDouble()
          : null,
      timeToFirstTokenMs: decoded['time_to_first_token_ms'] is num
          ? (decoded['time_to_first_token_ms'] as num).toDouble()
          : null,
      wallLatencyMs: wallLatencyMs,
    );
  }

  final bool success;
  final String? error;
  final String response;
  final List<NeedleFunctionCall> functionCalls;
  final double? confidence;
  final double? totalTimeMs;
  final double? timeToFirstTokenMs;
  final int wallLatencyMs;

  static List<NeedleFunctionCall> _parseFunctionCalls(Object? rawCalls) {
    if (rawCalls is! List) return const [];
    final calls = <NeedleFunctionCall>[];
    for (final entry in rawCalls) {
      if (entry is! Map) continue;
      final function = entry['function'];
      final source = function is Map ? function : entry;
      final name = source['name'];
      if (name is! String || name.isEmpty) continue;
      calls.add(
        NeedleFunctionCall(
          name: name,
          arguments: _parseArguments(source['arguments']),
        ),
      );
    }
    return calls;
  }

  static Map<String, dynamic> _parseArguments(Object? rawArguments) {
    if (rawArguments is Map) {
      return rawArguments.map((k, v) => MapEntry(k.toString(), v));
    }
    if (rawArguments is String && rawArguments.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawArguments);
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(k.toString(), v));
        }
      } on FormatException {
        // Fall through to empty.
      }
    }
    return const {};
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/needle_spike/needle_result_test.dart`
Expected: 6 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/needle_spike/services/needle_result.dart test/features/needle_spike/needle_result_test.dart
git commit -m "spike(needle): defensive engine response parsing"
```

---

### Task 4: Scorecard model (counts only — privacy constraint)

**Files:**
- Create: `lib/features/needle_spike/models/needle_scorecard.dart`
- Test: `test/features/needle_spike/needle_scorecard_test.dart`

**Interfaces:**
- Produces: `enum NeedleVerdict { correct, wrongTool, wrongArgs, noCall }`, `class NeedleScorecard { int countFor(NeedleVerdict v); int get total; void record(NeedleVerdict v); void reset(); String get summaryLine; }`. Consumed by Task 7. Stores integers only — no transcripts, no tool call payloads.

- [ ] **Step 1: Write the failing test**

Create `test/features/needle_spike/needle_scorecard_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/needle_spike/models/needle_scorecard.dart';

void main() {
  test('records verdict counts and totals', () {
    final card = NeedleScorecard();
    card.record(NeedleVerdict.correct);
    card.record(NeedleVerdict.correct);
    card.record(NeedleVerdict.wrongArgs);
    card.record(NeedleVerdict.noCall);
    expect(card.countFor(NeedleVerdict.correct), 2);
    expect(card.countFor(NeedleVerdict.wrongTool), 0);
    expect(card.countFor(NeedleVerdict.wrongArgs), 1);
    expect(card.countFor(NeedleVerdict.noCall), 1);
    expect(card.total, 4);
    expect(card.summaryLine, 'correct 2 · wrong tool 0 · wrong args 1 · no call 1 · total 4');
  });

  test('reset clears all counts', () {
    final card = NeedleScorecard()..record(NeedleVerdict.correct);
    card.reset();
    expect(card.total, 0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/needle_spike/needle_scorecard_test.dart`
Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Implement**

Create `lib/features/needle_spike/models/needle_scorecard.dart`:

```dart
enum NeedleVerdict { correct, wrongTool, wrongArgs, noCall }

/// Manual evaluation tally. Holds counts only: persisting or logging
/// utterances is forbidden by the repo's voice privacy policy.
class NeedleScorecard {
  final Map<NeedleVerdict, int> _counts = {
    for (final v in NeedleVerdict.values) v: 0,
  };

  int countFor(NeedleVerdict verdict) => _counts[verdict]!;

  int get total => _counts.values.fold(0, (sum, c) => sum + c);

  void record(NeedleVerdict verdict) {
    _counts[verdict] = _counts[verdict]! + 1;
  }

  void reset() {
    for (final v in NeedleVerdict.values) {
      _counts[v] = 0;
    }
  }

  String get summaryLine =>
      'correct ${countFor(NeedleVerdict.correct)} · '
      'wrong tool ${countFor(NeedleVerdict.wrongTool)} · '
      'wrong args ${countFor(NeedleVerdict.wrongArgs)} · '
      'no call ${countFor(NeedleVerdict.noCall)} · '
      'total $total';
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/needle_spike/needle_scorecard_test.dart`
Expected: 2 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/needle_spike/models/needle_scorecard.dart test/features/needle_spike/needle_scorecard_test.dart
git commit -m "spike(needle): counts-only evaluation scorecard"
```

---

### Task 5: Model download + install service

**Files:**
- Create: `lib/features/needle_spike/services/needle_model_install_service.dart`
- Test: `test/features/needle_spike/needle_model_install_service_test.dart`

**Interfaces:**
- Consumes: nothing from earlier tasks (standalone IO service).
- Produces: `class NeedleModelInstallService { NeedleModelInstallService({required Directory supportDirectory}); Future<String?> installedModelDir(); Future<String> ensureModel({void Function(int receivedBytes)? onProgress}); }` — `ensureModel` downloads `needle-cq4.zip` (HTTPS, sha256-verified, 32 MB cap), extracts it, writes a completion marker, and returns the model directory path for `cactus_init`. Consumed by Tasks 6–7.

Mirrors the pocket_speech IO download pattern (temp file, size cap, checksum, HTTPS-only redirects) — duplicated inside the spike folder deliberately, to keep zero coupling with production voice code.

- [ ] **Step 1: Write the failing test** (tests the pure-logic parts: marker/laydown/extraction/model-dir resolution, using a zip built in-test; no network)

Create `test/features/needle_spike/needle_model_install_service_test.dart`:

```dart
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/needle_spike/services/needle_model_install_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('needle_spike_test');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('installedModelDir is null before any install', () async {
    final service = NeedleModelInstallService(supportDirectory: tempDir);
    expect(await service.installedModelDir(), isNull);
  });

  test('extraction resolves a flat zip to the extract dir', () async {
    final zip = _zipWith({'config.json': '{}', 'weights.bin': 'xx'});
    final service = NeedleModelInstallService(supportDirectory: tempDir);
    final dir = await service.installFromZipBytes(zip);
    expect(File('$dir/config.json').existsSync(), isTrue);
    expect(await service.installedModelDir(), dir);
  });

  test('extraction descends into a single wrapper directory', () async {
    final zip = _zipWith({
      'needle-cq4/config.json': '{}',
      'needle-cq4/weights.bin': 'xx',
    });
    final service = NeedleModelInstallService(supportDirectory: tempDir);
    final dir = await service.installFromZipBytes(zip);
    expect(dir, endsWith('needle-cq4'));
    expect(File('$dir/config.json').existsSync(), isTrue);
    expect(await service.installedModelDir(), dir);
  });

  test('empty zip fails installation and leaves no marker', () async {
    final zip = _zipWith({});
    final service = NeedleModelInstallService(supportDirectory: tempDir);
    await expectLater(service.installFromZipBytes(zip), throwsStateError);
    expect(await service.installedModelDir(), isNull);
  });
}

List<int> _zipWith(Map<String, String> files) {
  final archive = Archive();
  files.forEach((path, content) {
    archive.addFile(ArchiveFile(path, content.length, content.codeUnits));
  });
  return ZipEncoder().encode(archive);
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/needle_spike/needle_model_install_service_test.dart`
Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Implement**

Create `lib/features/needle_spike/services/needle_model_install_service.dart`:

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';

/// Downloads and installs the Needle CQ4 runtime bundle.
///
/// IO pattern (temp file, HTTPS-only redirects, size cap, sha256) mirrors
/// IoPocketSpeechAssetDownloadService; duplicated here on purpose so the
/// spike stays fully decoupled from production voice code.
class NeedleModelInstallService {
  NeedleModelInstallService({required this.supportDirectory});

  final Directory supportDirectory;

  static const modelZipUrl =
      'https://huggingface.co/Cactus-Compute/needle/resolve/main/needle-cq4.zip';
  static const modelZipSha256 =
      'a3423af7d7bd2a35e08ba1f262c4796f4e97963da0a3fbe124d3a8eaae9e4098';
  static const maximumZipBytes = 32 * 1024 * 1024;

  Directory get _root => Directory('${supportDirectory.path}/needle_spike');
  Directory get _modelRoot => Directory('${_root.path}/model');
  File get _marker => File('${_root.path}/.installed');

  /// Path to a previously installed model directory, or null.
  Future<String?> installedModelDir() async {
    if (!await _marker.exists()) return null;
    final recorded = (await _marker.readAsString()).trim();
    if (recorded.isEmpty || !await Directory(recorded).exists()) return null;
    return recorded;
  }

  Future<String>? _inFlight;

  /// Ensures the bundle is downloaded, verified, and extracted.
  /// Returns the directory to pass to `cactus_init`.
  ///
  /// Concurrent calls share one in-flight download/extract; only the first
  /// caller's [onProgress] receives updates.
  Future<String> ensureModel({void Function(int receivedBytes)? onProgress}) {
    return _inFlight ??= _ensureModel(onProgress: onProgress).whenComplete(() {
      _inFlight = null;
    });
  }

  Future<String> _ensureModel({
    void Function(int receivedBytes)? onProgress,
  }) async {
    final existing = await installedModelDir();
    if (existing != null) return existing;
    final zipBytes = await _downloadZip(onProgress: onProgress);
    return installFromZipBytes(zipBytes);
  }

  /// Extracts [zipBytes] and records the resolved model dir. Public so tests
  /// can exercise laydown logic without the network.
  Future<String> installFromZipBytes(List<int> zipBytes) async {
    if (await _modelRoot.exists()) {
      await _modelRoot.delete(recursive: true);
    }
    await _modelRoot.create(recursive: true);
    final archive = ZipDecoder().decodeBytes(zipBytes);
    await extractArchiveToDisk(archive, _modelRoot.path);
    // extractArchiveToDisk swallows per-entry write failures, so verify
    // every archive file actually landed on disk with the expected size.
    for (final entry in archive.files.where((f) => f.isFile)) {
      final out = File('${_modelRoot.path}/${entry.name}');
      if (!await out.exists() || await out.length() != entry.size) {
        throw StateError('Needle bundle extraction incomplete.');
      }
    }
    final modelDir = _resolveModelDir(_modelRoot);
    final hasFiles = modelDir
        .listSync(recursive: true)
        .whereType<File>()
        .isNotEmpty;
    if (!hasFiles) {
      throw StateError('Needle bundle extraction incomplete.');
    }
    await _marker.writeAsString(modelDir.path);
    return modelDir.path;
  }

  /// If the zip wraps everything in one directory, descend into it.
  Directory _resolveModelDir(Directory root) {
    var current = root;
    for (var depth = 0; depth < 3; depth++) {
      final entries = current.listSync();
      final files = entries.whereType<File>().toList();
      final dirs = entries.whereType<Directory>().toList();
      if (files.isNotEmpty || dirs.length != 1) return current;
      current = dirs.single;
    }
    return current;
  }

  Future<List<int>> _downloadZip({
    void Function(int receivedBytes)? onProgress,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      final response = await _openHttps(client, Uri.parse(modelZipUrl));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'GET $modelZipUrl failed with ${response.statusCode}',
        );
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response.timeout(const Duration(seconds: 30))) {
        builder.add(chunk);
        if (builder.length > maximumZipBytes) {
          throw StateError('Needle bundle exceeded its size limit.');
        }
        onProgress?.call(builder.length);
      }
      final bytes = builder.takeBytes();
      final digest = sha256.convert(bytes).toString().toLowerCase();
      if (digest != modelZipSha256.trim().toLowerCase()) {
        throw StateError('Needle bundle checksum mismatch.');
      }
      return bytes;
    } finally {
      client.close(force: true);
    }
  }

  Future<HttpClientResponse> _openHttps(HttpClient client, Uri uri) async {
    var current = uri;
    for (var redirects = 0; redirects <= 5; redirects++) {
      final request = await client.getUrl(current);
      request.followRedirects = false;
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      if (!const {
        HttpStatus.movedPermanently,
        HttpStatus.found,
        HttpStatus.seeOther,
        HttpStatus.temporaryRedirect,
        HttpStatus.permanentRedirect,
      }.contains(response.statusCode)) {
        return response;
      }
      final location = response.headers.value(HttpHeaders.locationHeader);
      await response.drain<void>();
      if (location == null || redirects == 5) {
        throw HttpException('Needle bundle redirect failed.', uri: current);
      }
      final next = current.resolve(location);
      if (next.scheme != 'https' || next.host.isEmpty) {
        throw StateError('Needle bundle redirect must use HTTPS.');
      }
      current = next;
    }
    throw StateError('Needle bundle redirected too many times.');
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/needle_spike/needle_model_install_service_test.dart`
Expected: 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/needle_spike/services/needle_model_install_service.dart test/features/needle_spike/needle_model_install_service_test.dart
git commit -m "spike(needle): sha256-verified model download and install service"
```

---

### Task 6: Engine wrapper (FFI in isolate) and spike service

**Files:**
- Create: `lib/features/needle_spike/services/needle_engine.dart`
- Create: `lib/features/needle_spike/services/needle_spike_service.dart`
- Test: `test/features/needle_spike/needle_spike_service_test.dart`
- Test: `test/features/needle_spike/native_call_queue_test.dart`

**Interfaces:**
- Consumes: vendored FFI functions (Task 1), `NeedleResult.fromEngineJson` (Task 3), `NeedleToolCatalog.toolsJson` (Task 2).
- Produces:
  - `abstract interface class NeedleEngineApi { bool get isLoaded; Future<void> load(String modelDir); Future<String> complete({required String messagesJson, required String toolsJson, required String optionsJson}); Future<void> unload(); }`
  - `class NativeCallQueue { Future<T> run<T>(Future<T> Function() op); }` (serializes async ops in submission order).
  - `class NeedleEngine implements NeedleEngineApi` (real FFI, runs blocking calls via `Isolate.run`, passes the model handle across isolates as an int address — native heap is process-wide so this is safe; all ops pass through a `NativeCallQueue`).
  - `class NeedleSpikeService { NeedleSpikeService({required NeedleEngineApi engine}); Future<NeedleResult> parseTranscript(String transcript); }`
  - `class NeedleEngineException implements Exception { final String message; }`

FFI calls are synchronous and CPU-heavy; running them on the main isolate would freeze the UI, so every native call goes through `Isolate.run`. The UI serializes requests (one at a time) because the engine's thread-safety is unknown. On top of that, `NeedleEngine` itself serializes load/complete/unload through an internal `NativeCallQueue`: unload must never destroy a handle another isolate is still using (use-after-free), and concurrent loads must not both run `cactus_init` (handle leak). A consequence: `complete()` on an unloaded engine rejects asynchronously with `NeedleEngineException` (the not-loaded check runs inside the queued op, since a queued complete may legitimately execute after a queued unload).

- [ ] **Step 1: Write the failing test** (exercises `NeedleSpikeService` against a fake engine — no native lib needed)

Create `test/features/needle_spike/needle_spike_service_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/needle_spike/services/needle_engine.dart';
import 'package:navivox/features/needle_spike/services/needle_spike_service.dart';

class _FakeEngine implements NeedleEngineApi {
  _FakeEngine(this.rawResponse);

  final String rawResponse;
  String? lastMessagesJson;
  String? lastToolsJson;
  String? lastOptionsJson;
  int completeCalls = 0;

  @override
  bool get isLoaded => true;

  @override
  Future<void> load(String modelDir) async {}

  @override
  Future<String> complete({
    required String messagesJson,
    required String toolsJson,
    required String optionsJson,
  }) async {
    completeCalls += 1;
    lastMessagesJson = messagesJson;
    lastToolsJson = toolsJson;
    lastOptionsJson = optionsJson;
    return rawResponse;
  }

  @override
  Future<void> unload() async {}
}

void main() {
  const toolCallResponse =
      '{"success": true, "response": "", "function_calls": '
      '[{"name": "show_status", "arguments": {}}], "total_time_ms": 42.0}';

  test('parseTranscript sends the transcript, catalog, and on-device options', () async {
    final engine = _FakeEngine(toolCallResponse);
    final service = NeedleSpikeService(engine: engine);

    final result = await service.parseTranscript('is the agent connected');

    expect(result.functionCalls.single.name, 'show_status');
    expect(result.wallLatencyMs, greaterThanOrEqualTo(0));
    final messages = jsonDecode(engine.lastMessagesJson!) as List<dynamic>;
    expect((messages.single as Map)['role'], 'user');
    expect((messages.single as Map)['content'], 'is the agent connected');
    final tools = jsonDecode(engine.lastToolsJson!) as List<dynamic>;
    expect(tools, hasLength(10));
    final options = jsonDecode(engine.lastOptionsJson!) as Map<String, dynamic>;
    expect(options['auto_handoff'], isFalse);
    expect(options['force_tools'], isTrue);
    expect(options['tool_rag_top_k'], 0);
  });

  test('concurrent parse attempts are rejected while busy', () async {
    final engine = _FakeEngine(toolCallResponse);
    final service = NeedleSpikeService(engine: engine);

    final first = service.parseTranscript('one');
    expect(() => service.parseTranscript('two'), throwsStateError);
    await first;
    expect(engine.completeCalls, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/needle_spike/needle_spike_service_test.dart`
Expected: FAIL — files don't exist.

- [ ] **Step 3: Implement the engine wrapper**

Create `lib/features/needle_spike/services/needle_engine.dart`:

```dart
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import '../ffi/cactus.dart' as cactus;

class NeedleEngineException implements Exception {
  const NeedleEngineException(this.message);

  final String message;

  @override
  String toString() => 'NeedleEngineException: $message';
}

abstract interface class NeedleEngineApi {
  bool get isLoaded;
  Future<void> load(String modelDir);
  Future<String> complete({
    required String messagesJson,
    required String toolsJson,
    required String optionsJson,
  });
  Future<void> unload();
}

/// Serializes async operations in submission order. Native engine calls
/// must never overlap: thread-safety of the engine is unknown, and
/// unload() must not destroy a handle another isolate is still using.
class NativeCallQueue {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() op) {
    final result = _tail.then((_) => op());
    _tail = result.then<void>((_) {}, onError: (_) {});
    return result;
  }
}

/// Real FFI engine. Blocking native calls run via [Isolate.run]; the model
/// handle crosses isolates as a raw address (native heap is process-wide).
/// Every op passes through a [NativeCallQueue] so ops execute strictly in
/// submission order: concurrent loads dedupe, and unload waits for any
/// in-flight complete before destroying the handle.
class NeedleEngine implements NeedleEngineApi {
  final NativeCallQueue _queue = NativeCallQueue();
  int? _modelAddress;

  // The _spawn* helpers below MUST stay static: Isolate.run serializes the
  // closure it is given together with its enclosing context. A closure
  // nested inside an instance method captures `this`, which drags in
  // NativeCallQueue._tail (a Future — unsendable) and crashes at send-time.
  // Statics have no `this` in scope, so their closures capture only their
  // sendable parameters.
  static Future<int> _spawnInit(String modelDir) =>
      Isolate.run(() => _initSync(modelDir));

  static Future<String> _spawnComplete(
    int address,
    String messagesJson,
    String toolsJson,
    String optionsJson,
  ) => Isolate.run(
    () => _completeSync(address, messagesJson, toolsJson, optionsJson),
  );

  static Future<void> _spawnDestroy(int address) =>
      Isolate.run(() => _destroySync(address));

  @override
  bool get isLoaded => _modelAddress != null;

  @override
  Future<void> load(String modelDir) {
    return _queue.run(() async {
      // Checked inside the queued op so concurrent loads dedupe instead of
      // both running cactus_init and leaking a handle.
      if (_modelAddress != null) return;
      final address = await _spawnInit(modelDir);
      if (address == 0) {
        throw NeedleEngineException('cactus_init returned null for $modelDir');
      }
      _modelAddress = address;
    });
  }

  @override
  Future<String> complete({
    required String messagesJson,
    required String toolsJson,
    required String optionsJson,
  }) {
    return _queue.run(() {
      // Checked inside the queued op: a queued complete may legitimately
      // run after a queued unload, and must then fail instead of touching
      // a destroyed handle.
      final address = _modelAddress;
      if (address == null) {
        throw const NeedleEngineException('Model is not loaded.');
      }
      return _spawnComplete(address, messagesJson, toolsJson, optionsJson);
    });
  }

  @override
  Future<void> unload() {
    return _queue.run(() async {
      final address = _modelAddress;
      _modelAddress = null;
      if (address != null) {
        await _spawnDestroy(address);
      }
    });
  }
}

const _responseBufferBytes = 64 * 1024;

int _initSync(String modelDir) {
  final path = modelDir.toNativeUtf8();
  try {
    return cactus.cactusInit(path, nullptr, false).address;
  } finally {
    calloc.free(path);
  }
}

String _completeSync(
  int modelAddress,
  String messagesJson,
  String toolsJson,
  String optionsJson,
) {
  final model = Pointer<Void>.fromAddress(modelAddress);
  final messages = messagesJson.toNativeUtf8();
  final tools = toolsJson.toNativeUtf8();
  final options = optionsJson.toNativeUtf8();
  final buffer = calloc<Uint8>(_responseBufferBytes);
  try {
    final written = cactus.cactusComplete(
      model,
      messages,
      buffer.cast<Utf8>(),
      _responseBufferBytes,
      options,
      tools,
      nullptr,
      nullptr,
      nullptr,
      0,
    );
    if (written < 0) {
      throw NeedleEngineException(
        'cactus_complete failed: status $written${_lastErrorSuffix()}',
      );
    }
    if (written >= _responseBufferBytes) {
      throw NeedleEngineException(
        'cactus_complete response truncated '
        '($written bytes; buffer $_responseBufferBytes)',
      );
    }
    return buffer.cast<Utf8>().toDartString(length: written);
  } finally {
    calloc.free(messages);
    calloc.free(tools);
    calloc.free(options);
    calloc.free(buffer);
  }
}

void _destroySync(int modelAddress) {
  cactus.cactusDestroy(Pointer<Void>.fromAddress(modelAddress));
}

/// Formats `cactus_get_last_error` as an exception-message suffix, or ''
/// when there is no error text. Only called on the isolate that just made
/// the failing native call.
String _lastErrorSuffix() {
  final error = cactus.cactusGetLastError();
  if (error == nullptr) return '';
  final text = error.toDartString();
  return text.isEmpty ? '' : ' ($text)';
}
```

Note: the vendored `cactus.dart` declares `cactusComplete`'s buffer parameter as `Pointer<Utf8>` — if `buffer.cast()` needs an explicit type, use `buffer.cast<Utf8>()`. Match whatever the vendored signatures require; do not edit the vendored file.

- [ ] **Step 4: Implement the spike service**

Create `lib/features/needle_spike/services/needle_spike_service.dart`:

```dart
import 'dart:convert';

import 'needle_engine.dart';
import 'needle_result.dart';
import 'needle_tool_catalog.dart';

/// Turns one transcript into one measured Needle inference.
class NeedleSpikeService {
  // Private field behind a public named parameter; an initializing formal
  // would force the parameter to be named `_engine`.
  // ignore: prefer_initializing_formals
  NeedleSpikeService({required NeedleEngineApi engine}) : _engine = engine;

  final NeedleEngineApi _engine;
  bool _busy = false;

  /// Generation options: deterministic, tool-constrained, and strictly
  /// on-device (`auto_handoff` defaults to true upstream — keep it false).
  static const String optionsJson =
      '{"max_tokens": 128, "temperature": 0, "force_tools": true, '
      '"tool_rag_top_k": 0, "auto_handoff": false}';

  bool get busy => _busy;

  Future<NeedleResult> parseTranscript(String transcript) async {
    if (_busy) {
      throw StateError('Needle is already processing a request.');
    }
    _busy = true;
    final stopwatch = Stopwatch()..start();
    try {
      final raw = await _engine.complete(
        messagesJson: jsonEncode([
          {'role': 'user', 'content': transcript},
        ]),
        toolsJson: NeedleToolCatalog.toolsJson,
        optionsJson: optionsJson,
      );
      return NeedleResult.fromEngineJson(
        raw,
        wallLatencyMs: stopwatch.elapsedMilliseconds,
      );
    } finally {
      _busy = false;
    }
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/needle_spike/needle_spike_service_test.dart`
Expected: 2 tests PASS. (`needle_engine.dart` compiles but `NeedleEngine` itself is not executed — the native lib isn't loadable on the host. The FFI lookups in the vendored file are top-level `final`s resolved lazily only on first use, so merely importing is safe. If the test run instead crashes at import time with a `DynamicLibrary.open` failure, split the interface: move `NeedleEngineApi` and `NeedleEngineException` into `needle_engine_api.dart`, have `needle_engine.dart` import it, and make service + tests import only `needle_engine_api.dart`.)

- [ ] **Step 6: Commit**

```bash
git add lib/features/needle_spike/services/needle_engine.dart lib/features/needle_spike/services/needle_spike_service.dart test/features/needle_spike/needle_spike_service_test.dart
git commit -m "spike(needle): isolate-backed FFI engine wrapper and measured parse service"
```

---

### Task 7: Providers and debug screen

**Files:**
- Create: `lib/features/needle_spike/providers/needle_spike_providers.dart`
- Create: `lib/features/needle_spike/screens/needle_spike_screen.dart`
- Test: `test/features/needle_spike/needle_spike_screen_test.dart`

**Interfaces:**
- Consumes: everything from Tasks 2–6, plus `createDefaultVoiceCaptureService()` from `lib/features/voice/services/platform/default_voice_capture_service.dart` and `VoiceCaptureService.capture({required Duration timeout})` → `VoiceCapture { transcript, confidence, ... }` from `lib/shared/voice/voice_capture_service.dart`.
- Produces: `needleEngineProvider` (`Provider<NeedleEngineApi>`), `needleInstallServiceProvider` (`FutureProvider<NeedleModelInstallService>` — resolving the app-support directory is async), `needleSpikeServiceProvider` (`Provider<NeedleSpikeService>`), `needleVoiceCaptureFactoryProvider` (`Provider<VoiceCaptureService? Function()>`), `class NeedleSpikeScreen extends ConsumerStatefulWidget`. Consumed by Task 8's router wiring.

- [ ] **Step 1: Write the providers**

Create `lib/features/needle_spike/providers/needle_spike_providers.dart`:

```dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../shared/voice/voice_capture_service.dart';
import '../../voice/services/platform/default_voice_capture_service.dart';
import '../services/needle_engine.dart';
import '../services/needle_model_install_service.dart';
import '../services/needle_spike_service.dart';

/// Deliberately root-scoped: the loaded model stays resident for the whole
/// app session, and [NeedleEngine.unload] runs only at ProviderContainer
/// teardown — not when the spike screen is popped.
final needleEngineProvider = Provider<NeedleEngineApi>((ref) {
  final engine = NeedleEngine();
  ref.onDispose(engine.unload);
  return engine;
});

/// FutureProvider because resolving the app-support directory is async.
/// The screen consumes it via `ref.read(needleInstallServiceProvider.future)`.
final needleInstallServiceProvider = FutureProvider<NeedleModelInstallService>((
  ref,
) async {
  final support = await getApplicationSupportDirectory();
  return NeedleModelInstallService(supportDirectory: support);
});

final needleSpikeServiceProvider = Provider<NeedleSpikeService>((ref) {
  return NeedleSpikeService(engine: ref.watch(needleEngineProvider));
});

final needleVoiceCaptureFactoryProvider =
    Provider<VoiceCaptureService? Function()>((ref) {
      return createDefaultVoiceCaptureService;
    });
```

Note: with the `FutureProvider`, the `dart:io` import in this file is unused — the import block is exactly: `package:flutter_riverpod/flutter_riverpod.dart`, `package:path_provider/path_provider.dart`, the two relative voice imports, and the three relative spike-service imports shown above.

- [ ] **Step 2: Write the failing widget test**

Create `test/features/needle_spike/needle_spike_screen_test.dart`:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/needle_spike/providers/needle_spike_providers.dart';
import 'package:navivox/features/needle_spike/screens/needle_spike_screen.dart';
import 'package:navivox/features/needle_spike/services/needle_engine.dart';
import 'package:navivox/features/needle_spike/services/needle_model_install_service.dart';

class _FakeEngine implements NeedleEngineApi {
  bool loaded = false;

  @override
  bool get isLoaded => loaded;

  @override
  Future<void> load(String modelDir) async {
    loaded = true;
  }

  @override
  Future<String> complete({
    required String messagesJson,
    required String toolsJson,
    required String optionsJson,
  }) async {
    return '{"success": true, "response": "", "function_calls": '
        '[{"name": "show_status", "arguments": {}}], "total_time_ms": 42.0}';
  }

  @override
  Future<void> unload() async {}
}

/// Lays down a pre-installed fake model and pumps the screen to ready state.
///
/// Directory.systemTemp.createTemp and the screen's own initState model
/// check both use dart:io's real (isolate-backed) async file APIs, which
/// never resolve inside a bare testWidgets pump cycle — they need the real
/// event loop that tester.runAsync provides, plus a short real-time delay
/// so the pending isolate response is delivered before the next pump().
Future<void> _pumpReadyScreen(WidgetTester tester) async {
  final tempDir = await tester.runAsync(
    () => Directory.systemTemp.createTemp('needle_screen'),
  );
  addTearDown(() => tempDir!.delete(recursive: true));
  final install = NeedleModelInstallService(supportDirectory: tempDir!);
  final modelDir = Directory('${tempDir.path}/needle_spike/model')
    ..createSync(recursive: true);
  File('${modelDir.path}/config.json').writeAsStringSync('{}');
  File(
    '${tempDir.path}/needle_spike/.installed',
  ).writeAsStringSync(modelDir.path);

  await tester.runAsync(() async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          needleEngineProvider.overrideWithValue(_FakeEngine()),
          needleInstallServiceProvider.overrideWith((ref) async => install),
          needleVoiceCaptureFactoryProvider.overrideWithValue(() => null),
        ],
        child: const MaterialApp(home: NeedleSpikeScreen()),
      ),
    );
    // Yield to the real event loop long enough for the pending real IO
    // (installedModelDir's File.exists/readAsString) to be delivered.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await tester.pump();
  });
  await tester.pumpAndSettle();
}

/// The result card and scorecard render below the 20-chip bank, which
/// pushes them out of the default test viewport. ListView only mounts
/// visible slivers, so scroll before locating them.
Future<void> _scrollToBottom(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -2000));
  await tester.pumpAndSettle();
}

Future<void> _scrollToTop(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, 2000));
  await tester.pumpAndSettle();
}

Future<void> _runTranscript(WidgetTester tester, String transcript) async {
  await tester.enterText(
    find.byKey(const Key('needle-transcript-field')),
    transcript,
  );
  await tester.tap(find.byKey(const Key('needle-run-button')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'typed transcript produces a parsed tool call and scorecard tick',
    (tester) async {
      await _pumpReadyScreen(tester);
      await _runTranscript(tester, 'is the agent connected');
      await _scrollToBottom(tester);

      expect(find.textContaining('show_status'), findsOneWidget);
      expect(find.textContaining('wall'), findsOneWidget);

      await tester.tap(find.byKey(const Key('needle-verdict-correct')));
      await tester.pump();
      expect(find.textContaining('correct 1'), findsOneWidget);
    },
  );

  testWidgets('verdict buttons only score a real, unscored, current result', (
    tester,
  ) async {
    await _pumpReadyScreen(tester);
    await _scrollToBottom(tester);

    // Before any run there is no result: the verdict buttons are disabled,
    // so tapping one must not record anything.
    await tester.tap(
      find.byKey(const Key('needle-verdict-correct')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(find.textContaining('total 0'), findsOneWidget);

    // Produce a result.
    await _scrollToTop(tester);
    await _runTranscript(tester, 'is the agent connected');
    await _scrollToBottom(tester);

    // First tap scores the result; a second tap must not double-count.
    await tester.tap(find.byKey(const Key('needle-verdict-correct')));
    await tester.pump();
    expect(find.textContaining('correct 1'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('needle-verdict-correct')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(find.textContaining('correct 1'), findsOneWidget);
    expect(find.textContaining('correct 2'), findsNothing);
  });
}
```

Adaptation note (discovered while implementing): the widget test as originally drafted hung indefinitely (10-minute framework timeout, `TimeoutException` stack rooted in `dart:isolate _RawReceivePort._handleMessage`). Root cause: `NeedleModelInstallService.installedModelDir()`'s real `dart:io` async calls (`File.exists()`, `File.readAsString()`) run during the screen's `initState`, and real isolate-backed IO never completes inside a bare `testWidgets` pump cycle — it requires `tester.runAsync()`, plus a genuine real-time yield (`Future.delayed`) after `pumpWidget` for the pending isolate response to be delivered before the next `pump()`. Separately, the 20-chip transcript bank pushes the result card and scorecard below the default test viewport; since `ListView` only mounts visible slivers, the test drags the `ListView` up before asserting on their content, exactly as this plan's original note anticipated ("adapt the test mechanics, never the asserted behaviors"). No production code changed for either fix.

Review-round additions (post-implementation code review): the screen now gates verdict scoring — verdict buttons are enabled only while `_result != null && !_running && !_resultScored`, `_recordVerdict` marks the result scored (each result scores exactly once; a 'scored ✓' line appears in the scorecard card), and `_run` clears the flag when a new run starts. The screen also tracks the in-flight mic capture in a `VoiceCaptureService? _activeCapture` field and fire-and-forgets `cancel()` in `dispose()` so the microphone is released if the user backs out mid-capture. A second widget test covers the scoring gate (disabled before any run; no double-count after scoring). The code blocks above reflect all of this.

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/features/needle_spike/needle_spike_screen_test.dart`
Expected: FAIL — screen doesn't exist.

- [ ] **Step 4: Implement the screen**

Create `lib/features/needle_spike/screens/needle_spike_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/voice/voice_capture_service.dart';
import '../data/needle_test_transcripts.dart';
import '../models/needle_scorecard.dart';
import '../providers/needle_spike_providers.dart';
import '../services/needle_result.dart';

/// Hidden evaluation screen for the Needle spike. Reached only via the
/// NEEDLE_SPIKE-gated route. Transcripts shown here are never logged or
/// persisted; the scorecard keeps counts only.
class NeedleSpikeScreen extends ConsumerStatefulWidget {
  const NeedleSpikeScreen({super.key});

  @override
  ConsumerState<NeedleSpikeScreen> createState() => _NeedleSpikeScreenState();
}

class _NeedleSpikeScreenState extends ConsumerState<NeedleSpikeScreen> {
  final _transcriptController = TextEditingController();
  final _scorecard = NeedleScorecard();

  String? _modelDir;
  bool _preparing = false;
  bool _running = false;
  bool _capturing = false;
  int _downloadedBytes = 0;
  String? _error;
  NeedleResult? _result;

  /// True once the current [_result] has been given a verdict. Gates the
  /// verdict buttons so each result is scored exactly once; cleared when a
  /// new run starts.
  bool _resultScored = false;

  /// The capture service currently recording, if any. Held so dispose can
  /// release the microphone if the user backs out mid-capture.
  VoiceCaptureService? _activeCapture;

  @override
  void initState() {
    super.initState();
    _checkInstalled();
  }

  @override
  void dispose() {
    // Fire-and-forget: release the microphone if a capture is in flight.
    _activeCapture?.cancel();
    _transcriptController.dispose();
    super.dispose();
  }

  Future<void> _checkInstalled() async {
    try {
      final install = await ref.read(needleInstallServiceProvider.future);
      final dir = await install.installedModelDir();
      if (!mounted) return;
      setState(() => _modelDir = dir);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  Future<void> _prepareModel() async {
    setState(() {
      _preparing = true;
      _error = null;
    });
    try {
      final install = await ref.read(needleInstallServiceProvider.future);
      final dir = await install.ensureModel(
        onProgress: (bytes) {
          if (mounted) setState(() => _downloadedBytes = bytes);
        },
      );
      final engine = ref.read(needleEngineProvider);
      await engine.load(dir);
      if (!mounted) return;
      setState(() => _modelDir = dir);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _preparing = false);
    }
  }

  Future<void> _run(String transcript) async {
    final trimmed = transcript.trim();
    if (trimmed.isEmpty || _running) return;
    setState(() {
      _running = true;
      _error = null;
      _result = null;
      _resultScored = false;
    });
    try {
      final engine = ref.read(needleEngineProvider);
      if (!engine.isLoaded) {
        final dir = _modelDir;
        if (dir == null) {
          throw StateError('Download the model first.');
        }
        await engine.load(dir);
      }
      final service = ref.read(needleSpikeServiceProvider);
      final result = await service.parseTranscript(trimmed);
      if (!mounted) return;
      setState(() => _result = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _captureFromMic() async {
    final factory = ref.read(needleVoiceCaptureFactoryProvider);
    final capture = factory();
    if (capture == null) {
      setState(() => _error = 'Speech capture unavailable on this platform.');
      return;
    }
    setState(() {
      _capturing = true;
      _error = null;
    });
    _activeCapture = capture;
    try {
      final result = await capture.capture(
        timeout: const Duration(seconds: 15),
      );
      if (!mounted) return;
      _transcriptController.text = result.transcript;
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      _activeCapture = null;
      if (mounted) setState(() => _capturing = false);
    }
  }

  /// Verdicts may only be recorded against a real, current, not-yet-scored
  /// result — otherwise the tally would drift from the actual runs.
  bool get _canRecordVerdict => _result != null && !_running && !_resultScored;

  void _recordVerdict(NeedleVerdict verdict) {
    if (!_canRecordVerdict) return;
    setState(() {
      _scorecard.record(verdict);
      _resultScored = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Needle spike')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_modelDir == null) _buildInstallCard() else ..._buildEvalUi(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstallCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Needle model is not installed (~16 MB download).'),
            const SizedBox(height: 12),
            if (_preparing)
              Text('Downloading… $_downloadedBytes bytes')
            else
              FilledButton(
                key: const Key('needle-download-button'),
                onPressed: _prepareModel,
                child: const Text('Download and load model'),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEvalUi() {
    final result = _result;
    return [
      TextField(
        key: const Key('needle-transcript-field'),
        controller: _transcriptController,
        decoration: InputDecoration(
          labelText: 'Transcript',
          suffixIcon: IconButton(
            key: const Key('needle-mic-button'),
            icon: Icon(_capturing ? Icons.mic : Icons.mic_none),
            onPressed: _capturing ? null : _captureFromMic,
          ),
        ),
      ),
      const SizedBox(height: 8),
      FilledButton(
        key: const Key('needle-run-button'),
        onPressed: _running ? null : () => _run(_transcriptController.text),
        child: Text(_running ? 'Running…' : 'Run Needle'),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final t in needleTestTranscripts)
            ActionChip(
              label: Text(t.text, overflow: TextOverflow.ellipsis),
              onPressed: _running
                  ? null
                  : () {
                      _transcriptController.text = t.text;
                      _run(t.text);
                    },
            ),
        ],
      ),
      const SizedBox(height: 16),
      if (result != null) _buildResultCard(result),
      const SizedBox(height: 16),
      _buildScorecard(),
    ];
  }

  Widget _buildResultCard(NeedleResult result) {
    final call = result.functionCalls.isEmpty
        ? null
        : result.functionCalls.first;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              call == null
                  ? 'No tool call. Raw response: ${result.response}'
                  : 'Tool: ${call.name}\nArgs: ${call.arguments}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'wall ${result.wallLatencyMs} ms · '
              'engine ${result.totalTimeMs?.toStringAsFixed(1) ?? '—'} ms · '
              'ttft ${result.timeToFirstTokenMs?.toStringAsFixed(1) ?? '—'} ms · '
              'confidence ${result.confidence?.toStringAsFixed(3) ?? '—'}',
            ),
            if (!result.success)
              Text('Engine error: ${result.error ?? 'unknown'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildScorecard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_scorecard.summaryLine),
            if (_resultScored)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('scored ✓'),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  key: const Key('needle-verdict-correct'),
                  onPressed: _canRecordVerdict
                      ? () => _recordVerdict(NeedleVerdict.correct)
                      : null,
                  child: const Text('Correct'),
                ),
                OutlinedButton(
                  key: const Key('needle-verdict-wrong-tool'),
                  onPressed: _canRecordVerdict
                      ? () => _recordVerdict(NeedleVerdict.wrongTool)
                      : null,
                  child: const Text('Wrong tool'),
                ),
                OutlinedButton(
                  key: const Key('needle-verdict-wrong-args'),
                  onPressed: _canRecordVerdict
                      ? () => _recordVerdict(NeedleVerdict.wrongArgs)
                      : null,
                  child: const Text('Wrong args'),
                ),
                OutlinedButton(
                  key: const Key('needle-verdict-no-call'),
                  onPressed: _canRecordVerdict
                      ? () => _recordVerdict(NeedleVerdict.noCall)
                      : null,
                  child: const Text('No call'),
                ),
                TextButton(
                  onPressed: () => setState(_scorecard.reset),
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/needle_spike/needle_spike_screen_test.dart`
Expected: PASS.

- [ ] **Step 6: Run the whole spike test suite and analyzer**

Run: `flutter test test/features/needle_spike && flutter analyze lib/features/needle_spike test/features/needle_spike`
Expected: all PASS, analyze clean.

- [ ] **Step 7: Commit**

```bash
git add lib/features/needle_spike/providers/needle_spike_providers.dart lib/features/needle_spike/screens/needle_spike_screen.dart test/features/needle_spike/needle_spike_screen_test.dart
git commit -m "spike(needle): evaluation debug screen with mic, canned bank, scorecard"
```

---

### Task 8: Gated route and settings entry point

**Files:**
- Modify: `lib/router/routes/app_routes.dart` (add constant)
- Modify: `lib/router/providers/app_router.dart` (conditional top-level route)
- Modify: `lib/features/settings/screens/settings_screen.dart` (guarded entry tile)
- Test: `test/router/needle_spike_route_test.dart`

**Interfaces:**
- Consumes: `needleSpikeEnabled` (Task 2), `NeedleSpikeScreen` (Task 7).
- Produces: `AppRoutes.needleSpike == '/needle-spike'`.

- [ ] **Step 1: Write the failing test** (asserts the route is ABSENT in default builds — this is the gate CI enforces)

Create `test/router/needle_spike_route_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:navivox/features/needle_spike/needle_spike_flag.dart';
import 'package:navivox/router/app_routes.dart';
import 'package:navivox/router/providers/app_router.dart';

void main() {
  test('needle spike route is absent unless NEEDLE_SPIKE is defined', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    final topLevelPaths = router.configuration.routes
        .whereType<GoRoute>()
        .map((r) => r.path);
    if (needleSpikeEnabled) {
      expect(topLevelPaths, contains(AppRoutes.needleSpike));
    } else {
      expect(topLevelPaths, isNot(contains(AppRoutes.needleSpike)));
    }
  });

  // Gated round-trip test (registered only under --dart-define=NEEDLE_SPIKE=true):
  // pump MaterialApp.router with the routerProvider's router (ProviderScope with
  // FakeHermesChannel/FakeHermesEndpointStore overrides plus a never-resolving
  // needleInstallServiceProvider), go('/settings'), push('/needle-spike'), and
  // assert router.canPop() is true, then pop() back to '/settings'. Locks the
  // push-over-Settings behavior so the operator can round-trip during evaluation.
  if (needleSpikeEnabled) {
    testWidgets('pushed spike route stacks over Settings for a round-trip',
        (tester) async {
      // see test/router/needle_spike_route_test.dart for the full harness
    });
  }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/router/needle_spike_route_test.dart`
Expected: FAIL — `AppRoutes.needleSpike` is not defined (compile error).

- [ ] **Step 3: Add the route constant**

In `lib/router/routes/app_routes.dart`, inside `abstract final class AppRoutes`, after `static const settings = '/settings';`:

```dart
  /// Needle spike evaluation screen; registered only in NEEDLE_SPIKE builds.
  static const needleSpike = '/needle-spike';
```

- [ ] **Step 4: Register the conditional route**

In `lib/router/providers/app_router.dart`, add imports:

```dart
import '../../features/needle_spike/needle_spike_flag.dart';
import '../../features/needle_spike/screens/needle_spike_screen.dart';
```

In the `GoRouter(... routes: [...])` list, after the closing `),` of the `ShellRoute(...)` entry, add a top-level route (outside the shell — the spike screen brings its own AppBar and must not appear in shell navigation):

```dart
      if (needleSpikeEnabled)
        GoRoute(
          path: AppRoutes.needleSpike,
          builder: (context, state) => const NeedleSpikeScreen(),
        ),
```

(`needleSpikeEnabled` is a compile-time const, so in default builds this route and all transitively imported spike Dart code are tree-shaken from the AOT snapshot. NOTE: the native `libcactus_engine.so` under `android/app/src/main/jniLibs/` is packaged by Gradle regardless of this flag once built (~4 MB compressed); it is gitignored and only present on machines that ran `scripts/spike/build_cactus_engine.sh`.)

- [ ] **Step 5: Add the guarded settings tile**

In `lib/features/settings/screens/settings_screen.dart`, add imports (with the other feature imports at the top):

```dart
import '../../needle_spike/needle_spike_flag.dart';
```

In the `ListView` `children:` list (after the last existing `_SettingsSectionCard`), add:

```dart
              if (needleSpikeEnabled)
                _SettingsSectionCard(
                  title: 'Needle spike (debug)',
                  icon: Icons.science_outlined,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.play_arrow_outlined),
                      title: const Text('Open Needle evaluation screen'),
                      // push (not go): the spike route is outside the
                      // ShellRoute, so go() would replace the whole match
                      // stack and leave canPop()==false — no back arrow.
                      onTap: () => context.push(AppRoutes.needleSpike),
                    ),
                  ],
                ),
```

(`AppRoutes` and the go_router context extensions are already imported in this file.)

- [ ] **Step 6: Run tests both gated and ungated**

Run: `flutter test test/router/needle_spike_route_test.dart`
Expected: PASS (asserts absence).
Run: `flutter test --dart-define=NEEDLE_SPIKE=true test/router/needle_spike_route_test.dart`
Expected: PASS (asserts presence).

- [ ] **Step 7: Run the full test suite** (regression check on the touched shared files)

Run: `flutter test`
Expected: all PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/router/routes/app_routes.dart lib/router/providers/app_router.dart lib/features/settings/screens/settings_screen.dart test/router/needle_spike_route_test.dart
git commit -m "spike(needle): NEEDLE_SPIKE-gated route and settings entry"
```

---

### Task 9: On-device evaluation and findings doc

**Files:**
- Create: `docs/superpowers/specs/2026-07-13-needle-spike-findings.md` (update the date to the day the evaluation actually runs)

This task is manual + observational; it produces the spike's real deliverable.

- [ ] **Step 1: Build and install the gated release APK**

```bash
scripts/build_send_apk.sh --release --extra-flutter-arg --dart-define=NEEDLE_SPIKE=true
stat -c %s build/app/outputs/flutter-apk/app-release.apk
```

Expected: installs on the attached Android device. Record the APK size; APK delta = this size minus the Task 1 baseline (`/tmp/needle_spike_baseline_apk_bytes.txt`).

- [ ] **Step 2: Run the evaluation on-device**

1. Open Settings → "Needle spike (debug)" → evaluation screen.
2. Tap "Download and load model" (Wi-Fi; ~16 MB). If load fails, the error text on screen is finding #1 — record it verbatim and skip to Step 4.
3. Tap each of the 20 canned transcript chips in order. For each, judge the shown tool call against the chip's intent and tap exactly one verdict button. Note the wall/engine latency of every run (photograph or hand-copy the numbers — do not add logging).
4. Run at least 5 mic-captured utterances (same commands, spoken) and judge them the same way, tallying separately by hand.

- [ ] **Step 3: Sanity-check the gate**

```bash
scripts/build_send_apk.sh --release
```

Open Settings on the device: the "Needle spike (debug)" section must be absent. Reinstalling the ungated APK also confirms default builds are unaffected.

- [ ] **Step 4: Write the findings doc**

Create `docs/superpowers/specs/2026-07-13-needle-spike-findings.md` with the observed values replacing every `<...>`:

```markdown
# Needle Spike — Findings

**Spec:** docs/superpowers/specs/2026-07-13-needle-spike-design.md
**Device:** <model, Android version>
**Engine:** cactus-compute/cactus@49e12567 · needle-cq4 (16.2 MB zip)

## 1. Does it run?
<loaded successfully / failed with error "...">
Coexistence with flutter_onnxruntime (pocket_speech TTS): <build conflicts? runtime issues? tested by playing TTS then running Needle>
- Telemetry kill switch active (CACTUS_NO_CLOUD_TELE=1 set before init): <verified how — e.g. airplane-mode run / traffic capture>

## 2. Accuracy (20 canned transcripts, typed)
| Verdict | Count |
|---|---|
| Correct | <n> |
| Wrong tool | <n> |
| Wrong args | <n> |
| No call | <n> |

Mic-spoken utterances (n=<5+>): <tally + notes on STT-noise sensitivity>

## 3. Size & speed
- APK delta (release, arm64): <bytes> (baseline <bytes> → gated <bytes>)
- Note: libcactus_engine.so ships in the APK regardless of NEEDLE_SPIKE once built locally (Gradle packages jniLibs unconditionally); flag-off APKs on a machine with the .so present are NOT byte-identical to baseline.
- Model download: 16,185,061 bytes zip → <extracted size> on disk
- Latency over the 20 runs: wall p50 <ms> / p95 <ms>; engine-reported p50 <ms>
- First-run model load time: <ms/s>

## 4. Verdict (augment-only; Hermes remains the intelligence source)
| Role | Go/No-go | Why |
|---|---|---|
| Local voice-command router | <> | <> |
| Hybrid pre-router | <> | <> |
| Offline fallback | <> | <> |

**Recommendation:** <proceed to a real integration design for role X / revisit when Y / drop>
```

- [ ] **Step 5: Commit the findings**

```bash
git add docs/superpowers/specs/2026-07-13-needle-spike-findings.md
git commit -m "spike(needle): record on-device evaluation findings"
```

- [ ] **Step 6: Report back**

Present the findings doc to the user. The spike branch stays unmerged; next steps (real integration design via brainstorming, or teardown) are the user's call.
