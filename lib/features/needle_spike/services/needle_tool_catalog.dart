import 'dart:convert';

/// Mock Hermes Wing actions exposed to Needle, in the Cactus/OpenAI tools JSON
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
    _tool(
      'navigate_to_screen',
      'Open one of the app screens.',
      {
        'screen': {
          'type': 'string',
          'enum': ['hermes', 'settings'],
          'description': 'Which screen to open.',
        },
      },
      ['screen'],
    ),
    _tool('start_voice_run', 'Start listening for a voice command.', {}, []),
    _tool('stop_voice_run', 'Stop the current voice capture.', {}, []),
    _tool(
      'toggle_continuous_mode',
      'Turn continuous voice mode on or off.',
      {
        'enabled': {
          'type': 'boolean',
          'description': 'true to enable continuous mode.',
        },
      },
      ['enabled'],
    ),
    _tool(
      'send_message',
      'Send a chat message to the agent.',
      {
        'text': {'type': 'string', 'description': 'The message to send.'},
      },
      ['text'],
    ),
    _tool('new_session', 'Start a fresh chat session.', {}, []),
    _tool(
      'switch_session',
      'Switch to a named chat session.',
      {
        'session_name': {
          'type': 'string',
          'description': 'Name of the session to switch to.',
        },
      },
      ['session_name'],
    ),
    _tool(
      'set_tts_voice',
      'Change the text-to-speech voice.',
      {
        'voice': {'type': 'string', 'description': 'Voice name to use.'},
      },
      ['voice'],
    ),
    _tool(
      'set_speech_rate',
      'Change how fast speech is read aloud.',
      {
        'rate': {
          'type': 'number',
          'description': 'Speech rate multiplier, e.g. 1.0 is normal.',
        },
      },
      ['rate'],
    ),
    _tool('show_status', 'Show the agent connection status.', {}, []),
  ];

  static final String toolsJson = jsonEncode(tools);

  static final Set<String> toolNames = tools
      .map((t) => (t['function'] as Map<String, dynamic>)['name'] as String)
      .toSet();
}
