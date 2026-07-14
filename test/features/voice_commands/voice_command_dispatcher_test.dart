import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/hermes/models/hermes_session.dart';
import 'package:navivox/features/voice_commands/models/voice_command.dart';
import 'package:navivox/features/voice_commands/services/voice_command_dispatcher.dart';
import 'package:navivox/router/app_routes.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';

/// Records every setter call instead of touching real prefs/Riverpod state —
/// the dispatcher only needs the three setters, never the full controller.
class _RecordingSettingsSink implements VoiceCommandSettingsSink {
  bool? continuousEnabled;
  double? speechRate;
  String? ttsVoiceName;

  @override
  void setContinuousVoiceEnabled(bool enabled) => continuousEnabled = enabled;

  @override
  void setSpeechRate(double rate) => speechRate = rate;

  @override
  void setTtsVoiceName(String? name) => ttsVoiceName = name;
}

class _Recorder {
  final navigated = <String>[];
  final notices = <String>[];
  int stopCalls = 0;
  int startCalls = 0;
  final settings = _RecordingSettingsSink();
}

VoiceCommandDispatcher _dispatcher(FakeHermesChannel channel, _Recorder r) {
  return VoiceCommandDispatcher(
    channel: () => channel,
    navigate: r.navigated.add,
    settings: () => r.settings,
    showNotice: r.notices.add,
    stopVoiceCapture: () => r.stopCalls += 1,
    startVoiceCapture: () => r.startCalls += 1,
  );
}

VoiceRouteResult _result(
  VoiceCommandId command,
  Map<String, Object?> args, {
  VoiceCommandTier tier = VoiceCommandTier.confirm,
}) {
  return VoiceRouteResult(
    command: command,
    args: args,
    tier: tier,
    transcript: 't',
  );
}

void main() {
  test(
    'navigate_to_screen(settings) navigates to AppRoutes.settings',
    () async {
      final channel = FakeHermesChannel();
      final r = _Recorder();
      await _dispatcher(channel, r).dispatch(
        _result(VoiceCommandId.navigateToScreen, const {'screen': 'settings'}),
      );
      expect(r.navigated, [AppRoutes.settings]);
    },
  );

  test('navigate_to_screen(hermes) navigates to AppRoutes.hermes', () async {
    final channel = FakeHermesChannel();
    final r = _Recorder();
    await _dispatcher(channel, r).dispatch(
      _result(VoiceCommandId.navigateToScreen, const {'screen': 'hermes'}),
    );
    expect(r.navigated, [AppRoutes.hermes]);
  });

  test('show_status shows the connection line with the model name', () async {
    final channel = FakeHermesChannel(models: const ['nova-turbo']);
    final r = _Recorder();
    await _dispatcher(
      channel,
      r,
    ).dispatch(_result(VoiceCommandId.showStatus, const {}));
    expect(r.notices, hasLength(1));
    expect(r.notices.single, contains('Connected'));
    expect(r.notices.single, contains('nova-turbo'));
  });

  test('show_status reports Disconnected with no model info', () async {
    final channel = FakeHermesChannel.disconnected();
    final r = _Recorder();
    await _dispatcher(
      channel,
      r,
    ).dispatch(_result(VoiceCommandId.showStatus, const {}));
    expect(r.notices.single, 'Disconnected');
  });

  test('stop_voice_run calls stopVoiceCapture', () async {
    final channel = FakeHermesChannel();
    final r = _Recorder();
    await _dispatcher(
      channel,
      r,
    ).dispatch(_result(VoiceCommandId.stopVoiceRun, const {}));
    expect(r.stopCalls, 1);
    expect(r.startCalls, 0);
  });

  test('start_voice_run calls startVoiceCapture', () async {
    final channel = FakeHermesChannel();
    final r = _Recorder();
    await _dispatcher(
      channel,
      r,
    ).dispatch(_result(VoiceCommandId.startVoiceRun, const {}));
    expect(r.startCalls, 1);
    expect(r.stopCalls, 0);
  });

  test(
    'toggle_continuous_mode calls the settings setter and notices',
    () async {
      final channel = FakeHermesChannel();
      final r = _Recorder();
      await _dispatcher(channel, r).dispatch(
        _result(VoiceCommandId.toggleContinuousMode, const {'enabled': false}),
      );
      expect(r.settings.continuousEnabled, isFalse);
      expect(r.notices, hasLength(1));
    },
  );

  test('new_session creates a session on the channel and notices', () async {
    final channel = FakeHermesChannel();
    final r = _Recorder();
    await _dispatcher(
      channel,
      r,
    ).dispatch(_result(VoiceCommandId.newSession, const {}));
    expect(channel.createSessionCalls, hasLength(1));
    expect(r.notices, hasLength(1));
  });

  test('switch_session resolves a real title to its session id', () async {
    final channel = FakeHermesChannel(
      sessions: const [
        HermesSession(id: 's1', source: 'x', title: 'groceries'),
        HermesSession(id: 's2', source: 'x', title: 'work notes'),
      ],
    );
    final r = _Recorder();
    await _dispatcher(channel, r).dispatch(
      _result(VoiceCommandId.switchSession, const {
        'session_name': 'groceries',
      }),
    );
    expect(channel.selectSessionCalls, ['s1']);
    expect(channel.state.activeSessionId, 's1');
    expect(r.notices, isEmpty);
  });

  test(
    'switch_session normalizes case/whitespace when matching titles',
    () async {
      final channel = FakeHermesChannel(
        sessions: const [
          HermesSession(id: 's1', source: 'x', title: '  Work   Notes  '),
        ],
      );
      final r = _Recorder();
      await _dispatcher(channel, r).dispatch(
        _result(VoiceCommandId.switchSession, const {
          'session_name': 'work notes',
        }),
      );
      expect(channel.selectSessionCalls, ['s1']);
    },
  );

  test('switch_session notices when the title no longer exists', () async {
    final channel = FakeHermesChannel(
      sessions: const [
        HermesSession(id: 's1', source: 'x', title: 'groceries'),
      ],
    );
    final r = _Recorder();
    await _dispatcher(channel, r).dispatch(
      _result(VoiceCommandId.switchSession, const {
        'session_name': 'poetry night',
      }),
    );
    expect(channel.selectSessionCalls, isEmpty);
    expect(r.notices, ['Session no longer exists.']);
  });

  test('set_tts_voice calls the settings setter and notices', () async {
    final channel = FakeHermesChannel();
    final r = _Recorder();
    await _dispatcher(
      channel,
      r,
    ).dispatch(_result(VoiceCommandId.setTtsVoice, const {'voice': 'nova'}));
    expect(r.settings.ttsVoiceName, 'nova');
    expect(r.notices, hasLength(1));
  });

  test('set_speech_rate calls the settings setter and notices', () async {
    final channel = FakeHermesChannel();
    final r = _Recorder();
    await _dispatcher(
      channel,
      r,
    ).dispatch(_result(VoiceCommandId.setSpeechRate, const {'rate': 1.5}));
    expect(r.settings.speechRate, 1.5);
    expect(r.notices, hasLength(1));
  });

  test('a throwing channel surfaces as a notice, never a throw', () async {
    final channel = FakeHermesChannel(createSessionFails: true);
    final r = _Recorder();
    await expectLater(
      _dispatcher(
        channel,
        r,
      ).dispatch(_result(VoiceCommandId.newSession, const {})),
      completes,
    );
    expect(r.notices, hasLength(1));
    // Exact "Command failed: <RuntimeType>" shape; never the transcript.
    expect(r.notices.single, 'Command failed: StateError');
  });

  test('a throwing selectSession also surfaces as a notice', () async {
    final channel = FakeHermesChannel(
      sessions: const [
        HermesSession(id: 's1', source: 'x', title: 'groceries'),
      ],
      selectSessionFails: true,
    );
    final r = _Recorder();
    await _dispatcher(channel, r).dispatch(
      _result(VoiceCommandId.switchSession, const {
        'session_name': 'groceries',
      }),
    );
    expect(r.notices, hasLength(1));
    expect(r.notices.single, startsWith('Command failed: '));
  });
}
