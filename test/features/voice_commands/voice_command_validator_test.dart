import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice_commands/core/needle_result.dart';
import 'package:wing/features/voice_commands/models/voice_command.dart';
import 'package:wing/features/voice_commands/services/voice_command_validator.dart';

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
    expect(
      run('toggle_continuous_mode', {'enabled': 'off'})!.tier,
      VoiceCommandTier.instant,
    );
    expect(
      run('toggle_continuous_mode', {'enabled': true})!.tier,
      VoiceCommandTier.confirm,
    );
    expect(run('toggle_continuous_mode', {'enabled': 'maybe'}), isNull);
  });

  test('rate parses and clamps; junk falls through', () {
    expect(run('set_speech_rate', {'rate': 0.5})!.args['rate'], 0.5);
    expect(run('set_speech_rate', {'rate': '9'})!.args['rate'], 3.0);
    expect(run('set_speech_rate', {'rate': 'faster'}), isNull);
  });

  test('session fuzzy-snaps to a real title or falls through', () {
    expect(
      run('switch_session', {
        'session_name': 'Groceries',
      })!.args['session_name'],
      'groceries',
    );
    expect(
      run('switch_session', {'session_name': 'work'})!.args['session_name'],
      'work notes',
    );
    expect(run('switch_session', {'session_name': 'poetry'}), isNull);
  });

  test('voice fuzzy-snaps; the spike wrong-tool artifact falls through', () {
    expect(run('set_tts_voice', {'voice': 'nova'})!.args['voice'], 'nova');
    // The spike produced set_tts_voice{voice: faster} for "speak faster
    // please" — an unresolvable voice must fall through, not execute.
    expect(run('set_tts_voice', {'voice': 'faster'}), isNull);
  });

  test('non-primitive arg values fall through instead of snapping', () {
    expect(
      run('navigate_to_screen', {
        'screen': {'nested': true},
      }),
      isNull,
    );
    expect(
      run('navigate_to_screen', {
        'screen': ['settings'],
      }),
      isNull,
    );
    expect(
      run('toggle_continuous_mode', {
        'enabled': {'value': false},
      }),
      isNull,
    );
    expect(
      run('set_speech_rate', {
        'rate': ['1.0'],
      }),
      isNull,
    );
    expect(
      run('switch_session', {
        'session_name': {'title': 'groceries'},
      }),
      isNull,
    );
    expect(
      run('set_tts_voice', {
        'voice': ['nova'],
      }),
      isNull,
    );
  });

  test('no-arg commands validate to their tier', () {
    expect(run('show_status', {})!.tier, VoiceCommandTier.instant);
    expect(run('new_session', {})!.tier, VoiceCommandTier.confirm);
    expect(run('start_voice_run', {})!.tier, VoiceCommandTier.confirm);
    expect(run('stop_voice_run', {})!.tier, VoiceCommandTier.instant);
  });
}
