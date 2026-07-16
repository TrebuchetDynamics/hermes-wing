// Table-driven regression fixture replaying the 20 REAL on-device Needle
// outputs recorded during the spike evaluation (see
// docs/superpowers/specs/2026-07-13-needle-spike-findings.md §2) through the
// real VoiceCommandRouter + VoiceCommandValidator (Tasks 2-4). This locks the
// guardrail behavior: some spike outputs picked the WRONG tool or hallucinated
// an arg, and the assertion in those rows is that the validator's guardrails
// neutralize them (fallthrough or a safe confirm tier) — not that Needle's
// tool choice was correct.
//
// This test must pass immediately. If a row fails, the validator has a gap;
// fix the validator, never this fixture (per the plan's Task 11 gate).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice_commands/core/needle_engine.dart';
import 'package:wing/features/voice_commands/models/voice_command.dart';
import 'package:wing/features/voice_commands/services/voice_command_router.dart';
import 'package:wing/features/voice_commands/services/voice_command_validator.dart';

/// Fixed-response fake: hands back whatever raw engine JSON the case
/// recorded, regardless of what the router asks for.
class _FixedEngine implements NeedleEngineApi {
  _FixedEngine(this._response);

  final String _response;
  bool _loaded = false;

  @override
  bool get isLoaded => _loaded;

  @override
  Future<void> load(String modelDir) async => _loaded = true;

  @override
  Future<String> complete({
    required String messagesJson,
    required String toolsJson,
    required String optionsJson,
  }) async => _response;

  @override
  Future<void> unload() async => _loaded = false;
}

String _rawEngineJson(String toolName, Map<String, Object?> arguments) =>
    jsonEncode({
      'success': true,
      'response': '',
      'function_calls': [
        {'name': toolName, 'arguments': arguments},
      ],
    });

const _context = VoiceCommandContext(
  sessionTitles: ['groceries', 'work notes'],
  voiceNames: ['nova', 'en-GB-standard'],
);

VoiceCommandRouter _routerFor(String toolName, Map<String, Object?> args) =>
    VoiceCommandRouter(
      engine: _FixedEngine(_rawEngineJson(toolName, args)),
      modelDirProvider: () async => '/model',
      contextProvider: () => _context,
    );

// Second context: a Kitten-style Pocket Speech voice catalog (no
// flutter_tts-style locale IDs). Locks two validator properties raw against
// this context rather than replaying a spike transcript: an unknown voice
// name still falls through, and a differently-cased match still snaps to the
// candidate's original casing.
const _kittenContext = VoiceCommandContext(
  sessionTitles: [],
  voiceNames: ['Bella', 'Jasper'],
);

VoiceCommandRouter _routerForKitten(
  String toolName,
  Map<String, Object?> args,
) => VoiceCommandRouter(
  engine: _FixedEngine(_rawEngineJson(toolName, args)),
  modelDirProvider: () async => '/model',
  contextProvider: () => _kittenContext,
);

/// One recorded spike row: the transcript, the RAW engine function_call it
/// actually produced on-device, and the expected validated outcome (null for
/// fallthrough, else the command id / snapped args / tier).
typedef _SpikeCase = ({
  String transcript,
  String toolName,
  Map<String, Object?> rawArgs,
  VoiceCommandId? expectedCommand,
  Map<String, Object?>? expectedArgs,
  VoiceCommandTier? expectedTier,
});

final List<_SpikeCase> _cases = [
  (
    transcript: 'open the settings screen',
    toolName: 'navigate_to_screen',
    rawArgs: const {'screen': 'settings screen'},
    // Enum snap: "settings screen" contains the token "settings".
    expectedCommand: VoiceCommandId.navigateToScreen,
    expectedArgs: const {'screen': 'settings'},
    expectedTier: VoiceCommandTier.instant,
  ),
  (
    transcript: 'take me back to the chat',
    toolName: 'switch_session',
    rawArgs: const {'session_name': 'back'},
    // Wrong tool AND no session named "back" in the fixture context ⇒
    // fallthrough. The guardrail neutralizes the bad tool choice.
    expectedCommand: null,
    expectedArgs: null,
    expectedTier: null,
  ),
  (
    transcript: 'start listening',
    toolName: 'start_voice_run',
    rawArgs: const {},
    expectedCommand: VoiceCommandId.startVoiceRun,
    expectedArgs: const {},
    expectedTier: VoiceCommandTier.confirm,
  ),
  (
    transcript: 'begin a voice command',
    toolName: 'start_voice_run',
    rawArgs: const {},
    expectedCommand: VoiceCommandId.startVoiceRun,
    expectedArgs: const {},
    expectedTier: VoiceCommandTier.confirm,
  ),
  (
    transcript: 'stop listening now',
    toolName: 'stop_voice_run',
    rawArgs: const {},
    expectedCommand: VoiceCommandId.stopVoiceRun,
    expectedArgs: const {},
    expectedTier: VoiceCommandTier.instant,
  ),
  (
    transcript: 'cancel the recording',
    toolName: 'stop_voice_run',
    rawArgs: const {},
    expectedCommand: VoiceCommandId.stopVoiceRun,
    expectedArgs: const {},
    expectedTier: VoiceCommandTier.instant,
  ),
  (
    transcript: 'turn on continuous mode',
    toolName: 'toggle_continuous_mode',
    rawArgs: const {'enabled': true},
    expectedCommand: VoiceCommandId.toggleContinuousMode,
    expectedArgs: const {'enabled': true},
    expectedTier: VoiceCommandTier.confirm,
  ),
  (
    transcript: 'disable hands free mode please',
    toolName: 'toggle_continuous_mode',
    rawArgs: const {'enabled': false},
    expectedCommand: VoiceCommandId.toggleContinuousMode,
    expectedArgs: const {'enabled': false},
    expectedTier: VoiceCommandTier.instant,
  ),
  (
    transcript: 'tell the agent I will be ten minutes late',
    toolName: 'send_message',
    rawArgs: const {'text': 'I will be ten minutes late'},
    // send_message is intentionally absent from the catalog: unmatched
    // transcripts fall through to Hermes, which IS the send path.
    expectedCommand: null,
    expectedArgs: null,
    expectedTier: null,
  ),
  (
    transcript: 'send a message saying good morning',
    toolName: 'send_message',
    rawArgs: const {'text': 'good morning'},
    expectedCommand: null,
    expectedArgs: null,
    expectedTier: null,
  ),
  (
    transcript: 'start a new conversation',
    toolName: 'toggle_continuous_mode',
    rawArgs: const {'enabled': true},
    // Recorded WRONG TOOL for this transcript (should have been
    // new_session). Previously the chip absorbed it (confirm tier, user
    // must approve); the affinity pre-route guard now catches the
    // wrong-tool pick before the chip — "start a new conversation" carries
    // no toggleContinuousMode anchor, so it falls straight through to
    // Hermes (2026-07-14).
    expectedCommand: null,
    expectedArgs: null,
    expectedTier: null,
  ),
  (
    transcript: 'give me a fresh session',
    toolName: 'new_session',
    rawArgs: const {},
    expectedCommand: VoiceCommandId.newSession,
    expectedArgs: const {},
    expectedTier: VoiceCommandTier.confirm,
  ),
  (
    transcript: 'switch to my groceries session',
    toolName: 'switch_session',
    rawArgs: const {'session_name': 'groceries'},
    expectedCommand: VoiceCommandId.switchSession,
    expectedArgs: const {'session_name': 'groceries'},
    expectedTier: VoiceCommandTier.confirm,
  ),
  (
    transcript: 'go to the session called work notes',
    toolName: 'switch_session',
    rawArgs: const {'session_name': 'work notes'},
    expectedCommand: VoiceCommandId.switchSession,
    expectedArgs: const {'session_name': 'work notes'},
    expectedTier: VoiceCommandTier.confirm,
  ),
  (
    transcript: 'change the voice to nova',
    toolName: 'set_tts_voice',
    rawArgs: const {'voice': 'nova'},
    expectedCommand: VoiceCommandId.setTtsVoice,
    expectedArgs: const {'voice': 'nova'},
    expectedTier: VoiceCommandTier.confirm,
  ),
  (
    transcript: 'use the british voice for speech',
    toolName: 'set_tts_voice',
    rawArgs: const {'voice': 'british'},
    // Known voice-alias limitation: "british" does not fuzzy-match
    // 'en-GB-standard' (no substring containment either direction), so this
    // falls through rather than silently picking a voice.
    expectedCommand: null,
    expectedArgs: null,
    expectedTier: null,
  ),
  (
    transcript: 'speak faster please',
    toolName: 'set_tts_voice',
    rawArgs: const {'voice': 'faster'},
    // Recorded wrong tool + nonsense arg; no such voice ⇒ fallthrough.
    expectedCommand: null,
    expectedArgs: null,
    expectedTier: null,
  ),
  (
    transcript: 'slow the reading speed down to half',
    toolName: 'set_speech_rate',
    rawArgs: const {'rate': 0.5},
    expectedCommand: VoiceCommandId.setSpeechRate,
    expectedArgs: const {'rate': 0.5},
    expectedTier: VoiceCommandTier.confirm,
  ),
  (
    transcript: 'is the agent connected',
    toolName: 'show_status',
    rawArgs: const {},
    expectedCommand: VoiceCommandId.showStatus,
    expectedArgs: const {},
    expectedTier: VoiceCommandTier.instant,
  ),
  (
    transcript: 'show me the connection status',
    toolName: 'show_status',
    rawArgs: const {},
    expectedCommand: VoiceCommandId.showStatus,
    expectedArgs: const {},
    expectedTier: VoiceCommandTier.instant,
  ),
];

void main() {
  for (final c in _cases) {
    test(c.transcript, () async {
      final router = _routerFor(c.toolName, c.rawArgs);
      final result = await router.route(c.transcript);

      if (c.expectedCommand == null) {
        expect(result, isNull, reason: c.transcript);
        return;
      }

      expect(result, isNotNull, reason: c.transcript);
      expect(result!.command, c.expectedCommand, reason: c.transcript);
      expect(result.args, c.expectedArgs, reason: c.transcript);
      expect(result.tier, c.expectedTier, reason: c.transcript);
    });
  }

  group('set_tts_voice against a Kitten-style voice context', () {
    test('unknown voice ("nova") falls through — no such voice in this '
        'context', () async {
      final router = _routerForKitten('set_tts_voice', const {'voice': 'nova'});
      final result = await router.route('change the voice to nova');
      expect(result, isNull);
    });

    test('differently-cased match ("bella") snaps to the original-cased '
        'candidate ("Bella")', () async {
      final router = _routerForKitten('set_tts_voice', const {
        'voice': 'bella',
      });
      final result = await router.route('change the voice to bella');
      expect(result, isNotNull);
      expect(result!.command, VoiceCommandId.setTtsVoice);
      expect(result.args, const {'voice': 'Bella'});
      expect(result.tier, VoiceCommandTier.confirm);
    });
  });
}
