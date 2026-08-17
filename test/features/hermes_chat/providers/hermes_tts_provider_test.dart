import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/shared/async/fire_and_forget.dart';
import 'package:wing/shared/voice/text_to_speech_service.dart';

import '../support/fake_hermes_channel.dart';

void main() {
  test('chat replies use Hermes Agent TTS', () async {
    final agent = _RecordingTts();
    final channel = _AudioFakeHermesChannel(
      capabilities: const HermesCapabilityDocument(
        object: 'hermes.api_server.capabilities',
        platform: 'test',
        model: 'test',
        auth: HermesAuthCapability(type: 'none', required: false),
        features: {'audio_api': true},
        endpoints: {
          'audio_speak': HermesEndpointCapability(
            method: 'POST',
            path: '/api/audio/speak',
          ),
        },
      ),
    );
    final container = ProviderContainer(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesAgentTtsFactoryProvider.overrideWithValue((_) => agent),
      ],
    );
    addTearDown(channel.dispose);
    addTearDown(container.dispose);

    await container.read(hermesTextToSpeechServiceProvider)!.speak('reply');

    expect(agent.spoken, ['reply']);
  });

  test('chat replies do not call unadvertised Hermes Agent TTS', () {
    final agent = _RecordingTts();
    final channel = _AudioFakeHermesChannel(
      capabilities: const HermesCapabilityDocument(
        object: 'hermes.api_server.capabilities',
        platform: 'test',
        model: 'test',
        auth: HermesAuthCapability(type: 'none', required: false),
        features: {'audio_api': true},
        endpoints: {},
      ),
    );
    final container = ProviderContainer(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesAgentTtsFactoryProvider.overrideWithValue((_) => agent),
      ],
    );
    addTearDown(channel.dispose);
    addTearDown(container.dispose);

    expect(container.read(hermesTextToSpeechServiceProvider), isNull);
  });

  test('chat TTS requires an audio-capable channel', () {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(audioSpeak: true),
    );
    final container = ProviderContainer(
      overrides: [hermesChannelProvider.overrideWithValue(channel)],
    );
    addTearDown(channel.dispose);
    addTearDown(container.dispose);

    expect(container.read(hermesTextToSpeechServiceProvider), isNull);
  });

  test('chat TTS requires every declared endpoint scope', () {
    final channel = _AudioFakeHermesChannel(
      capabilities: _capabilities(
        audioSpeak: true,
        auth: const HermesAuthCapability(
          type: 'bearer',
          required: true,
          grantedScopes: [],
        ),
        requiredScopes: const ['audio:speak'],
      ),
    );
    final container = ProviderContainer(
      overrides: [hermesChannelProvider.overrideWithValue(channel)],
    );
    addTearDown(channel.dispose);
    addTearDown(container.dispose);

    expect(container.read(hermesTextToSpeechServiceProvider), isNull);
  });

  test('profile-scoped chat TTS requires supported profile context', () {
    final channel = _AudioFakeHermesChannel(
      capabilities: _capabilities(audioSpeak: true, profileScoped: true),
    );
    final container = ProviderContainer(
      overrides: [hermesChannelProvider.overrideWithValue(channel)],
    );
    addTearDown(channel.dispose);
    addTearDown(container.dispose);

    expect(container.read(hermesTextToSpeechServiceProvider), isNull);
  });

  test('chat TTS becomes available when Agent audio is advertised', () async {
    final agent = _RecordingTts();
    final channel = _AudioFakeHermesChannel(
      capabilities: _capabilities(audioSpeak: false),
    );
    final container = ProviderContainer(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesAgentTtsFactoryProvider.overrideWithValue((_) => agent),
      ],
    );
    final subscription = container.listen(
      hermesTextToSpeechServiceProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    addTearDown(channel.dispose);
    addTearDown(container.dispose);

    expect(subscription.read(), isNull);

    channel.replaceCapabilitiesAndProfiles(
      _capabilities(audioSpeak: true),
      const [],
    );
    await Future<void>.delayed(Duration.zero);

    expect(subscription.read(), same(agent));
  });

  test('chat TTS is disposed when Agent audio is withdrawn', () async {
    final agent = _RecordingTts();
    final channel = _AudioFakeHermesChannel(
      capabilities: _capabilities(audioSpeak: true),
    );
    final container = ProviderContainer(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesAgentTtsFactoryProvider.overrideWithValue((_) => agent),
      ],
    );
    final subscription = container.listen(
      hermesTextToSpeechServiceProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    addTearDown(channel.dispose);
    addTearDown(container.dispose);

    expect(subscription.read(), same(agent));

    channel.replaceCapabilitiesAndProfiles(
      _capabilities(audioSpeak: false),
      const [],
    );
    await Future<void>.delayed(Duration.zero);

    expect(subscription.read(), isNull);
    expect(agent.disposeCalls, 1);
  });

  test(
    'chat TTS teardown failures are reported when audio is withdrawn',
    () async {
      final agent = _RecordingTts(disposeError: StateError('dispose failed'));
      final channel = _AudioFakeHermesChannel(
        capabilities: _capabilities(audioSpeak: true),
      );
      final container = ProviderContainer(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesAgentTtsFactoryProvider.overrideWithValue((_) => agent),
        ],
      );
      final subscription = container.listen(
        hermesTextToSpeechServiceProvider,
        (_, _) {},
        fireImmediately: true,
      );
      final reported = <String>[];
      final previousReporter = reportFireAndForgetFailure;
      reportFireAndForgetFailure = (operation, _) => reported.add(operation);
      addTearDown(() => reportFireAndForgetFailure = previousReporter);
      addTearDown(subscription.close);
      addTearDown(channel.dispose);
      addTearDown(container.dispose);

      channel.replaceCapabilitiesAndProfiles(
        _capabilities(audioSpeak: false),
        const [],
      );
      await Future<void>.delayed(Duration.zero);

      expect(reported, ['Hermes Agent TTS disposal']);
    },
  );

  test(
    'unrelated channel state preserves the active chat TTS service',
    () async {
      final agent = _RecordingTts();
      final channel = _AudioFakeHermesChannel(
        capabilities: _capabilities(audioSpeak: true),
      );
      final container = ProviderContainer(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesAgentTtsFactoryProvider.overrideWithValue((_) => agent),
        ],
      );
      final subscription = container.listen(
        hermesTextToSpeechServiceProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      addTearDown(channel.dispose);
      addTearDown(container.dispose);
      final original = subscription.read();

      channel.replaceSessions(const [
        HermesSession(id: 'new-session', source: 'test'),
      ], activeSessionId: 'new-session');
      await Future<void>.delayed(Duration.zero);

      expect(subscription.read(), same(original));
      expect(agent.disposeCalls, 0);
    },
  );
}

HermesCapabilityDocument _capabilities({
  required bool audioSpeak,
  HermesAuthCapability auth = const HermesAuthCapability(
    type: 'none',
    required: false,
  ),
  List<String> requiredScopes = const [],
  bool profileScoped = false,
}) {
  return HermesCapabilityDocument(
    object: 'hermes.api_server.capabilities',
    platform: 'test',
    model: 'test',
    auth: auth,
    features: const {'audio_api': true},
    endpoints: {
      if (audioSpeak)
        'audio_speak': HermesEndpointCapability(
          method: 'POST',
          path: '/api/audio/speak',
          requiredScopes: requiredScopes,
          profileScoped: profileScoped,
        ),
    },
  );
}

final class _AudioFakeHermesChannel extends FakeHermesChannel
    implements HermesAudioChannel {
  _AudioFakeHermesChannel({super.capabilities});

  @override
  Future<Uint8List> synthesizeSpeech(String text) async => Uint8List(0);

  @override
  Future<String> transcribePcm16(Uint8List pcm16) async => '';
}

final class _RecordingTts implements TextToSpeechService {
  _RecordingTts({this.disposeError});

  final Object? disposeError;
  final spoken = <String>[];
  int disposeCalls = 0;

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
    disposeCalls++;
    if (disposeError case final error?) throw error;
  }
}
