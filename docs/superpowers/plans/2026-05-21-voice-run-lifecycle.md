# Voice Run Lifecycle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a client-local Voice run lifecycle to Navivox so voice capture, transcript source, grace-window submission, cancellation, failure, and planned STT/TTS state are represented outside `ChatScreen` while preserving the current `start_turn` transcript fallback.

**Architecture:** Add a core `NavivoxVoiceRun` model and store Voice runs in `NavivoxChannelState`. Add small Voice run actions to `NavivoxChannel`; `GatewayNavivoxChannel` keeps sending the final transcript through the existing WebSocket `start_turn` message. `ChatScreen` keeps Local command parsing and route/Profile contact orchestration, but Voice run lifecycle state moves into channel state.

**Tech Stack:** Flutter, Dart, Riverpod, GoRouter, existing Navivox HTTP/WebSocket gateway, Flutter widget tests.

---

## Precondition

Finish or intentionally pause the Transcript surface rename/extraction before executing this plan. This plan assumes callers use `TranscriptSurface` from:

`/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/lib/features/chat/widgets/transcript_surface.dart`

If the codebase still uses `SimpleChatAdapter`, apply the callback changes in this plan to that current public transcript widget, then rename through the transcript plan before final validation.

## Accepted Scope

- Client-local Voice run lifecycle only.
- Keep final transcript fallback through existing `start_turn`.
- No Gormes endpoint changes.
- No binary audio upload.
- No server TTS playback.
- No provider config editing UI.
- No Local command grammar refactor.
- Add planned enum states for server STT/TTS so later protocol work does not reshape the model.

## File Structure

Create:

- `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/lib/core/protocol/navivox_voice_run.dart`
  - Voice run enums and immutable value object.

- `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/test/core/protocol/navivox_voice_run_test.dart`
  - Model and lifecycle transition tests.

- `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/test/core/channel/navivox_channel_voice_run_test.dart`
  - Channel state and gateway adapter Voice run tests.

Modify:

- `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/lib/core/channel/navivox_channel.dart`
  - Add Voice run state and channel actions.

- `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/lib/core/channel/gateway_navivox_channel.dart`
  - Implement Voice run actions and keep `sendVoice` compatibility.

- `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/lib/core/protocol/navivox_event.dart`
  - Link `NavivoxVoiceMessage` to a Voice run id and status.

- `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/lib/features/chat/screens/chat_screen.dart`
  - Remove pending voice lifecycle fields and use channel Voice run state.

- `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/lib/features/chat/widgets/transcript_surface.dart`
  - Add voice capture lifecycle callbacks.

- `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/test/support/test_navivox_channel.dart`
  - Implement Voice run actions for widget tests.

- `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/test/features/voice/continuous_voice_command_mode_test.dart`
  - Assert Voice run lifecycle behavior.

- `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/test/features/chat/chat_voice_button_test.dart`
  - Assert capture start/failure callbacks from Transcript surface.

---

## Task 1: Add core Voice run model

**Files:**
- Create: `app/lib/core/protocol/navivox_voice_run.dart`
- Create: `app/test/core/protocol/navivox_voice_run_test.dart`

- [ ] **Step 1: Write failing model tests**

Create `app/test/core/protocol/navivox_voice_run_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_voice_run.dart';

void main() {
  test('creates a recording voice run for a profile contact', () {
    final run = NavivoxVoiceRun.recording(
      id: 'voice-1',
      serverId: 'local',
      profileId: 'mineru',
      createdAt: DateTime.utc(2026, 5, 21, 12),
    );

    expect(run.id, 'voice-1');
    expect(run.serverId, 'local');
    expect(run.profileId, 'mineru');
    expect(run.status, NavivoxVoiceRunStatus.recording);
    expect(run.transcriptSource, NavivoxTranscriptSource.device);
    expect(run.ttsStatus, NavivoxTtsStatus.unavailable);
    expect(run.isTerminal, isFalse);
  });

  test('moves a device transcript to pending send without losing metadata', () {
    final run = NavivoxVoiceRun.recording(
      id: 'voice-1',
      serverId: 'local',
      profileId: 'mineru',
      createdAt: DateTime.utc(2026, 5, 21, 12),
    ).withDeviceTranscript(
      transcript: 'check status',
      duration: const Duration(milliseconds: 900),
      confidence: 0.91,
      updatedAt: DateTime.utc(2026, 5, 21, 12, 0, 1),
    );

    expect(run.status, NavivoxVoiceRunStatus.pendingSend);
    expect(run.transcript, 'check status');
    expect(run.duration, const Duration(milliseconds: 900));
    expect(run.confidence, 0.91);
    expect(run.transcriptSource, NavivoxTranscriptSource.device);
  });

  test('submitted completed cancelled and failed statuses are terminal-aware', () {
    final base = NavivoxVoiceRun.recording(
      id: 'voice-1',
      serverId: 'local',
      profileId: 'mineru',
      createdAt: DateTime.utc(2026, 5, 21, 12),
    ).withDeviceTranscript(
      transcript: 'hello',
      duration: const Duration(seconds: 1),
      confidence: 1,
      updatedAt: DateTime.utc(2026, 5, 21, 12, 0, 1),
    );

    expect(base.markSubmitted(requestId: 'req-1').isTerminal, isFalse);
    expect(base.markCompleted().isTerminal, isTrue);
    expect(base.markCancelled('cancelled before send').isTerminal, isTrue);
    expect(base.markFailed('microphone denied').isTerminal, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test test/core/protocol/navivox_voice_run_test.dart
```

Expected: FAIL because `navivox_voice_run.dart` does not exist.

- [ ] **Step 3: Implement the minimal Voice run model**

Create `app/lib/core/protocol/navivox_voice_run.dart`:

```dart
enum NavivoxVoiceRunStatus {
  idle,
  recording,
  transcribing,
  pendingSend,
  submitted,
  serverProcessing,
  serverSttComplete,
  agentTurnRunning,
  ttsQueued,
  ttsReady,
  playing,
  completed,
  cancelled,
  failed,
}

enum NavivoxTranscriptSource { device, manual, server }

enum NavivoxTtsStatus { unavailable, queued, ready, playing, stopped, failed }

class NavivoxVoiceRun {
  const NavivoxVoiceRun({
    required this.id,
    required this.serverId,
    required this.profileId,
    required this.status,
    required this.transcriptSource,
    required this.ttsStatus,
    required this.createdAt,
    required this.updatedAt,
    this.sessionId,
    this.requestId,
    this.transcript,
    this.duration,
    this.confidence,
    this.reason,
    this.retentionPolicy = 'transcript_only',
  });

  factory NavivoxVoiceRun.recording({
    required String id,
    required String serverId,
    required String profileId,
    required DateTime createdAt,
  }) {
    return NavivoxVoiceRun(
      id: id,
      serverId: serverId,
      profileId: profileId,
      status: NavivoxVoiceRunStatus.recording,
      transcriptSource: NavivoxTranscriptSource.device,
      ttsStatus: NavivoxTtsStatus.unavailable,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  final String id;
  final String serverId;
  final String profileId;
  final String? sessionId;
  final String? requestId;
  final NavivoxVoiceRunStatus status;
  final NavivoxTranscriptSource transcriptSource;
  final NavivoxTtsStatus ttsStatus;
  final String? transcript;
  final Duration? duration;
  final double? confidence;
  final String? reason;
  final String retentionPolicy;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isTerminal => switch (status) {
    NavivoxVoiceRunStatus.completed ||
    NavivoxVoiceRunStatus.cancelled ||
    NavivoxVoiceRunStatus.failed => true,
    _ => false,
  };

  NavivoxVoiceRun withDeviceTranscript({
    required String transcript,
    required Duration duration,
    required double confidence,
    required DateTime updatedAt,
  }) {
    return copyWith(
      status: NavivoxVoiceRunStatus.pendingSend,
      transcriptSource: NavivoxTranscriptSource.device,
      transcript: transcript,
      duration: duration,
      confidence: confidence,
      updatedAt: updatedAt,
    );
  }

  NavivoxVoiceRun markSubmitted({required String requestId, String? sessionId}) {
    return copyWith(
      status: NavivoxVoiceRunStatus.submitted,
      requestId: requestId,
      sessionId: sessionId,
    );
  }

  NavivoxVoiceRun markCompleted() {
    return copyWith(status: NavivoxVoiceRunStatus.completed);
  }

  NavivoxVoiceRun markCancelled(String reason) {
    return copyWith(status: NavivoxVoiceRunStatus.cancelled, reason: reason);
  }

  NavivoxVoiceRun markFailed(String reason) {
    return copyWith(status: NavivoxVoiceRunStatus.failed, reason: reason);
  }

  NavivoxVoiceRun copyWith({
    String? sessionId,
    String? requestId,
    NavivoxVoiceRunStatus? status,
    NavivoxTranscriptSource? transcriptSource,
    NavivoxTtsStatus? ttsStatus,
    String? transcript,
    Duration? duration,
    double? confidence,
    String? reason,
    String? retentionPolicy,
    DateTime? updatedAt,
  }) {
    return NavivoxVoiceRun(
      id: id,
      serverId: serverId,
      profileId: profileId,
      sessionId: sessionId ?? this.sessionId,
      requestId: requestId ?? this.requestId,
      status: status ?? this.status,
      transcriptSource: transcriptSource ?? this.transcriptSource,
      ttsStatus: ttsStatus ?? this.ttsStatus,
      transcript: transcript ?? this.transcript,
      duration: duration ?? this.duration,
      confidence: confidence ?? this.confidence,
      reason: reason ?? this.reason,
      retentionPolicy: retentionPolicy ?? this.retentionPolicy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test test/core/protocol/navivox_voice_run_test.dart
```

Expected: PASS.

- [ ] **Step 5: Format changed files**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
dart format lib/core/protocol/navivox_voice_run.dart test/core/protocol/navivox_voice_run_test.dart
```

Expected: formatter exits 0.

---

## Task 2: Add Voice run state and channel actions

**Files:**
- Modify: `app/lib/core/channel/navivox_channel.dart`
- Modify: `app/test/support/test_navivox_channel.dart`
- Create: `app/test/core/channel/navivox_channel_voice_run_test.dart`

- [ ] **Step 1: Write failing channel state tests**

Create `app/test/core/channel/navivox_channel_voice_run_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_voice_run.dart';

import '../../support/test_navivox_channel.dart';

void main() {
  test('channel state exposes voice runs in insertion order', () {
    final first = NavivoxVoiceRun.recording(
      id: 'voice-1',
      serverId: 'local',
      profileId: 'mineru',
      createdAt: DateTime.utc(2026, 5, 21, 12),
    );
    final second = NavivoxVoiceRun.recording(
      id: 'voice-2',
      serverId: 'local',
      profileId: 'support',
      createdAt: DateTime.utc(2026, 5, 21, 12, 1),
    );

    final state = NavivoxChannelState(voiceRuns: {
      first.id: first,
      second.id: second,
    });

    expect(state.voiceRunsList.map((run) => run.id), ['voice-1', 'voice-2']);
    expect(state.activeVoiceRun?.id, 'voice-2');
  });

  test('test channel can create stage cancel fail and submit voice runs', () {
    final channel = TestNavivoxChannel()
      ..seedProfileContacts(const [
        NavivoxProfileContact(
          serverId: 'local',
          profileId: 'mineru',
          displayName: 'Mineru',
          serverLabel: 'local',
          health: NavivoxProfileHealth.online,
          latestPreview: 'Ready',
          micAvailable: true,
        ),
      ], selectedKey: 'local::mineru');

    final id = channel.startVoiceRun();
    expect(channel.state.activeVoiceRun?.status, NavivoxVoiceRunStatus.recording);

    channel.stageVoiceRunTranscript(
      voiceRunId: id,
      transcript: 'check status',
      duration: const Duration(milliseconds: 900),
      confidence: 0.9,
    );
    expect(channel.state.voiceRuns[id]?.status, NavivoxVoiceRunStatus.pendingSend);

    channel.submitVoiceRun(id);
    expect(channel.sentVoiceTranscripts, ['check status']);
    expect(channel.state.voiceRuns[id]?.status, NavivoxVoiceRunStatus.submitted);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test test/core/channel/navivox_channel_voice_run_test.dart
```

Expected: FAIL because channel state and actions do not exist.

- [ ] **Step 3: Extend channel state and interface**

In `navivox_channel.dart`, import the model:

```dart
import '../protocol/navivox_voice_run.dart';
```

Add to `NavivoxChannelState` constructor and fields:

```dart
this.voiceRuns = const {},
this.activeVoiceRunId,
```

```dart
final Map<String, NavivoxVoiceRun> voiceRuns;
final String? activeVoiceRunId;

List<NavivoxVoiceRun> get voiceRunsList => voiceRuns.values.toList();
NavivoxVoiceRun? get activeVoiceRun => activeVoiceRunId == null
    ? null
    : voiceRuns[activeVoiceRunId];
```

Add to `copyWith`:

```dart
Map<String, NavivoxVoiceRun>? voiceRuns,
String? activeVoiceRunId,
```

and pass:

```dart
voiceRuns: voiceRuns ?? this.voiceRuns,
activeVoiceRunId: activeVoiceRunId ?? this.activeVoiceRunId,
```

Add methods to `NavivoxChannel`:

```dart
String startVoiceRun();
void stageVoiceRunTranscript({
  required String voiceRunId,
  required String transcript,
  required Duration duration,
  required double confidence,
  NavivoxTranscriptSource transcriptSource = NavivoxTranscriptSource.device,
});
void cancelVoiceRun(String voiceRunId, {String reason});
void failVoiceRun(String voiceRunId, {required String reason});
void submitVoiceRun(String voiceRunId);
```

- [ ] **Step 4: Implement test channel actions**

In `test_navivox_channel.dart`, import `navivox_voice_run.dart` and implement the new methods. Use this behavior:

```dart
@override
String startVoiceRun() {
  final active = _state.activeProfileContact;
  final id = 'test-voice-${++_messageCounter}';
  final run = NavivoxVoiceRun.recording(
    id: id,
    serverId: active?.serverId ?? 'navivox-gateway',
    profileId: active?.profileId ?? 'default',
    createdAt: DateTime.utc(2026, 5, 16, 12, 0, _messageCounter),
  );
  final runs = Map<String, NavivoxVoiceRun>.from(_state.voiceRuns);
  runs[id] = run;
  state = _state.copyWith(voiceRuns: runs, activeVoiceRunId: id);
  return id;
}

@override
void stageVoiceRunTranscript({
  required String voiceRunId,
  required String transcript,
  required Duration duration,
  required double confidence,
  NavivoxTranscriptSource transcriptSource = NavivoxTranscriptSource.device,
}) {
  final run = _state.voiceRuns[voiceRunId];
  if (run == null) return;
  final runs = Map<String, NavivoxVoiceRun>.from(_state.voiceRuns);
  runs[voiceRunId] = run.withDeviceTranscript(
    transcript: transcript,
    duration: duration,
    confidence: confidence,
    updatedAt: DateTime.utc(2026, 5, 16, 12, 1),
  );
  state = _state.copyWith(voiceRuns: runs, activeVoiceRunId: voiceRunId);
}

@override
void cancelVoiceRun(String voiceRunId, {String reason = 'cancelled before send'}) {
  final run = _state.voiceRuns[voiceRunId];
  if (run == null) return;
  final runs = Map<String, NavivoxVoiceRun>.from(_state.voiceRuns);
  runs[voiceRunId] = run.markCancelled(reason);
  state = _state.copyWith(voiceRuns: runs, activeVoiceRunId: voiceRunId);
}

@override
void failVoiceRun(String voiceRunId, {required String reason}) {
  final run = _state.voiceRuns[voiceRunId];
  if (run == null) return;
  final runs = Map<String, NavivoxVoiceRun>.from(_state.voiceRuns);
  runs[voiceRunId] = run.markFailed(reason);
  state = _state.copyWith(voiceRuns: runs, activeVoiceRunId: voiceRunId);
}

@override
void submitVoiceRun(String voiceRunId) {
  final run = _state.voiceRuns[voiceRunId];
  final transcript = run?.transcript?.trim() ?? '';
  if (run == null || transcript.isEmpty) return;
  sentVoiceTranscripts.add(transcript);
  final runs = Map<String, NavivoxVoiceRun>.from(_state.voiceRuns);
  runs[voiceRunId] = run.markSubmitted(requestId: 'test-request-$voiceRunId');
  state = _state.copyWith(voiceRuns: runs, activeVoiceRunId: voiceRunId);
}
```

- [ ] **Step 5: Run channel tests**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test test/core/channel/navivox_channel_voice_run_test.dart
```

Expected: PASS.

- [ ] **Step 6: Format changed files**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
dart format lib/core/channel/navivox_channel.dart test/support/test_navivox_channel.dart test/core/channel/navivox_channel_voice_run_test.dart
```

Expected: formatter exits 0.

---

## Task 3: Implement GatewayNavivoxChannel Voice run lifecycle

**Files:**
- Modify: `app/lib/core/channel/gateway_navivox_channel.dart`
- Modify: `app/lib/core/protocol/navivox_event.dart`
- Modify: `app/test/core/channel/gateway_navivox_channel_test.dart`

- [ ] **Step 1: Write failing gateway Voice run tests**

Append tests to `gateway_navivox_channel_test.dart`:

```dart
test('voice run submits transcript through existing start_turn path', () async {
  final server = await _FakeGatewayServer.start();
  addTearDown(server.close);

  final channel = GatewayNavivoxChannel();
  addTearDown(channel.dispose);

  await channel.connect(baseUrl: server.baseUrl, token: _FakeGatewayServer.token);

  final voiceRunId = channel.startVoiceRun();
  channel.stageVoiceRunTranscript(
    voiceRunId: voiceRunId,
    transcript: 'hello by voice',
    duration: const Duration(milliseconds: 800),
    confidence: 0.88,
  );
  channel.submitVoiceRun(voiceRunId);

  final sent = await server.nextClientMessage;
  expect(sent['type'], 'start_turn');
  expect(sent['text'], 'hello by voice');

  final run = channel.state.voiceRuns[voiceRunId];
  expect(run?.status, NavivoxVoiceRunStatus.submitted);
  expect(run?.requestId, isNotEmpty);

  final voiceMessages = channel.state.messagesList
      .where((message) => message.kind == NavivoxMessageKind.voice)
      .toList();
  expect(voiceMessages, hasLength(1));
  expect(voiceMessages.single.voice?.voiceRunId, voiceRunId);
});

test('cancelled voice run does not send a gateway turn', () async {
  final server = await _FakeGatewayServer.start();
  addTearDown(server.close);

  final channel = GatewayNavivoxChannel();
  addTearDown(channel.dispose);

  await channel.connect(baseUrl: server.baseUrl, token: _FakeGatewayServer.token);

  final voiceRunId = channel.startVoiceRun();
  channel.stageVoiceRunTranscript(
    voiceRunId: voiceRunId,
    transcript: 'do not send',
    duration: const Duration(milliseconds: 800),
    confidence: 0.88,
  );
  channel.cancelVoiceRun(voiceRunId);

  expect(channel.state.voiceRuns[voiceRunId]?.status, NavivoxVoiceRunStatus.cancelled);
  expect(channel.state.messagesList.where((m) => m.kind == NavivoxMessageKind.voice), isEmpty);
});
```

Also import:

```dart
import 'package:navivox/core/protocol/navivox_voice_run.dart';
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test test/core/channel/gateway_navivox_channel_test.dart
```

Expected: FAIL because `GatewayNavivoxChannel` has not implemented the new methods and `NavivoxVoiceMessage.voiceRunId` does not exist.

- [ ] **Step 3: Link voice messages to Voice runs**

In `navivox_event.dart`, update `NavivoxVoiceMessage`:

```dart
class NavivoxVoiceMessage {
  const NavivoxVoiceMessage({
    required this.duration,
    required this.transcript,
    required this.confidence,
    this.voiceRunId,
    this.status,
  });

  final String? voiceRunId;
  final Duration duration;
  final String transcript;
  final double confidence;
  final NavivoxVoiceRunStatus? status;
}
```

Import:

```dart
import 'navivox_voice_run.dart';
```

- [ ] **Step 4: Implement GatewayNavivoxChannel actions**

In `gateway_navivox_channel.dart`, import the Voice run model and add helper methods that update `_state.voiceRuns`.

Use this behavior:

- `startVoiceRun` creates a recording run for `_state.activeProfileContact` or the default gateway profile.
- `stageVoiceRunTranscript` updates the run to `pendingSend`.
- `cancelVoiceRun` marks the run cancelled and does not send a gateway turn.
- `failVoiceRun` marks the run failed and appends a safe system message.
- `submitVoiceRun` sends `NavivoxGatewayMessage.startTurn` with the run transcript and same Profile contact metadata as text turns, adds a voice `NavivoxChatMessage`, and marks the run submitted.
- Existing `sendVoice({required transcript})` stays as compatibility: create a run, stage it, submit it.

- [ ] **Step 5: Run gateway tests**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test test/core/channel/gateway_navivox_channel_test.dart
```

Expected: PASS.

- [ ] **Step 6: Format changed files**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
dart format lib/core/channel/gateway_navivox_channel.dart lib/core/protocol/navivox_event.dart test/core/channel/gateway_navivox_channel_test.dart
```

Expected: formatter exits 0.

---

## Task 4: Move ChatScreen pending voice lifecycle into channel state

**Files:**
- Modify: `app/lib/features/chat/screens/chat_screen.dart`
- Modify: `app/lib/features/chat/widgets/transcript_surface.dart`
- Modify: `app/test/features/chat/chat_voice_button_test.dart`
- Modify: `app/test/features/voice/continuous_voice_command_mode_test.dart`

- [ ] **Step 1: Write failing widget tests for Voice run lifecycle**

In `continuous_voice_command_mode_test.dart`, add these expectations to existing voice tests:

- In `trusted healthy voice capture shows grace and can cancel`, after tapping mic and pumping one frame:

```dart
expect(channel.state.activeVoiceRun?.status, NavivoxVoiceRunStatus.pendingSend);
expect(channel.state.activeVoiceRun?.transcript, 'check status');
```

After tapping Cancel:

```dart
expect(channel.state.activeVoiceRun?.status, NavivoxVoiceRunStatus.cancelled);
```

- In `trusted voice capture auto-sends after grace`, after the grace duration:

```dart
expect(channel.state.activeVoiceRun?.status, NavivoxVoiceRunStatus.submitted);
expect(channel.state.activeVoiceRun?.transcript, 'summarize workspace');
```

- In `typed command switches profile locally and is not sent`, after sending `navi mineru`:

```dart
expect(channel.state.voiceRuns, isEmpty);
```

Import:

```dart
import 'package:navivox/core/protocol/navivox_voice_run.dart';
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test test/features/voice/continuous_voice_command_mode_test.dart
```

Expected: FAIL because `ChatScreen` still uses local pending voice fields rather than channel Voice run state.

- [ ] **Step 3: Add Transcript surface lifecycle callbacks**

In `TranscriptSurface`, add constructor fields:

```dart
this.onVoiceCaptureStarted,
this.onVoiceCaptureFailed,
```

and properties:

```dart
final VoidCallback? onVoiceCaptureStarted;
final ValueChanged<Object>? onVoiceCaptureFailed;
```

In the mic capture flow, call `widget.onVoiceCaptureStarted?.call();` immediately before awaiting `service.capture(...)`. In the `catch (e)` block, call `widget.onVoiceCaptureFailed?.call(e);` after setting `_captureError`.

- [ ] **Step 4: Replace ChatScreen pending voice fields**

Remove lifecycle ownership fields from `_ChatScreenState`:

```dart
VoiceCapture? _pendingVoice;
DateTime? _pendingVoiceCreatedAt;
```

Keep only the timer needed to schedule submission:

```dart
String? _pendingVoiceRunId;
Timer? _pendingVoiceTimer;
```

Change pending message construction to derive from `state.activeVoiceRun` when its status is `pendingSend`.

In `TranscriptSurface(...)`, pass:

```dart
onVoiceCaptureStarted: () {
  _pendingVoiceRunId = channel.startVoiceRun();
},
onVoiceCaptureFailed: (error) {
  final id = _pendingVoiceRunId;
  if (id != null) {
    channel.failVoiceRun(id, reason: 'Voice capture failed.');
  }
  _pendingVoiceRunId = null;
},
```

In `_handleVoiceCapture`, after Local command check, use the existing `_pendingVoiceRunId` or `channel.startVoiceRun()`, then call `channel.stageVoiceRunTranscript(...)`. On grace timeout, call `channel.submitVoiceRun(id)`.

In `_cancelPendingVoice`, call `channel.cancelVoiceRun(id)` instead of deleting local state. Clear `_pendingVoiceRunId` and show the same notice.

- [ ] **Step 5: Run voice command tests**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test test/features/voice/continuous_voice_command_mode_test.dart
```

Expected: PASS.

- [ ] **Step 6: Run chat voice button tests**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test test/features/chat/chat_voice_button_test.dart
```

Expected: PASS.

- [ ] **Step 7: Format changed files**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
dart format lib/features/chat/screens/chat_screen.dart lib/features/chat/widgets/transcript_surface.dart test/features/chat/chat_voice_button_test.dart test/features/voice/continuous_voice_command_mode_test.dart
```

Expected: formatter exits 0.

---

## Task 5: Add read-only Profile contact voice capability state

**Files:**
- Modify: `app/lib/core/channel/navivox_channel.dart`
- Modify: `app/lib/core/channel/gateway_navivox_channel.dart`
- Modify: `app/test/core/channel/gateway_navivox_channel_test.dart`
- Modify: `app/test/features/chat/profile_contact_list_test.dart`

- [ ] **Step 1: Write failing capability decode test**

In `gateway_navivox_channel_test.dart`, extend the profile contact JSON in `loads profile contacts from snapshot and applies gateway updates` with:

```dart
'voice_capability': {
  'device_stt': 'available',
  'server_stt': 'planned',
  'server_tts': 'planned',
  'disabled_reason': '',
  'recovery_action': '',
},
```

Assert:

```dart
expect(contact.voiceCapability.deviceStt, 'available');
expect(contact.voiceCapability.serverStt, 'planned');
expect(contact.voiceCapability.serverTts, 'planned');
expect(contact.voiceCapability.enabled, isTrue);
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test test/core/channel/gateway_navivox_channel_test.dart
```

Expected: FAIL because `voiceCapability` does not exist.

- [ ] **Step 3: Add capability model**

In `navivox_channel.dart`, add:

```dart
class NavivoxVoiceCapability {
  const NavivoxVoiceCapability({
    this.deviceStt = 'unavailable',
    this.serverStt = 'unavailable',
    this.serverTts = 'unavailable',
    this.disabledReason = '',
    this.recoveryAction = '',
  });

  final String deviceStt;
  final String serverStt;
  final String serverTts;
  final String disabledReason;
  final String recoveryAction;

  bool get enabled => disabledReason.trim().isEmpty;
}
```

Add to `NavivoxProfileContact`:

```dart
this.voiceCapability = const NavivoxVoiceCapability(),
```

```dart
final NavivoxVoiceCapability voiceCapability;
```

- [ ] **Step 4: Decode capability from gateway JSON**

In `GatewayNavivoxChannel._profileContactFromJson`, parse `voice_capability` when present. If absent, preserve current behavior:

- `deviceStt`: `available` when `mic_available == true`, else `unavailable`
- `serverStt`: `unavailable`
- `serverTts`: `unavailable`
- `disabledReason`: empty when mic is available, otherwise `mic unavailable`

- [ ] **Step 5: Run capability tests**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test test/core/channel/gateway_navivox_channel_test.dart test/features/chat/profile_contact_list_test.dart
```

Expected: PASS.

- [ ] **Step 6: Format changed files**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
dart format lib/core/channel/navivox_channel.dart lib/core/channel/gateway_navivox_channel.dart test/core/channel/gateway_navivox_channel_test.dart test/features/chat/profile_contact_list_test.dart
```

Expected: formatter exits 0.

---

## Task 6: Document future server voice stream events without implementing protocol changes

**Files:**
- Modify: `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/navivox-architecture.md`
- Modify: `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/navivox-testing-plan.md`

- [ ] **Step 1: Update architecture doc**

In `navivox-architecture.md` under `## 10. Voice Architecture`, add a subsection:

```markdown
### 10.1 Client-local Voice run first

The first Voice run slice is client-local. Navivox records lifecycle metadata,
transcript source, pending-send/cancel/failure state, and planned STT/TTS
status while continuing to submit the final transcript through the existing
`start_turn` path.

Server voice events are future work. Planned event names are:

- `voice_run_started`
- `voice_transcript_partial`
- `voice_transcript_final`
- `voice_server_stt_complete`
- `voice_tts_ready`
- `voice_playback_started`
- `voice_playback_stopped`
- `voice_error`

These names are not active protocol until Gormes emits at least one of them.
Binary audio transport remains deferred until Voice run lifecycle,
retention/redaction policy, and a server STT/TTS event contract exist.
```

- [ ] **Step 2: Update testing plan**

In `navivox-testing-plan.md` under Flutter widget tests, add Voice run rows:

```markdown
### 4.5 Voice Run Lifecycle

| Test | Expected |
|------|----------|
| Capture starts | Voice run enters `recording`. |
| Device transcript ready | Voice run enters `pending_send` with `transcript_source=device`. |
| Grace cancel | Voice run enters `cancelled`; no gateway turn is sent. |
| Grace complete | Voice run enters `submitted`; existing `start_turn` receives final transcript. |
| Local command | No Voice run is created and no gateway turn is sent. |
| Capture failure | Voice run enters `failed` with safe recovery copy. |
```

- [ ] **Step 3: Run docs checks**

Run:

```bash
cd /home/xel/git/sages-openclaw
git diff --check -- workspace-mineru/navivox-app/navivox-architecture.md workspace-mineru/navivox-app/navivox-testing-plan.md
```

Expected: exit 0.

---

## Task 7: Full validation and commit decision

**Files:**
- All files touched by Tasks 1 through 6.

- [ ] **Step 1: Run focused tests**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test \
  test/core/protocol/navivox_voice_run_test.dart \
  test/core/channel/navivox_channel_voice_run_test.dart \
  test/core/channel/gateway_navivox_channel_test.dart \
  test/features/chat/chat_voice_button_test.dart \
  test/features/chat/profile_contact_list_test.dart \
  test/features/voice/continuous_voice_command_mode_test.dart
```

Expected: PASS.

- [ ] **Step 2: Run full Flutter test suite**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test
```

Expected: PASS. If unrelated WIP fails, capture the first failing test name and first error line; do not claim full suite green.

- [ ] **Step 3: Run formatting and diff checks**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
dart format lib test
cd /home/xel/git/sages-openclaw
git diff --check -- workspace-mineru/navivox-app
```

Expected: formatter exits 0; diff check exits 0.

- [ ] **Step 4: Commit/push only if Navivox ownership is resolved**

If `navivox-app` is still untracked in the parent repo, do not stage partial files. Report:

```bash
git status --short -- workspace-mineru/navivox-app
```

If the app has been made trackable as a complete repo or submodule, commit and push the validated slice:

```bash
cd /home/xel/git/sages-openclaw
git add workspace-mineru/navivox-app
git commit -m "feat(navivox): add client-local voice run lifecycle"
git push origin docs/normalize-bin-gormes-to-gormes
```

---

## Self-Review

### Spec coverage

- Voice run canonical term: Task 1 model and Task 6 docs.
- Metadata/lifecycle only: Tasks 1 through 4; no task adds audio upload or playback.
- Server STT planned state: Task 1 enum and Task 6 docs.
- Server TTS planned state: Task 1 enum and Task 6 docs.
- Core protocol/channel ownership: Tasks 1 through 3.
- Local command stays in ChatScreen and creates no Voice run: Task 4 tests.
- Client-local first and `start_turn` fallback: Task 3 tests.
- Gateway reducer planned later: Task 6 docs only.
- Voice control plane future: Task 6 docs only.
- STT/TTS capability first as read-only Profile contact state: Task 5.
- Binary audio deferral: Task 6 docs.

### Placeholder scan

No implementation step requires unspecified behavior. All new names, tests, and commands are explicit.

### Type consistency

The model type is `NavivoxVoiceRun`. Channel state stores `Map<String, NavivoxVoiceRun> voiceRuns`. Public actions use `voiceRunId`. Existing transcript fallback remains `sendVoice({required String transcript})` and `start_turn`.
